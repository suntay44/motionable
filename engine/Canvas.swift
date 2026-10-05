// motionable engine: canvas, colour, easing, text and images.
// Everything draws into `ctx` with a top-left origin, in pixels of the film's canvas.
import AppKit
import CoreImage
import CoreText
import ImageIO
import UniformTypeIdentifiers

/// Set by the engine from the film before anything is drawn.
var W: CGFloat = 1080, H: CGFloat = 1920
/// The project folder (the one holding scenes/ and assets/); relative asset paths resolve against it.
var projectDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

// MARK: - Colour

struct Col {
    var r, g, b, a: CGFloat
    init(_ hex: UInt32, _ a: CGFloat = 1) {
        r = CGFloat((hex >> 16) & 0xFF) / 255; g = CGFloat((hex >> 8) & 0xFF) / 255
        b = CGFloat(hex & 0xFF) / 255; self.a = a
    }
    init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) { self.r = r; self.g = g; self.b = b; self.a = a }
    var cg: CGColor { CGColor(srgbRed: r, green: g, blue: b, alpha: a) }
    func alpha(_ x: CGFloat) -> Col { Col(r: r, g: g, b: b, a: a * x) }
}
func mix(_ x: Col, _ y: Col, _ t: Double) -> Col {
    let k = CGFloat(clamp(t))
    return Col(r: x.r + (y.r - x.r) * k, g: x.g + (y.g - x.g) * k, b: x.b + (y.b - x.b) * k, a: x.a + (y.a - x.a) * k)
}

// MARK: - Easing

func clamp(_ x: Double, _ a: Double = 0, _ b: Double = 1) -> Double { min(max(x, a), b) }
func prog(_ t: Double, _ a: Double, _ b: Double) -> Double { clamp((t - a) / (b - a)) }
func outCubic(_ x: Double) -> Double { 1 - pow(1 - x, 3) }
func inCubic(_ x: Double) -> Double { x * x * x }
func inOut(_ x: Double) -> Double { x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2 }
func outBack(_ x: Double, _ s: Double = 1.6) -> Double { 1 + (s + 1) * pow(x - 1, 3) + s * pow(x - 1, 2) }
func lerp(_ a: CGFloat, _ b: CGFloat, _ t: Double) -> CGFloat { a + (b - a) * CGFloat(t) }
func lerp(_ a: CGRect, _ b: CGRect, _ t: Double) -> CGRect {
    CGRect(x: lerp(a.minX, b.minX, t), y: lerp(a.minY, b.minY, t),
           width: lerp(a.width, b.width, t), height: lerp(a.height, b.height, t))
}
func lerp(_ a: CGPoint, _ b: CGPoint, _ t: Double) -> CGPoint { CGPoint(x: lerp(a.x, b.x, t), y: lerp(a.y, b.y, t)) }
func centred(_ c: CGPoint, _ r: CGFloat) -> CGRect { CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r) }

// MARK: - Drawing helpers

var ctx: CGContext!
let ciContext = CIContext(options: [.workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!])
let srgb = CGColorSpace(name: CGColorSpace.sRGB)!

func rr(_ r: CGRect, _ rad: CGFloat) -> CGPath {
    let k = max(0, min(rad, r.width / 2, r.height / 2))
    return CGPath(roundedRect: r, cornerWidth: k, cornerHeight: k, transform: nil)
}
func fill(_ path: CGPath, _ c: Col) { ctx.addPath(path); ctx.setFillColor(c.cg); ctx.fillPath() }
func fill(_ r: CGRect, _ c: Col) { ctx.setFillColor(c.cg); ctx.fill(r) }
func fillShadowed(_ path: CGPath, _ c: Col, blur: CGFloat = 50, alpha: CGFloat = 0.18, dy: CGFloat = 18) {
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: dy), blur: blur, color: Col(0x000000, alpha).cg)
    fill(path, c)
    ctx.restoreGState()
}
func stroke(_ path: CGPath, _ c: Col, _ w: CGFloat) {
    ctx.addPath(path); ctx.setStrokeColor(c.cg); ctx.setLineWidth(w)
    ctx.setLineCap(.round); ctx.setLineJoin(.round); ctx.strokePath()
}
func line(_ a: CGPoint, _ b: CGPoint, _ c: Col, _ w: CGFloat) {
    let p = CGMutablePath(); p.move(to: a); p.addLine(to: b); stroke(p, c, w)
}
/// A polyline drawn up to `fraction` of its length (for checkmarks and strokes).
func partial(_ pts: [CGPoint], _ fraction: Double) -> CGPath {
    let p = CGMutablePath()
    guard pts.count > 1, fraction > 0 else { return p }
    var lengths: [CGFloat] = []
    for i in 1..<pts.count { lengths.append(hypot(pts[i].x - pts[i - 1].x, pts[i].y - pts[i - 1].y)) }
    var left = lengths.reduce(0, +) * CGFloat(clamp(fraction))
    p.move(to: pts[0])
    for i in 1..<pts.count {
        if left >= lengths[i - 1] { p.addLine(to: pts[i]); left -= lengths[i - 1] }
        else { p.addLine(to: lerp(pts[i - 1], pts[i], Double(left / lengths[i - 1]))); break }
    }
    return p
}

