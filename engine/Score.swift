// motionable engine: the Score. A film's `score` closure fills its buses with instruments and
// sound effects on the film's own times; `finish` ducks, muffles, masters and writes the files.
import AVFoundation

struct Hit: Encodable { let t: Double; let what: String }

final class Score {
    let bpm: Double
    /// Drums, stabs, impacts, crashes. Muffled ranges apply here.
    let music = Bus()
    /// Bass, pads, arpeggios: ducked under every kick, then added to `music`.
    let ducked = Bus()
    /// Risers and sweeps: never muffled, so a build is heard coming out of an "underwater" stretch.
    let fx = Bus()
    /// Sound effects tied to picture events.
    let sfx = Bus()
    /// Kick times, for the sidechain duck.
    var kicks: [Double] = []
    /// Ranges where the music goes underwater (low-passed and quieter).
    var muffled: [(from: Double, to: Double)] = []
    /// The tail fades to silence over this range; nil means no fade.
    var fadeOut: (from: Double, to: Double)?
    /// How loud effects sit against the music.
    var sfxLevel: Float = 1.8
    private(set) var hits: [Hit] = []

    init(bpm: Double) { self.bpm = bpm }
    var beat: Double { 60 / bpm }

    /// A sound effect on a picture event, logged in beats.json.
    func cue(_ t: Double, _ what: String, _ s: [Float], _ gain: Float, pan: Float = 0, bus: Bus? = nil) {
        (bus ?? sfx).add(s, at: t, gain: gain, pan: pan)
        hits.append(Hit(t: t, what: what))
    }
    func kick(at t: Double, gain: Float = 0.95) { kicks.append(t); music.add(motionable_kick(), at: t, gain: gain) }

    /// A ready-made four-on-the-floor groove: kick, offbeat hats, claps on 2 and 4, a pumping
    /// offbeat bass, a 16th-note arpeggio and a pad, one chord per bar.
    /// `chords` are MIDI triads, `roots` the bass note per chord; `full` is when the claps,
    /// 16th hats and offbeat bass come in (before it, the groove is a lighter build).
    func groove(from: Double, to: Double, chords: [[Int]], roots: [Int], full: Double) {
        let b = beat, barLen = 4 * b
        func chordAt(_ t: Double) -> Int { Int(floor(t / barLen + 1e-9)) % chords.count }
        for t in stride(from: from, to: to, by: b) {
            kick(at: t)
            music.add(hat(), at: t + b / 2, gain: 0.22)
            let idx = Int((t / b).rounded())
            if t >= full {
                music.add(hat(), at: t + b / 4, gain: 0.08); music.add(hat(), at: t + 3 * b / 4, gain: 0.08)
                if idx % 4 == 1 || idx % 4 == 3 { music.add(clap(), at: t, gain: 0.42) }
                ducked.add(bassNote(roots[chordAt(t)], 0.4 * b), at: t + b / 2, gain: 0.5)
            } else {
                ducked.add(bassNote(roots[chordAt(t)], 0.4 * b), at: t, gain: 0.32)
                ducked.add(bassNote(roots[chordAt(t)], 0.4 * b), at: t + b / 2, gain: 0.26)
            }
            let ch = chords[chordAt(t)]
            let pattern = [ch[0] + 12, ch[1] + 12, ch[2] + 12, ch[1] + 24]
            for k in 0..<4 { ducked.add(pluck(pattern[(idx * 4 + k) % 4]), at: t + Double(k) * b / 4, gain: t >= full ? 0.13 : 0.1) }
        }
        for t in stride(from: from, to: to, by: barLen) { ducked.add(pad(chords[chordAt(t)], barLen), at: t, gain: 0.22) }
    }
    /// A 16th-note snare roll that builds into `at`.
    func roll(into at: Double, beats: Double = 1) {
        let step = beat / 4, count = Int(beats * 4)
        for k in 0..<count { music.add(clap(), at: at - Double(count - k) * step, gain: 0.08 + 0.32 * Float(k) / Float(count)) }
    }

