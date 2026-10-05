// {{PRODUCT}} — hype film. A grey, deliberately plain skeleton that renders, so the toolchain is proven
// before the real work. Replace EVERY value from DIRECTION.md and SCRIPT.md: palette, faces, tempo, clips,
// joins, recipe, cues. Nothing here is a style to keep. API: ENGINE.md.
import AppKit

func makeFilm() -> Film {
    Film(name: "{{SLUG}}-hype", width: 1080, height: 1920, fps: 60, duration: 8, bpm: T.bpm,
         holdFrom: T.hold, draw: frame, score: score)
}

// MARK: - Timeline: every time on the beat grid of the chosen tempo

enum T {
    static let bpm = 100.0                            // from DIRECTION › Tempo
    static let beat = 60 / bpm, bar = 4 * beat
    static let cut1 = 2 * bar                         // from SCRIPT.md
    static let hold = 7.0
}

// MARK: - Palette, faces, assets (from DIRECTION › Palette use, Type; files in assets/)

let bg = Col(0x2A2A2E), fg = Col(0xE8E8EA), accent = Col(0x9A9AA0)
let headFace = Face.system(.heavy), bodyFace = Face.system(.medium)

// MARK: - Picture

let reel = Reel([
    Clip(from: 0, to: T.cut1) { t in
        fill(fullCanvas(), bg)
        Kinetic(lines: ["Plan mode", "decides this."], face: headFace, size: 130, colour: fg, x: 72, y: 760,
                from: 0, enter: .rise).draw(t)
    },
    Clip(from: T.cut1, to: 8) { t in
        fill(fullCanvas(), accent)
        Kinetic(lines: ["{{PRODUCT}}"], face: headFace, size: 120, colour: bg, x: 540, y: 980,
                from: T.cut1 + 0.2, enter: .fade, align: 0.5).draw(t)
    },
], joins: [(.dissolve, 0.5)])

func frame(_ t: Double) {
    reel.draw(t)
}

// MARK: - Sound (from DIRECTION › Recipe)

let recipe = Recipe(
    bpm: T.bpm, key: 0, mode: .major, progression: [1, 4], chordColour: .triad, kit: .clean,
    drums: Drums(kick: "x.......x.......", hat: "..x...x...x...x."),
    parts: [Part(synth: .pad, rhythm: "X_______________", notes: .chord, octave: 4, gain: 0.3)],
    space: .room, colour: .clean, seed: 1)

func score(_ s: Score) {
    s.compose(recipe, [Section(from: 0, to: T.cut1, energy: 1), Section(from: T.cut1, to: 8, energy: 2)])
    s.cue(T.cut1, "join", swish(), 0.3)
    s.fadeOut = (T.hold, 7.95)
}
