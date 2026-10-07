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
    /// Send to the room (reverb) and to the tempo echo; set by `compose`, or add to them directly.
    let verb = Bus()
    let echo = Bus()
    /// The room, the master's colour, and how hard the groove pumps under the kick.
    var space: Space = .dry
    var colour: Colour = .clean
    var duckDepth: Double = 0.6
    /// Echo length in beats (0.75 = dotted eighth).
    var echoBeats: Double = 0.75
    /// Kick times, for the sidechain duck.
    var kicks: [Double] = []
    /// Ranges where the music goes underwater (low-passed and quieter).
    var muffled: [(from: Double, to: Double)] = []
    /// The tail fades to silence over this range; nil means no fade.
    var fadeOut: (from: Double, to: Double)?
    /// How loud effects sit against the music.
    var sfxLevel: Float = 1.8
    /// `video effects`: only the sound effects, at the level they have in the full mix (for a platform sound or licensed track on top).
    var effectsOnly = false
    var narration: NarrationTrack? = nil
    /// Tape stops (the music slows to a halt over the range) and gates (silence over the range), from tempo changes.
    var stops: [(from: Double, to: Double)] = []
    var gates: [(from: Double, to: Double)] = []
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
        let step = tempoMap.secondsPerBeat(at: at - 0.01) / 4, count = Int(beats * 4)
        for k in 0..<count { music.add(clap(), at: at - Double(count - k) * step, gain: 0.08 + 0.32 * Float(k) / Float(count)) }
    }

    /// Ducks, muffles, masters and writes music.m4a and beats.json into `dir`. Returns the audio URL.
    func finish(to dir: URL, duration: Double) throws -> URL {
        // Tempo changes: tape stops slow the music to a halt; gates leave a beat of silence before the new tempo.
        for s in stops { for bus in [music, ducked, verb, echo] { tapeStop(bus, from: s.from, to: s.to) } }
        for g in gates {
            for bus in [music, ducked, verb, echo] {
                let a = max(0, n(g.from)), z = min(NS, n(g.to)), fade = n(0.006)
                guard z > a else { continue }
                for i in a..<z {
                    let k = Float(min(1, Double(min(i - a, z - 1 - i)) / Double(max(1, fade))))
                    bus.l[i] *= 1 - k; bus.r[i] *= 1 - k
                }
            }
        }
        var duck = [Float](repeating: 1, count: NS)
        for k in kicks {
            let i0 = n(k)
            for j in 0..<n(0.3) where i0 + j < NS && i0 + j >= 0 {
                duck[i0 + j] = min(duck[i0 + j], Float(1 - duckDepth * exp(-x(j) / 0.07)))
            }
        }
        for i in 0..<NS { music.l[i] += ducked.l[i] * duck[i]; music.r[i] += ducked.r[i] * duck[i] }
        applyReverb(verb, into: music, space: space == .dry && verb.l.contains(where: { $0 != 0 }) ? .room : space)
        applyEcho(echo, into: music, bpm: bpm, beats: echoBeats)

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
        var preGain: Float = 1, capGain: Float = 1
        if colour != .clean {
            // Colour expects a signal near full scale: bring the raw mix there first, so saturation is a flavour, not a crush.
            let raw = max(L.map(abs).max() ?? 1, R.map(abs).max() ?? 1, 1e-6)
            let k = 0.85 / raw
            preGain = k
            for i in 0..<NS { L[i] *= k; R[i] *= k }
            applyColour(&L, &R, colour)
        }
        let peak = max(L.map(abs).max() ?? 1, R.map(abs).max() ?? 1, 1e-6)
        for i in 0..<NS {
            let fade = fadeOut.map { Float(1 - prog(x(i), $0.from, $0.to)) } ?? 1
            L[i] = tanhf(1.4 * L[i] / peak) / tanhf(1.4) * 0.92 * fade
            R[i] = tanhf(1.4 * R[i] / peak) / tanhf(1.4) * 0.92 * fade
        }
        if colour != .clean {
            // Coloured mixes (tape, lo-fi…) lose peaks and read louder; cap their loudness so every film sits alike.
            let r = sqrtf((L.map { $0 * $0 }.reduce(0, +) + R.map { $0 * $0 }.reduce(0, +)) / Float(2 * NS))
            if r > 0.2 { let k = 0.2 / r; capGain = k; for i in 0..<NS { L[i] *= k; R[i] *= k } }
        }
        if effectsOnly {
            // The same gains as the full mix, applied to the effects alone, so they sit where they did.
            for i in 0..<NS {
                let fade = fadeOut.map { Float(1 - prog(x(i), $0.from, $0.to)) } ?? 1
                let el = (fx.l[i] + sfxLevel * sfx.l[i]) * preGain, er = (fx.r[i] + sfxLevel * sfx.r[i]) * preGain
                L[i] = tanhf(1.4 * el / peak) / tanhf(1.4) * 0.92 * fade * capGain
                R[i] = tanhf(1.4 * er / peak) / tanhf(1.4) * 0.92 * fade * capGain
            }
        }
        // Levels, so a mix can be checked without ears: muffled stretches should read quieter.
        func rms(_ a: Double, _ z: Double) -> Float {
            let lo = max(0, n(a)), hi = min(NS, n(z))
            guard hi > lo else { return 0 }
            let s = L[lo..<hi]
            return sqrtf(s.map { $0 * $0 }.reduce(0, +) / Float(s.count))
        }
        var report = String(format: "audio%@: peak %.2f · whole-mix rms %.3f", effectsOnly ? " (effects only)" : "", peak, rms(0, duration))
        for m in muffled { report += String(format: " · muffled %.1f–%.1f s rms %.3f (just before %.3f)", m.from, m.to, rms(m.from + 0.2, m.to - 0.2), rms(max(0, m.from - 2), m.from)) }
        print(report)

        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent(effectsOnly ? "effects.m4a" : "music.m4a")
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
        var beatTimes: [Double] = [], b = 0.0
        while tempoMap.time(ofBeat: b) < duration { beatTimes.append(tempoMap.time(ofBeat: b)); b += 1 }
        let beats = Beats(bpm: tempoMap.base, beats: beatTimes, downbeats: stride(from: 0, to: beatTimes.count, by: 4).map { beatTimes[$0] },
                          hits: hits.sorted { $0.t < $1.t })
        let enc = JSONEncoder(); enc.outputFormatting = [.prettyPrinted]
        try enc.encode(beats).write(to: dir.appendingPathComponent("beats.json"))
        if let narration, !effectsOnly {
            let mix = narration.mix(bedLeft: L, bedRight: R)
            let final = dir.appendingPathComponent("mix.m4a")
            try VoiceAudio.write(mix.left, mix.right, to: final)
            try VoiceAudio.write(mix.voiceLeft, mix.voiceRight, to: dir.appendingPathComponent("narration.m4a"))
            try narration.subtitles().write(to: dir.appendingPathComponent("captions.srt"), atomically: true, encoding: .utf8)
            print("narration: approved take mixed; music.m4a remains the unducked bed")
            return final
        }
        return url
    }
}

/// A tape stop: over `from…to` the music slows to a halt, pitch falling with it, as when a turntable's power is cut.
func tapeStop(_ bus: Bus, from t0: Double, to t1: Double) {
    let a = max(0, n(t0)), z = min(NS, n(t1))
    guard z > a + 32 else { return }
    let srcL = Array(bus.l[a..<z]), srcR = Array(bus.r[a..<z])
    let span = Double(z - a)
    var pos = 0.0
    for k in 0..<(z - a) {
        let i = Int(pos), f = Float(pos - Double(i))
        let l0 = i < srcL.count ? srcL[i] : 0, l1 = i + 1 < srcL.count ? srcL[i + 1] : 0
        let r0 = i < srcR.count ? srcR[i] : 0, r1 = i + 1 < srcR.count ? srcR[i + 1] : 0
        let tail = Float(min(1, (span - Double(k)) / (span * 0.15)))         // fade the last stretch to nothing
        bus.l[a + k] = (l0 + (l1 - l0) * f) * tail
        bus.r[a + k] = (r0 + (r1 - r0) * f) * tail
        pos += 1 - Double(k) / span                                          // the playback rate falls from 1 to 0
    }
}
