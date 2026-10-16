// Build a silent README preview from a locally rendered film, using system media frameworks.
import Foundation
import AVFoundation
import ImageIO
import UniformTypeIdentifiers
precondition(CommandLine.arguments.count==3,"usage: swift make-demo-gif.swift input.mp4 output.gif")
let asset=AVURLAsset(url:URL(fileURLWithPath:CommandLine.arguments[1]))
let duration=try await asset.load(.duration).seconds
let generator=AVAssetImageGenerator(asset:asset)
generator.appliesPreferredTrackTransform=true;generator.maximumSize=CGSize(width:270,height:480)
generator.requestedTimeToleranceBefore = .zero;generator.requestedTimeToleranceAfter = .zero
let count=Int(ceil(duration*4))
let output=URL(fileURLWithPath:CommandLine.arguments[2])
let dest=CGImageDestinationCreateWithURL(output as CFURL,UTType.gif.identifier as CFString,count,nil)!
CGImageDestinationSetProperties(dest,[kCGImagePropertyGIFDictionary:[kCGImagePropertyGIFLoopCount:0]] as CFDictionary)
for i in 0..<count {
 let (image,_)=try await generator.image(at:CMTime(seconds:Double(i)/4,preferredTimescale:600))
 CGImageDestinationAddImage(dest,image,[kCGImagePropertyGIFDictionary:[kCGImagePropertyGIFDelayTime:0.25]] as CFDictionary)
}
precondition(CGImageDestinationFinalize(dest));print("wrote \(output.path)")
