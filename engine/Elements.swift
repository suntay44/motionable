// motionable engine: elements. Small, reusable pieces a direction can call for — stickers, hand-drawn marks,
// confetti, receipts, chat bubbles, notices — plus backgrounds and overlays. Each takes its own progress or time,
// so it can sit anywhere in a scene. A film that needs something else writes it in its own scenes/.
import AppKit

// MARK: - Stickers and labels

enum StickerShape { case pill, burst(points: Int), tag, circle, ribbon, speech }

/// A label that pops on (p 0…1) with an overshoot, slightly rotated like a sticker.
func sticker(_ s: String, at c: CGPoint, shape: StickerShape = .pill, fill bg: Col, ink: Col, face: Face = .system(.heavy),
             size: CGFloat = 44, degrees: CGFloat = -6, p: Double, tailRight: Bool = false) {
    guard p > 0 else { return }
    let k = CGFloat(outBack(min(1, p), 1.7))
    let tw = textWidth(s, size, face)
    ctx.saveGState()
    ctx.translateBy(x: c.x, y: c.y); ctx.rotate(by: degrees * .pi / 180); ctx.scaleBy(x: k, y: k)
    let path: CGPath
    switch shape {
    case .pill: path = rr(CGRect(x: -tw / 2 - size * 0.6, y: -size * 0.8, width: tw + size * 1.2, height: size * 1.6), size * 0.8)
    case .circle:
        let r = max(tw / 2 + size * 0.5, size * 1.4)
        path = CGPath(ellipseIn: CGRect(x: -r, y: -r, width: 2 * r, height: 2 * r), transform: nil)
    case .burst(let n):
        let r = max(tw / 2 + size * 0.7, size * 1.6)
        let star = CGMutablePath()
        for i in 0..<(n * 2) {
            let a = CGFloat(i) * .pi / CGFloat(n) - .pi / 2
            let rad = i % 2 == 0 ? r : r * 0.82
            let pt = CGPoint(x: cos(a) * rad, y: sin(a) * rad)
            if i == 0 { star.move(to: pt) } else { star.addLine(to: pt) }
        }
        star.closeSubpath()
        path = star
    case .tag:
        let w = tw + size * 1.6, h = size * 1.7
        let p = CGMutablePath()
        p.move(to: CGPoint(x: -w / 2 + h * 0.45, y: -h / 2)); p.addLine(to: CGPoint(x: w / 2, y: -h / 2))
        p.addLine(to: CGPoint(x: w / 2, y: h / 2)); p.addLine(to: CGPoint(x: -w / 2 + h * 0.45, y: h / 2))
        p.addLine(to: CGPoint(x: -w / 2, y: 0)); p.closeSubpath()
        p.addEllipse(in: CGRect(x: -w / 2 + h * 0.3, y: -size * 0.14, width: size * 0.28, height: size * 0.28))
        path = p
    case .ribbon:
        let w = tw + size * 1.4, h = size * 1.5
        let p = CGMutablePath()
        p.move(to: CGPoint(x: -w / 2 - h * 0.4, y: -h / 2)); p.addLine(to: CGPoint(x: w / 2 + h * 0.4, y: -h / 2))
        p.addLine(to: CGPoint(x: w / 2 + h * 0.1, y: 0)); p.addLine(to: CGPoint(x: w / 2 + h * 0.4, y: h / 2))
        p.addLine(to: CGPoint(x: -w / 2 - h * 0.4, y: h / 2)); p.addLine(to: CGPoint(x: -w / 2 - h * 0.1, y: 0)); p.closeSubpath()
        path = p
    case .speech:
        let w = tw + size * 1.3, h = size * 1.7
        let p = CGMutablePath(); p.addPath(rr(CGRect(x: -w / 2, y: -h / 2, width: w, height: h), h * 0.45))
        let m: CGFloat = tailRight ? -1 : 1        // the tail points down-left, or down-right
        p.move(to: CGPoint(x: -w * 0.2 * m, y: h / 2 - 2)); p.addLine(to: CGPoint(x: -w * 0.32 * m, y: h / 2 + size * 0.6))
        p.addLine(to: CGPoint(x: -w * 0.04 * m, y: h / 2 - 2)); p.closeSubpath()
        path = p
    }
    ctx.setShadow(offset: CGSize(width: 0, height: 8), blur: 18, color: Col(0x000000, 0.22).cg)
    ctx.addPath(path); ctx.setFillColor(bg.cg); ctx.fillPath(using: .evenOdd)
    ctx.setShadow(offset: .zero, blur: 0, color: nil)
    text(s, size, face, ink, 0, size * 0.36, align: 0.5)
    ctx.restoreGState()
}

