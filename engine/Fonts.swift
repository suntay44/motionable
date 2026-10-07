// motionable engine: typefaces beyond the system font, and text as glyph outlines (for per-letter motion).
import AppKit
import CoreText

/// A typeface: a PostScript name (any font that ships with macOS, or one registered from the film's
/// assets/fonts/), or the system font in a weight and design (.default = SF Pro, .rounded, .serif = New York,
/// .monospaced = SF Mono). Unknown names fall back to the system font, with one warning. `.italic` slants any of them.
struct Face: Hashable {
    var name: String? = nil
    var weight: CGFloat = NSFont.Weight.heavy.rawValue
    var design: String = "default"
    var isItalic = false

    static func named(_ n: String) -> Face { Face(name: n) }
    static func system(_ w: NSFont.Weight, _ design: NSFontDescriptor.SystemDesign = .default) -> Face {
        Face(name: nil, weight: w.rawValue, design: design.rawValue)
    }
    /// The same face in italic: the family's true italic when it has one (SF Pro, New York, Avenir Next, Georgia…),
    /// otherwise a gentle synthetic slant.
    var italic: Face { var f = self; f.isItalic = true; return f }
}

var faceCache: [String: CTFont] = [:]
var warnedFaces = Set<String>()

func ctFont(_ face: Face, _ size: CGFloat) -> CTFont {
    let key = "\(face.name ?? "sys")-\(face.weight)-\(face.design)-\(face.isItalic)-\(size)"
    if let f = faceCache[key] { return f }
    var result: CTFont
    if let n = face.name {
        let f = CTFontCreateWithName(n as CFString, size, nil)
        if (CTFontCopyPostScriptName(f) as String) == n {
            result = f
        } else {
            if !warnedFaces.contains(n) { print("motionable: font \(n) isn't installed; using the system font"); warnedFaces.insert(n) }
            result = NSFont.systemFont(ofSize: size, weight: .heavy) as CTFont
        }
    } else {
        let base = NSFont.systemFont(ofSize: size, weight: NSFont.Weight(face.weight))
        let design = NSFontDescriptor.SystemDesign(rawValue: face.design)
        if design != .default, let d = base.fontDescriptor.withDesign(design), let f = NSFont(descriptor: d, size: size) {
            result = f as CTFont
        } else {
            result = base as CTFont
        }
    }
    if face.isItalic {
        if let it = CTFontCreateCopyWithSymbolicTraits(result, size, nil, .traitItalic, .traitItalic),
           CTFontGetSymbolicTraits(it).contains(.traitItalic), CTFontGetSlantAngle(it) != 0 {
            result = it                                          // the family's real italic
        } else {
            var slant = CGAffineTransform(a: 1, b: 0, c: 0.2, d: 1, tx: 0, ty: 0)
            result = CTFontCreateCopyWithAttributes(result, size, &slant, nil)
        }
    }
    faceCache[key] = result
    return result
}

/// Registers every .ttf/.otf in the film's assets/fonts/ (a brand font the user supplied, if its licence allows).
func registerProjectFonts() {
    let dir = projectDir.appendingPathComponent("assets/fonts")
    guard let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { return }
    for f in files where ["ttf", "otf", "ttc"].contains(f.pathExtension.lowercased()) {
        CTFontManagerRegisterFontsForURL(f as CFURL, .process, nil)
    }
}

func faceLine(_ s: String, _ size: CGFloat, _ face: Face, _ c: Col, kern: CGFloat = 0) -> CTLine {
    let attrs: [NSAttributedString.Key: Any] = [
        .font: ctFont(face, size), NSAttributedString.Key(kCTForegroundColorAttributeName as String): c.cg, .kern: kern]
    return CTLineCreateWithAttributedString(NSAttributedString(string: s, attributes: attrs))
}
func textWidth(_ s: String, _ size: CGFloat, _ face: Face, kern: CGFloat = 0) -> CGFloat {
    CGFloat(CTLineGetTypographicBounds(faceLine(s, size, face, Col(0xFFFFFF), kern: kern), nil, nil, nil))
}
/// Draws one line in any face with its baseline at y; `align` 0 = left, 0.5 = centre, 1 = right. Returns the width.
@discardableResult
func text(_ s: String, _ size: CGFloat, _ face: Face, _ c: Col, _ x: CGFloat, _ y: CGFloat,
          align: CGFloat = 0, kern: CGFloat = 0) -> CGFloat {
    let l = faceLine(s, size, face, c, kern: kern)
    let width = CGFloat(CTLineGetTypographicBounds(l, nil, nil, nil))
    ctx.saveGState()
    ctx.translateBy(x: x - width * align, y: y)
    ctx.scaleBy(x: 1, y: -1)
    ctx.textPosition = .zero
    CTLineDraw(l, ctx)
    ctx.restoreGState()
    noteText(s, size: size, rect: CGRect(x: x - width * align, y: y - size * 0.8, width: width, height: size), colours: [c])
    noteDrawn(s, size: size, rect: CGRect(x: x - width * align, y: y - size * 0.8, width: width, height: size), settled: true, align: align)
    return width
}
/// Outlined text (stroke only), e.g. for outline-to-fill reveals.
func outlineText(_ s: String, _ size: CGFloat, _ face: Face, _ c: Col, _ x: CGFloat, _ y: CGFloat,
                 width lineWidth: CGFloat, align: CGFloat = 0, kern: CGFloat = 0) {
    let set = glyphs(s, size, face, kern: kern)
    let x0 = x - set.width * align
    for g in set.glyphs {
        ctx.saveGState()
        ctx.translateBy(x: x0 + g.x, y: y); ctx.scaleBy(x: 1, y: -1)
        stroke(g.path, c, lineWidth / 1)
        ctx.restoreGState()
    }
}

