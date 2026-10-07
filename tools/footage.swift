// motionable: read a screen recording before editing it (Claude can't watch video, so this says where the action is).
// usage: footage <video>                          size, length, frame rate, and a timeline of where the screen changes
//        footage <video> sheet <s> [<s> …]        a labelled contact sheet of those moments (prints its path)
//        footage <video> frame <s> <out.png>      one moment at full size (to measure with inspect.sh)
//        footage <video> trim <from> <to> <out>   copies that stretch without re-encoding (full quality, small file)
import AppKit
import AVFoundation
import CoreImage

let args = Array(CommandLine.arguments.dropFirst())
guard let path = args.first else {
    print("usage: footage <video> [sheet <s> … | trim <from> <to> <out>]"); exit(2)
}
let url = URL(fileURLWithPath: path)
let asset = AVURLAsset(url: url)
guard let track = try? await asset.loadTracks(withMediaType: .video).first else { print("no video track in \(path)"); exit(1) }
let duration = CMTimeGetSeconds((try? await asset.load(.duration)) ?? .zero)
let (natural, transform) = (try? await track.load(.naturalSize, .preferredTransform)) ?? (.zero, .identity)
let upright = CGRect(origin: .zero, size: natural).applying(transform)
let W = abs(upright.width), H = abs(upright.height)
guard duration.isFinite, duration > 0, W > 0, H > 0 else { print("invalid video dimensions or duration"); exit(1) }
let ci = CIContext()