/// A price tag on a string, swinging into place.
func priceTag(_ s: String, at c: CGPoint, p: Double, fill bg: Col, ink: Col, face: Face = .system(.heavy), size: CGFloat = 52) {
    guard p > 0 else { return }
    let swing = CGFloat(sin(Double(p) * 9) * exp(-Double(p) * 4)) * 0.5
    ctx.saveGState()
    ctx.translateBy(x: c.x, y: c.y - size * 1.4); ctx.rotate(by: swing - 0.12)
    line(CGPoint(x: 0, y: -size * 1.2), CGPoint(x: 0, y: size * 0.6), Col(0x6B5B4B), 3)
    ctx.translateBy(x: 0, y: size * 1.4)
    sticker(s, at: .zero, shape: .tag, fill: bg, ink: ink, face: face, size: size, degrees: 0, p: 1)
    ctx.restoreGState()
}

// MARK: - Hand-drawn marks

/// A hand-drawn loop around a rect, drawing on over p.
func scribbleCircle(around r: CGRect, p: Double, colour: Col, width: CGFloat = 8, seed: Int = 1) {
    guard p > 0 else { return }
    var g = Seeded(UInt64(seed) &+ 31)
    let c = CGPoint(x: r.midX, y: r.midY), rx = r.width / 2 + 26, ry = r.height / 2 + 22
    var pts: [CGPoint] = []
    let turns = 1.15, steps = 90
    let a0 = -2.4 + g.next() * 0.4
    for i in 0...steps {
        let u = Double(i) / Double(steps)
        let a = a0 + u * 2 * .pi * turns
        let wob = 1 + 0.05 * sin(u * 13 + g.next() * 0.2) + 0.06 * u
        pts.append(CGPoint(x: c.x + CGFloat(cos(a) * wob) * rx, y: c.y + CGFloat(sin(a) * wob) * ry))
    }
    stroke(partial(pts, outCubic(p)), colour, width)
}

/// A hand-drawn arrow that draws itself from a to b, curving by `bend`.
func handArrow(from a: CGPoint, to b: CGPoint, p: Double, colour: Col, width: CGFloat = 8, bend: CGFloat = 0.25) {
    guard p > 0 else { return }
    let mid = CGPoint(x: (a.x + b.x) / 2 - (b.y - a.y) * bend, y: (a.y + b.y) / 2 + (b.x - a.x) * bend)
    var pts: [CGPoint] = []
    for i in 0...40 {
        let u = CGFloat(i) / 40
        pts.append(CGPoint(x: (1 - u) * (1 - u) * a.x + 2 * (1 - u) * u * mid.x + u * u * b.x,
                           y: (1 - u) * (1 - u) * a.y + 2 * (1 - u) * u * mid.y + u * u * b.y))
    }
    let body = prog(p, 0, 0.75)
    stroke(partial(pts, outCubic(body)), colour, width)
    let head = prog(p, 0.7, 1)
    if head > 0 {
        let d = atan2(b.y - pts[38].y, b.x - pts[38].x), len = width * 4.5 * CGFloat(outCubic(head))
        for s in [-1.0, 1.0] as [CGFloat] {
            line(b, CGPoint(x: b.x - cos(d + s * 0.55) * len, y: b.y - sin(d + s * 0.55) * len), colour, width)
        }
    }
}

enum UnderlineStyle { case straight, wave, scribble }
/// An underline under a text rect, drawing left to right.
func underlineStroke(_ r: CGRect, p: Double, colour: Col, width: CGFloat = 8, style: UnderlineStyle = .straight) {
    guard p > 0 else { return }
    var pts: [CGPoint] = []
    let y = r.maxY + width * 1.5
    for i in 0...60 {
        let u = CGFloat(i) / 60
        let x = r.minX + r.width * u
        switch style {
        case .straight: pts.append(CGPoint(x: x, y: y + 3 * sin(u * 3)))
        case .wave: pts.append(CGPoint(x: x, y: y + width * 0.9 * sin(u * 18)))
        case .scribble: pts.append(CGPoint(x: x, y: y + (i % 2 == 0 ? -1 : 1) * width * 0.5 + width * 0.6 * sin(u * 7)))
        }
    }
    stroke(partial(pts, outCubic(p)), colour, width)
}