// MARK: - Glyphs

/// One glyph of laid-out text: its outline (font units flipped to y-up, at the given size), its x offset
/// from the line start, advance width, and which word of the line it belongs to.
struct Glyph {
    let path: CGPath
    let x: CGFloat
    let advance: CGFloat
    let word: Int
    let char: Character
    var span = -1                    // which styled span it belongs to (styledGlyphs), or -1 for plain text
}
struct GlyphLine {
    let glyphs: [Glyph]
    let width: CGFloat
    let ascent: CGFloat
    let descent: CGFloat
    let words: Int
}

var glyphCache: [String: GlyphLine] = [:]

/// Lays a line out and returns each glyph's outline, so letters and words can move on their own.
func glyphs(_ s: String, _ size: CGFloat, _ face: Face, kern: CGFloat = 0) -> GlyphLine {
    let key = "\(s)|\(size)|\(face.name ?? "sys")|\(face.weight)|\(face.design)|\(face.isItalic)|\(kern)"
    if let g = glyphCache[key] { return g }
    let line = faceLine(s, size, face, Col(0xFFFFFF), kern: kern)
    var ascent: CGFloat = 0, descent: CGFloat = 0, leading: CGFloat = 0
    let width = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, &leading))
    let chars = Array(s.utf16)
    // Word index for each UTF-16 offset (-1 for spaces).
    var wordAt = [Int](repeating: -1, count: chars.count + 1)
    var words = 0, inWord = false
    for (i, c) in chars.enumerated() {
        if c == 32 || c == 9 { inWord = false; continue }
        if !inWord { words += 1; inWord = true }
        wordAt[i] = words - 1
    }
    var out: [Glyph] = []
    let runs = CTLineGetGlyphRuns(line) as! [CTRun]
    let sArr = Array(s)
    let utf16ToChar: [Int] = {
        var map = [Int](repeating: 0, count: chars.count + 1); var ci = 0, ui = 0
        for ch in sArr { let n = String(ch).utf16.count; for k in 0..<n { if ui + k < map.count { map[ui + k] = ci } }; ui += n; ci += 1 }
        return map
    }()
    for run in runs {
        let n = CTRunGetGlyphCount(run)
        guard n > 0 else { continue }
        let attrs = CTRunGetAttributes(run) as NSDictionary
        let font = attrs[kCTFontAttributeName as String] as! CTFont
        var gl = [CGGlyph](repeating: 0, count: n), pos = [CGPoint](repeating: .zero, count: n)
        var adv = [CGSize](repeating: .zero, count: n), idx = [CFIndex](repeating: 0, count: n)
        CTRunGetGlyphs(run, CFRangeMake(0, n), &gl)
        CTRunGetPositions(run, CFRangeMake(0, n), &pos)
        CTRunGetAdvances(run, CFRangeMake(0, n), &adv)
        CTRunGetStringIndices(run, CFRangeMake(0, n), &idx)
        for k in 0..<n {
            let ui = min(Int(idx[k]), chars.count - 1)
            let wi = wordAt[ui]
            if wi < 0 { continue }                                   // a space
            let path = CTFontCreatePathForGlyph(font, gl[k], nil) ?? CGMutablePath()
            out.append(Glyph(path: path, x: pos[k].x, advance: adv[k].width, word: wi, char: sArr[min(utf16ToChar[ui], sArr.count - 1)]))
        }
    }
    // Renumber words 0…n-1 in order of appearance.
    var remap: [Int: Int] = [:]
    var renumbered: [Glyph] = []
    for g in out {
        if remap[g.word] == nil { remap[g.word] = remap.count }
        renumbered.append(Glyph(path: g.path, x: g.x, advance: g.advance, word: remap[g.word]!, char: g.char))
    }
    let result = GlyphLine(glyphs: renumbered, width: width, ascent: ascent, descent: descent, words: remap.count)
    glyphCache[key] = result
    return result
}

