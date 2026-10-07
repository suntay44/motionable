// motionable engine: the layout audit (part of `check`, and run on the keyframes by `storyboard`). It finds what a
// careful eye finds: text colliding with text, text cut off by the frame or by its card, crops that slice through UI,
// large empty areas, and headlines that don't share a margin.
import AppKit

final class LayoutLog {
    struct Drawn { let key: String; let rect: CGRect; let clip: CGRect; let settled: Bool; let align: CGFloat; let size: CGFloat; let headline: Bool }
    var frame: [Drawn] = []                                              // text drawn in the current frame
    var collisions: [String: (times: [Double], joinFrames: Int)] = [:]
    var cutOff: [String: [Double]] = [:]
    var slices: [String: (times: [Double], camera: Bool)] = [:]
    var empty: [(t: Double, what: String)] = []
    var margins: [Int: Set<String>] = [:]                                // left edge (to 16 px) → left-aligned headlines there
    var lastCrop: [String: CGRect] = [:]                                 // where each source was cropped last frame
    var t = 0.0
    var inJoin = false
    var seeThrough = false
}
/// Non-nil only while `check` or `storyboard` runs.
var layoutLog: LayoutLog?

/// Records a block of text drawn now, settled or still moving (called by text drawing; a no-op outside `check`).
func noteDrawn(_ s: String, size: CGFloat, rect: CGRect, settled: Bool, align: CGFloat, headline: Bool = false) {
    guard let log = layoutLog, (textLog?.muted ?? 0) == 0, size >= 24 else { return }
    let key = s.trimmingCharacters(in: .whitespaces)
    guard key.count >= 2 else { return }
    let k = 1 / deviceScale
    func canvas(_ r: CGRect) -> CGRect {
        let d = ctx.convertToDeviceSpace(r)
        return CGRect(x: d.minX * k, y: d.minY * k, width: d.width * k, height: d.height * k)
    }
    log.frame.append(.init(key: key, rect: canvas(rect), clip: canvas(ctx.boundingBoxOfClipPath), settled: settled, align: align, size: size,
                           headline: headline))
}

/// Records whether a crop of `image` (a screenshot or a recording's frame, in its pixels) has an edge running through UI.
/// `camera`: the crop is a camera moving inside a card, where cropping the periphery is normal (advice, not a failure).
func noteCrop(_ name: String, image: CGImage, region: CGRect, camera: Bool) {
    guard let log = layoutLog else { return }
    let w = CGFloat(image.width), h = CGFloat(image.height)
    let r = region.intersection(CGRect(x: 0, y: 0, width: w, height: h))
    guard !r.isNull, r.width > 8, r.height > 8 else { return }
    // A camera mid-move crosses content on its way; only judge where it comes to rest.
    var moving = false
    if let last = log.lastCrop[name] {
        let dx: CGFloat = abs(last.minX - r.minX), dy: CGFloat = abs(last.minY - r.minY), dw: CGFloat = abs(last.width - r.width)
        moving = dx + dy + dw > 2
    }
    log.lastCrop[name] = r
    if camera && moving { return }
    var cut: [String] = []
    let x0 = Int(r.minX), x1 = Int(r.maxX), y0 = Int(r.minY), y1 = Int(r.maxY)
    if r.minY > 2 && (0..<3).contains(where: { lineBusy(image, row: y0 + $0, from: x0, to: x1) }) { cut.append("top") }
    if r.maxY < h - 2 && (1...3).contains(where: { lineBusy(image, row: y1 - $0, from: x0, to: x1) }) { cut.append("bottom") }
    if r.minX > 2 && (0..<3).contains(where: { lineBusy(image, col: x0 + $0, from: y0, to: y1) }) { cut.append("left") }
    if r.maxX < w - 2 && (1...3).contains(where: { lineBusy(image, col: x1 - $0, from: y0, to: y1) }) { cut.append("right") }
    for e in cut {
        let key = "\(name): the crop's \(e) edge"
        log.slices[key, default: ([], camera)].times.append(log.t)
    }
}

/// True when one row (or column) of an image crosses content: several sharp light-dark changes along it (text,
/// icons, controls), rather than background or the clean edge of a single card.
func lineBusy(_ image: CGImage, row: Int? = nil, col: Int? = nil, from a: Int, to b: Int) -> Bool {
    let n = max(1, b - a)
    let horizontal = row != nil
    let w = horizontal ? n : 1, h = horizontal ? 1 : n
    var px = [UInt8](repeating: 0, count: w * h)
    guard let c = CGContext(data: &px, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w, space: CGColorSpaceCreateDeviceGray(),
                            bitmapInfo: 0) else { return false }
    let iw = CGFloat(image.width), ih = CGFloat(image.height)
    // CG draws images bottom-up: put the wanted row (top-based) or column at the context's origin.
    if let row { c.draw(image, in: CGRect(x: -CGFloat(a), y: -(ih - 1 - CGFloat(row)), width: iw, height: ih)) }
    else if let col { c.draw(image, in: CGRect(x: -CGFloat(col), y: -(ih - CGFloat(b)), width: iw, height: ih)) }
    // Text and icons change light-dark densely (4+ changes within ~50 px); the clean edges of cards are far apart.
    var jumps: [Int] = []
    for i in 1..<px.count where abs(Int(px[i]) - Int(px[i - 1])) > 40 { jumps.append(i) }
    guard jumps.count >= 4 else { return false }
    for i in 0..<(jumps.count - 3) where jumps[i + 3] - jumps[i] <= 50 { return true }
    return false
}

