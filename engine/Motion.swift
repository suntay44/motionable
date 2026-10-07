// motionable engine: reusable motion pieces. Kinetic headlines, stamps, reveals, camera,
// and the store end card (badges follow Apple's and Google's rules; see rules.md).
import AppKit

// MARK: - Headlines

/// A left-aligned headline that reveals line by line from behind a mask and leaves upward,
/// with optional smaller lines underneath.
struct Headline {
    let from, to: Double
    let lines: [String]
    var sub: [String] = []
    var colour: Col
}

/// Draws whichever headlines are on screen at `t`. Lines auto-fit to `maxWidth`.
func drawHeadlines(_ list: [Headline], _ t: Double, x: CGFloat = 72, top: CGFloat = 370,
                   size base: CGFloat = 112, maxWidth: CGFloat = 880, subSize: CGFloat = 40) {
    for l in list where t >= l.from && t < l.to {
        let widest = l.lines.map { textWidth($0, base, .heavy, kern: -3) }.max() ?? 0
        let size = widest > 0 ? min(base, base * maxWidth / widest) : base
        let gone = inCubic(prog(t, l.to - 0.2, l.to))
        var y = top
        for (i, s) in l.lines.enumerated() {
            let e = outCubic(prog(t, l.from + Double(i) * 0.07, l.from + Double(i) * 0.07 + 0.36))
            ctx.saveGState()
            ctx.clip(to: CGRect(x: 0, y: y - size * 0.98, width: W, height: size * 1.24))
            text(s, size, .heavy, l.colour, x, y + size * CGFloat(1 - e) - size * 1.1 * CGFloat(gone), kern: -3)
            ctx.restoreGState()
            y += size
        }
        y = top + size * CGFloat(l.lines.count - 1) + subSize * 1.9
        let se = outCubic(prog(t, l.from + 0.22, l.from + 0.55)) * (1 - gone)
        ctx.saveGState(); ctx.setAlpha(CGFloat(se))
        for s in l.sub {
            text(s, subSize, .semibold, l.colour.alpha(0.82), x, y + 18 * CGFloat(1 - se))
            y += subSize * 1.3
        }
        ctx.restoreGState()
    }
}

/// Scale for a word that stamps in at `at` (1.22 → 1 over 0.14 s). Use around the word's centre.
func stampScale(_ t: Double, at: Double, overshoot: Double = 0.22) -> CGFloat {
    CGFloat(1 + overshoot * (1 - outCubic(prog(t, at, at + 0.14))))
}

/// Text that rises in at `at` (fade + 40 px lift over 0.4 s).
func riseText(_ s: String, _ size: CGFloat, _ w: NSFont.Weight, _ c: Col, _ x: CGFloat, _ y: CGFloat,
              at: Double, t: Double, align: CGFloat = 0.5, kern: CGFloat = 0) {
    guard t >= at else { return }
    let e = outCubic(prog(t, at, at + 0.4))
    ctx.saveGState(); ctx.setAlpha(CGFloat(e))
    text(s, size, w, c, x, y + 40 * CGFloat(1 - e), align: align, kern: kern)
    ctx.restoreGState()
}

// MARK: - Reveals and camera

/// Draws `paint` inside a circle growing from `from` (p = 0…1). Paint the old background first.
func circleReveal(from: CGPoint, _ p: Double, _ paint: () -> Void) {
    ctx.saveGState()
    ctx.addPath(CGPath(ellipseIn: centred(from, hypot(W, H) * 1.05 * CGFloat(outCubic(p))), transform: nil))
    ctx.clip()
    paint()
    ctx.restoreGState()
}

/// Applies a camera to everything drawn after it (wrap in save/restoreGState): scale about the centre plus shake.
func applyCamera(scale: Double, shake: Double = 0, t: Double = 0) {
    let dx = CGFloat(shake * sin(t * 97)), dy = CGFloat(shake * cos(t * 83))
    ctx.translateBy(x: W / 2 + dx, y: H / 2 + dy)
    ctx.scaleBy(x: CGFloat(scale), y: CGFloat(scale))
    ctx.translateBy(x: -W / 2, y: -H / 2)
}
/// A small zoom that breathes on every beat (add to the camera scale).
func beatPulse(_ t: Double, beat: Double, amount: Double = 0.006) -> Double {
    amount * exp(-t.truncatingRemainder(dividingBy: beat) * 14)
}
/// Shake amplitude from hits [(time, pixels, decay)] — the strongest live one wins.
func shake(_ t: Double, _ hits: [(at: Double, px: Double, decay: Double)]) -> Double {
    hits.filter { t >= $0.at }.map { $0.px * exp(-(t - $0.at) * $0.decay) }.max() ?? 0
}

