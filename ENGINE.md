# motionable engine reference

The engine is plain Swift on Apple's built-in frameworks (Core Graphics, Core Text, Core Image, AVFoundation, Accelerate). It needs nothing beyond the Xcode command line tools. **These are ingredients, not styles.** Plan mode (PLAN.md) decides which to use, and a film can add its own pieces in its `scenes/` folder.

```
<film>/
├── engine/            this film's own copy of the engine (new.sh copies it; plugin updates never change it)
├── scenes/Film.swift  makeFilm(): the film. Add more .swift files here for custom elements
├── assets/            screenshots, logo · drawn/ (SVGs Claude draws) · fonts/ (the brand's own font files)
├── DIRECTION.md       the plan (dials and reasons) · SCRIPT.md  the beat grid
└── out/               renders
```

`bash ROOT/scripts/run.sh <film> <mode>` rebuilds only when a `.swift` file changed:

| Mode | Output |
|---|---|
| `sheet` | `out/sheet.png`: labelled stills on one sheet, for critique: the whole film plus the edges and middle of every join. `sheet 0.5 3 7.5 …` picks the times |
| `stills 3 7.5` | `out/stills/still-3.00.png`… at full size |
| `audio` | `out/music.m4a` + `out/beats.json`, and prints levels |
| `check` | Readability: every line of text that leaves before it can be read (15 characters/s + 0.4 s, at least 1 s, after its entrance finishes), text in the social apps' button zones, dead air, and flashing (more than three flashes a second fails). It also reports what frame 1 says and whether the shot lengths vary |
| `draft` | `out/<name>-draft.mp4`: half size at 30 fps, about 3× faster, for your own review |
| `video` | `out/<name>.mp4` (H.264 + AAC). About 20–45 s for 30 s at 60 fps |
| `video effects` | `out/<name>-effects.mp4`: the sound effects only, where they sit in the full mix, so a platform sound or a licensed track can go on top |

`bash ROOT/scripts/compare.sh <film>` checks how much the film *sounds* like the other films in the studio (harmony, timbre, groove; above 0.85 is too similar).

`bash ROOT/scripts/inspect.sh <image> [pixel X,Y … | row Y | column X | find RRGGBB]` measures a screenshot: its size and colours, the edges of elements along a row or column, and the bounding boxes of everything in one colour (a ring, a bar, a badge). Use it before redrawing a tick, a counter or a bar on top of real UI.

## The Film

```swift
func makeFilm() -> Film {
    Film(name: "acme-hype", width: 1080, height: 1920, fps: 60, duration: 30, bpm: T.bpm,
         holdFrom: T.hold, draw: frame, score: score)
}
```

- `draw(t)` paints the frame at time `t` into the global `ctx` (top-left origin, pixels). `W` and `H` are the canvas size.
- The engine clears the frame first and adds film grain after; the grain freezes from `holdFrom`.
- `score(s)` fills a `Score`. Keep every time in an `enum T` on the beat grid (beat = 60/BPM).

## Drawing basics

| Call | Does |
|---|---|
| `Col(0xRRGGBB, alpha)`, `.alpha(x)`, `mix(a, b, t)` | Colours |
| `fill(rect/path, col)`, `fillShadowed(path, col, blur:, alpha:, dy:)`, `stroke(path, col, width)`, `line(a, b, col, w)` | Shapes |
| `rr(rect, radius)`, `centred(point, r)`, `partial(points, fraction)` | Paths |
| `loadImage("assets/x.png")`, `loadSVG("assets/x.svg", height:)`, `drawImage(img, in:)` | Images |
| `prog(t, a, b)` · `outCubic` `inCubic` `inOut` `outBack(x, s)` · `lerp` | Timing and easing |
| `Seeded(seed)`: `.next()` (0…1), `.int(n)`, `.pick(array)` | Repeatable randomness |

## Faces and type

`Face.named("Futura-CondensedExtraBold")` · `Face.system(.heavy)` · `Face.system(.bold, .rounded)` (also `.serif` = New York, `.monospaced`). Brand fonts in `assets/fonts/` register on their own; use their PostScript name. Unknown names fall back to the system font, with a warning.

