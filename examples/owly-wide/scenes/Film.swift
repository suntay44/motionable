// Owly the Scribe — demo film (16:9, 23 s). Direction: DIRECTION.md · beat grid: SCRIPT.md.
// Problem hook (texting reminders) → the signature: a list lands on Leo's widget, he ticks it, Mom sees "Done by Leo"
// → know when your day is full → end card with a drawn quill.
import AppKit

func makeFilm() -> Film {
    Film(name: "owly-wide", width: 1920, height: 1080, fps: 60, duration: 23, bpm: T.bpm,
         holdFrom: T.hold, draw: frame, score: score)
}

// MARK: - Timeline (88 BPM)

enum T {
    static let bpm = 88.0, beat = 60 / bpm
    static func b(_ n: Double) -> Double { n * beat }
    static let bubbles = [-0.1, b(1), b(2)]
    static let owl = b(3), meet = b(3.5)
    static let toShare = b(6)
    static let pick = b(7.5), send = b(8), land = b(9)
    static let tap = b(11)
    static let notice = b(12), momTick = b(12.5)
    static let toDay = b(17), callout = b(19), scribble = b(20)
    static let toEnd = b(25)
    static let hold = 21.3
}

// MARK: - Look

let green = Col(0x0F9B3E), paper = Col(0xF7F4EC), sage = Col(0xE4ECDF), ink = Col(0x1E2A22)
let night = Col(0x1B2235), dusk = Col(0x2E3A5C), white = Col(0xFFFFFF), grey = Col(0x8A8A8E)
let serif = Face.system(.bold, .serif), body = Face.system(.medium), ui = Face.system(.semibold)
let momList = Screenshot("assets/mom-list.png"), dayFull = Screenshot("assets/over.png")
let widgetArt = loadImage("assets/widget-tasks-from-mom.png"), owlIcon = loadImage("assets/owly-logo.png")
let owlMascot = loadImage("assets/owly-mascot.png"), quill = loadDrawing("assets/drawn/quill.svg")

/// A scribe's page: faint ruled lines and a green margin.
func ruledPaper() {
    fill(fullCanvas(), paper)
    var y: CGFloat = 92
    while y < H { line(CGPoint(x: 0, y: y), CGPoint(x: W, y: y), sage, 2); y += 64 }
    line(CGPoint(x: 92, y: 0), CGPoint(x: 92, y: H), green.alpha(0.28), 3)
}

/// A green tick drawn over a list ring (centre and radius in canvas units), p 0…1.
func tick(at c: CGPoint, radius r: CGFloat, p: Double) {
    guard p > 0 else { return }
    fill(CGPath(ellipseIn: centred(c, r * CGFloat(outBack(prog(p, 0, 0.5), 2))), transform: nil), green)
    let pts = [CGPoint(x: c.x - 0.42 * r, y: c.y + 0.02 * r), CGPoint(x: c.x - 0.12 * r, y: c.y + 0.32 * r),
               CGPoint(x: c.x + 0.46 * r, y: c.y - 0.34 * r)]
    stroke(partial(pts, prog(p, 0.3, 1)), white, max(2, 0.18 * r))
}

// MARK: - Scenes

/// Hook: the problem, then the owl.
func hookScene(_ t: Double) {
    ctx.saveGState()
    applyCamera(scale: 1 + 0.03 * outCubic(prog(t, 0, T.toShare + 0.4)))      // a slow push-in
    ruledPaper()
    // Starts a hair before 0, so frame 1 is already settled and readable.
    Kinetic(lines: ["Still texting", "reminders?"], face: serif, size: 132, colour: ink, x: 140, y: 400,
            from: -0.32, enter: .stamp, exit: .none, maxWidth: nil, stagger: 0.16).draw(t)
    // Mom's texts pile up, right-aligned like a thread.
    for (i, msg) in ["Piano at 4!", "Bins out tonight!", "Hello??"].enumerated() {
        let w = textWidth(msg, 46, body) + 46 * 1.2
        chatBubble(msg, at: CGPoint(x: 1740 - w / 2, y: 200 + CGFloat(i) * 128), mine: true,
                   p: prog(t, T.bubbles[i], T.bubbles[i] + 0.3), fill: green, ink: white, face: body, size: 46)
    }
    let op = outBack(prog(t, T.owl, T.owl + 0.4), 1.6)
    if op > 0 {
        let s = 300 * CGFloat(op), bob = 6 * CGFloat(sin(2 * .pi * t / T.beat))
        drawImage(owlMascot, in: CGRect(x: 1560 - s / 2, y: 790 - s / 2 + bob, width: s * 580 / 600, height: s))
    }
    sticker("Meet Owly.", at: CGPoint(x: 1220, y: 760), shape: .speech, fill: ink, ink: white, face: serif,
            size: 54, degrees: -4, p: prog(t, T.meet, T.meet + 0.25), tailRight: true)
    ctx.restoreGState()
}

