// motionable engine: footage, the real app moving. Any screen recording (.mov or .mp4: a Simulator capture,
// QuickTime, a phone recording) is drawn like a screenshot: whole, a region of it, or through a camera that follows
// the action, with speed ramps and freeze frames. `scripts/footage.sh` shows where the action is before you edit.
import AVFoundation
import AppKit

/// Holds a result across the thread hop in `blocking`.
private final class BlockingBox<T>: @unchecked Sendable { var value: T?; init() {} }
/// Runs async AVFoundation loading from the engine's synchronous drawing code.
private func blocking<T>(_ work: @escaping @Sendable () async throws -> T) -> T? {
    let box = BlockingBox<T>(), done = DispatchSemaphore(value: 0)
    Task.detached { box.value = try? await work(); done.signal() }
    done.wait()
    return box.value
}

/// A screen recording in the film's assets. Frames are decoded in order and cached, so playing it forward is cheap.
final class Footage {
    let path: String
    let duration: Double
    /// The recording's frame size, upright (pixels): use it like a screenshot's size for regions and `canvasPoint`.
    let size: CGSize
    var bounds: CGRect { CGRect(origin: .zero, size: size) }
    private let asset: AVURLAsset
    private let track: AVAssetTrack?
    private let transform: CGAffineTransform
    private var reader: AVAssetReader?
    private var output: AVAssetReaderTrackOutput?
    private var current: (s: Double, image: CGImage)?      // the newest frame at or before the last request
    private var ahead: (s: Double, image: CGImage)?        // a frame already decoded past it

    init(_ path: String) {
        self.path = path
        let url = path.hasPrefix("/") ? URL(fileURLWithPath: path) : projectDir.appendingPathComponent(path)
        asset = AVURLAsset(url: url)
        let a = asset
        let info = blocking { () -> (Double, AVAssetTrack?, CGSize, CGAffineTransform) in
            let d = try await a.load(.duration)
            guard let t = try await a.loadTracks(withMediaType: .video).first else { return (CMTimeGetSeconds(d), nil, .zero, .identity) }
            let (natural, pt) = try await t.load(.naturalSize, .preferredTransform)
            return (CMTimeGetSeconds(d), t, natural, pt)
        }
        if info?.1 == nil { print("motionable: can't read the video track of \(path)") }
        duration = info?.0 ?? 0
        track = info?.1
        transform = info?.3 ?? .identity
        let upright = CGRect(origin: .zero, size: info?.2 ?? .zero).applying(transform)
        size = CGSize(width: abs(upright.width), height: abs(upright.height))
    }

    /// The frame on screen `s` seconds into the recording (clamped to it). Variable-frame-rate recordings hold
    /// each frame until the next, just as they play.
    func frame(at s: Double) -> CGImage? {
        guard track != nil, duration > 0 else { return nil }
        let s = min(max(0, s), max(0, duration - 0.001))
        if let c = current, s >= c.s, ahead.map({ s < $0.s }) ?? false { return c.image }
        // Decode forward until the requested moment. A timeRange starting just before it can discard the
        // frame still on screen in sparse recordings, so backward seeks restart from the beginning.
        if reader == nil || s < (current?.s ?? 0) { restart() }
        while true {
            if let a = ahead {
                guard a.s <= s else { break }
                current = a; ahead = nil
            }
            guard let next = readNext() else { break }
            if next.s <= s { current = next } else { ahead = next; break }
        }
        if current == nil, let a = ahead { return a.image }                     // asked for a moment before the first frame
        return current?.image
    }

    private func restart() {
        reader?.cancelReading()
        guard let track, let r = try? AVAssetReader(asset: asset) else { reader = nil; return }
        let out = AVAssetReaderTrackOutput(track: track, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA])
        out.alwaysCopiesSampleData = false
        r.add(out)
        r.startReading()
        reader = r; output = out; current = nil; ahead = nil
    }

    private func readNext() -> (s: Double, image: CGImage)? {
        guard let sample = output?.copyNextSampleBuffer() else { return nil }
        guard let pixels = CMSampleBufferGetImageBuffer(sample) else { return readNext() }
        let s = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sample))
        var image = CIImage(cvPixelBuffer: pixels)
        if transform != .identity {                                            // a rotated phone recording: stand it up
            image = image.transformed(by: transform)
            image = image.transformed(by: CGAffineTransform(translationX: -image.extent.minX, y: -image.extent.minY))
        }
        guard let cg = ciContext.createCGImage(image, from: image.extent) else { return readNext() }
        return (s, cg)
    }
}

