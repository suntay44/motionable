// motionable engine: a Reel is a run of clips joined by transitions. Outside a join, the current clip draws
// straight to the canvas; inside one, both clips render to layers and the join composites them.
import AppKit

enum Side { case left, right, up, down }

/// How one clip hands over to the next.
enum Join {
    case cut                                   // instant, on the boundary
    case dissolve                              // cross-fade
    case dip(Col)                              // fade through a colour
    case push(Side)                            // both move; the new clip pushes the old one out toward `side`
    case cover(Side)                           // the new clip slides in over the old one, travelling toward `side`
    case uncover(Side)                         // the old clip slides away toward `side`, revealing the new one
    case whip(Side)                            // a fast push with motion blur
    case zoomThrough(CGPoint)                  // fly into a point of the old clip and out of the new one
    case iris(CGPoint)                         // circle reveal from a point
    case shape(JoinShape, CGPoint)             // any shape reveal from a point
    case blinds(Int, vertical: Bool)           // strips open in sequence
    case slice(degrees: CGFloat)               // a knife cut: the old clip splits along a line and the halves slide apart
    case glitch                                // RGB split and torn bands across the change
    case flash(Col)                            // a burst of colour at the change
    case spin(clockwise: Bool)                 // the old clip spins away, the new one spins in
    case pixelate                              // big pixels in, big pixels out
    case burn(Col)                             // a film-burn overexposure that hides the change
    case columns(Int)                          // the new clip drops in as staggered columns
}
extension Join {
    /// True when both scenes are visible in the same place during the join (a dissolve, a mask, a zoom through), so
    /// their text can collide; false when one scene slides over, past or away from the other.
    var seeThrough: Bool {
        switch self {
        case .dissolve, .zoomThrough, .iris, .shape, .blinds, .glitch, .pixelate, .burn, .columns: return true
        case .cut, .dip, .flash, .push, .cover, .uncover, .whip, .slice, .spin: return false
        }
    }
}

enum JoinShape { case star(points: Int), roundedSquare, diamond, heart, blob(seed: Int) }

struct Clip {
    let from: Double
    let to: Double
    let draw: (Double) -> Void        // draws the clip at absolute time t (it may be asked slightly outside [from, to) during joins)
}

/// Where the film's joins are (time, length, and whether both scenes show through each other in it), for `sheet`,
/// `storyboard` and the layout audit.
var reelJoins: [(at: Double, duration: Double, seeThrough: Bool)] = []

struct Reel {
    let clips: [Clip]
    /// joins[i] connects clips[i] → clips[i + 1], centred on clips[i].to.
    let joins: [(Join, Double)]

    init(_ clips: [Clip], joins: [(Join, Double)]) {
        precondition(joins.count == max(0, clips.count - 1), "a Reel needs one join between each pair of clips")
        self.clips = clips; self.joins = joins
        reelJoins = zip(clips, joins).map { (at: $0.0.to, duration: $0.1.1, seeThrough: $0.1.0.seeThrough) }
    }

    func draw(_ t: Double) {
        guard !clips.isEmpty else { return }
        for i in 0..<joins.count {
            let (style, dur) = joins[i]
            let b = clips[i].to
            let a0 = b - dur / 2, a1 = b + dur / 2
            if t >= a0 && t < a1 && dur > 0 {
                composite(style, p: (t - a0) / dur, a: { clips[i].draw(t) }, b: { clips[i + 1].draw(t) }, t: t)
                return
            }
        }
        let i = clips.lastIndex { t >= $0.from } ?? 0
        clips[i].draw(t)
    }
}

