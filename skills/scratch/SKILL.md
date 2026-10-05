---
name: scratch
description: Make a hype video for a product from scratch, by answering a few questions and dropping in a logo and screenshots. Interviews the user (product, pitch, features, length, format, platforms, what to show first), then plans, scores and renders an original motion-graphics MP4 on macOS. Use when the user wants a hype, launch or promo video and has no website or project folder to point at.
argument-hint: "[product name]"
---

# motionable: scratch

You're making a short hype video for the user's product, starting from nothing but a conversation. In this step you learn what the product is and collect the pictures. The shared pipeline in **make** then plans, renders and checks the video.

If the user mentions a website or a folder that holds the product, offer to switch to `/motionable:website <url>` or `/motionable:project <path>`. They learn more with fewer questions.

## 0. Find motionable and check the Mac

- **The motionable root** is `${CLAUDE_PLUGIN_ROOT}`. If that text appears unexpanded (e.g. in Codex, where skills are symlinked in), resolve it with `cd "$(dirname "$(realpath <path of this SKILL.md>)")/../.." && pwd`. That's the folder holding `engine/` and `scripts/`; a git clone usually lives at `~/.motionable`. Call it `ROOT` below.
- Run `bash ROOT/scripts/doctor.sh`. If it prints ✗, tell the user the fix it gives and stop. motionable runs on macOS only.

## 1. Ask

Use the **AskUserQuestion** tool if it's available: at most 4 questions per call, clickable options, your recommendation first. Otherwise ask in chat as a short numbered list. If the user passed a product name ($ARGUMENTS), don't ask for it again.

**Round 1** (free text; keep it to one message):
1. The product name exactly as it should appear, and **what it does in one sentence**.
2. Its **2–4 best features**, in the user's words.
3. Who it's for, and a price line if any ("Free", "One purchase. No subscription."). Never invent one.

**Round 2** (clickable):
4. **Length:** 15 s / 30 s (recommended) / 60 s.
5. **Format:** 9:16 for Reels, TikTok and Shorts (recommended) / 1:1 / 16:9.
6. **Where it's available:** App Store (live) / Google Play (live) / Web / Not released yet. Allow several. Ask about "Coming soon to …" lines separately and only use them if true.
7. **What should viewers see first?** Offer the features from round 1.

## 2. Collect the pictures

Ask the user to **drag in, or give paths to: a logo + 3–8 product screenshots** (different screens: the main screen, the best feature, and one more), and brand colours if they know them.
- Look at each image with the Read tool so you know what it shows.
- Pick the colours from the logo and screenshots if none were given.

**Image check:** you need **a logo + at least 3 product screenshots** that show different screens. If you're short, say exactly what's missing and ask once more. If they can't supply them, offer a type-and-shapes film built from colours and words, and say plainly that it will show less of the product.

## 3. Hand off

Read `ROOT/skills/make/SKILL.md` and follow it from step 1, carrying over the answers, the image paths and the colours. Here every fact's source is "the user".
