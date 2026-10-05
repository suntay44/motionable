// motionable engine: kinetic type. Any face, any size, many ways in and out — by line, word or letter.
import AppKit

enum TextIn {
    case rise                    // each line rises from behind a mask
    case fade                    // lines fade in, staggered
    case pop                     // each word scales up with an overshoot
    case cascade                 // letters drop in one after another
    case typewriter(cps: Double) // characters appear at `cps` per second, with a caret
    case slam                    // the whole block lands from big to size
    case slide(Side)             // words slide in from a side (the side they come FROM)
    case stamp                   // lines thump in at 1.25× and settle
    case scramble                // random characters resolve into the text, left to right
    case split                   // letters fly in from alternating sides
    case wave                    // rise, then letters keep bobbing
    case highlight(Col)          // a marker swipe draws behind each line, then the text lands on it
    case outlineFill             // outlines draw on, then the fill floods in
}
enum TextOut {
    case none, rise, fade, drop, scatter, shrink
    case wipe(Side)
}

/// A block of kinetic text. `x`/`y` place the first line's baseline; `align` 0 = x is the left edge,
/// 0.5 = x is the centre, 1 = x is the right edge. Lines shrink together to fit `maxWidth`.
struct Kinetic {
    var lines: [String]
    var face: Face
    var size: CGFloat
    var colour: Col
    var x: CGFloat
    var y: CGFloat
    var from: Double
    var to: Double? = nil
    var enter: TextIn = .rise
    var exit: TextOut = .rise
    var align: CGFloat = 0
    var lineHeight: CGFloat = 1.0
    var kern: CGFloat = 0
    var maxWidth: CGFloat? = 860
    var upper = false
    var stagger: Double = 0.06
    var seed: Int = 1

