import AppKit
import AVFoundation

func near(_ a: Double, _ b: Double, tolerance: Double = 1e-6) { precondition(abs(a-b) < tolerance, "\(a) != \(b)") }
for curve in [MotionCurve.linear, .easeIn, .easeOut, .easeInOut, .bezier(0.22, 1, 0.36, 1), .spring(response: 0.45, damping: 0.8), .spring(response: 0.4, damping: 1)] {
    near(curve.value(-1), 0); near(curve.value(2), 1)
    precondition((0...1000).allSatisfy { curve.value(Double($0)/1000).isFinite })
}
for x in [0.01, 0.1, 0.5, 0.8, 0.99] { near(MotionCurve.bezier(0, 0, 1, 1).value(x), x) }
let editorial = MotionCurve.bezier(0.22, 1, 0.36, 1)
precondition(editorial.value(0.25) > 0.7, "Bezier must solve elapsed x, not use x as the parameter")
let spring = MotionCurve.spring(response: 0.45, damping: 0.8)
near((1-spring.value(0.999999))/0.000001, 0, tolerance: 0.001)
let path = MotionPath([.init(time: 0, point: .zero), .init(time: 1, point: CGPoint(x: 100, y: 50), velocity: CGPoint(x: 60, y: 20)), .init(time: 2, point: CGPoint(x: 180, y: 80))])
precondition(path.position(-1) == .zero && path.position(3) == CGPoint(x: 180, y: 80))
let eps = 0.000001, before = path.position(1-eps), middle = path.position(1), after = path.position(1+eps)
near(Double((middle.x-before.x)/eps), 60, tolerance: 0.001)
near(Double((after.x-middle.x)/eps), 60, tolerance: 0.001)
near(Double((after.y-middle.y)/eps), 20, tolerance: 0.001)
near(Double(path.position(eps).x/eps), 0, tolerance: 0.001)
let shared = SharedElement(from: CGRect(x: 0, y: 0, width: 10, height: 20), to: CGRect(x: 100, y: 200, width: 30, height: 40), start: 1, end: 2)
precondition(shared.rect(at: 0) == shared.from && shared.rect(at: 3) == shared.to)
near(Double(shared.rect(at: 1.5).midX), 60)
textLog = TextLog()
shared.draw(1.5) { _ in precondition(textLog!.muted == 1) }
shared.draw(2) { _ in precondition(textLog!.muted == 0) }
textLog = nil

