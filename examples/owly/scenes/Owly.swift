// Owly the Scribe — the 30-second hype film that motionable grew out of.
// Concept: one card, never cut. The period of "Son did it." grows into Mom's list, which becomes
// the widget, three circles, the load bar, a Decide card and finally the app icon.
// Beat grid: ../SCRIPT.md · look: ../STYLE.md · every time lives in `T`, so picture and sound move together.
import AppKit

func makeFilm() -> Film {
    Film(name: badgeGrows ? "owly-hype-badge-grows" : "owly-hype", width: 1080, height: 1920, fps: 60,
         duration: 30, bpm: 120, holdFrom: T.still, draw: owlyFrame, score: owlyScore)
}

// MARK: - Timeline (seconds; 120 BPM, so a beat is 0.5)

enum T {
    static let stampsA = [0.0, 0.25, 0.5]          // Mom / wrote / it.
    static let stampsB = [1.0, 1.25, 1.5]          // Son / did / it.
    static let dotPulse = 1.75
    static let card = 2.0                          // the period grows into Mom's list
    static let typeFrom = 2.5, typeTo = 3.5
    static let chip = 3.6
    static let rows = [3.75, 4.25, 4.75, 5.25, 5.5]
    static let toWidget = 6.0
    static let tapPack = 8.5                       // tick lands 0.1 later
    static let banner1 = 8.9
    static let offline = 10.0
    static let tapDog = 11.0
    static let online = 12.0
    static let banner2 = 12.5
    static let toCircle = 14.0
    static let circles = [14.5, 14.75, 15.0]
    static let merge = 15.75
    static let toBar = 16.0
    static let chips = [16.5, 17.0, 17.5, 18.0, 18.5]   // the last one goes over
    static let toCard = 20.0
    static let pressA = 21.0, flingA = 21.25, enterB = 21.5
    static let pressB = 22.75, flingB = 23.0, enterC = 23.25
    static let toThemes = 24.0
    static let themeCuts = [24.5, 25.0, 25.5, 26.0]
    static let toIcon = 26.25, thump = 26.5
    static let endLines = [26.75, 26.9, 27.05]
    static let badge = 27.25                       // the App Store badge cuts in (never animated)
    static let google = 27.75, googleSettle = 28.5 // "Soon on Google Play": blur, land big, settle under
    static let still = 28.9
}

// MARK: - Palette

let green = Col(0x0F9B3E), greenDeep = Col(0x0B7A31), paper = Col(0xF6F3E8), ink = Col(0x10241A)
let white = Col(0xFFFFFF), night = Col(0x0B1020), night2 = Col(0x1A2340), over = Col(0xD93B47)
let amber = Col(0xE08A16), grey = Col(0x8E8E93), ring = Col(0xC7C7CC), hair = Col(0xE5E5EA)
let leo = Col(0x2F6FE0), gran = Col(0xD98014), track = Col(0xE4E0D4)
let themes: [(name: String, col: Col)] = [("Owly", Col(0x0F9B3E)), ("Ember", Col(0xE0601F)),
                                          ("Ink", Col(0x3D4ECC)), ("Plum", Col(0x9B3A8F))]
let logo = loadImage("assets/owly-logo.png")

// MARK: - Layout

let cardR = CGRect(x: 72, y: 600, width: 900, height: 900)
let widgetR = CGRect(x: 72, y: 720, width: 900, height: 480)
let circleC = CGPoint(x: 540, y: 960)
let circleR = centred(circleC, 210)
let smallCircleR = centred(circleC, 120)
let barR = CGRect(x: 72, y: 1000, width: 900, height: 56)
let decR = CGRect(x: 120, y: 660, width: 840, height: 840)
let iconR = CGRect(x: 360, y: 500, width: 360, height: 360)

// Hook geometry: three stacked words, the period of "it." is the dot that becomes everything.
let hookSize: CGFloat = 240
let hookX: CGFloat = 72
let hookBaselines: [CGFloat] = [620, 860, 1100]
let itWidth = textWidth("it", hookSize, .heavy, kern: -4)
let periodWidth = textWidth(".", hookSize, .heavy)
let dotR: CGFloat = hookSize * 0.072
let dotC = CGPoint(x: hookX + itWidth + periodWidth * 0.5, y: hookBaselines[2] - dotR)

// MARK: - The one container

/// The shape that carries the film from scene to scene: where it is, its corner radius and fill.
func box(_ t: Double) -> (CGRect, CGFloat, Col)? {
    switch t {
    case ..<T.card: return nil
    case ..<2.45:
        let e = inOut(prog(t, T.card, 2.45))
        return (lerp(centred(dotC, dotR), cardR, e), lerp(dotR, 56, e), mix(green, white, prog(t, 2.05, 2.3)))
    case ..<T.toWidget: return (cardR, 56, white)
    case ..<6.45:
        let e = inOut(prog(t, T.toWidget, 6.45))
        return (lerp(cardR, widgetR, e), lerp(56, 64, e), white)
    case ..<T.toCircle: return (widgetR, 64, white)
    case ..<14.4:
        let e = inOut(prog(t, T.toCircle, 14.4))
        return (lerp(widgetR, circleR, e), lerp(64, 210, e), mix(white, green, prog(t, 14.05, 14.3)))
    case ..<T.toBar: return nil                     // the circles scene draws itself
    case ..<16.3:
        let e = inOut(prog(t, T.toBar, 16.3))
        return (lerp(smallCircleR, barR, e), lerp(120, 28, e), mix(green, track, prog(t, 16.05, 16.3)))
    case ..<T.toCard:
        return (barR, 28, t < T.chips[4] ? track : white.alpha(0.28))
    case ..<20.4:
        let e = inOut(prog(t, T.toCard, 20.4))
        return (lerp(barR, decR, e), lerp(28, 56, e), mix(white.alpha(0.28), white, prog(t, T.toCard, 20.15)))
    case ..<T.toThemes: return nil                  // the Decide cards draw themselves
    case ..<24.3:
        let e = inOut(prog(t, T.toThemes, 24.3))
        return (lerp(decR, widgetR, e), lerp(56, 64, e), white)
    case ..<T.toIcon: return (widgetR, 64, white)
    case ..<26.6:
        let e = inOut(prog(t, T.toIcon, 26.6))
        return (lerp(widgetR, iconR, e), lerp(64, 80, e), mix(white, green, prog(t, 26.3, 26.5)))
    default: return (iconR, 80, green)
    }
}