    func draw(_ t: Double) {
        guard t >= from else { return }
        if let to, t >= to { return }
        let content = upper ? lines.map { $0.uppercased() } : lines
        let widest = content.map { textWidth($0, size, face, kern: kern) }.max() ?? 1
        let s = maxWidth.map { min(size, size * $0 / max(widest, 1)) } ?? size
        let k = kern * s / size
        let set = content.map { glyphs($0, s, face, kern: k) }
        let lt = t - from
        let gone: Double = to.map { inCubic(prog(t, $0 - 0.25, $0)) } ?? 0
        let blockW = set.map(\.width).max() ?? 0
        let blockLeft = x - blockW * align
        let blockTop = y - s * 0.95
        let blockH = s * lineHeight * CGFloat(set.count - 1) + s * 1.25
        var enterMasks = false
        switch enter { case .rise, .wave: enterMasks = true; default: break }
        var exitRises = false
        if case .rise = exit { exitRises = true }

        textLog?.muted += 1                                           // log the whole block below, not its pieces
        var blockAlpha: CGFloat = 1                                   // carried into every glyph (drawGlyph sets alpha itself)
        ctx.saveGState()
        // Block-level exits.
        switch exit {
        case .fade: blockAlpha = CGFloat(1 - gone); ctx.setAlpha(blockAlpha)
        case .shrink:
            let c = CGPoint(x: blockLeft + blockW / 2, y: blockTop + blockH / 2)
            let q = CGFloat(1 - outCubic(gone))
            ctx.translateBy(x: c.x, y: c.y); ctx.scaleBy(x: q, y: q); ctx.translateBy(x: -c.x, y: -c.y)
        case .wipe(let side):
            let q = CGFloat(gone), pad = s
            let r = CGRect(x: blockLeft - pad, y: blockTop - pad, width: blockW + 2 * pad, height: blockH + 2 * pad)
            switch side {      // the text is wiped away toward `side`
            case .left: ctx.clip(to: CGRect(x: r.minX, y: r.minY, width: r.width * (1 - q), height: r.height))
            case .right: ctx.clip(to: CGRect(x: r.minX + r.width * q, y: r.minY, width: r.width * (1 - q), height: r.height))
            case .up: ctx.clip(to: CGRect(x: r.minX, y: r.minY, width: r.width, height: r.height * (1 - q)))
            case .down: ctx.clip(to: CGRect(x: r.minX, y: r.minY + r.height * q, width: r.width, height: r.height * (1 - q)))
            }
        default: break
        }
        if case .slam = enter {
            let e = outCubic(prog(lt, 0, 0.2))
            let q = CGFloat(1 + 1.4 * (1 - e))
            let c = CGPoint(x: blockLeft + blockW / 2, y: blockTop + blockH / 2)
            ctx.translateBy(x: c.x, y: c.y); ctx.scaleBy(x: q, y: q); ctx.translateBy(x: -c.x, y: -c.y)
            blockAlpha *= CGFloat(min(1, e * 3)); ctx.setAlpha(blockAlpha)
        }

        var g = Seeded(UInt64(seed))
        var letter = 0, wordBase = 0, charsBefore = 0
        let typedTotal: Int = { if case .typewriter(let cps) = enter { return Int(lt * cps) }; return 0 }()
        let allChars = set.map(\.glyphs.count).reduce(0, +)
        for (li, line) in set.enumerated() {
            let baseline = y + s * lineHeight * CGFloat(li)
            let x0 = x - line.width * align
            let lineDelay = Double(li) * stagger
            ctx.saveGState()
            var lineDy: CGFloat = 0, lineAlpha: CGFloat = 1, lineScale: CGFloat = 1
            if enterMasks || exitRises {
                ctx.clip(to: CGRect(x: -10_000, y: baseline - s * 0.98, width: 30_000, height: s * 1.24))
            }
            switch enter {
            case .rise, .wave:
                lineDy = s * CGFloat(1 - outCubic(prog(lt, lineDelay, lineDelay + 0.36)))
            case .fade:
                lineAlpha = CGFloat(prog(lt, lineDelay, lineDelay + 0.3))
            case .stamp:
                lineAlpha = lt >= lineDelay ? 1 : 0
                lineScale = CGFloat(1 + 0.25 * (1 - outCubic(prog(lt, lineDelay, lineDelay + 0.14))))
            case .highlight(let mark):
                let m = outCubic(prog(lt, 0.1 + lineDelay, 0.5 + lineDelay))
                if m > 0 {
                    let r = CGRect(x: x0 - s * 0.12, y: baseline - s * 0.62, width: (line.width + s * 0.24) * CGFloat(m), height: s * 0.7)
                    fill(rr(r, s * 0.08), mark)
                }
                lineAlpha = CGFloat(prog(lt, lineDelay, lineDelay + 0.25))
            default: break
            }
            if exitRises { lineDy -= s * 1.1 * CGFloat(gone) }
            if lineScale != 1 {
                // Grow from the line's own alignment point, so left-aligned type never crosses the left margin.
                let c = CGPoint(x: x0 + line.width * align, y: baseline - s * 0.35)
                ctx.translateBy(x: c.x, y: c.y); ctx.scaleBy(x: lineScale, y: lineScale); ctx.translateBy(x: -c.x, y: -c.y)
            }
            let visible = lineAlpha * blockAlpha
            ctx.setAlpha(visible)

            var wordMin = [CGFloat](repeating: .greatestFiniteMagnitude, count: max(1, line.words))
            var wordMax = [CGFloat](repeating: 0, count: max(1, line.words))
            for gl in line.glyphs { wordMin[gl.word] = min(wordMin[gl.word], gl.x); wordMax[gl.word] = max(wordMax[gl.word], gl.x + gl.advance) }

            switch enter {
            case .scramble:
                let original = Array(content[li])
                let total = original.count
                let resolved = Int(Double(total) * prog(lt, lineDelay, lineDelay + 0.5 + Double(total) * 0.02))
                let pool = Array("ABCDEFGHJKLMNPQRSTUVWXYZ0123456789#$%&@")
                var str = ""
                for (i, ch) in original.enumerated() { str.append(ch == " " || i < resolved ? ch : pool[g.int(pool.count)]) }
                if lt >= lineDelay { text(str, s, face, colour, x0, baseline + lineDy, kern: k) }
            case .typewriter:
                let shown = typedTotal - charsBefore
                var caretX = x0
                for (i, gl) in line.glyphs.enumerated() where i < shown {
                    drawGlyph(gl, x0 + gl.x, baseline + lineDy, colour, alpha: visible)
                    caretX = x0 + gl.x + gl.advance
                }
                let typingHere = shown > 0 && shown < line.glyphs.count
                let finishedAll = typedTotal >= allChars && li == set.count - 1
                if (typingHere || finishedAll || (shown == 0 && li == 0)) && (t * 2).truncatingRemainder(dividingBy: 1) < 0.62 {
                    fill(CGRect(x: caretX + s * 0.04, y: baseline - s * 0.78, width: max(3, s * 0.06), height: s * 0.9), colour)
                }
            default:
                for gl in line.glyphs {
                    var dx: CGFloat = 0, dy: CGFloat = lineDy, sc: CGFloat = 1, rot: CGFloat = 0, a: CGFloat = 1
                    let wi = wordBase + gl.word
                    switch enter {
                    case .pop:
                        let e = prog(lt, Double(wi) * stagger, Double(wi) * stagger + 0.32)
                        let q = CGFloat(outBack(e, 2.4))
                        let wc = x0 + (wordMin[gl.word] + wordMax[gl.word]) / 2
                        dx = (x0 + gl.x + gl.advance / 2 - wc) * (q - 1)
                        sc = q; a = CGFloat(min(1, e * 4))
                    case .cascade:
                        let d = Double(letter) * stagger * 0.4
                        let e = prog(lt, d, d + 0.35)
                        dy += -s * 0.8 * CGFloat(1 - outBack(e, 1.8)); a = CGFloat(min(1, e * 3))
                        rot = CGFloat(1 - e) * (letter % 2 == 0 ? 0.35 : -0.35)
                    case .slide(let side):
                        let e = outCubic(prog(lt, Double(wi) * stagger, Double(wi) * stagger + 0.4))
                        let dist: CGFloat = 320 * CGFloat(1 - e)
                        switch side { case .left: dx = -dist; case .right: dx = dist; case .up: dy -= dist; case .down: dy += dist }
                        a = CGFloat(e)
                    case .split:
                        let d = Double(letter) * stagger * 0.3
                        let e = outCubic(prog(lt, d, d + 0.45))
                        dx = (letter % 2 == 0 ? -1 : 1) * 520 * CGFloat(1 - e); a = CGFloat(e)
                    case .wave:
                        if lt > 0.36 + lineDelay { dy += s * 0.06 * CGFloat(sin(t * 6 + Double(letter) * 0.55)) }
                    case .outlineFill:
                        let o = prog(lt, Double(letter) * 0.015, Double(letter) * 0.015 + 0.35)
                        if o > 0 {
                            ctx.saveGState()
                            ctx.translateBy(x: x0 + gl.x, y: baseline + dy); ctx.scaleBy(x: 1, y: -1)
                            ctx.setAlpha(CGFloat(o) * visible); stroke(gl.path, colour, max(2, s * 0.025))
                            ctx.restoreGState()
                        }
                        a = CGFloat(prog(lt, 0.45, 0.8))
                    default: break
                    }
                    switch exit {
                    case .drop:
                        let d = gone * 1.2 - Double(letter % 7) * 0.05
                        if d > 0 { dy += CGFloat(d * d) * H * 0.9; rot += CGFloat(d) * (letter % 2 == 0 ? 1 : -1) }
                    case .scatter:
                        var r = Seeded(UInt64(seed * 977 + letter))
                        let ang = r.next() * 2 * .pi, dist = CGFloat(gone) * (300 + 600 * CGFloat(r.next()))
                        dx += CGFloat(cos(ang)) * dist; dy += CGFloat(sin(ang)) * dist
                        rot += CGFloat(gone) * CGFloat(r.next() - 0.5) * 6; a *= CGFloat(1 - gone)
                    default: break
                    }
                    drawGlyph(gl, x0 + gl.x + dx, baseline, colour, scale: sc, rotate: rot, dy: dy, alpha: a * visible)
                    letter += 1
                }
            }
            ctx.restoreGState()
            wordBase += line.words
            charsBefore += line.glyphs.count
        }
        ctx.restoreGState()
        textLog?.muted -= 1
        // For the readability check: the block counts as readable once its entrance has finished.
        let words = set.map(\.words).reduce(0, +), letters = set.map(\.glyphs.count).reduce(0, +)
        let lastLine = Double(max(0, set.count - 1)) * stagger
        let reveal: Double
        switch enter {
        case .rise, .wave: reveal = lastLine + 0.36
        case .fade: reveal = lastLine + 0.3
        case .pop: reveal = Double(max(0, words - 1)) * stagger + 0.32
        case .slide: reveal = Double(max(0, words - 1)) * stagger + 0.4
        case .cascade: reveal = Double(max(0, letters - 1)) * stagger * 0.4 + 0.35
        case .typewriter(let cps): reveal = Double(letters) / cps
        case .slam: reveal = 0.2
        case .stamp: reveal = lastLine + 0.14
        case .scramble: reveal = lastLine + 0.5 + Double(content.map(\.count).max() ?? 0) * 0.02
        case .split: reveal = Double(max(0, letters - 1)) * stagger * 0.3 + 0.45
        case .highlight: reveal = lastLine + 0.5
        case .outlineFill: reveal = 0.8
        }
        if lt >= reveal && gone == 0 {
            noteText(content.joined(separator: " "), size: s,
                     rect: CGRect(x: blockLeft, y: blockTop, width: blockW, height: blockH))
        }
    }
}