/// The signature: Mom's list (left) → Leo's Home Screen widget (right) → he ticks it → "Done by Leo" on Mom's phone.
let momRegion = CGRect(x: 0, y: 165, width: 1206, height: 1085)
let momBox = CGRect(x: 120, y: 265, width: 740, height: 680)
let leoCard = CGRect(x: 1040, y: 265, width: 760, height: 680)
let widgetRect = CGRect(x: 1072, y: 345, width: 696, height: 696 * 1148 / 2450)
func shareScene(_ t: Double) {
    fill(fullCanvas(), sage)
    Kinetic(lines: ["Make a list for your son."], face: serif, size: 92, colour: ink, x: 120, y: 190,
            from: T.toShare + 0.1, enter: .rise, maxWidth: nil).draw(t)
    // Mom's list rises in.
    let e = outCubic(prog(t, T.toShare - 0.1, T.toShare + 0.5))
    ctx.saveGState(); ctx.translateBy(x: 0, y: 90 * CGFloat(1 - e))
    let mom = drawScreen(momList, region: momRegion, in: momBox, radius: 40, snap: false)
    func m(_ x: CGFloat, _ y: CGFloat) -> CGPoint { canvasPoint(CGPoint(x: x, y: y), region: momRegion, drawnIn: mom) }
    let k = mom.width / momRegion.width
    // The row being sent: a soft green outline.
    let hp = prog(t, T.pick, T.pick + 0.3) * (1 - prog(t, T.land, T.land + 0.4))
    if hp > 0 {
        let row = m(56, 544)                       // row 1 spans y 540–721 in the screenshot (inspect.sh … column 700)
        stroke(rr(CGRect(x: row.x, y: row.y, width: 1094 * k, height: 174 * k), 18), green.alpha(CGFloat(hp)), 5)
    }
    // When Leo ticks it, Mom's list ticks too (synced): greyed, struck through, ticked.
    let mt = prog(t, T.momTick, T.momTick + 0.4)
    if mt > 0 {
        tick(at: m(122, 609), radius: 30 * k, p: mt)
        let a = m(226, 584)
        fill(CGRect(x: a.x, y: a.y, width: 330 * k, height: 52 * k), white.alpha(0.5 * CGFloat(mt)))
        line(m(229, 611), m(229 + 320 * CGFloat(prog(mt, 0.4, 1)), 611), grey, 3.5 * k)
    }
    ctx.restoreGState()

    // Leo's Home Screen: the widget slot fills when the list lands.
    let ce = outCubic(prog(t, T.toShare + 0.1, T.toShare + 0.6))
    ctx.saveGState(); ctx.translateBy(x: 0, y: 90 * CGFloat(1 - ce))
    fillShadowed(rr(leoCard, 48), night, blur: 40, alpha: 0.25)
    ctx.saveGState(); ctx.addPath(rr(leoCard, 48)); ctx.clip()
    gradientFill([night, dusk], degrees: 90, in: leoCard)
    radialGlow(at: CGPoint(x: leoCard.maxX - 60, y: leoCard.minY + 40), radius: 420, colour: Col(0x4F6BD8, 0.35))
    ctx.restoreGState()
    text("Leo's iPhone", 34, ui, white.alpha(0.75), leoCard.minX + 34, leoCard.minY + 52)
    let apps: [(Icon, Col)] = [(.music, Col(0xE8655A)), (.camera, Col(0x8E8E93)), (.book, Col(0xF2A93B)), (.chat, Col(0x34C759))]
    for (i, app) in apps.enumerated() {     // a row of app icons, so it reads as a Home Screen
        let r = CGRect(x: widgetRect.minX + 26 + CGFloat(i) * 182, y: widgetRect.maxY + 54, width: 116, height: 116)
        fill(rr(r, 28), app.1)
        icon(app.0, at: CGPoint(x: r.midX, y: r.midY), size: 60, colour: white, weight: 2.2)
    }
    let wp = outCubic(prog(t, T.land, T.land + 0.45))
    if wp < 1 { stroke(rr(widgetRect, 34), white.alpha(0.25 * CGFloat(1 - wp)), 3) }   // the empty slot
    if wp > 0 {
        ctx.saveGState()
        let c = CGPoint(x: widgetRect.midX, y: widgetRect.midY), k = 0.7 + 0.3 * CGFloat(wp)
        ctx.setAlpha(CGFloat(min(1, wp * 2)))
        ctx.translateBy(x: c.x, y: c.y); ctx.scaleBy(x: k, y: k); ctx.translateBy(x: -c.x, y: -c.y)
        ctx.saveGState(); ctx.addPath(rr(widgetRect, 34)); ctx.clip(); drawImage(widgetArt, in: widgetRect); ctx.restoreGState()
        // The tap: exactly where the widget draws "Practice piano" (artwork is 2450 × 1148).
        let wk = widgetRect.width / 2450
        func w(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: widgetRect.minX + x * wk, y: widgetRect.minY + y * wk) }
        let tp = prog(t, T.tap + 0.05, T.tap + 0.45)
        if tp > 0 {
            tick(at: w(168, 387), radius: 49 * wk, p: tp)
            fill(CGRect(origin: w(280, 340), size: CGSize(width: 560 * wk, height: 90 * wk)), white.alpha(0.5 * CGFloat(tp)))
            line(w(287, 392), w(287 + 520 * CGFloat(prog(tp, 0.4, 1)), 392), grey, 7 * wk)
            // Its counter and bar move on: 1/5 → 2/5.
            fill(CGRect(origin: w(2200, 130), size: CGSize(width: 150 * wk, height: 66 * wk)), white)
            text(tp < 0.5 ? "1/5" : "2/5", 48 * wk, ui, grey, w(2331, 179).x, w(2331, 179).y, align: 1)
            let bar = w(112, 255)
            fill(rr(CGRect(x: bar.x, y: bar.y, width: (444 + 445 * CGFloat(outCubic(prog(tp, 0.3, 1)))) * wk, height: 28 * wk), 14 * wk), green)
        }
        tapRipple(at: w(168, 387), at: T.tap, t: t, colour: green)
        ctx.restoreGState()
    }
    ctx.restoreGState()

    // The task travelling from Mom's row to Leo's widget.
    let fp = prog(t, T.send, T.land)
    if fp > 0 && fp < 1 {
        let a = CGPoint(x: momBox.maxX - 40, y: momBox.minY + 300), z = CGPoint(x: widgetRect.minX + 70, y: widgetRect.minY + 110)
        let u = CGFloat(inOut(fp)), v = 1 - u
        let mid = CGPoint(x: (a.x + z.x) / 2, y: min(a.y, z.y) - 170)
        let p = CGPoint(x: v * v * a.x + 2 * v * u * mid.x + u * u * z.x, y: v * v * a.y + 2 * v * u * mid.y + u * u * z.y)
        fill(CGPath(ellipseIn: centred(p, 30), transform: nil), green.alpha(0.2))
        fill(CGPath(ellipseIn: centred(p, 16), transform: nil), green)
    }
    // "Done by Leo" arrives on Mom's phone (Owly's real notification wording).
    let nIn = outCubic(prog(t, T.notice, T.notice + 0.4)), nOut = inCubic(prog(t, T.toDay - 0.45, T.toDay - 0.1))
    if nIn > 0 && nOut < 1 {
        let r = CGRect(x: momBox.midX - 320, y: lerp(120, 300, nIn) - 200 * CGFloat(nOut), width: 640, height: 128)
        ctx.saveGState(); ctx.setAlpha(CGFloat(min(1, nIn * 2)) * CGFloat(1 - nOut))
        fillShadowed(rr(r, 32), white.alpha(0.98), blur: 36, alpha: 0.28)
        ctx.saveGState(); ctx.addPath(rr(CGRect(x: r.minX + 22, y: r.minY + 24, width: 80, height: 80), 20)); ctx.clip()
        drawImage(owlIcon, in: CGRect(x: r.minX + 22, y: r.minY + 24, width: 80, height: 80)); ctx.restoreGState()
        text("OWLY", 24, ui, grey, r.minX + 124, r.minY + 50, kern: 1)
        text("now", 24, body, grey, r.maxX - 28, r.minY + 50, align: 1)
        text("Done by Leo: Practice piano", 36, ui, ink, r.minX + 124, r.minY + 98)
        ctx.restoreGState()
    }
}

