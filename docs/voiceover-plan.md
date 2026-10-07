# Optional voiceover: product and implementation plan

Status: initial integration implemented (2026-10-07); final validation results below. This document records the design and broader scenario backlog; operational instructions live in [voiceover.md](voiceover.md). Initial scope: optional native Kokoro preparation on Apple Silicon, a fixed English voice, recording import, approved-take validation, clean mixing, no-voice variants and phrase SRT export. Cloud/STT, additional voices/languages and automatic burned-in captions remain deferred. Scenarios below are acceptance targets, not a claim that every route is implemented. The current music-and-effects workflow stays the default.

## What the user chooses

Add one question to the initial briefing in project, website and scratch, after platform/length and before the story is timed. Do not ask again if the user already specified a preference.

> Would you like a voiceover?
>
> - Music and sound effects only — the current experience.
> - Add a natural-sounding generated voice — preview it first; runs locally after optional setup; an external service is an optional alternative.
> - Use my own voice recording — import an existing take and confirm its spoken words.

Proposed source support: both generated speech and supplied recordings. Prefer evaluating local Kokoro for generated speech, based on the existing Watch-Health-Tracker implementation. This is a candidate decision, pending a video-specific audition and macOS packaging check. No voice is selected automatically merely because a service is connected. After choosing generated voice, show local setup or an explicitly selected cloud service; keep backend names out of the initial creative question.

When voiceover is selected, collect only missing details in one short follow-up:

- Language and accent; a specific voice preference if the user has one.
- Delivery: recommend a direction from the product's personality, such as warm and conversational, calm and reassuring, or bright and confident. The user can describe something else.
- Coverage: a few key lines or narration through most of the story. Recommend sparse narration for short, visually driven films.
- Product-name pronunciation and any unusual names, abbreviations or numbers.
- Captions: recommend readable phrase captions, with room reserved in the layout. Offer no burned-in captions when the destination will add them; keep the visual story understandable without sound.

Avoid a menu of technical settings. Map the approved direction to provider controls internally. Voice selection should not force a generic visual style or replace the evidence-based direction.

## How a narrated film gets made

1. Learn the product and record the voiceover choice with the other initial answers.
2. Write the story, on-screen copy and spoken copy together. Narration adds context or emotion; it does not mechanically read every UI label and headline aloud.
3. Present the usual treatment and beat grid, with an optional **Voice** line and the exact spoken script. Include the selected source, expected generation cost or the fact that cost is not yet known, and pronunciation notes. Agree on the script and voice direction before generating the full take.
4. For generated speech, preview roughly 5–8 seconds containing the product name and a representative sentence. Offer at most two suitable voices/takes initially. Ask which sounds right before producing the final performance; skip a redundant audition when the user explicitly chose a known voice or supplied an approved take. Auditions can also incur provider charges, so include them in the agreed generation budget.
5. Produce one coherent narration take for a short film. Preserve the surrounding text when a provider supports contextual pickup lines. A whole take is the default so every sentence does not sound like a separate announcement.
6. Measure the actual recording and align its spoken phrases. Fit the scene timing to the approved speech and music grid, then lock the storyboard. Do not treat a word-count estimate as measured timing.
7. Compose and mix around the voice. Check a dry voice preview, then the voice with music, effects and picture. Reuse the approved take during visual revisions.
8. Deliver the narrated master, a version without narration if requested, and the narration/caption assets. Keep existing revisions bounded: one repair batch per feedback round, and no automatic regeneration loop.

The extra audition is conditional on voiceover. Films without narration retain the existing approval and rendering flow.

## What makes it sound natural

These are creative acceptance criteria, not a guarantee supplied by a model name:

- Short spoken sentences, contractions where appropriate, and one thought per phrase.
- Direction tied to meaning: where to pause, what word to emphasize, and how the feeling changes. Avoid exaggerated announcer delivery unless explicitly requested.
- Natural pauses and varied sentence rhythm. Do not snap syllables to musical beats or add artificial breaths to every line.
- Correct pronunciation of names, prices, acronyms and numbers. Store pronunciation overrides separately from display copy and captions.
- One consistent voice, language and delivery across takes and versions. Keep the selected voice/model/settings with the saved audio.
- No awkward joins, clipped consonants, missing words, unwanted laughter or unrequested vocal sounds.
- Listen to the take. Level checks and transcripts cannot prove that a performance sounds human. If the assistant cannot audition audio, say so and rely on the user's preview selection rather than claiming a listening review occurred.

