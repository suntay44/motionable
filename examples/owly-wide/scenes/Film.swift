// Owly the Scribe — demo film (16:9, 25 s). Direction: DIRECTION.md · beat grid: SCRIPT.md.
// Problem hook (texting reminders) → the signature: a list lands on Leo's widget, he ticks it, Mom sees "Done by Leo"
// → know when your day is full → end card with a drawn quill.
import AppKit

func makeFilm() -> Film {
    Film(name: "owly-wide", width: 1920, height: 1080, fps: 60, duration: 25, bpm: T.bpm,
         holdFrom: T.hold, draw: frame, score: score, keyframes: [3.4, 6.3, 7.7, 10.1, 12.6, 18.0, 24.5])
}

// MARK: - Timeline (88 BPM)

enum T {
    static let bpm = 88.0, beat = 60 / bpm
    static func b(_ n: Double) -> Double { n * beat }
    static let bubbles = [-0.1, b(1), b(2)]
    static let owl = b(2.5), meet = b(3)                 // the owl fills the lower right early: no empty stretch
    static let toShare = b(6)                          // Mom's phone slides in
    static let momPlus = b(6.8), momAdd = b(10.2)      // her recording: she taps +, types "Pack gym clothes", taps Add
    static let send = b(11.5), land = b(12.5)          // the task travels to Leo's phone
    static let leoTap = b(13.5)                        // his recording: he ticks it on his widget
    static let notice = b(15), momTick = b(15.5)       // "Done by Leo" on Mom's phone, and her list ticks too
    static let toDay = b(20), callout = b(22), scribble = b(23)
    static let toEnd = b(28)
    static let hold = 23.4
}

// MARK: - Look

let green = Col(0x0F9B3E), paper = Col(0xF7F4EC), sage = Col(0xE4ECDF), ink = Col(0x1E2A22)
let night = Col(0x1B2235), dusk = Col(0x2E3A5C), white = Col(0xFFFFFF), grey = Col(0x8A8A8E)
let serif = Face.system(.bold, .serif), body = Face.system(.medium), ui = Face.system(.semibold)
// Type mix: New York bold, with the feeling phrase in New York italic, in a deeper Owly green that keeps text contrast
// on paper and sage (the brand green itself is for shapes).
let greenInk = Col(0x0B7A31)
let feeling = TextStyle(face: Face.system(.bold, .serif).italic, colour: greenInk)
let dayFull = Screenshot("assets/over.png"), owlIcon = loadImage("assets/owly-logo.png")
// The app working: two real screen recordings from the Simulator (scripts/footage.sh shows their timelines).
let momRec = Footage("assets/mom-adds-task.mp4"), leoRec = Footage("assets/sons-widget.mp4")
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
    Kinetic(lines: ["Still texting", "*reminders?*"], face: serif, size: 132, colour: ink, x: 140, y: 400,
            from: -0.32, enter: .stamp, exit: .none, maxWidth: nil, stagger: 0.16, accent: feeling).draw(t)
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

/// The signature, on the app's own recordings: Mom adds "Pack gym clothes" on her phone; it lands on Leo's widget;
/// he ticks it; "Done by Leo" arrives on Mom's phone and her list ticks too.
let momPhone = CGRect(x: 740, y: 120, width: 386, height: 840), leoPhone = CGRect(x: 1300, y: 120, width: 386, height: 840)
let fullFrame = CGRect(x: 0, y: 0, width: 1206, height: 2622)
// Film time → recording time: through the waits, at speed through the typing, freezing on each result.
let momPlay = Playback([(T.toShare - 0.1, 0.3), (T.momPlus, 0.68), (T.momPlus + 0.65, 3.2), (T.momPlus + 0.8, 4.4),
                        (T.momPlus + 1.85, 6.8), (T.momAdd, 9.04), (T.momAdd + 0.6, 10.5), (T.momAdd + 1.0, 10.7)])
