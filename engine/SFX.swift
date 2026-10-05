// motionable engine: more sound effects, each from a product's world — kitchen, money, paper, camera, play,
// tech. All synthesised; place them with `s.cue(t, "what", sound, gain)`.
import Foundation

private func e(_ s: Double, _ a: Double, _ d: Double) -> Float { Float(min(1, s / max(a, 1e-4)) * exp(-s * d)) }

/// A knife chop on a board: a sharp tick and a woody thunk.
func chop() -> [Float] {
    var f = SVF(), g = SVF(); var ph = 0.0
    return (0..<n(0.18)).map { i in
        let s = x(i)
        ph += (140 * (1 + exp(-s * 50))) / Double(SR)
        let tick = f.run(noise.next(), 3400, 0.5).band * e(s, 0.0003, 120) * 1.4
        let thunk = Float(sin(2 * .pi * ph)) * e(s, 0.001, 32) * 0.8
        return tick + thunk + g.run(noise.next(), 900, 0.7).band * e(s, 0.001, 60) * 0.5
    }
}
/// Pan sizzle: crackling fat over a hiss (loopable bed; give it a length).
func sizzle(_ length: Double = 1.5) -> [Float] {
    var f = SVF(), h = SVF(); var g = Noise(s: 4411)
    return (0..<n(length)).map { i in
        let s = x(i)
        let pop: Float = abs(g.next()) > 0.996 ? g.next() * 0.9 : 0
        let hiss = h.run(g.next(), 6500, 0.6).high * 0.25
        let fade = Float(min(1, s / 0.15) * min(1, (length - s) / 0.25))
        return (f.run(pop, 4200, 1.2).band * 1.6 + hiss) * fade
    }
}
/// Liquid pouring.
func pour(_ length: Double = 1.0) -> [Float] {
    var f = SVF()
    return (0..<n(length)).map { i in
        let s = x(i)
        let gurgle = 700 + 500 * sin(2 * .pi * 9 * s) + 300 * sin(2 * .pi * 23 * s)
        let fade = Float(min(1, s / 0.1) * min(1, (length - s) / 0.2))
        return f.run(noise.next(), Float(gurgle), 3).band * 0.6 * fade
    }
}
/// A cash register "ka-ching": a ratchet, then two bright bell notes.
func kaching() -> [Float] {
    var out = [Float](repeating: 0, count: n(1.2))
    var f = SVF()
    for i in 0..<n(0.12) { let s = x(i); out[i] += f.run(noise.next(), 2500, 0.5).band * Float(abs(sin(2 * .pi * 60 * s))) * 0.8 }
    let b1 = bell(88, vel: 0.9, length: 1.0), b2 = bell(93, vel: 1, length: 1.0)
    let o1 = n(0.1), o2 = n(0.18)
    for (k, v) in b1.enumerated() where o1 + k < out.count { out[o1 + k] += v }
    for (k, v) in b2.enumerated() where o2 + k < out.count { out[o2 + k] += v }
    return out
}
/// A few coins landing.
func coins(_ count: Int = 5) -> [Float] {
    var out = [Float](repeating: 0, count: n(0.9))
    var g = Seeded(55)
    for c in 0..<count {
        let o = n(Double(c) * 0.07 + g.next() * 0.04)
        let f = 3000 + g.next() * 2500
        for i in 0..<n(0.25) where o + i < out.count {
            let s = x(i); out[o + i] += Float(sin(2 * .pi * f * s) + 0.5 * sin(2 * .pi * f * 2.76 * s)) * e(s, 0.0005, 18) * 0.3
        }
    }
    return out
}
/// A page turning.
func pageFlip() -> [Float] {
    var f = SVF()
    return (0..<n(0.35)).map { i in
        let s = x(i), p = s / 0.35
        return f.run(noise.next(), Float(4500 - 3200 * p), 0.6).band * Float(sin(.pi * p)) * 0.9
    }
}
/// A pen scribbling (give it a length).
func penScribble(_ length: Double = 0.6) -> [Float] {
    var f = SVF()
    return (0..<n(length)).map { i in
        let s = x(i)
        let strokes = Float(max(0, sin(2 * .pi * 11 * s + sin(2 * .pi * 3 * s) * 2)))
        return f.run(noise.next(), 5200, 0.8).band * strokes * Float(min(1, (length - s) / 0.08)) * 0.7
    }
}
/// A camera shutter.
func shutter() -> [Float] {
    var f = SVF()
    return (0..<n(0.2)).map { i in
        let s = x(i)
        let clicks = e(s, 0.0003, 160) + (s > 0.07 ? e(s - 0.07, 0.0003, 120) * 0.8 : 0)
        return f.run(noise.next(), 3800, 0.5).band * clicks * 1.4
    }
}
/// A cartoon spring "boing".
func boing() -> [Float] {
    var ph = 0.0
    return (0..<n(0.6)).map { i in
        let s = x(i)
        ph += (220 + 180 * s + 60 * sin(2 * .pi * 14 * s) * exp(-s * 3)) / Double(SR)
        return Float(sin(2 * .pi * ph)) * e(s, 0.002, 5) * 0.7
    }
}
/// A bubbly "bloop" (pitch drop).
func bloop() -> [Float] {
    var ph = 0.0
    return (0..<n(0.2)).map { i in
        let s = x(i); ph += (900 * exp(-s * 14) + 200) / Double(SR)
        return Float(sin(2 * .pi * ph)) * e(s, 0.002, 16) * 0.8
    }
}
/// A slide whistle, up or down.
func slideWhistle(up: Bool = true, length: Double = 0.5) -> [Float] {
    var ph = 0.0
    return (0..<n(length)).map { i in
        let s = x(i), p = s / length
        let f = up ? 500 + 1300 * p : 1800 - 1300 * p
        ph += f * (1 + 0.01 * sin(2 * .pi * 7 * s)) / Double(SR)
        return Float(sin(2 * .pi * ph)) * Float(sin(.pi * p)) * 0.5
    }
}
/// A short, airy swish (lighter than a whoosh).
func swish() -> [Float] { whoosh(0.22) }
/// A zipper-like fast sweep.
func zipper(_ length: Double = 0.25) -> [Float] {
    var f = SVF()
    return (0..<n(length)).map { i in
        let s = x(i), p = s / length
        let grain = Float(abs(sin(2 * .pi * (80 + 260 * p) * s)))
        return f.run(noise.next(), Float(1500 + 4500 * p), 0.6).band * grain * Float(sin(.pi * p)) * 1.2
    }
}
/// A digital glitch zap.
func glitchZap() -> [Float] {
    var g = Seeded(31); var ph = 0.0
    var f = 300.0
    return (0..<n(0.25)).map { i in
        if i % n(0.02) == 0 { f = 150 + g.next() * 1800 }
        ph += f / Double(SR)
        let v: Float = (ph - floor(ph)) < 0.5 ? 0.5 : -0.5
        return v * e(x(i), 0.001, 8) * (g.next() > 0.15 ? 1 : 0)
    }
}
/// A run of short data blips.
func blips(_ count: Int = 4, spacing: Double = 0.06) -> [Float] {
    var out = [Float](repeating: 0, count: n(Double(count) * spacing + 0.1))
    var g = Seeded(7)
    for c in 0..<count {
        let o = n(Double(c) * spacing), f = 1200 + g.next() * 1600
        for i in 0..<n(0.04) where o + i < out.count { let s = x(i); out[o + i] += Float(sin(2 * .pi * f * s)) * e(s, 0.001, 70) * 0.5 }
    }
    return out
}
/// A rising major chime: something worked.
func success() -> [Float] {
    var out = [Float](repeating: 0, count: n(1.0))
    for (k, m) in [76, 80, 83, 88].enumerated() {
        let b = marimba(m, vel: 0.8), o = n(Double(k) * 0.07)
        for (j, v) in b.enumerated() where o + j < out.count { out[o + j] += v * 0.6 }
    }
    return out
}
/// A low double buzz: something failed.
func errorBuzz() -> [Float] {
    var ph = 0.0
    return (0..<n(0.32)).map { i in
        let s = x(i); ph += 150 / Double(SR)
        let gate: Float = (s < 0.12 || (s > 0.17 && s < 0.29)) ? 1 : 0
        return saw(ph) * gate * 0.35
    }
}
/// A bubble pop.
func bubble() -> [Float] {
    var ph = 0.0
    return (0..<n(0.12)).map { i in
        let s = x(i); ph += (400 + 2200 * s / 0.12) / Double(SR)
        return Float(sin(2 * .pi * ph)) * e(s, 0.001, 30) * 0.6
    }
}
/// A heartbeat (lub-dub).
func heartbeat() -> [Float] {
    var out = [Float](repeating: 0, count: n(0.7))
    for (o, v) in [(0.0, 1.0), (0.22, 0.75)] {
        let k = kick(deep: false)
        let off = n(o)
        for (j, s) in k.enumerated() where off + j < out.count { out[off + j] += s * Float(v) * 0.8 }
    }
    return out
}