/// Know when your day is full: the real load bar lifts off the screen; a scribe's circle marks it.
let loadRegion = CGRect(x: 40, y: 340, width: 1126, height: 216)
let loadTarget = CGRect(x: 120, y: 540, width: 940, height: 200)
func dayScene(_ t: Double) {
    fill(fullCanvas(), paper)
    Kinetic(lines: ["Know when your", "day is full."], face: serif, size: 112, colour: ink, x: 120, y: 300,
            from: T.toDay + 0.1, enter: .rise, maxWidth: nil).draw(t)
    fill(CGPath(ellipseIn: centred(CGPoint(x: 1440, y: 560), 420), transform: nil), sage)
    let e = outCubic(prog(t, T.toDay - 0.1, T.toDay + 0.5))
    let phone = drawScreen(dayFull, in: CGRect(x: 1215, y: 60 + 80 * CGFloat(1 - e), width: 450, height: 960), radius: 48)
    callout(dayFull, region: loadRegion, screenRect: phone, to: loadTarget, p: prog(t, T.callout, T.callout + 0.5), plate: white)
    if t >= T.callout + 0.5 {
        let r = fitted(dayFull.snapped(loadRegion), in: loadTarget)
        scribbleCircle(around: r.insetBy(dx: -18, dy: -14), p: prog(t, T.scribble, T.scribble + 0.7), colour: green, width: 6, seed: 3)
    }
}

