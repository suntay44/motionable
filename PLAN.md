# motionable plan mode

Plan mode runs **inside** every motionable command, after the product is understood and before any scene is written. It decides what *this* film should feel like, look like and sound like. The answer comes **from the product's own content**, never from a preset, never copied from another film. Its output is `DIRECTION.md` and `SCRIPT.md`, which the user approves once.

There are no styles to pick from. A direction is about 16 independent choices ("dials"). Each one is set from evidence about the product, and each one carries a one-line reason. Two products differ in their evidence, so their films differ. Two films in the same studio are also checked against each other.

---

## 1. Read the product's personality

Use what was gathered (repo, site, store page, screenshots, the user's answers). Write an **evidence board** of 8–12 signals, each with its source:

| Signal | Look for |
|---|---|
| What it does, for whom | The one-sentence job and the person doing it |
| The feeling after using it | Relief, pride, control, joy, calm, speed, belonging… |
| Voice | Quote 2–3 real lines of its copy. Playful? Precise? Warm? Bold? Technical? |
| Colours | Brand hues: warm or cool, saturated or muted, light or dark UI, contrast |
| Type | Fonts in the app or site (rounded, geometric, serif, mono, condensed) |
| Illustration and mascot | Character style, line weight, flat or textured, or none |
| UI density | Airy cards or dense data; big numbers or long lists |
| Signature numbers | Real figures it can show (490+ dishes, $3.10 per serving, 2 taps) |
| Its world | The physical world it lives in (kitchen, gym, studio, family, desk, road, money) |
| Audience and platform | Who, on what device, what they already watch |
| Business | Free, paid, subscription, coming soon, B2B |

Then write the **personality**: 3–5 adjectives, plus **2 it must never feel like** ("never corporate", "never frantic").

## 2. Find the story

- **Promise:** the one sentence the film proves.
- **Tension → payoff:** the small problem the viewer recognises, then the moment the product removes it.
- **Signature moment:** the most visual *real* interaction this product has that others don't, taken from its screenshots or code. Examples: a total rolling as servings go 4 → 40; a widget ticking on a son's Home Screen. The film must contain it, redrawn to animate exactly as the real UI does.
- **Hook:** write **3 candidates** from real content (a number, a question, a before/after, a line of its own copy, a real UI moment) and pick one, with a reason. Frame 1 must already show it.
- **Arc:** the order of beats (for example: hook → tension → signature moment → proof ×2 → payoff → end card). Use one beat per idea, and keep each beat to one claim.

## 2b. Shape it: the anatomy that works (RESEARCH.md)

The *feel* is free, and the dials decide it. The *shape* follows what platforms and ad data agree on:

| Beat | 30 s | 15 s | What it does |
|---|---|---|---|
| **Hook** | 0–3 s | 0–2 s | The problem, a question or the promise, **readable in frame 1**, with motion. Problem hooks lead software-app ad spend; value promises and questions also work |
| **Reveal** | by 2–5 s | by 2 s | The product or mascot on screen early, woven in, never a logo slate. Two or more shots in the first 5 s |
| **Benefits** | ~5–22 s | ~2–11 s | **At most 3 (2 in 15 s)**, each a benefit, not a feature, shown on real UI. The signature moment is one of them |
| **Proof** *(optional)* | ~22–26 s | — | Real numbers or facts (490+ dishes, works offline). Never invented ratings or quotes |
| **End card** | last 3–5 s | last 3 s | Icon, name, one line, and a **text CTA** that's true (store availability per rules.md). It holds still for the thumbnail |

**Message budget.** One core message. Every line needs its reading time: characters ÷ 15 + 0.4 s, at least 1 s, *after* its entrance ends (`check` measures it). Add those up: on-screen reading should fill **no more than about 60%** of the film. That leaves room for motion and breath. If it doesn't fit, cut lines; never speed them up.

**Layout (9:16).** Key text lives in the **band x 6–90%, y 14–65%** of the frame. That clears both Reels' and Shorts' published safe zones. Screens, illustrations and colour can fill the whole frame. 16:9 and 1:1 have their own margins (`check` knows them).

**Versions.**
- **30 s** is the master: it suits TikTok auction ads and Shorts.
- Offer a **15 s cut** for Reels and Meta.
- Offer a **launch-safe ending** (no "Download" before the app is live).
- motionable videos are ads and launch videos, **not App Store previews**, which must be captured footage of the app.

**What viewers reward** (RESEARCH.md › community check): clarity before polish (the script carries the message); text held long enough to read; the real UI big and legible; quick, smooth easing with no bounce on big things; shots of varied length; original sound, never the stock "startup" formula; short brand moments.

**Mini images that earn their place:**
- real UI close-ups and lifted callouts;
- tap ripples on the actions;
- benefit chips (an icon and two words);
- counters on real numbers;
- captions;
- the app icon on the end card.

Decoration is fine when it carries the product's world, such as Claude-drawn accents. It's never filler.

## 3. Set the dials

Set every dial from the evidence. Write the reason as "because …", pointing at a signal on the board. The middle column lists **ranges to choose from, not menus to copy.** Blend them freely, and invent anything that fits better.

| Dial | Range |
|---|---|
| **Energy and pacing** | 1 calm … 5 relentless; shots of 2–7 s with 2–4 moves inside each, of varied lengths; where it peaks |
| **Tempo and feel** | 70–150 BPM; straight, swing (0.1–0.5), half-time, or 3/4 (a waltz or lullaby: `meter: 12`). Match the product's pace, not a habit |
| **Tempo phases** *(optional)* | Most films keep one tempo. Change it only when the story moves that way and the user's brief allows it: a half-time groove under the problem, then the full groove at the reveal (`feel: .half`); a tape stop or a hit and a beat of silence into a new tempo; a ramp speeding into the drop or slowing into the end. Say why, from the evidence ("calm products stay steady") |
| **Key and mode** | Any key. Major or lydian: open, bright. Mixolydian or dorian: groovy, cool, confident. Minor or phrygian: tense, dramatic. Pentatonic or blues: playful, soulful. Harmonic minor: exotic, cinematic |
| **Harmony colour** | Triads (plain, punchy), 7ths and 9ths (warm, jazzy, lo-fi), sus (airy), power (hard). Progression of your choosing |
| **Drum language** | Write the real patterns (16 steps a bar; 12 in 3/4). A soft entrance (`fill: false`) skips the fill and crash. Four-on-the-floor, breakbeat, boom-bap swing, half-time trap, Latin clave, funk with ghost notes, shuffle, a cinematic pulse, or no drums at all. Bring in the product's world (knife chops as the hi-hat, pen clicks as the rim) |
| **Instruments** | 3–5 voices from: sub, 808, funk bass, saw bass, electric piano, organ, piano, marimba, kalimba, bells, pluck, guitar, strings, brass, choir, pad, supersaw, chip. The lead voice says the most about the product |
| **Room and colour** | Dry, room, studio, hall or cathedral; clean, warm, tape, lo-fi, bright or crushed |
| **Signature sounds** | 2–4 effects from the product's world (sizzle, ka-ching, page flip, shutter, pen, coins, boing, bubbles, glitch…) for its key moments |
| **Palette use** | Which brand colour leads and when; backgrounds (solid, gradient, paper, dark, pattern); one accent for emphasis |
| **Type** | The product's own font if its file is available; otherwise a macOS face that matches its type personality (see ENGINE.md › Faces). Choose case, alignment, scale, **at least 2 entrance styles**, and an exit |
| **Type mix** | How faces and weights combine, read from the product's voice: one face in two weights (black + ultralight: modern, precise), a heavy sans with a serif italic for the emotional word (editorial, warm), a rounded face with a slant (soft, friendly), a condensed caps line over a light line (bold, sporty). At most 3 faces in a film; the mix goes on 1–2 words a line (`*accent*`, `{name:words}`), never whole paragraphs |
| **Colour mix** | Which words get which colours: the base text colour plus 1–2 accents from the brand palette, with a job each (numbers, the benefit word, the product's name). Highlighter marks or underlines only if the brand already uses them. Every line keeps 3:1 contrast with what's behind it (`check` measures it) |
| **Motion vocabulary** | How things enter and leave, the same way through the whole film: 3–5 motions from ENGINE.md › Entrances (`show`: pop, zoom, fade, rise, drop, slide, fly, wipe, iris, blur, flip, spin) plus the text entrances. Calm products: fade, rise, zoom, wipe. Playful: pop, drop, flip, spin on small things. Crisp: slide, fly, wipe. Each kind of thing moves one way (screens one way, stickers another), so the motion reads as a language, not a sampler |
| **Framing** | **At least 3** of: **footage of the app working (a recording, with a camera moving inside it)**, a whole screen, a snapped focus, a camera move inside a screen, a lifted callout, a row of screens, a fan of screens, a redrawn UI element with UI acting (typing, a finger, a state change), an illustration. If a recording exists, the signature moment uses it |
| **Transitions** | A different kind at each boundary (≥3 kinds in 30 s, ≥2 in 15 s), each with a reason, matched to energy and personality: calm (dissolve, iris, morph, blob, dip, an in-shot colour shift), crisp (push, cover, uncover, columns, blinds), energetic (whip, zoom-through, slice, flash, glitch, pixelate), warm and analogue (burn) |
| **Camera** | Locked, slow push, glide inside screens, beat pulse, shake on impacts, handheld |
| **Texture** | None, grain, paper, scanlines, halftone, light leaks, vignette, bloom, letterbox |
| **Elements** | From ENGINE.md › Elements (stickers, tags, receipts, chat, notices, scribbles, arrows, confetti, sparkles, counters…), **plus any custom element this product needs**, built in the film's scenes |
| **Illustrations** | See §5: drawn for this film, or none |
| **End card** | Designed for this film. Lockup, line and store availability per rules.md. Not a formula |

## 4. Make it unique

1. **Read the studio.** List the other films in the studio folder and read the `## Fingerprint` block of each one's DIRECTION.md.
2. **Differ.** This film must differ from **every** other film on at least **5** fingerprint lines:
   - a tempo more than 12 BPM apart;
   - a different mode;
   - a different drum language, lead instrument, colour, type face, type mix, motion vocabulary, hook device or end-card device;
   - at most 2 shared transition kinds.

   If it collides, change dials. Change them for reasons, not at random, and keep the product's truth.
3. **Seed.** Pick a new random `seed` for the recipe, so even similar choices play differently.
4. **Check the sound.** After the audio exists, `scripts/compare.sh <film>` must report every other film at **0.85 or below**. If one is higher, change the recipe.

Never reuse another film's hook device, signature moment layout or end-card layout unless the user asks for a series look.

## 5. Ask about illustrations (one question, inside the approval step)

Ask whether Claude should **draw illustrations for this film**. Recommend it when screenshots are few, when the brand has an illustration style, or when the story has an object the UI doesn't show (a pot, a trophy, a city):

- **Yes, illustrate it**: doodles, icons, objects and patterns drawn in this product's style.
- **A few accents**: small marks, sparkles and one hero doodle.
- **No**: screenshots, type and shapes only.

**How:** Claude writes simple SVGs into `assets/drawn/` (see ENGINE.md › Drawn), in the brand's colours and line style, and they can draw themselves on.
- **Cost:** this is free and needs nothing installed.
- **Image generators:** if the user has one connected (an image-generation tool or connector) and prefers it, offer it, and say up front that it may cost money.
- **Never redraw** the user's logo, mascot or real UI. Use their files.
- **Never imitate** another brand's characters or artwork.

## 5b. Compose every frame

Before a scene is animated, its settled frame has to work as a still picture. For each beat decide:
- **The focal point:** one thing the eye goes to (usually the product's UI or the number), and where it sits.
- **Where the words go**, in the format's safe band, on a margin the whole film shares.
- **What fills the rest:** the product, a visual from its world, or deliberate space. Nothing empty by accident, nothing touching an edge by accident, no crop through UI.
- **How it hands over** to the next beat: new text arrives after a see-through join, not during it.

These go in SCRIPT.md per beat, and the beats' settled moments become the film's `keyframes`.

## 6. Write it down

- **DIRECTION.md** from `templates/DIRECTION.md`: board, personality, story, every dial with its reason, the recipe, the look, illustrations, end card, and the fingerprint.
- **SCRIPT.md:** the beat grid at the chosen tempo (one beat = 60/BPM s). One row per moment: picture, words, transition, sound. Put the signature moment on a strong beat. Add the claims to verify.

Then show the user a **4-line treatment** and the compact grid, for one approval:

> **Feel:** confident kitchen funk — warm, cheeky, never fussy
> **Sound:** 104 BPM D dorian funk, slap bass, brass stabs, cowbell; chops on the cuts, a ka-ching when costs land
> **Look:** Ponda red and cream; condensed caps popping word by word, prices in a bigger yellow; knife-slice and whip transitions; screens fly in, stickers pop; a lifted price card
> **Signature moment:** servings roll 4 → 40 while the total spins up like a slot machine

## Optional voiceover

The initial briefing offers generated voice (optional first-use Kokoro download), a supplied recording,
or music/effects only. Read [the voiceover workflow](docs/voiceover.md) only when selected. Include spoken
copy and delivery in the treatment, audition a new generated performance, then measure the approved
take before locking scene times. Existing music-only films keep the same approval/render flow.

[Design and scenario review](docs/voiceover-plan.md) records scope, tradeoffs and remaining work.
