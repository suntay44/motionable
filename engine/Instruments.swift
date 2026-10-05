// motionable engine: more instruments, all synthesised. Drums take a velocity (0…1); pitched voices take a
// MIDI note and a length in seconds, and return mono samples.
import Foundation

private func env(_ s: Double, attack: Double, decay: Double) -> Float { Float(min(1, s / max(attack, 1e-4)) * exp(-s * decay)) }
private func adsr(_ s: Double, _ dur: Double, a: Double, d: Double, sus: Double, r: Double) -> Float {
    let v: Double
    if s < a { v = s / a } else if s < a + d { v = 1 - (1 - sus) * (s - a) / d } else { v = sus }
    return Float(s < dur ? v : v * exp(-(s - dur) / max(r, 1e-4) * 5))
}
private func sine(_ ph: Double) -> Float { Float(sin(2 * .pi * ph)) }

// MARK: - Drums

func snare(_ vel: Float = 1, tone: Double = 185, snap: Double = 1) -> [Float] {
    var f = SVF(), hp = SVF(); var ph = 0.0
    return (0..<n(0.32)).map { i in
        let s = x(i)
        ph += (tone + 60 * exp(-s * 40)) / Double(SR)
        let body = sine(ph) * env(s, attack: 0.001, decay: 22) * 0.7
        let wires = hp.run(f.run(noise.next(), 5200, 0.6).low, 900, 0.7).high * env(s, attack: 0.001, decay: 13 / snap) * 0.9
        return (body + wires) * vel
    }
}
func rim(_ vel: Float = 1) -> [Float] {
    var f = SVF()
    return (0..<n(0.06)).map { i in let s = x(i); return (sine(1750 * s) * 0.6 + f.run(noise.next(), 3000, 0.4).band * 1.2) * env(s, attack: 0.0005, decay: 90) * vel }
}
func shaker(_ vel: Float = 1) -> [Float] {
    var f = SVF()
    return (0..<n(0.09)).map { i in let s = x(i); return f.run(noise.next(), 7500, 0.6).high * Float(min(1, s / 0.012) * exp(-s * 45)) * vel * 0.8 }
}
func tambourine(_ vel: Float = 1) -> [Float] {
    var f = SVF()
    return (0..<n(0.22)).map { i in
        let s = x(i)
        let jingle = Float(0.6 + 0.4 * sin(2 * .pi * 70 * s))
        return f.run(noise.next(), 8000, 0.5).high * jingle * env(s, attack: 0.001, decay: 16) * vel
    }
}
func cowbell(_ vel: Float = 1) -> [Float] {
    var f = SVF(); var p1 = 0.0, p2 = 0.0
    return (0..<n(0.3)).map { i in
        let s = x(i)
        p1 += 540 / Double(SR); p2 += 800 / Double(SR)
        let sq: Float = ((p1 - floor(p1)) < 0.5 ? 1 : -1) + ((p2 - floor(p2)) < 0.5 ? 1 : -1)
        return f.run(sq * 0.5, 2600, 1.4).band * env(s, attack: 0.001, decay: 11) * vel
    }
}
func clave(_ vel: Float = 1) -> [Float] {
    (0..<n(0.08)).map { i in let s = x(i); return sine(2500 * s) * env(s, attack: 0.0004, decay: 70) * vel }
}
func conga(_ vel: Float = 1, pitch: Double = 210) -> [Float] {
    var ph = 0.0
    return (0..<n(0.35)).map { i in
        let s = x(i)
        ph += (pitch * (1 + 0.25 * exp(-s * 60))) / Double(SR)
        return (sine(ph) + noise.next() * Float(exp(-s * 300)) * 0.4) * env(s, attack: 0.001, decay: 11) * vel
    }
}
/// A tom or taiko: low, pitched, with a skin thump. `big` makes it a taiko.
func tom(_ vel: Float = 1, pitch: Double = 110, big: Bool = false) -> [Float] {
    var ph = 0.0; var f = SVF()
    let len = big ? 1.4 : 0.5
    return (0..<n(len)).map { i in
        let s = x(i)
        ph += (pitch * (1 + 0.6 * exp(-s * 25))) / Double(SR)
        let skin = f.run(noise.next(), 600, 0.8).low * Float(exp(-s * 30)) * (big ? 1.4 : 0.6)
        return tanhf((sine(ph) * env(s, attack: 0.001, decay: big ? 3.2 : 8) + skin) * (big ? 1.6 : 1.1)) * vel
    }
}
/// The 808: a long tuned boom with a pitch drop; `glide` slides from another note (trap slides).
func eight08(_ midi: Int, _ dur: Double, glideFrom: Int? = nil, drive: Float = 1.6) -> [Float] {
    var ph = 0.0
    let target = hz(midi), start = glideFrom.map(hz) ?? target
    return (0..<n(dur + 0.08)).map { i in
        let s = x(i)
        let f = target + (start - target) * exp(-s * 18) + target * 1.6 * exp(-s * 55)
        ph += f / Double(SR)
        let a = Float(min(1, s / 0.002)) * Float(s < dur ? exp(-s * 0.9) : exp(-dur * 0.9) * exp(-(s - dur) * 60))
        return tanhf(sine(ph) * drive) / tanhf(drive) * a
    }
}

