---
name: make
description: "Internal motionable pipeline (plan mode, approval, scenes, music, critique, render). Start with /motionable:scratch, :website or :project instead."
user-invocable: false
---

# motionable: make

You arrive here with facts about a product (each with a source), the user's answers, image paths, colours, and notes on its personality. Your job is a finished film that feels like **this** product, and like no other film in the studio.

`ROOT` is the motionable root: `${CLAUDE_PLUGIN_ROOT}`. If that isn't expanded, use the folder two levels above this file's real path (`realpath`), which holds `engine/` and `scripts/`.

Read **`ROOT/PLAN.md`** (plan mode), **`ROOT/ENGINE.md`** (the ingredients), **`ROOT/rules.md`** (hard rules) and **`ROOT/checklist.md`** (critique) before you plan. `ROOT/examples/owly/` shows what finished work looks like. **Never copy its look, sound or structure**: it is one direction among endless ones.

## 1. Create the film

- **Where:** films live in the **current folder** (usually the user's studio for hype videos), as `<slug>/`.
  - If the current folder is the product's own repo, use `motionable/<slug>/` instead.
  - Never write into a product folder given to `/motionable:project`.
  - If `<slug>/` exists, ask: make a new version (`<slug>-2/`), or continue that film?
- **Create it:** run `bash ROOT/scripts/new.sh <film> "<Product name>"`. It copies the engine into the film and writes the templates.
- **Assets:** copy the images into `<film>/assets/` with clear names (`logo.png`, `screen-home.png`…). A brand font file, if the user has one, goes in `assets/fonts/`.

## 2. Plan mode (internal: no command, no style menu)

Follow **PLAN.md** from start to finish:
1. **Evidence board and personality.**
2. **Story:** promise, signature moment, 3 hooks → 1.
3. **Every dial set, each with its reason.**
4. **Uniqueness against the studio:** read the other films' `DIRECTION.md` › Fingerprint. Films made before v0.2 have none; treat them as 120 BPM A-minor house with left-aligned headlines over a card.
5. **Write DIRECTION.md and SCRIPT.md** at the chosen tempo.

Do not ask the user to pick a style. The direction comes from the evidence.

## 3. One approval

Show the **4-line treatment** (Feel · Sound · Look · Signature moment) and a compact beat grid (time · picture · words · join). Then ask, with **AskUserQuestion** if available (otherwise in chat):
1. **The plan:** approve, or change something.
2. **Illustrations:** "Should I draw illustrations for this film?" Yes, illustrate it / A few accents / No, screenshots and type only. Recommend one with a reason (PLAN.md §5).
   - Drawing them is free: Claude writes SVGs.
   - Only if the session has an image-generation tool connected, add it as an option, and say it may cost money.

Write no scene code before approval. A change here is cheap.

## 4. Build

1. **Illustrations** (if yes): write the SVGs into `assets/drawn/` in the brand's colours and one line weight (ENGINE.md › Drawn illustrations). Look at each one rendered on a sheet, and redraw anything clumsy.
2. **Storyboard first.** Lay every scene out at its settled state before any motion: every element at its final place. Set `keyframes:` to each beat's settled moment (SCRIPT.md), run `bash ROOT/scripts/run.sh <film> storyboard`, fix every ✗ (overlaps, cut-off text, crops through UI, contrast, safe zones), and judge each keyframe as a still: one focal point, a shared margin, nothing empty or touching an edge by accident (PLAN.md › 5b). Then animate.
3. **`scenes/Film.swift`:** replace the skeleton completely. Every value comes from DIRECTION.md and SCRIPT.md:
   - the times go into `enum T`;
   - clips and joins go into a `Reel`;
   - screens go through the framing calls (never clipped into a fixed box);
   - **if there's a recording of the signature moment, use it** (ENGINE.md › Footage): trim it into `assets/` with `footage.sh … trim`, map film time to it with `Playback` (through waits fast, typing at most about 2.5×, freezing on results), move a `Zoom` camera to where its timeline says the change happens, and put fingers on its taps with `TouchPath`. Sounds go on recorded events through `play.filmTime(of:)`;
   - otherwise the signature moment is redrawn to animate exactly like the real UI, with UI acting (typing, a finger, a state change). Measure where it sits first: `bash ROOT/scripts/inspect.sh <screenshot> find <its colour>` (or `row`, `column`, `pixel`) gives exact rings, bars and text edges.
   - **Custom elements** the direction needs go in their own `scenes/*.swift` files.
4. **Sound:** the direction's `Recipe` + `Section`s via `s.compose`, plus a `s.cue` for every picture event, using the signature sounds. Tempo phases only if DIRECTION.md chose them (ENGINE.md › Sound).
5. **Check it builds:** `bash ROOT/scripts/run.sh <film> sheet` (no times: the whole film plus every join). Fix compile errors (ENGINE.md › Gotchas).

## 5. Draft, fix, then show the user

Work in drafts, and never loop endlessly:

1. **Draft 1** is the first complete build: scenes, music and every cue. Review it from the film itself (the steps below); you don't need a video file for that. (`run.sh <film> draft` renders a small, fast MP4 if the user wants an early look.)
2. **Self-review: one pass, and every check.**
   - `run.sh <film> check`: every ✗ is a must-fix. Hold the line longer, start it sooner, cut words, or drop the line. A typed line needs its typing time *plus* its reading time. Every layout ✗ too: overlapping text, cut-off text, a crop through UI. Act on its ⚠ advice (frame 1, rhythm, empty stretches, text crossing in a join, covered text, a camera cropping UI) unless DIRECTION.md says why not.
   - `run.sh <film> storyboard` again: every keyframe ✓.
   - `run.sh <film> sheet`: score every category in checklist.md, and fix anything below 8. Look at full-size `stills` of the hook, the signature moment and the end card: is the UI legible, does anything collide, is every corner of the frame doing something or deliberately empty?
   - **What viewers punish** (RESEARCH.md › community check): UI too small to read, bounce on big things, shots of one length, stock-sounding music, a slow logo moment.
   - `run.sh <film> audio`, then `bash ROOT/scripts/compare.sh <film>`: if another film is too similar, change the recipe for a reason.
   - Step through the whole film: `run.sh <film> sheet $(seq 0.5 1 <length>)` (one frame a second). Look for what single stills hide: a scene that empties out, a beat with no movement, a join that jars, a line that appears just as the scene leaves.
3. **Draft 2.** Fix everything found in one batch, then run `check` and `sheet` again.
   - If something still fails, allow **one** more fix pass at most.
   - If it still fails after that, don't keep going: tell the user what's left and why.
   - Keep a short critique log in SCRIPT.md: what changed and why.
4. **Render the real file:** `run.sh <film> video`, about 45 s for 30 s.
5. **Show it and ask** (AskUserQuestion if available). Send the MP4, the 4-line treatment and the critique log, then ask **3–4 targeted questions** about *this* cut. Each needs a recommended option, and "Other" lets the user say anything:
   - **Pacing:** feels right / slower, fewer lines / faster, more punch.
   - **Sound:** keep it / more energy / calmer / different instruments.
   - **Hook:** keep it, or the strongest of the other two hook candidates from plan mode, named.
   - **Ending:** keep it / a launch-safe ending (for example, no Download badge before the app is live) / add the price.
6. **Revise once per round of answers**, rerunning `check` and `audio` and `compare`, then show the new cut. After two user rounds, offer to stop or continue; the user decides.

## 6. Store badges (only if the product is live)

- **App Store live and the user wants a badge:** ask permission to download Apple's official badge (about 11 KB, black, English SVG; URL in rules.md) into `assets/`.
  - Draw it with `drawAppStoreBadge`, still and never animated; emphasis comes from `glowRing`.
  - If the user insists on animating it, explain Apple's rule once. If they still want it, make that a separate, clearly named variant.
- **Google Play:** its badge only if the app is live there and the user approves the download. Otherwise, at most a plain-text line, and only if true.

## 7. Deliver

With every cut you show, include:
- the treatment in a few lines;
- what the self-review fixed;
- the compare result and the `check` verdict;
- **the claims to verify before posting**;
- how to change it: edit SCRIPT.md or DIRECTION.md, or just say.

After the user is happy, offer the next useful things:
- a 15 s cut, or another format (1:1, 16:9);
- **hook variants** for an A/B test: the same film opened with the other two hook candidates from plan mode;
- a launch-safe ending (no "Download" before the app is live);
- an effects-only version (`run.sh <film> video effects`), for posting with a platform sound or a licensed track.