func drawBox(_ t: Double) {
    guard let (r, rad, c) = box(t) else { return }
    var rect = r
    if t >= T.thump {                                   // the icon lands with a little bounce
        let s = 1 + 0.07 * sin(Double.pi * prog(t, T.thump, 26.8))
        rect = centred(CGPoint(x: r.midX, y: r.midY), r.width / 2 * CGFloat(s))
    }
    let path = rr(rect, rad * rect.width / max(r.width, 1))
    if rect.width > 60 && c.a > 0.9 { fillShadowed(path, c, alpha: t >= T.toIcon ? 0.28 : 0.18) } else { fill(path, c) }

    // What's inside it.
    ctx.saveGState()
    ctx.addPath(path); ctx.clip()
    let momA = prog(t, 2.3, 2.5) * (1 - prog(t, T.toWidget, 6.15))
    if momA > 0 { momList(r, t, CGFloat(momA)) }
    let widA = prog(t, 6.3, 6.5) * (1 - prog(t, T.toCircle, 14.12))
    if widA > 0 && t < 14.4 { widget(r, t, CGFloat(widA), accent: green) }
    if t >= 20.25 && t < 20.4 { decideCard(r, cards[0], t, alpha: CGFloat(prog(t, 20.25, 20.4))) }
    if t >= T.toThemes && t < 24.15 { decideCard(r, cards[2], t, alpha: CGFloat(1 - prog(t, T.toThemes, 24.1))) }
    let themeA = prog(t, 24.2, 24.35) * (1 - prog(t, T.toIcon, 26.35))
    if themeA > 0 { widget(r, t, CGFloat(themeA), accent: themeAt(t).col) }
    if t >= 26.4 {
        ctx.setAlpha(CGFloat(prog(t, 26.4, 26.55)))
        drawImage(logo, in: rect.insetBy(dx: -rect.width * 0.035, dy: -rect.width * 0.035))
    }
    ctx.restoreGState()
}

// MARK: - Mom's list (her iPhone)

let momRows: [(title: String, sub: String?, at: Double)] = [
    ("Practice piano", "4 pm", T.rows[0]), ("Feed the dog", nil, T.rows[1]),
    ("Put the bins out", "7 pm", T.rows[2]), ("Pack gym clothes", nil, T.rows[3]),
    ("Math homework", nil, T.rows[4])]

func momList(_ r: CGRect, _ t: Double, _ a: CGFloat) {
    ctx.saveGState(); ctx.setAlpha(a)
    let x0 = r.minX, y0 = r.minY, w = r.width
    text("MOM'S IPHONE", 26, .bold, grey, x0 + 56, y0 + 78, kern: 2.5)
    text("Todo list for my son", 50, .bold, ink, x0 + 56, y0 + 146, kern: -0.5)

    let seg = CGRect(x: x0 + 56, y: y0 + 184, width: w - 112, height: 64)
    fill(rr(seg, 32), Col(0xEEEEF0))
    let third = seg.width / 3
    fillShadowed(rr(CGRect(x: seg.minX + 5, y: seg.minY + 5, width: third - 10, height: 54), 27), white,
                 blur: 8, alpha: 0.10, dy: 2)
    for (i, s) in ["Today", "Routine", "Later"].enumerated() {
        text(s, 28, i == 0 ? .semibold : .regular, ink, seg.minX + third * (CGFloat(i) + 0.5), seg.minY + 42, align: 0.5)
    }

    // The add field: "Practice piano 4pm" is typed, a 4 pm chip pops, then it drops into the list.
    let field = CGRect(x: x0 + 56, y: y0 + 276, width: w - 112, height: 96)
    fill(rr(field, 24), Col(0xF2F2F5))
    let full = "Practice piano 4pm"
    let typed = t < T.rows[0] ? Int(Double(full.count) * prog(t, T.typeFrom, T.typeTo)) : 0
    let caretOn = t.truncatingRemainder(dividingBy: 0.5) < 0.3 || (t > T.typeFrom && t < T.typeTo)
    var caretX = field.minX + 32
    if typed > 0 {
        caretX += text(String(full.prefix(typed)), 38, .regular, ink, field.minX + 32, field.minY + 60) + 3
    } else {
        text("Add a task", 38, .regular, grey.alpha(0.7), field.minX + 32, field.minY + 60)
    }
    if caretOn && t < T.rows[0] { fill(CGRect(x: caretX, y: field.minY + 26, width: 3.5, height: 46), green) }
    if t >= T.chip && t < T.rows[0] {
        let s = CGFloat(outBack(prog(t, T.chip, T.chip + 0.22)))
        let c = CGPoint(x: field.maxX - 24 - 64, y: field.midY)
        ctx.saveGState()
        ctx.translateBy(x: c.x, y: c.y); ctx.scaleBy(x: s, y: s); ctx.translateBy(x: -c.x, y: -c.y)
        fill(rr(CGRect(x: c.x - 64, y: c.y - 27, width: 128, height: 54), 27), green.alpha(0.14))
        text("4 pm", 30, .semibold, green, c.x, c.y + 11, align: 0.5)
        ctx.restoreGState()
    }

    for (i, row) in momRows.enumerated() where t >= row.at {
        let e = outCubic(prog(t, row.at, row.at + 0.28))
        let slot = y0 + 440 + CGFloat(i) * 94
        let y = i == 0 ? lerp(field.midY, slot, e) : slot + (1 - CGFloat(e)) * 34
        ctx.saveGState(); ctx.setAlpha(a * CGFloat(i == 0 ? 1 : e))
        let cx = x0 + 86
        let done = i == 4
        if done {
            fill(CGPath(ellipseIn: centred(CGPoint(x: cx, y: y), 24), transform: nil), leo)
            text("L", 26, .bold, white, cx, y + 9.5, align: 0.5)
        } else {
            stroke(CGPath(ellipseIn: centred(CGPoint(x: cx, y: y), 23), transform: nil), ring, 3.5)
        }
        let ty = row.sub == nil ? y + 13 : y - 2
        let tw = text(row.title, 40, .regular, done ? grey : ink, x0 + 132, ty)
        if done { line(CGPoint(x: x0 + 132, y: ty - 13), CGPoint(x: x0 + 132 + tw, y: ty - 13), grey, 3) }
        if let sub = row.sub { text(sub, 28, .regular, grey, x0 + 132, y + 36) }
        if i < 4 { fill(CGRect(x: x0 + 132, y: y + 47, width: w - 172, height: 1.5), hair) }
        ctx.restoreGState()
    }
    ctx.restoreGState()
}

