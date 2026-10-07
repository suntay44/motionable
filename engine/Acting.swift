// motionable engine: UI acting. The app's own interactions, performed on its real screens: text typed into a field
// with a caret, a finger (or cursor) moving and tapping, and a screen changing to its next state. Use them to make
// stills feel alive, or on top of footage to point at what the app is doing. Only act out what the app really does.
import AppKit

// MARK: - Typing

/// The moments at which each character of `text` lands when typed from `from` at about `cps` characters a second,
/// with a human rhythm: a little uneven, pausing after spaces and punctuation (seeded, so every render matches).
func typingTimes(_ text: String, from: Double, cps: Double = 12, seed: Int = 1) -> [Double] {
    var g = Seeded(UInt64(seed) &+ 71)
    var clock = from, out: [Double] = []
    for ch in text {
        var d = (0.7 + 0.6 * g.next()) / cps
        if ch == " " || ch == "," || ch == "." { d *= 1.7 }
        clock += d
        out.append(clock)
    }
    return out
}
/// When typing `text` from `from` is finished: put the next beat (or a sound) after it.
func typingEnds(_ text: String, from: Double, cps: Double = 12, seed: Int = 1) -> Double {
    typingTimes(text, from: from, cps: cps, seed: seed).last ?? from
}

/// Text typed into a field, with a caret: solid while typing, blinking when idle. `baseline` is where the field's text
/// starts (left end of its baseline, canvas units); match the app's font with `face` and `size`. `clear` first paints
/// a rect (the field's inside) in `clearColour`, hiding what the screenshot had typed there. `caret` nil hides it.
func typeIn(_ typed: String, t: Double, from: Double, cps: Double = 12, at baseline: CGPoint, size: CGFloat,
            face: Face = .system(.regular), colour: Col, caret: Col? = Col(0x0A84FF), clear: CGRect? = nil,
            clearColour: Col = Col(0xFFFFFF), seed: Int = 1) {
    guard t >= from - 0.5 else { return }
    if let clear { fill(clear, clearColour) }
    let times = typingTimes(typed, from: from, cps: cps, seed: seed)
    let n = times.filter { $0 <= t }.count
    let shown = String(typed.prefix(n))
    let w = shown.isEmpty ? 0 : text(shown, size, face, colour, baseline.x, baseline.y)
    if let caret {
        let typing = n > 0 && n < typed.count
        if typing || (t * 2).truncatingRemainder(dividingBy: 1) < 0.6 {
            fill(rr(CGRect(x: baseline.x + w + size * 0.05, y: baseline.y - size * 0.8, width: max(2, size * 0.07), height: size), size * 0.035), caret)
        }
    }
}

// MARK: - Touches and cursors

enum Pointer { case finger, arrow }

/// A finger (or a cursor) that moves through `keys` (film time, canvas point) and taps at `taps` (film times). It moves
/// smoothly between keys, presses with a small squish on each tap and leaves a ripple, appears just before its first
/// key and leaves after its last tap. `position(t)` lets a camera follow it.
struct TouchPath {
    let keys: [(t: Double, p: CGPoint)]
    var taps: [Double]
    var style: Pointer

    init(_ keys: [(Double, CGPoint)], taps: [Double] = [], style: Pointer = .finger) {
        self.keys = keys.map { (t: $0.0, p: $0.1) }.sorted { $0.t < $1.t }
        self.taps = taps; self.style = style
    }

    func position(_ t: Double) -> CGPoint {
        guard let first = keys.first else { return .zero }
        if t <= first.t || keys.count == 1 { return first.p }
        guard let last = keys.last, t < last.t else { return keys[keys.count - 1].p }
        var i = 0
        while i < keys.count - 2 && t > keys[i + 1].t { i += 1 }
        let u = CGFloat(inOut(prog(t, keys[i].t, keys[i + 1].t)))
        // Catmull–Rom through the neighbouring keys, so a path through several points curves naturally.
        let p0 = keys[max(0, i - 1)].p, p1 = keys[i].p, p2 = keys[i + 1].p, p3 = keys[min(keys.count - 1, i + 2)].p
        func cr(_ a: CGFloat, _ b: CGFloat, _ c: CGFloat, _ d: CGFloat) -> CGFloat {
            0.5 * (2 * b + (-a + c) * u + (2 * a - 5 * b + 4 * c - d) * u * u + (-a + 3 * b - 3 * c + d) * u * u * u)
        }
        return CGPoint(x: cr(p0.x, p1.x, p2.x, p3.x), y: cr(p0.y, p1.y, p2.y, p3.y))
    }

