// motionable engine: the readability check (`run.sh <film> check`). Samples the film, records every line of
// readable text while it is fully shown (and where it sits), then reports lines that leave before a viewer can
// read them, and text inside the social apps' button zones.
import AppKit

/// Reading speed for on-screen text: characters per second, plus a minimum time, after the line has fully appeared.
let readingCPS = 15.0, readingMinimum = 1.0, readingSettle = 0.4

/// The check renders at this fraction of full size: it needs where text sits, not every pixel.
let checkScale: CGFloat = 0.5
/// Pixels per canvas unit of the context being drawn into now (check and draft render small; layers are full size).
var deviceScale: CGFloat = 1

final class TextLog {
    struct Sighting { let t: Double; let rect: CGRect }
    var seen: [String: [Sighting]] = [:]
    var muted = 0
    var t = 0.0
}
/// Where platform UI covers the video, by format (canvas fractions). Sources in RESEARCH.md.
/// Portrait 9:16: the union of Meta Reels' keep-clear zones (top 14 %, bottom 35 %, sides 6 %) and YouTube Shorts'
/// (top 10 %, bottom 25 %, right 10 %); TikTok publishes templates, not numbers. Key text lives in the band between.
/// Landscape 16:9 (YouTube, websites): the player controls along the bottom (an estimate). Square / 4:5: a thin margin.
func uiZones() -> [(name: String, rect: CGRect)] {
    let r = W / H
    func z(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect { CGRect(x: x * W, y: y * H, width: w * W, height: h * H) }
    if r < 0.7 {
        return [("the bottom 35 % (Reels caption and buttons; Shorts covers the bottom 25 %)", z(0, 0.65, 1, 0.35)),
                ("the top 14 % (Reels and Shorts top bar)", z(0, 0, 1, 0.14)),
                ("the right 10 % (Shorts and TikTok buttons)", z(0.90, 0, 0.10, 1)),
                ("the left 6 % (Reels side margin)", z(0, 0, 0.06, 1))]
    } else if r > 1.3 {
        return [("the bottom 12 % (player controls, estimate)", z(0, 0.88, 1, 0.12)),
                ("the outer 4 % (title-safe margin)", z(0, 0, 1, 0.04)), ("the outer 4 % (title-safe margin)", z(0, 0, 0.04, 1)),
                ("the outer 4 % (title-safe margin)", z(0.96, 0, 0.04, 1))]
    } else {
        return [("the outer 5 % (feed margin)", z(0, 0.95, 1, 0.05)), ("the outer 5 % (feed margin)", z(0, 0, 1, 0.05)),
                ("the outer 5 % (feed margin)", z(0, 0, 0.05, 1)), ("the outer 5 % (feed margin)", z(0.95, 0, 0.05, 1))]
    }
}

/// Non-nil only while `check` runs.
var textLog: TextLog?

/// Records a readable line that is fully on screen now (called by text drawing; cheap no-op outside `check`).
func noteText(_ s: String, size: CGFloat, rect: CGRect) {
    guard let log = textLog, log.muted == 0, size >= 34 else { return }
    let clean = s.trimmingCharacters(in: .whitespaces)
    guard clean.count >= 2 else { return }
    let device = ctx.convertToDeviceSpace(rect)                     // device pixels (top-down here), at deviceScale
    let k = 1 / deviceScale
    let top = CGRect(x: device.minX * k, y: device.minY * k, width: device.width * k, height: device.height * k)
    log.seen[clean, default: []].append(TextLog.Sighting(t: log.t, rect: top))
}
/// Runs `draw` without recording its text (decorative or intermediate text: tickers, rolling digits, scrambles).
func unlogged(_ draw: () -> Void) {
    textLog?.muted += 1
    draw()
    textLog?.muted -= 1
}

/// Samples the film at `fps` and prints the report. Returns false if anything fails.
@discardableResult
func runReadabilityCheck(fps: Double = 20) -> Bool {
    let log = TextLog()
    textLog = log
    let c = CGContext(data: nil, width: Int(W * checkScale), height: Int(H * checkScale), bitsPerComponent: 8, bytesPerRow: 0,
                      space: srgb, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    let frames = Int(film.duration * fps)
    var flat: [Double] = []                                        // times of frames with almost nothing on them
    var lumas: [Double] = []                                       // each frame's mean relative luminance, for flashing
    deviceScale = checkScale
    defer { deviceScale = 1 }
    for f in 0..<frames {
        let t = Double(f) / fps
        log.t = t
        c.saveGState()
        c.translateBy(x: 0, y: H * checkScale); c.scaleBy(x: checkScale, y: -checkScale)
        ctx = c
        ctx.textMatrix = .identity
        fill(CGRect(x: 0, y: 0, width: W, height: H), Col(0x000000))
        film.draw(t)
        c.restoreGState()
        if t < film.holdFrom && isEmptyFrame(c) { flat.append(t) }
        lumas.append(meanLuminance(c))
    }
    textLog = nil

    // A line that is a prefix of a longer line on the same baseline, moments apart, is a typing state, not its own line.
    let keys = log.seen.keys.sorted { $0.count > $1.count }
    // A counter (the same text with different numbers, each replaced by the next within a moment) is judged
    // only by the value it settles on: its in-between values are skipped.
    func pattern(_ k: String) -> String { k.replacingOccurrences(of: "[0-9]+", with: "#", options: .regularExpression) }
    let firstSeen = log.seen.mapValues { $0.map(\.t).min()! }, lastSeen = log.seen.mapValues { $0.map(\.t).max()! }
    var counting = Set<String>()
    for k in keys where k.rangeOfCharacter(from: .decimalDigits) != nil {
        let pk = pattern(k)
        if keys.contains(where: { $0 != k && pattern($0) == pk && firstSeen[$0]! > lastSeen[k]! - 0.001 && firstSeen[$0]! <= lastSeen[k]! + 0.2 }) {
            counting.insert(k)
        }
    }
    var report: [(String, Double, Double, Bool)] = []          // text, longest span, needed, ok
    var zoneHits: [String] = []
    let step = 1 / fps
    for k in keys where !counting.contains(k) {
        let times = log.seen[k]!.map(\.t).sorted()
        let first = log.seen[k]!.min { $0.t < $1.t }!
        if keys.contains(where: { $0 != k && $0.count > k.count && $0.hasPrefix(k)
                                  && log.seen[$0]!.contains(where: { s in abs(s.t - first.t) < 3 && abs(s.rect.maxY - first.rect.maxY) < 8 }) }) { continue }
        var longest = 0.0, start = times[0], prev = times[0]
        for tt in times.dropFirst() {
            if tt - prev > step * 1.6 { longest = max(longest, prev - start + step); start = tt }
            prev = tt
        }
        longest = max(longest, prev - start + step)
        let needed = max(readingMinimum, Double(k.count) / readingCPS + readingSettle)
        report.append((k, longest, needed, longest + 0.001 >= needed))
        // Safe zones: platform UI covers these parts of the frame (uiZones, by format).
        // Only text that stays there counts (half a second or more), not text passing through during a join.
        for zone in uiZones() {
            let inside = log.seen[k]!.filter { zone.rect.intersects($0.rect.insetBy(dx: 4, dy: 4)) }.count
            if Double(inside) * step >= 0.5 { zoneHits.append("\"\(k)\" sits in \(zone.name)"); break }
        }
    }
    report.sort { a, b in (log.seen[a.0]!.first!.t) < (log.seen[b.0]!.first!.t) }
    print(String(format: "text on screen (needs %.0f characters/s + %.1f s, at least %.1f s, after it has fully appeared):", readingCPS, readingSettle, readingMinimum))
    for (k, longest, needed, ok) in report {
        let first = log.seen[k]!.first!.t
        print(String(format: "  %@ %5.2f s  \"%@\"  readable %.2f s, needs %.2f s%@", ok ? "✓" : "✗", first, k, longest, needed,
                     ok ? "" : "  ← TOO SHORT: hold it longer, start it sooner, or speed up its entrance"))
    }
    let format = W / H < 0.7 ? "9:16 portrait" : (W / H > 1.3 ? "16:9 landscape" : "square / 4:5")
    if zoneHits.isEmpty { print("safe zones (\(format)): ✓ no text under platform UI") }
    else { for k in zoneHits { print("safe zones (\(format)): ✗ \(k), where the app's buttons or controls cover it") } }
    if let probe = ProcessInfo.processInfo.environment["MOTIONABLE_PROBE"], let hits = log.seen.first(where: { $0.key.contains(probe) })?.value {
        for h in hits.prefix(4) + hits.suffix(2) { print(String(format: "probe %.2f s: x %.0f y %.0f w %.0f h %.0f", h.t, h.rect.minX, h.rect.minY, h.rect.width, h.rect.height)) }
    }
    // Dead air: a run of near-empty frames (one flat colour) of 0.3 s or more, before the final hold.
    var dead: [(Double, Double)] = []
    if var start = flat.first {
        var prev = start
        for t in flat.dropFirst() + [Double.infinity] {
            if t - prev > 1.5 / fps { if prev - start + 1 / fps >= 0.3 { dead.append((start, prev + 1 / fps)) }; start = t }
            prev = t
        }
    }
    if dead.isEmpty { print("dead air: ✓ no empty stretches") }
    else { for d in dead { print(String(format: "dead air: ✗ %.2f–%.2f s is an empty frame; start the next scene's content before the join's middle", d.0, d.1)) } }

    // Frame 1: the hook should already read (rules.md › 12). Advice, not a failure: a film may open on a picture on purpose.
    let opening = log.seen.filter { $0.value.contains { $0.t == 0 } }.map(\.key).sorted { $0.count > $1.count }
    if let first = opening.first { print("frame 1: ✓ \"\(first)\"") }
    else { print("frame 1: ⚠ no readable words yet; open on the hook (rules.md › 12), or keep the reason in DIRECTION.md") }

    // Rhythm: shots of one length feel mechanical (RESEARCH.md › Rhythm). Advice, not a failure.
    let cuts = [0] + reelJoins.map(\.at).filter { $0 > 0 && $0 < film.duration } + [film.duration]
    let shots = zip(cuts, cuts.dropFirst()).map { $1 - $0 }
    if shots.count >= 4, let lo = shots.min(), let hi = shots.max() {
        if hi / max(lo, 0.01) < 1.25 { print(String(format: "rhythm: ⚠ all %d shots are %.1f–%.1f s long; vary them", shots.count, lo, hi)) }
        else { print(String(format: "rhythm: ✓ %d shots, %.1f to %.1f s", shots.count, lo, hi)) }
    }

    // Flashing (WCAG 2.3.1): no more than three flashes in any second. A flash is a pair of opposite changes of 10 % or
    // more in the frame's mean relative luminance, with the darker side below 0.8.
    var changes: [Double] = [], lastLevel = lumas.first ?? 0, lastUp: Bool? = nil
    for (i, l) in lumas.enumerated() {
        let d = l - lastLevel
        if abs(d) >= 0.1 && min(l, lastLevel) < 0.8 {
            if lastUp != (d > 0) { changes.append(Double(i) / fps); lastUp = d > 0 }
            lastLevel = l
        } else if let up = lastUp, (up && l > lastLevel) || (!up && l < lastLevel) { lastLevel = l }   // still moving the same way
    }
    var flashing: Double? = nil
    for (i, t) in changes.enumerated() where changes[i...].prefix(while: { $0 < t + 1 }).count > 6 { flashing = t; break }
    if let t = flashing { print(String(format: "flashing: ✗ more than three flashes within a second from %.2f s; slow them down or soften them (seizure risk)", t)) }
    else { print("flashing: ✓ within the three-flashes-a-second limit") }

    let ok = report.allSatisfy(\.3) && zoneHits.isEmpty && dead.isEmpty && flashing == nil
    print(ok ? "verdict: readable" : "verdict: fix the lines marked ✗")
    return ok
}

/// The frame's mean relative luminance (0…1, linear light), from a coarse grid of the bitmap.
func meanLuminance(_ c: CGContext) -> Double {
    guard let data = c.data else { return 0 }
    let w = c.width, h = c.height, bpr = c.bytesPerRow
    let px = data.bindMemory(to: UInt8.self, capacity: bpr * h)
    func lin(_ v: UInt8) -> Double { let x = Double(v) / 255; return x <= 0.04045 ? x / 12.92 : pow((x + 0.055) / 1.055, 2.4) }
    var sum = 0.0
    for gy in 0..<32 {
        let y = (gy * h) / 32 + h / 64
        for gx in 0..<32 {
            let o = y * bpr + ((gx * w) / 32 + w / 64) * 4
            sum += 0.2126 * lin(px[o]) + 0.7152 * lin(px[o + 1]) + 0.0722 * lin(px[o + 2])
        }
    }
    return sum / 1024
}

/// True when the frame is one flat colour (nothing to look at): samples a coarse grid of the bitmap.
func isEmptyFrame(_ c: CGContext) -> Bool {
    guard let data = c.data else { return false }
    let w = c.width, h = c.height, bpr = c.bytesPerRow
    let px = data.bindMemory(to: UInt8.self, capacity: bpr * h)
    var lo = 255, hi = 0
    for gy in 0..<48 {
        let y = (gy * h) / 48 + h / 96
        for gx in 0..<27 {
            let x = (gx * w) / 27 + w / 54
            let o = y * bpr + x * 4
            let l = (Int(px[o]) * 3 + Int(px[o + 1]) * 6 + Int(px[o + 2])) / 10
            lo = min(lo, l); hi = max(hi, l)
        }
    }
    return hi - lo < 10
}