/// Looks at one rendered frame of the check (after drawing): collisions, cut-off text, empty areas, margins.
func auditFrame(_ c: CGContext, holdFrom: Double) {
    guard let log = layoutLog else { return }
    let texts = log.frame
    defer { log.frame.removeAll() }
    // Text against text: two different blocks whose letters would overlap.
    for i in 0..<texts.count {
        for j in (i + 1)..<texts.count where texts[i].key != texts[j].key {
            let a = texts[i], b = texts[j]
            let ra = a.rect.intersection(a.clip).insetBy(dx: a.size * 0.08, dy: a.size * 0.12)
            let rb = b.rect.intersection(b.clip).insetBy(dx: b.size * 0.08, dy: b.size * 0.12)
            guard !ra.isNull, !rb.isNull, ra.intersects(rb) else { continue }
            if log.inJoin && !log.seeThrough { continue }          // one scene slides over the other: no clash
            let pair = [a.key, b.key].sorted().map { "\"\($0)\"" }.joined(separator: " and ")
            log.collisions[pair, default: ([], 0)].times.append(log.t)
            if log.inJoin { log.collisions[pair]!.joinFrames += 1 }
        }
    }
    // Settled text cut off by the frame or by the card it sits in (outside joins, where masks are expected).
    if !log.inJoin {
        let frameRect = CGRect(x: 0, y: 0, width: W, height: H)
        for d in texts where d.settled {
            let r = d.rect.insetBy(dx: d.size * 0.05, dy: d.size * 0.15)
            if !frameRect.contains(r) { log.cutOff["\"\(d.key)\" by the edge of the frame", default: []].append(log.t) }
            else if !d.clip.insetBy(dx: -2, dy: -2).contains(r) { log.cutOff["\"\(d.key)\" by the card or mask it sits in", default: []].append(log.t) }
            if d.headline && d.align == 0 && d.size >= 60 { log.margins[Int((d.rect.minX / 16).rounded()) * 16, default: []].insert(d.key) }
        }
    }
    // Empty areas: a large part of the frame with nothing on it, outside joins.
    if !log.inJoin, let what = largestEmptyArea(c) { log.empty.append((log.t, what)) }
}

/// The largest empty rectangle of the frame (cells with almost no contrast), described in words, when it covers more
/// than 42 % of the frame. Ruled lines, gradients and soft shapes count as empty: they're background.
func largestEmptyArea(_ c: CGContext) -> String? {
    guard let data = c.data else { return nil }
    let w = c.width, h = c.height, bpr = c.bytesPerRow
    let px = data.bindMemory(to: UInt8.self, capacity: bpr * h)
    let cols = 16, rows = max(6, Int((CGFloat(h) / CGFloat(w) * 16).rounded()))
    var empty = [[Bool]](repeating: [Bool](repeating: false, count: cols), count: rows)
    for gy in 0..<rows {
        for gx in 0..<cols {
            var lo = 255, hi = 0
            for sy in 0..<6 {
                for sx in 0..<6 {
                    let x = min(w - 1, (gx * w) / cols + (sx * w) / (cols * 6)), y = min(h - 1, (gy * h) / rows + (sy * h) / (rows * 6))
                    let o = y * bpr + x * 4
                    let l = (Int(px[o]) * 3 + Int(px[o + 1]) * 6 + Int(px[o + 2])) / 10
                    lo = min(lo, l); hi = max(hi, l)
                }
            }
            empty[gy][gx] = hi - lo < 28
        }
    }
    // Largest all-empty rectangle (histogram method).
    var heights = [Int](repeating: 0, count: cols)
    var best = (area: 0, x: 0, y: 0, w: 0, h: 0)
    for gy in 0..<rows {
        for gx in 0..<cols { heights[gx] = empty[gy][gx] ? heights[gx] + 1 : 0 }
        for gx in 0..<cols where heights[gx] > 0 {
            var minH = Int.max
            for gx2 in gx..<cols {
                minH = min(minH, heights[gx2])
                if minH == 0 { break }
                let area = minH * (gx2 - gx + 1)
                if area > best.area { best = (area, gx, gy - minH + 1, gx2 - gx + 1, minH) }
            }
        }
    }
    let frac = Double(best.area) / Double(rows * cols)
    guard frac > 0.42 else { return nil }
    let cx = (Double(best.x) + Double(best.w) / 2) / Double(cols), cy = (Double(best.y) + Double(best.h) / 2) / Double(rows)
    let horiz = best.w >= cols - 2 ? "" : (cx < 0.4 ? "left " : (cx > 0.6 ? "right " : "middle "))
    let vert = best.h >= rows - 2 ? "" : (cy < 0.4 ? "top " : (cy > 0.6 ? "bottom " : "middle "))
    let place = (vert + horiz).isEmpty ? "most of the frame" : "the \(vert)\(horiz)part".replacingOccurrences(of: "middle middle ", with: "middle ")
    return String(format: "%@ (%.0f%%)", place, frac * 100)
}

