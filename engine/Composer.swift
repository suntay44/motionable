// motionable engine: the Composer. A film's direction writes a Recipe — tempo, feel, key, mode, chords, drum
// patterns and instrument parts — and a list of Sections with energy levels; the Composer plays it onto the Score.
// Nothing here is a preset: every value comes from the film's DIRECTION.md.
//
// Patterns are strings, 16 steps per bar (they loop, so 32 or 64 characters make 2- or 4-bar patterns):
//   X accent · x hit · o soft · - ghost · . rest · _ hold the previous note · 2/3/4/6 a roll of that many hits in the step
import Foundation

enum Mode {
    case major, minor, dorian, mixolydian, lydian, phrygian, harmonicMinor, majorPentatonic, minorPentatonic, blues
    /// The scale chords are built from.
    var harmony: [Int] {
        switch self {
        case .major, .majorPentatonic: return [0, 2, 4, 5, 7, 9, 11]
        case .minor, .minorPentatonic, .blues: return [0, 2, 3, 5, 7, 8, 10]
        case .dorian: return [0, 2, 3, 5, 7, 9, 10]
        case .mixolydian: return [0, 2, 4, 5, 7, 9, 10]
        case .lydian: return [0, 2, 4, 6, 7, 9, 11]
        case .phrygian: return [0, 1, 3, 5, 7, 8, 10]
        case .harmonicMinor: return [0, 2, 3, 5, 7, 8, 11]
        }
    }
    /// The scale melodies are drawn from.
    var melody: [Int] {
        switch self {
        case .majorPentatonic: return [0, 2, 4, 7, 9]
        case .minorPentatonic: return [0, 3, 5, 7, 10]
        case .blues: return [0, 3, 5, 6, 7, 10]
        default: return harmony
        }
    }
}
enum ChordColour { case triad, seventh, add9, ninth, sus2, sus4, power }
/// The drum sounds' character.
enum Kit { case clean, punchy, lofi, trap, acoustic, cinematic, electro }

struct Drums {
    var kick = "", snare = "", clap = "", hat = "", openHat = "", rim = "", shaker = "", tamb = "", cowbell = "", clave = "", conga = "", tom = ""
}
enum Synth { case sub, eight08, funk, sawBass, pluck, ePiano, organ, marimba, bell, kalimba, piano, strings, brass, supersaw, chip, guitar, pad, choir, stab }
enum Notes {
    case root, rootFifth, octaves, chord, arpUp, arpDown, arpUpDown, arpRandom, motif, walk
    case line([Int])                 // explicit scale degrees (1 = tonic), cycled per hit — for hooks
}
struct Part {
    var synth: Synth
    var rhythm: String
    var notes: Notes = .root
    var octave: Int = 3              // MIDI octave of the part (C4 = 60 is octave 4)
    var gain: Float = 0.3
    var pan: Float = 0
    var reverb: Float = 0.15         // send to the room
    var echo: Float = 0              // send to the tempo echo
    var ducked = true                // pumps under the kick
    var from = 1                     // plays in sections with energy ≥ this
}
struct Recipe {
    var bpm: Double
    var swing: Double = 0            // 0…0.6 — delays every off-16th by this share of a 16th
    var key: Int = 0                 // tonic pitch class: 0 C, 2 D, 4 E, 5 F, 7 G, 9 A, 11 B (+1 for sharps)
    var mode: Mode = .major
    var progression: [Int] = [1, 5, 6, 4]
    var barsPerChord: Int = 1
    var meter: Int = 16              // 16ths per bar: 16 = 4/4, 12 = 3/4 (a waltz or lullaby), 20 = 5/4; patterns should match it
    var chordColour: ChordColour = .triad
    var kit: Kit = .clean
    var drums = Drums()
    var parts: [Part] = []
    var space: Space = .room
    var colour: Colour = .clean
    var sidechain: Double = 0.55
    var seed: Int = 1
}
/// A stretch of the film with an energy level: 0 ambient · 1 light · 2 groove · 3 full.
struct Section {
    var from: Double
    var to: Double
    var energy: Int
    var muffled = false
    var fill = true                  // false: a rise in energy arrives softly (a swell; no drum fill, riser or crash)
}

