# Owly — capacity benchmark

| Time | Picture / primary action | Words | Sound / pause |
|---|---|---|---|
| 0–3.2 | Real Today screen right; mascot supports the hook | A day has a ceiling. Make room for today. | Quiet bed; reading pause after 1.1 |
| 3.2–4.1 | Same screen glides left; dot carries across a curved path | Small persistent brand annotation | No effect required |
| 4.1–7.9 | Capacity region lifts from the same screen and settles by 4.75; headline fades in 4.75–5.1 | Know when your day is full. Your tasks. Your capacity. | Focus accent; hold |
| 7.9–11.25 | Dissolve between two real screenshots, including the lifted region | See when there’s more than fits. | Warning accent at 8.4; hold |
| 11.25–13.2 | Screen fades by 11.65; brand arrives from 11.7 and settles by 12.4 | Owly the Scribe. Plan what fits. An honest to-do list. | Bed resolves |
| 13.2–15 | Sharp, fully frozen visual hold | Same end card | Music fades |

## Claims and sources

- Capacity and overcommitment: TODO-LIST-APP/Shared/TaskLogic.swift:243–260, Tests/TaskLogicTests.swift capacity cases.
- Exact warning copy and screenshot states: App/LoadMeter.swift:76–85 and Website/owly-today.png / owly-over-capacity.png.
- No price, availability, cloud sync or unsupported functionality claim.
- Two still UI states are presented as evidence; no claim of recorded continuous app interaction.

## Action timing and continuity

| Identity | Role | Move / settle / read hold | Curve / path | Handoff |
|---|---|---|---|---|
| Today screen | Primary | 3.2–4.1; holds before/after | Bezier .65,0,.35,1 | Same bounds source for the focus lift |
| Mascot | Supporting | .35–1; then still | Finite spring response .45 damping .85 | Ends with hook |
| Dot | Supporting | 3.2–4.1 | Hermite through middle point at 3.65 | Fades out; no informational role |
| Meter | Primary | 4.15–4.75; holds 4.75–7.9 | Existing focus lift | Real warning state 7.9–8.4 |
| End lockup | Primary | 11.7–12.4; subline 12.5–12.85 | Ease out / fade | Frozen from 13.2 |

## Motion review

- First pass: closing sentence needed 2.87 seconds but had 2.45; shortened to “An honest to-do list.” (needs 1.80 seconds; final timing provides 2.15).
- First visual pass: meter focus included a small sliver of the preceding heading; moved the requested region down and matched the lift origin to the fitted screen bounds. Rerendered storyboard: all four frames clean; readability/layout check: readable.
- Inspected the storyboard and dense rendered screen-glide/focus/state-change sequences. End PNGs at 13.2 and 14.8 seconds are byte-identical.
- Final MP4: 1920×1080, 60 fps, 900 decoded frames, 15 seconds, audio present. Draft: 960×540, 30 fps, 450 decoded frames. Full presentation timestamp grids verified.
- Continuous normal-speed playback and audio listening were not assessed. Levels and audio presence do not certify sound quality.
- Full plugin regressions passed; OwlyLogic app tests: 572 executed, one opt-in screenshot-art test skipped, zero failures. See docs/motion-validation.md in the plugin root for scope and limits.

- Dense motion review: the focus lift crossed the headline at 4.18–4.32 and the brand overlapped the phone at 11.4–12.0. Headline now arrives after the lift settles; brand begins after the phone clears. Targeted storyboard, readability, motion and export checks rerun.