/// Prints the layout part of the report; returns false when something must be fixed.
func reportLayout(fps: Double, holdFrom: Double) -> Bool {
    guard let log = layoutLog else { return true }
    func spans(_ times: [Double]) -> String {
        let ts = times.sorted()
        guard var start = ts.first else { return "" }
        var prev = start, out: [String] = []
        for t in ts.dropFirst() + [Double.infinity] {
            if t - prev > 1.6 / fps { out.append(abs(prev - start) < 0.001 ? String(format: "%.2f s", start) : String(format: "%.2f–%.2f s", start, prev + 1 / fps)); start = t }
            prev = t
        }
        return out.prefix(3).joined(separator: ", ") + (out.count > 3 ? "…" : "")
    }
    func long(_ times: [Double], _ seconds: Double) -> Bool { Double(times.count) / fps >= seconds }
    var failures = 0, advice = 0
    for (pair, v) in log.collisions.sorted(by: { $0.key < $1.key }) {
        let outside = Double(v.times.count - v.joinFrames) / fps, during = Double(v.joinFrames) / fps
        if outside >= 0.2 {
            print("layout: ✗ \(pair) overlap (\(spans(v.times))): move one, shrink one, or don't show them together"); failures += 1
        } else if during >= 0.6 {
            print("layout: ✗ \(pair) sit on top of each other through a join (\(spans(v.times))): start the new text after the join, or move it"); failures += 1
        } else if during >= 0.15 {
            print("layout: ⚠ \(pair) cross during a join (\(spans(v.times))): start the new text after the join, or keep them apart"); advice += 1
        }
    }
    for (what, times) in log.cutOff.sorted(by: { $0.key < $1.key }) where long(times, 0.2) {
        print("layout: ✗ \(what) is cut off (\(spans(times))): move it in, or make it fit"); failures += 1
    }
    for (what, v) in log.slices.sorted(by: { $0.key < $1.key }) where long(v.times, v.camera ? 0.5 : 0.2) {
        if v.camera { print("layout: ⚠ \(what) crops through UI (\(spans(v.times))): fine at the edge of a camera move, but keep what matters inside"); advice += 1 }
        else { print("layout: ✗ \(what) slices through UI (\(spans(v.times))): snap the crop to a gap between elements"); failures += 1 }
    }
    // Empty: runs of at least 1.2 s, reported once per run.
    var runStart: Double? = nil, prev = -1.0, what = ""
    for e in log.empty + [(t: Double.infinity, what: "")] {
        if let s = runStart, e.t - prev > 1.6 / fps {
            if prev - s + 1 / fps >= 1.2 { print(String(format: "layout: ⚠ %@ is empty from %.2f–%.2f s: fill it on purpose (the product, a visual, the type), or tighten the layout", what, s, prev + 1 / fps)); advice += 1 }
            runStart = nil
        }
        if runStart == nil { runStart = e.t; what = e.what }
        prev = e.t
    }
    let groups = log.margins.keys.sorted()
    var merged: [Int] = []
    for g in groups where merged.last.map({ g - $0 > 24 }) ?? true { merged.append(g) }
    if merged.count > 2 {
        print("layout: ⚠ left-aligned headlines start at \(merged.count) different edges (x \(merged.map(String.init).joined(separator: ", "))): give them one margin"); advice += 1
    }
    if failures == 0 && advice == 0 { print("layout: ✓ no collisions, cut-off text, sliced UI or empty stretches") }
    return failures == 0
}

// MARK: - Storyboard

/// The settled moment of each beat: the film's `keyframes`, or each scene just before its outgoing join, and the end.
func storyboardTimes() -> [Double] {
    if !film.keyframes.isEmpty { return film.keyframes.sorted() }
    _ = renderImage(0)                                   // registers the reel's joins
    var ts: [Double] = []
    for j in reelJoins { ts.append(max(0, j.at - j.duration / 2 - 0.25)) }
    ts.append(film.duration - 1 / Double(film.fps))
    if ts.count < 2 { ts = (0..<6).map { film.duration * (Double($0) + 0.9) / 6 } }
    return ts.map { ($0 * 100).rounded() / 100 }
}

