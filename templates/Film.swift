// {{PRODUCT}} — hype film, built on the motionable engine.
// This starter renders as-is (a 15-second, 9:16 film: hook → three promises → end card), so
// there is always a working video. Replace the scenes beat by beat from SCRIPT.md; keep every
// time in `T` so picture and sound stay together. Engine reference: ENGINE.md in the plugin.
import AppKit

func makeFilm() -> Film {
    Film(name: "{{SLUG}}-hype", width: 1080, height: 1920, fps: 60, duration: 15, bpm: 120,
         holdFrom: T.still, draw: frame, score: score)
}

// MARK: - Timeline (120 BPM: a beat is 0.5 s, a bar 2 s)

enum T {
    static let hook = [0.0, 0.25, 0.5]            // three words stamp in
    static let promises = [2.0, 5.0, 8.0]         // one headline per bar-and-a-half
    static let toEnd = 11.0                       // brand colour floods back
    static let endLines = [11.5, 11.75, 12.0]
    static let still = 13.0                       // nothing moves from here
}

// MARK: - Palette (replace with the product's real colours)

let brand = Col(0x2F6FE0), brandDeep = Col(0x1D4FB0)
let paper = Col(0xF6F3E8), ink = Col(0x111827), white = Col(0xFFFFFF)

/// assets/logo.png if the project has one.
let logo: CGImage? = FileManager.default.fileExists(atPath: projectDir.appendingPathComponent("assets/logo.png").path)
    ? loadImage("assets/logo.png") : nil

// MARK: - Words

let hookWords = ["Say", "hello to", "{{PRODUCT}}."]
let promises: [Headline] = [
    Headline(from: T.promises[0], to: T.promises[1], lines: ["The first", "big promise."], sub: ["One line that proves it."], colour: ink),
    Headline(from: T.promises[1], to: T.promises[2], lines: ["The second", "big promise."], sub: ["One line that proves it."], colour: ink),
    Headline(from: T.promises[2], to: T.toEnd, lines: ["The third", "big promise."], sub: ["One line that proves it."], colour: ink)]

// MARK: - Frame

func frame(_ t: Double) {
    // Background: brand for the hook, paper for the promises, brand again for the end card.
    let full = CGRect(x: 0, y: 0, width: W, height: H)
    if t < 1.0 || t >= T.toEnd + 0.45 { fill(full, brand) } else { fill(full, paper) }
    if t >= T.toEnd && t < T.toEnd + 0.45 { circleReveal(from: CGPoint(x: W / 2, y: H / 2), prog(t, T.toEnd, T.toEnd + 0.45)) { fill(full, brand) } }

    ctx.saveGState()
    let push = t >= 2 && t < T.toEnd ? 0.03 * inOut(prog(t, 2, T.toEnd)) : 0
    applyCamera(scale: 1 + push + (t < T.toEnd ? beatPulse(t, beat: 0.5) : 0),
                shake: shake(t, T.hook.map { (at: $0, px: 7.0, decay: 28.0) }), t: t)

    // Hook: three words stamp in on the beat.
    if t < 2.0 {
        for (i, w) in hookWords.enumerated() where t >= T.hook[i] {
            let base: CGFloat = 200, y = 700 + CGFloat(i) * 210
            let size = min(base, base * (W - 144) / textWidth(w, base, .heavy, kern: -4))   // long names shrink to fit
            let width = textWidth(w, size, .heavy, kern: -4)
            let s = stampScale(t, at: T.hook[i])
            ctx.saveGState()
            ctx.translateBy(x: 72 + width / 2, y: y - size * 0.35); ctx.scaleBy(x: s, y: s)
            ctx.translateBy(x: -(72 + width / 2), y: -(y - size * 0.35))
            text(w, size, .heavy, paper, 72, y, kern: -4)
            ctx.restoreGState()
        }
    }

    // Promises: kinetic headlines over a card that stands in for a product screen.
    drawHeadlines(promises, t)
    if t >= 2.2 && t < T.toEnd {
        let e = outBack(prog(t, 2.2, 2.6), 1.2) * (1 - inCubic(prog(t, T.toEnd - 0.3, T.toEnd)))
        let card = CGRect(x: 72, y: 760 + 120 * CGFloat(1 - e), width: W - 144, height: 640)
        ctx.saveGState(); ctx.setAlpha(CGFloat(e))
        fillShadowed(rr(card, 56), white)
        text("Put a real screenshot here", 40, .semibold, ink.alpha(0.4), card.midX, card.midY + 14, align: 0.5)
        ctx.restoreGState()
    }

    // End card: logo, name, one line.
    if t >= T.toEnd + 0.3 {
        let p = outBack(prog(t, T.toEnd + 0.3, T.toEnd + 0.7), 1.4)
        let r = CGRect(x: W / 2 - 160 * CGFloat(p), y: 640 + 160 * CGFloat(1 - p), width: 320 * CGFloat(p), height: 320 * CGFloat(p))
        if let logo { ctx.saveGState(); ctx.addPath(rr(r, 72 * CGFloat(p))); ctx.clip(); drawImage(logo, in: r); ctx.restoreGState() }
        else { fillShadowed(rr(r, 72 * CGFloat(p)), white) }
    }
    riseText("{{PRODUCT}}", 92, .heavy, white, W / 2, 1110, at: T.endLines[0], t: t, kern: -1.5)
    riseText("The one line that says what it is.", 44, .semibold, white.alpha(0.9), W / 2, 1186, at: T.endLines[1], t: t)
    riseText("Get it today", 40, .semibold, white.alpha(0.8), W / 2, 1250, at: T.endLines[2], t: t)
    ctx.restoreGState()
}

// MARK: - Score

func score(_ s: Score) {
    let chords = [[57, 60, 64], [57, 60, 65], [55, 60, 64], [55, 59, 62]]   // Am F C G
    let roots = [45, 41, 48, 43]
    s.music.add(impact(), at: 0, gain: 0.9)
    for at in T.hook { s.cue(at, "stamp", stampHit(), 0.55); s.music.add(stab(chords[0]), at: at, gain: 0.5) }
    s.fx.add(riser(0.5), at: 1.5, gain: 0.35)
    s.groove(from: 0, to: T.toEnd, chords: chords, roots: roots, full: 2.0)
    for at in T.promises { s.music.add(crash(), at: at, gain: 0.25); s.cue(at, "headline", whoosh(0.35), 0.25) }
    s.fx.add(riser(0.9), at: T.toEnd - 0.9, gain: 0.4)
    s.cue(T.toEnd, "reveal", whoosh(0.45), 0.28)
    s.music.add(impact(), at: T.toEnd + 0.5, gain: 0.85)
    s.cue(T.toEnd + 0.5, "logo", thumpSnd(), 0.8)
    s.music.add(chordVoice([48, 55, 60, 64, 67, 74], dur: 3.5, attack: 0.01, cutoff: { 900 + 2400 * exp(-$0 * 1.5) }, decay: 0.9),
                at: T.toEnd + 0.5, gain: 0.55)
    for at in T.endLines { s.cue(at, "line", pop(620), 0.12) }
    s.fadeOut = (13.6, 14.95)
}