// MARK: - The "Tasks from Mom" widget

let widgetRows = ["Practice piano", "Feed the dog", "Put the bins out", "Pack gym clothes", "Math homework"]
let tickAt: [Double?] = [nil, T.tapDog + 0.1, nil, T.tapPack + 0.1, -10]
func widgetRowCentre(_ r: CGRect, _ i: Int) -> CGPoint {
    let k = r.width / 900
    return CGPoint(x: r.minX + 70 * k, y: r.minY + (190 + CGFloat(i) * 60) * k)
}

func widget(_ r: CGRect, _ t: Double, _ a: CGFloat, accent: Col) {
    ctx.saveGState(); ctx.setAlpha(a)
    let k = r.width / 900
    let done = tickAt.compactMap { $0 }.filter { t >= $0 + 0.12 }.count
    let fraction = tickAt.compactMap { $0 }.map { outCubic(prog(t, $0 + 0.05, $0 + 0.4)) }.reduce(0, +) / 5
    text("Tasks from Mom", 44 * k, .bold, ink, r.minX + 48 * k, r.minY + 84 * k, kern: -0.5)
    text("\(done)/5", 38 * k, .medium, grey, r.maxX - 48 * k, r.minY + 84 * k, align: 1)
    let trackR = CGRect(x: r.minX + 48 * k, y: r.minY + 108 * k, width: r.width - 96 * k, height: 12 * k)
    fill(rr(trackR, 6 * k), hair)
    fill(rr(CGRect(x: trackR.minX, y: trackR.minY, width: trackR.width * CGFloat(fraction), height: trackR.height), 6 * k), accent)

    for (i, title) in widgetRows.enumerated() {
        let c = widgetRowCentre(r, i)
        let tp = tickAt[i].map { prog(t, $0, $0 + 0.22) } ?? 0
        let ink2 = mix(ink, grey, tp)
        if tp > 0 {
            let s = CGFloat(outBack(tp, 2.2))
            fill(CGPath(ellipseIn: centred(c, 21 * k * s), transform: nil), accent)
            let pts = [CGPoint(x: c.x - 9 * k, y: c.y + 0.5 * k), CGPoint(x: c.x - 3 * k, y: c.y + 7 * k),
                       CGPoint(x: c.x + 10 * k, y: c.y - 7.5 * k)]
            stroke(partial(pts, prog(t, tickAt[i]! + 0.06, tickAt[i]! + 0.22)), white, 4.5 * k)
        } else {
            stroke(CGPath(ellipseIn: centred(c, 20 * k), transform: nil), ring, 3.5 * k)
        }
        let tx = r.minX + 112 * k, ty = c.y + 13 * k
        let tw = text(title, 38 * k, .regular, ink2, tx, ty)
        if let at = tickAt[i] {
            let sp = prog(t, at + 0.08, at + 0.32)
            if sp > 0 { line(CGPoint(x: tx, y: ty - 12 * k), CGPoint(x: tx + tw * CGFloat(sp), y: ty - 12 * k), grey, 3 * k) }
        }
    }
    ctx.restoreGState()
}

// MARK: - Scenes

func hook(_ t: Double) {
    guard t < 2.3 else { return }
    let wordsA = ["Mom", "wrote", "it"], wordsB = ["Son", "did", "it"]
    let b = t >= T.stampsB[0]
    let words = b ? wordsB : wordsA
    let stamps = b ? T.stampsB : T.stampsA
    let colour = b ? leo : paper
    let exit = inCubic(prog(t, T.card, 2.22))
    for i in 0..<3 where t >= stamps[i] {
        let p = outCubic(prog(t, stamps[i], stamps[i] + 0.14))
        let s = CGFloat(1 + 0.22 * (1 - p))
        let w = textWidth(words[i], hookSize, .heavy, kern: -4)
        let c = CGPoint(x: hookX + w / 2, y: hookBaselines[i] - hookSize * 0.35)
        ctx.saveGState()
        ctx.translateBy(x: c.x - CGFloat(exit) * 260, y: c.y); ctx.scaleBy(x: s, y: s); ctx.translateBy(x: -c.x, y: -c.y)
        ctx.setAlpha(CGFloat(1 - exit))
        text(words[i], hookSize, .heavy, colour, hookX, hookBaselines[i], kern: -4)
        ctx.restoreGState()
        // The period, drawn on its own because it becomes the container.
        if i == 2 && t < T.card {
            let pulse = sin(Double.pi * prog(t, T.dotPulse, T.dotPulse + 0.2))
            let dotCol = b ? mix(leo, green, prog(t, T.dotPulse, T.dotPulse + 0.12)) : paper
            let dc = CGPoint(x: c.x + (dotC.x - c.x) * s, y: c.y + (dotC.y - c.y) * s)
            fill(CGPath(ellipseIn: centred(dc, dotR * s * CGFloat(1 + 0.6 * pulse)), transform: nil), dotCol)
        }
    }
}