// MARK: - Bass

func subBass(_ midi: Int, _ dur: Double) -> [Float] {
    var ph = 0.0
    return (0..<n(dur + 0.05)).map { i in
        let s = x(i); ph += hz(midi) / Double(SR)
        return tanhf(sine(ph) * 1.3) * adsr(s, dur, a: 0.005, d: 0.1, sus: 0.85, r: 0.06)
    }
}
/// A funky plucked bass: bright attack that closes fast, `vel` opens the filter more.
func funkBass(_ midi: Int, _ dur: Double, vel: Float = 1) -> [Float] {
    var f = SVF(); var p1 = 0.0, p2 = 0.0
    return (0..<n(dur + 0.05)).map { i in
        let s = x(i)
        p1 += hz(midi) / Double(SR); p2 += hz(midi) * 1.002 / Double(SR)
        let raw = saw(p1) * 0.6 + ((p2 - floor(p2)) < 0.5 ? Float(0.5) : Float(-0.5))
        let fc = Float(180 + (900 + 2400 * Double(vel)) * exp(-s * 22))
        return f.run(raw, fc, 0.45).low * adsr(s, dur, a: 0.002, d: 0.15, sus: 0.7, r: 0.03) * 1.3
    }
}

// MARK: - Keys, mallets, bells

/// Electric piano (two-operator FM: a warm tine plus a bell-like attack).
func ePiano(_ midi: Int, _ dur: Double, vel: Float = 0.8) -> [Float] {
    var pc = 0.0, pm = 0.0, pb = 0.0
    let f = hz(midi)
    return (0..<n(dur + 0.6)).map { i in
        let s = x(i)
        pm += f / Double(SR); pb += f * 14 / Double(SR)
        let index = (1.2 + 1.8 * Double(vel)) * exp(-s * 5)
        pc += f / Double(SR)
        let tone = Float(sin(2 * .pi * pc + index * sin(2 * .pi * pm)))
        let bell = sine(pb) * Float(exp(-s * 40)) * 0.25 * vel
        let trem = Float(1 + 0.08 * sin(2 * .pi * 4.5 * s))
        return (tone + bell) * adsr(s, dur, a: 0.002, d: 1.2, sus: 0.35, r: 0.25) * trem * 0.7
    }
}
func organ(_ midi: Int, _ dur: Double) -> [Float] {
    var p = [Double](repeating: 0, count: 4)
    let f = hz(midi), ratios = [1.0, 2.0, 3.0, 4.0], amps: [Float] = [1, 0.6, 0.35, 0.25]
    return (0..<n(dur + 0.1)).map { i in
        let s = x(i)
        var v: Float = 0
        for k in 0..<4 { p[k] += f * ratios[k] / Double(SR); v += sine(p[k]) * amps[k] }
        let click = s < 0.004 ? noise.next() * 0.3 : 0
        return (v / 2.2 + click) * adsr(s, dur, a: 0.006, d: 0.05, sus: 0.9, r: 0.05)
    }
}
func marimba(_ midi: Int, vel: Float = 1) -> [Float] {
    var p1 = 0.0, p2 = 0.0
    let f = hz(midi)
    return (0..<n(0.7)).map { i in
        let s = x(i)
        p1 += f / Double(SR); p2 += f * 3.93 / Double(SR)
        return (sine(p1) * env(s, attack: 0.001, decay: 7) + sine(p2) * env(s, attack: 0.001, decay: 30) * 0.4) * vel
    }
}
func bell(_ midi: Int, vel: Float = 1, length: Double = 2) -> [Float] {
    var pc = 0.0, pm = 0.0
    let f = hz(midi)
    return (0..<n(length)).map { i in
        let s = x(i)
        pm += f * 3.5 / Double(SR); pc += f / Double(SR)
        let index = 2.4 * exp(-s * 2)
        return Float(sin(2 * .pi * pc + index * sin(2 * .pi * pm))) * env(s, attack: 0.001, decay: 2.2) * vel * 0.6
    }
}
func kalimba(_ midi: Int, vel: Float = 1) -> [Float] {
    var p1 = 0.0, p2 = 0.0
    let f = hz(midi)
    return (0..<n(0.9)).map { i in
        let s = x(i); p1 += f / Double(SR); p2 += f * 6.2 / Double(SR)
        return (sine(p1) * env(s, attack: 0.001, decay: 4.5) + sine(p2) * env(s, attack: 0.001, decay: 40) * 0.5) * vel
    }
}
/// A piano-ish tone: decaying harmonics and a felt hammer.
func piano(_ midi: Int, _ dur: Double, vel: Float = 0.8) -> [Float] {
    var p = [Double](repeating: 0, count: 6)
    let f = hz(midi)
    return (0..<n(dur + 0.8)).map { i in
        let s = x(i)
        var v: Float = 0
        for k in 0..<6 {
            let ratio = Double(k + 1) * (1 + 0.0004 * Double(k * k))       // slight inharmonicity
            p[k] += f * ratio / Double(SR)
            v += sine(p[k]) * Float(exp(-s * (1.6 + Double(k) * 1.4))) / Float(k + 1)
        }
        let hammer = noise.next() * Float(exp(-s * 200)) * 0.15
        return (v * 0.8 + hammer) * vel * adsr(s, dur, a: 0.002, d: 0.01, sus: 1, r: 0.3)
    }
}

