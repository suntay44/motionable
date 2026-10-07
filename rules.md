# motionable rules

Hard rules. Every film follows them, and the critique pass checks them.

## Truth

1. **No made-up features.** Every claim, screen and number comes from the product's code, docs, website or store page, or from the user. Anything you can't verify goes on SCRIPT.md's "Claims to verify" list, and you tell the user about it.
2. **Real UI only.** Use the user's screenshots, or redraw UI that matches a screenshot exactly. Never invent screens.
3. **Prices and availability** must match the store page or the user's words. Don't say "Download" before the product is live.

## Apple

Source: [App Store marketing guidelines](https://developer.apple.com/app-store/marketing/guidelines/).

4. **The "Download on the App Store" badge:** use Apple's official artwork, unmodified. **Never animate it**: no scale-in, bounce, rotation or fade. It cuts in and holds still. Keep clear space of a quarter of its height around it, and use one badge per video.
5. When other store badges or lines appear, **use the black badge and put it first**.
6. **Never bundle or redistribute the badge file.** Ask the user's permission, then download it from Apple's marketing toolbox (`https://toolbox.marketingtools.apple.com/api/v2/badges/download-on-the-app-store/black/en-us`, an SVG of about 11 KB) into the project's `assets/`.
7. **No Apple logo on its own**, and never use the logo in place of the word "Apple".
8. **iPhone images stay upright and uncovered.** Don't tilt them, don't put graphics over them, and don't let graphics come out of the screen.

## Google

Source: [Google Play badge guidelines](https://partnermarketinghub.withgoogle.com/brands/google-play/google-play/lockups-icons-badges/).

9. The **Google Play badge only for apps that are on Google Play** (or the "Pre-register" badge for apps in pre-registration). Don't modify it. It must be the same size as, or larger than, other store badges.
10. **Coming to Android but not on Play yet?** Plain text only, e.g. "Soon on Google Play", with no Google artwork, and only if it's true.

## Social

11. **Safe zones:** in 9:16, key text stays in the band x 6–90 %, y 14–65 %, which clears Reels' and Shorts' published zones (RESEARCH.md). 16:9 and 1:1 keep their margins. `run.sh <film> check` enforces it.
12. **The hook is readable in frame 1**, and the message lands within 3 s. Never fade in from black, and never open on a logo slate.
13. **The last 1–2 s hold perfectly still**, so the final frame works as a thumbnail.
13b. **Not an App Store preview.** App previews must be footage captured in the app (Apple 2.3.4); motionable videos are ads and launch videos. Never call one an app preview.

## Directed, not templated

14. **Every look and sound choice is derived:** DIRECTION.md gives each dial a reason that points at evidence about the product (PLAN.md). No presets, and no copying another film, the Owly example included.
15. **Unique in the studio:** at least 5 fingerprint lines differ from every other film in the studio, and `scripts/compare.sh` reports every other film at 0.85 or below. A series look only if the user asks for one.
16. **Variety inside the film:** never the same join twice in a row, and at least 3 kinds of join in a 30 s film (2 in a 15 s cut); at least 3 kinds of framing (2 in 15 s) and at least 2 type entrances. No two scenes in a row share the same layout. Each join has a reason; motion for its own sake reads as a template.
17. **The signature moment:** the product's most visual real interaction is in the film, redrawn to move exactly like the real UI.
18. **Screens are never sliced:** show them through `drawScreen`, `ScreenMove`, `callout`, `screensRow` or `screensFan`, which fit whole screens or snap crops to the gaps between elements. Never clip a screenshot into a fixed box.
19. **Hard cuts and joins land on the beat.** Every on-screen event has a matching sound, and every musical hit has something that moves.
20. **Music is original, made in code.** Never a commercial track or a trending sound; the user can swap in a licensed track later.

## Craft (what viewers reward: RESEARCH.md › community check)

25. **Ease, don't bounce.** Screens, headlines and cards ease out smoothly with no overshoot. Only small accents (stickers, icons, chips) may overshoot, and gently. Never blur text people need to read.
26. **No strobing.** At most three flashes in any second (WCAG 2.3.1); `check` fails a film that breaks it. Keep flash and glitch joins brief and rare.
27. **The UI is legible.** When a screen's words carry the message, crop to the part that matters (a region, a callout, a camera move) instead of shrinking the whole screen.
28. **Vary the shot lengths.** Shots of one length feel mechanical; `check` warns.
29. **No stock-music formula:** no ukulele and whistling, no swoosh-and-claps "startup" build. The sound comes from the product's world (PLAN.md).
30. **Brand moments are short.** The icon or logo reveal takes under a second; then the end card holds still.
31. **Type mixes stay readable.** At most 3 faces in a film; a mix of face, weight, italic or colour goes on 1–2 words a line, and each accent has a job (the number, the benefit word, the name). Every line keeps **3:1 contrast** with what's behind it; `check` measures it and fails lower.
32. **One motion vocabulary.** Each kind of thing enters and leaves the same way through the film (screens one way, small accents another, text its own), chosen in plan mode. Bounce (pop, drop) only on small things.
33. **Footage stays true.** Speed it, trim it, zoom into it and freeze it, but never change what the app did. Draw on top only to act out what the app really does (a finger on a recorded tap, a tick that syncs), and keep typing slow enough to read (about 2.5× at most).
34. **Every keyframe composes.** Before anything moves, each beat's settled frame passes `storyboard`: no overlapping or cut-off text, no crop through UI, no accidental emptiness. New text arrives after a see-through join, not during it.

## Narration (when selected)

Use the approved recording and verified spoken claims. Preserve its words, pronunciation and timing; do not silently switch voices, speed it up, or send it to a service. Keep speech outside musical effects. The preparation, review and failure behavior is in [voiceover workflow](docs/voiceover.md).

## Illustrations

21. **Claude-drawn illustrations** are simple SVGs in `assets/drawn/`, in the brand's colours and line style. Draw them only if the user said yes in plan mode.
22. **Never redraw or alter** the user's logo, mascot, characters or real UI. Use their files.
23. **Never imitate** another brand's characters, artwork or style signatures.
24. **An image generator** (an external tool or connector) only if the user has one and chooses it, after being told it may cost money. Its output follows rules 22–23 too.
