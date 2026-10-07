// Focused regressions for playback, sparse footage, typography, motion and tempo.
// Built by scripts/regression.sh against the real engine (without its CLI entry point).
import AppKit
import AVFoundation

func near(_ actual: Double, _ expected: Double, _ message: String) {
    precondition(abs(actual - expected) < 1e-7, "\(message): \(actual) != \(expected)")
}

let linear = Playback([(0, 0), (1, 1), (2, 4)], ramps: false)
near(linear.at(0.5), 0.5, "ramps:false must use constant speed within each segment")
near(linear.at(1.5), 2.5, "second linear segment")
near(linear.filmTime(of: 3004), 1002, "inverse playback must extrapolate beyond 600 seconds")
let frozen = Playback([(0, 0), (1, 2), (2, 2)])
near(frozen.filmTime(of: 2), 1, "inverse freeze returns its first moment")
precondition(frozen.filmTime(of: 3).isInfinite, "unreachable events must not invent a film time")
precondition(Playback([(0, 2)]).filmTime(of: 3).isInfinite)
let smooth = Playback([(0, 0), (1, 4), (2, 4), (3, 5)])
var previous = -Double.infinity
for i in 0...300 {
    let t = Double(i) / 100, s = smooth.at(t)
    precondition(s >= previous - 1e-9, "speed ramps must never rewind")
    if t >= 1 && t <= 2 { near(s, 4, "freeze must hold") }
    previous = s
}
let region = CGRect(x: 10, y: 20, width: 50, height: 60)
precondition(Zoom([(0, region)]).region(5) == region, "one camera key must hold")

let tempo = TempoMap(120, [.at(beat: 4, bpm: 90), .ramp(from: 8, to: 12, bpm: 60)])
near(tempo.time(ofBeat: 4), 2, "tempo boundary")
for i in 0...160 {
    let beat = Double(i) / 8
    near(tempo.beat(at: tempo.time(ofBeat: beat)), beat, "tempo map round trip")
}
// A recipe without film tempo phases must choose the same hit chord regardless of the global map.
NS = SR * 4
let recipe = Recipe(bpm: 60, progression: [1, 2], meter: 12)
tempoMap = TempoMap(60)
let matching = Score(bpm: 60)
matching.hit(recipe, at: 3.2, crashToo: false)
tempoMap = TempoMap(120)
let different = Score(bpm: 60)
different.hit(recipe, at: 3.2, crashToo: false)
precondition(matching.music.l == different.music.l, "hits must follow the recipe tempo without film phases")
let face = Face.named("Georgia")
glyphCache.removeAll()
let upright = glyphs("Italic", 72, face)
let italic = glyphs("Italic", 72, face.italic)
precondition(glyphCache.count == 2, "italic and upright glyphs need distinct cache entries")
precondition(upright.glyphs[0].path != italic.glyphs[0].path, "italic outlines must differ")