/// Drains the frame to grey (amount 0…1), except inside a circle growing back from `restoreFrom`
/// when `restore` > 0 — the "offline → back online" colour flood.
func desaturate(_ amount: Double, restoreFrom: CGPoint = .zero, restore: Double = 0) {
    guard amount > 0 else { return }
    ctx.saveGState()
    if restore > 0 {
        let p = CGMutablePath(); p.addRect(CGRect(x: 0, y: 0, width: W, height: H))
        p.addEllipse(in: centred(restoreFrom, hypot(W, H) * 1.05 * CGFloat(outCubic(restore))))
        ctx.addPath(p); ctx.clip(using: .evenOdd)
    }
    ctx.setBlendMode(.saturation)
    fill(CGRect(x: 0, y: 0, width: W, height: H), Col(0x808080, CGFloat(amount)))
    ctx.setBlendMode(.normal)
    fill(CGRect(x: 0, y: 0, width: W, height: H), Col(0x000000, CGFloat(0.18 * amount)))
    ctx.restoreGState()
}

// MARK: - Store end card

/// Apple's "Download on the App Store" badge. The user downloads it from Apple
/// (https://toolbox.marketingtools.apple.com/app-store/) into assets/ — it is never bundled.
/// Rules: never modify, angle or animate it; it cuts in and holds still; keep a quarter of its
/// height clear around it; it goes first when other store badges or lines appear.
func drawAppStoreBadge(_ badge: CGImage, centre: CGPoint, height: CGFloat) -> CGRect {
    let w = height * CGFloat(badge.width) / CGFloat(badge.height)
    let r = CGRect(x: centre.x - w / 2, y: centre.y - height / 2, width: w, height: height)
    drawImage(badge, in: r)
    return r
}
/// Emphasis that leaves the badge untouched: a ring of our own pulsing out behind it,
/// starting outside its clear space. p = 0…1 over the pulse.
func glowRing(around r: CGRect, _ p: Double, colour: Col = Col(0xFFFFFF)) {
    guard p > 0 && p < 1 else { return }
    let clear = r.height / 4 + 4
    let ring = r.insetBy(dx: -(clear + 70 * CGFloat(outCubic(p))), dy: -(clear + 70 * CGFloat(outCubic(p))))
    stroke(rr(ring, ring.height / 2), colour.alpha(CGFloat(0.7 * (1 - p))), 5)
}

// MARK: - Entrances and exits for anything

/// How a thing enters or leaves: images, screens, cards, stickers, icons, illustrations, or a whole text block
/// (Kinetic's own `TextIn` moves letters, words and lines; use `.none` there and `show` to move the block).
/// For slides and flies, the side is where the thing is while hidden: it comes in from there, and leaves toward it.
enum Appear {
    case cut               // just there, or just gone
    case fade
    case pop               // grows from 60 % with a small overshoot: small things only (stickers, icons, chips, avatars)
    case zoom              // grows from 88 % while fading in, no overshoot: cards, screens, photos
    case rise              // comes up 80 px while fading in
    case drop              // falls in from above and settles: small things
    case slide(Side)       // travels in from a side while fading in
    case fly(Side)         // comes in from beyond the frame's edge on that side, without a fade
    case wipe(Side)        // revealed by an edge moving away from that side
    case iris              // a circle opens from its centre
    case blur              // sharpens out of a blur while fading in
    case flip              // turns in like a card on its vertical axis
    case spin              // turns in from a quarter turn while growing
}

/// Draws `draw` (everything inside `rect`) entering at `from` and, if `until` is set, leaving so that it's gone at `until`.
/// `length` is the entrance's duration; an exit takes 80 % of it. Text inside isn't counted as readable by `check`
/// while it moves. Example: `show(card, t: t, from: T.cards, enter: .slide(.left)) { drawScreen(shot, in: card) }`.
func show(_ rect: CGRect, t: Double, from: Double, until: Double? = nil, enter: Appear = .fade, exit: Appear = .fade,
          length: Double = 0.45, _ draw: () -> Void) {
    guard t >= from else { return }
    let cutsIn: Bool = { if case .cut = enter { return true }; return false }()
    let cutsOut: Bool = { if case .cut = exit { return true }; return false }()
    let pIn = length > 0 && !cutsIn ? prog(t, from, from + length) : 1
    let pOut = until.map { u in length > 0 && !cutsOut ? prog(t, u - length * 0.8, u) : (t >= u ? 1 : 0) } ?? 0
    guard pOut < 1 else { return }
    let moving = pIn < 1 || pOut > 0
    appearing(exit, visible: 1 - pOut, entering: false, rect) {
        appearing(enter, visible: pIn, entering: true, rect) {
            if moving { unlogged(draw) } else { draw() }
        }
    }
}