/// End card: icon, name, the price line, a truthful CTA, and the quill.
func endScene(_ t: Double) {
    ruledPaper()
    let ip = outBack(prog(t, T.toEnd - 0.25, T.toEnd + 0.2), 1.6)
    if ip > 0 {
        let s = 230 * CGFloat(ip)
        let r = CGRect(x: 960 - s / 2, y: 300 - s / 2, width: s, height: s)
        fillShadowed(rr(r, 46 * CGFloat(ip)), white, blur: 30, alpha: 0.2)
        ctx.saveGState(); ctx.addPath(rr(r, 46 * CGFloat(ip))); ctx.clip(); drawImage(owlIcon, in: r); ctx.restoreGState()
    }
    Kinetic(lines: ["Owly the Scribe"], face: serif, size: 120, colour: ink, x: 960, y: 570, from: T.toEnd + 0.3,
            enter: .rise, exit: .none, align: 0.5, maxWidth: nil).draw(t)
    Kinetic(lines: ["Family to-do lists. No subscription."], face: body, size: 46, colour: ink.alpha(0.75), x: 960, y: 652,
            from: T.toEnd + 0.6, enter: .fade, exit: .none, align: 0.5, maxWidth: nil).draw(t)
    let cp = outCubic(prog(t, T.toEnd + 0.9, T.toEnd + 1.3))
    if cp > 0 {
        let label = "Coming soon to the App Store"
        let w = textWidth(label, 44, ui) + 104
        let pill = CGRect(x: 960 - w / 2, y: 716 + 24 * CGFloat(1 - cp), width: w, height: 94)
        ctx.saveGState(); ctx.setAlpha(CGFloat(cp)); fill(rr(pill, 47), green)
        text(label, 44, ui, white, 960, pill.minY + 62, align: 0.5); ctx.restoreGState()
    }
    drawDrawing(quill, in: CGRect(x: 1440, y: 400, width: 200, height: 200), draw: prog(t, T.toEnd + 0.5, T.toEnd + 1.8),
                fill: prog(t, T.toEnd + 1.4, T.toEnd + 1.9))
}