/// Composites two scenes for a transition at progress p (0…1). Usable on its own, outside a Reel.
func composite(_ style: Join, p: Double, a drawA: () -> Void, b drawB: () -> Void, t: Double = 0) {
    let e = inOut(p)
    func offset(_ side: Side, _ k: CGFloat) -> (CGFloat, CGFloat) {
        switch side { case .left: return (-W * k, 0); case .right: return (W * k, 0); case .up: return (0, -H * k); case .down: return (0, H * k) }
    }
    /// Where the incoming clip sits relative to the outgoing one, overlapping it by 2 px so no seam shows.
    func follow(_ side: Side, _ ax: CGFloat, _ ay: CGFloat) -> (CGFloat, CGFloat) {
        switch side {
        case .left: return (ax + W - 2, ay)
        case .right: return (ax - W + 2, ay)
        case .up: return (ax, ay + H - 2)
        case .down: return (ax, ay - H + 2)
        }
    }
    switch style {
    case .cut:
        if p < 0.5 { drawA() } else { drawB() }
    case .dissolve:
        drawA()
        let b = layer(drawB); drawLayer(b, alpha: CGFloat(e))
    case .dip(let c):
        if p < 0.5 { drawA(); fill(fullCanvas(), c.alpha(CGFloat(inOut(p * 2)))) }
        else { drawB(); fill(fullCanvas(), c.alpha(CGFloat(1 - inOut((p - 0.5) * 2)))) }
    case .push(let side):
        let a = layer(drawA), b = layer(drawB)
        let (ax, ay) = offset(side, CGFloat(e))
        let (bx, by) = follow(side, ax, ay)
        drawLayer(a, dx: ax, dy: ay)
        drawLayer(b, dx: bx, dy: by)
    case .cover(let side):
        drawA()
        fill(fullCanvas(), Col(0x000000, CGFloat(0.25 * e)))
        let b = layer(drawB)
        let (ox, oy) = offset(side, CGFloat(1 - e))
        ctx.saveGState(); ctx.setShadow(offset: .zero, blur: 40, color: Col(0x000000, 0.35).cg)
        drawLayer(b, dx: -ox, dy: -oy)
        ctx.restoreGState()
    case .uncover(let side):
        drawB()
        let a = layer(drawA)
        let (ox, oy) = offset(side, CGFloat(e))
        ctx.saveGState(); ctx.setShadow(offset: .zero, blur: 40, color: Col(0x000000, 0.35).cg)
        drawLayer(a, dx: ox, dy: oy)
        ctx.restoreGState()
    case .whip(let side):
        let speed = sin(Double.pi * p)                                    // fastest mid-move
        let deg: Double = (side == .left || side == .right) ? 0 : 90
        let blur = 90 * speed
        let k = CGFloat(inOut(p))
        let (ax, ay) = offset(side, k)
        // Both clips stay on screen (the new one follows the old one in), each smeared by the speed.
        let (bx, by) = follow(side, ax, ay)
        drawLayer(motionBlurred(layer(drawA), radius: blur, degrees: deg), dx: ax, dy: ay)
        drawLayer(motionBlurred(layer(drawB), radius: blur, degrees: deg), dx: bx, dy: by)
    case .zoomThrough(let pt):
        // Fly into the point of the old clip while the new one, already close, settles back to size:
        // the frame stays full the whole way (no empty borders).
        let b = layer(drawB)
        if p < 0.5 {
            let q = inCubic(p * 2)
            drawLayer(zoomBlurred(b, centre: CGPoint(x: W / 2, y: H / 2), amount: 28), scale: 1.6)
            let a = zoomBlurred(layer(drawA), centre: pt, amount: 40 * q)
            drawLayer(a, alpha: CGFloat(1 - q), scale: CGFloat(1 + 2.2 * q), anchor: pt)
        } else {
            let q = outCubic((p - 0.5) * 2)
            drawLayer(zoomBlurred(b, centre: CGPoint(x: W / 2, y: H / 2), amount: 28 * (1 - q)), scale: CGFloat(1.6 - 0.6 * q))
        }
    case .iris(let pt):
        drawA()
        ctx.saveGState()
        ctx.addPath(CGPath(ellipseIn: centred(pt, hypot(W, H) * 1.05 * CGFloat(outCubic(p))), transform: nil)); ctx.clip()
        drawB()
        ctx.restoreGState()
    case .shape(let s, let pt):
        drawA()
        ctx.saveGState()
        ctx.addPath(joinShapePath(s, centre: pt, size: hypot(W, H) * 1.6 * CGFloat(inCubic(p) * 0.5 + outCubic(p) * 0.5), spin: CGFloat(p) * 0.6))
        ctx.clip()
        drawB()
        ctx.restoreGState()
    case .blinds(let n, let vertical):
        drawA()
        let path = CGMutablePath()
        for i in 0..<n {
            let local = prog(p, Double(i) / Double(n) * 0.5, Double(i) / Double(n) * 0.5 + 0.5)
            let k = CGFloat(outCubic(local))
            if vertical { let w = W / CGFloat(n); path.addRect(CGRect(x: CGFloat(i) * w, y: 0, width: w * k, height: H)) }
            else { let h = H / CGFloat(n); path.addRect(CGRect(x: 0, y: CGFloat(i) * h, width: W, height: h * k)) }
        }
        ctx.saveGState(); ctx.addPath(path); ctx.clip(); drawB(); ctx.restoreGState()
    case .slice(let degrees):
        drawB()
        let a = layer(drawA)
        let ang = degrees * .pi / 180
        let nx = -sin(ang), ny = cos(ang)                                // normal to the cut line
        let sep = CGFloat(inOut(prog(p, 0.08, 1))) * hypot(W, H) * 1.05   // past the diagonal: gone by the end, no pop
        let big = max(W, H) * 3
        let c = CGPoint(x: W / 2, y: H / 2)
        for side in [-1.0, 1.0] as [CGFloat] {
            let half = CGMutablePath()
            let dx = cos(ang) * big, dy = sin(ang) * big
            half.move(to: CGPoint(x: c.x - dx, y: c.y - dy)); half.addLine(to: CGPoint(x: c.x + dx, y: c.y + dy))
            half.addLine(to: CGPoint(x: c.x + dx + nx * big * side, y: c.y + dy + ny * big * side))
            half.addLine(to: CGPoint(x: c.x - dx + nx * big * side, y: c.y - dy + ny * big * side)); half.closeSubpath()
            ctx.saveGState(); ctx.addPath(half); ctx.clip()
            ctx.setShadow(offset: .zero, blur: 30, color: Col(0x000000, 0.4).cg)
            drawLayer(a, dx: nx * sep * side, dy: ny * sep * side)
            ctx.restoreGState()
        }
        let flashA = 1 - prog(p, 0, 0.25)
        if flashA > 0 {                                                   // the blade's glint along the cut
            let dx = cos(ang) * big, dy = sin(ang) * big
            line(CGPoint(x: c.x - dx, y: c.y - dy), CGPoint(x: c.x + dx, y: c.y + dy), Col(0xFFFFFF, CGFloat(flashA)), 10)
        }
    case .glitch:
        let src = p < 0.5 ? layer(drawA) : layer(drawB)
        let amount = sin(Double.pi * p)
        var g = Seeded(UInt64(t * 1000) &+ 7)
        let split = channelSplit(src, dx: CGFloat(28 * amount), dy: CGFloat(6 * amount))
        drawImage(split, in: fullCanvas())
        let bands = Int(4 + 10 * amount)
        for _ in 0..<bands {
            let y = CGFloat(g.next()) * H, h = CGFloat(8 + 60 * g.next())
            let dx = CGFloat((g.next() - 0.5) * 160 * amount)
            ctx.saveGState(); ctx.clip(to: CGRect(x: 0, y: y, width: W, height: h))
            drawImage(split, in: fullCanvas().offsetBy(dx: dx, dy: 0))
            ctx.restoreGState()
        }
    case .flash(let c):
        if p < 0.5 { drawA(); fill(fullCanvas(), c.alpha(CGFloat(inCubic(p * 2)))) }
        else { drawB(); fill(fullCanvas(), c.alpha(CGFloat(1 - outCubic((p - 0.5) * 2)))) }
    case .spin(let cw):
        // The old clip spins away over the new one, which settles in beneath it (never an empty frame).
        let dir: CGFloat = cw ? 1 : -1
        drawLayer(layer(drawB), scale: CGFloat(1.15 - 0.15 * e))
        drawLayer(layer(drawA), alpha: CGFloat(1 - prog(e, 0.55, 1)), scale: CGFloat(1 - 0.85 * e), rotate: dir * CGFloat(e) * .pi * 0.9)
    case .pixelate:
        let amount = 70 * sin(Double.pi * p)
        drawImage(pixellated(p < 0.5 ? layer(drawA) : layer(drawB), scale: amount), in: fullCanvas())
    case .burn(let c):
        let heat = sin(Double.pi * p)
        if p < 0.5 { drawA() } else { drawB() }
        ctx.saveGState()
        ctx.setBlendMode(.screen)
        let centre = CGPoint(x: W * CGFloat(0.2 + 0.6 * p), y: H * 0.35)
        let g = CGGradient(colorsSpace: srgb, colors: [c.alpha(CGFloat(heat)).cg, c.alpha(CGFloat(heat * 0.6)).cg, c.alpha(0).cg] as CFArray, locations: [0, 0.45, 1])!
        ctx.drawRadialGradient(g, startCenter: centre, startRadius: 0, endCenter: centre, endRadius: H * CGFloat(0.4 + 0.9 * heat), options: [])
        fill(fullCanvas(), Col(0xFFFFFF, CGFloat(0.55 * pow(heat, 3))))
        ctx.restoreGState()
    case .columns(let n):
        drawA()
        let b = layer(drawB)
        let w = W / CGFloat(n)
        for i in 0..<n {
            let local = outCubic(prog(p, Double(i) * 0.4 / Double(n), Double(i) * 0.4 / Double(n) + 0.6))
            let fromTop: CGFloat = i % 2 == 0 ? -1 : 1
            ctx.saveGState()
            ctx.clip(to: CGRect(x: CGFloat(i) * w, y: 0, width: w + 1, height: H))
            drawLayer(b, dy: fromTop * H * CGFloat(1 - local))
            ctx.restoreGState()
        }
    }
}

