// motionable test: every element, type entrance, look and join, drawn once, so `scripts/test.sh` can show them on one sheet.
// Not a film: a page per second (0.5 s into each), nothing animates between pages.
import AppKit

func makeFilm() -> Film {
    Film(name: "gallery", width: 1080, height: 1920, fps: 30, duration: 9, bpm: 120, holdFrom: 9, draw: frame, score: { _ in })
}
let paper = Col(0xF4F1EA), ink = Col(0x1D1D1F), red = Col(0xD8342C), blue = Col(0x2F6FEB), green = Col(0x1E9E4A)
let head = Face.system(.heavy), mono = Face.named("Menlo-Bold")

func label(_ s: String, _ x: CGFloat, _ y: CGFloat) { unlogged { text(s, 26, Face.system(.semibold), Col(0x6E6E73), x, y) } }

/// Page 1: stickers, tags, chat, notices, hand-drawn marks, sparkles.
func elementsA(_ t: Double) {
    fill(fullCanvas(), paper)
    let shapes: [(StickerShape, String)] = [(.pill, "pill"), (.burst(points: 12), "burst"), (.tag, "tag"), (.circle, "circle"), (.ribbon, "ribbon"), (.speech, "speech")]
    for (i, s) in shapes.enumerated() {
        let c = CGPoint(x: 190 + CGFloat(i % 3) * 350, y: 160 + CGFloat(i / 3) * 230)
        sticker("NEW", at: c, shape: s.0, fill: red, ink: Col(0xFFFFFF), size: 44, p: 1)
        label(s.1, c.x - 40, c.y + 100)
    }
    priceTag("$9.99", at: CGPoint(x: 200, y: 640), p: 0.6, fill: blue, ink: Col(0xFFFFFF))
    chatBubble("Mine", at: CGPoint(x: 800, y: 600), mine: true, p: 1, fill: green, ink: Col(0xFFFFFF))
    chatBubble("Theirs", at: CGPoint(x: 640, y: 720), mine: false, p: 1, fill: Col(0xE5E5EA), ink: ink)
    notice(title: "App", message: "A notification", icon: nil, t: 0.6, from: 0, to: 2, top: 820)
    let box = CGRect(x: 120, y: 1100, width: 360, height: 90)
    unlogged { text("circled", 60, head, ink, box.minX + 20, box.maxY - 20) }
    scribbleCircle(around: box, p: 1, colour: red)
    handArrow(from: CGPoint(x: 560, y: 1250), to: CGPoint(x: 900, y: 1120), p: 1, colour: blue)
    for (i, st) in [UnderlineStyle.straight, .wave, .scribble].enumerated() {
        underlineStroke(CGRect(x: 120 + CGFloat(i) * 320, y: 1400, width: 260, height: 12), p: 1, colour: red, style: st)
    }
    sparkle(at: CGPoint(x: 200, y: 1600), size: 60, p: 0.5, colour: Col(0xF5A623))
    sparkles(around: CGRect(x: 400, y: 1520, width: 500, height: 200), t: 0.9, from: 0.3, count: 8, colour: red)
    tapRipple(at: CGPoint(x: 540, y: 1800), at: 0.3, t: 0.55, colour: blue)
    pointer(at: CGPoint(x: 820, y: 1800), pressed: 0.5)
}

/// Page 2: meters, receipt, counters, marquee, chips and every icon.
func elementsB(_ t: Double) {
    fill(fullCanvas(), paper)
    progressRing(centre: CGPoint(x: 180, y: 200), radius: 90, width: 22, progress: 0.7, track: Col(0xDDDDDD), fill: green)
    progressBar(CGRect(x: 340, y: 180, width: 640, height: 40), progress: 0.45, track: Col(0xDDDDDD), fill: blue)
    receipt([("Coffee", "$3.10"), ("Bagel", "$2.40")], total: ("Total", "$5.50"), in: CGRect(x: 80, y: 340, width: 440, height: 420), p: 1, title: "RECEIPT")
    _ = rollNumber("$124.00", p: 1, x: 580, y: 420, size: 90, face: head, colour: ink)
    marquee("MARQUEE", y: 560, height: 110, band: ink, ink: paper, face: head, size: 60, speed: 300, t: 0.5, degrees: -4)
    iconChip(.offline, "Works offline", at: CGPoint(x: 780, y: 760), p: 1, fill: Col(0xFFFFFF), ink: ink, disc: red, discInk: Col(0xFFFFFF), face: head, size: 40)
    for (i, ic) in Icon.allCases.enumerated() {
        let c = CGPoint(x: 110 + CGFloat(i % 8) * 123, y: 950 + CGFloat(i / 8) * 150)
        icon(ic, at: c, size: 64, colour: ink, weight: 2.2)
        label(ic.rawValue, c.x - 45, c.y + 64)
    }
    confetti(from: CGPoint(x: 540, y: 1900), at: 0, t: 0.6, colours: [red, blue, green], count: 60)
}