func homeScreen(_ t: Double) {
    guard t >= T.toWidget && t < 14.4 else { return }
    let out = 1 - prog(t, T.toCircle, 14.2)
    // Ghost app icons and the status bar, so it reads as a Home Screen.
    for j in 0..<8 {
        let a = prog(t, 6.3 + Double(j) * 0.04, 6.55 + Double(j) * 0.04) * out
        guard a > 0 else { continue }
        let col = j % 4, row = j / 4
        let r = CGRect(x: 72 + CGFloat(col) * 242, y: 1340 + CGFloat(row) * 240, width: 176, height: 176)
        fill(rr(r, 42), white.alpha(CGFloat(0.09 * a)))
    }
    ctx.saveGState(); ctx.setAlpha(CGFloat(prog(t, 6.3, 6.5) * out))
    text("9:41", 34, .semibold, white, 96, 104)
    ctx.restoreGState()

    // Taps on the widget.
    for (i, at) in [(3, T.tapPack), (1, T.tapDog)] {
        let c = widgetRowCentre(widgetR, i)
        let pre = prog(t, at - 0.18, at)
        if pre > 0 && t < at { fill(CGPath(ellipseIn: centred(c, 34 * CGFloat(pre)), transform: nil), ink.alpha(0.14)) }
        let p = prog(t, at, at + 0.4)
        if p > 0 && p < 1 {
            fill(CGPath(ellipseIn: centred(c, 26 + 56 * CGFloat(outCubic(p))), transform: nil), ink.alpha(CGFloat(0.16 * (1 - p))))
        }
    }

    // The Wi-Fi pill.
    let a = prog(t, 9.9, 10.1) * (1 - prog(t, 13.6, 13.8))
    guard a > 0 else { return }
    ctx.saveGState(); ctx.setAlpha(CGFloat(a))
    let online = t >= T.online
    let label = online ? "Back online" : "Offline"
    let tw = textWidth(label, 40, .semibold)
    let pill = CGRect(x: 72, y: 1236, width: 112 + tw + 36, height: 80)
    fill(rr(pill, 40), mix(Col(0x2C2C2E), green, prog(t, T.online, T.online + 0.15)))
    let wc = CGPoint(x: pill.minX + 56, y: pill.minY + 56)
    for rad in [CGFloat(12), 22, 32] {
        var pts: [CGPoint] = []
        for deg in stride(from: -135.0, through: -45.0, by: 5) {
            let a: Double = deg * Double.pi / 180
            pts.append(CGPoint(x: wc.x + rad * CGFloat(cos(a)), y: wc.y + rad * CGFloat(sin(a))))
        }
        stroke(partial(pts, 1), white, 5)
    }
    fill(CGPath(ellipseIn: centred(wc, 4), transform: nil), white)
    let slash = prog(t, T.offline + 0.05, T.offline + 0.25) * (1 - prog(t, T.online, T.online + 0.1))
    if slash > 0 {
        stroke(partial([CGPoint(x: wc.x - 26, y: wc.y - 40), CGPoint(x: wc.x + 24, y: wc.y + 8)], slash),
               Col(0x2C2C2E), 11)
        stroke(partial([CGPoint(x: wc.x - 26, y: wc.y - 40), CGPoint(x: wc.x + 24, y: wc.y + 8)], slash), white, 5)
    }
    text(label, 40, .semibold, white, pill.minX + 112, pill.minY + 54)
    ctx.restoreGState()
}

func circlesScene(_ t: Double) {
    guard t >= 14.4 && t < T.toBar else { return }
    let finals = [CGPoint(x: 540, y: 880), CGPoint(x: 432, y: 1066), CGPoint(x: 648, y: 1066)]
    let names = ["Mom", "Leo", "Grandma"]
    let cols = [green, leo, gran]
    let nameAt = [CGPoint(x: 540, y: 820), CGPoint(x: 380, y: 1124), CGPoint(x: 700, y: 1124)]
    let m = inCubic(prog(t, T.merge, T.toBar))
    ctx.saveGState()
    ctx.setBlendMode(.multiply)
    for i in 0..<3 {
        let at = T.circles[i]
        if i > 0 && t < at { continue }
        let e = i == 0 ? outBack(prog(t, at, at + 0.4), 1.2) : outBack(prog(t, at, at + 0.4))
        let start = i == 0 ? CGFloat(210) : 120
        var c = lerp(circleC, finals[i], e)
        var rad = lerp(start, 178, e)
        c = lerp(c, circleC, m); rad = lerp(rad, 120, m)
        fill(CGPath(ellipseIn: centred(c, rad), transform: nil), mix(cols[i], green, m).alpha(0.92))
    }
    ctx.restoreGState()
    for i in 0..<3 where t >= T.circles[i] {
        let a = prog(t, T.circles[i] + 0.12, T.circles[i] + 0.3) * (1 - prog(t, T.merge, T.merge + 0.1))
        ctx.saveGState(); ctx.setAlpha(CGFloat(a))
        text(names[i], 42, .bold, white, nameAt[i].x, nameAt[i].y, align: 0.5)
        ctx.restoreGState()
    }
}

let chips: [(title: String, mins: Int)] = [("Q3 budget review", 60), ("Prep Monday's pitch", 60),
                                           ("Call mum", 20), ("Pay the electricity bill", 20),
                                           ("Clear out the garage", 60)]
func load(_ t: Double) -> Double {
    zip(chips, T.chips).map { Double($0.mins) * outCubic(prog(t, $1, $1 + 0.16)) }.reduce(0, +)
}
func hm(_ m: Double) -> String {
    let n = Int(m.rounded()), h = n / 60, mm = n % 60
    return h == 0 ? "\(mm)m" : (mm == 0 ? "\(h)h" : "\(h)h \(mm)m")
}

func loadScene(_ t: Double) {
    guard t >= 16.3 && t < 20.1 else { return }
    let a = prog(t, 16.3, 16.45) * (1 - prog(t, T.toCard, 20.1))
    let red = t >= T.chips[4]
    let m = load(t)
    ctx.saveGState(); ctx.setAlpha(CGFloat(a))
    let state: (String, Col) = m > 180 ? ("More than fits", over) : m >= 120 ? ("Day is about full", amber) : ("Fits", green)
    let fillCol = red ? white : (m < 120 ? green : amber)
    ctx.saveGState()
    ctx.addPath(rr(barR, 28)); ctx.clip()
    fill(CGRect(x: barR.minX, y: barR.minY, width: barR.width * CGFloat(min(m / 240, 1)), height: barR.height), fillCol)
    ctx.restoreGState()
    let markX = barR.minX + barR.width * 0.75
    let fg = red ? white : ink
    line(CGPoint(x: markX, y: barR.minY - 16), CGPoint(x: markX, y: barR.maxY + 16), fg.alpha(0.6), 4)
    text("3h", 30, .semibold, fg.alpha(0.7), markX, barR.maxY + 60, align: 0.5)
    text(state.0, 44, .bold, red ? white : state.1, barR.minX, barR.minY - 40)
    text("\(hm(m)) / 3h", 40, .medium, red ? white.alpha(0.85) : grey, barR.maxX, barR.minY - 40, align: 1)
    ctx.restoreGState()

    // Task chips dropping into the bar.
    for (i, chip) in chips.enumerated() {
        let at = T.chips[i], from = at - 0.45
        guard t >= from && t < at else { continue }
        let p = inCubic(prog(t, from, at))
        let label = "\(chip.title) · \(hm(Double(chip.mins)))"
        let tw = textWidth(label, 36, .semibold)
        let s = CGFloat(1 - 0.45 * p)
        let c = CGPoint(x: 540 + (i % 2 == 0 ? -50 : 50) * CGFloat(1 - p), y: lerp(660, barR.midY, p))
        ctx.saveGState()
        ctx.translateBy(x: c.x, y: c.y); ctx.scaleBy(x: s, y: s)
        fillShadowed(rr(CGRect(x: -tw / 2 - 40, y: -44, width: tw + 80, height: 88), 44), white, blur: 30, alpha: 0.2, dy: 10)
        text(label, 36, .semibold, ink, 0, 13, align: 0.5)
        ctx.restoreGState()
    }
}

