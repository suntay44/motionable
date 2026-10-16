// Decoded export validation for the maintained 15-second Owly craft benchmark.
// Run with scripts/test-craft.sh after rendering both sizes.
import Foundation
import AVFoundation
import CoreGraphics

let root = URL(fileURLWithPath: CommandLine.arguments[1])
for (file, fps, width, height) in [("owly-craft.mp4", 60, 1920, 1080), ("owly-craft-draft.mp4", 30, 960, 540)] {
    let asset = AVURLAsset(url: root.appendingPathComponent(file))
    let duration = try await asset.load(.duration).seconds
    let tracks = try await asset.loadTracks(withMediaType: .video)
    let audio = try await asset.loadTracks(withMediaType: .audio)
    precondition(tracks.count == 1 && audio.count == 1)
    let track = tracks[0]
    let size = try await track.load(.naturalSize), rate = try await track.load(.nominalFrameRate)
    precondition(abs(duration-15) < 0.05 && size.width == CGFloat(width) && size.height == CGFloat(height) && abs(Double(rate)-Double(fps)) < 0.01)
    let reader = try AVAssetReader(asset: asset)
    let output = AVAssetReaderTrackOutput(track: track, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA])
    reader.add(output); precondition(reader.startReading())
    var timestamps: [Double] = []
    while let sample = output.copyNextSampleBuffer() {
        let time = CMSampleBufferGetPresentationTimeStamp(sample).seconds
        precondition(time.isFinite && time >= 0); timestamps.append(time)
    }
    let count = timestamps.count
    precondition(reader.status == .completed && count == 15*fps)
    // Inspect decoded display frames; compressed packets may contain preroll and reordered samples.
    for (i, time) in timestamps.sorted().enumerated() { precondition(abs(time-Double(i)/Double(fps)) < 0.001) }
    let generator = AVAssetImageGenerator(asset: asset)
    generator.requestedTimeToleranceBefore = .zero; generator.requestedTimeToleranceAfter = .zero
    func pixels(_ seconds: Double) async throws -> [UInt8] {
        let (img, _) = try await generator.image(at: CMTime(seconds: seconds, preferredTimescale: 600))
        var bytes = [UInt8](repeating: 0, count: 320*180*4)
        let c = CGContext(data: &bytes, width: 320, height: 180, bitsPerComponent: 8, bytesPerRow: 320*4,
                          space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
        c.draw(img, in: CGRect(x: 0, y: 0, width: 320, height: 180))
        return bytes
    }
    let a = try await pixels(13.5), b = try await pixels(14.5)
    let error = zip(a,b).reduce(0.0) { $0 + abs(Double($1.0)-Double($1.1)) } / Double(a.count)
    precondition(error < 0.5, "encoded final hold changes: \(error)")
    print("\(file): \(width)x\(height), \(fps) fps, \(count) frames, \(duration)s, audio present, complete presentation timestamps, final hold delta \(error)")
}