// Return false to stop once the requested moments have been found. Start at zero so sparse recordings
// retain the frame held on screen, even when its presentation timestamp is several seconds earlier.
func frames(scaledTo width: Int, _ each: (Double, CGImage) -> Bool) {
    guard let reader = try? AVAssetReader(asset: asset) else { print("can't read video"); exit(1) }
    let h = Int(Double(width) * Double(natural.height) / Double(max(1, natural.width)))
    let out = AVAssetReaderTrackOutput(track: track, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                                                                     kCVPixelBufferWidthKey as String: width, kCVPixelBufferHeightKey as String: h])
    out.alwaysCopiesSampleData = false
    guard reader.canAdd(out) else { print("can't decode video"); exit(1) }
    reader.add(out)
    guard reader.startReading() else { print("can't decode video: \(String(describing: reader.error))"); exit(1) }
    while let sample = out.copyNextSampleBuffer() {
        guard let pb = CMSampleBufferGetImageBuffer(sample) else { continue }
        var img = CIImage(cvPixelBuffer: pb)
        if transform != .identity {
            img = img.transformed(by: transform)
            img = img.transformed(by: CGAffineTransform(translationX: -img.extent.minX, y: -img.extent.minY))
        }
        if let cg = ci.createCGImage(img, from: img.extent), !each(CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sample)), cg) {
            reader.cancelReading(); return
        }
    }
    if reader.status == .failed { print("video decoding failed: \(String(describing: reader.error))"); exit(1) }
}
func writePNG(_ image: CGImage, to url: URL) {
    guard url.resolvingSymlinksInPath().standardizedFileURL != URL(fileURLWithPath: path).resolvingSymlinksInPath().standardizedFileURL else {
        print("output must differ from the source recording"); exit(2)
    }
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
        print("can't write \(url.path)"); exit(1)
    }
    CGImageDestinationAddImage(dest, image, nil)
    guard CGImageDestinationFinalize(dest) else { print("can't finish \(url.path)"); exit(1) }
}
func pixels(_ img: CGImage) -> (w: Int, h: Int, data: [UInt8]) {
    var d = [UInt8](repeating: 0, count: img.width * img.height * 4)
    let c = CGContext(data: &d, width: img.width, height: img.height, bitsPerComponent: 8, bytesPerRow: img.width * 4,
                      space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    c.draw(img, in: CGRect(x: 0, y: 0, width: img.width, height: img.height))
    return (img.width, img.height, d)
}

switch args.count > 1 ? args[1] : "info" {
case "sheet":
    let times = args.dropFirst(2).compactMap(Double.init).sorted()
    guard !times.isEmpty, times.count == args.count - 2, times.allSatisfy({ $0.isFinite && $0 >= 0 && $0 <= duration }) else {
        print("sheet times must be within the recording"); exit(2)
    }
    let cw = W > H ? 360 : 220, ch = Int(Double(cw) * Double(H) / Double(W)), cols = min(6, times.count), rows = (times.count + cols - 1) / cols
    let sheet = CGContext(data: nil, width: cols * cw, height: rows * (ch + 30), bitsPerComponent: 8, bytesPerRow: 0,
                          space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    sheet.setFillColor(CGColor(gray: 0.15, alpha: 1)); sheet.fill(CGRect(x: 0, y: 0, width: cols * cw, height: rows * (ch + 30)))
    var shown = [CGImage?](repeating: nil, count: times.count), latest: CGImage? = nil, k = 0
    frames(scaledTo: cw * 2) { s, img in       // frames arrive in order; each moment shows the frame on screen then
        while k < times.count && times[k] < s { shown[k] = latest ?? img; k += 1 }
        latest = img
        return k < times.count
    }
    while k < times.count { shown[k] = latest; k += 1 }
    for (i, img) in shown.enumerated() {
        let col = i % cols, row = i / cols, y = rows * (ch + 30) - (row + 1) * (ch + 30)
        if let img { sheet.draw(img, in: CGRect(x: col * cw, y: y + 30, width: cw, height: ch)) }
        let label = NSAttributedString(string: String(format: "%.2f s", times[i]), attributes: [.font: NSFont.boldSystemFont(ofSize: 18), .foregroundColor: NSColor.white])
        sheet.textPosition = CGPoint(x: col * cw + 6, y: y + 8); CTLineDraw(CTLineCreateWithAttributedString(label), sheet)
    }
    let out = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("motionable-footage-sheet.png")
    writePNG(sheet.makeImage()!, to: out)
    print("wrote \(out.path)")

case "frame":
    guard args.count == 4, let at = Double(args[2]), at.isFinite, at >= 0, at <= duration else {
        print("usage: footage <video> frame <s within recording> <out.png>"); exit(2)
    }
    var shown: CGImage? = nil
    // Decoder dimensions are before rotation; using upright W would shrink a rotated phone recording.
    frames(scaledTo: Int(natural.width)) { s, img in
        if s <= at || shown == nil { shown = img }
        return s <= at
    }
    guard let img = shown else { print("no frame at \(at) s"); exit(1) }
    let out = URL(fileURLWithPath: args[3])
    writePNG(img, to: out)
    print("wrote \(out.path) (\(img.width) × \(img.height) px, the frame on screen at \(at) s)")

case "trim":
    guard args.count == 5, let a = Double(args[2]), let b = Double(args[3]), a.isFinite, b.isFinite,
          a >= 0, b > a, b <= duration else { print("trim needs 0 <= from < to <= duration"); exit(2) }
    let out = URL(fileURLWithPath: args[4])
    guard out.resolvingSymlinksInPath().standardizedFileURL != url.resolvingSymlinksInPath().standardizedFileURL else {
        print("output must differ from the source recording"); exit(2)
    }
    guard ["mp4", "mov"].contains(out.pathExtension.lowercased()) else { print("output must be .mp4 or .mov"); exit(2) }
    guard let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else { print("can't export \(path)"); exit(1) }
    export.timeRange = CMTimeRange(start: CMTime(seconds: a, preferredTimescale: 600), end: CMTime(seconds: b, preferredTimescale: 600))
    do {
        if FileManager.default.fileExists(atPath: out.path) { try FileManager.default.removeItem(at: out) }
        try await export.export(to: out, as: out.pathExtension.lowercased() == "mp4" ? .mp4 : .mov)
        let size = (try? FileManager.default.attributesOfItem(atPath: out.path)[.size] as? Int) ?? 0
        print(String(format: "wrote %@ (%.1f s, %.1f MB). It may start a moment early, at a keyframe: check with `footage <out>`.", out.path, b - a, Double(size) / 1_048_576))
    } catch { print("trim failed: \(error.localizedDescription)"); exit(1) }

case "info":
    // Activity: compare each frame with the one before on a small grid, and gather the changes into 0.25 s windows.
    let gw = 72
    var prev: (w: Int, h: Int, data: [UInt8])? = nil, count = 0
    var windows: [Int: (change: Double, box: CGRect)] = [:]
    frames(scaledTo: gw) { s, img in
        count += 1
        let px = pixels(img)
        defer { prev = px }
        guard let p = prev, p.w == px.w, p.h == px.h else { return true }
        var changed = 0, minX = px.w, minY = px.h, maxX = -1, maxY = -1
        for y in 0..<px.h { for x in 0..<px.w {
            let o = (y * px.w + x) * 4
            if abs(Int(px.data[o]) - Int(p.data[o])) + abs(Int(px.data[o + 1]) - Int(p.data[o + 1])) + abs(Int(px.data[o + 2]) - Int(p.data[o + 2])) > 36 {
                changed += 1; minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
            }
        } }
        guard changed > 0 else { return true }
        let k = Int(s / 0.25), sx = Double(W) / Double(px.w), sy = Double(H) / Double(px.h)
        let box = CGRect(x: Double(minX) * sx, y: Double(minY) * sy, width: Double(maxX - minX + 1) * sx, height: Double(maxY - minY + 1) * sy)
        let frac = Double(changed) / Double(px.w * px.h)
        let old = windows[k]
        windows[k] = (max(old?.change ?? 0, frac), old.map { $0.box.union(box) } ?? box)
        return true
    }
    print(String(format: "%@: %.0f × %.0f px, %.2f s, %d frames (%.0f fps on average%@)", url.lastPathComponent, W, H, duration, count,
                 Double(count) / max(0.01, duration), count < Int(duration * 20) ? "; it records only when the screen changes" : ""))
    // Merge active windows into moments.
    var moments: [(from: Double, to: Double, peak: Double, box: CGRect)] = []
    for k in windows.keys.sorted() {
        let w = windows[k]!, from = Double(k) * 0.25
        if var last = moments.last, from - last.to < 0.3 {
            last.to = from + 0.25; last.peak = max(last.peak, w.change); last.box = last.box.union(w.box); moments[moments.count - 1] = last
        } else { moments.append((from, from + 0.25, w.change, w.box)) }
    }
    print("where the screen changes (recording seconds · how much changes · where, in recording pixels):")
    var cursor = 0.0
    for m in moments {
        if m.from - cursor >= 1.0 { print(String(format: "  %6.2f–%6.2f   still for %.1f s: speed through it, freeze on it, or cut it", cursor, m.from, m.from - cursor)) }
        let kind = m.peak > 0.35 ? "the whole screen changes (a new screen or a scroll)" : (m.peak > 0.05 ? "part of the screen changes" : "a small change (typing, a tap, a tick, a counter)")
        print(String(format: "  %6.2f–%6.2f   %5.2f%%  x %4.0f y %4.0f w %4.0f h %4.0f   %@", m.from, m.to, m.peak * 100, m.box.minX, m.box.minY, m.box.width, m.box.height, kind))
        cursor = m.to
    }
    if duration - cursor >= 1.0 { print(String(format: "  %6.2f–%6.2f   still for %.1f s", cursor, duration, duration - cursor)) }
    print("next: footage <video> sheet <s> … to look at moments; zoom into a change's box with Zoom; ramp through still stretches with Playback")
default:
    print("unknown mode \(args[1])"); exit(2)
}