struct Card { let title: String; let pushed: Int; let tag: String; let tagCol: Col; let press: Int; let pressAt: Double }
let cards = [Card(title: "Book the car service", pushed: 5, tag: "Home", tagCol: Col(0x1C8E96), press: 2, pressAt: T.pressA),
             Card(title: "Renew passport", pushed: 3, tag: "Errands", tagCol: Col(0x8B46C9), press: 0, pressAt: T.pressB),
             Card(title: "Fix the bike light", pushed: 4, tag: "Home", tagCol: Col(0x1C8E96), press: -1, pressAt: 0)]

func decideCard(_ r: CGRect, _ card: Card, _ t: Double, alpha: CGFloat) {
    ctx.saveGState(); ctx.setAlpha(alpha)
    text("Decide", 34, .semibold, ink, r.midX, r.minY + 78, align: 0.5)
    text("Close", 30, .regular, green, r.maxX - 40, r.minY + 78, align: 1)
    text("PUSHED \(card.pushed) TIMES", 26, .bold, over, r.midX, r.minY + 300, align: 0.5, kern: 3)
    text(card.title, 56, .bold, ink, r.midX, r.minY + 374, align: 0.5, kern: -0.5)
    let tw = textWidth(card.tag, 30, .regular)
    fill(CGPath(ellipseIn: centred(CGPoint(x: r.midX - tw / 2 - 8, y: r.minY + 416), 7), transform: nil), card.tagCol)
    text(card.tag, 30, .regular, grey, r.midX + 10, r.minY + 427, align: 0.5)
    let buttons: [(String, Col, Col)] = [("Do it today", green, white), ("Already done", Col(0xEFEFF1), ink),
                                         ("Drop it", Col(0xEFEFF1), over)]
    for (i, b) in buttons.enumerated() {
        var br = CGRect(x: r.minX + 40, y: r.minY + 500 + CGFloat(i) * 104, width: r.width - 80, height: 88)
        if i == card.press {
            let bump = sin(Double.pi * prog(t, card.pressAt - 0.05, card.pressAt + 0.22))
            br = br.insetBy(dx: br.width * 0.03 * CGFloat(bump), dy: br.height * 0.05 * CGFloat(bump))
            fill(rr(br, 22), mix(b.1, Col(0x000000), 0.18 * bump))
            if bump > 0 { stroke(rr(br.insetBy(dx: -6, dy: -6), 26), b.2.alpha(CGFloat(0.5 * bump)), 3) }
        } else {
            fill(rr(br, 22), b.1)
        }
        text(b.0, 34, .semibold, b.2, br.midX, br.midY + 12, align: 0.5)
    }
    ctx.restoreGState()
}

func decideScene(_ t: Double) {
    guard t >= 20.4 && t < T.toThemes else { return }
    // (card, enters at, flings at, direction)
    let plan: [(Int, Double, Double?, CGFloat)] = [(0, 20.4, T.flingA, -1), (1, T.enterB, T.flingB, 1), (2, T.enterC, nil, 0)]
    for (i, enter, fling, dir) in plan where t >= enter {
        let f = fling.map { inCubic(prog(t, $0, $0 + 0.35)) } ?? 0
        if f >= 1 { continue }
        let e = i == 0 ? 1 : outCubic(prog(t, enter, enter + 0.3))
        ctx.saveGState()
        let c = CGPoint(x: decR.midX, y: decR.midY)
        ctx.translateBy(x: c.x + dir * 1300 * CGFloat(f), y: c.y + 90 * CGFloat(1 - e) + 120 * CGFloat(f))
        ctx.rotate(by: dir * 0.26 * CGFloat(f))
        let s = CGFloat(0.94 + 0.06 * e)
        ctx.scaleBy(x: s, y: s)
        ctx.translateBy(x: -c.x, y: -c.y)
        ctx.setAlpha(CGFloat(e))
        fillShadowed(rr(decR, 56), white)
        decideCard(decR, cards[i], t, alpha: 1)
        ctx.restoreGState()
    }
}

func themeAt(_ t: Double) -> (name: String, col: Col) {
    if t < T.themeCuts[0] { return themes[0] }
    if t < T.themeCuts[1] { return themes[1] }
    if t < T.themeCuts[2] { return themes[2] }
    if t < T.themeCuts[3] { return themes[3] }
    return themes[0]
}

func themeName(_ t: Double) {
    let a = prog(t, 24.3, 24.45) * (1 - prog(t, 26.1, 26.25))
    guard a > 0 else { return }
    ctx.saveGState(); ctx.setAlpha(CGFloat(a))
    let th = themeAt(t)
    let cut = ([T.toThemes] + T.themeCuts).last { $0 <= t } ?? T.toThemes
    let pop = CGFloat(1 + 0.12 * (1 - outCubic(prog(t, cut, cut + 0.15))))
    fill(CGPath(ellipseIn: centred(CGPoint(x: 92, y: 1290), 20 * pop), transform: nil), white)
    fill(CGPath(ellipseIn: centred(CGPoint(x: 92, y: 1290), 13 * pop), transform: nil), th.col)
    text(th.name, 48, .bold, white, 132, 1307)
    ctx.restoreGState()
}

/// Apple's official badge (Docs/HypeVideo/assets). Apple's rules: never modify, angle or animate it,
/// and keep a quarter of its height clear around it. It cuts in on the beat and holds still.
let badgeImage = loadSVG("assets/download-on-the-app-store-black-en-us.svg", height: 120)
let badgeR: CGRect = {
    let h: CGFloat = 120, w = h * CGFloat(badgeImage.width) / CGFloat(badgeImage.height)
    return CGRect(x: 540 - w / 2, y: 1200, width: w, height: h)
}()
let badgeGrows = ProcessInfo.processInfo.environment["BADGE_GROW"] == "1"
let googleSmall = (size: CGFloat(38), y: CGFloat(1418))