/// Sums sounds into one, as long as the longest.
func mixDown(_ sounds: [[Float]]) -> [Float] {
    var out = [Float](repeating: 0, count: sounds.map(\.count).max() ?? 0)
    for s in sounds { for (i, v) in s.enumerated() { out[i] += v } }
    return out
}

// MARK: - Harmony

func noteOf(_ r: Recipe, degree: Int, octave: Int, melody: Bool = false) -> Int {
    let steps = melody ? r.mode.melody : r.mode.harmony
    let d = degree - 1
    let o = Int(floor(Double(d) / Double(steps.count)))
    let idx = ((d % steps.count) + steps.count) % steps.count
    return 12 * (octave + 1) + r.key + steps[idx] + 12 * o
}
/// Chord tones (MIDI) for a scale degree, voiced near the part's octave.
func chordTones(_ r: Recipe, degree: Int, octave: Int) -> [Int] {
    let offsets: [Int]
    switch r.chordColour {
    case .triad: offsets = [0, 2, 4]
    case .seventh: offsets = [0, 2, 4, 6]
    case .add9: offsets = [0, 2, 4, 8]
    case .ninth: offsets = [0, 2, 4, 6, 8]
    case .sus2: offsets = [0, 1, 4]
    case .sus4: offsets = [0, 3, 4]
    case .power: offsets = [0, 4, 7]
    }
    let centre = 12 * (octave + 1) + r.key + 6
    return offsets.map { off -> Int in
        var m = noteOf(r, degree: degree + off, octave: octave)
        while m < centre - 7 { m += 12 }
        while m >= centre + 7 { m -= 12 }
        return m
    }.sorted()
}

private func velocity(_ c: Character) -> Float? {
    switch c { case "X": return 1; case "x": return 0.8; case "o": return 0.55; case "-": return 0.3; default: return nil }
}

