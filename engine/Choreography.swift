// Opt-in choreography. Existing films retain their original timing and easing.
import AppKit

enum MotionCurve {
    case linear, easeIn, easeOut, easeInOut
    /// x handles must be in 0...1; y handles may overshoot.
    case bezier(Double, Double, Double, Double)
    /// Response is measured relative to the animation interval; damping is a ratio in 0...1.
    /// A small endpoint correction brings the spring to exact rest at the end of that interval.
    case spring(response: Double, damping: Double)

    func value(_ progress: Double) -> Double {
        let u = clamp(progress)
        if u == 0 || u == 1 { return u }
        switch self {
        case .linear: return u
        case .easeIn: return inCubic(u)
        case .easeOut: return outCubic(u)
        case .easeInOut: return inOut(u)
        case .bezier(let x1, let y1, let x2, let y2):
            precondition([x1, y1, x2, y2].allSatisfy(\.isFinite) && (0...1).contains(x1) && (0...1).contains(x2))
            func component(_ t: Double, _ a: Double, _ b: Double) -> Double {
                3 * (1-t) * (1-t) * t * a + 3 * (1-t) * t * t * b + t * t * t
            }
            // Invert x, rather than treating the Bezier parameter as elapsed time.
            var lo = 0.0, hi = 1.0
            for _ in 0..<40 {
                let mid = (lo + hi) / 2
                if component(mid, x1, x2) < u { lo = mid } else { hi = mid }
            }
            return component((lo + hi) / 2, y1, y2)
        case .spring(let response, let damping):
            precondition(response.isFinite && response > 0 && damping.isFinite && (0...1).contains(damping))
            let w = 2 * Double.pi / response
            func raw(_ t: Double) -> Double {
                if damping >= 0.9999 { return 1 - exp(-w*t) * (1+w*t) }
                let wd = w * sqrt(1-damping*damping)
                return 1 - exp(-damping*w*t) * (cos(wd*t) + damping*w/wd * sin(wd*t))
            }
            let slope = (raw(1.00001)-raw(0.99999)) / 0.00002
            return raw(u) + (1-raw(1)) * (3*u*u-2*u*u*u) - slope * (u*u*u-u*u)
        }
    }
}

/// Hermite keys with explicit velocity (canvas units/second). Use zero velocity for a pause;
/// give intermediate keys the same incoming/outgoing velocity to carry an object through a shot.
struct MotionPath {
    struct Key {
        var time: Double
        var point: CGPoint
        var velocity: CGPoint = .zero
    }
    let keys: [Key]
    init(_ keys: [Key]) {
        precondition(!keys.isEmpty)
        precondition(keys.allSatisfy { $0.time.isFinite && [$0.point.x, $0.point.y, $0.velocity.x, $0.velocity.y].allSatisfy(\.isFinite) })
        self.keys = keys.sorted { $0.time < $1.time }
        precondition(zip(self.keys, self.keys.dropFirst()).allSatisfy { $0.time < $1.time })
    }
    func position(_ t: Double) -> CGPoint {
        if t <= keys[0].time { return keys[0].point }
        if t >= keys.last!.time { return keys.last!.point }
        let i = keys.indices.dropLast().first { t < keys[$0+1].time }!
        let a = keys[i], b = keys[i+1], dt = b.time-a.time, u = (t-a.time)/dt
        let h0 = 2*u*u*u-3*u*u+1, h1 = u*u*u-2*u*u+u
        let h2 = -2*u*u*u+3*u*u, h3 = u*u*u-u*u
        return CGPoint(x: CGFloat(h0)*a.point.x + CGFloat(h1*dt)*a.velocity.x + CGFloat(h2)*b.point.x + CGFloat(h3*dt)*b.velocity.x,
                       y: CGFloat(h0)*a.point.y + CGFloat(h1*dt)*a.velocity.y + CGFloat(h2)*b.point.y + CGFloat(h3*dt)*b.velocity.y)
    }
}

/// One visual identity persists while its bounds change. Draw it once, outside scene crossfades.
struct SharedElement {
    var from, to: CGRect
    var start, end: Double
    var curve: MotionCurve = .easeInOut
    func rect(at t: Double) -> CGRect {
        precondition(end > start && start.isFinite && end.isFinite)
        let r = lerp(from, to, curve.value(prog(t, start, end)))
        return CGRect(x: r.minX, y: r.minY, width: max(0.001, r.width), height: max(0.001, r.height))
    }
    func draw(_ t: Double, _ paint: (CGRect) -> Void) {
        let r = rect(at: t)
        if t > start && t < end { unlogged { paint(r) } } else { paint(r) }
    }
}

/// Temporal blur for a selected moving layer, with midpoint samples averaged in premultiplied RGBA.
/// Keep readable type outside this layer. Draw closures must be deterministic at arbitrary times.
/// It samples only inside `moving`; outside it draws once, so holds stay sharp. No audit duplication.
func temporalLayer(t: Double, fps: Int? = nil, shutter: Double = 0.5, samples: Int = 5,
                   moving: ClosedRange<Double>, _ paint: (Double) -> Void) {
    let fps = fps ?? renderFPS
    precondition(fps > 0 && samples >= 1 && samples <= 16 && shutter.isFinite && (0...1).contains(shutter))
    guard samples > 1 && shutter > 0 && t > moving.lowerBound && t < moving.upperBound else { paint(t); return }
    // Audit the nominal frame only; subframes must not become duplicate text or crop observations.
    if textLog != nil || layoutLog != nil { paint(t); return }
    let saved = ctx!, savedScale = deviceScale
    let width = max(1, Int(W * savedScale)), height = max(1, Int(H * savedScale)), count = width * height * 4
    var sum = [UInt32](repeating: 0, count: count)
    for i in 0..<samples {
        let time = clamp(t + ((Double(i)+0.5)/Double(samples)-0.5) * shutter/Double(fps), moving.lowerBound, moving.upperBound)
        let c = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width*4,
                          space: srgb, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        c.translateBy(x: 0, y: CGFloat(height)); c.scaleBy(x: savedScale, y: -savedScale)
        c.textMatrix = .identity
        ctx = c
        paint(time)
        let bytes = c.data!.assumingMemoryBound(to: UInt8.self)
        for j in 0..<count { sum[j] += UInt32(bytes[j]) }
    }
    ctx = saved; deviceScale = savedScale
    var bytes = sum.map { UInt8(($0 + UInt32(samples/2))/UInt32(samples)) }
    let c = CGContext(data: &bytes, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width*4,
                      space: srgb, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    drawImage(c.makeImage()!, in: fullCanvas())
}