/// `glyphs` for a line made of styled spans: each span may change the face, size and colour (Kinetic's `accent` and
/// `styles`). Every glyph records its span, so it can be drawn in that span's colour.
func styledGlyphs(_ spans: [(text: String, style: TextStyle?)], _ size: CGFloat, _ face: Face, kern: CGFloat = 0) -> GlyphLine {
    func styleKey(_ st: TextStyle?) -> String {
        guard let st else { return "-" }
        let f = st.face ?? face
        return "\(f.name ?? "sys")-\(f.weight)-\(f.design)-\(f.isItalic)-\(st.scale)"
    }
    let key = "styled|" + spans.map { "\($0.text)#\(styleKey($0.style))" }.joined(separator: "|") + "|\(size)|\(face.name ?? "sys")|\(face.weight)|\(face.design)|\(face.isItalic)|\(kern)"
    if let g = glyphCache[key] { return g }
    let s = spans.map(\.text).joined()
    let attributed = NSMutableAttributedString()
    var spanAt: [Int] = []                                       // span index for each UTF-16 offset
    for (i, sp) in spans.enumerated() {
        let f = ctFont(sp.style?.face ?? face, size * (sp.style?.scale ?? 1))
        attributed.append(NSAttributedString(string: sp.text, attributes: [.font: f, .kern: kern]))
        spanAt += [Int](repeating: i, count: sp.text.utf16.count)
    }
    let line = CTLineCreateWithAttributedString(attributed)
    var ascent: CGFloat = 0, descent: CGFloat = 0, leading: CGFloat = 0
    let width = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, &leading))
    let chars = Array(s.utf16), sArr = Array(s)
    var wordAt = [Int](repeating: -1, count: chars.count + 1)
    var words = 0, inWord = false
    for (i, c) in chars.enumerated() {
        if c == 32 || c == 9 { inWord = false; continue }
        if !inWord { words += 1; inWord = true }
        wordAt[i] = words - 1
    }
    var utf16ToChar = [Int](repeating: 0, count: chars.count + 1)
    do { var ci = 0, ui = 0; for ch in sArr { let n = String(ch).utf16.count; for k in 0..<n where ui + k < utf16ToChar.count { utf16ToChar[ui + k] = ci }; ui += n; ci += 1 } }
    var out: [Glyph] = []
    for run in CTLineGetGlyphRuns(line) as! [CTRun] {
        let n = CTRunGetGlyphCount(run)
        guard n > 0 else { continue }
        let font = (CTRunGetAttributes(run) as NSDictionary)[kCTFontAttributeName as String] as! CTFont
        var gl = [CGGlyph](repeating: 0, count: n), pos = [CGPoint](repeating: .zero, count: n)
        var adv = [CGSize](repeating: .zero, count: n), idx = [CFIndex](repeating: 0, count: n)
        CTRunGetGlyphs(run, CFRangeMake(0, n), &gl); CTRunGetPositions(run, CFRangeMake(0, n), &pos)
        CTRunGetAdvances(run, CFRangeMake(0, n), &adv); CTRunGetStringIndices(run, CFRangeMake(0, n), &idx)
        for k in 0..<n {
            let ui = min(Int(idx[k]), chars.count - 1)
            guard wordAt[ui] >= 0 else { continue }               // a space
            let path = CTFontCreatePathForGlyph(font, gl[k], nil) ?? CGMutablePath()
            out.append(Glyph(path: path, x: pos[k].x, advance: adv[k].width, word: wordAt[ui],
                             char: sArr[min(utf16ToChar[ui], sArr.count - 1)], span: spanAt[min(ui, spanAt.count - 1)]))
        }
    }
    var remap: [Int: Int] = [:]
    let renumbered = out.map { g -> Glyph in
        if remap[g.word] == nil { remap[g.word] = remap.count }
        return Glyph(path: g.path, x: g.x, advance: g.advance, word: remap[g.word]!, char: g.char, span: g.span)
    }
    let result = GlyphLine(glyphs: renumbered, width: width, ascent: ascent, descent: descent, words: remap.count)
    glyphCache[key] = result
    return result
}

/// Draws one glyph at (x, baseline) with an optional scale and rotation about its own centre.
func drawGlyph(_ g: Glyph, _ x: CGFloat, _ baseline: CGFloat, _ c: Col, scale: CGFloat = 1, rotate: CGFloat = 0,
               dy: CGFloat = 0, alpha: CGFloat = 1) {
    guard scale > 0.001, alpha > 0.001 else { return }
    let b = g.path.boundingBox
    let cx = x + b.midX, cy = baseline - b.midY
    ctx.saveGState()
    ctx.setAlpha(alpha)
    ctx.translateBy(x: cx, y: cy + dy)
    ctx.rotate(by: rotate)
    ctx.scaleBy(x: scale, y: scale)
    ctx.translateBy(x: -cx, y: -cy)
    ctx.translateBy(x: x, y: baseline)
    ctx.scaleBy(x: 1, y: -1)
    fill(g.path, c)
    ctx.restoreGState()
}