// MARK: - Sustained and lead

/// Strings: a soft, slow, wide ensemble.
func strings(_ midi: Int, _ dur: Double) -> [Float] {
    var ph = [Double](repeating: 0, count: 5); var f = SVF()
    let detune = [-12.0, -5, 0, 6, 11]
    for k in 0..<5 { ph[k] = Double(k) * 0.21 }
    return (0..<n(dur + 0.6)).map { i in
        let s = x(i)
        let vib = 1 + 0.004 * sin(2 * .pi * 5.2 * s)
        var v: Float = 0
        for k in 0..<5 { ph[k] += hz(midi) * pow(2, detune[k] / 1200) * vib / Double(SR); v += saw(ph[k]) }
        return f.run(v / 5, 2600, 0.8).low * adsr(s, dur, a: 0.35, d: 0.3, sus: 0.85, r: 0.5)
    }
}
/// Brass: a punchy stab with a filter that opens fast and a small pitch scoop.
func brass(_ midi: Int, _ dur: Double, vel: Float = 1) -> [Float] {
    var ph = [Double](repeating: 0, count: 3); var f = SVF()
    return (0..<n(dur + 0.15)).map { i in
        let s = x(i)
        let scoop = pow(2, -0.6 * exp(-s * 30) / 12)
        var v: Float = 0
        for (k, c) in [-7.0, 0, 7].enumerated() { ph[k] += hz(midi) * pow(2, c / 1200) * scoop / Double(SR); v += saw(ph[k]) }
        let fc = Float(500 + 3200 * Double(vel) * (1 - exp(-s * 40)) * exp(-s * 2.5))
        return tanhf(f.run(v / 3, fc, 0.7).low * 1.6) * adsr(s, dur, a: 0.02, d: 0.2, sus: 0.7, r: 0.08)
    }
}
func supersaw(_ midi: Int, _ dur: Double) -> [Float] {
    var ph = [Double](repeating: 0, count: 7); var f = SVF()
    let det = [-28.0, -18, -8, 0, 8, 18, 28]
    for k in 0..<7 { ph[k] = Double(k) * 0.13 }
    return (0..<n(dur + 0.2)).map { i in
        let s = x(i)
        var v: Float = 0
        for k in 0..<7 { ph[k] += hz(midi) * pow(2, det[k] / 1200) / Double(SR); v += saw(ph[k]) }
        return f.run(v / 5, 6500, 0.6).low * adsr(s, dur, a: 0.005, d: 0.3, sus: 0.75, r: 0.15)
    }
}
/// 8-bit square lead with a quick vibrato.
func chip(_ midi: Int, _ dur: Double, duty: Double = 0.25) -> [Float] {
    var ph = 0.0
    return (0..<n(dur + 0.02)).map { i in
        let s = x(i)
        ph += hz(midi) * (1 + 0.006 * sin(2 * .pi * 6 * max(0, s - 0.15))) / Double(SR)
        let v: Float = (ph - floor(ph)) < duty ? 0.5 : -0.5
        return v * adsr(s, dur, a: 0.001, d: 0.05, sus: 0.8, r: 0.02)
    }
}
/// A plucked string (Karplus–Strong): guitar, harp or koto depending on `bright` and register.
func guitar(_ midi: Int, _ dur: Double, bright: Float = 0.5) -> [Float] {
    let period = max(2, Int(Double(SR) / hz(midi)))
    var buf = (0..<period).map { _ in noise.next() }
    var out = [Float](repeating: 0, count: n(dur + 1.2))
    var idx = 0
    let damp = 0.5 + 0.495 * Double(bright)
    for i in out.indices {
        let a = buf[idx], b = buf[(idx + 1) % period]
        let v = Float(damp) * a + Float(1 - damp) * b
        buf[idx] = v * 0.996
        out[i] = a * (i > n(dur) ? Float(exp(-Double(i - n(dur)) / Double(SR) * 6)) : 1)
        idx = (idx + 1) % period
    }
    return out
}
/// A soft "ooh" pad (formant-filtered saw).
func choir(_ midi: Int, _ dur: Double) -> [Float] {
    var ph = [Double](repeating: 0, count: 3); var f1 = SVF(), f2 = SVF()
    return (0..<n(dur + 0.6)).map { i in
        let s = x(i)
        var v: Float = 0
        for (k, c) in [-6.0, 0, 6].enumerated() { ph[k] += hz(midi) * pow(2, c / 1200) * (1 + 0.003 * sin(2 * .pi * 5 * s)) / Double(SR); v += saw(ph[k]) }
        let o = f1.run(v / 3, 420, 2.2).band * 1.4 + f2.run(v / 3, 820, 2.6).band
        return o * adsr(s, dur, a: 0.4, d: 0.3, sus: 0.85, r: 0.5)
    }
}