/// Page 3: backgrounds and overlays, in strips.
func backgrounds(_ t: Double) {
    let strips: [(String, () -> Void)] = [
        ("stripes", { stripes(width: 40, a: red, b: Col(0xF06A62)) }),
        ("dotGrid", { fill(fullCanvas(), ink); dotGrid(spacing: 40, radius: 4, colour: Col(0xFFFFFF, 0.4)) }),
        ("gridLines", { fill(fullCanvas(), paper); gridLines(spacing: 60, colour: Col(0x000000, 0.2)) }),
        ("blobs", { fill(fullCanvas(), paper); blobs(count: 4, colours: [blue, green], t: 0, seed: 2, alpha: 0.5) }),
        ("gradient + glow", { gradientFill([blue, ink], degrees: 90); radialGlow(at: CGPoint(x: 540, y: 960), radius: 500, colour: Col(0xFFFFFF, 0.4)) }),
        ("vignette, scanlines", { fill(fullCanvas(), Col(0x8899AA)); vignette(0.6); scanlines(alpha: 0.2) }),
        ("lightLeak, letterbox", { fill(fullCanvas(), Col(0x334455)); lightLeak(t: 0.5, strength: 0.8); letterbox(0.6) }),
    ]
    for (i, s) in strips.enumerated() {
        let r = CGRect(x: 0, y: CGFloat(i) * H / CGFloat(strips.count), width: W, height: H / CGFloat(strips.count))
        let img = layer(s.1)
        ctx.saveGState(); ctx.clip(to: r); drawImage(img, in: CGRect(x: 0, y: 0, width: W, height: H)); ctx.restoreGState()
        unlogged { text(s.0, 34, Face.system(.bold), Col(0xFFFFFF), 30, r.minY + 50) }
    }
}

/// Page 4: every text entrance, caught at the end of its entrance.
func typePage(_ t: Double) {
    fill(fullCanvas(), paper)
    let styles: [(String, TextIn)] = [("rise", .rise), ("fade", .fade), ("pop", .pop), ("cascade", .cascade), ("typewriter", .typewriter(cps: 30)),
                                       ("slam", .slam), ("slide", .slide(.left)), ("stamp", .stamp), ("scramble", .scramble), ("split", .split),
                                       ("wave", .wave), ("highlight", .highlight(Col(0xFFD84D))), ("outlineFill", .outlineFill)]
    for (i, s) in styles.enumerated() {
        Kinetic(lines: ["Entrance: \(s.0)"], face: head, size: 64, colour: ink, x: 60, y: 120 + CGFloat(i) * 136, from: 3 - 1.0, enter: s.1, exit: .none).draw(t)
    }
    outlineText("outline", 90, head, red, 640, 1860, width: 3)
}

/// Page 5: looks applied to one card.
func looksPage(_ t: Double) {
    fill(fullCanvas(), ink)
    let card = layer {
        fill(fullCanvas(), paper)
        fill(rr(CGRect(x: 240, y: 560, width: 600, height: 800), 60), red)
        unlogged { text("LOOK", 200, head, Col(0xFFFFFF), 540, 1050, align: 0.5) }
    }
    let looks: [(String, CGImage)] = [("plain", card), ("bloomed", bloomed(card)), ("saturated", saturated(card, 0.2)),
                                      ("gaussianBlurred", gaussianBlurred(card, sigma: 12)), ("halftoned", halftoned(card)),
                                      ("pixellated", pixellated(card, scale: 30)), ("channelSplit", channelSplit(card, dx: 14)),
                                      ("motionBlurred", motionBlurred(card, radius: 40)), ("zoomBlurred", zoomBlurred(card, centre: CGPoint(x: 540, y: 960), amount: 40))]
    for (i, l) in looks.enumerated() {
        let r = CGRect(x: 30 + CGFloat(i % 3) * 350, y: 40 + CGFloat(i / 3) * 620, width: 320, height: 568)
        drawImage(l.1, in: r)
        unlogged { text(l.0, 28, Face.system(.bold), Col(0xFFFFFF), r.minX, r.maxY + 34) }
    }
}