/// One motion at `visible` (0 hidden … 1 fully shown). Entrances ease out; exits ease in.
func appearing(_ m: Appear, visible v: Double, entering: Bool, _ r: CGRect, _ draw: () -> Void) {
    if v >= 1 { draw(); return }
    guard v > 0 else { return }
    let e = CGFloat(entering ? outCubic(v) : 1 - inCubic(1 - v))
    let c = CGPoint(x: r.midX, y: r.midY)
    var alpha: CGFloat = 1, scaleX: CGFloat = 1, scaleY: CGFloat = 1, dx: CGFloat = 0, dy: CGFloat = 0, rot: CGFloat = 0
    var clip: CGPath? = nil
    switch m {
    case .cut: break
    case .fade: alpha = e
    case .pop:
        let k = entering ? CGFloat(outBack(v, 1.5)) : e
        scaleX = 0.6 + 0.4 * k; scaleY = scaleX; alpha = CGFloat(min(1, v * 3))
    case .zoom: scaleX = 0.88 + 0.12 * e; scaleY = scaleX; alpha = e
    case .rise: dy = 80 * (1 - e); alpha = e
    case .drop:
        let k = entering ? CGFloat(outBack(v, 1.3)) : e
        dy = -140 * (1 - k); alpha = CGFloat(min(1, v * 3))
    case .slide(let side):
        let d = (side == .left || side == .right ? W : H) * 0.18 * (1 - e)
        switch side { case .left: dx = -d; case .right: dx = d; case .up: dy = -d; case .down: dy = d }
        alpha = e
    case .fly(let side):
        switch side {
        case .left: dx = -(r.maxX + 40) * (1 - e)
        case .right: dx = (W - r.minX + 40) * (1 - e)
        case .up: dy = -(r.maxY + 40) * (1 - e)
        case .down: dy = (H - r.minY + 40) * (1 - e)
        }
    case .wipe(let side):
        let pad: CGFloat = 60, b = r.insetBy(dx: -pad, dy: -pad)
        switch side {
        case .left: clip = CGPath(rect: CGRect(x: b.minX, y: b.minY, width: b.width * e, height: b.height), transform: nil)
        case .right: clip = CGPath(rect: CGRect(x: b.maxX - b.width * e, y: b.minY, width: b.width * e, height: b.height), transform: nil)
        case .up: clip = CGPath(rect: CGRect(x: b.minX, y: b.minY, width: b.width, height: b.height * e), transform: nil)
        case .down: clip = CGPath(rect: CGRect(x: b.minX, y: b.maxY - b.height * e, width: b.width, height: b.height * e), transform: nil)
        }
    case .iris:
        clip = CGPath(ellipseIn: centred(c, hypot(r.width, r.height) / 2 * e + 1), transform: nil)
    case .blur:
        let img = layer(draw)
        drawLayer(gaussianBlurred(img, sigma: Double(26 * (1 - e))), alpha: e)
        return
    case .flip: scaleX = max(0.002, e); alpha = min(1, e * 2)
    case .spin: rot = (1 - e) * .pi / 2; scaleX = 0.7 + 0.3 * e; scaleY = scaleX; alpha = e
    }
    ctx.saveGState()
    if let clip { ctx.addPath(clip); ctx.clip() }
    ctx.translateBy(x: c.x + dx, y: c.y + dy)
    if rot != 0 { ctx.rotate(by: rot) }
    ctx.scaleBy(x: scaleX, y: scaleY)
    ctx.translateBy(x: -c.x, y: -c.y)
    ctx.setAlpha(alpha)
    ctx.beginTransparencyLayer(auxiliaryInfo: nil)        // so nested fades multiply, whatever `draw` does with alpha
    draw()
    ctx.endTransparencyLayer()
    ctx.restoreGState()
}
