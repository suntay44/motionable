// Bonnie — demo film (1:1, 15 s, the 15-second cut). Direction: DIRECTION.md · beat grid: SCRIPT.md.
// Night ("Ready for today?") → the sky turns to morning and the watch answers "Ready" → one answer each morning
// → evening: when to go to bed → a star opens on the end card. A 3/4 lullaby.
import AppKit

func makeFilm() -> Film {
    Film(name: "bonnie", width: 1080, height: 1080, fps: 60, duration: 15, bpm: T.bpm,
         holdFrom: T.hold, draw: frame, score: score, keyframes: [2.2, 7.6, 11.0, 14.95], tempo: phases)
}

// MARK: - Timeline (72 BPM, 3/4: a bar is 3 beats, 2.5 s)

// Tempo phase: the lullaby winds down from 72 to 60 BPM over the last bar before the end card, like falling asleep.
let phases = TempoMap(72, [.ramp(from: 12, to: 14, bpm: 60)])

enum T {
    static let bpm = 72.0, beat = 60 / bpm
    static func b(_ n: Double) -> Double { phases.time(ofBeat: n) }
    static let zzz = b(1)
    static let dawn = b(3)                         // the sky turns from night to morning over a beat and a bit
    static let watchIn = b(3.55), morning = b(4), ready = b(4.6)
    static let pills = [b(5), b(5.75), b(6.5)]
    static let toBed = b(10), bedLift = b(11.5)
    static let toEnd = b(14)
    static let name = b(14.1), line = b(14.25), pill = b(14.4)   // after the slowdown, beats are a second long
    static let hold = 14.0
}

// MARK: - Look

let blueTop = Col(0x188EFF), blueBottom = Col(0x004ABA), nightTop = Col(0x081040), nightBottom = Col(0x1D2C74)
let duskTop = Col(0x0E1446), duskBottom = Col(0x33307E)
let white = Col(0xFFFFFF), moonGold = Col(0xFFE9A8), ink = Col(0x101828)
let green = Col(0x30C85E), amber = Col(0xF5A623), coral = Col(0xF0564A)
let round = Face.system(.heavy, .rounded), roundBold = Face.system(.bold, .rounded), roundSemi = Face.system(.semibold, .rounded)
// Type mix: SF Rounded heavy; the time words take moonlight gold at night (gold on the morning blue would drop below
// 3:1), and a softer weight in the morning.
let moonlight = TextStyle(colour: Col(0xFFE9A8)), softer = TextStyle(face: .system(.semibold, .rounded))
let watchShot = loadImage("assets/watch-today.png"), home = Screenshot("assets/home-dark.png")
let appIcon = loadImage("assets/bonnie-icon.png")
let moon = loadDrawing("assets/drawn/moon.svg"), zzz = loadDrawing("assets/drawn/zzz.svg")

/// A sky of seeded stars that twinkle; `fade` 0…1 hides them (dawn).
func stars(_ t: Double, fade: Double = 0, seed: Int = 7) {
    guard fade < 1 else { return }
    var g = Seeded(UInt64(seed))
    for i in 0..<46 {
        let c = CGPoint(x: W * CGFloat(g.next()), y: H * 0.85 * CGFloat(g.next()))
        let r = 1.6 + 2.6 * CGFloat(g.next()), phase = 6.28 * g.next(), speed = 1.2 + 1.6 * g.next()
        let a = (0.35 + 0.65 * (0.5 + 0.5 * sin(t * speed + phase))) * (1 - fade)
        if i % 9 == 0 {
            sparkle(at: c, size: r * 6, p: 0.5, colour: white.alpha(CGFloat(a)))
        } else {
            fill(CGPath(ellipseIn: centred(c, r), transform: nil), white.alpha(CGFloat(a)))
        }
    }
}

