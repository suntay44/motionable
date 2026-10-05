# motionable

**Hype videos for your product, drawn in code on your Mac.**

Point motionable at your app, website or project folder. It learns what the product does, plans a beat-synced film for you to approve, composes original music, and renders a ready-to-post MP4: 9:16 for Reels, TikTok and Shorts, or square or wide. No templates, no stock music, nothing to install.

```
/motionable:scratch                      start from scratch: answer a few questions, drop in screenshots
/motionable:website https://your.site    read your website
/motionable:project ~/Projects/my-app    read a folder on your Mac (a repo, or screenshots and notes)
```

## One studio for all your videos

Make a folder for hype videos, open Claude Code there, and point it at any product. Each film gets its own folder, and your app repos are only read, never written to:

```
~/HypeVideos/                         ← open Claude Code here
├── owly/          STYLE.md  SCRIPT.md  scenes/  assets/  out/owly-hype.mp4
├── acme-notes/    …
└── my-game/       …
```

Come back any time in the same folder and say "make a 15-second cut of owly" or "re-render acme-notes".

## What you get

- **A plan before anything renders:** `STYLE.md` (concept, colours, motion rules) and `SCRIPT.md`, a beat grid of every moment, its words and its sound. You approve it first.
- **Your real product:** your logo, your screenshots and your colours, with key UI elements redrawn so they can animate. Nothing invented.
- **Original music, made in code:** 120 BPM, with every on-screen moment getting its own hit, whoosh or pop. No licensing, ever.
- **A critique loop:** it renders contact sheets, scores hook, readability, story, motion, brand, rules and sound, and fixes anything below 8.
- **Store-safe endings:** Apple's App Store badge used the way Apple allows (never animated), and Google Play only when the app is really there.
- **Fast:** a 30-second, 60 fps video renders in about 45 seconds. Change a line and re-render.

## Requirements

- **A Mac on macOS 15 or later.** motionable draws with Apple's built-in frameworks, so it runs on macOS only.
- **Xcode or the free command line tools** (`xcode-select --install`).
- **Claude Code** (terminal or the desktop app's Code tab). Codex works too (see below).

That's all: no ffmpeg, no Node, no browser, no API keys.

## Install

**Claude Code (terminal):**

```
/plugin marketplace add suntay44/motionable
/plugin install motionable@motionable
```

**Claude desktop app (Code tab):** **+ → Plugins → Add plugin**, enter `suntay44/motionable`, then install **motionable**.

**From a local clone** (for development): `/plugin marketplace add /path/to/motionable`, then install as above.

**Codex:** skills follow the open Agent Skills format.

```
git clone https://github.com/suntay44/motionable ~/.motionable
mkdir -p ~/.agents/skills
for s in scratch website project make; do ln -s ~/.motionable/skills/$s ~/.agents/skills/motionable-$s; done
```

Then ask Codex to use the motionable-scratch, motionable-website or motionable-project skill.

## How it works

1. **Learn:**
   - `scratch` interviews you;
   - `website` reads your site (and its App Store page, if it has one);
   - `project` reads a folder: README, app metadata, store listing drafts, icons, screenshots, colours.

   The last two ask only about gaps.
2. **Collect:** it needs a logo and at least 3 product screenshots. If it finds fewer, it tells you exactly which ones to drop in.
3. **Plan:** it writes a concept and a beat grid, and you approve or change it.
4. **Build:** it writes `scenes/Film.swift` on the motionable engine (see [ENGINE.md](ENGINE.md)), scores the music, and runs the critique loop.
5. **Deliver:** `<product>/out/<product>-hype.mp4` in your studio folder, plus the list of claims to double-check before you post.

## Repo layout

```
.claude-plugin/   plugin.json + marketplace.json
skills/           scratch · website · project · make (the shared pipeline)
engine/           Swift: canvas, motion, score, render, main
scripts/          doctor.sh · new.sh · run.sh
templates/        Film.swift starter · STYLE.md · SCRIPT.md
examples/owly/    the film motionable grew out of
ENGINE.md rules.md checklist.md
```

## Rules it follows

See [rules.md](rules.md): truth (no invented features), Apple's and Google's badge guidelines, upright iPhones, social safe zones, a hook in frame 1, and a still final frame.

## Licence

MIT, see [LICENSE](LICENSE). Apple's badge artwork is never bundled. motionable asks before downloading it from Apple's marketing toolbox into your project.
# motionable