/// Film time → recording time. The recording is at `keys[0].s` at film time `keys[0].t`; between keys it runs at
/// whatever speed gets it from one moment to the next (3 s of recording in 1 s of film plays 3× fast), and two keys
/// at the same recording moment hold a freeze frame. Speed changes ease into each other (a speed ramp), and it never
/// runs backwards. Before the first key it holds the first moment; after the last it keeps the last speed.
struct Playback {
    let keys: [(t: Double, s: Double)]
    private let slopes: [Double]
    private let ramps: Bool

    init(_ keys: [(Double, Double)], ramps: Bool = true) {
        precondition(keys.allSatisfy { $0.0.isFinite && $0.1.isFinite }, "Playback keys must be finite")
        self.keys = keys.map { (t: $0.0, s: $0.1) }.sorted { $0.t < $1.t }
        self.ramps = ramps
        precondition(zip(self.keys, self.keys.dropFirst()).allSatisfy { $1.t > $0.t && $1.s >= $0.s },
                     "Playback needs distinct film times and nondecreasing recording times")
        let k = self.keys, n = k.count
        guard n > 1 else { slopes = [1]; return }
        let d = (0..<(n - 1)).map { (k[$0 + 1].s - k[$0].s) / max(1e-6, k[$0 + 1].t - k[$0].t) }
        var m = [Double](repeating: 0, count: n)
        if ramps {
            // Fritsch–Carlson: a smooth, monotone curve through the keys (no overshoot, so no rewinding).
            m[0] = d[0]; m[n - 1] = d[n - 2]
            for i in 1..<(n - 1) { m[i] = d[i - 1] * d[i] > 0 ? (d[i - 1] + d[i]) / 2 : 0 }
            for i in 0..<(n - 1) {
                if abs(d[i]) < 1e-9 { m[i] = 0; m[i + 1] = 0; continue }
                let a = m[i] / d[i], b = m[i + 1] / d[i], q = a * a + b * b
                if q > 9 { let tau = 3 / q.squareRoot(); m[i] = tau * a * d[i]; m[i + 1] = tau * b * d[i] }
            }
            slopes = m
        } else {
            slopes = d + [d[n - 2]]                         // straight lines: speed changes are cuts
        }
    }

    /// The recording's moment at film time `t`.
    func at(_ t: Double) -> Double {
        guard let first = keys.first else { return t }
        if keys.count == 1 || t <= first.t { return first.s }
        let last = keys[keys.count - 1]
        if t >= last.t { return last.s + (t - last.t) * slopes[keys.count - 1] }
        var i = 0
        while i < keys.count - 2 && t > keys[i + 1].t { i += 1 }
        let a = keys[i], b = keys[i + 1], h = b.t - a.t, u = (t - a.t) / h
        if !ramps { return a.s + (b.s - a.s) * u }
        let h00 = 2 * u * u * u - 3 * u * u + 1, h10 = u * u * u - 2 * u * u + u, h01 = -2 * u * u * u + 3 * u * u, h11 = u * u * u - u * u
        return h00 * a.s + h10 * h * slopes[i] + h01 * b.s + h11 * h * slopes[i + 1]
    }

    /// The earliest film time when the recording reaches `s`; infinity if a final freeze never reaches it.
    func filmTime(of s: Double) -> Double {
        guard let first = keys.first, let last = keys.last else { return s }
        if s <= first.s { return first.t }
        if s > last.s {
            let speed = keys.count > 1 ? slopes[keys.count - 1] : 0
            return speed > 0 ? last.t + (s - last.s) / speed : .infinity
        }
        var lo = first.t, hi = last.t
        for _ in 0..<60 { let mid = (lo + hi) / 2; if at(mid) < s { lo = mid } else { hi = mid } }
        return hi
    }
}