**Faces that ship on every Mac**, by personality:
- Condensed and loud: `Futura-CondensedExtraBold`, `DINCondensed-Bold`, `Impact`, `AvenirNextCondensed-Heavy`, `HelveticaNeue-CondensedBlack`
- Geometric and friendly: `Futura-Bold`, `AvenirNext-Heavy`, `Avenir-Black`, `ArialRoundedMTBold`
- Neutral and clean: `HelveticaNeue-Bold`, `GillSans-Bold`, `Optima-Bold`, `Verdana-Bold`, `PTSans-Bold`
- Editorial and serif: `Didot-Bold`, `BodoniSvtyTwoITCTT-Bold`, `Baskerville-Bold`, `BigCaslon-Medium`, `Charter-Black`, `Georgia-Bold`, `HoeflerText-Black`
- Slab and retro: `Rockwell-Bold`, `AmericanTypewriter-Bold`, `Copperplate-Bold`, `Phosphate-Solid`
- Hand and playful: `MarkerFelt-Wide`, `Noteworthy-Bold`, `ChalkboardSE-Bold`, `BradleyHandITCTT-Bold`
- Mono and tech: `Menlo-Bold`, `Monaco`, `PTMono-Bold`, `AndaleMono`

| Call | Does |
|---|---|
| `text(s, size, face, col, x, baseline, align:, kern:)` → width | One line (`align` 0 left, 0.5 centre, 1 right). The older `text(s, size, .heavy, …)` with an SF weight still works |
| `textWidth(s, size, face)`, `outlineText(…, width:)` | Measure; outline only |
| `Kinetic(lines:, face:, size:, colour:, x:, y:, from:, to:, enter:, exit:, align:, lineHeight:, kern:, maxWidth:, upper:, stagger:, seed:).draw(t)` | Kinetic type. Pass arguments **in this order**; omit any with defaults |
| `TextIn` | `.rise` `.fade` `.pop` (per word) `.cascade` (per letter) `.typewriter(cps:)` `.slam` `.slide(Side)` `.stamp` `.scramble` `.split` `.wave` `.highlight(Col)` `.outlineFill` |
| `TextOut` | `.none` `.rise` `.fade` `.drop` `.scatter` `.shrink` `.wipe(Side)` |
| `rollNumber("$124.00", p:, x:, y:, size:, face:, colour:, align:)` | Slot-machine digits (nothing shows until p > 0) |
| `marquee("TEXT", y:, height:, band:, ink:, face:, size:, speed:, t:, degrees:)` | A scrolling ticker band, optionally slanted |
| `glyphs(s, size, face)` + `drawGlyph(…)` | Raw per-letter outlines, for custom type effects |

The older `Headline` + `drawHeadlines` and `stampScale`, `riseText` still work.

## Screens (never sliced)

`let s = Screenshot("assets/screen-home.png")`. It finds the quiet rows between UI elements, so crops snap to gaps.

| Call | Does |
|---|---|
| `drawScreen(s, region:, in: box, radius:, shadow:, snap:, alpha:, border:)` → rect | The whole screen (`region: nil`) or a snapped region, fitted into `box`. The card takes the region's shape; it is never cropped to the box |
| `ScreenMove(s, [(t, region), …]).draw(t, in:)` | A camera inside a screen: eased pans and zooms that rest on whole elements |
| `callout(s, region:, screenRect:, to: target, p:)` | Lifts one element off a drawn screen and carries it, scaled, to `target` |
| `screensRow([s1, s2, s3], in:, gap:, p:, vertical:)` | Screens side by side (or stacked), entering in turn |
| `screensFan([s1, s2, s3], centre:, height:, spread:, p:)` | Flat fanned screens (2D, never tilted like a device photo) |
| `canvasPoint(p, region:, drawnIn:)` | A screenshot pixel → canvas point (for taps, stickers, arrows); measure the pixel with `scripts/inspect.sh` |

## Joins (transitions)

```swift
let reel = Reel([
    Clip(from: 0, to: 3) { t in … },
    Clip(from: 3, to: 7) { t in … },
], joins: [(.whip(.left), 0.36)])      // one join per boundary: (style, duration), centred on the boundary
func frame(_ t: Double) { reel.draw(t); /* overlays */ }
```

`Join`:
- `.cut`, `.dissolve`, `.dip(Col)`, `.flash(Col)`, `.burn(Col)`
- `.push(Side)`, `.cover(Side)`, `.uncover(Side)`, `.whip(Side)`
- `.zoomThrough(CGPoint)`, `.iris(CGPoint)`, `.shape(.star(points:) | .roundedSquare | .diamond | .heart | .blob(seed:), CGPoint)`
- `.blinds(n, vertical:)`, `.columns(n)`, `.slice(degrees:)`, `.glitch`, `.pixelate`, `.spin(clockwise:)`

`composite(style, p:, a: { … }, b: { … })` runs any join outside a Reel. `layer { … }` renders anything to its own image. Looks: `motionBlurred`, `zoomBlurred`, `gaussianBlurred`, `pixellated`, `channelSplit`, `saturated`, `bloomed`, `halftoned`; apply to the frame so far with `postProcess { look($0) }`, or blur it with `blurFrame(sigma:, darken:)`.

## Elements

