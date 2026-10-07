import Foundation
@main struct InspectVoiceAudio {
    static func main() {
        do {
            guard CommandLine.arguments.count == 2 else { exit(2) }
            let audio = try VoiceAudio.read(URL(fileURLWithPath: CommandLine.arguments[1]))
            let info: [String: Double] = ["duration": audio.duration,
                "peak": Double(max(audio.left.map(abs).max() ?? 0, audio.right.map(abs).max() ?? 0))]
            FileHandle.standardOutput.write(try JSONSerialization.data(withJSONObject: info, options: [.sortedKeys]))
        } catch {
            fputs("voice audio: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }
}
