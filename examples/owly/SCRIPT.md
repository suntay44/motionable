# Owly — 30-second hype video: beat grid

9:16, 60 fps, 120 BPM (one beat = 0.5 s, one bar = 2 s). The style rules are in [STYLE.md](STYLE.md), and the code is `scenes/Owly.swift`. The times below are the `T` constants in that file. Change them there, and the picture and the sound move together.

| Time (s) | Bar | Picture | Words on screen | Sound |
|---|---|---|---|---|
| 0.00 / 0.25 / 0.50 | 1 | On Owly green, three words stamp in one under another; the first frame already shows "Mom" | **Mom / wrote / it.** | Impact, then a stamp + chord stab on each word |
| 1.00 / 1.25 / 1.50 | 1 | Hard cut to paper, the words in Leo's blue | **Son / did / it.** | Stamp + stab on each word, riser |
| 1.75 | 1 | The period of "it." pulses and turns green | | Pop |
| 2.00 – 2.45 | 2 | **The period grows into Mom's list** ("Todo list for my son") | **You write it.** | Whoosh. The beat starts: kick, hats, bass, arpeggio |
| 2.50 – 3.50 | 2 | "Practice piano 4pm" is typed into the add field | | Key clicks |
| 3.60 | 2 | A **4 pm** chip pops in | | Pop |
| 3.75 – 5.50 | 2–3 | Rows drop in: Practice piano · Feed the dog · Put the bins out · Pack gym clothes · Math homework (already ticked by Leo, with his blue **L**) | | Pop per row, riser |
| 6.00 – 6.45 | 4 | **The list folds into the "Tasks from Mom" widget.** The background sweeps to night, and Home Screen icons fade in around it | **It's on his Home Screen.** *He sees it as "Tasks from Mom".* | **Drop:** impact, crash, full beat |
| 8.50 | 5 | A tap on "Pack gym clothes": ripple, tick, strike-through, 2/5 | **He ticks it off.** *You see who did it.* | Click + pop |
| 8.90 | 5 | A banner on **Mom's iPhone**: "Done by Leo: Pack gym clothes" | | Ding |
| 10.00 | 6 | The Wi-Fi icon gets crossed out, an **Offline** pill appears, and the whole frame drains to grey | **Works offline.** *No signal? Keep ticking.* | **The music goes underwater** (low-pass) |
| 11.00 | 6 | He ticks "Feed the dog", still offline: 3/5 | | Muffled click + pop, riser |
| 12.00 | 7 | The Wi-Fi comes back, and **colour floods out from the icon**. The pill turns green: **Back online** | **Syncs when you're back.** | The music opens back up, crash |
| 12.50 | 7 | Banner: "Done by Leo: Feed the dog" | | Ding |
| 14.00 – 14.40 | 8 | **The widget becomes a green circle.** Paper wipes in from it | | Whoosh |
| 14.50 / 14.75 / 15.00 | 8 | It splits into three circles: **Mom · Leo · Grandma** | **Circles.** *Shared to-do lists for your whole family.* | Pop per circle |
| 15.75 – 16.30 | 8–9 | **The circles merge and stretch into the load bar** | | Whoosh |
| 16.50 / 17.00 / 17.50 / 18.00 | 9 | Task chips drop into the bar: Q3 budget review 1h · Prep Monday's pitch 1h · Call mum 20m · Pay the electricity bill 20m. The bar fills green, then amber | **Know when your day is full.** | Pop per chip, riser, snare roll |
| 18.50 | 10 | "Clear out the garage 1h" goes past the **3h** mark: **3h 40m / 3h**. Hard cut to full red, shake | **More than fits.** *40m over. Something here is tomorrow's problem.* | Impact, crash |
| 20.00 – 20.45 | 11 | **The bar thickens into a Decide card.** Paper wipes in | **Settle what you keep putting off.** | Whoosh |
| 21.00 – 21.60 | 11 | PUSHED 5 TIMES · *Book the car service*: **Drop it**, and the card flings left | | Click, whoosh |
| 22.75 – 23.35 | 12 | PUSHED 3 TIMES · *Renew passport*: **Do it today**, and the card flings right | | Click, whoosh |
| 23.25 | 12 | PUSHED 4 TIMES · *Fix the bike light* drops in | | |
| 24.00 – 24.30 | 13 | **The card folds back into the widget.** Owly green floods in from it | **Make it yours.** *Themes, widget backgrounds, your own photo.* | Whoosh, crash |
| 24.50 / 25.00 / 25.50 / 26.00 | 13 | Hard cuts on each beat: **Ember → Ink → Plum → Owly**. The widget's accent changes with each | Theme name under the widget | Stab + click per cut |
| 26.25 – 26.60 | 14 | **The widget shrinks into the app icon** | | The beat drops out, riser |
| 26.50 | 14 | The icon lands | | **Thump**, final chord |
| 26.75 / 26.90 / 27.05 | 14 | Lines rise in under the icon | **Owly the Scribe** · *To-do lists for the whole family.* · One purchase. No subscription. | Soft pops; the chord rings out |
| 27.25 | 14 | Apple's official **Download on the App Store** badge cuts in and holds still. A glow ring pulses out behind it, outside its clear space (Apple doesn't allow animating the badge). `BADGE_GROW=1` renders a variant where the badge swells instead | | Bright pop and a soft ding |
| 27.75 | 14 | The whole frame blurs, and **Soon on Google Play** (plain text, no Google artwork) lands big in the middle | **Soon on Google Play** | Whoosh into a stamp |
| 28.50 – 28.90 | 15 | The line shrinks into place under the badge while the frame sharpens | | Whoosh down, pop |
| 28.90 – 30.00 | 15 | **Everything holds still** | | The chord fades to silence |

## Checks before posting

- [ ] **"Syncs when you're back."** Test one offline edit syncing back once the connection returns, on two phones (`Docs/CLOUDKIT.md`). If it fails, cut the 12.0–14.0 s line and the second banner.
- [x] The completer's initial on circle ticks: tested on two phones on 1 Oct (`Docs/LAUNCH.md`).
- [x] "Done by Leo: …" uses the format of the real notification (`Shared/CircleActivity.swift`).
- [ ] Post only after 1.0 is released: the badge says **Download**.
- [ ] "Soon on Google Play" must be true. Google's badge artwork is left out on purpose, because Google allows it only for apps already on Play.
- [x] The day-limit wording matches the app: "More than fits", "Something here is tomorrow's problem".