| Call | Does |
|---|---|
| `sticker("NEW", at:, shape: .pill/.burst(points:)/.tag/.circle/.ribbon/.speech, fill:, ink:, face:, size:, degrees:, p:, tailRight:)` | A popping sticker label; a `.speech` tail points down-left, or down-right with `tailRight: true` |
| `priceTag("$9.99", at:, p:, fill:, ink:, face:, size:)` | A tag swinging on a string |
| `receipt([(item, price)…], total:, in:, p:, size:, title:)` | A receipt printing out |
| `chatBubble(text, at:, mine:, p:, fill:, ink:)`, `notice(title:, message:, icon:, t:, from:, to:)` | Chat and notifications |
| `scribbleCircle(around:, p:, colour:)`, `handArrow(from:, to:, p:, colour:, bend:)`, `underlineStroke(rect, p:, colour:, style: .straight/.wave/.scribble)` | Hand-drawn marks |
| `sparkle(at:, size:, p:, colour:)`, `sparkles(around:, t:, from:, colour:)`, `confetti(from:, at:, t:, colours:)` | Celebration |
| `tapRipple(at:, at: t0, t:)`, `pointer(at:, pressed:)` | Taps and a cursor |
| `progressRing(centre:, radius:, width:, progress:, track:, fill:)`, `progressBar(rect, progress:, track:, fill:)` | Meters |
| `gradientFill([cols], degrees:)`, `radialGlow(at:, radius:, colour:)`, `dotGrid(…)`, `stripes(…)`, `blobs(…)`, `gridLines(…)` | Backgrounds |
| `vignette(amount)`, `scanlines(alpha:)`, `lightLeak(t:, colour:, strength:)`, `letterbox(amount)` | Overlays |
| `circleReveal(from:, p) { … }`, `desaturate(amount, restoreFrom:, restore:)`, `applyCamera(scale:, shake:, t:)`, `beatPulse`, `shake` | Reveals and camera |
| `drawAppStoreBadge(img, centre:, height:)`, `glowRing(around:, p)` | Store end card: the badge never animates (rules.md) |

**Need something else?** Write it in the film's own `scenes/`, as a function that takes its progress (`p`) or time. Examples: a slot machine, a steaming pan, a scoreboard, a map pin drop.

## Icons ("mini images")

46 original line icons on a 24-unit grid (MIT, part of motionable; not SF Symbols):
- `check close plus star heart bolt clock cart lock shield cloud offline share download bell chat camera user users home search`
- `fire leaf coin chartUp calendar gift trophy play pin globe book forkKnife cup dumbbell sparkle music doc tag timer phone wand scale list send eye`

| Call | Does |
|---|---|
| `icon(.cart, at:, size:, colour:, weight:, p:, fill:)` | An icon; `p` 0 → 1 draws it on stroke by stroke |
| `iconChip(.offline, "Works offline", at:, p:, fill:, ink:, disc:, discInk:, face:, size:)` | A benefit chip: an icon in a disc plus a short label, popping in |

Use icons for benefit chips, feature rows and callouts, one idea per icon. They need no licence check, so no Claude-drawn SVG is required for these basics.

## Drawn illustrations

Claude writes simple SVGs into `assets/drawn/`. Use `path`, `circle`, `ellipse`, `rect`, `line`, `polyline` and `polygon` with `fill`, `stroke`, `stroke-width` and `opacity`; **no `transform`, gradients or text**. Use the brand's colours, and keep one line weight per illustration.

`let pot = loadDrawing("assets/drawn/pot.svg")` then `drawDrawing(pot, in: box, draw: p, fill: q)`: strokes draw themselves on as `draw` goes 0 → 1, and fills fade in with `fill`. `svgPath("M10 10 C…")` turns path data into a `CGPath` for custom motion.

## Sound

A `Recipe` plus `Section`s, played with `s.compose(recipe, sections)`:

```swift
let recipe = Recipe(bpm: 104, swing: 0.12, key: 2, mode: .dorian, progression: [1, 4], barsPerChord: 1,
    chordColour: .seventh, kit: .acoustic,
    drums: Drums(kick: "X..x..X...x.X...", snare: "....X..-.-..X.-.", hat: "x.x.x.x.x.x.x.x."),
    parts: [Part(synth: .funk, rhythm: "X..x.xX..x..X.x.", notes: .octaves, octave: 2, gain: 0.5),
            Part(synth: .brass, rhythm: "....X.......x...", notes: .chord, octave: 4, gain: 0.32, from: 3)],
    space: .room, colour: .warm, sidechain: 0.3, seed: 4)
s.compose(recipe, [Section(from: 0, to: 2.3, energy: 1), Section(from: 2.3, to: 9.2, energy: 3), Section(from: 9.2, to: 12, energy: 0)])
```

