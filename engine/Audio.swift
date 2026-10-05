// motionable engine: an original score and sound effects, synthesised from scratch.
// Instruments return mono sample arrays; a `Score` mixes them onto buses, ducks the groove under
// the kick, muffles ranges ("underwater"), masters, and writes music.m4a + beats.json.
import AVFoundation

let SR = 48000
/// Samples in the film; set by the engine from the film's duration.
var NS = 0

final class Bus {
    var l = [Float](repeating: 0, count: NS), r = [Float](repeating: 0, count: NS)
    func add(_ s: [Float], at t: Double, gain: Float, pan: Float = 0) {
        let i0 = Int(t * Double(SR))
        let gl = gain * min(1, 1 - pan), gr = gain * min(1, 1 + pan)
        for (j, v) in s.enumerated() {
            let i = i0 + j
            if i >= NS { break }
            if i >= 0 { l[i] += v * gl; r[i] += v * gr }
        }
    }
}
struct Noise { var s: UInt32; mutating func next() -> Float { s = s &* 1664525 &+ 1013904223; return Float(s >> 8) / 8388608 - 1 } }
var noise = Noise(s: 12345)
struct SVF {
    var low: Float = 0, band: Float = 0
    mutating func run(_ x: Float, _ fc: Float, _ q: Float = 0.7) -> (low: Float, band: Float, high: Float) {
        let f = 2 * sinf(.pi * min(fc, 7000) / Float(SR))
        let high = x - low - q * band
        band += f * high
        low += f * band
        return (low, band, high)
    }
}
func hz(_ midi: Int) -> Double { 440 * pow(2, Double(midi - 69) / 12) }
func saw(_ ph: Double) -> Float { Float(2 * (ph - floor(ph)) - 1) }
func n(_ secs: Double) -> Int { Int(secs * Double(SR)) }
func x(_ i: Int) -> Double { Double(i) / Double(SR) }

// MARK: - Instruments

func kick(deep: Bool = false) -> [Float] {
    var out = [Float](repeating: 0, count: n(deep ? 0.9 : 0.42)); var ph = 0.0
    for i in out.indices {
        let s = x(i)
        ph += 2 * .pi * ((deep ? 36 : 47) + 125 * exp(-s * 26)) / Double(SR)
        var v = Float(sin(ph) * exp(-s * (deep ? 3.6 : 7.5)))
        if s < 0.004 { v += noise.next() * 0.35 * Float(1 - s / 0.004) }
        out[i] = tanhf(v * 1.6)
    }
    return out
}
func clap() -> [Float] {
    var out = [Float](repeating: 0, count: n(0.28)); var f = SVF()
    for i in out.indices {
        let s = x(i)
        var env = 0.0
        for o in [0, 0.011, 0.022] where s >= o { env = max(env, exp(-(s - o) * 170)) }
        env = max(env, 0.55 * exp(-s * 15))
        out[i] = f.run(noise.next(), 1350, 0.9).band * Float(env) * 1.6
    }
    return out
}
func hat(open: Bool = false) -> [Float] {
    var out = [Float](repeating: 0, count: n(open ? 0.35 : 0.07)); var f = SVF()
    for i in out.indices { out[i] = f.run(noise.next(), 7000, 0.5).high * Float(exp(-x(i) * (open ? 11 : 65))) }
    return out
}
func bassNote(_ midi: Int, _ dur: Double) -> [Float] {
    var out = [Float](repeating: 0, count: n(dur + 0.04)); var f = SVF(); var p1 = 0.0, p2 = 0.0
    let fr = hz(midi)
    for i in out.indices {
        let s = x(i)
        p1 += fr / Double(SR); p2 += fr / 2 / Double(SR)
        let raw = saw(p1) * 0.7 + Float(sin(2 * .pi * p2)) * 0.6
        let fc = Float(160 + 1300 * exp(-s * 13))
        let amp = Float(min(1, s / 0.004) * (s < dur ? 1 : exp(-(s - dur) * 60)))
        out[i] = f.run(raw, fc, 0.6).low * amp
    }
    return out
}
func chordVoice(_ notes: [Int], dur: Double, attack: Double, cutoff: (Double) -> Double, decay: Double) -> [Float] {
    var out = [Float](repeating: 0, count: n(dur)); var f = SVF()
    var phases = [Double](repeating: 0, count: notes.count * 3)
    for (j, _) in phases.enumerated() { phases[j] = Double(j) * 0.37 }
    for i in out.indices {
        let s = x(i)
        var v: Float = 0
        for (k, m) in notes.enumerated() {
            for (d, cents) in [-9.0, 0, 9].enumerated() {
                let j = k * 3 + d
                phases[j] += hz(m) * pow(2, cents / 1200) / Double(SR)
                v += saw(phases[j])
            }
        }
        v /= Float(notes.count * 3)
        let amp = Float(min(1, s / attack) * exp(-s * decay) * min(1, (dur - s) / 0.06))
        out[i] = f.run(v, Float(cutoff(s)), 0.75).low * amp
    }
    return out
}
func stab(_ notes: [Int]) -> [Float] { chordVoice(notes, dur: 0.5, attack: 0.004, cutoff: { 500 + 3800 * exp(-$0 * 7) }, decay: 4.5) }
func pad(_ notes: [Int], _ dur: Double) -> [Float] { chordVoice(notes, dur: dur, attack: 0.08, cutoff: { _ in 1300 }, decay: 0.15) }
func pluck(_ midi: Int) -> [Float] {
    var out = [Float](repeating: 0, count: n(0.3)); var f = SVF(); var ph = 0.0
    for i in out.indices {
        let s = x(i)
        ph += hz(midi) / Double(SR)
        let sq: Float = (ph - floor(ph)) < 0.5 ? 1 : -1
        out[i] = f.run(sq * 0.6 + saw(ph) * 0.4, Float(350 + 4200 * exp(-s * 24)), 0.6).low * Float(exp(-s * 11))
    }
    return out
}
func riser(_ dur: Double) -> [Float] {
    var out = [Float](repeating: 0, count: n(dur)); var f = SVF(); var ph = 0.0
    for i in out.indices {
        let p = x(i) / dur
        ph += (180 + 700 * p * p) / Double(SR)
        let v = f.run(noise.next(), Float(300 * pow(20, p)), 0.5).band * 1.4 + Float(sin(2 * .pi * ph)) * 0.12
        out[i] = v * Float(p * p)
    }
    return out
}
func crash() -> [Float] {
    var out = [Float](repeating: 0, count: n(2.2)); var f = SVF()
    for i in out.indices { out[i] = f.run(noise.next(), 5200, 0.6).high * Float(exp(-x(i) * 2.4)) }
    return out
}
func impact() -> [Float] {
    var out = kick(deep: true); var f = SVF(); var ph = 0.0
    out += [Float](repeating: 0, count: n(1.6) - out.count)
    for i in out.indices {
        let s = x(i)
        ph += 41 / Double(SR)
        out[i] += f.run(noise.next(), 700, 0.8).low * Float(exp(-s * 7)) * 0.9 + Float(sin(2 * .pi * ph) * exp(-s * 2.2)) * 0.5
    }
    return out
}