// MARK: - Sparkle, confetti, taps

/// A four-point twinkle; p runs 0…1 over its life.
func sparkle(at c: CGPoint, size: CGFloat, p: Double, colour: Col) {
    guard p > 0 && p < 1 else { return }
    let k = CGFloat(sin(Double.pi * p)) * size
    let path = CGMutablePath()
    for i in 0..<8 {
        let a = CGFloat(i) * .pi / 4 + CGFloat(p - 0.5) * 0.4      // points stay near upright: a twinkle, never an ×
        let r = i % 2 == 0 ? k : k * 0.22
        let pt = CGPoint(x: c.x + cos(a) * r, y: c.y + sin(a) * r)
        if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
    }
    path.closeSubpath()
    fill(path, colour)
}
/// Twinkles scattered around a rect, starting at `from`.
func sparkles(around r: CGRect, t: Double, from: Double, count: Int = 6, colour: Col, seed: Int = 1, size: CGFloat = 26) {
    var g = Seeded(UInt64(seed) &+ 101)
    for _ in 0..<count {
        let a = g.next() * 2 * .pi, d = 0.55 + g.next() * 0.25
        let c = CGPoint(x: r.midX + CGFloat(cos(a)) * r.width * CGFloat(d), y: r.midY + CGFloat(sin(a)) * r.height * CGFloat(d))
        let start = from + g.next() * 0.5
        sparkle(at: c, size: size * CGFloat(0.6 + g.next() * 0.6), p: prog(t, start, start + 0.55), colour: colour)
    }
}
/// A burst of confetti from `origin` at time t0 (physics: launch, gravity, flutter).
func confetti(from origin: CGPoint, at t0: Double, t: Double, colours: [Col], count: Int = 90, seed: Int = 1, power: CGFloat = 1) {
    let dt = t - t0
    guard dt > 0 && dt < 3.5, !colours.isEmpty else { return }
    var g = Seeded(UInt64(seed) &+ 7)
    for i in 0..<count {
        let ang = -Double.pi / 2 + (g.next() - 0.5) * 2.2
        let speed = (900 + g.next() * 1300) * Double(power)
        let vx = cos(ang) * speed, vy = sin(ang) * speed
        let drag = 1.6
        let fx = vx / drag * (1 - exp(-drag * dt)), fy = vy / drag * (1 - exp(-drag * dt)) + 0.5 * 1500 * dt * dt * 0.6
        let x = origin.x + CGFloat(fx) + CGFloat(sin(dt * 7 + Double(i))) * 14
        let y = origin.y + CGFloat(fy)
        let w = CGFloat(10 + g.next() * 12), h = CGFloat(6 + g.next() * 8)
        let spin = CGFloat(dt * (4 + g.next() * 8))
        let fade = CGFloat(1 - prog(dt, 2.6, 3.5))
        ctx.saveGState()
        ctx.translateBy(x: x, y: y); ctx.rotate(by: spin)
        ctx.scaleBy(x: 1, y: CGFloat(abs(cos(dt * 9 + Double(i)))) + 0.15)
        let c = colours[i % colours.count].alpha(fade)
        if i % 5 == 0 { fill(CGPath(ellipseIn: CGRect(x: -w / 3, y: -w / 3, width: w / 1.5, height: w / 1.5), transform: nil), c) }
        else { fill(CGRect(x: -w / 2, y: -h / 2, width: w, height: h), c) }
        ctx.restoreGState()
    }
}
/// A finger tap: a soft dot presses in, then a ripple spreads.
func tapRipple(at c: CGPoint, at t0: Double, t: Double, colour: Col = Col(0x000000)) {
    let pre = prog(t, t0 - 0.18, t0)
    if pre > 0 && t < t0 { fill(CGPath(ellipseIn: centred(c, 36 * CGFloat(pre)), transform: nil), colour.alpha(0.16)) }
    let q = prog(t, t0, t0 + 0.45)
    if q > 0 && q < 1 { fill(CGPath(ellipseIn: centred(c, 28 + 60 * CGFloat(outCubic(q))), transform: nil), colour.alpha(CGFloat(0.18 * (1 - q)))) }
}
/// A generic pointer arrow (for desktop/web products), pressing when `pressed` > 0.
func pointer(at c: CGPoint, pressed: Double = 0, fill bg: Col = Col(0x111111), edge: Col = Col(0xFFFFFF), size: CGFloat = 46) {
    let k = size / 46 * CGFloat(1 - 0.12 * sin(Double.pi * min(1, pressed)))
    let p = CGMutablePath()
    let pts = [(0, 0), (0, 40), (10, 31), (17, 46), (24, 43), (17, 28), (30, 28)].map { CGPoint(x: c.x + CGFloat($0.0) * k, y: c.y + CGFloat($0.1) * k) }
    p.move(to: pts[0]); for q in pts.dropFirst() { p.addLine(to: q) }; p.closeSubpath()
    ctx.saveGState(); ctx.setShadow(offset: CGSize(width: 0, height: 4), blur: 10, color: Col(0x000000, 0.3).cg)
    fill(p, bg); ctx.restoreGState()
    stroke(p, edge, 3 * k)
}