func joinShapePath(_ s: JoinShape, centre c: CGPoint, size: CGFloat, spin: CGFloat = 0) -> CGPath {
    let p = CGMutablePath()
    let r = size / 2
    switch s {
    case .star(let n):
        for i in 0..<(n * 2) {
            let a = spin + CGFloat(i) * .pi / CGFloat(n) - .pi / 2
            let rad = i % 2 == 0 ? r : r * 0.45
            let pt = CGPoint(x: c.x + cos(a) * rad, y: c.y + sin(a) * rad)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
    case .roundedSquare:
        p.addPath(rr(CGRect(x: c.x - r * 0.75, y: c.y - r * 0.75, width: r * 1.5, height: r * 1.5), r * 0.3),
                  transform: CGAffineTransform(translationX: c.x, y: c.y).rotated(by: spin).translatedBy(x: -c.x, y: -c.y))
    case .diamond:
        p.move(to: CGPoint(x: c.x, y: c.y - r)); p.addLine(to: CGPoint(x: c.x + r, y: c.y))
        p.addLine(to: CGPoint(x: c.x, y: c.y + r)); p.addLine(to: CGPoint(x: c.x - r, y: c.y)); p.closeSubpath()
    case .heart:
        let k = r / 16
        for i in 0...64 {
            let a = Double(i) / 64 * 2 * .pi
            let x = 16 * pow(sin(a), 3)
            let y = -(13 * cos(a) - 5 * cos(2 * a) - 2 * cos(3 * a) - cos(4 * a))
            let pt = CGPoint(x: c.x + CGFloat(x) * k, y: c.y + CGFloat(y) * k)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
    case .blob(let seed):
        p.addPath(blobPath(centre: c, radius: r * 0.8, seed: seed, wobble: 0.22, phase: Double(spin)))
    }
    return p
}

/// A soft organic closed shape (seeded), for reveals and backgrounds.
func blobPath(centre c: CGPoint, radius r: CGFloat, seed: Int, wobble: Double = 0.18, phase: Double = 0) -> CGPath {
    var g = Seeded(UInt64(seed) &* 2654435761 &+ 1)
    let k = 3 + Int(g.next() * 3)
    let amps = (0..<k).map { _ in g.next() * wobble }, phases = (0..<k).map { _ in g.next() * 2 * .pi }
    let p = CGMutablePath()
    let steps = 72
    for i in 0...steps {
        let a = Double(i) / Double(steps) * 2 * .pi
        var rr = 1.0
        for j in 0..<k { rr += amps[j] * sin(Double(j + 2) * a + phases[j] + phase * Double(j + 1)) }
        let pt = CGPoint(x: c.x + CGFloat(cos(a) * rr) * r, y: c.y + CGFloat(sin(a) * rr) * r)
        if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
    }
    p.closeSubpath()
    return p
}

/// A small deterministic random generator (SplitMix64), so every film is repeatable from its seed.
struct Seeded {
    var state: UInt64
    init(_ seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }
    mutating func nextUInt() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
    /// 0 ..< 1
    mutating func next() -> Double { Double(nextUInt() >> 11) / Double(1 << 53) }
    mutating func int(_ n: Int) -> Int { Int(next() * Double(n)) % max(1, n) }
    mutating func pick<T>(_ a: [T]) -> T { a[int(a.count)] }
}
