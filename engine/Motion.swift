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