    /// Ducks, muffles, masters and writes music.m4a and beats.json into `dir`. Returns the audio URL.
    func finish(to dir: URL, duration: Double) throws -> URL {
        var duck = [Float](repeating: 1, count: NS)
        for k in kicks {
            let i0 = n(k)
            for j in 0..<n(0.3) where i0 + j < NS && i0 + j >= 0 {
                duck[i0 + j] = min(duck[i0 + j], Float(1 - 0.6 * exp(-x(j) / 0.07)))
            }
        }
        for i in 0..<NS { music.l[i] += ducked.l[i] * duck[i]; music.r[i] += ducked.r[i] * duck[i] }

        if !muffled.isEmpty {
            var fl = SVF(), fr = SVF()
            for i in 0..<NS {
                let s = x(i)
                var w = 0.0
                for m in muffled { w = max(w, prog(s, m.from, m.from + 0.12) * (1 - prog(s, m.to - 0.1, m.to))) }
                let lo = fl.run(music.l[i], 320, 0.8).low, ro = fr.run(music.r[i], 320, 0.8).low
                let k = Float(w)
                music.l[i] = music.l[i] * (1 - k) + lo * k * 0.6
                music.r[i] = music.r[i] * (1 - k) + ro * k * 0.6
            }
        }

        var L = [Float](repeating: 0, count: NS), R = L
        for i in 0..<NS {
            L[i] = music.l[i] + fx.l[i] + sfxLevel * sfx.l[i]
            R[i] = music.r[i] + fx.r[i] + sfxLevel * sfx.r[i]
        }
        let peak = max(L.map(abs).max() ?? 1, R.map(abs).max() ?? 1, 1e-6)
        for i in 0..<NS {
            let fade = fadeOut.map { Float(1 - prog(x(i), $0.from, $0.to)) } ?? 1
            L[i] = tanhf(1.4 * L[i] / peak) / tanhf(1.4) * 0.92 * fade
            R[i] = tanhf(1.4 * R[i] / peak) / tanhf(1.4) * 0.92 * fade
        }
        // Levels, so a mix can be checked without ears: muffled stretches should read quieter.
        func rms(_ a: Double, _ z: Double) -> Float {
            let lo = max(0, n(a)), hi = min(NS, n(z))
            guard hi > lo else { return 0 }
            let s = L[lo..<hi]
            return sqrtf(s.map { $0 * $0 }.reduce(0, +) / Float(s.count))
        }
        var report = String(format: "audio: peak %.2f · whole-mix rms %.3f", peak, rms(0, duration))
        for m in muffled { report += String(format: " · muffled %.1f–%.1f s rms %.3f (just before %.3f)", m.from, m.to, rms(m.from + 0.2, m.to - 0.2), rms(max(0, m.from - 2), m.from)) }
        print(report)

        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("music.m4a")
        try? FileManager.default.removeItem(at: url)
        let fmt = AVAudioFormat(standardFormatWithSampleRate: Double(SR), channels: 2)!
        let file = try AVAudioFile(forWriting: url, settings: [AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: SR,
                                                                AVNumberOfChannelsKey: 2, AVEncoderBitRateKey: 256_000],
                                   commonFormat: .pcmFormatFloat32, interleaved: false)
        let buf = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: AVAudioFrameCount(NS))!
        buf.frameLength = AVAudioFrameCount(NS)
        for i in 0..<NS { buf.floatChannelData![0][i] = L[i]; buf.floatChannelData![1][i] = R[i] }
        try file.write(from: buf)

        struct Beats: Encodable { let bpm: Double; let beats: [Double]; let downbeats: [Double]; let hits: [Hit] }
        let beats = Beats(bpm: bpm, beats: Array(stride(from: 0.0, to: duration, by: beat)),
                          downbeats: Array(stride(from: 0.0, to: duration, by: 4 * beat)), hits: hits.sorted { $0.t < $1.t })
        let enc = JSONEncoder(); enc.outputFormatting = [.prettyPrinted]
        try enc.encode(beats).write(to: dir.appendingPathComponent("beats.json"))
        return url
    }
}
