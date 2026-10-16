// Review artifacts expose timing; they do not automatically certify visual quality.
import Foundation

func motionReviewWindows(_ centers: [Double], duration: Double, fps: Int) -> [[Double]] {
    precondition(duration.isFinite && duration > 0 && fps > 0)
    let last = max(0, duration - 1/Double(fps))
    let valid = centers.filter(\.isFinite).map { clamp($0, 0, last) }
    return Array(Set(valid)).sorted().map { center in
        let start = max(0, center - 0.3), end = min(last, center + 0.3)
        let first = Int(ceil(start * Double(fps))), final = Int(floor(end * Double(fps)))
        guard final >= first else { return [center] }
        let step = max(1, Int(ceil(Double(final-first)/11)))
        var times = stride(from: first, through: final, by: step).map { Double($0)/Double(fps) }
        if times.last != Double(final)/Double(fps) { times.append(Double(final)/Double(fps)) }
        return times
    }
}

func writeMotionReview(_ requested: [Double], to dir: URL) throws {
    _ = renderImage(0) // registers lazy reels
    var centers = requested
    if centers.isEmpty {
        centers = film.motionMoments + reelJoins.map(\.at) + film.keyframes + [0, film.holdFrom]
    }
    let windows = motionReviewWindows(centers, duration: film.duration, fps: film.fps)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    for (i, times) in windows.enumerated() {
        writeSheet(times, to: dir.appendingPathComponent(String(format: "sequence-%02d.png", i+1)))
    }
    let report: [String: Any] = ["film": film.name, "fps": film.fps, "duration": film.duration,
        "windows": windows, "assessment": "pending visual playback review",
        "inspect": ["attention and pauses", "acceleration and settling", "continuity across joins", "text reading time", "voice and sound timing", "sharp final hold"]]
    try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
        .write(to: dir.appendingPathComponent("review.json"))
    print("wrote \(windows.count) motion sequences to \(dir.path); inspect playback before judging motion quality")
}
