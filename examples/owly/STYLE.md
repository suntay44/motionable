# Owly hype video — style

## Concept: one card, never cut

Everything the viewer sees comes out of the **period at the end of "Son did it."** That dot grows into Mom's list. The list becomes his Home Screen widget, the widget becomes a circle, the circle becomes the load bar, the bar becomes a Decide card, and the card shrinks into the app icon. Each idea changes shape into the next, so the film reads as one continuous thought, not a slideshow.

## Look

| | |
|---|---|
| Canvas | 1080 × 1920, 60 fps, 30.0 s |
| Paper | `#F6F3E8`. Owly is a scribe, so the base is paper and ink, not a gradient |
| Ink | `#10241A` for type on paper |
| Owly green | `#0F9B3E` → `#0B7A31` (hook and end frame) |
| Night | `#0B1020` → `#1A2340`, the son's Home Screen |
| Over red | `#D93B47`, full-bleed when the day is over capacity |
| Themes | Ember `#E0601F`, Ink `#3D4ECC`, Plum `#9B3A8F` |
| People | Mom: Owly green. Leo (the son): `#2F6FE0`. Grandma: `#D98014`. These are the app's participant colours |
| Type | SF Pro (the app's own font). Heavy for headlines, Semibold for lines underneath |
| Texture | A fine film grain over everything, which freezes for the final hold |

## Motion rules

1. **Headlines are left-aligned and big** (up to 112 px), at x = 72. They're revealed line by line from behind a mask and leave upward. Only the end frame is centred.
2. **Hard cuts happen only on the beat.** Changes of shape take 0.25–0.45 s with in-out easing. Anything appearing uses ease-out, sometimes with a slight overshoot.
3. **Camera:** a slow push-in during each scene, eased back on each change of shape. A tiny pulse on every beat. Shake only on a stamp or an impact.
4. **Colour carries the story:** green (Mom), then paper, then night (his phone), then grey (offline), flooding back (online), then paper, then red (over), then four themes, then green.
5. **The last 1.9 s don't move.** No grain, no camera, nothing, so the final frame works as a thumbnail.

## Bans

- No centred headline on a gradient, except the end frame.
- No tilted or covered iPhones, and nothing coming out of a phone screen (Apple's marketing guidelines).
- No made-up features. Every UI element is redrawn from the real app: the widget, the rows, the load bar, Decide, the time chip, "Done by Leo".
- No text in the bottom 20 % or the right 12 % (where TikTok, Reels and Shorts put their buttons).
- No stock music and no voice-over. The score is made in code (`scenes/Owly.swift`, `owlyScore`).

## Sound

- 120 BPM, A minor → F → C → G, one chord per bar.
- A four-on-the-floor kick, claps on beats 2 and 4, an offbeat pumping bass, and a 16th-note pluck arpeggio.
- Every on-screen event has a sound: a stamp hit on each hook word, key clicks while typing, a pop on each tick, a whoosh on each change of shape, a ding on "Done by Leo", a thump on the icon.
- **Offline = underwater:** the whole track is low-pass filtered from 10.0 to 12.0 s, then opens back up on "Syncs when you're back."
- The beat grid is written to `out/beats.json`.