/// Page 6: every join at its midpoint, between card A and card B.
func joinsPage(_ t: Double) {
    fill(fullCanvas(), ink)
    let joins: [(String, Join)] = [("cut", .cut), ("dissolve", .dissolve), ("dip", .dip(paper)), ("push", .push(.left)), ("cover", .cover(.up)),
                                   ("uncover", .uncover(.down)), ("whip", .whip(.left)), ("zoomThrough", .zoomThrough(CGPoint(x: 540, y: 960))),
                                   ("iris", .iris(CGPoint(x: 540, y: 960))), ("star", .shape(.star(points: 5), CGPoint(x: 540, y: 960))),
                                   ("heart", .shape(.heart, CGPoint(x: 540, y: 960))), ("blob", .shape(.blob(seed: 2), CGPoint(x: 540, y: 960))),
                                   ("blinds", .blinds(6, vertical: false)), ("slice", .slice(degrees: -18)), ("glitch", .glitch), ("flash", .flash(Col(0xFFFFFF))),
                                   ("spin", .spin(clockwise: true)), ("pixelate", .pixelate), ("burn", .burn(Col(0xFF9A3C))), ("columns", .columns(6))]
    func card(_ c: Col, _ s: String) { fill(fullCanvas(), c); unlogged { text(s, 400, head, Col(0xFFFFFF), 540, 1100, align: 0.5) } }
    for (i, j) in joins.enumerated() {
        let img = layer { composite(j.1, p: 0.5, a: { card(red, "A") }, b: { card(blue, "B") }, t: 0.5) }
        let r = CGRect(x: 20 + CGFloat(i % 5) * 212, y: 20 + CGFloat(i / 5) * 470, width: 200, height: 356)
        drawImage(img, in: r)
        unlogged { text(j.0, 26, Face.system(.bold), Col(0xFFFFFF), r.minX, r.maxY + 32) }
    }
}

/// Page 7: mixed type: faces, weights, italics, sizes, colours, a highlighter and an underline inside one line.
func typeMixPage(_ t: Double) {
    fill(fullCanvas(), paper)
    let rows: [Kinetic] = [
        Kinetic(lines: ["Cooking for *40?*"], face: head, size: 104, colour: ink, x: 60, y: 160, from: 0, enter: .none, exit: .none,
                accent: TextStyle(colour: red, scale: 1.25)),
        Kinetic(lines: ["Make a list for *your son.*"], face: .system(.bold, .serif), size: 76, colour: ink, x: 60, y: 330, from: 0,
                enter: .none, exit: .none, maxWidth: nil, accent: TextStyle(face: Face.system(.regular, .serif).italic, colour: green)),
        Kinetic(lines: ["One answer *each morning.*"], face: .system(.heavy, .rounded), size: 74, colour: Col(0xFFFFFF), x: 60, y: 500, from: 0,
                enter: .none, exit: .none, maxWidth: nil, accent: TextStyle(colour: Col(0xFFE9A8))),
        Kinetic(lines: ["{m:Scale} any recipe."], face: .named("AvenirNext-Heavy"), size: 84, colour: ink, x: 60, y: 680, from: 0,
                enter: .none, exit: .none, styles: ["m": TextStyle(mark: Col(0xFFD84D))]),
        Kinetic(lines: ["Know what each plate {u:costs.}"], face: .named("AvenirNext-Heavy"), size: 70, colour: ink, x: 60, y: 840, from: 0,
                enter: .none, exit: .none, maxWidth: nil, styles: ["u": TextStyle(colour: red, underline: red)]),
        Kinetic(lines: ["*Fast.* Friendly. {thin:Free.}"], face: .system(.medium), size: 80, colour: ink, x: 60, y: 1010, from: 0,
                enter: .none, exit: .none, maxWidth: nil, accent: TextStyle(face: .system(.black)), styles: ["thin": TextStyle(face: .system(.ultraLight), colour: blue)]),
        Kinetic(lines: ["Rounded, *slanted*"], face: .system(.heavy, .rounded), size: 84, colour: ink, x: 60, y: 1180, from: 0,
                enter: .none, exit: .none, accent: TextStyle(face: Face.system(.heavy, .rounded).italic, colour: green)),
        Kinetic(lines: ["The *real* thing."], face: .named("Futura-Bold"), size: 96, colour: ink, x: 60, y: 1350, from: 0,
                enter: .none, exit: .none, accent: TextStyle(face: Face.named("Didot").italic, colour: red, scale: 1.2)),
        Kinetic(lines: ["Words pop in", "*one by one*"], face: head, size: 80, colour: ink, x: 60, y: 1560, from: 6.0, enter: .pop, exit: .none,
                stagger: 0.08, accent: TextStyle(colour: blue)),
    ]
    let dark = CGRect(x: 30, y: 420, width: 1020, height: 120)
    fill(rr(dark, 24), Col(0x1D2C74))                         // row 3 sits on night blue, as in Bonnie
    for k in rows { k.draw(t) }
}

