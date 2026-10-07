import Foundation
import AVFoundation

let root = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: root.appendingPathComponent("assets/voice"), withIntermediateDirectories: true)
func require(_ condition: Bool, _ message: String) { precondition(condition, message) }
func rejects(_ message: String, _ action: () throws -> Void) {
    do { try action(); fatalError("accepted \(message)") } catch { print("✓ rejected \(message)") }
}
let source = root.appendingPathComponent("assets/voice/source.wav")
// 44.1 kHz mono recording, with speech-like energy only in the middle.
let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
do {
    let file = try AVAudioFile(forWriting: source, settings: format.settings)
    let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 88_200)!
    buffer.frameLength = buffer.frameCapacity
    for i in 0..<88_200 {
        buffer.floatChannelData![0][i] = (22_050..<66_150).contains(i) ? 0.1 * sin(Float(i) * 0.045) : 0
    }
    try file.write(from: buffer)
}
let decoded = try VoiceAudio.read(source)
require(abs(decoded.duration - 2) < 0.01 && decoded.left == decoded.right, "mono 44.1 kHz must convert to centered 48 kHz")
let stereoURL = root.appendingPathComponent("stereo.wav")
do {
    let stereoFormat = AVAudioFormat(standardFormatWithSampleRate: 24_000, channels: 2)!
    let file = try AVAudioFile(forWriting: stereoURL, settings: stereoFormat.settings)
    let buffer = AVAudioPCMBuffer(pcmFormat: stereoFormat, frameCapacity: 24_000)!
    buffer.frameLength = buffer.frameCapacity
    for i in 0..<24_000 {
        buffer.floatChannelData![0][i] = 0.1 * sin(Float(i) * 0.04)
        buffer.floatChannelData![1][i] = -buffer.floatChannelData![0][i]
    }
    try file.write(from: buffer)
}
let stereo = try VoiceAudio.read(stereoURL)
require(zip(stereo.left, stereo.right).allSatisfy { abs($0 + $1) < 0.0001 }, "stereo channels must stay distinct after resampling")
let script = root.appendingPathComponent("assets/voice/script.json")
try "{\"phrases\":[{\"id\":\"one\",\"text\":\"Hello there.\"}]}".write(to: script, atomically: true, encoding: .utf8)
let manifestURL = root.appendingPathComponent("assets/voice/narration.json")
var object: [String: Any] = ["version": 1, "audio": "assets/voice/source.wav", "audioSHA256": NarrationTrack.hash(try Data(contentsOf: source)),
    "script": "assets/voice/script.json", "scriptSHA256": NarrationTrack.hash(try Data(contentsOf: script)),
    "duration": decoded.duration, "offset": 0.5, "gain": 1.0, "duckDB": 8.0,
    "phrases": [["id": "one", "text": "Hello there.", "start": 0.5, "end": 1.5]]]