let reel = Reel([
    Clip(from: 0, to: T.toShare, draw: hookScene),
    Clip(from: T.toShare, to: T.toDay, draw: shareScene),
    Clip(from: T.toDay, to: T.toEnd, draw: dayScene),
    Clip(from: T.toEnd, to: 23, draw: endScene),
], joins: [(.shape(.blob(seed: 3), CGPoint(x: 1480, y: 740)), 0.7), (.cover(.left), 0.55), (.dip(paper), 0.5)])

func frame(_ t: Double) {
    reel.draw(t)
}

// MARK: - Sound

let recipe = Recipe(
    bpm: T.bpm, swing: 0.18, key: 2, mode: .lydian, progression: [1, 2, 6, 5], barsPerChord: 1, chordColour: .add9, kit: .acoustic,
    drums: Drums(kick: "X.......x.x.....", rim: "....x.......x...", shaker: "x.x.x.x.x.x.x.x."),
    parts: [
        Part(synth: .piano, rhythm: "X_______x_______", notes: .chord, octave: 4, gain: 0.3, reverb: 0.3),
        Part(synth: .sub, rhythm: "X_______x___x___", notes: .root, octave: 2, gain: 0.4),
        Part(synth: .kalimba, rhythm: "..x...x...x.x...", notes: .motif, octave: 5, gain: 0.15, reverb: 0.2, echo: 0.3, from: 2),
        Part(synth: .strings, rhythm: "X_______________", notes: .chord, octave: 4, gain: 0.16, reverb: 0.3, from: 3),
    ],
    space: .studio, colour: .tape, sidechain: 0.25, seed: 52)

func score(_ s: Score) {
    s.compose(recipe, [Section(from: 0, to: T.toShare, energy: 1), Section(from: T.toShare, to: T.toDay, energy: 3),
                       Section(from: T.toDay, to: T.toEnd, energy: 2), Section(from: T.toEnd, to: 23, energy: 0)])
    s.cue(0, "Still texting", stampHit(), 0.35); s.cue(0.25, "reminders?", stampHit(), 0.3)
    for at in T.bubbles.dropFirst() { s.cue(at, "message", bubble(), 0.45) }
    s.cue(T.owl, "owl", bloop(), 0.4)
    s.cue(T.toShare - 0.35, "blob", whoosh(0.7), 0.22)
    s.cue(T.pick, "pick", click(), 0.3)
    s.cue(T.send, "send", whoosh(T.land - T.send, up: true), 0.22); s.cue(T.land, "land", pop(700), 0.35)
    s.cue(T.tap, "tap", click(), 0.35); s.cue(T.tap + 0.1, "tick", pop(900), 0.35)
    s.cue(T.notice, "done by Leo", ding(), 0.3)
    s.cue(T.momTick, "Mom's tick", pop(900), 0.25)
    s.cue(T.toDay - 0.3, "cover", pageFlip(), 0.45)
    s.cue(T.callout, "lift", bloop(), 0.35)
    s.cue(T.scribble, "scribble", penScribble(0.7), 0.4)
    s.cue(T.toEnd - 0.25, "dip", swish(), 0.22)
    s.cue(T.toEnd - 0.05, "icon", thumpSnd(), 0.5)
    s.cue(T.toEnd + 0.5, "quill", penScribble(1.2), 0.3)
    s.cadence(recipe, at: T.toEnd, length: 5.5, synth: .strings, gain: 0.45)
    s.fadeOut = (21.6, 22.95)
}
