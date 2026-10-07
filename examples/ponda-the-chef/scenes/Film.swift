// Ponda the Chef — demo film (9:16, 30 s). Direction: DIRECTION.md · beat grid: SCRIPT.md.
// Problem hook ("Cooking for 40?") → scale (signature) → cost per plate → one list → proof → end card.
import AppKit

func makeFilm() -> Film {
    Film(name: "ponda-the-chef", width: 1080, height: 1920, fps: 60, duration: 30, bpm: T.bpm,
         holdFrom: T.hold, draw: frame, score: score, keyframes: [2.6, 7.6, 13.2, 18.8, 24.0, 29.5])
}

// MARK: - Timeline (122 BPM)

enum T {
    static let bpm = 122.0, beat = 60 / bpm
    static func b(_ n: Double) -> Double { n * beat }
    static let line2 = b(2)                     // "Ponda's got it." with Ponda
    static let toScale = b(6)
    static let tapServings = b(8), roll = (b(9), b(13))
    static let toCost = b(18), callout = b(20)
    static let toList = b(28), listTotal = b(36)
    static let toProof = b(40)
    static let chips = [b(41), b(42), b(43)]
    static let toEnd = b(50)
    static let hold = 28.4
}

// MARK: - Look

let red = Col(0xB4232D), redDeep = Col(0x9A1D26), blush = Col(0xFDEBEC), offWhite = Col(0xFAF8F7)
let ink = Col(0x1C1C1E), cream = Col(0xFFF6EE)
let head = Face.named("AvenirNext-Heavy"), body = Face.named("AvenirNext-DemiBold")
let uiRegular = Face.system(.regular), uiBold = Face.system(.bold)
// Type mix: one geometric face; numbers are the hero (bigger), and each benefit's key word takes Ponda red.
let bigNumber = TextStyle(scale: 1.22), redWord = TextStyle(colour: red)

let pondaClosed = loadImage("assets/mascot-pose-1.png"), pondaOpen = loadImage("assets/mascot-pose-2.png")
let pondaHappy = loadImage("assets/mascot-pose-3.png"), appIcon = loadImage("assets/logo-icon.png")
let shotScaling = Screenshot("assets/screen-scaling.png"), shotDetail = Screenshot("assets/screen-detail.png")
let shotCart = Screenshot("assets/screen-cart.png")

/// Ponda, talking on the 8ths while `talking`; bobbing on the beat.
func drawPonda(at c: CGPoint, size: CGFloat, t: Double, talking: Bool, happy: Bool = false, pop: Double = 1) {
    guard pop > 0 else { return }
    let open = talking && Int(floor(t / (T.beat / 2))) % 2 == 0
    let img = happy ? pondaHappy : (open ? pondaOpen : pondaClosed)
    let s = size * CGFloat(outBack(min(1, pop), 1.7))
    let dy = 8 * CGFloat(sin(2 * .pi * t / T.beat))
    drawImage(img, in: CGRect(x: c.x - s / 2, y: c.y - s / 2 + dy, width: s, height: s))
}

// MARK: - Scenes

/// Hook: plates multiply from 4 to 40 under the question.
func hookScene(_ t: Double) {
    fill(fullCanvas(), red)
    dotGrid(spacing: 46, radius: 3, colour: Col(0xFFFFFF, 0.07), t: t, drift: 14)
    // Both lines have landed before 0, so frame 1 already reads "Cooking for 40?" (the film opens on the impact).
    Kinetic(lines: ["Cooking", "for *40?*"], face: head, size: 190, colour: cream, x: 72, y: 470,
            from: -0.3, enter: .stamp, exit: .none, lineHeight: 1.12, stagger: 0.12, accent: bigNumber).draw(t)
    // 40 place settings: 4 at once, then the rest on the 16ths.
    let shown = t < 0.3 ? 4 : min(40, 4 + Int((t - 0.3) / (T.beat / 4)) * 2)
    for i in 0..<shown {
        let col = i % 10, row = i / 10
        let c = CGPoint(x: 140 + CGFloat(col) * 89, y: 760 + CGFloat(row) * 88)
        let born = i < 4 ? 0.0 : 0.3 + Double((i - 4) / 2) * T.beat / 4
        let pop = outBack(prog(t, born, born + 0.18), 2.2)
        fill(CGPath(ellipseIn: centred(c, 36 * CGFloat(pop)), transform: nil), Col(0xFFFFFF, 0.16))
        icon(.forkKnife, at: c, size: 46 * CGFloat(pop), colour: cream, weight: 2.4)
    }
    drawPonda(at: CGPoint(x: 540, y: 1480), size: 440, t: t, talking: t > T.line2 && t < T.line2 + 1.4,
              pop: prog(t, T.line2 - 0.05, T.line2 + 0.3))
    sticker("Ponda's got it.", at: CGPoint(x: 540, y: 1150), shape: .speech, fill: cream, ink: red, face: head,
            size: 52, degrees: -3, p: prog(t, T.line2, T.line2 + 0.25))
}

