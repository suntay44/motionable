# motionable engine reference

The engine is plain Swift on Apple's built-in frameworks (Core Graphics, Core Text, Core Image, AVFoundation), so nothing has to be installed beyond the Xcode command line tools. A project is a folder:

```
<project>/
├── scenes/Film.swift    defines makeFilm() — the only file the agent writes per product
├── assets/              logo, screenshots, badges (relative paths resolve here)
├── STYLE.md SCRIPT.md   the plan the user approved
└── out/                 renders (git-ignored)
```

Run everything through `scripts/run.sh <project> <mode>`. It rebuilds only when a `.swift` file changed:

| Mode | Output |
|---|---|
| `sheet 0.5 3 7.5 …` | `out/sheet.png`, one contact sheet of labelled stills (use this for critique) |
| `stills 3 7.5` | `out/stills/still-3.00.png` … at full size |
| `audio` | `out/music.m4a` + `out/beats.json`, and prints levels (peak, rms, muffled vs. just before) |
| `video` | `out/<name>.mp4` (H.264 + AAC), audio included. About 45 s for 30 s at 60 fps |

## The Film

```swift
func makeFilm() -> Film {
    Film(name: "acme-hype", width: 1080, height: 1920, fps: 60, duration: 30, bpm: 120,
         holdFrom: T.still, draw: frame, score: score)
}
```

- `draw(t)` paints the frame at time `t` into the global `ctx` (top-left origin, pixels). `W` and `H` hold the canvas size. The engine adds film grain afterwards and freezes it from `holdFrom`.
- `score(s)` fills a `Score` (below). Keep every time in an `enum T`, so picture and sound share them.

## Drawing (Canvas.swift)

| Call | Does |
|---|---|
| `Col(0xRRGGBB, alpha)`, `.alpha(x)`, `mix(a, b, t)` | Colours |
| `fill(rect/path, col)`, `fillShadowed(path, col, blur:, alpha:, dy:)`, `stroke(path, col, width)`, `line(a, b, col, w)` | Shapes |
| `rr(rect, radius)` | Rounded-rect path |
| `partial(points, fraction)` | A polyline drawn part-way (checkmarks, underlines) |
| `text(s, size, weight, col, x, baseline, align: 0/0.5/1, kern:)` → width | SF Pro text; returns its width |
| `textWidth(s, size, weight, kern:)` | Measure before drawing |
| `loadImage("assets/x.png")`, `loadSVG("assets/x.svg", height:)` | Images (PNG/JPEG/HEIC, SVG) |
| `drawImage(img, in: rect)` | Draw upright. Clip first (`ctx.addPath(rr(…)); ctx.clip()`) for rounded screenshots |
| `blurFrame(sigma:, darken:)` | Blur everything drawn so far this frame |
| `ctx.saveGState()` / `setAlpha` / `translateBy` / `scaleBy` / `rotate` | Core Graphics directly |

Easing: `prog(t, a, b)` (0…1 between two times), `outCubic`, `inCubic`, `inOut`, `outBack(x, s)`, `lerp` (numbers, points, rects), `centred(point, radius)`.

## Motion (Motion.swift)

| Call | Does |
|---|---|
| `Headline(from:, to:, lines:, sub:, colour:)` + `drawHeadlines(list, t)` | Left-aligned kinetic headlines: masked line reveal, auto-fit to 880 px, exit upward |
| `stampScale(t, at:)` | 1.22 → 1 "stamp" for a word; scale around the word's centre |
| `riseText(s, size, weight, col, x, y, at:, t:)` | Fade and lift in (end-card lines) |
| `circleReveal(from:, p) { paint }` | Paints a new background inside a growing circle |
| `applyCamera(scale:, shake:, t:)` | Camera for everything after it (wrap in save/restore) |
| `beatPulse(t, beat:)`, `shake(t, [(at, px, decay)])` | Breathing zoom on the beat; impact shake |
| `desaturate(amount, restoreFrom:, restore:)` | Drain to grey, then flood colour back from a point ("offline → online") |
| `drawAppStoreBadge(img, centre:, height:)` → rect | Apple's badge: never animate, scale-in or rotate it |
| `glowRing(around: rect, p)` | Emphasis behind a badge without touching it |

## Score (Score.swift + Audio.swift)

Buses: `s.music` (drums, stabs, impacts; muffled ranges apply), `s.ducked` (bass, pads, arps; ducked under kicks), `s.fx` (risers, never muffled), `s.sfx` (picture-synced effects).

| Call | Does |
|---|---|
| `s.groove(from:, to:, chords:, roots:, full:)` | Four-on-the-floor house groove, one chord per bar; lighter before `full` |
| `s.kick(at:)`, `s.roll(into:)` | Single kick (registers for ducking); 16th snare roll into a hit |
| `s.cue(t, "what", sound, gain, pan:)` | A sound effect on a picture event, logged in beats.json |
| `s.muffled = [(from, to)]` | Underwater stretch (low-pass and quieter) |
| `s.fadeOut = (from, to)` | Tail fade |
| `bus.add(sound, at:, gain:, pan:)` | Place any sound |

Instruments: `kick(deep:)`, `clap()`, `hat(open:)`, `bassNote(midi, dur)`, `stab([midi])`, `pad([midi], dur)`, `pluck(midi)`, `chordVoice(…)`, `riser(dur)`, `crash()`, `impact()`.
Effects: `click()`, `keyTap()`, `pop(baseHz)`, `ding()`, `whoosh(dur, up:)`, `powerDown()`, `stampHit()`, `thumpSnd()`.
At 120 BPM a beat is 0.5 s; put every hit on a beat or an eighth (0.25).

## Gotchas

- If the Swift compiler says an expression is too complex, split it into typed `let`s.
- Draw text with `text(...)` only. It flips Core Text for the top-left canvas.
- Keep `T` times on the beat grid, or picture and music drift apart.
- From `holdFrom` to the end, nothing may move: no camera pulse, no animation.