func endFrame(_ t: Double) {
    guard t >= T.endLines[0] else { return }
    let lines: [(String, CGFloat, NSFont.Weight, CGFloat, CGFloat)] = [
        ("Owly the Scribe", 92, .heavy, 1, 1000), ("To-do lists for the whole family.", 44, .semibold, 0.92, 1076),
        ("One purchase. No subscription.", 40, .semibold, 0.78, 1136)]
    for (i, l) in lines.enumerated() {
        let e = outCubic(prog(t, T.endLines[i], T.endLines[i] + 0.4))
        ctx.saveGState(); ctx.setAlpha(CGFloat(e))
        text(l.0, l.1, l.2, white.alpha(l.3), 540, l.4 + 40 * CGFloat(1 - e), align: 0.5, kern: i == 0 ? -1.5 : 0)
        ctx.restoreGState()
    }
    guard t >= T.badge else { return }
    // Emphasis lives in a ring of our own behind the badge, outside its clear space; the badge never moves.
    let p = prog(t, T.badge, T.badge + 0.7)
    if p < 1 {
        let grow = CGFloat(outCubic(p))
        let ring = badgeR.insetBy(dx: -(34 + 70 * grow), dy: -(34 + 70 * grow))
        if !badgeGrows { stroke(rr(ring, ring.height / 2), white.alpha(CGFloat(0.7 * (1 - p))), 5) }
    }
    // BADGE_GROW=1 renders the variant the badge swells and settles in. Apple's guidelines say not to animate
    // the badge, so the default keeps it still.
    let s = badgeGrows ? CGFloat(1 + 0.55 * sin(Double.pi * prog(t, T.badge, T.badge + 0.5))) : 1
    let c = CGPoint(x: badgeR.midX, y: badgeR.midY)
    drawImage(badgeImage, in: CGRect(x: c.x - badgeR.width * s / 2, y: c.y - badgeR.height * s / 2,
                                     width: badgeR.width * s, height: badgeR.height * s))
}

/// "Soon on Google Play" (plain text, no Google artwork): lands big over a blurred frame, then settles under the badge.
func googleBlur(_ t: Double) -> Double {
    prog(t, T.google - 0.08, T.google + 0.1) * (1 - inOut(prog(t, T.googleSettle, T.googleSettle + 0.4)))
}
func googleLine(_ t: Double) {
    guard t >= T.google else { return }
    let stamp = outCubic(prog(t, T.google, T.google + 0.16))
    let settle = inOut(prog(t, T.googleSettle, T.googleSettle + 0.4))
    let size = lerp(84, googleSmall.size, settle) * CGFloat(1 + 0.18 * (1 - stamp))
    let y = lerp(985, googleSmall.y, settle)
    let colour = mix(white, white.alpha(0.85), settle)
    ctx.saveGState(); ctx.setAlpha(CGFloat(stamp))
    text("Soon on Google Play", size, settle < 0.5 ? .heavy : .semibold, colour, 540, y, align: 0.5, kern: settle < 0.5 ? -2 : 0)
    ctx.restoreGState()
}


// MARK: - Headlines

struct Label { let from, to: Double; let lines: [String]; let sub: [String]; let colour: Col }
let labels: [Headline] = [
    Headline(from: 2.4, to: 5.9, lines: ["You write it."], sub: [], colour: ink),
    Headline(from: 6.45, to: 8.2, lines: ["It's on his", "Home Screen."], sub: ["He sees it as “Tasks from Mom”."], colour: white),
    Headline(from: 8.25, to: 10.0, lines: ["He ticks", "it off."], sub: ["You see who did it."], colour: white),
    Headline(from: 10.0, to: 12.0, lines: ["Works", "offline."], sub: ["No signal? Keep ticking."], colour: white),
    Headline(from: 12.0, to: 14.0, lines: ["Syncs when", "you're back."], sub: [], colour: white),
    Headline(from: 14.45, to: 15.95, lines: ["Circles."], sub: ["Shared to-do lists", "for your whole family."], colour: ink),
    Headline(from: 16.3, to: 18.45, lines: ["Know when your", "day is full."], sub: [], colour: ink),
    Headline(from: 18.5, to: 20.0, lines: ["More than", "fits."], sub: ["40m over. Something here", "is tomorrow's problem."], colour: white),
    Headline(from: 20.45, to: 24.0, lines: ["Settle what you", "keep putting off."], sub: [], colour: ink),
    Headline(from: 24.3, to: 26.2, lines: ["Make it", "yours."], sub: ["Themes, widget backgrounds,", "your own photo."], colour: white)]


// MARK: - Background, camera, overlays

enum BG { case green, paper, night, red, flat(Col) }
func paint(_ bg: BG) {
    switch bg {
    case .green:
        let g = CGGradient(colorsSpace: srgb, colors: [green.cg, greenDeep.cg] as CFArray, locations: [0, 1])!
        ctx.drawLinearGradient(g, start: .zero, end: CGPoint(x: 0, y: H), options: [])
    case .night:
        let g = CGGradient(colorsSpace: srgb, colors: [night.cg, night2.cg] as CFArray, locations: [0, 1])!
        ctx.drawLinearGradient(g, start: .zero, end: CGPoint(x: 0, y: H), options: [])
    case .paper: fill(CGRect(x: 0, y: 0, width: W, height: H), paper)
    case .red: fill(CGRect(x: 0, y: 0, width: W, height: H), over)
    case .flat(let c): fill(CGRect(x: 0, y: 0, width: W, height: H), c)
    }
}
func themeBG(_ t: Double) -> BG { themeAt(t).name == "Owly" ? .green : .flat(themeAt(t).col) }
/// Paints `under`, then `top` inside a circle growing from `from`.
func circleWipe(_ under: BG, _ top: BG, from: CGPoint, _ p: Double) {
    paint(under)
    ctx.saveGState()
    ctx.addPath(CGPath(ellipseIn: centred(from, 2300 * CGFloat(outCubic(p))), transform: nil)); ctx.clip()
    paint(top)
    ctx.restoreGState()
}