A practical English drafting budget is about 20–28 spoken words for a 15-second film and 45–60 for 30 seconds. These are starting budgets for sparse narration, not speed requirements or universal limits across languages. Actual audio decides whether it fits. Shorten the copy or move a scene boundary when necessary; do not force a long script into a short cut by speeding up the voice.

## TTS, transcription and timing are separate capabilities

| Need | Capability | Download or service required? |
|---|---|---|
| Existing music/effects film | None | No speech dependencies |
| Generate narration from approved words | Text-to-speech (TTS) | Local model/runtime installed once, or an explicitly chosen hosted service |
| Import a recording with known words | Audio import | No TTS or speech recognition; phrase timing can be reviewed manually |
| Discover words in a recording without a transcript | Speech-to-text (STT) | Optional transcription model/service, only when this is requested |
| Locate known words in audio | Alignment | Use trustworthy source timing, manually reviewed phrase boundaries, or a separately selected aligner |
| Render an approved film again | Saved audio and timing | No model, account or network required |

Do not download a TTS-and-STT bundle for every voice request. Transcription is not required to read a script aloud. Even when the script is known, its precise timing is not known until audio exists. A transcript also needs review; recognition is not proof that the audio contains every intended word.

## Reference implementation: Watch-Health-Tracker

Inspected 2026-10-06, without running setup, modifying that project or regenerating speech. These are code findings; the reference project's historical measurements were not repeated in this review.

- `tools/luna/get-luna.sh` downloads a pinned Kokoro int8 ONNX model (about 88 MB), a voices archive (about 27 MB), and Misaki US word lists (about 6 MB). It verifies SHA-256 hashes and makes the converted model, an `af_heart` voice file (about 0.5 MB), and a lexicon (about 5 MB). Those sizes exclude the separately downloaded ONNX runtime and setup intermediates.
- `Packages/OnnxRuntime/Package.swift` pins ONNX Runtime 1.24.2 with a binary archive checksum. Declaring macOS support in that package does not establish that our command-line distribution and linking work; test those explicitly.
- `App/Luna.swift` generates 24 kHz audio locally, shares in-flight work and caches pieces in memory. `KokoroPhonemizer.swift` implements an English lexicon/rules path with limited handling of unknown words. This is TTS, not STT.
- `App/BunnyVoice.swift` can switch the entire reading to Apple's voice for missing assets, slow generation or unknown words. That serves a live app's response-time needs. A rendered film must preserve its selected narrator instead: report the problem, correct pronunciation or select a different take explicitly.

Reuse candidates: pinned asset manifests, checksums, model conversion, phonemization, pronunciation overrides, serialized inference and duplicate-request suppression. Keep runtime/model installation shared across films, but save approved audio with each film.

Adaptation work: extract a standalone macOS synthesis helper with a stable file contract; avoid importing the sleep application's UI, logging, health logic, `SleepCore` wholesale or bundle-only resource lookup. Review attribution and dependencies for copied components. The plugin must not depend on the sibling checkout existing on another user's machine.

Do not blindly reuse the app's roughly four-second chunking, fixed inter-piece pauses, aggressive quiet-end trimming, six-second live timeout or memory-only cache. Videos can wait for a complete take. Compare sentence-sized and longer supported chunks for natural continuity, preserve breaths/consonants and persist approved output. Respect model token limits without chopping words. Model-conversion quality and speed require fresh checks on the supported Macs.

## Source and provider decision

**Recommendation for evaluation: local Kokoro first, imported recordings always supported, cloud generation optional.** Implement one common local-audio contract; every source passes through the same timing and mix pipeline.