// SF Pro by weight — kept for films written before Faces existed; everything routes through Fonts.swift.
func font(_ size: CGFloat, _ w: NSFont.Weight) -> CTFont { ctFont(.system(w), size) }
func textWidth(_ s: String, _ size: CGFloat, _ w: NSFont.Weight, kern: CGFloat = 0) -> CGFloat {
    textWidth(s, size, .system(w), kern: kern)
}
/// Draws one line of text with its baseline at y; `align` 0 = left, 0.5 = centre, 1 = right.
@discardableResult
func text(_ s: String, _ size: CGFloat, _ w: NSFont.Weight, _ c: Col, _ x: CGFloat, _ y: CGFloat,
          align: CGFloat = 0, kern: CGFloat = 0) -> CGFloat {
    text(s, size, .system(w), c, x, y, align: align, kern: kern)
}
func drawImage(_ img: CGImage, in r: CGRect) {
    ctx.saveGState()
    ctx.translateBy(x: r.minX, y: r.maxY)
    ctx.scaleBy(x: 1, y: -1)
    ctx.interpolationQuality = .high
    ctx.draw(img, in: CGRect(origin: .zero, size: r.size))
    ctx.restoreGState()
}
/// Loads a PNG/JPEG/HEIC. Relative paths resolve against the project folder.
func loadImage(_ path: String) -> CGImage {
    let url = path.hasPrefix("/") ? URL(fileURLWithPath: path) : projectDir.appendingPathComponent(path)
    guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
          let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else { fatalError("can't read \(url.path)") }
    return img
}
/// Rasterises an SVG (store badges, logos) at `height` pixels, 2x for a crisp downscale.
func loadSVG(_ path: String, height: CGFloat) -> CGImage {
    let url = path.hasPrefix("/") ? URL(fileURLWithPath: path) : projectDir.appendingPathComponent(path)
    guard let svg = NSImage(contentsOf: url) else { fatalError("can't read \(url.path)") }
    var rect = CGRect(x: 0, y: 0, width: 2 * height * svg.size.width / svg.size.height, height: 2 * height)
    return svg.cgImage(forProposedRect: &rect, context: nil, hints: nil)!
}
/// Blurs everything drawn so far in this frame (for "focus" moments), optionally darkening it.
func blurFrame(sigma: Double, darken: CGFloat = 0) {
    guard sigma > 0, let snap = ctx.makeImage() else { return }
    let full = CGRect(x: 0, y: 0, width: W, height: H)
    let ci = CIImage(cgImage: snap).clampedToExtent().applyingGaussianBlur(sigma: sigma).cropped(to: full)
    if let blurred = ciContext.createCGImage(ci, from: full) { drawImage(blurred, in: full) }
    if darken > 0 { fill(full, Col(0x000000, darken)) }
}

// MARK: - Film grain (drawn by the engine over every frame; frozen during the final hold)

var grain: [CGImage] = []
var grainAlpha: UInt8 = 9
func makeGrain() {
    var seed: UInt32 = 0x9E3779B9
    for _ in 0..<6 {
        let w = Int(W), h = Int(H)
        var px = [UInt8](repeating: 0, count: w * h * 4)
        for i in 0..<(w * h) {
            seed = seed &* 1664525 &+ 1013904223
            let v = UInt8(truncatingIfNeeded: seed >> 24)
            let a = grainAlpha
            let pv = UInt8((Int(v) * Int(a)) / 255)
            px[i * 4] = pv; px[i * 4 + 1] = pv; px[i * 4 + 2] = pv; px[i * 4 + 3] = a
        }
        let c = CGContext(data: &px, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: srgb,
                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        grain.append(c.makeImage()!)
    }
}

func writePNG(_ img: CGImage, _ url: URL) {
    let d = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(d, img, nil)
    CGImageDestinationFinalize(d)
}