func background(_ t: Double) {
    switch t {
    case ..<T.stampsB[0]: paint(.green)
    case ..<T.toWidget: paint(.paper)
    case ..<6.5:
        paint(.paper)
        ctx.saveGState(); ctx.clip(to: CGRect(x: 0, y: 0, width: W, height: H * CGFloat(inOut(prog(t, T.toWidget, 6.5)))))
        paint(.night); ctx.restoreGState()
    case ..<T.toCircle: paint(.night)
    case ..<14.45: circleWipe(.night, .paper, from: circleC, prog(t, T.toCircle, 14.45))
    case ..<T.chips[4]: paint(.paper)
    case ..<T.toCard: paint(.red)
    case ..<20.45: circleWipe(.red, .paper, from: CGPoint(x: barR.midX, y: barR.midY), prog(t, T.toCard, 20.45))
    case ..<T.toThemes: paint(.paper)
    case ..<24.35: circleWipe(.paper, .green, from: CGPoint(x: widgetR.midX, y: widgetR.midY), prog(t, T.toThemes, 24.35))
    case ..<T.toIcon: paint(themeBG(t))
    default: paint(.green)
    }
}

func camera(_ t: Double) {
    var s = 1.0
    s += 0.035 * inOut(prog(t, 2.45, T.toWidget)) * (1 - inOut(prog(t, T.toWidget, 6.45)))
    s += 0.04 * inOut(prog(t, 6.45, T.toCircle)) * (1 - inOut(prog(t, T.toCircle, 14.4)))
    if t < T.chips[4] { s += 0.05 * inOut(prog(t, 16.3, T.chips[4])) }
    s += 0.03 * inOut(prog(t, 20.45, T.toThemes)) * (1 - inOut(prog(t, T.toThemes, 24.3)))
    if t < T.toIcon && !(t >= T.offline && t < T.online) {
        s += 0.006 * exp(-t.truncatingRemainder(dividingBy: 0.5) * 14)      // breathe on every beat
    }
    var amp = 0.0
    for at in T.stampsA + T.stampsB where t >= at { amp = max(amp, 7 * exp(-(t - at) * 28)) }
    if t >= T.chips[4] { amp = max(amp, 18 * exp(-(t - T.chips[4]) * 8)) }
    let dx = CGFloat(amp * sin(t * 97)), dy = CGFloat(amp * cos(t * 83))
    ctx.translateBy(x: W / 2 + dx, y: H / 2 + dy)
    ctx.scaleBy(x: CGFloat(s), y: CGFloat(s))
    ctx.translateBy(x: -W / 2, y: -H / 2)
}

/// Offline: the whole frame drains to grey, then colour floods back out from the Wi-Fi icon.
func offlineOverlay(_ t: Double) {
    let d = inOut(prog(t, T.offline, T.offline + 0.25))
    guard d > 0 && t < T.online + 0.5 else { return }
    ctx.saveGState()
    let full = CGMutablePath(); full.addRect(CGRect(x: 0, y: 0, width: W, height: H))
    if t >= T.online {
        let r = 2300 * CGFloat(outCubic(prog(t, T.online, T.online + 0.45)))
        full.addEllipse(in: centred(CGPoint(x: 128, y: 1292), r))
        ctx.addPath(full); ctx.clip(using: .evenOdd)
    }
    ctx.setBlendMode(.saturation)
    fill(CGRect(x: 0, y: 0, width: W, height: H), Col(0x808080, CGFloat(d)))
    ctx.setBlendMode(.normal)
    fill(CGRect(x: 0, y: 0, width: W, height: H), Col(0x000000, CGFloat(0.18 * d)))
    ctx.restoreGState()
}

/// The notification on Mom's iPhone.
func banner(_ t: Double, at: Double, until: Double, _ msg: String) {
    guard t >= at && t < until else { return }
    let y = lerp(-220, 40, outBack(prog(t, at, at + 0.32), 1.2)) - lerp(0, 270, inCubic(prog(t, until - 0.25, until)))
    let r = CGRect(x: 40, y: y - 16, width: 1000, height: 162)
    fillShadowed(rr(r, 44), Col(0xFFFFFF, 0.96), blur: 40, alpha: 0.3)
    ctx.saveGState()
    ctx.addPath(rr(CGRect(x: 72, y: y + 40, width: 90, height: 90), 22)); ctx.clip()
    drawImage(logo, in: CGRect(x: 69, y: y + 37, width: 96, height: 96))
    ctx.restoreGState()
    text("OWLY", 28, .semibold, grey, 190, y + 72, kern: 1)
    text("Mom's iPhone · now", 28, .regular, grey, r.maxX - 40, y + 72, align: 1)
    text(msg, 38, .semibold, ink, 190, y + 124)
}


func owlyFrame(_ t: Double) {
    background(t)
    ctx.saveGState()
    camera(t)
    hook(t)
    homeScreen(t)
    drawBox(t)
    circlesScene(t)
    loadScene(t)
    decideScene(t)
    themeName(t)
    endFrame(t)
    drawHeadlines(labels, t)
    ctx.restoreGState()
    offlineOverlay(t)
    if t >= T.chips[4] && t < T.chips[4] + 0.12 {                       // the over-capacity flash
        fill(CGRect(x: 0, y: 0, width: W, height: H), white.alpha(CGFloat(0.45 * (1 - prog(t, T.chips[4], T.chips[4] + 0.12)))))
    }
    banner(t, at: T.banner1, until: 10.0, "Done by Leo: Pack gym clothes")
    banner(t, at: T.banner2, until: 13.9, "Done by Leo: Feed the dog")
    let blur = googleBlur(t)
    blurFrame(sigma: 26 * blur, darken: CGFloat(0.22 * blur))
    googleLine(t)
}


// MARK: - Score (120 BPM, A minor → F → C → G)

let chordsSeq: [[Int]] = [[57, 60, 64], [57, 60, 65], [55, 60, 64], [55, 59, 62]]   // Am F C G
let bassSeq = [45, 41, 48, 43]
func bar(_ t: Double) -> Int { Int(floor(t / 2 + 1e-9)) % 4 }

