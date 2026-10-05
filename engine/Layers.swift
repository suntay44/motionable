// motionable engine: off-screen layers and Core Image looks. Render any part of a frame on its own, then
// blur, mask, move or composite it — the basis of transitions and post looks.
import AppKit
import CoreImage

/// Renders `draw` into its own transparent full-canvas layer and returns it as an image.
func layer(_ draw: () -> Void) -> CGImage {
    let saved = ctx, savedScale = deviceScale
    let c = CGContext(data: nil, width: Int(W), height: Int(H), bitsPerComponent: 8, bytesPerRow: 0, space: srgb,
                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    c.translateBy(x: 0, y: H); c.scaleBy(x: 1, y: -1)
    c.textMatrix = .identity
    ctx = c
    deviceScale = 1
    draw()
    ctx = saved
    deviceScale = savedScale
    return c.makeImage()!
}

let fullCanvas: () -> CGRect = { CGRect(x: 0, y: 0, width: W, height: H) }

/// Draws a full-canvas layer, optionally moved, scaled (about `anchor`) and rotated.
func drawLayer(_ img: CGImage, alpha: CGFloat = 1, dx: CGFloat = 0, dy: CGFloat = 0, scale: CGFloat = 1,
               rotate: CGFloat = 0, anchor: CGPoint? = nil) {
    guard alpha > 0.001 else { return }
    let a = anchor ?? CGPoint(x: W / 2, y: H / 2)
    ctx.saveGState()
    ctx.setAlpha(alpha)
    ctx.translateBy(x: a.x + dx, y: a.y + dy)
    ctx.rotate(by: rotate)
    ctx.scaleBy(x: scale, y: scale)
    ctx.translateBy(x: -a.x, y: -a.y)
    drawImage(img, in: fullCanvas())
    ctx.restoreGState()
}

// MARK: - Core Image looks (all take and return full-canvas images)

func ci(_ img: CGImage, _ apply: (CIImage) -> CIImage) -> CGImage {
    let input = CIImage(cgImage: img)
    let out = apply(input).cropped(to: input.extent)
    return ciContext.createCGImage(out, from: input.extent) ?? img
}
/// Directional motion blur (degrees: 0 = horizontal).
func motionBlurred(_ img: CGImage, radius: Double, degrees: Double = 0) -> CGImage {
    guard radius > 0.5 else { return img }
    return ci(img) { $0.clampedToExtent().applyingFilter("CIMotionBlur", parameters: [kCIInputRadiusKey: radius, kCIInputAngleKey: degrees * .pi / 180]) }
}
/// Radial zoom blur around a canvas point (top-left coordinates).
func zoomBlurred(_ img: CGImage, centre: CGPoint, amount: Double) -> CGImage {
    guard amount > 0.5 else { return img }
    return ci(img) { $0.clampedToExtent().applyingFilter("CIZoomBlur", parameters: [kCIInputCenterKey: CIVector(x: centre.x, y: H - centre.y), kCIInputAmountKey: amount]) }
}
func gaussianBlurred(_ img: CGImage, sigma: Double) -> CGImage {
    guard sigma > 0.3 else { return img }
    return ci(img) { $0.clampedToExtent().applyingGaussianBlur(sigma: sigma) }
}
func pixellated(_ img: CGImage, scale: Double) -> CGImage {
    guard scale > 1.5 else { return img }
    return ci(img) { $0.applyingFilter("CIPixellate", parameters: [kCIInputScaleKey: scale, kCIInputCenterKey: CIVector(x: W / 2, y: H / 2)]) }
}
/// RGB split: red pushed one way, blue the other (glitch / chromatic aberration).
func channelSplit(_ img: CGImage, dx: CGFloat, dy: CGFloat = 0) -> CGImage {
    guard abs(dx) + abs(dy) > 0.5 else { return img }
    return ci(img) { input in
        let im = input.clampedToExtent()                                  // shifted channels fill the edges with edge pixels
        func only(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> CIImage {
            im.applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: r, y: 0, z: 0, w: 0), "inputGVector": CIVector(x: 0, y: g, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: b, w: 0), "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1)])
        }
        let red = only(1, 0, 0).transformed(by: CGAffineTransform(translationX: dx, y: -dy))
        let green = only(0, 1, 0)
        let blue = only(0, 0, 1).transformed(by: CGAffineTransform(translationX: -dx, y: dy))
        return red.applyingFilter("CIAdditionCompositing", parameters: [kCIInputBackgroundImageKey: green])
            .applyingFilter("CIAdditionCompositing", parameters: [kCIInputBackgroundImageKey: blue])
    }
}
func saturated(_ img: CGImage, _ s: Double, brightness: Double = 0, contrast: Double = 1) -> CGImage {
    ci(img) { $0.applyingFilter("CIColorControls", parameters: [kCIInputSaturationKey: s, kCIInputBrightnessKey: brightness, kCIInputContrastKey: contrast]) }
}
func bloomed(_ img: CGImage, radius: Double = 18, intensity: Double = 0.7) -> CGImage {
    ci(img) { $0.clampedToExtent().applyingFilter("CIBloom", parameters: [kCIInputRadiusKey: radius, kCIInputIntensityKey: intensity]) }
}
/// Newsprint dots over the whole image.
func halftoned(_ img: CGImage, width: Double = 9, degrees: Double = 25) -> CGImage {
    // A colour print halftone (cyan, magenta, yellow and black dots), so brand colours survive.
    ci(img) { $0.applyingFilter("CICMYKHalftone", parameters: [kCIInputCenterKey: CIVector(x: W / 2, y: H / 2), kCIInputWidthKey: width,
                                                               kCIInputAngleKey: degrees * .pi / 180, kCIInputSharpnessKey: 0.7,
                                                               "inputGCR": 1, "inputUCR": 0.5]) }
}

/// Applies a look to everything drawn so far in this frame (e.g. `postProcess { halftoned($0) }`).
func postProcess(_ look: (CGImage) -> CGImage) {
    guard let snap = ctx.makeImage() else { return }
    drawImage(look(snap), in: fullCanvas())
}
