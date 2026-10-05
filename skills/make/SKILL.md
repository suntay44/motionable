---
name: make
description: The motionable pipeline that the scratch, website and project skills hand off to. Plans a hype video (style plus a beat grid the user approves), writes the scenes on the Swift engine, scores original music in code, critiques contact sheets, then renders the MP4. Start with /motionable:scratch, /motionable:website or /motionable:project instead of calling this directly.
user-invocable: false
---

# motionable: make

You arrive here with facts about a product (each with a source), the user's answers, image paths and colours. Your job is to turn them into a finished film the user is proud to post.

`ROOT` is the motionable root: `${CLAUDE_PLUGIN_ROOT}`. If that isn't expanded, use the folder two levels above this file's real path (`realpath`), which holds `engine/` and `scripts/`. Before writing scenes, read **`ROOT/ENGINE.md`** (the API), **`ROOT/rules.md`** (hard rules) and **`ROOT/checklist.md`** (critique). The Owly example in `ROOT/examples/owly/` (scenes/Owly.swift, STYLE.md, SCRIPT.md) shows what finished work looks like; borrow its techniques, never its content.

## 1. Create the project

- **Folder:** films live in the **current folder**, usually the user's studio folder for hype videos. Create `<slug>/` there.
  - If the current folder *is* the product's own repo (the product folder is `.`), use `motionable/<slug>/` instead, so the repo stays tidy.
  - Never write into a product folder given to `/motionable:project`.
  - If `<slug>/` already exists, ask: make a new version (`<slug>-2/`), or continue that film?
- Run `bash ROOT/scripts/new.sh <film folder> "<Product name>"`.
- Copy the collected images into its `assets/` (and delete a `<slug>-downloads/` folder once copied), with clear names (`logo.png`, `screen-home.png`, `screen-feature.png`…).
- If the format isn't 9:16, set `width`/`height` in `makeFilm()` and adapt the layout constants.

## 2. Plan, and get approval before writing scenes

**Concept.** Pick one continuous idea that suits this product, for example:
- a shape that changes into each next scene;
- a single screenshot the camera travels across;
- a word that becomes the UI;
- a before/after that flips.

Lead with what the user chose to show first. One benefit per scene, building to the end card.

**STYLE.md.** Fill in the template: concept, palette with real hex values, type, motion rules, bans, sound.

**SCRIPT.md.** Write the beat grid, one row per moment, at 120 BPM (beat = 0.5 s, bar = 2 s):

| Time | Bar | Picture | Words | Sound |
|---|---|---|---|---|

Rules for the grid:
- The hook is on screen in frame 1, and the first second sets up something specific.
- Hard cuts only on beats, and every row has a sound.
- Every claim goes on the "Claims to verify" list with its source.
- The end card has the name, one line, the price line if any, and store availability that follows rules.md.
- The last 1–2 s hold still.

**Show the user a compact version of the grid** (time, picture, words) and ask for approval with AskUserQuestion: approve / change something. Don't write scene code until they approve. This is the cheapest point to change direction.

## 3. Build

1. **Write `scenes/Film.swift`,** replacing the starter. Every time from SCRIPT.md becomes a constant in `enum T`.
   - Use real screenshots: clip them into rounded "screen" cards (`ctx.addPath(rr(r, 48)); ctx.clip(); drawImage(img, in: r)`).
   - Move the camera across them, and crop or zoom into the part that matters.
   - Where something must animate (a tick, a counter, a progress bar, a typed line), redraw that one element to match the screenshot exactly, and lay it over the shot.
   - Never invent a screen.
2. **Write the score** in the same file: `s.groove(...)` for the bed, plus a `s.cue(...)` for every on-screen event (stamp, whoosh on morphs, pop on ticks, ding on notifications, thump on the logo), risers into big moments, and `s.muffled` for any "quiet" stretch.
3. **Run** `bash ROOT/scripts/run.sh <film folder> sheet <times…>` with two or three times per scene. Fix any compile errors (ENGINE.md › Gotchas).

## 4. Critique loop

- **Look at `out/sheet.png`.** Score every category in checklist.md, fix anything below 8, re-render, and repeat. At most three rounds.
- **Run `… audio`** and read the printed levels. Muffled stretches must read quieter than "just before". Effects must line up with the `T` times in `out/beats.json`.
- **Keep a short log** of what you changed and why, to tell the user.

## 5. Store badges (only if the product is live)

- **App Store live and the user wants a badge:** ask permission to download Apple's official badge (about 11 KB, black, English SVG; URL in rules.md) into `assets/`.
  - Draw it with `drawAppStoreBadge`, still and never animated; emphasis comes from `glowRing`.
  - If the user insists on animating it, explain Apple's rule once. If they still want it, make that a separate, clearly named variant and keep the compliant version as the main one.
- **Google Play:** use Google's official badge only if the app is live on Google Play and the user supplies or approves downloading it. Otherwise, at most a plain-text "Soon on Google Play", and only if true.

## 6. Render and deliver

1. Run `bash ROOT/scripts/run.sh <film folder> video`. It takes about 45 s for 30 s at 60 fps.
2. **Hand over the MP4.** Use SendUserFile if it's available; otherwise give the path. Add:
   - one paragraph on the concept and how it plays;
   - what the critique loop fixed;
   - **the claims the user must verify before posting**;
   - how to change it: edit SCRIPT.md, or tell you, and re-run `video`.
3. Offer the next useful things: a 15 s cut, another format, a variant ending, or swapping in a licensed music track.