// MARK: - Big moments

/// A cinematic low brass "braam" cluster.
func braam(_ midi: Int = 36, length: Double = 2.4) -> [Float] {
    var ph = [Double](repeating: 0, count: 4); var f = SVF()
    let notes = [midi, midi + 7, midi + 12, midi + 3]
    return (0..<n(length)).map { i in
        let s = x(i)
        var v: Float = 0
        for k in 0..<4 { ph[k] += hz(notes[k]) * (1 + 0.003 * Double(k)) / Double(SR); v += saw(ph[k]) }
        let fc = Float(220 + 1800 * (1 - exp(-s * 6)) * exp(-s * 0.9))
        return tanhf(f.run(v / 2.5, fc, 0.6).low * 2.2) * adsr(s, length * 0.7, a: 0.06, d: 0.5, sus: 0.7, r: 0.6)
    }
}
/// A reversed cymbal swell that lands on its end (place it so it ends on the hit).
func reverseCymbal(_ length: Double = 1.2) -> [Float] {
    var f = SVF()
    let c = (0..<n(length)).map { i in f.run(noise.next(), 6000, 0.5).high * Float(exp(-x(i) * 3)) }
    return Array(c.reversed())
}
/// A sub drop: a falling sine boom.
func subDrop(_ length: Double = 1.0) -> [Float] {
    var ph = 0.0
    return (0..<n(length)).map { i in
        let s = x(i); ph += (90 * exp(-s * 2.2) + 30) / Double(SR)
        return tanhf(sine(ph) * 1.8) * Float(min(1, s / 0.01) * exp(-s * 2.4))
    }
}
/// A bed of vinyl crackle and hiss (place under a lo-fi section).
func vinylBed(_ length: Double) -> [Float] {
    var f = SVF(); var g = Noise(s: 9001)
    return (0..<n(length)).map { _ in
        let c = g.next()
        let pop: Float = abs(c) > 0.9997 ? c * 0.5 : 0
        return f.run(g.next(), 3000, 0.6).band * 0.03 + pop
    }
}
