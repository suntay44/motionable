// motionable engine: small line icons for "mini images" — benefit chips, feature rows, callouts. Original paths
// (MIT, part of motionable) on a 24-unit grid, drawn with round caps; they can pop in or draw themselves on.
// Not Apple's SF Symbols (whose licence limits use), not any other icon set.
import AppKit

enum Icon: String, CaseIterable {
    case check, close, plus, star, heart, bolt, clock, cart, lock, shield, cloud, offline, share, download, bell, chat
    case camera, user, users, home, search, fire, leaf, coin, chartUp, calendar, gift, trophy, play, pin, globe, book
    case forkKnife, cup, dumbbell, sparkle, music, doc, tag, timer, phone, wand, scale, list, send, eye

    var d: String {
        switch self {
        case .check: return "M5 12.5 L10 17.5 L19 7"
        case .close: return "M6 6 L18 18 M18 6 L6 18"
        case .plus: return "M12 5 V19 M5 12 H19"
        case .star: return "M12 3 L14.6 8.6 L20.7 9.3 L16.2 13.4 L17.4 19.5 L12 16.5 L6.6 19.5 L7.8 13.4 L3.3 9.3 L9.4 8.6 Z"
        case .heart: return "M12 20.5 C6 16 2.5 12.5 4 8.5 C5.3 5.2 9.6 4.8 12 8 C14.4 4.8 18.7 5.2 20 8.5 C21.5 12.5 18 16 12 20.5 Z"
        case .bolt: return "M13 2.5 L4.5 13.5 H11 L10 21.5 L19.5 10 H13 Z"
        case .clock: return "M12 3 A9 9 0 1 1 11.99 3 Z M12 7 V12 L15.5 14"
        case .cart: return "M2.5 4 H5 L7.4 15 H18.3 L20.8 7.2 H6 M9 19.5 A1.4 1.4 0 1 1 8.99 19.5 Z M17 19.5 A1.4 1.4 0 1 1 16.99 19.5 Z"
        case .lock: return "M6 11 H18 V20.5 H6 Z M8.5 11 V8 A3.5 3.5 0 0 1 15.5 8 V11 M12 14.5 V17"
        case .shield: return "M12 2.8 L19.5 6 V11.5 C19.5 16.5 16.2 19.8 12 21.2 C7.8 19.8 4.5 16.5 4.5 11.5 V6 Z M8.8 12 L11 14.2 L15.4 9.6"
        case .cloud: return "M7 18.5 H17.2 A4.2 4.2 0 0 0 17.6 10.1 A6 6 0 0 0 6.2 11.6 A3.5 3.5 0 0 0 7 18.5 Z"
        case .offline: return "M2.5 8.8 A13.5 13.5 0 0 1 21.5 8.8 M5.6 12.2 A9 9 0 0 1 18.4 12.2 M8.7 15.6 A4.6 4.6 0 0 1 15.3 15.6 M12 19.2 V19.3 M4 3.5 L20 20.5"
        case .share: return "M12 3.5 V14.5 M8 7.5 L12 3.5 L16 7.5 M5.5 11.5 V20 H18.5 V11.5"
        case .download: return "M12 3.5 V15 M7.5 10.5 L12 15 L16.5 10.5 M5 20 H19"
        case .bell: return "M6 16.5 V11 A6 6 0 0 1 18 11 V16.5 L19.6 18.5 H4.4 Z M10 21 H14"
        case .chat: return "M4 5 H20 V16 H11.5 L7 20 V16 H4 Z M8 9.5 H16 M8 12.5 H13"
        case .camera: return "M3.5 8 H7.5 L9 5.5 H15 L16.5 8 H20.5 V19 H3.5 Z M12 10 A3.5 3.5 0 1 1 11.99 10 Z"
        case .user: return "M12 4 A4 4 0 1 1 11.99 4 Z M4.5 21 A7.5 7.5 0 0 1 19.5 21"
        case .users: return "M9 5 A3.5 3.5 0 1 1 8.99 5 Z M2.5 20.5 A6.5 6.5 0 0 1 15.5 20.5 M16 5.2 A3.2 3.2 0 0 1 16 11.5 M18 14.4 A6.5 6.5 0 0 1 21.5 20.5"
        case .home: return "M3 11.2 L12 3.8 L21 11.2 M5.5 9.2 V20.5 H18.5 V9.2 M10 20.5 V14.5 H14 V20.5"
        case .search: return "M11 4.5 A6.5 6.5 0 1 1 10.99 4.5 Z M15.8 15.8 L20.5 20.5"
        case .fire: return "M12 21.5 C7.6 21.5 5 18.7 5 15.3 C5 11 8.8 9.2 9.4 4.4 C12.3 6.4 13 8.8 12.5 11 C14 10 15 8.5 15.2 7 C17.8 9 19 12 19 15.3 C19 18.7 16.4 21.5 12 21.5 Z"
        case .leaf: return "M5 19 C5 10.5 10 5.2 20 4 C19 14 13.8 19 5 19 Z M5 19 L13.5 10.5"
        case .coin: return "M12 3 A9 9 0 1 1 11.99 3 Z M14.6 9 C14.1 8 13.1 7.4 12 7.4 C10.4 7.4 9.4 8.3 9.4 9.5 C9.4 12.4 14.7 11.2 14.7 14.4 C14.7 15.8 13.5 16.7 12 16.7 C10.7 16.7 9.7 16.1 9.2 15.1 M12 5.8 V7.4 M12 16.7 V18.3"
        case .chartUp: return "M3.5 20 H20.5 M5 16 L10 11 L13 14 L19.5 7 M15 7 H19.5 V11.5"
        case .calendar: return "M4 6 H20 V20.5 H4 Z M4 10 H20 M8 3.5 V7.5 M16 3.5 V7.5 M8 13.5 H9 M11.5 13.5 H12.5 M15 13.5 H16 M8 17 H9 M11.5 17 H12.5"
        case .gift: return "M4 9 H20 V12.5 H4 Z M5.5 12.5 V20.5 H18.5 V12.5 M12 9 V20.5 M12 9 C10.5 5.5 6.5 5.5 7.6 8 C8.2 9 12 9 12 9 Z M12 9 C13.5 5.5 17.5 5.5 16.4 8 C15.8 9 12 9 12 9 Z"
        case .trophy: return "M7.5 4 H16.5 V9.5 A4.5 4.5 0 0 1 7.5 9.5 Z M7.5 6 H4.5 V7.8 A3 3 0 0 0 7.6 10.8 M16.5 6 H19.5 V7.8 A3 3 0 0 1 16.4 10.8 M12 14 V17.5 M8.5 20.5 H15.5 M9.5 17.5 H14.5 V20.5 H9.5 Z"
        case .play: return "M8 5 L19 12 L8 19 Z"
        case .pin: return "M12 21.5 C9.5 18.8 5 14.2 5 9.6 A7 7 0 0 1 19 9.6 C19 14.2 14.5 18.8 12 21.5 Z M12 7.2 A2.4 2.4 0 1 1 11.99 7.2 Z"
        case .globe: return "M12 3 A9 9 0 1 1 11.99 3 Z M3 12 H21 M12 3 C9 6 8.2 9 8.2 12 C8.2 15 9 18 12 21 M12 3 C15 6 15.8 9 15.8 12 C15.8 15 15 18 12 21"
        case .book: return "M12 6.2 C10 4.6 6.6 4.1 3 4.6 V19 C6.6 18.5 10 19 12 20.5 C14 19 17.4 18.5 21 19 V4.6 C17.4 4.1 14 4.6 12 6.2 Z M12 6.2 V20.5"
        case .forkKnife: return "M5.5 3 V8 A2.5 2.5 0 0 0 10.5 8 V3 M8 3 V21 M17.5 21 V3 C15.2 4.8 14.4 8 14.6 12.5 H17.5"
        case .cup: return "M5 9 H16 V15 A4 4 0 0 1 12 19 H9 A4 4 0 0 1 5 15 Z M16 10.5 H17.5 A2.5 2.5 0 0 1 17.5 15.5 H16 M8 3.5 C7.2 4.6 8.8 5.4 8 6.5 M11 3.5 C10.2 4.6 11.8 5.4 11 6.5 M4 21 H17"
        case .dumbbell: return "M2.5 10 V14 M5 7.5 V16.5 H7.5 V7.5 Z M16.5 7.5 V16.5 H19 V7.5 Z M21.5 10 V14 M7.5 12 H16.5"
        case .sparkle: return "M12 3 C12.6 8.2 15.8 11.4 21 12 C15.8 12.6 12.6 15.8 12 21 C11.4 15.8 8.2 12.6 3 12 C8.2 11.4 11.4 8.2 12 3 Z"
        case .music: return "M9 18 V5.5 L19.5 3.5 V16 M9 18 A2.5 2.2 0 1 1 8.99 18 Z M19.5 16 A2.5 2.2 0 1 1 19.49 16 Z"
        case .doc: return "M6 3 H14 L19 8 V21 H6 Z M14 3 V8 H19 M9 12.5 H16 M9 16 H16"
        case .tag: return "M3.5 12.5 V4 H12 L21 13 L13 21 Z M8 7 A1.5 1.5 0 1 1 7.99 7 Z"
        case .timer: return "M12 7 A7.5 7.5 0 1 1 11.99 7 Z M12 10.5 V14.5 L14.5 16 M9.5 3 H14.5 M12 3 V7 M18.2 6.6 L19.8 5"
        case .phone: return "M7 2.5 H17 V21.5 H7 Z M10.5 18.5 H13.5"
        case .wand: return "M4 20 L15 9 M13 7 L17 11 M17.5 3 V6 M16 4.5 H19 M20 9.5 V12 M18.8 10.8 H21.2 M10.5 3.5 V5.5 M9.5 4.5 H11.5"
        case .scale: return "M12 3.5 V20.5 M6 20.5 H18 M4.5 7 H19.5 M4.5 7 L2 13 A2.6 2.6 0 0 0 7 13 Z M19.5 7 L17 13 A2.6 2.6 0 0 0 22 13 Z"
        case .list: return "M9 6.5 H20 M9 12 H20 M9 17.5 H20 M4.5 6.5 H5.5 M4.5 12 H5.5 M4.5 17.5 H5.5"
        case .send: return "M21 3 L3 10.5 L10.5 13.5 L13.5 21 Z M10.5 13.5 L21 3"
        case .eye: return "M2.5 12 C5 7 8.3 5 12 5 C15.7 5 19 7 21.5 12 C19 17 15.7 19 12 19 C8.3 19 5 17 2.5 12 Z M12 9 A3 3 0 1 1 11.99 9 Z"
        }
    }
}