/// Benefit 1 (signature): the real Scaling screen; servings roll 4 → 40, the total $12.40 → $124.00.
let scaleRegion = CGRect(x: 0, y: 640, width: 1206, height: 1180)
func scaleScene(_ t: Double) {
    fill(fullCanvas(), offWhite)
    blobs(count: 3, colours: [blush, Col(0xF6D6D9)], t: t, seed: 4, alpha: 0.8, scale: 1.1)
    Kinetic(lines: ["Scale *any* recipe."], face: head, size: 112, colour: ink, x: 72, y: 400,
            from: T.toScale + 0.1, enter: .rise, accent: redWord).draw(t)
    let e = outCubic(prog(t, T.toScale, T.toScale + 0.5))
    let box = CGRect(x: 60, y: 500 + 120 * CGFloat(1 - e), width: 960, height: 960 * 1180 / 1206)
    let dest = drawScreen(shotScaling, region: scaleRegion, in: box, radius: 44, snap: false)
    let k = dest.width / scaleRegion.width
    func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { canvasPoint(CGPoint(x: x, y: y), region: scaleRegion, drawnIn: dest) }
    func area(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect { let o = pt(x, y); return CGRect(x: o.x, y: o.y, width: w * k, height: h * k) }
    // Repaint only what changes with servings, exactly where the screenshot has it (it matches at 40).
    let pax = Int((4 + 36 * outCubic(prog(t, T.roll.0, T.roll.1))).rounded())
    fill(area(990, 885, 130, 72), Col(0xFFFFFF))
    let v = pt(1108, 937); text("\(pax)", 52 * k, uiRegular, Col(0x000000), v.x, v.y, align: 1)
    fill(area(100, 1150, 760, 212), Col(0xFFFFFF))
    let l = pt(110, 1198); text("\(pax) PAX", 38 * k, uiBold, red, l.x, l.y, kern: 5.5 * k)
    let tot = pt(110, 1342); text(String(format: "$%.2f", Double(pax) * 3.10), 107 * k, uiBold, Col(0x000000), tot.x, tot.y)
    // UI acting: a finger comes in and taps the servings stepper, as a cook would.
    TouchPath([(T.tapServings - 0.45, pt(930, 1090)), (T.tapServings, pt(985, 925))], taps: [T.tapServings]).draw(t, colour: ink, size: 70)  // beside the number, so the roll stays visible
    sparkles(around: CGRect(x: tot.x, y: tot.y - 90 * k, width: 430 * k, height: 110 * k), t: t, from: T.roll.1, count: 7, colour: red, seed: 4)
}

/// Benefit 2: the cost card lifts off the real recipe screen.
let costRegion = CGRect(x: 30, y: 440, width: 1146, height: 400)
let costTarget = CGRect(x: 330, y: 700, width: 640, height: 240)
func costScene(_ t: Double) {
    fill(fullCanvas(), blush)
    blobs(count: 3, colours: [Col(0xF8D9DC), offWhite], t: t, seed: 12, alpha: 0.7, scale: 1.1)
    Kinetic(lines: ["Know what each", "*plate* costs."], face: head, size: 112, colour: ink, x: 72, y: 400,
            from: T.toCost + 0.1, enter: .rise, accent: redWord).draw(t)
    // Motion vocabulary: screens slide in from the side they sit on; stickers and chips pop.
    let box = CGRect(x: 60, y: 600, width: 520, height: 1240), screen = fitted(shotDetail.bounds, in: box)
    show(screen, t: t, from: T.toCost - 0.1, enter: .slide(.left), length: 0.5) { drawScreen(shotDetail, in: box, radius: 40) }
    let lp = prog(t, T.callout, T.callout + 0.5)
    callout(shotDetail, region: costRegion, screenRect: screen, to: costTarget, p: lp, plate: Col(0xFFFFFF))
    if lp >= 1 {
        let r = fitted(shotDetail.snapped(costRegion), in: costTarget)
        let k = r.width / shotDetail.snapped(costRegion).width
        let y = r.minY + (735 - shotDetail.snapped(costRegion).minY) * k
        underlineStroke(CGRect(x: r.minX + 870 * k, y: y, width: 260 * k, height: 12), p: prog(t, T.callout + 0.6, T.callout + 1.0),
                        colour: red, width: 7, style: .wave)
    }
}

/// Benefit 3: the cart scrolls down to the estimated total.
let cartMove = ScreenMove(shotCart, [(T.toList + 0.3, CGRect(x: 0, y: 280, width: 1206, height: 1150)),
                                     (T.listTotal, CGRect(x: 0, y: 1000, width: 1206, height: 1150))])
func listScene(_ t: Double) {
    fill(fullCanvas(), offWhite)
    Kinetic(lines: ["One list", "for *the week.*"], face: head, size: 112, colour: ink, x: 72, y: 400,
            from: T.toList + 0.1, enter: .rise, accent: redWord).draw(t)
    let region = cartMove.region(t)
    let dest = cartMove.draw(t, in: CGRect(x: 90, y: 640, width: 900, height: 1180), radius: 40)
    let total = canvasPoint(CGPoint(x: 1010, y: 2095), region: region, drawnIn: dest)
    sparkles(around: CGRect(x: total.x - 200, y: total.y - 60, width: 260, height: 90), t: t, from: T.listTotal, count: 6, colour: red, seed: 9)
}

/// Proof: three short facts as chips; Ponda waves.
func proofScene(_ t: Double) {
    fill(fullCanvas(), red)
    let facts: [(Icon, String)] = [(.book, "490+ dishes"), (.offline, "Works offline"), (.lock, "No account")]
    for (i, f) in facts.enumerated() {
        let p = prog(t, T.chips[i], T.chips[i] + 0.35)
        let x = 540 + 380 * CGFloat(1 - outCubic(p)) * (i % 2 == 0 ? -1 : 1)
        iconChip(f.0, f.1, at: CGPoint(x: x, y: 500 + CGFloat(i) * 200), p: p, fill: cream, ink: ink, disc: red, discInk: cream,
                 face: head, size: 64)
    }
    drawPonda(at: CGPoint(x: 540, y: 1430), size: 520, t: t, talking: false, happy: true, pop: prog(t, T.toProof, T.toProof + 0.35))
}

/// End card: icon, name, the site's line, a truthful CTA; Ponda peeks up from below.
func endScene(_ t: Double) {
    fill(fullCanvas(), offWhite)
    let ip = outBack(prog(t, T.toEnd - 0.25, T.toEnd + 0.2), 1.6)   // already arriving as the iris opens
    if ip > 0 {
        let s = 230 * CGFloat(ip)
        let r = CGRect(x: 540 - s / 2, y: 560 - s / 2, width: s, height: s)
        ctx.saveGState(); ctx.addPath(rr(r, 52 * CGFloat(ip))); ctx.clip(); drawImage(appIcon, in: r); ctx.restoreGState()
    }
    Kinetic(lines: ["Ponda the Chef"], face: head, size: 104, colour: ink, x: 540, y: 820, from: T.toEnd + 0.4, enter: .rise, exit: .none, align: 0.5).draw(t)
    Kinetic(lines: ["Scale any recipe. Know what it costs."], face: body, size: 44, colour: ink.alpha(0.8), x: 540, y: 900,
            from: T.toEnd + 0.7, enter: .fade, exit: .none, align: 0.5).draw(t)
    let label = "Coming soon to the App Store"
    let pw = textWidth(label, 40, head) + 90
    let pill = CGRect(x: 540 - pw / 2, y: 975, width: pw, height: 86)
    show(pill, t: t, from: T.toEnd + 1.0, enter: .pop, length: 0.4) {
        fill(rr(pill, 43), red)
        text(label, 40, head, cream, 540, pill.minY + 57, align: 0.5)
    }
    let peek = outCubic(prog(t, T.toEnd + 0.9, T.toEnd + 1.6))
    if peek > 0 { drawImage(pondaHappy, in: CGRect(x: 290, y: 1920 - 470 * CGFloat(peek), width: 500, height: 500)) }
}

let reel = Reel([
    Clip(from: 0, to: T.toScale, draw: hookScene),
    Clip(from: T.toScale, to: T.toCost, draw: scaleScene),
    Clip(from: T.toCost, to: T.toList, draw: costScene),
    Clip(from: T.toList, to: T.toProof, draw: listScene),
    Clip(from: T.toProof, to: T.toEnd, draw: proofScene),
    Clip(from: T.toEnd, to: 30, draw: endScene),
], joins: [(.slice(degrees: -18), 0.5), (.push(.left), 0.42),
           (.zoomThrough(CGPoint(x: 650, y: 820)), 0.5), (.columns(6), 0.5), (.iris(CGPoint(x: 540, y: 560)), 0.5)])

func frame(_ t: Double) {
    let pulse = t < T.hold ? beatPulse(t, beat: T.beat, amount: 0.004) : 0
    ctx.saveGState()
    applyCamera(scale: 1 + pulse)
    reel.draw(t)
    ctx.restoreGState()
}

// MARK: - Sound

let recipe = Recipe(
    bpm: T.bpm, swing: 0, key: 5, mode: .major, progression: [1, 5, 6, 4], barsPerChord: 1, chordColour: .add9, kit: .punchy,
    drums: Drums(kick: "X.....x.X.......", clap: "....X.......X...", hat: "x.x.x.x.x.x.x.x.", openHat: "..............x.",
                 shaker: "..x...x...x...x."),
    parts: [
        Part(synth: .guitar, rhythm: "x.x.x.x.x.x.x.x.", notes: .arpUpDown, octave: 4, gain: 0.2, reverb: 0.2),
        Part(synth: .sub, rhythm: "X..X..X.X..X..X.", notes: .root, octave: 2, gain: 0.45),
        Part(synth: .brass, rhythm: "X...............", notes: .chord, octave: 4, gain: 0.22, reverb: 0.25, ducked: false, from: 3),
    ],
    space: .room, colour: .bright, sidechain: 0.4, seed: 31)

func score(_ s: Score) {
    // Tempo phase: the problem ("Cooking for 40?") sits on a heavy half-time groove; the full groove lands with the fix.
    s.compose(recipe, [Section(from: 0, to: T.toScale, energy: 2, feel: .half), Section(from: T.toScale, to: T.toProof, energy: 3),
                       Section(from: T.toProof, to: T.toEnd, energy: 2), Section(from: T.toEnd, to: 30, energy: 0)])
    s.music.add(impact(), at: 0, gain: 0.8)
    s.cue(0, "Cooking for 40?", stampHit(), 0.6)
    for k in 0..<4 { s.cue(0.3 + Double(k) * T.beat, "plates", blips(4, spacing: T.beat / 4), 0.22) }
    s.cue(T.line2, "Ponda", boing(), 0.35)
    s.cue(T.toScale - 0.08, "slice", chop(), 0.8); s.cue(T.toScale, "slice", swish(), 0.3)
    s.cue(T.tapServings, "tap", click(), 0.4)
    s.cue(T.roll.0, "roll", blips(10, spacing: (T.roll.1 - T.roll.0) / 10), 0.25)
    s.cue(T.roll.1, "total", kaching(), 0.45); s.hit(recipe, at: T.roll.1, synth: .brass, gain: 0.3)
    s.cue(T.toCost - 0.2, "push", whoosh(0.42), 0.3)
    s.cue(T.callout, "lift", bloop(), 0.4); s.cue(T.callout + 0.45, "price", kaching(), 0.4)
    s.cue(T.toList - 0.25, "zoom", whoosh(0.5), 0.3)
    s.fx.add(sizzle(T.listTotal - T.toList), at: T.toList, gain: 0.14)
    s.cue(T.listTotal, "total", kaching(), 0.45)
    s.cue(T.toProof - 0.25, "columns", swish(), 0.3)
    for at in T.chips { s.cue(at, "chip", pop(700), 0.3) }
    s.cue(T.toEnd - 0.25, "iris", whoosh(0.45), 0.25)
    s.cue(T.toEnd - 0.05, "icon", thumpSnd(), 0.7)
    s.cue(T.toEnd + 0.4, "name", success(), 0.25)
    s.cadence(recipe, at: T.toEnd + 0.15, length: 4.5, synth: .ePiano, gain: 0.45)
    s.fadeOut = (28.6, 29.95)
}
