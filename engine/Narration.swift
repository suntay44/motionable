// Optional narration: saved takes only. No synthesis, model loading or network in the renderer.
import AVFoundation
import CryptoKit

struct NarrationFailure: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

struct VoiceAudio {
    let left: [Float]
    let right: [Float]
    var duration: Double { Double(left.count) / 48_000 }

    static func read(_ url: URL) throws -> VoiceAudio {
        let file = try AVAudioFile(forReading: url)
        let input = file.processingFormat
        guard (1...2).contains(input.channelCount), input.sampleRate > 0,
              file.length > 0, Double(file.length) / input.sampleRate <= 600 else {
            throw NarrationFailure(message: "Narration must be nonempty mono/stereo audio, at most ten minutes.")
        }
        let target = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: input.channelCount)!
        guard let converter = AVAudioConverter(from: input, to: target),
              let source = AVAudioPCMBuffer(pcmFormat: input, frameCapacity: AVAudioFrameCount(file.length)) else {
            throw NarrationFailure(message: "Cannot decode narration format.")
        }
        try file.read(into: source)
        var fed = false, left: [Float] = [], right: [Float] = []
        while true {
            let output = AVAudioPCMBuffer(pcmFormat: target, frameCapacity: 8192)!
            var error: NSError?
            let status = converter.convert(to: output, error: &error) { _, state in
                if fed { state.pointee = .endOfStream; return nil }
                fed = true; state.pointee = .haveData; return source
            }
            if let error { throw error }
            guard status != .error else { throw NarrationFailure(message: "Audio conversion failed.") }
            if let channels = output.floatChannelData, output.frameLength > 0 {
                let count = Int(output.frameLength)
                left += Array(UnsafeBufferPointer(start: channels[0], count: count))
                right += Array(UnsafeBufferPointer(start: channels[input.channelCount == 1 ? 0 : 1], count: count))
            }
            if status == .endOfStream { break }
            guard output.frameLength > 0 else { throw NarrationFailure(message: "Audio conversion stalled.") }
        }
        guard !left.isEmpty, left.allSatisfy(\.isFinite), right.allSatisfy(\.isFinite),
              max(left.map(abs).max() ?? 0, right.map(abs).max() ?? 0) > 0.00001 else {
            throw NarrationFailure(message: "Narration is empty, silent or contains invalid samples.")
        }
        return VoiceAudio(left: left, right: right)
    }

    static func write(_ left: [Float], _ right: [Float], to url: URL) throws {
        guard left.count == right.count, !left.isEmpty else { throw NarrationFailure(message: "Invalid audio buffers.") }
        let format = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 2)!
        let temporary = url.deletingLastPathComponent().appendingPathComponent(".\(UUID().uuidString).m4a")
        defer { try? FileManager.default.removeItem(at: temporary) }
        do {
            let file = try AVAudioFile(forWriting: temporary, settings: [AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 48_000, AVNumberOfChannelsKey: 2, AVEncoderBitRateKey: 256_000],
                commonFormat: .pcmFormatFloat32, interleaved: false)
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(left.count))!
            buffer.frameLength = buffer.frameCapacity
            for i in left.indices { buffer.floatChannelData![0][i] = left[i]; buffer.floatChannelData![1][i] = right[i] }
            try file.write(from: buffer)
        }
        // POSIX rename atomically replaces a previous completed output.
        guard rename(temporary.path, url.path) == 0 else { throw NarrationFailure(message: "Cannot save \(url.lastPathComponent).") }
    }
}

struct NarrationManifest: Decodable {
    struct Phrase: Decodable {
        let id: String
        let text: String
        let start: Double
        let end: Double
    }
    let version: Int
    let audio: String
    let audioSHA256: String
    let script: String
    let scriptSHA256: String
    let duration: Double
    let offset: Double
    let gain: Double
    let duckDB: Double
    let phrases: [Phrase]
}

struct NarrationTrack {
    let manifest: NarrationManifest
    let audio: VoiceAudio

