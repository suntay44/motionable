// motionable engine: showing real screenshots without slicing them. A Screenshot knows where its quiet
// rows are (the gaps between UI elements), so any crop can be snapped to them: no button, price or list row
// is ever cut through. Screens fit their box instead of being cropped to it.
import AppKit

final class Screenshot {
    let image: CGImage
    let size: CGSize
    /// Quiet rows / columns in image pixels: rows with almost no edges (background between elements).
    private(set) var quietRows: [Bool] = []
    private(set) var quietCols: [Bool] = []
    /// The colour at the screenshot's edges, for padding.
    private(set) var edge = Col(0xFFFFFF)

    init(_ path: String) {
        image = loadImage(path)
        size = CGSize(width: image.width, height: image.height)
        analyse()
    }

    private func analyse() {
        let w = 240, h = max(1, Int(CGFloat(w) * size.height / size.width))
        var px = [UInt8](repeating: 0, count: w * h)
        let c = CGContext(data: &px, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w,
                          space: CGColorSpaceCreateDeviceGray(), bitmapInfo: 0)!
        c.interpolationQuality = .medium
        c.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        // CGContext rows run bottom-up in memory order of the drawn image: row 0 of px is the image's top.
        func lum(_ x: Int, _ y: Int) -> Int { Int(px[y * w + x]) }
        var rowEdges = [Int](repeating: 0, count: h), colEdges = [Int](repeating: 0, count: w)
        for y in 0..<h { for x in 1..<w where abs(lum(x, y) - lum(x - 1, y)) > 14 { rowEdges[y] += 1 } }
        for x in 0..<w { for y in 1..<h where abs(lum(x, y) - lum(x, y - 1)) > 14 { colEdges[x] += 1 } }
        let sy = size.height / CGFloat(h), sx = size.width / CGFloat(w)
        quietRows = (0..<Int(size.height)).map { rowEdges[min(h - 1, Int(CGFloat($0) / sy))] <= 4 }
        quietCols = (0..<Int(size.width)).map { colEdges[min(w - 1, Int(CGFloat($0) / sx))] <= 4 }
        edge = Screenshot.pixel(image, at: CGPoint(x: 8, y: size.height * 0.5))
    }