extension Score {
    /// Plays a recipe over the sections onto this score (and sets its room, colour and pump).
    func compose(_ r: Recipe, _ sections: [Section]) {
        space = r.space; colour = r.colour; duckDepth = r.sidechain
        let step = 60 / r.bpm / 4, meter = max(4, r.meter), bar = step * Double(meter)
        var g = Seeded(UInt64(r.seed) &* 7919 &+ 3)
        var drumCache: [String: [Float]] = [:]

        func drum(_ voice: String) -> [Float] {
            let key = voice
            if let d = drumCache[key] { return d }
            let s: [Float]
            switch (voice, r.kit) {
            case ("kick", .cinematic): s = tom(1, pitch: 55, big: true)
            case ("kick", .trap), ("kick", .punchy), ("kick", .electro): s = motionable_kick().map { tanhf($0 * 1.5) }
            case ("kick", .lofi): s = motionable_kick().map { $0 * 0.85 }
            case ("kick", _): s = motionable_kick()
            case ("snare", .lofi): s = snare(1, tone: 200, snap: 0.7)
            case ("snare", .trap), ("snare", .electro): s = mixDown([snare(1, snap: 1.3), clap()])
            case ("snare", .cinematic): s = snare(1, tone: 160, snap: 0.6)
            case ("snare", _): s = snare()
            case ("clap", _): s = clap()
            case ("hat", .lofi): s = hat().map { $0 * 0.7 }
            case ("hat", _): s = hat()
            case ("openHat", _): s = hat(open: true)
            case ("rim", _): s = rim()
            case ("shaker", _): s = shaker()
            case ("tamb", _): s = tambourine()
            case ("cowbell", _): s = cowbell()
            case ("clave", _): s = clave()
            case ("conga", _): s = conga()
            case ("tom", .cinematic): s = tom(1, pitch: 70, big: true)
            case ("tom", _): s = tom()
            default: s = []
            }
            drumCache[key] = s
            return s
        }
        let drumLevels: [(String, String, Float, Int, Float)] = [   // voice, pattern, gain, min energy, reverb send
            ("kick", r.drums.kick, 0.95, 2, 0), ("snare", r.drums.snare, 0.55, 2, 0.25), ("clap", r.drums.clap, 0.42, 2, 0.2),
            ("hat", r.drums.hat, 0.2, 1, 0.05), ("openHat", r.drums.openHat, 0.14, 3, 0.1), ("rim", r.drums.rim, 0.3, 1, 0.15),
            ("shaker", r.drums.shaker, 0.22, 1, 0.08), ("tamb", r.drums.tamb, 0.16, 3, 0.1), ("cowbell", r.drums.cowbell, 0.18, 3, 0.15),
            ("clave", r.drums.clave, 0.22, 1, 0.12), ("conga", r.drums.conga, 0.35, 2, 0.15), ("tom", r.drums.tom, 0.5, 3, 0.3)]

        func swung(_ i: Int) -> Double { Double(i) * step + (i % 2 == 1 ? r.swing * step : 0) }

        // Drums.
        for sec in sections where sec.energy > 0 {
            let i0 = Int((sec.from / step).rounded()), i1 = Int((sec.to / step).rounded())
            for (voice, pattern, gain, minE, send) in drumLevels where !pattern.isEmpty && sec.energy >= minE {
                let pat = Array(pattern)
                for i in i0..<i1 {
                    let c = pat[i % pat.count]
                    let t = swung(i)
                    if let v = velocity(c) {
                        let s = drum(voice)
                        music.add(s, at: t, gain: gain * v, pan: voice == "hat" ? 0.15 : (voice == "shaker" ? -0.2 : 0))
                        if send > 0 { verb.add(s, at: t, gain: gain * v * send) }
                        if voice == "kick" { kicks.append(t) }
                    } else if let rolls = c.wholeNumberValue, rolls > 1 {
                        let s = drum(voice)
                        for k in 0..<rolls { music.add(s, at: t + step * Double(k) / Double(rolls), gain: gain * 0.7, pan: 0.15) }
                    }
                }
            }
        }

        // Pitched parts.
        let motifLen = meter
        var motif = [Int](repeating: 0, count: motifLen)
        var walkStep = 0
        for k in 0..<motifLen { walkStep = max(-2, min(5, walkStep + g.pick([-2, -1, -1, 0, 1, 1, 2]))); motif[k] = walkStep }
        for part in r.parts {
            let pat = Array(part.rhythm)
            guard !pat.isEmpty else { continue }
            var hit = 0, prevNote: Int? = nil
            for sec in sections where sec.energy >= part.from {
                let i0 = Int((sec.from / step).rounded()), i1 = Int((sec.to / step).rounded())
                for i in i0..<i1 {
                    guard let v = velocity(pat[i % pat.count]) else { continue }
                    var holds = 1
                    while holds < pat.count && pat[(i + holds) % pat.count] == "_" { holds += 1 }
                    let t = swung(i)
                    let dur = step * Double(holds) * 0.92
                    let barIndex = Int(floor(Double(i) / Double(meter)))
                    let degree = r.progression[(barIndex / max(1, r.barsPerChord)) % r.progression.count]
                    let tones = chordTones(r, degree: degree, octave: part.octave)
                    let root = noteOf(r, degree: degree, octave: part.octave)
                    var notes: [Int]
                    switch part.notes {
                    case .root: notes = [root]
                    case .rootFifth: notes = [hit % 2 == 0 ? root : noteOf(r, degree: degree + 4, octave: part.octave)]
                    case .octaves: notes = [hit % 2 == 0 ? root : root + 12]
                    case .chord: notes = tones
                    case .arpUp, .arpDown, .arpUpDown, .arpRandom:
                        let pool = tones + tones.map { $0 + 12 }
                        let idx: Int
                        switch part.notes {
                        case .arpUp: idx = hit % pool.count
                        case .arpDown: idx = pool.count - 1 - hit % pool.count
                        case .arpUpDown: let c = (pool.count - 1) * 2; let h = hit % max(1, c); idx = h < pool.count ? h : c - h
                        default: idx = g.int(pool.count)
                        }
                        notes = [pool[max(0, min(pool.count - 1, idx))]]
                    case .motif:
                        var m = motif[hit % motifLen]
                        if barIndex % 4 == 3 && hit % motifLen >= motifLen - 4 { m += 1 }      // a lift every 4th bar
                        notes = [noteOf(r, degree: degree + m, octave: part.octave, melody: true)]
                    case .walk:
                        let posInBar = i % meter
                        let next = r.progression[((barIndex + 1) / max(1, r.barsPerChord)) % r.progression.count]
                        let nextRoot = noteOf(r, degree: next, octave: part.octave)
                        notes = [posInBar >= meter - 4 ? nextRoot - 1 : [root, noteOf(r, degree: degree + 2, octave: part.octave), noteOf(r, degree: degree + 4, octave: part.octave)][hit % 3]]
                    case .line(let degrees):
                        notes = [noteOf(r, degree: degrees[hit % max(1, degrees.count)], octave: part.octave, melody: true)]
                    }
                    var sound = [Float]()
                    func addNote(_ s: [Float], _ offset: Int = 0) {
                        if sound.count < s.count + offset { sound += [Float](repeating: 0, count: s.count + offset - sound.count) }
                        for (j, val) in s.enumerated() { sound[j + offset] += val }
                    }
                    switch part.synth {
                    case .pad: addNote(pad(notes, max(dur, step * 4)))
                    case .stab: addNote(stab(notes))
                    default:
                        for (k, m) in notes.enumerated() {
                            let strum = part.synth == .guitar ? n(0.012) * k : 0
                            let s: [Float]
                            switch part.synth {
                            case .sub: s = subBass(m, dur)
                            case .eight08: s = eight08(m, dur, glideFrom: (v >= 1 ? prevNote : nil).flatMap { $0 != m ? $0 : nil })
                            case .funk: s = funkBass(m, dur, vel: v)
                            case .sawBass: s = bassNote(m, dur)
                            case .pluck: s = pluck(m)
                            case .ePiano: s = ePiano(m, dur, vel: v)
                            case .organ: s = organ(m, dur)
                            case .marimba: s = marimba(m, vel: v)
                            case .bell: s = bell(m, vel: v)
                            case .kalimba: s = kalimba(m, vel: v)
                            case .piano: s = piano(m, dur, vel: v)
                            case .strings: s = strings(m, dur)
                            case .brass: s = brass(m, dur, vel: v)
                            case .supersaw: s = supersaw(m, dur)
                            case .chip: s = chip(m, dur)
                            case .guitar: s = guitar(m, dur)
                            case .choir: s = choir(m, dur)
                            case .pad, .stab: s = []
                            }
                            addNote(s.map { $0 / Float(max(1, notes.count)).squareRoot() }, strum)
                        }
                    }
                    let gain = part.gain * v
                    (part.ducked ? ducked : music).add(sound, at: t, gain: gain, pan: part.pan)
                    if part.reverb > 0 { verb.add(sound, at: t, gain: gain * part.reverb) }
                    if part.echo > 0 { echo.add(sound, at: t, gain: gain * part.echo) }
                    prevNote = notes.last
                    hit += 1
                }
            }
        }

        // Joins between sections: fills, risers, crashes, impacts, quiet stretches.
        for (k, sec) in sections.enumerated() {
            if sec.muffled { muffled.append((sec.from, sec.to)) }
            guard k > 0 else { continue }
            let prev = sections[k - 1]
            let jump = sec.energy - prev.energy
            let b = sec.from
            if jump > 0 && sec.energy >= 2 && !sec.fill {
                fx.add(reverseCymbal(bar / 2), at: b - bar / 2, gain: 0.1)
            } else if jump > 0 && sec.energy >= 2 {
                switch r.kit {
                case .cinematic: for q in 0..<4 { music.add(tom(0.7 + 0.1 * Float(q), pitch: 140 - Double(q) * 20), at: b - step * Double(4 - q) * 2, gain: 0.45) }
                case .trap: for q in 0..<8 { music.add(hat(), at: b - step * 4 + step * Double(q) / 2, gain: 0.1 + 0.02 * Float(q)) }
                default: roll(into: b, beats: 1)
                }
                fx.add(riser(bar * (jump >= 2 ? 1 : 0.5)), at: b - bar * (jump >= 2 ? 1 : 0.5), gain: 0.35)
                music.add(crash(), at: b, gain: 0.3)
                verb.add(crash(), at: b, gain: 0.1)
                if sec.energy == 3 && prev.energy <= 1 { music.add(impact(), at: b, gain: 0.7) }
            } else if jump < 0 {
                fx.add(reverseCymbal(bar / 2), at: b - bar / 2, gain: 0.12)
            }
        }
    }