// Averaging moving opaque pixels must preserve total coverage, not darken or favor the last sample.
W = 64; H = 32; deviceScale = 1
func canvas() -> CGContext {
    let c = CGContext(data: nil, width: 64, height: 32, bitsPerComponent: 8, bytesPerRow: 256, space: srgb,
                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    c.translateBy(x: 0, y: 32); c.scaleBy(x: 1, y: -1); return c
}
ctx = canvas()
let target = ctx!
var sampled: [Double] = []
temporalLayer(t: 0.5, fps: 10, shutter: 1, samples: 4, moving: 0...1) { t in
    sampled.append(t)
    fill(CGRect(x: Int(t*80), y: 8, width: 2, height: 2), Col(0xFFFFFF))
}
precondition(ctx === target && deviceScale == 1)
precondition(sampled.count == 4)
near(sampled[0], 0.4625); near(sampled[3], 0.5375)
let bytes = ctx.data!.assumingMemoryBound(to: UInt8.self)
let coverage = stride(from: 3, to: 64*32*4, by: 4).reduce(0) { $0 + Int(bytes[$1]) }
precondition(abs(coverage - 4*255) <= 16, "premultiplied temporal average must preserve pixel coverage")
let occupied = stride(from: 3, to: 64*32*4, by: 4).filter { bytes[$0] > 0 }.count
precondition(occupied > 4, "temporal samples must leave a real trail")
for t in [0.0, 1.0, 1.5] {
    sampled.removeAll(); ctx = canvas()
    temporalLayer(t: t, moving: 0...1) { sampled.append($0) }
    precondition(sampled == [t], "holds and boundaries must draw sharply once")
}
textLog = TextLog(); layoutLog = LayoutLog(); sampled.removeAll()
temporalLayer(t: 0.5, moving: 0...1) { sampled.append($0) }
precondition(sampled == [0.5], "audits must observe only the nominal frame")
textLog = nil; layoutLog = nil
// The default shutter follows the real export cadence, including a 30 fps draft.
renderFPS = 30; sampled.removeAll(); ctx = canvas()
temporalLayer(t: 0.5, shutter: 1, samples: 2, moving: 0...1) { sampled.append($0) }
near(sampled[0], 0.5-1.0/120); near(sampled[1], 0.5+1.0/120)
renderFPS = 60
func entrancePixels(_ curve: MotionCurve?, entering: Bool) -> Data {
    ctx = canvas()
    appearing(.zoom, visible: 0.5, entering: entering, CGRect(x: 8, y: 8, width: 16, height: 16), curve: curve) {
        fill(CGRect(x: 8, y: 8, width: 16, height: 16), Col(0xFFFFFF))
    }
    return Data(bytes: ctx.data!, count: 256*32)
}
precondition(entrancePixels(nil, entering: true) == entrancePixels(.easeOut, entering: true), "legacy entry curve changed")
precondition(entrancePixels(nil, entering: false) == entrancePixels(.easeIn, entering: false), "legacy exit curve changed")
precondition(entrancePixels(.linear, entering: true) != entrancePixels(.easeOut, entering: true), "curve override must affect rendering")
let windows = motionReviewWindows([0, 1, 1, 10, .nan], duration: 2, fps: 60)
precondition(windows.count == 3)
for ts in windows {
    precondition(ts.count > 1 && ts.count <= 13 && ts == ts.sorted())
    precondition(ts.allSatisfy { $0 >= 0 && $0 < 2 && abs($0*60-($0*60).rounded()) < 1e-7 })
}
print("motion: curves, velocity continuity, shared bounds, temporal coverage, sharp holds, audit isolation and review timestamps passed")

// A moving-camera advisory must not downgrade a later invalid settled crop of the same source.
let cropCanvas = CGContext(data: nil, width: 64, height: 64, bitsPerComponent: 8, bytesPerRow: 256, space: srgb,
                           bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
for y in stride(from: 0, to: 64, by: 4) { for x in stride(from: 0, to: 64, by: 4) {
    cropCanvas.setFillColor(CGColor(gray: (x/4+y/4)%2 == 0 ? 0 : 1, alpha: 1))
    cropCanvas.fill(CGRect(x: x, y: y, width: 4, height: 4))
} }
let cropImage = cropCanvas.makeImage()!
layoutLog = LayoutLog()
let badCrop = CGRect(x: 8, y: 8, width: 48, height: 48)
noteCrop("camera-fixture", image: cropImage, region: badCrop, camera: true)
noteCrop("camera-fixture", image: cropImage, region: badCrop, camera: false)
precondition(layoutLog!.slices.values.contains { $0.camera })
precondition(layoutLog!.slices.values.contains { !$0.camera }, "fixed crop failure was downgraded by a camera advisory")
layoutLog = nil
print("motion: camera advisories and settled crop failures remain separate")

// A failed re-render must preserve a user's previous export; a successful one replaces it.
let work = FileManager.default.temporaryDirectory.appendingPathComponent("motionable-export-" + UUID().uuidString)
try FileManager.default.createDirectory(at: work, withIntermediateDirectories: true)
defer { try? FileManager.default.removeItem(at: work) }
projectDir = work
prepare(Film(name: "preserved", width: 64, height: 64, fps: 12, duration: 0.5, holdFrom: 0,
             draw: { _ in fill(fullCanvas(), Col(0x123456)) }, score: { _ in }))
let exportURL = work.appendingPathComponent("preserved.mp4"), previous = Data("previous user export".utf8)
try previous.write(to: exportURL)
var failed = false
do { _ = try await renderVideo(to: work, audio: work.appendingPathComponent("missing.m4a")) }
catch { failed = true }
precondition(failed)
let afterFailure = try Data(contentsOf: exportURL)
precondition(afterFailure == previous, "failed render destroyed previous export")
let remainingFiles = try FileManager.default.contentsOfDirectory(atPath: work.path)
precondition(remainingFiles.allSatisfy { !$0.hasPrefix(".") })
let tinyScore = Score(bpm: 120)
let tinyAudio = try tinyScore.finish(to: work, duration: 0.5)
_ = try await renderVideo(to: work, audio: tinyAudio)
let afterSuccess = try Data(contentsOf: exportURL)
precondition(afterSuccess != previous)
let tinyAsset = AVURLAsset(url: exportURL)
let tinyDuration = try await tinyAsset.load(.duration).seconds
let tinyTracks = try await tinyAsset.loadTracks(withMediaType: .video)
near(tinyDuration, 0.5, tolerance: 0.01)
precondition(tinyTracks.count == 1)
print("render: failure preserves previous export, success replaces it and temporary files are cleaned")
