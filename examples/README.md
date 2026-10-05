# Example films

Each folder is a finished film: its plan (`DIRECTION.md`), its beat grid (`SCRIPT.md`), the film as Swift (`scenes/`), and its assets. They were made the way `/motionable:project` makes a film, and they double as motionable's regression tests.

| Film | Format | What it shows |
|---|---|---|
| [ponda-the-chef](ponda-the-chef) | 9:16 · 30 s · Reels, TikTok, Shorts | A problem hook ("Cooking for 40?"); servings roll 4 → 40 on the real Scaling screen; the cost per plate lifts out; the cart's total; proof chips; punchy pop at 122 BPM |
| [owly-wide](owly-wide) | 16:9 · 23 s · YouTube, a website | Mom's texts pile up; her list lands on her son's widget, he ticks it, "Done by Leo" arrives; the day-is-full bar; a drawn quill; piano and kalimba at 88 BPM |
| [bonnie](bonnie) | 1:1 · 15 s · feeds | Night turns to morning in one shot and the watch answers "Ready"; the bedtime tile under a spotlight; a 3/4 music-box lullaby at 72 BPM |
| [owly](owly) | 9:16 · 30 s | v0.1: the film motionable grew out of |

Render one (macOS, about a minute):

```bash
bash scripts/run.sh examples/bonnie video
```

The MP4 lands in `examples/bonnie/out/bonnie.mp4`.

**Assets.** The screenshots, icons, mascots and logos in `examples/*/assets/` belong to their apps (© 2026 Christian Patrick Suntay). They're here only to show what motionable makes, and they are **not** covered by the MIT licence: please don't reuse them. The Claude-drawn SVGs in `assets/drawn/` are MIT, like the code.