/// The sleepy moon, bobbing gently; `sink` 0…1 sets it.
func drawMoon(_ t: Double, at r: CGRect, sink: Double = 0) {
    guard sink < 1 else { return }
    ctx.saveGState()
    ctx.setAlpha(CGFloat(1 - pow(sink, 0.6)))                       // sets down and away to the right, clear of the watch band
    let bob = 8 * CGFloat(sin(2 * .pi * t / (T.beat * 3)))
    let c = CGPoint(x: r.midX + 300 * CGFloat(inCubic(sink)), y: r.midY + bob + 420 * CGFloat(inCubic(sink)))
    ctx.translateBy(x: c.x, y: c.y); ctx.rotate(by: CGFloat(0.06 * sin(t * 0.9))); ctx.translateBy(x: -c.x, y: -c.y)
    radialGlow(at: c, radius: r.width * 0.9, colour: moonGold.alpha(0.16))
    drawDrawing(moon, in: CGRect(x: c.x - r.width / 2, y: c.y - r.height / 2, width: r.width, height: r.height))
    ctx.restoreGState()
}

/// One of Bonnie's three answers, as the app shows them: a white pill with a coloured dot.
func answerPillRect(_ label: String, at left: CGPoint) -> CGRect {
    CGRect(x: left.x, y: left.y - 41, width: textWidth(label, 44, roundBold) + 112, height: 82)
}
func answerPill(_ label: String, dot: Col, in r: CGRect) {
    fillShadowed(rr(r, 41), white, blur: 24, alpha: 0.18, dy: 8)
    fill(CGPath(ellipseIn: centred(CGPoint(x: r.minX + 44, y: r.midY), 12), transform: nil), dot)
    text(label, 44, roundBold, ink, r.minX + 72, r.midY + 15)
}

// MARK: - Scenes

let moonRect = CGRect(x: 640, y: 96, width: 300, height: 300)
let watchScreen = CGRect(x: 618, y: 372, width: 340, height: 405)

/// Night turns to morning in one shot: the hook question, then the watch answers.
func nightToMorning(_ t: Double) {
    let d = outCubic(prog(t, T.dawn, T.dawn + 1.1))
    gradientFill([mix(nightTop, blueTop, d), mix(nightBottom, blueBottom, d)], degrees: 90)
    radialGlow(at: CGPoint(x: 540, y: 1260 - 240 * CGFloat(d)), radius: 760, colour: Col(0xFFD58A, 0.08 + 0.22 * d * (1 - 0.6 * d)))
    stars(t, fade: d)
    drawMoon(t, at: moonRect, sink: prog(t, T.dawn - 0.2, T.dawn + 0.9))
    // Zzz drift up from the moon while it sleeps.
    let zp = prog(t, T.zzz, T.dawn + 0.3)
    if zp > 0 && zp < 1 {
        ctx.saveGState(); ctx.setAlpha(CGFloat(sin(Double.pi * zp)))
        drawDrawing(zzz, in: CGRect(x: 880 + 30 * CGFloat(zp), y: 250 - 150 * CGFloat(zp), width: 150, height: 150))
        ctx.restoreGState()
    }
    // The hook, readable from frame 1 (it has settled before 0).
    Kinetic(lines: ["Ready for", "*today?*"], face: round, size: 136, colour: white, x: 84, y: 640,
            from: -0.6, to: T.dawn + 0.3, enter: .rise, exit: .rise, maxWidth: nil, accent: moonlight).draw(t)

    // Morning: the watch rises in and answers.
    let wp = outCubic(prog(t, T.watchIn, T.watchIn + 0.7))
    if wp > 0 {
        ctx.saveGState(); ctx.translateBy(x: 0, y: 460 * CGFloat(1 - wp))
        let body = watchScreen.insetBy(dx: -26, dy: -26)
        let band = Col(0xE8F1FF)
        fill(rr(CGRect(x: body.minX + 66, y: -40, width: body.width - 132, height: body.minY + 80), 40), band)
        fill(rr(CGRect(x: body.minX + 66, y: body.maxY - 40, width: body.width - 132, height: 600), 40), band)
        fillShadowed(rr(body, 104), Col(0x1E1F24), blur: 50, alpha: 0.35, dy: 24)
        stroke(rr(body.insetBy(dx: 2, dy: 2), 102), Col(0x5A5D66), 3)
        fill(rr(CGRect(x: body.maxX - 6, y: body.minY + 120, width: 24, height: 76), 11), Col(0x3A3C44))
        fill(rr(CGRect(x: body.maxX - 4, y: body.minY + 230, width: 14, height: 70), 7), Col(0x3A3C44))
        ctx.saveGState(); ctx.addPath(rr(watchScreen, 72)); ctx.clip(); drawImage(watchShot, in: watchScreen); ctx.restoreGState()
        let k = watchScreen.width / 416
        let ready = CGRect(x: watchScreen.minX + 120 * k, y: watchScreen.minY + 146 * k, width: 130 * k, height: 48 * k)
        sparkles(around: ready.insetBy(dx: -20, dy: -20), t: t, from: T.ready, count: 6, colour: white, seed: 5, size: 22)
        ctx.restoreGState()
    }
    Kinetic(lines: ["One answer", "*each morning.*"], face: round, size: 84, colour: white, x: 84, y: 190,
            from: T.morning, enter: .rise, maxWidth: nil, accent: softer).draw(t)
    let answers: [(String, Col)] = [("Ready", green), ("Take it easy", amber), ("Recover", coral)]
    for (i, a) in answers.enumerated() {
        // Motion vocabulary (gentle): pills slide in, cards zoom, the watch rises, small things pop.
        let r = answerPillRect(a.0, at: CGPoint(x: 84, y: 470 + CGFloat(i) * 112))
        show(r, t: t, from: T.pills[i], enter: .slide(.left), length: 0.4) { answerPill(a.0, dot: a.1, in: r) }
    }
}

