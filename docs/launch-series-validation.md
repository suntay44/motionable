# Launch series validation — October 16, 2026

The user approved Owly’s stronger visual treatment, requested official App Store badges, and asked for matching Ponda and Dove films. All three releases are owner-confirmed live. Product repositories were read only. Sources and asset manifests are in `examples/owly-launch`, `examples/ponda-launch` and `examples/dove-launch`.

## Changes reviewed

Reviewed all maintained uncommitted engine, skill, template, example, documentation and helper changes before committing to `main`. The choreography API is opt-in; default easing remains compatible. Motion review generates a draft and timestamped dense sequences. Sound comparison now describes a similarity metric rather than claiming a listening verdict. Guidance calls for product evidence and meaningful action instead of arbitrary effect quotas.

Review found that a moving crop advisory and a later fixed crop failure could share one audit key. The classifications now remain separate; a regression checks both observations of the same image and edge. The recording helper exposes a camera flag only for actual camera movement.

Local narration auditions and scratch films are preserved but ignored. Compiled engines, rendered MP4s, validation logs and Apple’s standalone badge artwork are excluded. The explicitly invoked badge helper downloads unmodified artwork from Apple. Published examples use text availability if the optional file is absent; the local final films contain the official badge.

## Verification

- Full `scripts/test.sh`: passed. Choreography, camera classification, optional narration, footage CLI, gallery, intentional audit failures and every maintained example were checked. Older examples retain their documented compatibility notes.
- Ponda’s final live-availability example passed both master and short checks after the owner’s confirmation.
- Shell syntax and staged whitespace checks: passed.
- All four new example asset manifests match their SHA-256 hashes. Commit candidates are below GitHub’s 100 MB file limit.
- Launch films: master and short readability/layout checks passed. Whole-film sheets, settled storyboards and selected dense sequences were inspected. Detailed observations and subjective visual scores are in each SCRIPT.md.
- Audio peaks 0.74–0.77; RMS approximately 0.200–0.201. Maximum measured comparison scores remain below the 0.85 review threshold. No subjective listening quality is claimed.

## Export evidence

Each delivery is 1080×1920 at 60 fps, H.264 with an audio track. Every video frame was decoded and its presentation timestamp checked. Masters contain 1,800 frames / 30 seconds; short cuts contain 900 frames / 15 seconds. Closing-hold mean pixel differences must be below 0.5.

| Film | Master closing difference | Short closing difference |
|---|---:|---:|
| Owly | 0.304 | 0.261 |
| Dove | 0.186 | 0.225 |
| Ponda | 0.268 | 0.236 |

Playback was sampled, not continuously observed. Short cuts were reviewed through rendered motion sequences. Final Dove playback review was interrupted by user control. Ponda’s final badge layout was also inspected at 29 seconds. Audio presence, levels and cue timing were measured; the final soundtrack still benefits from human listening. These are launch ads rather than App Store preview submissions. The renderer is Motionable’s native Swift engine; HyperFrames references informed visible treatment, not a claim about the renderer or reference source code.

Local export logs are in ignored `.build/validation/`. README GIFs are silent 270×480 previews at four frames per second; full MP4s are rendered locally using each example’s README.