| Candidate | Why evaluate it | Gate before shipping |
|---|---|---|
| Kokoro through ONNX, adapted from Luna | Existing Swift integration and a known voice; offline generation after setup, no hosted per-request fees | Real marketing-script auditions, pronunciation coverage, macOS packaging, dependency/voice notices, measured runtime and total download size |
| Supplied human or externally generated take | Broadest voice/language flexibility; no synthesis account or model needed | Decode, transcript/timing review and acceptable recording quality |
| ElevenLabs, optional later adapter | Alternative performances and source alignment | Audition, account/voice availability, supported controls, commercial-use eligibility, budget and data handling |
| whisper.cpp, optional later transcription helper | Local transcription for recordings lacking words | Separate opt-in setup, language-appropriate model, accuracy review; not installed for ordinary TTS |

The [Kokoro model card](https://huggingface.co/hexgrad/Kokoro-82M) identifies Apache-2.0 weights. The [kokoro-onnx project](https://github.com/thewh1teagle/kokoro-onnx) identifies MIT code and separate model assets. Review the exact pinned distribution and its notices, including runtime and phonemizer components; a model license alone does not describe the whole installed stack. The reference's US-English phonemizer does not inherit all languages of other Kokoro integrations.

[whisper.cpp](https://github.com/ggml-org/whisper.cpp) provides local transcription with separately downloaded models and labels word-level timing experimental. It is an optional convenience, not the minimum caption dependency. [WhisperX](https://github.com/m-bain/whisperX) uses separate alignment models and documents limitations with numbers and overlapping speech; do not add that larger stack merely to show phrase captions.

ElevenLabs documents [speech with character timing](https://elevenlabs.io/docs/api-reference/text-to-speech/convert-with-timestamps/) and [model-specific delivery guidance](https://elevenlabs.io/docs/overview/capabilities/text-to-speech/best-practices). Its [publishing policy](https://help.elevenlabs.io/hc/en-us/articles/13313564601361-Can-I-publish-the-content-I-generate-on-the-platform) says free-plan output lacks a commercial license. Advertising use therefore needs an eligible plan and applicable voice terms. Its [zero-retention option](https://elevenlabs.io/docs/eleven-api/resources/zero-retention-mode) is not a universal account default. Verify terms and capabilities at implementation time.

No provider guarantees a human-sounding result for every script. Voice quality is a listening decision. Start with one tested stock voice and single-speaker English; expand only after separate language/accent tests. Cloning, multi-speaker dialogue, singing and lip-synchronized dubbing are outside the first release.

## Installation, privacy and failure contract

1. No narration means no model checks, downloads or runtime setup. Imported takes need only the existing audio frameworks.
2. Before local setup, show the pinned components, download size, expected installed footprint, hardware/OS support and shared cache location. Exact totals remain a packaging milestone; “88 MB” describes one model, not the complete installation. Use an isolated helper/runtime, not global Python modifications or privileged installation.
3. Fetch only missing verified assets. Download to temporary paths; verify before atomic promotion, and retain a previously working installation on interruption, full disk or checksum failure. Serialize concurrent setup. Provide progress, cancellation, repair and removal; removing model caches must not delete film recordings.
4. Separate “allow model setup downloads” from “allow sending script/audio to a service.” A local-only project never uploads script or recordings. Offline first use with missing assets explains what is unavailable; no automatic cloud fallback. Once all dependencies are installed, local synthesis must pass a network-disabled check.
5. Cloud requests require the selected account, a known or explicitly accepted budget, and permission for the needed script/audio transfer. Send only required material. Credentials stay outside films, generated code and logs. Transcribing an uploaded recording is a separate transfer from TTS of text.
6. A failed preview, missing voice, timeout or rate limit retains prior approved audio. Bound retries; an ambiguous charged timeout must not trigger repeated paid requests blindly. Cancel safely and discard incomplete output. Never silently switch narrator or deliver music-only when narration was requested.
7. Ordinary check/storyboard/audio/draft/video operations read saved assets only. If a take is absent or stale, stop with the preparation step required. An intentional preview may use the old take only when clearly marked stale; final export requires current approval.
8. Cache synthesis by complete input identity, including model/voice checksums, helper/phonemizer version, language, pronunciation and settings. Persist take approval separately from mix approval. Model updates do not silently replace an approved take. Deterministic export means reuse of recorded samples; do not promise bit-identical fresh TTS across runtimes.

## Project assets and timing contract

Proposed additions for a narrated film:

```text
assets/voice/
  narration.wav           approved dry take, normalized to the engine format
  narration.json          versioned manifest, script identity and phrase timing
out/
  mix.m4a                 final narration + music + effects
  narration.m4a           narration on the film timeline
  captions.srt            phrase captions when requested
```

Keep an original supplied recording untouched and copy it into the film. Decode supported WAV, M4A and MP3 through Apple's audio frameworks; convert once to the engine's 48 kHz floating-point PCM working format. Preserve channels on import and center spoken mono audio in the mix. Inspect duration, silence and peaks; reject corrupt, empty or non-finite input with a clear error.

The manifest records a schema version, source type, exact spoken text, pronunciation substitutions, language, voice/model/settings where applicable, audio checksum, measured duration, approval state and phrase intervals. Each phrase has a stable ID, source-audio in/out times, film start time and caption text. Times are seconds, not beat indices. Validate bounds and ordering; allow pauses but no accidental duplicate or overlapping speech.

Generated alignment refers to source audio. Convert it to film time after any leading-silence trim or placement change. For a supplied recording, use a provided transcript with alignment, or reviewed phrase timing; transcription and alignment are separate optional service capabilities. Never fabricate precise subtitle times from word counts. Phrase-level timing is enough for the first release; word-by-word highlighting can come later.

Hash the spoken text, pronunciation data, voice, model and generation settings for the audio cache. A layout, colour, camera or music change must not regenerate speech. A changed script or voice invalidates the relevant take and requires a new preview/approval within the agreed revision budget. Preserve approved takes if a replacement request fails.

## Engine integration and compatibility

The current `Score.finish` processes music buses, combines effects, applies the selected sound colour and masters the result. Narration needs its own path:

1. Add optional narration configuration with an empty/default-off value, and an audio loader/timeline mixer in a dedicated `engine/Narration.swift`.
2. Keep the current non-narrated rendering path intact. Existing films without narration must produce the same audio samples and require no network or account.
3. On narrated films, process the music/effects bed first. Apply a smooth speech-driven attenuation envelope to the bed; start with an auditionable 6–10 dB reduction, short lookahead/attack and a slower release. These are initial tuning values, not a loudness standard.
4. Add the clean voice after musical tape stops, muffling, saturation, echo and kick-driven ducking. A musical pause must not cut off a word or change its pitch. Let strong sound effects sit between phrases or attenuate them under speech.
5. Reserve output headroom and check decoded final audio for clipping. Do not normalize each sentence independently or hard-normalize the combined mix in a way that defeats the approved speech/music balance. Choose and document final loudness targets during listening tests.
6. Keep narration on a seconds-based timeline when the tempo changes. Place major visual reveals and musical hits around phrase boundaries where useful. Do not run the voice through `Playback` or the music's tape-stop processing.
7. Preserve `out/music.m4a` as the existing music-and-effects output for `compare.sh`; narration must not contaminate the studio music-similarity comparison. Produce `out/mix.m4a` for the narrated export and have the render entry point choose it only when narration is enabled.
8. Preserve `video effects` as effects only, excluding both music and speech. Add a separately named voice-plus-effects variant later only if needed; do not change the current flag's meaning.
9. Make ordinary renders offline and deterministic by consuming saved audio. Generation is an explicit preparation step, never a hidden side effect of `check`, `storyboard`, `audio`, `draft` or `video`.

A narration-free alternate should use the existing unducked bed, so it does not retain unexplained volume dips. The legacy filename `music.m4a` already includes effects; do not rename it in this feature.

## Planning and review changes to ship with the engine

| File | Change |
|---|---|
| `skills/project/SKILL.md` | Add the voiceover question to section 3; carry the answer and supplied audio paths into make |
| `skills/website/SKILL.md` | Add the same question to section 2; use the same shared options |
| `skills/scratch/SKILL.md` | Add it as the fourth choice in round 2, keeping the existing four-question limit |
| `skills/make/SKILL.md` | Add script/voice review, optional audition, measured timing before storyboard, narration mixing and voice feedback |
| `PLAN.md` | Add optional voice direction, spoken-word budgeting and narration-first timing; keep the no-voice path unchanged |
| `templates/DIRECTION.md` | Voice enabled/source, language, delivery, coverage, selected voice, pronunciation, preview approval and caption preference |
| `templates/SCRIPT.md` | Separate exact spoken words from on-screen words, with phrase IDs, measured durations and caption placement |
| `rules.md` and `checklist.md` | Truthful spoken claims, correct pronunciation, intelligibility, complete phrases, captions, and no automatic voice degradation |
| `ENGINE.md` and `README.md` | Document only implemented calls, supported inputs, output variants, setup/cost expectations and offline reuse |
| `scripts/new.sh` | Ensure new narration code/assets and optional template fields work for new films without changing old film defaults |

Existing films have private engine copies. Upgrading the plugin alone does not add narration to them. Document an explicit engine-copy upgrade with a backup and regression check; never silently overwrite a customized film engine.

The narrated SCRIPT should have two linked tables: the existing visual beat grid and a narration table with phrase ID, exact spoken words, delivery note, source in/out, film start/end and caption text. This avoids making the existing grid too wide and lets visual copy differ from speech deliberately.

## Delivery phases and acceptance

**Phase 0 — Prove the local candidate.** During implementation, build an isolated macOS spike using the Luna approach and audition real 15/30-second marketing scripts. Compare longer chunks with the reference app's chunks, check unknown product names, measure cold/warm latency and peak memory, verify offline operation, and measure the full installation footprint. Test Apple Silicon; support Intel only after a separate successful check. Do not promote historical iPhone/simulator measurements into desktop promises. Select the backend only after this gate.

**Phase 1 — Imported narration and compatibility.** Implement imported-audio decoding, phrase placement, clean speech mixing, bed ducking and the narrated export. Test with small generated audio fixtures and a supplied human take. Preserve all current examples and the effects-only contract. Do not enable generated-voice choices yet.

**Phase 2 — Natural generated voice.** Add the selected local synthesis helper, explicit setup, capability checks, previews, pronunciation preflight, reviewed phrase timing and approved-take caching. Cloud generation is a later optional adapter, with account and budget checks. Never require network in rendering. Enable the initial three-way question only when the routes it offers work; otherwise expose only available sources and explain missing capability.

**Phase 3 — Captions and complete review.** Add phrase caption layout/export, safe-zone and collision checks, and narration checks for source bounds, overlaps, cutoff, missing takes and outdated approvals. Fold them into the bounded draft loop. Complete this phase before advertising the full narrated workflow described here.

Release checks:

- No-voice default: all existing regressions/examples pass; compare audio PCM with a pre-feature baseline to confirm the old path is unchanged.
- Input: supported formats, mono/stereo, sample-rate conversion, leading silence, corrupt/empty files and paths containing spaces.
- Timing: no missing last word, no speech beyond the cut, proper alignment after trim/placement, and no pitch/rate change across tempo phases.
- Mix: voice remains clean through musical tape stops and colour changes; ducking is smooth and releases naturally; final encoded audio does not clip.
- Output: normal mix, no-narration variant and effects-only variant contain exactly the expected sources; compare still analyzes the narration-free bed.
- Cache/failure: visual-only re-renders make zero speech requests; changed script/voice invalidates the take; failed generation retains the previous approved take and reports the failure.
- Captions: match the approved spoken words after pronunciation normalization, respect safe zones, and do not collide with important UI or headlines.
- Human listening: approve a real 15-second and 30-second film for pronunciation, natural delivery, musical balance and comfortable pauses. Automated checks do not substitute for this.

First film milestone: one existing demo as a separate narrated variant, with a short audition approved before the full take. Keep its current film and assets intact for comparison. A multilingual rollout, cloned voices, multiple speakers and automated word-level animated captions are later work.

## Real-world scenario review and acceptance matrix

These are planned behaviors and test cases, not claims that the feature has been implemented or tested. They cover the principal routes and failures; extend the matrix when a new supported source, language or delivery format adds a case.

| ID | Situation | Required behavior and evidence |
|---|---|---|
| V01 | User wants no voice | Preserve current questions after the initial choice, approval count and audio output; zero speech setup/network calls |
| V02 | First local voice, no account | Explain one-time setup; generate a short audition locally after setup; no paid account requirement |
| V03 | Offline, assets installed | Synthesize and render with networking disabled |
| V04 | Offline, assets missing | Preserve draft; offer import or later setup; never upload or silently substitute |
| V05 | Interrupted/corrupt download, full disk | Leave working assets intact, explain repair, validate the replacement before use |
| V06 | Slow/unsupported Mac or memory pressure | Report supported limits; bounded work and cancellation; keep approved voice rather than real-time Apple fallback |
| V07 | Private launch or confidential script | Local-only policy applies to TTS, STT and alignment; ensure no hidden upload |
| V08 | Paid service missing key, credit or voice | Explain exact missing capability; preserve prior take; choose another source explicitly |
| V09 | Cloud timeout, rate limit or partial response | Bounded retries and charge awareness; no partial take promoted to approved |
| V10 | Commercial advertisement | Verify chosen distribution/voice terms; do not assume a hosted free tier permits ads |
| V11 | User supplies clean recording and script | Import without TTS/STT; listen for script mismatches and confirm phrase boundaries |
| V12 | Supplied recording, no transcript | Offer optional reviewed transcription or user-authored transcript/manual timing; no automatic model bundle |
| V13 | Recording differs from proposed script | Reconcile actual words and intended claims; do not silently synthesize replacement words |
| V14 | Noisy, clipped, quiet or stereo recording | Preserve original; inspect channels/peaks; request replacement if unusable, preview any cleanup; normalization cannot repair clipping |
| V15 | Screen recording already contains speech/music | Detect audio tracks; choose keep/extract/mute explicitly and avoid double narration. Automatic source separation is outside MVP |
| V16 | Product names, URLs, prices, acronyms | Preflight pronunciation; user-confirmed spoken forms, audition names, retain proper spelling in captions |
| V17 | Unfamiliar English word outside Luna lexicon | Flag before full generation; add validated pronunciation override or change the source; no Apple fallback |
| V18 | Non-English language, accent or code switching | Check the actual adapter's support; do not approximate with an English voice. Offer supplied audio; multilingual rendering remains separately tested |
| V19 | Translation creates a longer script | Approve translated meaning and new take; retime/rewrite rather than squeeze it into the original word timings |
| V20 | 15-second cut has too much speech | Shorten copy or extend duration with the user; never clip the final word or silently speed speech |
| V21 | Voice sounds flat or robotic | Listen to a bounded alternative performance/voice; keep the earlier take; do not loop endlessly or promise success from settings alone |
| V22 | Pronunciation correction or pickup line | Invalidate affected take/timing, preserve context; audition joins, regenerate the whole short take if continuity suffers |
| V23 | Visual, colour or music revision only | Zero TTS calls; reuse dry take, recheck mix and any changed placement |
| V24 | Tempo, tape stop or playback ramp changes | Speech pitch/duration remain unchanged; validate phrase placement and ducking against new bed |
| V25 | Vertical, square and landscape exports | Reuse the same take where duration/script match; relayout captions and check safe zones per format |
| V26 | 15/30/60-second versions | Separate script/timing approvals where content differs; do not reuse stale timings or stretch a take |
| V27 | Captions requested | Use verified spoken words and reviewed phrase times; test trims, placement, long words, names and number display |
| V28 | Platform supplies captions or viewer watches muted | Avoid duplicate burned-in captions when requested; retain readable visual story and optional subtitle file |
| V29 | Music masks speech or strong effects overlap | Audition phone speakers/headphones; duck smoothly, move effects or lower them, check final encoded peaks |
| V30 | Narration only or multiple deliverables | Define mix sources explicitly; voice-only available as narration stem, narrated master as mix, alternate no-voice bed unducked, existing effects-only unchanged |
| V31 | Missing audio, edited script or invalid manifest | Fail final export clearly; validate hashes, intervals and approval identity; no stale/unapproved take delivered |
| V32 | Concurrent films, cancel and resume | Shared installation lock, separate project outputs, atomic writes and duplicate-request suppression; no cache collision |
| V33 | New computer or discontinued provider | Film carries approved audio and timing; export works without the original model/provider; regeneration requires available setup |
| V34 | Old film with customized engine copy | Explicit migration/backup and regressions; no overwrite merely from updating plugin |
| V35 | Requested cloned voice, dialogue or lip sync | Explain first-release limits and accept a finished supplied take where it fits; do not imply the stock-voice route implements these |

## Remaining decisions and release evidence

The next implementation decision is whether the adapted Kokoro helper passes quality and packaging checks, not whether every user must install TTS and STT. The proposed first scope is one English stock voice, optional setup, supplied recordings, phrase timing, clean mixing and captions. Cloud generation and automatic transcription can follow independently.

Record implementation evidence for: supported macOS/CPU combinations, pinned runtime/model licenses and checksums, exact setup size, resource measurements, representative scripts and approved audition results. Resolve pronunciation coverage and caption timing without assuming that STT is mandatory. During release verification attach automated results to the relevant V-cases and listening results to V16–V22/V29. Cases outside the first scope must produce a clear unsupported outcome rather than a misleading option.

The original planning review inspected Watch-Health-Tracker only. See the implementation evidence added below for subsequent tests; historical reference-app measurements are not desktop promises.

## Implemented scope and validation (2026-10-07)

The first integration uses a native ONNX Runtime 1.24.2 worker plus the adapted Swift English
phonemizer. `scripts/voice.sh` handles explicit setup, generation, import, review approval and
mix/placement revisions. Python is used only for standard-library orchestration and asset preparation;
no Python ML environment, espeak, STT, account or cloud adapter is installed.

Measured setup on this Apple Silicon Mac: about 227 MB installed (including the native runtime and
model), plus cached downloads; budget about 153 MB of downloads and 1 GB free for staging/builds.
Asset hashes and helper source identity version the shared installation. Native inference at 24 kHz
feeds the engine's 48 kHz import path. Full narration is saved with its script/audio hashes, measured
phrase times and separate approval hash. The renderer never needs the helper/model installation.

Implemented and exercised: mono resampling, candidate import and approval, invalid/stale manifest
rejection, no voice cutoff, musical-effect isolation, speech ducking, no-voice/effects-only variants,
unchanged music bed, phrase SRT placement, failure preservation and no model setup during import.
A generated two-phrase take and narrated MP4 exercised the preparation-to-export path. Native local
synthesis also succeeded with network access denied by a macOS sandbox profile. A generated take is
not automatically a user-approved performance: the audition remains part of each creative workflow.

Deferred: other stock voices, non-English generation, Intel synthesis, cloud adapters, automatic STT,
forced alignment, automatic burned-in captions, source separation, cloning and multi-speaker generation.
Supplied takes remain the route for voices outside the supported local generator. The broad scenario
matrix above remains a backlog and review guide, not a promise of these deferred capabilities.

Validation evidence: the full `scripts/test.sh` suite passed (gallery, planted layout errors, existing
engine/footage regressions and all examples; the legacy Owly example retains its 86 pre-existing audit
notes). Four skills passed common schema validation with their existing Claude-specific metadata
checked separately and preserved. On this Mac, a prepared-install run generated 4.78 seconds of speech
in 3.53 seconds; the repeated request reused the candidate in 0.11 seconds. These are one-machine
measurements, not performance guarantees. Human judgment of the voice's delivery remains an audition
step; no automated test proves a performance sounds natural.

Final focused checks also cover stereo-channel preservation, modified audio hashes, actual decoded duration beyond the cut, corrupt imports without a crash, readable stale-script errors, and offline narrated/no-voice exports.

Pre-commit review added regressions for script edits during preparation, numeric-only captions on supplied recordings, and malformed candidate phrase metadata. These fail before approval without replacing the previous take.
