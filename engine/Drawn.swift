// motionable engine: illustrations drawn for the film. Claude writes simple SVG files (paths, circles, rects,
// lines, polylines, polygons, ellipses — no transforms or gradients) into the film's assets/drawn/; this reads
// them as vector shapes, so they can pop, slide and — stroke by stroke — draw themselves on.
import AppKit

/// One shape of an illustration: its outline in the SVG's own units, plus fill and stroke.
struct DrawnShape {
    let path: CGPath
    let fill: Col?
    let stroke: Col?
    let width: CGFloat
}
struct Drawing {
    let shapes: [DrawnShape]
    let viewBox: CGRect
}

/// Reads an SVG written for the film (relative to the film folder).
func loadDrawing(_ file: String) -> Drawing {
    let url = file.hasPrefix("/") ? URL(fileURLWithPath: file) : projectDir.appendingPathComponent(file)
    guard let svg = try? String(contentsOf: url, encoding: .utf8) else { fatalError("can't read \(url.path)") }
    return parseDrawing(svg)
}

func parseDrawing(_ svg: String) -> Drawing {
    func attrs(_ tag: String) -> [String: String] {
        var out: [String: String] = [:]
        let re = try! NSRegularExpression(pattern: #"([a-zA-Z\-:]+)\s*=\s*"([^"]*)""#)
        for m in re.matches(in: tag, range: NSRange(tag.startIndex..., in: tag)) {
            out[String(tag[Range(m.range(at: 1), in: tag)!])] = String(tag[Range(m.range(at: 2), in: tag)!])
        }
        // style="fill:#fff;stroke:#000"
        if let style = out["style"] {
            for part in style.split(separator: ";") {
                let kv = part.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
                if kv.count == 2 { out[kv[0]] = kv[1] }
            }
        }
        return out
    }
    func num(_ s: String?) -> CGFloat { CGFloat(Double((s ?? "0").replacingOccurrences(of: "px", with: "")) ?? 0) }
    var viewBox = CGRect(x: 0, y: 0, width: 100, height: 100)
    if let open = svg.range(of: #"<svg[^>]*>"#, options: .regularExpression) {
        let a = attrs(String(svg[open]))
        if let vb = a["viewBox"] {
            let v = vb.split(whereSeparator: { $0 == " " || $0 == "," }).compactMap { Double($0) }
            if v.count == 4 { viewBox = CGRect(x: v[0], y: v[1], width: v[2], height: v[3]) }
        } else if a["width"] != nil { viewBox = CGRect(x: 0, y: 0, width: num(a["width"]), height: num(a["height"])) }
    }
    var shapes: [DrawnShape] = []
    let tagRe = try! NSRegularExpression(pattern: #"<(path|circle|ellipse|rect|line|polyline|polygon)\b[^>]*>"#)
    for m in tagRe.matches(in: svg, range: NSRange(svg.startIndex..., in: svg)) {
        let tag = String(svg[Range(m.range, in: svg)!])
        let kind = String(svg[Range(m.range(at: 1), in: svg)!])
        let a = attrs(tag)
        let p = CGMutablePath()
        switch kind {
        case "path": p.addPath(svgPath(a["d"] ?? ""))
        case "circle":
            let r = num(a["r"]); p.addEllipse(in: CGRect(x: num(a["cx"]) - r, y: num(a["cy"]) - r, width: 2 * r, height: 2 * r))
        case "ellipse":
            let rx = num(a["rx"]), ry = num(a["ry"]); p.addEllipse(in: CGRect(x: num(a["cx"]) - rx, y: num(a["cy"]) - ry, width: 2 * rx, height: 2 * ry))
        case "rect":
            let r = CGRect(x: num(a["x"]), y: num(a["y"]), width: num(a["width"]), height: num(a["height"]))
            let rx = min(num(a["rx"] ?? a["ry"]), r.width / 2, r.height / 2)
            p.addPath(rx > 0 ? CGPath(roundedRect: r, cornerWidth: rx, cornerHeight: rx, transform: nil) : CGPath(rect: r, transform: nil))
        case "line":
            p.move(to: CGPoint(x: num(a["x1"]), y: num(a["y1"]))); p.addLine(to: CGPoint(x: num(a["x2"]), y: num(a["y2"])))
        default:
            let v = (a["points"] ?? "").split(whereSeparator: { $0 == " " || $0 == "," || $0 == "\n" }).compactMap { Double($0) }
            for i in stride(from: 0, to: v.count - 1, by: 2) {
                let pt = CGPoint(x: v[i], y: v[i + 1]); if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
            if kind == "polygon" { p.closeSubpath() }
        }
        let fillAttr = a["fill"], strokeAttr = a["stroke"]
        let fill: Col? = fillAttr == "none" ? nil : (fillAttr.flatMap(svgColour) ?? (kind == "line" || kind == "polyline" ? nil : Col(0x000000)))
        let stroke: Col? = strokeAttr == nil || strokeAttr == "none" ? nil : svgColour(strokeAttr!)
        var f = fill, s = stroke
        if let o = a["opacity"].flatMap(Double.init) { f = f?.alpha(CGFloat(o)); s = s?.alpha(CGFloat(o)) }
        if let o = a["fill-opacity"].flatMap(Double.init) { f = f?.alpha(CGFloat(o)) }
        if let o = a["stroke-opacity"].flatMap(Double.init) { s = s?.alpha(CGFloat(o)) }
        shapes.append(DrawnShape(path: p, fill: f, stroke: s, width: a["stroke-width"].map { num($0) } ?? 1))
    }
    return Drawing(shapes: shapes, viewBox: viewBox)
}

func svgColour(_ s: String) -> Col? {
    let v = s.trimmingCharacters(in: .whitespaces).lowercased()
    let named: [String: UInt32] = ["black": 0x000000, "white": 0xFFFFFF, "red": 0xFF0000, "green": 0x008000, "blue": 0x0000FF,
                                   "yellow": 0xFFFF00, "orange": 0xFFA500, "gray": 0x808080, "grey": 0x808080, "pink": 0xFFC0CB]
    if let n = named[v] { return Col(n) }
    guard v.hasPrefix("#") else { return nil }
    var hex = String(v.dropFirst())
    if hex.count == 3 { hex = hex.map { "\($0)\($0)" }.joined() }
    guard hex.count == 6, let n = UInt32(hex, radix: 16) else { return nil }
    return Col(n)
}

/// Parses SVG path data (M L H V C S Q T A Z, absolute and relative) into a CGPath.
func svgPath(_ d: String) -> CGPath {
    let p = CGMutablePath()
    var tokens: [String] = []
    var cur = ""
    func flush() { if !cur.isEmpty { tokens.append(cur); cur = "" } }
    var prev: Character = " "
    for ch in d {
        if ch.isLetter && ch != "e" && ch != "E" { flush(); tokens.append(String(ch)) }
        else if ch == "," || ch == " " || ch == "\n" || ch == "\t" { flush() }
        else if ch == "-" && !(prev == "e" || prev == "E") { flush(); cur.append(ch) }
        else if ch == "." && cur.contains(".") && !cur.contains("e") { flush(); cur.append(ch) }
        else { cur.append(ch) }
        prev = ch
    }
    flush()
    var i = 0
    var cmd: Character = "M"
    var pt = CGPoint.zero, start = CGPoint.zero, lastCtrl: CGPoint? = nil, lastQ: CGPoint? = nil
    func n() -> CGFloat { defer { i += 1 }; return i < tokens.count ? CGFloat(Double(tokens[i]) ?? 0) : 0 }
    func isNum() -> Bool { i < tokens.count && Double(tokens[i]) != nil }
    while i < tokens.count {
        if let c = tokens[i].first, tokens[i].count == 1, c.isLetter { cmd = c; i += 1 }
        let rel = cmd.isLowercase
        let base = rel ? pt : .zero
        switch cmd.uppercased().first! {
        case "M":
            pt = CGPoint(x: base.x + n(), y: base.y + n()); p.move(to: pt); start = pt
            cmd = rel ? "l" : "L"; lastCtrl = nil; lastQ = nil
        case "L": pt = CGPoint(x: base.x + n(), y: base.y + n()); p.addLine(to: pt); lastCtrl = nil; lastQ = nil
        case "H": pt = CGPoint(x: (rel ? pt.x : 0) + n(), y: pt.y); p.addLine(to: pt); lastCtrl = nil; lastQ = nil
        case "V": pt = CGPoint(x: pt.x, y: (rel ? pt.y : 0) + n()); p.addLine(to: pt); lastCtrl = nil; lastQ = nil
        case "C":
            let c1 = CGPoint(x: base.x + n(), y: base.y + n()), c2 = CGPoint(x: base.x + n(), y: base.y + n())
            pt = CGPoint(x: base.x + n(), y: base.y + n()); p.addCurve(to: pt, control1: c1, control2: c2); lastCtrl = c2; lastQ = nil
        case "S":
            let c1 = lastCtrl.map { CGPoint(x: 2 * pt.x - $0.x, y: 2 * pt.y - $0.y) } ?? pt
            let c2 = CGPoint(x: base.x + n(), y: base.y + n())
            pt = CGPoint(x: base.x + n(), y: base.y + n()); p.addCurve(to: pt, control1: c1, control2: c2); lastCtrl = c2; lastQ = nil
        case "Q":
            let c = CGPoint(x: base.x + n(), y: base.y + n())
            pt = CGPoint(x: base.x + n(), y: base.y + n()); p.addQuadCurve(to: pt, control: c); lastQ = c; lastCtrl = nil
        case "T":
            let c = lastQ.map { CGPoint(x: 2 * pt.x - $0.x, y: 2 * pt.y - $0.y) } ?? pt
            pt = CGPoint(x: base.x + n(), y: base.y + n()); p.addQuadCurve(to: pt, control: c); lastQ = c; lastCtrl = nil
        case "A":
            let rx = abs(n()), ry = abs(n()), rot = n() * .pi / 180, large = n() != 0, sweep = n() != 0
            let end = CGPoint(x: base.x + n(), y: base.y + n())
            for q in arcPoints(from: pt, to: end, rx: rx, ry: ry, rotation: rot, large: large, sweep: sweep) { p.addLine(to: q) }
            pt = end; lastCtrl = nil; lastQ = nil
        case "Z":
            p.closeSubpath(); pt = start; lastCtrl = nil; lastQ = nil
            if isNum() { i += 1 }                                   // stray number after Z: skip it, never loop on it
            continue
        default: i += 1
        }
        if !isNum() && i < tokens.count && !(tokens[i].first?.isLetter ?? false) { i += 1 }
    }
    return p
}

/// SVG elliptical arc → points (endpoint parameterisation, SVG spec F.6).
func arcPoints(from p1: CGPoint, to p2: CGPoint, rx rx0: CGFloat, ry ry0: CGFloat, rotation phi: CGFloat, large: Bool, sweep: Bool) -> [CGPoint] {
    guard rx0 > 0, ry0 > 0, p1 != p2 else { return [p2] }
    var rx = rx0, ry = ry0
    let cp = cos(phi), sp = sin(phi)
    let dx = (p1.x - p2.x) / 2, dy = (p1.y - p2.y) / 2
    let x1 = cp * dx + sp * dy, y1 = -sp * dx + cp * dy
    let lam = x1 * x1 / (rx * rx) + y1 * y1 / (ry * ry)
    if lam > 1 { rx *= sqrt(lam); ry *= sqrt(lam) }
    let num = rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1
    let den = rx * rx * y1 * y1 + ry * ry * x1 * x1
    var co = sqrt(max(0, num / den)); if large == sweep { co = -co }
    let cx1 = co * rx * y1 / ry, cy1 = -co * ry * x1 / rx
    let cx = cp * cx1 - sp * cy1 + (p1.x + p2.x) / 2, cy = sp * cx1 + cp * cy1 + (p1.y + p2.y) / 2
    func ang(_ ux: CGFloat, _ uy: CGFloat, _ vx: CGFloat, _ vy: CGFloat) -> CGFloat {
        let a = atan2(ux * vy - uy * vx, ux * vx + uy * vy); return a
    }
    let t1 = ang(1, 0, (x1 - cx1) / rx, (y1 - cy1) / ry)
    var dt = ang((x1 - cx1) / rx, (y1 - cy1) / ry, (-x1 - cx1) / rx, (-y1 - cy1) / ry)
    if !sweep && dt > 0 { dt -= 2 * .pi } else if sweep && dt < 0 { dt += 2 * .pi }
    let steps = max(6, Int(abs(dt) / (.pi / 16)))
    return (1...steps).map { k in
        let a = t1 + dt * CGFloat(k) / CGFloat(steps)
        let x = rx * cos(a), y = ry * sin(a)
        return CGPoint(x: cp * x - sp * y + cx, y: sp * x + cp * y + cy)
    }
}

func quadPoint(_ a: CGPoint, _ c: CGPoint, _ b: CGPoint, _ u: CGFloat) -> CGPoint {
    let v: CGFloat = 1 - u
    let x: CGFloat = v * v * a.x + 2 * v * u * c.x + u * u * b.x
    let y: CGFloat = v * v * a.y + 2 * v * u * c.y + u * u * b.y
    return CGPoint(x: x, y: y)
}
func cubicPoint(_ a: CGPoint, _ c1: CGPoint, _ c2: CGPoint, _ b: CGPoint, _ u: CGFloat) -> CGPoint {
    let v: CGFloat = 1 - u
    let k0: CGFloat = v * v * v, k1: CGFloat = 3 * v * v * u, k2: CGFloat = 3 * v * u * u, k3: CGFloat = u * u * u
    let x: CGFloat = k0 * a.x + k1 * c1.x + k2 * c2.x + k3 * b.x
    let y: CGFloat = k0 * a.y + k1 * c1.y + k2 * c2.y + k3 * b.y
    return CGPoint(x: x, y: y)
}

/// Flattens a path into polylines (one per subpath), for draw-on strokes.
func polylines(_ path: CGPath, tolerance: CGFloat = 1.5) -> [[CGPoint]] {
    var out: [[CGPoint]] = []
    var cur: [CGPoint] = []
    var last = CGPoint.zero, first = CGPoint.zero
    path.applyWithBlock { (el: UnsafePointer<CGPathElement>) in
        let e: CGPathElement = el.pointee
        switch e.type {
        case .moveToPoint:
            if cur.count > 1 { out.append(cur) }
            last = e.points[0]; first = last; cur = [last]
        case .addLineToPoint:
            last = e.points[0]; cur.append(last)
        case .addQuadCurveToPoint:
            let c: CGPoint = e.points[0], to: CGPoint = e.points[1]
            let n: Int = max(4, Int(hypot(to.x - last.x, to.y - last.y) / (tolerance * 4)))
            for k in 1...n { cur.append(quadPoint(last, c, to, CGFloat(k) / CGFloat(n))) }
            last = to
        case .addCurveToPoint:
            let c1: CGPoint = e.points[0], c2: CGPoint = e.points[1], to: CGPoint = e.points[2]
            let n: Int = max(6, Int(hypot(to.x - last.x, to.y - last.y) / (tolerance * 3)))
            for k in 1...n { cur.append(cubicPoint(last, c1, c2, to, CGFloat(k) / CGFloat(n))) }
            last = to
        case .closeSubpath:
            cur.append(first); last = first
        @unknown default:
            break
        }
    }
    if cur.count > 1 { out.append(cur) }
    return out
}

/// Draws an illustration fitted into `box`.
/// `draw` 0…1 draws strokes on in order (outlines of filled shapes too); `fill` 0…1 fades the fills in.
func drawDrawing(_ d: Drawing, in box: CGRect, draw drawP: Double = 1, fill fillP: Double = 1, tint: Col? = nil, lineScale: CGFloat = 1) {
    let dest = fitted(d.viewBox, in: box)
    let k = dest.width / d.viewBox.width
    let total = d.shapes.count
    ctx.saveGState()
    ctx.translateBy(x: dest.minX - d.viewBox.minX * k, y: dest.minY - d.viewBox.minY * k)
    ctx.scaleBy(x: k, y: k)
    for (i, s) in d.shapes.enumerated() {
        if let f = s.fill, fillP > 0 { fill(s.path, (tint ?? f).alpha(CGFloat(fillP) * (tint == nil ? 1 : f.a))) }
        let share = 1 / Double(max(1, total))
        let local = prog(drawP, Double(i) * share * 0.6, Double(i) * share * 0.6 + 0.4 + share * 0.4)
        if let st = s.stroke ?? (fillP < 1 ? s.fill : nil), local > 0 {
            let w = max(s.width, s.stroke == nil ? 2 / k : s.width) * lineScale
            if local >= 1 { stroke(s.path, tint ?? st, w) }
            else { for poly in polylines(s.path) { stroke(partial(poly, local), tint ?? st, w) } }
        }
    }
    ctx.restoreGState()
}