var iconPathCache: [Icon: CGPath] = [:]
func iconPath(_ i: Icon) -> CGPath {
    if let p = iconPathCache[i] { return p }
    let p = svgPath(i.d)
    iconPathCache[i] = p
    return p
}

/// Draws an icon centred at `c`, `size` px across. `p` 0…1 draws it on stroke by stroke; `fill` fills closed shapes.
func icon(_ i: Icon, at c: CGPoint, size: CGFloat, colour: Col, weight: CGFloat = 2, p: Double = 1, fill bg: Col? = nil) {
    guard p > 0 else { return }
    let k = size / 24
    ctx.saveGState()
    ctx.translateBy(x: c.x - 12 * k, y: c.y - 12 * k)
    ctx.scaleBy(x: k, y: k)
    let path = iconPath(i)
    if let bg { ctx.saveGState(); ctx.setAlpha(CGFloat(min(1, p * 1.5))); fill(path, bg); ctx.restoreGState() }
    if p >= 1 { stroke(path, colour, weight) }
    else { for poly in polylines(path, tolerance: 0.3) { stroke(partial(poly, outCubic(p)), colour, weight) } }
    ctx.restoreGState()
}

/// A benefit chip: an icon in a disc plus a short label, popping in over p (0…1). Returns its width.
@discardableResult
func iconChip(_ i: Icon, _ label: String, at c: CGPoint, p: Double, fill bg: Col, ink: Col, disc: Col, discInk: Col,
              face: Face = .system(.bold), size: CGFloat = 40) -> CGFloat {
    let tw = textWidth(label, size, face)
    let h = size * 1.9, w = h + tw + size * 0.9
    guard p > 0 else { return w }
    let k = CGFloat(outBack(min(1, p), 1.8))
    ctx.saveGState()
    ctx.translateBy(x: c.x, y: c.y); ctx.scaleBy(x: k, y: k); ctx.translateBy(x: -c.x, y: -c.y)
    let r = CGRect(x: c.x - w / 2, y: c.y - h / 2, width: w, height: h)
    fillShadowed(rr(r, h / 2), bg, blur: 24, alpha: 0.18, dy: 8)
    let dc = CGPoint(x: r.minX + h / 2, y: c.y)
    fill(CGPath(ellipseIn: centred(dc, h * 0.38), transform: nil), disc)
    icon(i, at: dc, size: h * 0.44, colour: discInk, weight: 2.4, p: prog(p, 0.15, 0.8))
    text(label, size, face, ink, r.minX + h + size * 0.1, c.y + size * 0.35)
    ctx.restoreGState()
    return w
}
