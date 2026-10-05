<div align="center">
<img width="1774" height="887" alt="motionable" src="https://github.com/user-attachments/assets/a041873e-1d21-4ec4-b69a-d9ff04dee422" />

### ⭐ Stars are appreciated! ⭐

**One shot Hype Video with the latest AI Models**

**Hype videos for your product, drawn in code on your Mac.**
A Claude Code plugin that reads your app, website or project, plans a beat-synced film you approve, composes original music and renders a ready-to-post MP4.

Free · open source · macOS only · nothing to install

<br />

![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg) ![Release](https://img.shields.io/github/v/release/suntay44/Plannable)


<br />
</div>



## Install

```
/plugin marketplace add suntay44/motionable
/plugin install motionable@motionable
```

Desktop app: **+ → Plugins → Add plugin** → `suntay44/motionable`.
Needs macOS 15+ and the Xcode command line tools (`xcode-select --install`).

## Use it

Make one folder for all your videos and open Claude Code there:

```
mkdir ~/HypeVideos && cd ~/HypeVideos && claude
```

| You have… | Run |
|---|---|
| The app's code on your Mac | `/motionable:project ~/Projects/my-app` |
| A website or landing page | `/motionable:website https://my-app.com` |
| Just an idea and some screenshots | `/motionable:scratch` |

## Example runs

**An iOS app repo**

```
/motionable:project ~/Projects/PandaChef
```

→ Reads the README, App Store metadata, design tokens and 11 screenshots (read-only)
→ Asks 4 things: length · format · what to show first · price and availability
→ Shows the beat grid. You approve.
→ `~/HypeVideos/ponda-the-chef/out/ponda-the-chef-hype.mp4`

**A SaaS landing page**

```
/motionable:website https://acme.app
```

→ Pulls the name, pitch, features, colours, logo, screenshots and store links
→ "The site has 1 product screenshot. Drag in 2–4 more."
→ Plan → approve → MP4

**A brand-new idea**

```
/motionable:scratch Acme Notes
```

→ 7 quick questions, then "drag in a logo and 3+ screenshots"
→ Plan → approve → MP4

**Later, in the same folder:**

```
make a 15-second cut of ponda-the-chef
re-render acme-notes with a square format
```

## What you get

```
~/HypeVideos/ponda-the-chef/
├── STYLE.md      concept, colours, motion rules
├── SCRIPT.md     beat grid: every moment, its words and its sound
├── scenes/       the film as Swift code
├── assets/       logo + screenshots (copied, never moved)
└── out/          ponda-the-chef-hype.mp4 · music.m4a · beats.json
```

- **Your real product:** your screenshots, colours and logo. No invented features.
- **Original music:** made in code at 120 BPM, synced to every cut. No licensing.
- **Self-checked:** it scores its own stills (hook, readability, motion, brand) and fixes anything below 8.
- **Store-safe:** Apple's badge is never animated; Google Play is shown only if you're on it.
- **Fast:** a 30 s, 60 fps video renders in about 45 s.

## Codex

```
git clone https://github.com/suntay44/motionable ~/.motionable
mkdir -p ~/.agents/skills
for s in scratch website project make; do ln -s ~/.motionable/skills/$s ~/.agents/skills/motionable-$s; done
```

## More

[ENGINE.md](ENGINE.md) (engine API) · [rules.md](rules.md) (what every film follows) · [checklist.md](checklist.md) (self-critique) · [examples/owly](examples/owly) (the film motionable grew out of)

MIT licence. Apple's badge artwork is never bundled. motionable asks before downloading it from Apple.