func save(_ object: [String: Any], approve: Bool = true) throws {
    let data = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    try data.write(to: manifestURL)
    if approve { try NarrationTrack.hash(data).write(to: manifestURL.appendingPathExtension("approved"), atomically: true, encoding: .utf8) }
}
try save(object)
let track = try NarrationTrack.load("assets/voice/narration.json", project: root, filmDuration: 4)
require(track.subtitles().contains("00:00:01,000 --> 00:00:02,000"), "caption offset must follow audio placement")
let bed = [Float](repeating: 0.15, count: 192_000)
let mixed = track.mix(bedLeft: bed, bedRight: bed)
require(abs(mixed.left[1000] - 0.15) < 0.0001, "no duck long before speech")
let during = 60_000
require(mixed.left[during] - mixed.voiceLeft[during] < 0.08, "bed must duck under active voice")
require(mixed.left[180_000] > 0.14, "bed must recover after voice")
require(mixed.voiceLeft[48_000] == decoded.left[24_000], "voice must preserve seconds-based samples")
rejects("take beyond cut") { _ = try NarrationTrack.load("assets/voice/narration.json", project: root, filmDuration: 1) }
var shortDuration = object; shortDuration["duration"] = decoded.duration - 0.02; try save(shortDuration)
rejects("actual audio beyond cut despite rounded metadata") {
    _ = try NarrationTrack.load("assets/voice/narration.json", project: root, filmDuration: decoded.duration + 0.49)
}
var bad = object; bad["offset"] = -1.0; try save(bad)
rejects("negative placement") { _ = try NarrationTrack.load("assets/voice/narration.json", project: root, filmDuration: 4) }
bad = object; bad["audio"] = "../outside.wav"; try save(bad)
rejects("escaping asset path") { _ = try NarrationTrack.load("assets/voice/narration.json", project: root, filmDuration: 4) }
bad = object; bad["phrases"] = [["id": "one", "text": "oops", "start": 1.8, "end": 3.0]]; try save(bad)
rejects("caption past take") { _ = try NarrationTrack.load("assets/voice/narration.json", project: root, filmDuration: 4) }
try save(object); bad = object; bad["gain"] = 0.5; try save(bad, approve: false)
rejects("unapproved manifest edit") { _ = try NarrationTrack.load("assets/voice/narration.json", project: root, filmDuration: 4) }
try save(object)
let originalAudio = try Data(contentsOf: source)
try Data("broken audio".utf8).write(to: source)
rejects("changed audio hash") { _ = try NarrationTrack.load("assets/voice/narration.json", project: root, filmDuration: 4) }
try originalAudio.write(to: source)
try "changed words".write(to: script, atomically: true, encoding: .utf8)
rejects("stale script") { _ = try NarrationTrack.load("assets/voice/narration.json", project: root, filmDuration: 4) }

// Same bed with/without voice: adding narration must not alter compare's music file.
NS = 192_000
tempoMap = TempoMap(100)
func score(_ narrated: Bool, effects: Bool = false) -> Score {
    let score = Score(bpm: 100)
    score.music.add((0..<NS).map { 0.1 * sin(Float($0) * 0.02) }, at: 0, gain: 1)
    score.colour = .clean
    score.stops = [(1, 1.5)]
    score.muffled = [(1.5, 2.0)]
    score.effectsOnly = effects
    score.narration = narrated ? track : nil
    return score
}
let plain = root.appendingPathComponent("plain"), narrated = root.appendingPathComponent("narrated")
_ = try score(false).finish(to: plain, duration: 4)
let final = try score(true).finish(to: narrated, duration: 4)
require(final.lastPathComponent == "mix.m4a", "narrated renderer must select mix")
let baseline = try VoiceAudio.read(plain.appendingPathComponent("music.m4a"))
let unchanged = try VoiceAudio.read(narrated.appendingPathComponent("music.m4a"))
require(baseline.left == unchanged.left && baseline.right == unchanged.right, "unducked bed must remain sample-identical")
let output = try VoiceAudio.read(final)
require(output.left.allSatisfy(\.isFinite) && (output.left.map(abs).max() ?? 2) < 1, "encoded mix must not clip")
let effectsURL = try score(true, effects: true).finish(to: root.appendingPathComponent("effects"), duration: 4)
require(effectsURL.lastPathComponent == "effects.m4a", "effects-only must bypass narration")
// Silence is expected in effects-only; inspect with AVAudioFile rather than the voice importer.
let effectsFile = try AVAudioFile(forReading: effectsURL)
let effectsBuffer = AVAudioPCMBuffer(pcmFormat: effectsFile.processingFormat, frameCapacity: AVAudioFrameCount(effectsFile.length))!
try effectsFile.read(into: effectsBuffer)
require((0..<Int(effectsBuffer.frameLength)).allSatisfy { abs(effectsBuffer.floatChannelData![0][$0]) < 0.0001 }, "effects-only must contain no speech/music")
print("narration: resampling, centered mono, approval/hash/timing validation, ducking, captions, clipping, unchanged bed and effects-only passed")