    static func hash(_ data: Data) -> String { SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined() }
    static func confined(_ path: String, project: URL) throws -> URL {
        let root = project.resolvingSymlinksInPath().standardizedFileURL
        let url = root.appendingPathComponent(path).resolvingSymlinksInPath().standardizedFileURL
        guard !path.hasPrefix("/"), url.path.hasPrefix(root.path + "/") else {
            throw NarrationFailure(message: "Narration assets must live inside the film.")
        }
        return url
    }
    static func load(_ path: String, project: URL, filmDuration: Double) throws -> NarrationTrack {
        let url = try confined(path, project: project)
        let bytes = try Data(contentsOf: url)
        let approval = try String(contentsOf: url.appendingPathExtension("approved"), encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
        guard hash(bytes) == approval else { throw NarrationFailure(message: "Narration changed since approval. Preview and approve the current take.") }
        let m = try JSONDecoder().decode(NarrationManifest.self, from: bytes)
        guard m.version == 1, m.offset.isFinite, m.offset >= 0, m.duration.isFinite, m.duration > 0,
              m.gain.isFinite, (0...2).contains(m.gain), m.duckDB.isFinite, (0...24).contains(m.duckDB),
              m.offset + m.duration <= filmDuration + 1.0 / 48_000 else {
            throw NarrationFailure(message: "Narration settings are invalid or the take runs past the film. Retime the film or revise the script.")
        }
        let audioURL = try confined(m.audio, project: project)
        guard hash(try Data(contentsOf: audioURL)) == m.audioSHA256,
              hash(try Data(contentsOf: confined(m.script, project: project))) == m.scriptSHA256 else {
            throw NarrationFailure(message: "Narration audio or script changed. Prepare and approve a new take.")
        }
        var previous = 0.0, ids = Set<String>()
        for p in m.phrases {
            guard !p.id.isEmpty, ids.insert(p.id).inserted, !p.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  p.start.isFinite, p.end.isFinite, p.start >= previous, p.end > p.start, p.end <= m.duration + 0.0001 else {
                throw NarrationFailure(message: "Narration phrase intervals must be ordered, non-overlapping and within the take.")
            }
            previous = p.end
        }
        let audio = try VoiceAudio.read(audioURL)
        guard abs(audio.duration - m.duration) < 0.03 else { throw NarrationFailure(message: "Narration duration does not match the recording.") }
        guard m.offset + audio.duration <= filmDuration + 1.0 / 48_000 else {
            throw NarrationFailure(message: "The actual recording runs past the film. Extend the cut or revise the take.")
        }
        return NarrationTrack(manifest: m, audio: audio)
    }

    /// Voice bypasses all musical effects. Duck from short-window audio levels, not caption boxes.
    func mix(bedLeft: [Float], bedRight: [Float]) -> (left: [Float], right: [Float], voiceLeft: [Float], voiceRight: [Float]) {
        let count = bedLeft.count, rate = 48_000.0, offset = Int((manifest.offset * rate).rounded())
        var voiceL = [Float](repeating: 0, count: count), voiceR = voiceL
        for i in audio.left.indices where i + offset < count {
            voiceL[i + offset] = audio.left[i] * Float(manifest.gain)
            voiceR[i + offset] = audio.right[i] * Float(manifest.gain)
        }
        // 10 ms blocks, 40 ms lookahead, 250 ms release avoid syllable-by-syllable pumping.
        let block = 480, blocks = (count + block - 1) / block
        var active = [Bool](repeating: false, count: blocks)
        for b in 0..<blocks {
            var energy: Float = 0
            for i in b * block..<min(count, (b + 1) * block) { energy += (voiceL[i] * voiceL[i] + voiceR[i] * voiceR[i]) / 2 }
            active[b] = sqrt(energy / Float(min(block, count - b * block))) > 0.004
        }
        let reduction = Float(pow(10, -manifest.duckDB / 20))
        let attack = Float(exp(-1 / (0.012 * rate))), release = Float(exp(-1 / (0.25 * rate)))
        var envelope: Float = 1, left = bedLeft, right = bedRight
        for i in 0..<count {
            let b = i / block
            let target: Float = active[b..<min(blocks, b + 5)].contains(true) ? reduction : 1
            let coefficient = target < envelope ? attack : release
            envelope = target + coefficient * (envelope - target)
            left[i] = bedLeft[i] * envelope + voiceL[i]
            right[i] = bedRight[i] * envelope + voiceR[i]
        }
        var peak: Float = 0
        for i in 0..<count {
            peak = max(peak, abs(left[i]), abs(right[i]))
            peak = max(peak, abs(voiceL[i]), abs(voiceR[i]))
        }
        // Only attenuate for headroom; no sentence normalization, coloration or saturation of speech.
        if peak > 0.89 { let gain: Float = 0.89 / peak; for i in 0..<count { left[i] *= gain; right[i] *= gain; voiceL[i] *= gain; voiceR[i] *= gain } }
        return (left, right, voiceL, voiceR)
    }

    func subtitles() -> String {
        func time(_ seconds: Double) -> String {
            let ms = Int((seconds * 1000).rounded())
            return String(format: "%02d:%02d:%02d,%03d", ms / 3_600_000, ms / 60_000 % 60, ms / 1000 % 60, ms % 1000)
        }
        return manifest.phrases.enumerated().map { i, p in
            "\(i + 1)\n\(time(p.start + manifest.offset)) --> \(time(p.end + manifest.offset))\n\(p.text.replacingOccurrences(of: "\n", with: " "))\n"
        }.joined(separator: "\n")
    }
}