let leoPlay = Playback([(T.land - 0.4, 0.5), (T.leoTap, 1.4), (T.leoTap + 0.45, 3.7), (T.leoTap + 0.9, 4.3), (T.leoTap + 1.3, 4.5)])
// The camera inside each phone: in on the typing, back out for Add; in on Leo's widget.
let typingView = CGRect(x: 0, y: 220, width: 860, height: 1870), widgetView = CGRect(x: 0, y: 150, width: 900, height: 1957)
let momZoom = Zoom([(T.momPlus + 0.6, fullFrame), (T.momPlus + 0.95, typingView), (T.momPlus + 1.9, typingView), (T.momAdd - 0.15, fullFrame)])
let leoZoom = Zoom([(T.land + 0.1, fullFrame), (T.land + 0.5, widgetView)])
// Fingers on the recorded taps (positions from the recording's tap log, in its pixels).
let tapPlus = TouchPath([(T.momPlus - 0.35, CGPoint(x: 990, y: 2340)), (T.momPlus, CGPoint(x: 1062, y: 2253))], taps: [T.momPlus])
let tapAdd = TouchPath([(T.momAdd - 0.35, CGPoint(x: 990, y: 420)), (T.momAdd, CGPoint(x: 1062, y: 300))], taps: [T.momAdd])
let tapTick = TouchPath([(T.leoTap - 0.35, CGPoint(x: 260, y: 680)), (T.leoTap, CGPoint(x: 157, y: 575))], taps: [T.leoTap])

func shareScene(_ t: Double) {
    fill(fullCanvas(), sage)
    Kinetic(lines: ["Make a list", "for *your son.*"], face: serif, size: 96, colour: ink, x: 120, y: 470,
            from: T.toShare + 0.4, enter: .rise, maxWidth: nil, accent: feeling).draw(t)       // after the blob has opened
    func onMom(_ p: CGPoint) -> CGPoint { canvasPoint(p, region: footageRegion(momRec, momZoom.region(t), momPhone), drawnIn: momPhone) }
    func onLeo(_ p: CGPoint) -> CGPoint { canvasPoint(p, region: footageRegion(leoRec, leoZoom.region(t), leoPhone), drawnIn: leoPhone) }
    let k = momPhone.width / footageRegion(momRec, momZoom.region(t), momPhone).width

    // Mom's phone comes in from the left, playing her recording.
    show(momPhone, t: t, from: T.toShare - 0.1, enter: .slide(.left), length: 0.6) {
        drawFootage(momRec, at: momPlay.at(t), region: momZoom.region(t), in: momPhone, cover: true, radius: 54)
        // When Leo ticks it, Mom's list ticks too (it syncs): her row greys, strikes through and ticks.
        let mt = prog(t, T.momTick, T.momTick + 0.4)
        if mt > 0 {
            tick(at: onMom(CGPoint(x: 122, y: 987.5)), radius: 29 * k, p: mt)
            let a = onMom(CGPoint(x: 224, y: 958))
            fill(CGRect(x: a.x, y: a.y, width: 410 * k, height: 60 * k), white.alpha(0.5 * CGFloat(mt)))   // text spans x 229–625
            line(onMom(CGPoint(x: 229, y: 990)), onMom(CGPoint(x: 229 + 396 * CGFloat(prog(mt, 0.4, 1)), y: 990)), grey, 4 * k)
        }
        tapPlus.draw(t, map: onMom); tapAdd.draw(t, map: onMom)
    }
    // Leo's phone comes in from the right as the task lands, playing his recording.
    show(leoPhone, t: t, from: T.land - 0.35, enter: .slide(.right), length: 0.6) {
        drawFootage(leoRec, at: leoPlay.at(t), region: leoZoom.region(t), in: leoPhone, cover: true, radius: 54)
        tapTick.draw(t, map: onLeo)
    }
    // The task travelling from Mom's new row to the same row on Leo's widget.
    let fp = prog(t, T.send, T.land)
    if fp > 0 && fp < 1 {
        let a = onMom(CGPoint(x: 640, y: 987)), z = CGPoint(x: leoPhone.minX + 60, y: leoPhone.minY + 180)
        let u = CGFloat(inOut(fp)), v = 1 - u
        let mid = CGPoint(x: (a.x + z.x) / 2, y: min(a.y, z.y) - 160)
        let p = CGPoint(x: v * v * a.x + 2 * v * u * mid.x + u * u * z.x, y: v * v * a.y + 2 * v * u * mid.y + u * u * z.y)
        fill(CGPath(ellipseIn: centred(p, 30), transform: nil), green.alpha(0.2))
        fill(CGPath(ellipseIn: centred(p, 16), transform: nil), green)
    }
    // "Done by Leo" arrives on Mom's phone (Owly's real notification wording), lifted so it reads.
    let nIn = outCubic(prog(t, T.notice, T.notice + 0.4)), nOut = inCubic(prog(t, T.toDay - 0.45, T.toDay - 0.1))
    if nIn > 0 && nOut < 1 {
        let r = CGRect(x: momPhone.midX - 320, y: lerp(-40, 70, nIn) - 200 * CGFloat(nOut), width: 640, height: 124)
        ctx.saveGState(); ctx.setAlpha(CGFloat(min(1, nIn * 2)) * CGFloat(1 - nOut))
        fillShadowed(rr(r, 32), white.alpha(0.98), blur: 36, alpha: 0.28)
        ctx.saveGState(); ctx.addPath(rr(CGRect(x: r.minX + 22, y: r.minY + 22, width: 80, height: 80), 20)); ctx.clip()
        drawImage(owlIcon, in: CGRect(x: r.minX + 22, y: r.minY + 22, width: 80, height: 80)); ctx.restoreGState()
        text("OWLY", 24, ui, grey, r.minX + 124, r.minY + 48, kern: 1)
        text("now", 24, body, grey, r.maxX - 28, r.minY + 48, align: 1)
        text("Done by Leo: Pack gym clothes", 34, ui, ink, r.minX + 124, r.minY + 94)
        ctx.restoreGState()
    }
}

