// motionable test: a film with every layout mistake the audit must catch. `scripts/test.sh` expects `check` to fail it
// with each finding below. Don't fix it: it tests the checker, not the film.
import AppKit

func makeFilm() -> Film {
    Film(name: "audit", width: 1080, height: 1920, fps: 30, duration: 10, bpm: 120, holdFrom: 10, draw: frame, score: { _ in })
}
let ink = Col(0x1D1D1F), paper = Col(0xF4F1EA), head = Face.system(.heavy)
let ui = Screenshot("assets/fake-ui.png")

func sceneA(_ t: Double) {
    fill(fullCanvas(), paper)
    // 1. Two settled headlines on top of each other.
    Kinetic(lines: ["Overlapping words"], face: head, size: 90, colour: ink, x: 120, y: 420, from: 0, enter: .none, exit: .none).draw(t)
    Kinetic(lines: ["Collide right here"], face: head, size: 90, colour: Col(0xC0392B), x: 160, y: 450, from: 0, enter: .none, exit: .none).draw(t)
    // 2. A line running off the right edge of the frame.
    text("This sentence runs right off the edge of the frame", 70, Face.system(.bold), ink, 200, 640)
    // 3. A line overflowing the card that clips it.
    let card = CGRect(x: 120, y: 760, width: 420, height: 160)
    fill(rr(card, 24), Col(0xFFFFFF))
    ctx.saveGState(); ctx.addPath(rr(card, 24)); ctx.clip()
    text("Too long for its card", 64, Face.system(.bold), ink, 150, 860)
    ctx.restoreGState()
    // 4. A crop of a screen that slices through its rows of text.
    drawScreen(ui, region: CGRect(x: 0, y: 300, width: 600, height: 470), in: CGRect(x: 120, y: 1000, width: 840, height: 660), snap: false)
    // 5. A finger resting on a line people need to read.
    text("Read this line", 80, Face.system(.bold), ink, 560, 1820 - 80)
    if t > 2 && t < 3.5 { fill(CGPath(ellipseIn: centred(CGPoint(x: 700, y: 1712), 70), transform: nil), Col(0x444444)) }
}
func sceneB(_ t: Double) {
    fill(fullCanvas(), paper)
    // 6. Headlines at different left margins, and 7. a frame that is mostly empty for a long time.
    Kinetic(lines: ["Margin one"], face: head, size: 90, colour: ink, x: 60, y: 300, from: 0, enter: .none, exit: .none).draw(t)
    Kinetic(lines: ["Margin two"], face: head, size: 90, colour: ink, x: 260, y: 460, from: 0, enter: .none, exit: .none).draw(t)
    Kinetic(lines: ["Margin three"], face: head, size: 90, colour: ink, x: 460, y: 620, from: 0, enter: .none, exit: .none).draw(t)
}
// 8. A dissolve between two scenes whose headlines sit in the same place.
let reel = Reel([Clip(from: 0, to: 5, draw: sceneA), Clip(from: 5, to: 10, draw: sceneB)], joins: [(.dissolve, 0.8)])
func frame(_ t: Double) { reel.draw(t) }
