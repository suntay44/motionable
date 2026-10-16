// Owly craft benchmark: real capacity evidence, persistent screen identity, measured holds.
import AppKit

func makeFilm() -> Film {
    grainAlpha = 0
    return Film(name: "owly-craft", width: 1920, height: 1080, fps: 60, duration: 15, bpm: 96,
                holdFrom: 13.2, draw: frame, score: score,
                keyframes: [1.2, 5.2, 9.4, 13.3], motionMoments: [3.55, 4.35, 8.15, 11.7, 12.6])
}
let paper = Col(0xF5F3EC), ink = Col(0x182D22), green = Col(0x0F9B3E), muted = Col(0x53675B)
let heading = Face.system(.bold), body = Face.system(.medium), serif = Face.named("Georgia").italic
let today = Screenshot("assets/today.png"), over = Screenshot("assets/over.png")
let mascot = loadImage("assets/mascot.png"), logo = loadImage("assets/logo.png")
let glide = MotionCurve.bezier(0.65, 0, 0.35, 1)
let phone = SharedElement(from: CGRect(x: 1260, y: 95, width: 398, height: 890),
                          to: CGRect(x: 120, y: 95, width: 398, height: 890), start: 3.2, end: 4.1, curve: glide)
let meter = CGRect(x: 0, y: 520, width: 1206, height: 230)
let focus = CGRect(x: 650, y: 480, width: 1100, height: 255)
let accentPath = MotionPath([.init(time: 3.2, point: CGPoint(x: 1160, y: 530)),
                            .init(time: 3.65, point: CGPoint(x: 930, y: 380), velocity: CGPoint(x: -680, y: 60)),
                            .init(time: 4.1, point: CGPoint(x: 580, y: 570))])

func frame(_ time: Double) {
    let t = min(time, 13.2)
    fill(fullCanvas(), paper)
    // Quiet repeatable margins and one brand treatment; annotations support the story.
    text("OWLY / A DAY HAS A CEILING", 25, body, muted, 120, 62, kern: 1)
    if t < 11.25 {
        phone.draw(t) { r in
            let e = prog(t, 7.9, 8.4)
            ctx.saveGState(); ctx.setAlpha(CGFloat(1-e)); _ = drawScreen(today, in: r, radius: 48); ctx.restoreGState()
            if e > 0 { ctx.saveGState(); ctx.setAlpha(CGFloat(e)); _ = drawScreen(over, in: r, radius: 48); ctx.restoreGState() }
        }
    } else if t < 11.65 {
        show(phone.to, t: t, from: 0, until: 11.65, enter: .cut, exit: .fade, length: 0.5) {
            _ = drawScreen(over, in: phone.to, radius: 48)
        }
    }
    if t < 3.2 {
        Kinetic(lines: ["A day has", "*a ceiling.*"], face: heading, size: 134, colour: ink, x: 120, y: 385,
                from: -1, enter: .none, exit: .none, maxWidth: 1020, accent: TextStyle(face: serif, colour: green)).draw(t)
        show(CGRect(x: 120, y: 680, width: 950, height: 80), t: t, from: 0.45, enter: .rise, length: 0.65,
             curve: .bezier(0.22, 1, 0.36, 1)) {
            text("Make room for today.", 45, body, muted, 120, 735)
        }
        let r = CGRect(x: 120, y: 825, width: 145, height: 145)
        show(r, t: t, from: 0.35, enter: .zoom, length: 0.65, curve: .spring(response: 0.45, damping: 0.85)) { drawImage(mascot, in: r) }
    }
    if t > 3.2 && t < 4.1 {
        // One supporting accent follows an authored path; readable type never enters the blurred layer.
        temporalLayer(t: t, samples: 4, moving: 3.2...4.1) { sample in
            let p = accentPath.position(sample)
            let alpha = prog(sample, 3.2, 3.3) * (1-prog(sample, 4, 4.1))
            fill(CGPath(ellipseIn: centred(p, 14), transform: nil), green.alpha(CGFloat(alpha)))
        }
    }
    if t >= 4.1 && t < 11.25 {
        let label = t < 7.9 ? ["Know when your", "*day is full.*"] : ["See when there’s", "*more than fits.*"]
        // Content changes use a deliberate cut; no competing entrance while the UI is changing.
        // The lift crosses this area: let it settle before readable type arrives.
        show(CGRect(x: 650, y: 160, width: 1120, height: 220), t: t, from: 4.75, enter: .fade, length: 0.35) {
            Kinetic(lines: label, face: heading, size: 100, colour: ink, x: 650, y: 260,
                    from: 0, enter: .none, exit: .none, maxWidth: 1120, accent: TextStyle(face: serif, colour: green)).draw(t)
        }
        let p = prog(t, 4.15, 4.75), e = prog(t, 7.9, 8.4)
        // These are two real screenshot states, not a fabricated recording of an interaction.
        if e < 1 { ctx.saveGState(); ctx.setAlpha(CGFloat(1-e)); callout(today, region: meter, screenRect: fitted(today.bounds, in: phone.to), to: focus, p: p, plate: Col(0xFFFFFF)); ctx.restoreGState() }
        if e > 0 { ctx.saveGState(); ctx.setAlpha(CGFloat(e)); callout(over, region: meter, screenRect: fitted(today.bounds, in: phone.to), to: focus, p: p, plate: Col(0xFFFFFF)); ctx.restoreGState() }
        show(CGRect(x: 650, y: 790, width: 1100, height: 80), t: t, from: 4.75, enter: .fade, length: 0.35) {
            text("Your tasks. Your capacity.", 43, body, muted, 650, 845)
        }
    }
    if t >= 11.7 {
        let r = CGRect(x: 120, y: 310, width: 180, height: 180)
        show(r, t: t, from: 11.7, enter: .zoom, length: 0.7, curve: .easeOut) { drawImage(logo, in: r) }
        show(CGRect(x: 350, y: 300, width: 1390, height: 430), t: t, from: 11.7, enter: .rise, length: 0.7, curve: .easeOut) {
            text("Owly the Scribe", 122, heading, ink, 350, 445)
            text("Plan what fits.", 92, serif, green, 350, 600)
        }
        show(CGRect(x: 350, y: 715, width: 1100, height: 80), t: t, from: 12.5, enter: .fade, length: 0.35) {
            text("An honest to-do list.", 42, body, muted, 350, 770)
        }
    }
}
let recipe = Recipe(bpm: 96, swing: 0.12, key: 2, mode: .lydian, progression: [1, 4, 1, 5], chordColour: .add9, kit: .acoustic,
                    drums: Drums(kick: "X...............", rim: "........x.......", shaker: "................"),
                    parts: [Part(synth: .piano, rhythm: "X_______x_______", notes: .chord, octave: 4, gain: 0.22),
                            Part(synth: .sub, rhythm: "X_______________", notes: .root, octave: 2, gain: 0.2)],
                    space: .studio, colour: .warm, seed: 108)
func score(_ s: Score) {
    s.compose(recipe, [Section(from: 0, to: 11.25, energy: 1), Section(from: 11.25, to: 15, energy: 0, fill: false)])
    s.cue(4.15, "capacity focus", swish(), 0.12)
    s.cue(8.4, "over capacity", penScribble(0.22), 0.16)
    s.fadeOut = (13.2, 14.95)
}