/// A camera inside a recording (or any image): keyframed regions, eased between. Zooms feel even because the size
/// changes geometrically. Keep the regions' proportions close to the card's, or draw with `cover: true`.
struct Zoom {
    let keys: [(t: Double, region: CGRect)]
    init(_ keys: [(Double, CGRect)]) { self.keys = keys.map { (t: $0.0, region: $0.1) }.sorted { $0.t < $1.t } }

    func region(_ t: Double) -> CGRect {
        guard var r = keys.first?.region else { return .zero }
        for i in 1..<keys.count where t > keys[i - 1].t {
            let a = keys[i - 1].region, b = keys[i].region, e = inOut(prog(t, keys[i - 1].t, keys[i].t))
            let w = a.width * pow(b.width / a.width, CGFloat(e)), h = a.height * pow(b.height / a.height, CGFloat(e))
            let c = lerp(CGPoint(x: a.midX, y: a.midY), CGPoint(x: b.midX, y: b.midY), e)
            r = CGRect(x: c.x - w / 2, y: c.y - h / 2, width: w, height: h)
        }
        return r
    }
}

/// Draws the recording's frame at moment `s` (or a region of it) like `drawScreen`: fitted into `box` as a rounded card
/// with a shadow. With `cover: true` the card is exactly `box`, and the region grows to the box's shape around its
/// centre (for a camera moving inside a card that stays put). Returns the card's canvas rect; map recording pixels to the
/// canvas with `canvasPoint(p, region: footageRegion(…), drawnIn: card)`.
@discardableResult
func drawFootage(_ f: Footage, at s: Double, region: CGRect? = nil, in box: CGRect, cover: Bool = false, radius: CGFloat = 44,
                 shadow: Bool = true, alpha: CGFloat = 1, edge: Col = Col(0xFFFFFF)) -> CGRect {
    let src = footageRegion(f, region, cover ? box : nil)
    let dest = cover ? box : fitted(src, in: box)
    guard let frame = f.frame(at: s) else {
        fill(rr(dest, radius), Col(0x000000, 0.2 * alpha)); return dest
    }
    if region != nil { noteCrop(f.path, image: frame, region: src, camera: cover) }
    let k = dest.width / src.width
    let path = rr(dest, radius)
    ctx.saveGState()
    ctx.setAlpha(alpha)
    if shadow { fillShadowed(path, edge, blur: 46, alpha: 0.22, dy: 16) }
    ctx.addPath(path); ctx.clip()
    ctx.interpolationQuality = .high
    drawImage(frame, in: CGRect(x: dest.minX - src.minX * k, y: dest.minY - src.minY * k, width: f.size.width * k, height: f.size.height * k))
    ctx.restoreGState()
    return dest
}

/// The region of the recording `drawFootage` actually shows: `region` (or the whole frame), grown to `box`'s shape when
/// covering a fixed card (`cover: true`), and kept inside the frame.
func footageRegion(_ f: Footage, _ region: CGRect?, _ box: CGRect? = nil) -> CGRect {
    var r = region ?? f.bounds
    if let box, box.height > 0, r.height > 0 {
        let want = box.width / box.height, have = r.width / r.height
        if have < want { let w = r.height * want; r = CGRect(x: r.midX - w / 2, y: r.minY, width: w, height: r.height) }
        else if have > want { let h = r.width / want; r = CGRect(x: r.minX, y: r.midY - h / 2, width: r.width, height: h) }
    }
    if r.width > f.size.width { r = CGRect(x: (f.size.width - r.width) / 2, y: r.minY, width: r.width, height: r.height) }
    else { r.origin.x = min(max(0, r.minX), f.size.width - r.width) }
    if r.height > f.size.height { r = CGRect(x: r.minX, y: (f.size.height - r.height) / 2, width: r.width, height: r.height) }
    else { r.origin.y = min(max(0, r.minY), f.size.height - r.height) }
    return r
}
