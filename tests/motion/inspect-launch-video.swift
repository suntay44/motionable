// Decode portrait launch exports and verify duration, presentation cadence, audio and final stillness.
import Foundation
import AVFoundation
import CoreGraphics
precondition(CommandLine.arguments.count > 1, "pass one or more launch MP4s named with 15s or 30s")
for path in CommandLine.arguments.dropFirst() {
 let url=URL(fileURLWithPath:path),file=url.lastPathComponent
 precondition(file.contains("15s") || file.contains("30s"))
 let expected=file.contains("15s") ? 15.0 : 30.0
 let asset=AVURLAsset(url:url),duration=try await asset.load(.duration).seconds
 let videos=try await asset.loadTracks(withMediaType:.video),audio=try await asset.loadTracks(withMediaType:.audio)
 precondition(videos.count==1 && audio.count==1)
 let track=videos[0],size=try await track.load(.naturalSize),fps=try await track.load(.nominalFrameRate)
 precondition(abs(duration-expected)<0.05 && size.width==1080 && size.height==1920 && abs(fps-60)<0.01)
 let reader=try AVAssetReader(asset:asset)
 let output=AVAssetReaderTrackOutput(track:track,outputSettings:[kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32BGRA])
 reader.add(output);precondition(reader.startReading())
 var times:[Double]=[]
 while let sample=output.copyNextSampleBuffer(){times.append(CMSampleBufferGetPresentationTimeStamp(sample).seconds)}
 precondition(reader.status == .completed && times.count == Int(expected*60))
 for (i,t) in times.sorted().enumerated(){precondition(t.isFinite && abs(t-Double(i)/60)<0.001)}
 let generator=AVAssetImageGenerator(asset:asset)
 generator.requestedTimeToleranceBefore = .zero;generator.requestedTimeToleranceAfter = .zero
 func pixels(_ s:Double) async throws -> [UInt8] {
  let (img,_)=try await generator.image(at:CMTime(seconds:s,preferredTimescale:600))
  var bytes=[UInt8](repeating:0,count:180*320*4)
  let c=CGContext(data:&bytes,width:180,height:320,bitsPerComponent:8,bytesPerRow:180*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.noneSkipLast.rawValue)!
  c.draw(img,in:CGRect(x:0,y:0,width:180,height:320));return bytes
 }
 let a=try await pixels(expected-1.5),b=try await pixels(expected-0.5)
 let difference=zip(a,b).reduce(0.0){$0+abs(Double($1.0)-Double($1.1))}/Double(a.count)
 precondition(difference<0.5,"closing hold changes: \(difference)")
 print("\(file):1080×1920,60fps,\(duration)s,\(times.count)decoded frames,audio present,complete timestamps,closing difference \(difference)")
}