func owlyScore(_ score: Score) {
    let music = score.music, ducked = score.ducked, fx = score.fx, sfx = score.sfx
    func cue(_ t: Double, _ what: String, _ s: [Float], _ g: Float, pan: Float = 0, bus: Bus? = nil) {
        score.cue(t, what, s, g, pan: pan, bus: bus)
    }
    // Hook: an impact, then a stamp and a stab on every word.
    music.add(impact(), at: 0, gain: 0.9)
    for (i, at) in T.stampsA.enumerated() { cue(at, "stamp", stampHit(), 0.55); music.add(stab(chordsSeq[0].map { $0 + (i == 2 ? 12 : 0) }), at: at, gain: 0.5) }
    for (i, at) in T.stampsB.enumerated() { cue(at, "stamp", stampHit(), 0.55); music.add(stab(chordsSeq[1].map { $0 + (i == 2 ? 12 : 0) }), at: at, gain: 0.5) }
    fx.add(riser(0.55), at: 1.45, gain: 0.35)

    var kicks: [Double] = []
    for b in stride(from: 0.0, to: 26.0, by: 0.5) { kicks.append(b); music.add(kick(), at: b, gain: 0.95) }
    for b in stride(from: 2.0, to: 26.0, by: 0.5) {
        music.add(hat(), at: b + 0.25, gain: 0.22)
        if b >= 6 { music.add(hat(), at: b + 0.125, gain: 0.08); music.add(hat(), at: b + 0.375, gain: 0.08) }
        if b >= 6 && Int(b * 2) % 4 == 1 || b >= 6 && Int(b * 2) % 4 == 3 { music.add(clap(), at: b, gain: 0.42) }
        let root = bassSeq[bar(b)]
        if b >= 6 { ducked.add(bassNote(root, 0.2), at: b + 0.25, gain: 0.5) }
        else { ducked.add(bassNote(root, 0.2), at: b, gain: 0.32); ducked.add(bassNote(root, 0.2), at: b + 0.25, gain: 0.26) }
        // 16th-note arpeggio over the chord.
        let ch = chordsSeq[bar(b)]
        let pattern = [ch[0] + 12, ch[1] + 12, ch[2] + 12, ch[1] + 24]
        for k in 0..<4 { ducked.add(pluck(pattern[(Int(b * 2) * 4 + k) % 4]), at: b + Double(k) * 0.125, gain: b >= 6 ? 0.13 : 0.1) }
    }
    for b in stride(from: 2.0, to: 26.0, by: 2.0) { ducked.add(pad(chordsSeq[bar(b)], 2.0), at: b, gain: 0.22) }
    // Builds and drops.
    fx.add(riser(1.0), at: 5.0, gain: 0.4)
    for k in 0..<8 { music.add(clap(), at: 5.5 + Double(k) * 0.0625, gain: 0.08 + 0.035 * Float(k)) }
    for at in [6.0, 18.5] { music.add(impact(), at: at, gain: 0.75) }
    for at in [6.0, 12.0, 18.5, 24.0] { music.add(crash(), at: at, gain: 0.32) }
    for at in [6.0, 12.0, 14.0, 18.5, 20.0, 24.0] + T.themeCuts.dropLast() { music.add(stab(chordsSeq[bar(at)].map { $0 + 12 }), at: at, gain: 0.32) }
    fx.add(riser(1.0), at: 11.0, gain: 0.4)
    fx.add(riser(1.0), at: 17.5, gain: 0.4)
    for k in 0..<8 { music.add(clap(), at: 18.0 + Double(k) * 0.0625, gain: 0.08 + 0.04 * Float(k)) }
    fx.add(riser(0.5), at: 23.5, gain: 0.3)
    fx.add(riser(0.9), at: 25.6, gain: 0.45)
    // Ending: the beat drops out on 26, the icon lands on 26.5 with one long chord.
    music.add(impact(), at: T.thump, gain: 0.85)
    music.add(chordVoice([48, 55, 60, 64, 67, 74], dur: 3.5, attack: 0.01, cutoff: { 900 + 2400 * exp(-$0 * 1.5) }, decay: 0.9), at: T.thump, gain: 0.55)
    music.add(bassNote(36, 1.6), at: T.thump, gain: 0.5)
    for k in 0..<16 { music.add(pluck([72, 76, 79, 84][k % 4]), at: T.thump + Double(k) * 0.125, gain: 0.11 * Float(1 - Double(k) / 16)) }

    // Sound effects, on the picture's own times.
    cue(T.dotPulse, "pop", pop(700), 0.3)
    cue(T.card, "whoosh", whoosh(0.45), 0.28)
    for k in 1...18 { sfx.add(keyTap(), at: T.typeFrom + (T.typeTo - T.typeFrom) * Double(k) / 18, gain: 0.22, pan: Float(k % 3 - 1) * 0.2) }
    cue(T.chip, "pop", pop(820), 0.3)
    for (i, at) in T.rows.enumerated() { cue(at, "pop", pop(440 + Double(i) * 60), 0.24) }
    cue(T.toWidget - 0.05, "whoosh", whoosh(0.5), 0.3)
    cue(T.tapPack, "tap", click(), 0.3); cue(T.tapPack + 0.1, "tick", pop(900), 0.3)
    cue(T.banner1 + 0.08, "ding", ding(), 0.2)
    cue(T.offline, "offline", powerDown(), 0.3)
    cue(T.tapDog, "tap", click(), 0.3, bus: music); cue(T.tapDog + 0.1, "tick", pop(900), 0.3, bus: music)
    cue(T.online, "online", whoosh(0.45), 0.32)
    cue(T.banner2 + 0.08, "ding", ding(), 0.2)
    cue(T.toCircle, "whoosh", whoosh(0.4), 0.28)
    for (i, at) in T.circles.enumerated() { cue(at, "pop", pop(500 + Double(i) * 120), 0.3, pan: Float(i - 1) * 0.4) }
    cue(T.merge, "whoosh", whoosh(0.5, up: false), 0.28)
    for (i, at) in T.chips.enumerated() {
        sfx.add(whoosh(0.42, up: false), at: at - 0.45, gain: 0.12, pan: i % 2 == 0 ? -0.3 : 0.3)
        cue(at, "drop", pop(260), 0.32)
    }
    cue(T.toCard, "whoosh", whoosh(0.42), 0.28)
    cue(T.pressA, "press", click(), 0.32); cue(T.flingA, "fling", whoosh(0.38), 0.3, pan: -0.5)
    cue(T.pressB, "press", click(), 0.32); cue(T.flingB, "fling", whoosh(0.38), 0.3, pan: 0.5)
    cue(T.toThemes, "whoosh", whoosh(0.35), 0.28)
    for at in T.themeCuts { cue(at, "cut", click(), 0.3) }
    cue(T.toIcon, "whoosh", whoosh(0.3, up: false), 0.25)
    cue(T.thump, "thump", thumpSnd(), 0.8)
    for at in T.endLines { cue(at, "line", pop(620), 0.12) }
    cue(T.badge, "badge", pop(980), 0.3); sfx.add(ding(), at: T.badge, gain: 0.12)

    score.kicks = kicks
    score.muffled = [(T.offline, T.online)]          // offline: the music goes underwater
    score.fadeOut = (28.6, 29.95)
}
