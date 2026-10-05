// motionable tool: how much does this film SOUND like the other films in the studio?
// Compares harmony (pitch-class profile), timbre (spectral shape) and groove (kick / snare / hat patterns per bar)
// of <film>/out/music.m4a against every sibling film's out/music.m4a, using each film's tempo from beats.json.
// Prints one line per film; "TOO SIMILAR" above 0.85 means viewers will hear the same track.
//
// build: swiftc -O tools/compare.swift -o <cache>/motionable-compare      usage: motionable-compare <film-dir>
import AVFoundation
import Accelerate

struct Print {
    let chroma: [Double], timbre: [Double], groove: [Double]
}

func decode(_ url: URL) -> [Float]? {
    let asset = AVURLAsset(url: url)
    guard let track = asset.tracks(withMediaType: .audio).first, let reader = try? AVAssetReader(asset: asset) else { return nil }
    let out = AVAssetReaderTrackOutput(track: track, outputSettings: [
        AVFormatIDKey: kAudioFormatLinearPCM, AVLinearPCMBitDepthKey: 32, AVLinearPCMIsFloatKey: true,
        AVLinearPCMIsNonInterleaved: false, AVNumberOfChannelsKey: 1, AVSampleRateKey: 22050])
    reader.add(out); reader.startReading()
    var s: [Float] = []
    while let buf = out.copyNextSampleBuffer(), let block = CMSampleBufferGetDataBuffer(buf) {
        let n = CMBlockBufferGetDataLength(block)
        var chunk = [Float](repeating: 0, count: n / 4)
        CMBlockBufferCopyDataBytes(block, atOffset: 0, dataLength: n, destination: &chunk)
        s += chunk
    }
    return s
}

let N = 4096, hop = 512, sr = 22050.0
let fft = vDSP.FFT(log2n: 12, radix: .radix2, ofType: DSPSplitComplex.self)!
var window = [Float](repeating: 0, count: N)
vDSP_hann_window(&window, vDSP_Length(N), Int32(vDSP_HANN_NORM))

func fingerprint(_ x: [Float], bpm: Double) -> Print {
    var mags: [[Float]] = []
    var i = 0
    while i + N < x.count {
        var frame = Array(x[i..<i + N]); vDSP.multiply(frame, window, result: &frame)
        var re = [Float](repeating: 0, count: N / 2), im = [Float](repeating: 0, count: N / 2)
        re.withUnsafeMutableBufferPointer { rp in im.withUnsafeMutableBufferPointer { ip in
            var split = DSPSplitComplex(realp: rp.baseAddress!, imagp: ip.baseAddress!)
            frame.withUnsafeBufferPointer { fp in
                fp.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: N / 2) { vDSP_ctoz($0, 2, &split, 1, vDSP_Length(N / 2)) }
            }
            fft.forward(input: split, output: &split)
            var m = [Float](repeating: 0, count: N / 2)
            vDSP_zvabs(&split, 1, &m, 1, vDSP_Length(N / 2))
            mags.append(m)
        }}
        i += hop
    }
    let binHz = sr / Double(N), fps = sr / Double(hop), barSec = 240 / bpm
    var chroma = [Double](repeating: 0, count: 12)
    let edges = (0...24).map { 60 * pow(11000.0 / 60, Double($0) / 24) }
    var timbre = [Double](repeating: 0, count: 24)
    var groove = [Double](repeating: 0, count: 48)
    var prev: [Float] = [0, 0, 0]
    for (f, m) in mags.enumerated() {
        var bands = [Double](repeating: 0, count: 24)
        var e: [Float] = [0, 0, 0]
        for b in 1..<(N / 2) {
            let hz = Double(b) * binHz, p = Double(m[b] * m[b])
            if hz >= 80 && hz <= 2000 { chroma[((Int((12 * log2(hz / 440)).rounded()) + 69) % 12 + 12) % 12] += p }
            if hz >= 60 && hz < 11000 { var k = 0; while k < 23 && hz >= edges[k + 1] { k += 1 }; bands[k] += p }
            if hz >= 30 && hz < 150 { e[0] += m[b] } else if hz < 2000 { e[1] += m[b] } else if hz < 11000 { e[2] += m[b] }
        }
        for k in 0..<24 { timbre[k] += log10(bands[k] + 1e-9) }
        let step = Int(((Double(f) / fps).truncatingRemainder(dividingBy: barSec) / barSec * 16).rounded()) % 16
        for bi in 0..<3 { let le = log1p(e[bi]); groove[bi * 16 + step] += Double(max(0, le - prev[bi])); prev[bi] = le }
    }
    let cs = max(chroma.reduce(0, +), 1e-12); chroma = chroma.map { $0 / cs }
    timbre = timbre.map { $0 / Double(max(1, mags.count)) }
    let tm = timbre.reduce(0, +) / 24; timbre = timbre.map { $0 - tm }
    for bi in 0..<3 {
        let sum = groove[(bi * 16)..<(bi * 16 + 16)].reduce(0, +)
        for k in 0..<16 { groove[bi * 16 + k] = (sum > 0 ? groove[bi * 16 + k] / sum : 0) - 1.0 / 16 }
    }
    return Print(chroma: chroma, timbre: timbre, groove: groove)
}

func cosine(_ a: [Double], _ b: [Double]) -> Double {
    let d = zip(a, b).map(*).reduce(0, +)
    let na = sqrt(a.map { $0 * $0 }.reduce(0, +)), nb = sqrt(b.map { $0 * $0 }.reduce(0, +))
    return na > 0 && nb > 0 ? d / (na * nb) : 0
}
func bpm(of film: URL) -> Double {
    guard let data = try? Data(contentsOf: film.appendingPathComponent("out/beats.json")),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let b = json["bpm"] as? Double else { return 120 }
    return b
}

guard CommandLine.arguments.count == 2 else { print("usage: motionable-compare <film-dir>"); exit(2) }
let film = URL(fileURLWithPath: CommandLine.arguments[1]).standardizedFileURL
let mine = film.appendingPathComponent("out/music.m4a")
guard let mineSamples = decode(mine) else { print("no out/music.m4a yet — run `run.sh <film> audio` first"); exit(1) }
let me = fingerprint(mineSamples, bpm: bpm(of: film))

let studio = film.deletingLastPathComponent()
let siblings = ((try? FileManager.default.contentsOfDirectory(at: studio, includingPropertiesForKeys: nil)) ?? [])
    .filter { $0.standardizedFileURL != film && FileManager.default.fileExists(atPath: $0.appendingPathComponent("out/music.m4a").path) }
    .sorted { $0.lastPathComponent < $1.lastPathComponent }
if siblings.isEmpty { print("no other films in \(studio.path) yet — nothing to compare"); exit(0) }
print("sound vs other films in the studio: harmony · timbre · groove → overall (above 0.85 = will feel the same)")
var worst = 0.0
for s in siblings {
    guard let x = decode(s.appendingPathComponent("out/music.m4a")) else { continue }
    let other = fingerprint(x, bpm: bpm(of: s))
    let h = cosine(me.chroma, other.chroma), t = max(0, cosine(me.timbre, other.timbre)), g = max(0, cosine(me.groove, other.groove))
    let overall = (h + t + g) / 3
    worst = max(worst, overall)
    print(String(format: "  %@  %.2f · %.2f · %.2f → %.2f%@", s.lastPathComponent, h, t, g, overall, overall > 0.85 ? "  TOO SIMILAR" : ""))
}
print(worst > 0.85 ? "verdict: too close to another film — change the recipe (tempo, mode, drums, instruments, colour)" : "verdict: distinct")
