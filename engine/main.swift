// motionable — hype videos drawn in code, on macOS.
//
// Built by scripts/build.sh together with a project's scenes/*.swift, which defines `makeFilm()`.
// usage: motionable <project-dir> audio                  out/music.m4a + out/beats.json
//        motionable <project-dir> stills <t> [<t> …]     out/stills/still-<t>.png
//        motionable <project-dir> sheet <t> [<t> …]      out/sheet.png (one contact sheet)
//        motionable <project-dir> video                  out/<name>.mp4 (renders the audio too)
import Foundation

let args = CommandLine.arguments
guard args.count >= 3 else {
    print("usage: motionable <project-dir> audio|stills|sheet|video [seconds …]")
    exit(2)
}
projectDir = URL(fileURLWithPath: args[1]).standardizedFileURL
let out = projectDir.appendingPathComponent("out")
prepare(makeFilm())
let times = args.dropFirst(3).compactMap(Double.init)

switch args[2] {
case "audio":
    let s = Score(bpm: film.bpm)
    film.score(s)
    _ = try s.finish(to: out, duration: film.duration)
case "stills":
    let dir = out.appendingPathComponent("stills")
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    for t in times { writePNG(renderImage(t), dir.appendingPathComponent(String(format: "still-%.2f.png", t))) }
    print("wrote \(times.count) stills to \(dir.path)")
case "sheet":
    try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
    let url = out.appendingPathComponent("sheet.png")
    writeSheet(times, to: url)
    print("wrote \(url.path)")
case "video":
    let s = Score(bpm: film.bpm)
    film.score(s)
    let audio = try s.finish(to: out, duration: film.duration)
    let start = Date()
    let url = try await renderVideo(to: out, audio: audio)
    print(String(format: "wrote %@ in %.0f s", url.path, Date().timeIntervalSince(start)))
default:
    print("unknown mode \(args[2])")
    exit(2)
}