/// Slot-machine digits: each digit column spins to its value, right to left. Non-digits stay put.
/// `p` runs 0…1 over the roll. Returns the drawn width.
@discardableResult
func rollNumber(_ final: String, p: Double, x: CGFloat, y: CGFloat, size: CGFloat, face: Face, colour: Col,
                align: CGFloat = 0, spins: Int = 1, kern: CGFloat = 0) -> CGFloat {
    guard p > 0 else { return 0 }                                         // nothing until the roll starts
    textLog?.muted += 1
    defer {
        textLog?.muted -= 1
        if p >= 1 { noteText(final, size: size, rect: CGRect(x: x - textWidth(final, size, face, kern: kern) * align, y: y - size * 0.8, width: textWidth(final, size, face, kern: kern), height: size)) }
    }
    let cell = textWidth("0", size, face, kern: kern)
    let chars = Array(final)
    let widths = chars.map { $0.isNumber ? cell : textWidth(String($0), size, face, kern: kern) }
    let total = widths.reduce(0, +)
    var cx = x - total * align
    let digits = chars.filter(\.isNumber).count
    var di = 0
    for (i, ch) in chars.enumerated() {
        if let v = ch.wholeNumberValue {
            let order = digits - 1 - di                                   // rightmost settles first
            let local = outCubic(prog(p, Double(order) * 0.08, min(1, Double(order) * 0.08 + 0.7)))
            let pos = Double(v + 10 * spins) * local                       // scrolls 0 → value + full spins
            let base = Int(floor(pos)), frac = CGFloat(pos - floor(pos))
            ctx.saveGState()
            ctx.clip(to: CGRect(x: cx - 2, y: y - size * 0.95, width: cell + 4, height: size * 1.2))
            text(String(base % 10), size, face, colour, cx + cell / 2, y - frac * size * 1.1, align: 0.5, kern: kern)
            text(String((base + 1) % 10), size, face, colour, cx + cell / 2, y + (1 - frac) * size * 1.1, align: 0.5, kern: kern)
            ctx.restoreGState()
            di += 1
        } else {
            text(String(ch), size, face, colour, cx, y, kern: kern)
        }
        cx += widths[i]
    }
    return total
}

/// A ticker band of repeating text scrolling across the canvas, optionally on a slant.
func marquee(_ s: String, y: CGFloat, height: CGFloat, band: Col, ink: Col, face: Face, size: CGFloat,
             speed: CGFloat, t: Double, degrees: CGFloat = 0, separator: String = "  ✦  ") {
    let unit = s + separator
    let uw = textWidth(unit, size, face)
    guard uw > 1 else { return }
    textLog?.muted += 1                                                   // a ticker is decoration, not a line to read
    defer { textLog?.muted -= 1 }
    ctx.saveGState()
    ctx.translateBy(x: W / 2, y: y); ctx.rotate(by: degrees * .pi / 180); ctx.translateBy(x: -W / 2, y: -y)
    let r = CGRect(x: -W, y: y - height / 2, width: W * 3, height: height)
    fill(r, band)
    ctx.clip(to: r)
    var x = -W - CGFloat(fmod(Double(speed) * t, Double(uw)))
    while x < W * 2 {
        text(unit, size, face, ink, x, y + size * 0.35)
        x += uw
    }
    ctx.restoreGState()
}