// MARK: - Meters

func progressRing(centre c: CGPoint, radius r: CGFloat, width: CGFloat, progress: Double, track: Col, fill fg: Col) {
    stroke(CGPath(ellipseIn: centred(c, r), transform: nil), track, width)
    guard progress > 0 else { return }
    let p = CGMutablePath()
    p.addArc(center: c, radius: r, startAngle: -.pi / 2, endAngle: -.pi / 2 + 2 * .pi * CGFloat(min(1, progress)), clockwise: false)
    stroke(p, fg, width)
}
func progressBar(_ r: CGRect, progress: Double, track: Col, fill fg: Col) {
    fill(rr(r, r.height / 2), track)
    let w = r.width * CGFloat(max(0, min(1, progress)))
    if w > 0 { fill(rr(CGRect(x: r.minX, y: r.minY, width: max(w, r.height), height: r.height), r.height / 2), fg) }
}

// MARK: - Paper and chat

/// A receipt printing out (p 0…1): rows appear top to bottom, the paper grows, the total lands last.
func receipt(_ rows: [(String, String)], total: (String, String)?, in r: CGRect, p: Double,
             face: Face = .named("Menlo-Regular"), bold: Face = .named("Menlo-Bold"),
             ink: Col = Col(0x222222), paperCol: Col = Col(0xFFFDF8), size: CGFloat = 34, title: String? = nil) {
    guard p > 0 else { return }
    let lh = size * 1.55
    let n = rows.count + (total == nil ? 0 : 2) + (title == nil ? 0 : 2)
    let fullH = CGFloat(n) * lh + size * 2.2
    let h = min(r.height, fullH * CGFloat(outCubic(p)))
    let paperRect = CGRect(x: r.minX, y: r.minY, width: r.width, height: h)
    let edge = CGMutablePath()
    edge.move(to: CGPoint(x: paperRect.minX, y: paperRect.minY)); edge.addLine(to: CGPoint(x: paperRect.maxX, y: paperRect.minY))
    edge.addLine(to: CGPoint(x: paperRect.maxX, y: paperRect.maxY))
    let teeth = 18, tw = paperRect.width / CGFloat(teeth)
    for i in 0..<teeth {
        edge.addLine(to: CGPoint(x: paperRect.maxX - tw * (CGFloat(i) + 0.5), y: paperRect.maxY + 12))
        edge.addLine(to: CGPoint(x: paperRect.maxX - tw * CGFloat(i + 1), y: paperRect.maxY))
    }
    edge.closeSubpath()
    fillShadowed(edge, paperCol, blur: 30, alpha: 0.2, dy: 10)
    ctx.saveGState(); ctx.addPath(edge); ctx.clip()
    var y = r.minY + size * 1.6
    if let title { text(title, size * 1.1, bold, ink, r.midX, y, align: 0.5); y += lh * 1.3
        line(CGPoint(x: r.minX + 30, y: y - lh * 0.55), CGPoint(x: r.maxX - 30, y: y - lh * 0.55), ink.alpha(0.5), 2) }
    for row in rows {
        text(row.0, size, face, ink, r.minX + 36, y); text(row.1, size, face, ink, r.maxX - 36, y, align: 1)
        y += lh
    }
    if let total {
        line(CGPoint(x: r.minX + 30, y: y - lh * 0.45), CGPoint(x: r.maxX - 30, y: y - lh * 0.45), ink, 2)
        y += lh * 0.4
        text(total.0, size * 1.15, bold, ink, r.minX + 36, y); text(total.1, size * 1.15, bold, ink, r.maxX - 36, y, align: 1)
    }
    ctx.restoreGState()
}
/// A chat bubble that pops in (p 0…1). `mine` puts the tail on the right.
func chatBubble(_ s: String, at c: CGPoint, mine: Bool, p: Double, fill bg: Col, ink: Col, face: Face = .system(.medium), size: CGFloat = 40) {
    guard p > 0 else { return }
    let k = CGFloat(outBack(min(1, p), 1.5))
    let tw = textWidth(s, size, face)
    let w = tw + size * 1.2, h = size * 1.9
    ctx.saveGState()
    ctx.translateBy(x: c.x, y: c.y); ctx.scaleBy(x: k, y: k)
    let body = CGMutablePath(); body.addPath(rr(CGRect(x: -w / 2, y: -h / 2, width: w, height: h), h * 0.45))
    let tx: CGFloat = mine ? w / 2 - 18 : -w / 2 + 18
    body.move(to: CGPoint(x: tx - 14, y: h / 2 - 12)); body.addLine(to: CGPoint(x: tx + (mine ? 22 : -22), y: h / 2 + 10))
    body.addLine(to: CGPoint(x: tx + 14, y: h / 2 - 12)); body.closeSubpath()
    fill(body, bg)
    text(s, size, face, ink, 0, size * 0.36, align: 0.5)
    ctx.restoreGState()
}
/// A generic notification card sliding down from the top (in over 0.3 s from `from`, out over 0.25 s before `to`).
func notice(title: String, message: String, icon: CGImage?, t: Double, from: Double, to: Double,
            top: CGFloat = 50, fill bg: Col = Col(0xFFFFFF, 0.96), ink: Col = Col(0x111111), sub: Col = Col(0x8E8E93),
            face: Face = .system(.semibold), detail: String = "now") {
    guard t >= from && t < to else { return }
    let y = lerp(-220, top, outCubic(prog(t, from, from + 0.36))) - lerp(0, 270, inCubic(prog(t, to - 0.25, to)))
    let r = CGRect(x: 40, y: y, width: W - 80, height: 162)
    fillShadowed(rr(r, 44), bg, blur: 40, alpha: 0.3)
    if let icon {
        ctx.saveGState(); ctx.addPath(rr(CGRect(x: 72, y: y + 36, width: 90, height: 90), 22)); ctx.clip()
        drawImage(icon, in: CGRect(x: 72, y: y + 36, width: 90, height: 90)); ctx.restoreGState()
    }
    let tx: CGFloat = icon == nil ? 72 : 190
    text(title.uppercased(), 28, face, sub, tx, y + 66, kern: 1)
    text(detail, 28, .system(.regular), sub, r.maxX - 40, y + 66, align: 1)
    text(message, 38, face, ink, tx, y + 118)
}