/// `run.sh <film> storyboard`: every keyframe on one large sheet, each audited on its own (overlaps, cut-off text,
/// sliced crops, contrast, safe zones, empty areas). Lay a film out and pass this before animating it.
@discardableResult
func runStoryboard(to url: URL) -> Bool {
    let times = storyboardTimes()
    // The sheet: big enough to judge composition.
    let cw = W > H ? 640 : (W < H ? 360 : 480), ch = Int(CGFloat(cw) * H / W), cols = min(W > H ? 3 : 5, times.count)
    let rows = (times.count + cols - 1) / cols
    let sheet = CGContext(data: nil, width: cols * cw, height: rows * (ch + 44), bitsPerComponent: 8, bytesPerRow: 0, space: srgb,
                          bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    sheet.setFillColor(CGColor(gray: 0.13, alpha: 1)); sheet.fill(CGRect(x: 0, y: 0, width: cols * cw, height: rows * (ch + 44)))
    let images = times.map { renderImage($0) }
    // Audit each keyframe at the check's scale.
    var findings: [[String]] = []
    let c = CGContext(data: nil, width: Int(W * checkScale), height: Int(H * checkScale), bitsPerComponent: 8, bytesPerRow: 0, space: srgb,
                      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    deviceScale = checkScale
    for t in times {
        let log = TextLog(), layout = LayoutLog()
        textLog = log; layoutLog = layout
        log.t = t; layout.t = t
        layout.inJoin = false
        c.saveGState()
        c.translateBy(x: 0, y: H * checkScale); c.scaleBy(x: checkScale, y: -checkScale)
        ctx = c; ctx.textMatrix = .identity
        fill(CGRect(x: 0, y: 0, width: W, height: H), Col(0x000000))
        film.draw(t)
        c.restoreGState()
        var issues: [String] = []
        for s in log.thisFrame {
            let sighting = log.seen[s.key]![s.index]
            if let m = measureContrast(c, rect: sighting.rect, colours: sighting.colours), m.ratio < minimumContrast {
                issues.append(String(format: "✗ \"%@\" is %.1f:1 against its background", s.key, m.ratio))
            }
            for zone in uiZones() where zone.rect.intersects(sighting.rect.insetBy(dx: 4, dy: 4)) {
                issues.append("✗ \"\(s.key)\" sits in \(zone.name)"); break
            }
        }
        auditFrame(c, holdFrom: film.holdFrom)
        for (pair, _) in layout.collisions { issues.append("✗ \(pair) overlap") }
        for (what, _) in layout.cutOff { issues.append("✗ \(what) is cut off") }
        for (what, v) in layout.slices { issues.append(v.camera ? "⚠ \(what) crops through UI" : "✗ \(what) slices through UI") }
        for e in layout.empty { issues.append("⚠ \(e.what) is empty") }
        findings.append(issues)
        textLog = nil; layoutLog = nil
    }
    deviceScale = 1
    // Draw the sheet with each keyframe's verdict under it.
    ctx = sheet
    sheet.translateBy(x: 0, y: CGFloat(rows * (ch + 44))); sheet.scaleBy(x: 1, y: -1)
    sheet.textMatrix = .identity
    sheet.interpolationQuality = .high
    for (i, img) in images.enumerated() {
        let col = i % cols, row = i / cols
        let x = CGFloat(col * cw), y = CGFloat(row * (ch + 44))
        drawImage(img, in: CGRect(x: x, y: y, width: CGFloat(cw), height: CGFloat(ch)))
        let bad = findings[i].contains { $0.hasPrefix("✗") }, warn = !findings[i].isEmpty
        let label = String(format: "%d · %.2f s · %@", i + 1, times[i], bad ? "fix" : (warn ? "look" : "ok"))
        text(label, 24, .semibold, bad ? Col(0xFF6B6B) : (warn ? Col(0xFFC542) : Col(0x7EE08A)), x + 10, y + CGFloat(ch) + 31)
    }
    writePNG(sheet.makeImage()!, url)
    print("storyboard: \(times.count) keyframes → \(url.path)")
    var ok = true
    for (i, t) in times.enumerated() {
        let f = findings[i]
        print(String(format: "  %d · %6.2f s  %@", i + 1, t, f.isEmpty ? "✓ clean" : f.joined(separator: "; ")))
        if f.contains(where: { $0.hasPrefix("✗") }) { ok = false }
    }
    print(ok ? "verdict: the layout holds; animate it" : "verdict: fix the keyframes marked ✗ before animating")
    return ok
}
