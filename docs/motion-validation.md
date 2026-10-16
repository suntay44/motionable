# Motion craft validation — 9 October 2026

This records implementation evidence for the five requested improvements. It is not a certification of professional visual quality.

## Changes exercised

| Improvement | Implementation | Evidence |
|---|---|---|
| Creative rules | PLAN.md, rules.md, checklist.md, make skill and templates permit deliberate stillness and repeated layouts; effect quotas removed | Owly benchmark uses reading holds and one persistent screen composition |
| Shot connections | Action timing/identity tables, MotionPath and SharedElement | Numerical velocity continuity tests; dense screen-glide sequences |
| Motion control | Custom Bezier/easing and finite spring curves; opt-in temporal layer blur | Curve endpoints, Bezier time inversion, endpoint settling, pixel coverage, default-curve compatibility and actual-render-cadence tests |
| Artwork direction | Artwork specification, source/role/treatment table and copied-asset hashes | Five Owly assets match supplied files; screenshot state claims checked against current app source |
| Moving-sequence review | `motion` command writes a draft, dense sequences and timestamps; review checklist records what was assessed | 11 sequence sheets and a 30 fps draft; full-rate final MP4 separately validated |

## Checks run

- `bash scripts/test.sh`: passed. Includes choreography, offline narration and footage regressions, ingredient gallery, planted layout failures and every example film. Current examples report readable. The historical v0.1 Owly example retains 86 pre-existing audit notes and is only required to build, as before.
- `bash scripts/test-motion.sh`: passed again after adding pixel comparisons proving the legacy entry/exit curves remain unchanged and that a curve override affects rendering. Tests also verify that temporal shutters use the actual draft cadence.
- Owly craft `storyboard`: four clean keyframes. `check`: every text line has its required reading time; safe zones, dead air, flashing, contrast and layout pass.
- Owly craft `motion` and `video`: completed. Final: 1920×1080, 60 fps, 900 decoded frames, 15 seconds, one audio track. Draft: 960×540, 30 fps, 450 decoded frames, 15 seconds, one audio track. Both have the complete expected presentation timestamp grid.
- Final hold: rendered PNGs at 13.2 and 14.8 seconds have identical SHA-256 hashes. Decoded video frames at 13.5 and 14.5 seconds differ by less than 0.1 intensity levels on average at a 320×180 comparison size; minor codec variation is expected.
- Sound comparison: maximum measured similarity to another example is 0.64. This metric detects similarity, not listening quality. The tool's wording now states that limitation.
- A fresh film created through `new.sh` successfully built and rendered with its copied engine. Shell syntax and whitespace checks pass. Standard skill frontmatter validates after excluding the plugin's existing `user-invocable` and `argument-hint` routing extensions from a temporary validation copy; those extensions are preserved in the real skill.
- TODO-LIST-APP: the existing `OwlyLogic` Mac Catalyst test scheme executed 572 tests, one opt-in screenshot-art test skipped, zero failures. Local test signing was disabled to avoid a signing-environment failure. Derived data and results live under this plugin's ignored `.build/validation/`, outside the app repository. No app source changes were made.

## Review observations and limits

The first visual/readability pass caught a closing sentence that needed more reading time and a sliver of the preceding screenshot heading in the meter focus. The sentence was shortened and the focus region moved below that heading. Dense sequence inspection then found the lift crossing the headline and the closing brand overlapping the fading phone. The headline now waits until the lift settles; the brand begins after the phone clears. Targeted checks and exports were rerun after those timing fixes.

The storyboard and dense rendered motion sequences were inspected. The screen stays the same identity during its glide, the focus lift resolves to a readable real meter, and the end card holds. The benchmark presents two real screenshot states; it does not claim a captured continuous app interaction. CloudKit/shared-family behavior, price and availability are excluded from its claims because the app's own documentation does not verify them for this test.

Continuous normal-speed playback and listening quality were not assessed. Audio presence and levels are measured only; the soundtrack still needs listening review. No iOS UI-test or two-device CloudKit run was performed. This is an original capacity-focused benchmark, not a reproduction of the reference video or a claim about its undisclosed source code.

The decoded export assertions are maintained in `tests/motion/inspect-video.swift`; `scripts/test-craft.sh` reproduces the benchmark checks and both exports.

Detailed local logs and the Xcode result bundle are in `.build/validation/` (ignored). The maintainable benchmark direction, script, scene source and asset provenance are in `examples/owly-craft/`.