    /// A closing chord on the tonic (the recipe's colour), ringing out from `at` — for end cards.
    func cadence(_ r: Recipe, at t: Double, length: Double = 3.5, synth: Synth = .pad, gain: Float = 0.5) {
        let tones = chordTones(r, degree: 1, octave: 4)
        let root = noteOf(r, degree: 1, octave: 2)
        var sound: [Float]
        switch synth {
        case .strings: sound = mixDown(tones.map { strings($0, length) })
        case .ePiano: sound = mixDown(tones.map { ePiano($0, length, vel: 0.7) })
        case .bell, .kalimba, .marimba:            // a music-box roll: the chord, one note after another
            sound = []
            for (k, m) in (tones + [tones[0] + 12]).enumerated() {
                let note = synth == .bell ? bell(m, vel: 0.8, length: length) : (synth == .kalimba ? kalimba(m, vel: 0.8) : marimba(m, vel: 0.8))
                let off = n(0.11) * k
                if sound.count < note.count + off { sound += [Float](repeating: 0, count: note.count + off - sound.count) }
                for (j, v) in note.enumerated() { sound[j + off] += v * 0.6 }
            }
        default: sound = chordVoice(tones + [tones[0] + 12], dur: length, attack: 0.01, cutoff: { 900 + 2400 * exp(-$0 * 1.5) }, decay: 0.9)
        }
        music.add(sound, at: t, gain: gain)
        verb.add(sound, at: t, gain: gain * 0.4)
        music.add(bassNote(root, length * 0.5), at: t, gain: 0.45)
    }
    /// A chord stab on the current chord at a picture hit (brass, stab or piano), with a crash if wanted.
    func hit(_ r: Recipe, at t: Double, synth: Synth = .stab, gain: Float = 0.4, crashToo: Bool = false) {
        let barIndex = Int(floor(t / (240 / r.bpm)))
        let degree = r.progression[(barIndex / max(1, r.barsPerChord)) % r.progression.count]
        let tones = chordTones(r, degree: degree, octave: 4)
        let s: [Float]
        switch synth {
        case .brass: s = mixDown(tones.map { brass($0, 0.35) })
        case .piano: s = mixDown(tones.map { piano($0, 0.5) })
        default: s = stab(tones)
        }
        music.add(s, at: t, gain: gain)
        verb.add(s, at: t, gain: gain * 0.3)
        if crashToo { music.add(crash(), at: t, gain: 0.3) }
    }
}