// MARK: - Backgrounds

func gradientFill(_ colours: [Col], degrees: CGFloat = 90, in r: CGRect? = nil) {
    let rect = r ?? fullCanvas()
    guard colours.count > 1 else { fill(rect, colours.first ?? Col(0x000000)); return }
    let locs = (0..<colours.count).map { CGFloat($0) / CGFloat(colours.count - 1) }
    let g = CGGradient(colorsSpace: srgb, colors: colours.map(\.cg) as CFArray, locations: locs)!
    let a = degrees * .pi / 180
    let c = CGPoint(x: rect.midX, y: rect.midY), half = hypot(rect.width, rect.height) / 2
    ctx.saveGState(); ctx.clip(to: rect)
    ctx.drawLinearGradient(g, start: CGPoint(x: c.x - cos(a) * half, y: c.y - sin(a) * half),
                           end: CGPoint(x: c.x + cos(a) * half, y: c.y + sin(a) * half), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    ctx.restoreGState()
}
func radialGlow(at c: CGPoint, radius: CGFloat, colour: Col) {
    let g = CGGradient(colorsSpace: srgb, colors: [colour.cg, colour.alpha(0).cg] as CFArray, locations: [0, 1])!
    ctx.drawRadialGradient(g, startCenter: c, startRadius: 0, endCenter: c, endRadius: radius, options: [])
}
func dotGrid(spacing: CGFloat = 48, radius: CGFloat = 3, colour: Col, t: Double = 0, drift: CGFloat = 0) {
    let off = CGFloat(fmod(Double(drift) * t, Double(spacing)))
    var y = -spacing + off
    while y < H + spacing {
        var x = -spacing + off
        while x < W + spacing { fill(CGPath(ellipseIn: centred(CGPoint(x: x, y: y), radius), transform: nil), colour); x += spacing }
        y += spacing
    }
}
func stripes(width: CGFloat = 60, a: Col, b: Col, degrees: CGFloat = -30, t: Double = 0, speed: CGFloat = 40) {
    fill(fullCanvas(), a)
    ctx.saveGState()
    ctx.translateBy(x: W / 2, y: H / 2); ctx.rotate(by: degrees * .pi / 180)
    let span = hypot(W, H)
    var x = -span + CGFloat(fmod(Double(speed) * t, Double(width * 2)))
    while x < span { fill(CGRect(x: x, y: -span, width: width, height: span * 2), b); x += width * 2 }
    ctx.restoreGState()
}
/// Soft organic shapes drifting slowly (seeded).
func blobs(count: Int = 4, colours: [Col], t: Double, seed: Int = 1, alpha: CGFloat = 0.5, scale: CGFloat = 1) {
    var g = Seeded(UInt64(seed) &+ 999)
    for i in 0..<count {
        let c = CGPoint(x: W * CGFloat(g.next()), y: H * CGFloat(g.next()))
        let r = (180 + 260 * CGFloat(g.next())) * scale
        let drift = CGPoint(x: CGFloat(sin(t * 0.4 + Double(i))) * 40, y: CGFloat(cos(t * 0.3 + Double(i) * 2)) * 50)
        fill(blobPath(centre: CGPoint(x: c.x + drift.x, y: c.y + drift.y), radius: r, seed: seed * 10 + i, wobble: 0.2, phase: t * 0.5),
             colours[i % max(1, colours.count)].alpha(alpha))
    }
}
func gridLines(spacing: CGFloat = 90, colour: Col, width: CGFloat = 1.5) {
    var x: CGFloat = 0
    while x <= W { fill(CGRect(x: x, y: 0, width: width, height: H), colour); x += spacing }
    var y: CGFloat = 0
    while y <= H { fill(CGRect(x: 0, y: y, width: W, height: width), colour); y += spacing }
}

// MARK: - Overlays

func vignette(_ amount: CGFloat = 0.45) {
    let c = CGPoint(x: W / 2, y: H / 2)
    let g = CGGradient(colorsSpace: srgb, colors: [Col(0x000000, 0).cg, Col(0x000000, amount).cg] as CFArray, locations: [0.55, 1])!
    ctx.drawRadialGradient(g, startCenter: c, startRadius: 0, endCenter: c, endRadius: hypot(W, H) / 2, options: [.drawsAfterEndLocation])
}
func scanlines(alpha: CGFloat = 0.12, spacing: CGFloat = 6) {
    var y: CGFloat = 0
    while y < H { fill(CGRect(x: 0, y: y, width: W, height: spacing / 2), Col(0x000000, alpha)); y += spacing }
}
/// Warm drifting light leaks (screen-blended).
func lightLeak(t: Double, colour: Col = Col(0xFF8A3D), strength: CGFloat = 0.5, seed: Int = 1) {
    var g = Seeded(UInt64(seed) &+ 55)
    ctx.saveGState(); ctx.setBlendMode(.screen)
    for i in 0..<3 {
        let c = CGPoint(x: W * CGFloat(g.next()) + CGFloat(sin(t * 0.5 + Double(i))) * 160,
                        y: H * CGFloat(g.next()) + CGFloat(cos(t * 0.4 + Double(i))) * 220)
        radialGlow(at: c, radius: 520 + 200 * CGFloat(g.next()), colour: colour.alpha(strength * CGFloat(0.5 + 0.5 * sin(t * 0.9 + Double(i) * 2))))
    }
    ctx.restoreGState()
}
/// Cinema bars closing in (amount 0…1 of a 2.39:1 frame).
func letterbox(_ amount: CGFloat, colour: Col = Col(0x000000)) {
    let target = (H - W / 2.39) / 2 * amount
    guard target > 0 else { return }
    fill(CGRect(x: 0, y: 0, width: W, height: target), colour)
    fill(CGRect(x: 0, y: H - target, width: W, height: target), colour)
}
