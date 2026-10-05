// motionable: measure a screenshot, so a redrawn tick, counter or bar lands exactly where the real UI has it.
// usage: inspect <image>                                   size, the background colour and the darkest/lightest colours
//        inspect <image> pixel X,Y [X,Y …]                 the colour at each point
//        inspect <image> row Y [lo hi]                     runs along row Y whose luminance is in lo…hi (default: differs from the background)
//        inspect <image> column X [lo hi]                  the same down column X
//        inspect <image> find RRGGBB [tolerance]           bounding boxes of areas in that colour (rings, bars, badges)
import AppKit

let a = Array(CommandLine.arguments.dropFirst())
guard let path = a.first, let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
      let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else { print("usage: inspect <image> [pixel X,Y … | row Y | column X | find RRGGBB]"); exit(2) }
let w = img.width, h = img.height
var px = [UInt8](repeating: 0, count: w * h * 4)
let c = CGContext(data: &px, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
c.draw(img, in: CGRect(x: 0, y: 0, width: w, height: h))
func rgb(_ x: Int, _ y: Int) -> (Int, Int, Int) { let o = (y * w + x) * 4; return (Int(px[o]), Int(px[o + 1]), Int(px[o + 2])) }
func lum(_ x: Int, _ y: Int) -> Int { let (r, g, b) = rgb(x, y); return (r * 3 + g * 6 + b) / 10 }
func hex(_ x: Int, _ y: Int) -> String { let (r, g, b) = rgb(x, y); return String(format: "#%02X%02X%02X", r, g, b) }
/// The most common luminance on a coarse grid: the background.
let background: Int = {
    var counts = [Int: Int]()
    for y in stride(from: 0, to: h, by: max(1, h / 60)) { for x in stride(from: 0, to: w, by: max(1, w / 40)) { counts[lum(x, y) / 4, default: 0] += 1 } }
    return (counts.max { $0.value < $1.value }?.key ?? 0) * 4 + 2
}()
func runs(_ n: Int, _ value: (Int) -> Int, lo: Int?, hi: Int?) -> [(Int, Int)] {
    var out: [(Int, Int)] = [], start = -1
    for i in 0...n {
        let v = i < n ? value(i) : -999
        let hit = i < n && (lo.map { v >= $0 && v <= hi! } ?? (abs(v - background) > 12))
        if hit && start < 0 { start = i }
        if !hit && start >= 0 { if i - start >= 2 { out.append((start, i - 1)) }; start = -1 }
    }
    return out
}
let mode = a.count > 1 ? a[1] : "info"
switch mode {
case "pixel":
    for p in a.dropFirst(2) {
        let xy = p.split(separator: ",").compactMap { Int($0) }
        guard xy.count == 2, xy[0] < w, xy[1] < h else { print("\(p): outside \(w)×\(h)"); continue }
        print("(\(xy[0]), \(xy[1]))  \(hex(xy[0], xy[1]))")
    }
case "row", "column":
    guard a.count > 2, let i = Int(a[2]) else { print("usage: inspect <image> \(mode) N [lo hi]"); exit(2) }
    let lo = a.count > 4 ? Int(a[3]) : nil, hi = a.count > 4 ? Int(a[4]) : nil
    let r = mode == "row" ? runs(w, { lum($0, i) }, lo: lo, hi: hi) : runs(h, { lum(i, $0) }, lo: lo, hi: hi)
    print("\(mode) \(i): \(r.count) runs \(lo == nil ? "that differ from the background (luminance \(background))" : "with luminance \(lo!)…\(hi!)")")
    for (s, e) in r.prefix(60) {
        let mid = (s + e) / 2
        print("  \(s)–\(e)  (\(e - s + 1) px)  \(mode == "row" ? hex(mid, i) : hex(i, mid))")
    }
case "find":
    guard a.count > 2, let target = Int(a[2], radix: 16) else { print("usage: inspect <image> find RRGGBB [tolerance]"); exit(2) }
    let tol = a.count > 3 ? Int(a[3]) ?? 24 : 24
    let tr = (target >> 16) & 255, tg = (target >> 8) & 255, tb = target & 255
    var seen = [Bool](repeating: false, count: w * h)
    var boxes: [(Int, Int, Int, Int, Int)] = []
    for y in 0..<h { for x in 0..<w where !seen[y * w + x] {
        let (r, g, b) = rgb(x, y)
        guard abs(r - tr) <= tol && abs(g - tg) <= tol && abs(b - tb) <= tol else { continue }
        var stack = [(x, y)], minX = x, maxX = x, minY = y, maxY = y, count = 0
        seen[y * w + x] = true
        while let (cx, cy) = stack.popLast() {
            count += 1; minX = min(minX, cx); maxX = max(maxX, cx); minY = min(minY, cy); maxY = max(maxY, cy)
            for (nx, ny) in [(cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)] where nx >= 0 && ny >= 0 && nx < w && ny < h && !seen[ny * w + nx] {
                let (r2, g2, b2) = rgb(nx, ny)
                if abs(r2 - tr) <= tol && abs(g2 - tg) <= tol && abs(b2 - tb) <= tol { seen[ny * w + nx] = true; stack.append((nx, ny)) }
            }
        }
        if count >= 12 { boxes.append((minX, minY, maxX - minX + 1, maxY - minY + 1, count)) }
    } }
    print("#\(a[2]) ±\(tol): \(boxes.count) areas (x, y, width, height · centre)")
    for b in boxes.sorted(by: { ($0.1, $0.0) < ($1.1, $1.0) }).prefix(60) {
        print("  \(b.0), \(b.1), \(b.2) × \(b.3)  · centre (\(b.0 + b.2 / 2), \(b.1 + b.3 / 2))  \(b.4) px")
    }
default:
    var lo = 255, hi = 0, dark = (0, 0), light = (0, 0)
    for y in stride(from: 0, to: h, by: 2) { for x in stride(from: 0, to: w, by: 2) {
        let l = lum(x, y); if l < lo { lo = l; dark = (x, y) }; if l > hi { hi = l; light = (x, y) }
    } }
    print("\(w) × \(h) px · background luminance \(background) · corner \(hex(0, 0)) · centre \(hex(w / 2, h / 2))")
    print("darkest \(hex(dark.0, dark.1)) at (\(dark.0), \(dark.1)) · lightest \(hex(light.0, light.1)) at (\(light.0), \(light.1))")
    print("next: inspect <image> row Y · column X · pixel X,Y · find RRGGBB")
}