/// Evening: when to go to bed (the real tiles, the bedtime one lifted).
let bedRegion = CGRect(x: 40, y: 880, width: 1126, height: 735)
let bedTile = CGRect(x: 48, y: 891, width: 539, height: 305)
func bedScene(_ t: Double) {
    gradientFill([duskTop, duskBottom], degrees: 90)
    stars(t, seed: 11)
    drawMoon(t, at: CGRect(x: 760, y: 60, width: 230, height: 230))
    Kinetic(lines: ["And when to", "*go to bed.*"], face: round, size: 84, colour: white, x: 84, y: 170,
            from: T.toBed + 0.15, enter: .rise, maxWidth: nil, accent: moonlight).draw(t)
    let cardBox = CGRect(x: 70, y: 400, width: 940, height: 610), card = fitted(bedRegion, in: cardBox)
    show(card, t: t, from: T.toBed - 0.1, enter: .zoom, length: 0.6) {
        drawScreen(home, region: bedRegion, in: cardBox, radius: 36, snap: false)
    }
    let k = card.width / bedRegion.width
    let tile = CGRect(x: card.minX + (bedTile.minX - bedRegion.minX) * k, y: card.minY + (bedTile.minY - bedRegion.minY) * k,
                      width: bedTile.width * k, height: bedTile.height * k)
    // Spotlight: the rest of the card dims, the bedtime tile lifts out bigger, with a warm moonlit glow.
    let lp = prog(t, T.bedLift, T.bedLift + 0.5)
    if lp > 0 { fill(rr(card, 36), Col(0x000000, 0.45 * CGFloat(outCubic(lp)))) }
    let lift = CGRect(x: tile.midX - tile.width * 0.65 + 40, y: tile.midY - tile.height * 0.65 - 50,
                      width: tile.width * 1.3, height: tile.height * 1.3)
    if lp > 0.3 { radialGlow(at: CGPoint(x: lift.midX, y: lift.midY), radius: lift.width * 0.8, colour: moonGold.alpha(0.2 * CGFloat(prog(lp, 0.3, 1)))) }
    callout(home, region: bedTile, screenRegion: bedRegion, screenRect: card, to: lift, p: lp, plate: Col(0x1C1C1E), radius: 30)
}