- **Patterns** have 16 steps per bar, and 32 or 64 characters make longer loops: `X` accent, `x` hit, `o` soft, `-` ghost, `.` rest, `_` hold the note, `2`/`3`/`4`/`6` a roll.
- **Meter:** `Recipe(…, barsPerChord: 1, meter: 12, …)` makes a bar 12 steps (3/4: a waltz or lullaby); write the patterns 12 long. The default is 16 (4/4).
- **Mode:** `.major` `.minor` `.dorian` `.mixolydian` `.lydian` `.phrygian` `.harmonicMinor` `.majorPentatonic` `.minorPentatonic` `.blues`.
- **Key:** 0 = C … 11 = B.
- **ChordColour:** `.triad` `.seventh` `.add9` `.ninth` `.sus2` `.sus4` `.power`.
- **Kit:** `.clean` `.punchy` `.lofi` `.trap` `.acoustic` `.cinematic` `.electro`.
- **Drums:** `kick snare clap hat openHat rim shaker tamb cowbell clave conga tom`.
- **Part `synth`:** `.sub .eight08 .funk .sawBass .pluck .ePiano .organ .marimba .bell .kalimba .piano .strings .brass .supersaw .chip .guitar .pad .choir .stab`.
- **Part `notes`:** `.root .rootFifth .octaves .chord .arpUp .arpDown .arpUpDown .arpRandom .motif .walk .line([degrees])`.
- **Part `from`:** the lowest section energy it plays in.
- **Sections:** energy 0 ambient · 1 light · 2 groove · 3 full. Rises get fills, risers and crashes on their own (`fill: false` swells in softly instead); `muffled: true` makes a stretch sound underwater.
- **Space:** `.dry` `.room` `.studio` `.hall` `.cathedral`.
- **Colour:** `.clean` `.warm` `.tape` `.lofi` `.bright` `.crushed`.

**Beyond the recipe:**
- `s.cue(t, "what", sound, gain, pan:)` puts a sound effect on a picture event.
- `s.hit(recipe, at:, synth: .stab/.brass/.piano)` plays a chord stab on a hit.
- `s.cadence(recipe, at:, length:, synth:)` plays the closing chord (`.bell`, `.kalimba` or `.marimba` roll it like a music box).
- `s.music`, `s.ducked`, `s.fx`, `s.sfx`, `s.verb`, `s.echo` take `.add(sound, at:, gain:, pan:)`.
- The older `s.groove(…)` still works.

**Instruments** (sample arrays):
- drums: `kick(deep:)` `snare()` `clap()` `hat(open:)` `rim()` `shaker()` `tambourine()` `cowbell()` `clave()` `conga()` `tom(pitch:, big:)`
- bass: `eight08(midi, dur, glideFrom:)` `subBass` `funkBass` `bassNote`
- keys and mallets: `ePiano` `organ` `piano` `marimba` `bell` `kalimba` `pluck`
- sustained and lead: `strings` `brass` `supersaw` `chip` `guitar` `choir` `pad` `stab`
- big moments: `braam` `riser` `crash` `impact` `reverseCymbal` `subDrop` `vinylBed`

**Effects:** `chop()` `sizzle()` `pour()` `kaching()` `coins()` `pageFlip()` `penScribble()` `shutter()` `boing()` `bloop()` `slideWhistle(up:)` `swish()` `zipper()` `glitchZap()` `blips()` `success()` `errorBuzz()` `bubble()` `heartbeat()` `click()` `keyTap()` `pop()` `ding()` `whoosh(dur, up:)` `powerDown()` `stampHit()` `thumpSnd()`.

## Gotchas

- **"Invalid redeclaration":** one of your names collides with an engine name, such as `impact`, `chop`, `pop`, `bell`, `strings`, `reel`, `tom`, `kick`, `line`, `text`, `fill`, `layer`, `sticker` or `notice`. Rename yours (`impactFace`, `screenPop`…).
- **"Unable to type-check in reasonable time":** split the expression into typed `let`s.
- **Wrong argument order** (`Kinetic`, `Part`, `Recipe`, `Film`): Swift wants them in declaration order. Copy the order above.
- **Text:** draw it only with `text(…)`, `Kinetic` or the type helpers, which handle the top-left canvas. They also report to `check`. Wrap decorative or in-between text in `unlogged { … }` so `check` ignores it; counters that settle on a value are recognised on their own.
- **Timing:** keep every time on the beat grid, or picture and music drift.
- **The final hold:** from `holdFrom` to the end, nothing may move.
- **Render time:** about 1.5–4 s per second of film. Per-frame looks (`bloomed`, `postProcess`, big shadows) cost the most, so use them where they matter.