/// Know when your day is full: the real load bar lifts off the screen; a scribe's circle marks it.
let loadRegion = CGRect(x: 40, y: 340, width: 1126, height: 216)
let loadTarget = CGRect(x: 120, y: 540, width: 940, height: 200)
func dayScene(_ t: Double) {
    fill(fullCanvas(), paper)
    Kinetic(lines: ["Know when your", "*day is full.*"], face: serif, size: 112, colour: ink, x: 120, y: 300,
            from: T.toDay + 0.1, enter: .rise, maxWidth: nil, accent: feeling).draw(t)
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
    Kinetic(lines: ["Owly the *Scribe*"], face: serif, size: 120, colour: ink, x: 960, y: 570, from: T.toEnd + 0.3,
            enter: .rise, exit: .none, align: 0.5, maxWidth: nil, accent: feeling).draw(t)
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
    Clip(from: T.toEnd, to: 25, draw: endScene),
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
                       Section(from: T.toDay, to: T.toEnd, energy: 2), Section(from: T.toEnd, to: 25, energy: 0)])
    s.cue(0, "Still texting", stampHit(), 0.35); s.cue(0.25, "reminders?", stampHit(), 0.3)
    for at in T.bubbles.dropFirst() { s.cue(at, "message", bubble(), 0.45) }
    s.cue(T.owl, "owl", bloop(), 0.4)
    s.cue(T.toShare - 0.35, "blob", whoosh(0.7), 0.22)
    // Sounds on the recorded events, placed through the playback's film times.
    s.cue(T.momPlus, "+ tap", click(), 0.35); s.cue(T.momPlus + 0.1, "sheet", whoosh(0.4), 0.15)
    for key in [4.8, 5.85, 6.6] { s.cue(momPlay.filmTime(of: key), "typing", keyTap(), 0.3) }
    s.cue(T.momAdd, "Add", click(), 0.35); s.cue(momPlay.filmTime(of: 10.0), "added", pop(760), 0.3)
    s.cue(T.send, "send", whoosh(T.land - T.send, up: true), 0.22); s.cue(T.land, "land", pop(700), 0.3)
    s.cue(T.leoTap, "tap", click(), 0.35); s.cue(leoPlay.filmTime(of: 3.9), "tick", pop(900), 0.35)
    s.cue(T.notice, "done by Leo", ding(), 0.3)
    s.cue(T.momTick, "Mom's tick", pop(900), 0.25)
    s.cue(T.toDay - 0.3, "cover", pageFlip(), 0.45)
    s.cue(T.callout, "lift", bloop(), 0.35)
    s.cue(T.scribble, "scribble", penScribble(0.7), 0.4)
    s.cue(T.toEnd - 0.25, "dip", swish(), 0.22)
    s.cue(T.toEnd - 0.05, "icon", thumpSnd(), 0.5)
    s.cue(T.toEnd + 0.5, "quill", penScribble(1.2), 0.3)
    s.cadence(recipe, at: T.toEnd, length: 5.5, synth: .strings, gain: 0.45)
    s.fadeOut = (23.6, 24.95)
}