    /// The colour of one pixel (top-left coordinates), read through a known RGBA format so any PNG/JPEG works.
    static func pixel(_ img: CGImage, at p: CGPoint) -> Col {
        guard let one = img.cropping(to: CGRect(x: Int(p.x), y: Int(p.y), width: 1, height: 1)) else { return Col(0xFFFFFF) }
        var rgba = [UInt8](repeating: 0, count: 4)
        let c = CGContext(data: &rgba, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: srgb,
                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        c.draw(one, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        return Col(r: CGFloat(rgba[0]) / 255, g: CGFloat(rgba[1]) / 255, b: CGFloat(rgba[2]) / 255, a: 1)
    }

    var bounds: CGRect { CGRect(origin: .zero, size: size) }

    /// Moves a crop's edges outward to the nearest gap between elements (or inward if no gap is near),
    /// so nothing is cut in half. Prefers the middle of a run of quiet rows, for even margins.
    func snapped(_ r: CGRect) -> CGRect {
        let b = r.intersection(bounds)
        guard !b.isNull, b.height > 4 else { return bounds }
        func runMid(_ quiet: [Bool], around i: Int, dir: Int, limit: Int) -> Int? {
            // Already in a clear gap (6 quiet rows either side): keep the edge that was asked for.
            if i >= 6 && i + 6 < quiet.count && (i - 6...i + 6).allSatisfy({ quiet[$0] }) { return i }
            var k = i, steps = 0
            while k >= 0 && k < quiet.count && steps <= limit {
                if quiet[k] {
                    var a = k, z = k
                    while a > 0 && quiet[a - 1] && k - a < 60 { a -= 1 }
                    while z < quiet.count - 1 && quiet[z + 1] && z - k < 60 { z += 1 }
                    return (a + z) / 2
                }
                k += dir; steps += 1
            }
            return nil
        }
        let reachOut = Int(b.height * 0.18), reachIn = Int(b.height * 0.10)
        var top = Int(b.minY), bottom = Int(b.maxY) - 1
        if top > 0 { top = runMid(quietRows, around: top, dir: -1, limit: reachOut) ?? runMid(quietRows, around: top, dir: 1, limit: reachIn) ?? top }
        if bottom < quietRows.count - 1 {
            bottom = runMid(quietRows, around: bottom, dir: 1, limit: reachOut) ?? runMid(quietRows, around: bottom, dir: -1, limit: reachIn) ?? bottom
        }
        var left = Int(b.minX), right = Int(b.maxX) - 1
        if left > 0 || right < quietCols.count - 1 {
            let rw = Int(b.width * 0.15)
            if left > 0 { left = runMid(quietCols, around: left, dir: -1, limit: rw) ?? left }
            if right < quietCols.count - 1 { right = runMid(quietCols, around: right, dir: 1, limit: rw) ?? right }
        }
        return CGRect(x: CGFloat(left), y: CGFloat(top), width: CGFloat(max(8, right - left + 1)), height: CGFloat(max(8, bottom - top + 1)))
    }
}

/// Where a region of a screenshot lands when fitted ("contain") into `box`, keeping its proportions.
func fitted(_ region: CGRect, in box: CGRect) -> CGRect {
    let k = min(box.width / region.width, box.height / region.height)
    let w = region.width * k, h = region.height * k
    return CGRect(x: box.midX - w / 2, y: box.midY - h / 2, width: w, height: h)
}

/// Draws a screenshot (or a snapped region of it) fitted inside `box`: the card takes the region's shape,
/// so it is never cropped to the box. Returns the canvas rect it occupies.
@discardableResult
func drawScreen(_ s: Screenshot, region: CGRect? = nil, in box: CGRect, radius: CGFloat = 44, shadow: Bool = true,
                snap: Bool = true, alpha: CGFloat = 1, border: Col? = nil) -> CGRect {
    let src = region.map { snap ? s.snapped($0) : $0 } ?? s.bounds
    let dest = fitted(src, in: box)
    let k = dest.width / src.width
    let path = rr(dest, radius)
    ctx.saveGState()
    ctx.setAlpha(alpha)
    if shadow { fillShadowed(path, s.edge, blur: 46, alpha: 0.22, dy: 16) }
    ctx.addPath(path); ctx.clip()
    drawImage(s.image, in: CGRect(x: dest.minX - src.minX * k, y: dest.minY - src.minY * k, width: s.size.width * k, height: s.size.height * k))
    ctx.restoreGState()
    if let border { stroke(path, border, 3) }
    return dest
}

/// A camera inside a screenshot: keyframed regions (snapped once), eased between, for pans and zooms
/// that always rest on whole elements.
struct ScreenMove {
    let shot: Screenshot
    let keys: [(t: Double, region: CGRect)]
    init(_ shot: Screenshot, _ keys: [(Double, CGRect)], snap: Bool = true) {
        self.shot = shot
        self.keys = keys.map { (t: $0.0, region: snap ? shot.snapped($0.1) : $0.1) }
    }
    func region(_ t: Double) -> CGRect {
        guard var r = keys.first?.region else { return shot.bounds }
        for i in 1..<keys.count where t > keys[i - 1].t {
            r = lerp(keys[i - 1].region, keys[i].region, inOut(prog(t, keys[i - 1].t, keys[i].t)))
        }
        return r
    }
    @discardableResult
    func draw(_ t: Double, in box: CGRect, radius: CGFloat = 44, shadow: Bool = true, alpha: CGFloat = 1) -> CGRect {
        drawScreen(shot, region: region(t), in: box, radius: radius, shadow: shadow, snap: false, alpha: alpha)
    }
}

/// A screenshot point → canvas point, given the rect the screenshot region was drawn into.
func canvasPoint(_ p: CGPoint, region: CGRect, drawnIn dest: CGRect) -> CGPoint {
    let k = dest.width / region.width
    return CGPoint(x: dest.minX + (p.x - region.minX) * k, y: dest.minY + (p.y - region.minY) * k)
}

/// Lifts one element (a snapped region) off a screen drawn at `screenRect` and carries it, scaled, to
/// `target` on a plate with a shadow — the "callout" that shows a detail big while keeping context.
func callout(_ s: Screenshot, region: CGRect, screenRegion: CGRect? = nil, screenRect: CGRect, to target: CGRect,
             p: Double, plate: Col? = nil, radius: CGFloat = 32) {
    guard p > 0 else { return }
    let r = s.snapped(region)
    let full = screenRegion ?? s.bounds
    let origin = CGRect(origin: canvasPoint(r.origin, region: full, drawnIn: screenRect),
                        size: CGSize(width: r.width * screenRect.width / full.width, height: r.height * screenRect.width / full.width))
    let dest = lerp(origin, fitted(r, in: target), outCubic(p))        // a card: smooth, no overshoot (rules.md › 25)
    let path = rr(dest.insetBy(dx: -10, dy: -10), radius)
    ctx.saveGState()
    fillShadowed(path, plate ?? s.edge, blur: 60, alpha: CGFloat(0.35 * min(1, p * 2)), dy: 24)
    ctx.addPath(path); ctx.clip()
    let k = dest.width / r.width
    drawImage(s.image, in: CGRect(x: dest.minX - r.minX * k, y: dest.minY - r.minY * k, width: s.size.width * k, height: s.size.height * k))
    ctx.restoreGState()
}

/// Several screens side by side (or stacked) in `box`, entering one after another over p.
func screensRow(_ shots: [Screenshot], in box: CGRect, gap: CGFloat = 28, p: Double, radius: CGFloat = 36, vertical: Bool = false) {
    let n = CGFloat(shots.count)
    for (i, s) in shots.enumerated() {
        let local = outBack(prog(p, Double(i) * 0.18, Double(i) * 0.18 + 0.5), 1.1)
        guard local > 0 else { continue }
        let cell: CGRect = vertical
            ? CGRect(x: box.minX, y: box.minY + CGFloat(i) * (box.height + gap) / n, width: box.width, height: (box.height - gap * (n - 1)) / n)
            : CGRect(x: box.minX + CGFloat(i) * (box.width + gap) / n, y: box.minY, width: (box.width - gap * (n - 1)) / n, height: box.height)
        ctx.saveGState()
        ctx.translateBy(x: 0, y: (1 - CGFloat(local)) * 140)
        drawScreen(s, in: cell, radius: radius, alpha: CGFloat(min(1, local * 1.5)))
        ctx.restoreGState()
    }
}

/// Screens fanned like cards (flat, 2D: offset and slightly scaled — never tilted like a device photo).
func screensFan(_ shots: [Screenshot], centre: CGPoint, height: CGFloat, spread: CGFloat = 230, p: Double, radius: CGFloat = 40) {
    let n = shots.count
    for (i, s) in shots.enumerated().reversed() {
        let k = CGFloat(i) - CGFloat(n - 1) / 2
        let e = CGFloat(outBack(p, 1.15))
        let h = height * (1 - abs(k) * 0.08)
        let w = h * s.size.width / s.size.height
        let c = CGPoint(x: centre.x + k * spread * e, y: centre.y + abs(k) * 40 * e)
        drawScreen(s, in: CGRect(x: c.x - w / 2, y: c.y - h / 2, width: w, height: h), radius: radius)
    }
}