/// Page 8: every `show` entrance, caught halfway in.
func motionsPage(_ t: Double) {
    fill(fullCanvas(), ink)
    let motions: [(String, Appear)] = [("cut", .cut), ("fade", .fade), ("pop", .pop), ("zoom", .zoom), ("rise", .rise), ("drop", .drop),
                                       ("slide left", .slide(.left)), ("fly right", .fly(.right)), ("wipe left", .wipe(.left)), ("iris", .iris),
                                       ("blur", .blur), ("flip", .flip), ("spin", .spin)]
    for (i, m) in motions.enumerated() {
        let cell = CGRect(x: 40 + CGFloat(i % 3) * 340, y: 40 + CGFloat(i / 3) * 370, width: 320, height: 300)
        unlogged { text(m.0, 28, Face.system(.bold), Col(0xFFFFFF, 0.6), cell.minX, cell.maxY + 36) }
        stroke(rr(cell, 30), Col(0xFFFFFF, 0.15), 2)
        let card = cell.insetBy(dx: 50, dy: 50)
        show(card, t: t, from: 7.5 - 0.225, enter: m.1) {      // halfway through a 0.45 s entrance at 7.5 s
            fill(rr(card, 24), red)
            icon(.star, at: CGPoint(x: card.midX, y: card.midY), size: 90, colour: Col(0xFFFFFF), weight: 2.6)
        }
    }
}

/// Page 9: UI acting: typing into a field, a finger moving and tapping, and each state change caught halfway.
func actingPage(_ t: Double) {
    fill(fullCanvas(), paper)
    let field = CGRect(x: 80, y: 120, width: 920, height: 120)
    fill(rr(field, 24), Col(0xFFFFFF)); stroke(rr(field, 24), Col(0x000000, 0.1), 2)
    typeIn("Pack gym clothes", t: t, from: 8.0, cps: 14, at: CGPoint(x: 120, y: 198), size: 52, colour: ink)
    let finger = TouchPath([(8.0, CGPoint(x: 200, y: 420)), (8.3, CGPoint(x: 540, y: 380)), (8.5, CGPoint(x: 820, y: 420))], taps: [8.5])
    finger.draw(t); finger.draw(t + 0.02, colour: blue, size: 50)              // a second one just behind, to show the path
    TouchPath([(8.0, CGPoint(x: 300, y: 560)), (8.5, CGPoint(x: 700, y: 560))], taps: [8.5], style: .arrow).draw(t)
    let styles: [(String, StateChange)] = [("crossfade", .crossfade), ("push", .push(.right)), ("reveal", .reveal(CGPoint(x: 130, y: 1120)))]
    for (i, st) in styles.enumerated() {
        let r = CGRect(x: 60 + CGFloat(i) * 330, y: 760, width: 300, height: 620)
        changeState(t: t, at: 8.5 - 0.175, length: 0.35, style: st.1, in: CGRect(x: r.minX, y: r.minY, width: r.width, height: r.height), radius: 30,
                    before: { fill(rr(r, 30), red); unlogged { text("A", 160, head, Col(0xFFFFFF), r.midX, r.midY + 60, align: 0.5) } },
                    after: { fill(rr(r, 30), blue); unlogged { text("B", 160, head, Col(0xFFFFFF), r.midX, r.midY + 60, align: 0.5) } })
        unlogged { text(st.0, 30, Face.system(.bold), ink, r.minX, r.maxY + 44) }
    }
}

func frame(_ t: Double) {
    switch Int(t) {
    case 0: elementsA(t)
    case 1: elementsB(t)
    case 2: backgrounds(t)
    case 3: typePage(t)
    case 4: looksPage(t)
    case 5: joinsPage(t)
    case 6: typeMixPage(t)
    case 7: motionsPage(t)
    default: actingPage(t)
    }
}