// MARK: - Sound effects

func click() -> [Float] { (0..<n(0.03)).map { i in Float(sin(2 * .pi * 2600 * x(i)) * exp(-x(i) * 380)) + noise.next() * Float(exp(-x(i) * 900)) * 0.3 } }
func keyTap() -> [Float] {
    var f = SVF()
    return (0..<n(0.03)).map { i in f.run(noise.next(), 3200, 0.5).band * Float(exp(-x(i) * 260)) }
}
func pop(_ base: Double = 520) -> [Float] {
    var ph = 0.0
    return (0..<n(0.13)).map { i in
        ph += (base + base * 1.7 * min(1, x(i) / 0.035)) / Double(SR)
        return Float(sin(2 * .pi * ph) * exp(-x(i) * 42))
    }
}
func ding() -> [Float] {
    (0..<n(1.1)).map { (i: Int) -> Float in
        let s: Double = x(i)
        let w: Double = 2 * Double.pi * s
        let tone: Double = sin(w * 1318.5) + 0.55 * sin(w * 1975.5) + 0.2 * sin(w * 2637)
        let env: Double = min(1, s / 0.003) * exp(-s * 4.2)
        return Float(tone * env)
    }
}
func whoosh(_ dur: Double = 0.42, up: Bool = true) -> [Float] {
    var f = SVF()
    return (0..<n(dur)).map { i in
        let p = x(i) / dur
        let fc = up ? 300 + 2600 * sin(.pi * p * 0.9) : 2400 - 2100 * p
        return f.run(noise.next(), Float(fc), 0.7).band * Float(pow(sin(.pi * p), 1.5)) * 1.3
    }
}
func powerDown() -> [Float] {
    var ph = 0.0
    return (0..<n(0.45)).map { i in
        let p = x(i) / 0.45
        ph += (620 * pow(0.13, p)) / Double(SR)
        return Float(sin(2 * .pi * ph) * (1 - p) * min(1, x(i) / 0.005))
    }
}
func stampHit() -> [Float] {
    var f = SVF(); var ph = 0.0
    return (0..<n(0.26)).map { i in
        let s = x(i)
        ph += (65 + 90 * exp(-s * 30)) / Double(SR)
        return Float(sin(2 * .pi * ph) * exp(-s * 13)) + f.run(noise.next(), 1000, 0.7).band * Float(exp(-s * 55)) * 0.9
    }
}
func thumpSnd() -> [Float] {
    (0..<n(0.8)).map { (i: Int) -> Float in
        let s: Double = x(i)
        let w: Double = 2 * Double.pi * s
        let tone: Double = sin(w * 55) + 0.4 * sin(w * 110)
        return Float(tone * exp(-s * 5) * min(1, s / 0.002))
    }
}

/// The kick, under a name that a Score's own `kick(at:)` can't shadow.
func motionable_kick() -> [Float] { kick() }