    /// Draws it at `t`. `map` turns its points into canvas points, e.g. when the keys are in a recording's pixels and
    /// a camera is moving inside it: `map: { canvasPoint($0, region: footageRegion(f, zoom.region(t), card), drawnIn: card) }`.
    func draw(_ t: Double, colour: Col = Col(0x1C1C1E), size: CGFloat = 64, map: (CGPoint) -> CGPoint = { $0 }) {
        guard let first = keys.first, let lastKey = keys.last else { return }
        let end = max(lastKey.t, taps.max() ?? lastKey.t)
        let alpha = prog(t, first.t - 0.25, first.t) * (1 - prog(t, end + 0.35, end + 0.65))
        guard alpha > 0 else { return }
        let p = map(position(t))
        let pressed = taps.map { max(0, 1 - abs(t - $0) / 0.12) }.max() ?? 0
        for tap in taps { tapRipple(at: p, at: tap, t: t, colour: colour) }
        ctx.saveGState(); ctx.setAlpha(CGFloat(alpha))
        switch style {
        case .finger:     // like the Simulator's touch indicator: a soft disc with a pale rim, pressing in on a tap
            let r = size / 2 * CGFloat(1 - 0.16 * pressed)
            fill(CGPath(ellipseIn: centred(p, r), transform: nil), colour.alpha(0.28 + 0.12 * CGFloat(pressed)))
            stroke(CGPath(ellipseIn: centred(p, r), transform: nil), Col(0xFFFFFF, 0.7), max(2, size * 0.04))
        case .arrow:
            pointer(at: p, pressed: pressed, size: size * 0.72)
        }
        ctx.restoreGState()
    }
}

// MARK: - State changes

/// How a screen moves to its next state. `push` is iOS navigation: the next screen comes in from `side` while the
/// current one slides a little the other way and dims. `reveal` grows the next state from a point (the tap).
enum StateChange {
    case cut, crossfade, push(Side), reveal(CGPoint)
}

/// A screen changing state at `at`: `before` until then, `after` from then, joined by `style` over `length` seconds,
/// inside the screen's card `rect`. Draw each state the way you'd draw that screen on its own.
func changeState(t: Double, at t0: Double, length: Double = 0.35, style: StateChange = .crossfade, in rect: CGRect,
                 radius: CGFloat = 44, before: () -> Void, after: () -> Void) {
    if case .cut = style { if t < t0 { before() } else { after() }; return }
    let p = prog(t, t0, t0 + length)
    if p <= 0 { before(); return }
    if p >= 1 { after(); return }
    let e = CGFloat(outCubic(p))
    switch style {
    case .cut: break
    case .crossfade:
        before()
        ctx.saveGState(); ctx.setAlpha(e); ctx.beginTransparencyLayer(auxiliaryInfo: nil); after(); ctx.endTransparencyLayer(); ctx.restoreGState()
    case .push(let side):
        ctx.saveGState(); ctx.addPath(rr(rect, radius)); ctx.clip()
        let (fx, fy): (CGFloat, CGFloat) = {
            switch side { case .right: return (1, 0); case .left: return (-1, 0); case .down: return (0, 1); case .up: return (0, -1) }
        }()
        ctx.saveGState(); ctx.translateBy(x: -fx * rect.width * 0.3 * e, y: -fy * rect.height * 0.3 * e)
        before(); fill(rect, Col(0x000000, 0.18 * e)); ctx.restoreGState()
        ctx.saveGState(); ctx.translateBy(x: fx * rect.width * (1 - e), y: fy * rect.height * (1 - e))
        fillShadowed(rr(rect, radius), Col(0xFFFFFF), blur: 30, alpha: 0.18, dy: 0)
        after(); ctx.restoreGState()
        ctx.restoreGState()
    case .reveal(let from):
        before()
        let far = [CGPoint(x: rect.minX, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY), CGPoint(x: rect.minX, y: rect.maxY),
                   CGPoint(x: rect.maxX, y: rect.maxY)].map { hypot($0.x - from.x, $0.y - from.y) }.max() ?? 1
        ctx.saveGState(); ctx.addPath(rr(rect, radius)); ctx.clip()
        ctx.addPath(CGPath(ellipseIn: centred(from, far * e), transform: nil)); ctx.clip()
        after()
        ctx.restoreGState()
    }
}
