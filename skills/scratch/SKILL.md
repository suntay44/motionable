---
name: scratch
description: "Make a hype/launch/promo video from scratch: interviews the user and takes a logo and screenshots, then plans, scores and renders an original motion-graphics MP4 on macOS."
argument-hint: "[product name]"
---

# motionable: scratch

You're making a short hype video for the user's product, starting from nothing but a conversation. In this step you learn what the product is and collect the pictures. The shared pipeline in **make** then plans, renders and checks the video.

If the user mentions a website or a folder that holds the product, offer to switch to `/motionable:website <url>` or `/motionable:project <path>`. They learn more with fewer questions.

## 0. Find motionable and check the Mac

- **The motionable root** is `${CLAUDE_PLUGIN_ROOT}`. If that text appears unexpanded (e.g. in Codex, where skills are symlinked in), resolve it with `cd "$(dirname "$(realpath <path of this SKILL.md>)")/../.." && pwd`. That's the folder holding `engine/` and `scripts/`; a git clone usually lives at `~/.motionable`. Call it `ROOT` below.
- Run `bash ROOT/scripts/doctor.sh`. If it prints ✗, tell the user the fix it gives and stop. motionable runs on macOS only.

## 1. Ask

Use the **available user-input tool** (`AskUserQuestion` or its host equivalent): at most 4 questions per call, clickable options, your recommendation first. Otherwise ask in chat as a short numbered list. If the user passed a product name ($ARGUMENTS), don't ask for it again.

**Round 1** (free text; keep it to one message):
1. The product name exactly as it should appear, and **what it does in one sentence**.
2. Its **2–4 best features**, in the user's words.
3. Who it's for, and a price line if any ("Free", "One purchase. No subscription."). Never invent one.
4. *(Optional)* How people should feel about it, in their own words, and anything it must never feel like. This is evidence for plan mode; don't offer style options.

**Round 2** (clickable):
5. **Where will people watch it?** (sets the format and length; "Other" takes any size or length):
   - Reels, TikTok, Shorts: 9:16, 30 s, plus a 15 s cut (recommended);
   - YouTube, a website, a launch post: 16:9, 20–30 s;
   - Feeds (X, LinkedIn, Instagram): 1:1, 15 s.
6. **Where it's available:** App Store (live) / Google Play (live) / Web / Not released yet. Allow several. Ask about "Coming soon to …" lines separately and only use them if true.
7. **What should viewers see first?** Offer the features from round 1.

8. **Would you like a voiceover?** Generate a voice (downloads Kokoro on first use; local, no paid account) / Use my recording (no model download) / No voiceover (music and effects only). Ask only if not already answered; carry the answer and any audio paths into make. For generated voice, check `ROOT/scripts/voice.sh status`; if installed, say it uses the installed local engine. Explain English/Apple Silicon support and setup size from status before setup. Full workflow: `ROOT/docs/voiceover.md`, read only if voice is selected.

## 2. Collect the pictures

Ask the user to **drag in, or give paths to: a logo + 3–8 product screenshots** (different screens: the main screen, the best feature, and one more), and brand colours if they know them. **A short screen recording of the best feature** (QuickTime, the Simulator, or the phone's own screen recording) is the most valuable thing they can add: films that show the app working are the ones people remember. Read it with `bash ROOT/scripts/footage.sh <video>`.
- Look at each image with the Read tool so you know what it shows.
- Pick the colours from the logo and screenshots if none were given.

**Image check:** you need **a logo + at least 3 product screenshots** that show different screens. If you're short, say exactly what's missing and ask once more. If they can't supply them, offer a type-and-shapes film built from colours and words, and say plainly that it will show less of the product.

## 3. Hand off

Read `ROOT/skills/make/SKILL.md` and follow it from step 1, carrying over the answers, the image paths, the colours and **personality notes** (the user's own words, the logo's style, the screenshots' feel) for plan mode. Here every fact's source is "the user".
