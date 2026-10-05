// motionable engine: audio effects. Reverb (space), echo, and master "colour" (tape, lo-fi, crushed, bright).
import Foundation

/// How big the room sounds.
enum Space { case dry, room, studio, hall, cathedral
    var size: Float { switch self { case .dry: return 0; case .room: return 0.55; case .studio: return 0.68; case .hall: return 0.82; case .cathedral: return 0.92 } }
    var wet: Float { switch self { case .dry: return 0; case .room: return 0.18; case .studio: return 0.24; case .hall: return 0.32; case .cathedral: return 0.42 } }
}
/// The master's character.
enum Colour { case clean, tape, lofi, crushed, bright, warm }

/// Freeverb-style stereo reverb (8 combs + 4 all-passes per side).
struct Reverb {
    private var combs: [[Float]], combIdx: [Int], combStore: [Float]
    private var aps: [[Float]], apIdx: [Int]
    let size: Float, damp: Float
    init(size: Float, damp: Float = 0.3, spread: Int = 0) {
        let scale = Double(SR) / 44100
        let c = [1116, 1188, 1277, 1356, 1422, 1491, 1557, 1617].map { Int(Double($0 + spread) * scale) }
        let a = [556, 441, 341, 225].map { Int(Double($0 + spread) * scale) }
        combs = c.map { [Float](repeating: 0, count: $0) }; combIdx = c.map { _ in 0 }; combStore = c.map { _ in 0 }
        aps = a.map { [Float](repeating: 0, count: $0) }; apIdx = a.map { _ in 0 }
        self.size = 0.7 + size * 0.28; self.damp = damp
    }
    mutating func run(_ x: Float) -> Float {
        var out: Float = 0
        let input = x * 0.015
        for k in 0..<combs.count {
            let i = combIdx[k]
            let y = combs[k][i]
            combStore[k] = y * (1 - damp) + combStore[k] * damp
            combs[k][i] = input + combStore[k] * size
            combIdx[k] = (i + 1) % combs[k].count
            out += y
        }
        for k in 0..<aps.count {
            let i = apIdx[k]
            let b = aps[k][i]
            aps[k][i] = out + b * 0.5
            out = b - out
            apIdx[k] = (i + 1) % aps[k].count
        }
        return out
    }
}

func applyReverb(_ send: Bus, into dest: Bus, space: Space) {
    guard space != .dry, send.l.contains(where: { $0 != 0 }) || send.r.contains(where: { $0 != 0 }) else { return }
    var rl = Reverb(size: space.size), rr = Reverb(size: space.size, spread: 23)
    let wet = space.wet * 3.2
    for i in 0..<NS {
        let m = (send.l[i] + send.r[i]) * 0.5
        dest.l[i] += rl.run(m + send.l[i] * 0.3) * wet
        dest.r[i] += rr.run(m + send.r[i] * 0.3) * wet
    }
}

/// Ping-pong echo: `beats` long at the film's tempo, darkening as it repeats.
func applyEcho(_ send: Bus, into dest: Bus, bpm: Double, beats: Double = 0.75, feedback: Float = 0.42) {
    guard send.l.contains(where: { $0 != 0 }) || send.r.contains(where: { $0 != 0 }) else { return }
    let d = max(1, Int(60 / bpm * beats * Double(SR)))
    var bl = [Float](repeating: 0, count: d), br = [Float](repeating: 0, count: d)
    var idx = 0, lpL: Float = 0, lpR: Float = 0
    for i in 0..<NS {
        let yl = bl[idx], yr = br[idx]
        lpL += (yr - lpL) * 0.35; lpR += (yl - lpR) * 0.35        // cross-fed: ping-pong, with a gentle low-pass
        bl[idx] = (send.l[i] + send.r[i]) * 0.5 + lpL * feedback
        br[idx] = lpR * feedback
        idx = (idx + 1) % d
        dest.l[i] += yl * 0.5; dest.r[i] += yr * 0.5
    }
}

/// Master colour on the final stereo mix.
func applyColour(_ L: inout [Float], _ R: inout [Float], _ c: Colour) {
    switch c {
    case .clean: return
    case .tape:
        // Wow and flutter through a modulated delay, soft saturation, a gentle top roll-off, a little hiss.
        let maxD = 400
        var bufL = [Float](repeating: 0, count: maxD), bufR = bufL
        var w = 0
        var f1 = SVF(), f2 = SVF()
        var hiss = Noise(s: 4242)
        for i in 0..<L.count {
            bufL[w] = L[i]; bufR[w] = R[i]
            let s = x(i)
            let dly = 120 + 90 * sin(2 * .pi * 0.55 * s) + 14 * sin(2 * .pi * 6.1 * s)
            let rp = Double(w) - dly
            let i0 = Int(floor(rp)), fr = Float(rp - floor(rp))
            func tap(_ b: [Float]) -> Float { let a = b[(i0 % maxD + maxD) % maxD], z = b[((i0 + 1) % maxD + maxD) % maxD]; return a + (z - a) * fr }
            let l = tanhf(tap(bufL) * 1.25) / 1.1, r = tanhf(tap(bufR) * 1.25) / 1.1
            L[i] = f1.run(l, 11_000, 0.7).low + hiss.next() * 0.0025
            R[i] = f2.run(r, 11_000, 0.7).low + hiss.next() * 0.0025
            w = (w + 1) % maxD
        }
    case .lofi:
        // Dark, crunchy, a touch of vinyl.
        var f1 = SVF(), f2 = SVF(), hp1 = SVF(), hp2 = SVF()
        var crackle = Noise(s: 777)
        var holdL: Float = 0, holdR: Float = 0
        for i in 0..<L.count {
            if i % 2 == 0 { holdL = L[i]; holdR = R[i] }                           // half sample rate
            let q: Float = 512                                                      // ~10-bit
            var l = (holdL * q).rounded() / q, r = (holdR * q).rounded() / q
            l = f1.run(l, 4200, 0.8).low; r = f2.run(r, 4200, 0.8).low
            l = hp1.run(l, 90, 0.7).high; r = hp2.run(r, 90, 0.7).high
            let c = crackle.next()
            let pop: Float = abs(c) > 0.9993 ? c * 0.12 : 0
            L[i] = l + pop + crackle.next() * 0.002
            R[i] = r + pop + crackle.next() * 0.002
        }
    case .crushed:
        for i in 0..<L.count { L[i] = max(-0.8, min(0.8, tanhf(L[i] * 2.6))); R[i] = max(-0.8, min(0.8, tanhf(R[i] * 2.6))) }
    case .bright:
        // A gentle high shelf: add back some of the highs.
        var h1 = SVF(), h2 = SVF()
        for i in 0..<L.count { L[i] += h1.run(L[i], 5500, 0.7).high * 0.35; R[i] += h2.run(R[i], 5500, 0.7).high * 0.35 }
    case .warm:
        var l1 = SVF(), l2 = SVF()
        for i in 0..<L.count {
            L[i] = tanhf(l1.run(L[i], 7000, 0.7).low * 1.15); R[i] = tanhf(l2.run(R[i], 7000, 0.7).low * 1.15)
        }
    }
}