/// End card: the icon, the name, one line, a truthful CTA (Bonnie isn't on the App Store yet).
func endScene(_ t: Double) {
    gradientFill([blueTop, blueBottom], degrees: 90)
    ctx.saveGState(); ctx.setAlpha(0.3); stars(t, seed: 11); ctx.restoreGState()
    radialGlow(at: CGPoint(x: 540, y: 360), radius: 420, colour: white.alpha(0.18))
    let ip = outBack(prog(t, T.toEnd - 0.3, T.toEnd + 0.2), 1.3)
    if ip > 0 {
        let s = 250 * CGFloat(ip)
        let r = CGRect(x: 540 - s / 2, y: 340 - s / 2, width: s, height: s)
        fillShadowed(rr(r, 58 * CGFloat(ip)), Col(0x003A94), blur: 40, alpha: 0.35, dy: 16)
        ctx.saveGState(); ctx.addPath(rr(r, 58 * CGFloat(ip))); ctx.clip(); drawImage(appIcon, in: r); ctx.restoreGState()
        stroke(rr(r, 58 * CGFloat(ip)), white.alpha(0.5), 4)
    }
    sparkles(around: CGRect(x: 380, y: 190, width: 320, height: 300), t: t, from: T.toEnd + 0.2, count: 5, colour: moonGold, seed: 3, size: 28)
    Kinetic(lines: ["Bonnie"], face: round, size: 128, colour: white, x: 540, y: 640, from: T.name, enter: .rise, exit: .none,
            align: 0.5, maxWidth: nil).draw(t)
    Kinetic(lines: ["No account. No ads."], face: roundSemi, size: 46, colour: white.alpha(0.85), x: 540, y: 716, from: T.line,
            enter: .fade, exit: .none, align: 0.5, maxWidth: nil).draw(t)
    let label = "Coming soon to the App Store"
    let pw = textWidth(label, 42, roundBold) + 100
    let pill = CGRect(x: 540 - pw / 2, y: 772, width: pw, height: 90)
    show(pill, t: t, from: T.pill, enter: .pop, length: 0.4) {
        fill(rr(pill, 45), white)
        text(label, 42, roundBold, blueBottom, 540, pill.minY + 60, align: 0.5)
    }
}

let reel = Reel([
    Clip(from: 0, to: T.toBed, draw: nightToMorning),
    Clip(from: T.toBed, to: T.toEnd, draw: bedScene),
    Clip(from: T.toEnd, to: 15, draw: endScene),
], joins: [(.uncover(.down), 0.6), (.shape(.star(points: 5), CGPoint(x: 875, y: 175)), 0.7)])

func frame(_ t: Double) {
    reel.draw(t)
}

// MARK: - Sound: a 3/4 lullaby

let recipe = Recipe(
    bpm: T.bpm, swing: 0, key: 8, mode: .major, progression: [1, 6, 4, 5], barsPerChord: 1, meter: 12, chordColour: .seventh,
    kit: .lofi, drums: Drums(kick: "X...........", rim: "........x...", shaker: "..x...x...x."),
    parts: [
        Part(synth: .pad, rhythm: "X___________", notes: .chord, octave: 4, gain: 0.15, reverb: 0.45),
        Part(synth: .sub, rhythm: "X___________", notes: .root, octave: 2, gain: 0.3),
        Part(synth: .bell, rhythm: "x.x.x.x.x.x.", notes: .motif, octave: 5, gain: 0.13, reverb: 0.4, echo: 0.25),
        Part(synth: .kalimba, rhythm: "....x...x...", notes: .arpUp, octave: 4, gain: 0.13, reverb: 0.3, from: 2),
    ],
    space: .hall, colour: .warm, sidechain: 0.12, seed: 72)

func score(_ s: Score) {
    s.compose(recipe, [Section(from: 0, to: T.dawn, energy: 1), Section(from: T.dawn, to: T.toBed, energy: 2, fill: false),
                       Section(from: T.toBed, to: T.toEnd, energy: 1), Section(from: T.toEnd, to: 15, energy: 0)])
    s.cue(T.zzz, "zzz", slideWhistle(up: true, length: 0.6), 0.08)
    s.cue(T.dawn, "dawn", riser(1.0), 0.12)
    s.cue(T.watchIn + 0.4, "watch", bloop(), 0.3)
    s.cue(T.ready, "ready", success(), 0.25)
    for at in T.pills { s.cue(at, "answer", pop(820), 0.22) }
    s.cue(T.toBed - 0.3, "evening", whoosh(0.6, up: false), 0.2)
    s.cue(T.bedLift, "bedtime", ding(), 0.25)
    s.cue(T.toEnd - 0.35, "star", whoosh(0.7), 0.18)
    s.cue(T.toEnd, "icon", thumpSnd(), 0.4)
    s.cadence(recipe, at: T.toEnd, length: 4.5, synth: .bell, gain: 0.5)
    s.fadeOut = (14.0, 14.95)
}