ctx = CGContext(data: nil, width: 320, height: 240, bitsPerComponent: 8, bytesPerRow: 0,
                space: srgb, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
textLog = TextLog()
var drew = false
show(CGRect(x: 0, y: 0, width: 100, height: 100), t: 0, from: 0, until: 2, enter: .cut, exit: .cut) {
    drew = true
    precondition(textLog?.muted == 0, "cut entrance must be readable immediately")
}
precondition(drew, "cut entrance must draw on the first frame")
drew = false
show(CGRect(x: 0, y: 0, width: 100, height: 100), t: 2, from: 0, until: 2, enter: .cut, exit: .cut) { drew = true }
precondition(!drew, "cut exit must disappear at its endpoint")
textLog = nil

// A settled rise mask must not shave the tops off enlarged accents.
func styledBitmap(_ entrance: TextIn) -> Data {
    ctx = CGContext(data: nil, width: 320, height: 240, bitsPerComponent: 8, bytesPerRow: 0,
                    space: srgb, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    ctx.translateBy(x: 0, y: 240); ctx.scaleBy(x: 1, y: -1)
    ctx.textMatrix = .identity
    fill(CGRect(x: 0, y: 0, width: 320, height: 240), Col(0xFFFFFF))
    Kinetic(lines: ["*HI*"], face: .system(.heavy), size: 100, colour: Col(0), x: 20, y: 170,
            from: 0, enter: entrance, exit: .none, maxWidth: nil, accent: TextStyle(scale: 1.6)).draw(2)
    return Data(bytes: ctx.data!, count: ctx.bytesPerRow * ctx.height)
}
precondition(styledBitmap(.rise) == styledBitmap(.none), "settled rise must preserve enlarged glyphs")

// Three frames separated by long holds, stored sideways like a rotated phone capture.
let directory = URL(fileURLWithPath: CommandLine.arguments[1])
let fixture = directory.appendingPathComponent("sparse.mov")
let writer = try AVAssetWriter(outputURL: fixture, fileType: .mov)
let input = AVAssetWriterInput(mediaType: .video, outputSettings: [AVVideoCodecKey: AVVideoCodecType.h264,
    AVVideoWidthKey: 96, AVVideoHeightKey: 64])
input.transform = CGAffineTransform(a: 0, b: 1, c: -1, d: 0, tx: 64, ty: 0)
let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
    kCVPixelBufferWidthKey as String: 96, kCVPixelBufferHeightKey as String: 64,
    kCVPixelBufferCGImageCompatibilityKey as String: true, kCVPixelBufferCGBitmapContextCompatibilityKey as String: true])
writer.add(input)
precondition(writer.startWriting())
writer.startSession(atSourceTime: .zero)
for (i, color) in [NSColor.red, NSColor.green, NSColor.blue].enumerated() {
    while !input.isReadyForMoreMediaData { try await Task.sleep(nanoseconds: 1_000_000) }
    var buffer: CVPixelBuffer?
    precondition(CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &buffer) == kCVReturnSuccess)
    let pb = buffer!
    CVPixelBufferLockBaseAddress(pb, [])
    let c = CGContext(data: CVPixelBufferGetBaseAddress(pb), width: 96, height: 64, bitsPerComponent: 8,
        bytesPerRow: CVPixelBufferGetBytesPerRow(pb), space: srgb, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)!
    c.setFillColor(color.cgColor); c.fill(CGRect(x: 0, y: 0, width: 96, height: 64))
    CVPixelBufferUnlockBaseAddress(pb, [])
    precondition(adaptor.append(pb, withPresentationTime: CMTime(seconds: Double(i * 2), preferredTimescale: 600)))
}
writer.endSession(atSourceTime: CMTime(seconds: 6, preferredTimescale: 600))
input.markAsFinished()
await writer.finishWriting()
precondition(writer.status == .completed, "fixture failed: \(String(describing: writer.error))")

func dominant(_ image: CGImage) -> Int {
    var pixel = [UInt8](repeating: 0, count: 4)
    let c = CGContext(data: &pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                      space: srgb, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    c.draw(image, in: CGRect(x: 0, y: 0, width: 1, height: 1))
    return (0..<3).max { pixel[$0] < pixel[$1] }!
}
let footage = Footage(fixture.path)
precondition(footage.size == CGSize(width: 64, height: 96), "rotated footage must be upright")
for (time, expected) in [(1.5, 0), (3.5, 1), (5.5, 2), (0.5, 0), (3.5, 1)] {
    guard let image = footage.frame(at: time) else { fatalError("missing frame at \(time)") }
    precondition(dominant(image) == expected, "wrong held frame at \(time)")
}
// Use the separately compiled CLI too: checks its full-resolution orientation and sparse seek path.
let command = Process()
command.executableURL = URL(fileURLWithPath: CommandLine.arguments[2])
let frame = directory.appendingPathComponent("frame.png")
command.arguments = [fixture.path, "frame", "1.5", frame.path]
try command.run(); command.waitUntilExit()
precondition(command.terminationStatus == 0)
let image = CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(frame as CFURL, nil)!, 0, nil)!
precondition(image.width == 64 && image.height == 96, "frame extraction must retain full rotated resolution")
precondition(dominant(image) == 0, "CLI must return the held frame, not a future frame")
print("regressions: playback, tempo, italic cache, cut motion, sparse and rotated footage passed")
