// motionable engine: the Film, frame rendering, contact sheets and the MP4 (H.264 + AAC).
import AVFoundation
import CoreGraphics

/// What a project's scenes/*.swift hands the engine through `makeFilm()`.
struct Film {
    var name: String                      // output file name, without .mp4
    var width = 1080, height = 1920       // 9:16 by default; 1080×1080 or 1920×1080 work too
    var fps = 60
    var duration = 30.0
    var bpm = 120.0
    /// From here to the end nothing may move, so the last frame works as a thumbnail; the grain freezes.
    var holdFrom: Double
    /// Draws the frame at `t` into `ctx` (top-left origin). The engine adds grain afterwards.
    var draw: (_ t: Double) -> Void
    /// Fills the score: instruments and sound effects on the film's times.
    var score: (_ s: Score) -> Void
}

var film: Film!

func prepare(_ f: Film) {
    film = f
    W = CGFloat(f.width); H = CGFloat(f.height)
    NS = Int(f.duration * Double(SR))
    registerProjectFonts()
    makeGrain()
}

func drawFrame(_ t: Double, frame: Int) {
    ctx.textMatrix = .identity
    fill(CGRect(x: 0, y: 0, width: W, height: H), Col(0x000000))          // never show a reused buffer's old pixels
    film.draw(t)
    drawImage(grain[t >= film.holdFrom ? 0 : frame % grain.count], in: CGRect(x: 0, y: 0, width: W, height: H))
}

func renderImage(_ t: Double) -> CGImage {
    let c = CGContext(data: nil, width: Int(W), height: Int(H), bitsPerComponent: 8, bytesPerRow: 0, space: srgb,
                      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    c.translateBy(x: 0, y: H); c.scaleBy(x: 1, y: -1)
    ctx = c
    drawFrame(t, frame: Int(t * Double(film.fps)))
    return c.makeImage()!
}

/// One PNG of small labelled stills — how the critique loop looks at a whole film at once.
/// The default review set: 12 moments spread over the film, the middle and both edges of every join, and the last frame.
func reviewTimes() -> [Double] {
    _ = renderImage(0)                           // a film's reel is created on first use; this registers its joins
    var ts = (0..<12).map { film.duration * (Double($0) + 0.5) / 12 }
    for j in reelJoins { ts += [j.at - j.duration * 0.3, j.at, j.at + j.duration * 0.3] }
    ts.append(film.duration - 1 / Double(film.fps))
    return ts.map { ($0 * 100).rounded() / 100 }.sorted()
}

func writeSheet(_ times: [Double], to url: URL) {
    guard !times.isEmpty else { return }
    let cols = min(6, max(1, times.count))
    let cw = 270, ch = Int(270 * H / W), rows = (times.count + cols - 1) / cols
    let sheetH = rows * (ch + 36)
    let sheet = CGContext(data: nil, width: cols * cw, height: sheetH, bitsPerComponent: 8, bytesPerRow: 0,
                          space: srgb, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    sheet.setFillColor(CGColor(gray: 0.15, alpha: 1))
    sheet.fill(CGRect(x: 0, y: 0, width: cols * cw, height: sheetH))
    var images: [(Int, CGImage)] = []
    for (i, t) in times.enumerated() { images.append((i, renderImage(t))) }
    ctx = sheet
    sheet.translateBy(x: 0, y: CGFloat(sheetH)); sheet.scaleBy(x: 1, y: -1)
    sheet.textMatrix = .identity
    sheet.interpolationQuality = .high
    for (i, img) in images {
        let col = i % cols, row = i / cols
        drawImage(img, in: CGRect(x: col * cw, y: row * (ch + 36), width: cw, height: ch))
        text(String(format: "%.2f s", times[i]), 22, .semibold, Col(0xFFFFFF), CGFloat(col * cw + 8), CGFloat(row * (ch + 36) + ch + 27))
    }
    writePNG(sheet.makeImage()!, url)
}

/// Renders the film. `draft` = half size at 30 fps (about 3× faster) for internal review; the file gets a -draft suffix.
func renderVideo(to dir: URL, audio: URL, draft: Bool = false, suffix: String = "") async throws -> URL {
    let scale: CGFloat = draft ? 0.5 : 1
    let fps = draft ? min(30, film.fps) : film.fps
    let outW = Int(CGFloat(film.width) * scale) / 2 * 2, outH = Int(CGFloat(film.height) * scale) / 2 * 2
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    let silent = dir.appendingPathComponent(".video-only.mp4"), out = dir.appendingPathComponent("\(film.name)\(draft ? "-draft" : "")\(suffix).mp4")
    for u in [silent, out] { try? FileManager.default.removeItem(at: u) }
    let writer = try AVAssetWriter(outputURL: silent, fileType: .mp4)
    let pixels = Double(outW * outH)
    let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
        AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: outW, AVVideoHeightKey: outH,
        AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: Int(12_000_000 * pixels / (1080 * 1920)),
                                          AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                                          AVVideoExpectedSourceFrameRateKey: fps, AVVideoMaxKeyFrameIntervalKey: fps],
        AVVideoColorPropertiesKey: [AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
                                    AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
                                    AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2]])
    input.expectsMediaDataInRealTime = false
    let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
        kCVPixelBufferWidthKey as String: outW, kCVPixelBufferHeightKey as String: outH])
    writer.add(input)
    writer.startWriting()
    writer.startSession(atSourceTime: .zero)
    let frames = Int((film.duration * Double(fps)).rounded())
    for f in 0..<frames {
        while !input.isReadyForMoreMediaData { usleep(2000) }
        var pb: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &pb)
        let buffer = pb!
        CVPixelBufferLockBaseAddress(buffer, [])
        let c = CGContext(data: CVPixelBufferGetBaseAddress(buffer), width: outW, height: outH, bitsPerComponent: 8,
                          bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: srgb,
                          bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)!
        c.translateBy(x: 0, y: CGFloat(outH)); c.scaleBy(x: scale, y: -scale)
        ctx = c
        deviceScale = scale
        drawFrame(Double(f) / Double(fps), frame: f)
        CVPixelBufferUnlockBaseAddress(buffer, [])
        adaptor.append(buffer, withPresentationTime: CMTime(value: CMTimeValue(f), timescale: CMTimeScale(fps)))
        if f % (fps * 5) == 0 { print("frame \(f)/\(frames)") }
    }
    input.markAsFinished()
    await writer.finishWriting()
    guard writer.status == .completed else { throw writer.error ?? NSError(domain: "motionable", code: 1) }

    let comp = AVMutableComposition()
    let v = AVURLAsset(url: silent), a = AVURLAsset(url: audio)
    let vt = try await v.loadTracks(withMediaType: .video)[0], at = try await a.loadTracks(withMediaType: .audio)[0]
    let aDur = try await a.load(.duration)
    let full = CMTime(value: CMTimeValue(frames), timescale: CMTimeScale(fps))
    try comp.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
        .insertTimeRange(CMTimeRange(start: .zero, duration: full), of: vt, at: .zero)
    try comp.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
        .insertTimeRange(CMTimeRange(start: .zero, duration: CMTimeMinimum(full, aDur)), of: at, at: .zero)
    let ex = AVAssetExportSession(asset: comp, presetName: AVAssetExportPresetPassthrough)!
    try await ex.export(to: out, as: .mp4)
    try? FileManager.default.removeItem(at: silent)
    return out
}
