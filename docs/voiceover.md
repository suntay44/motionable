# Optional voiceover workflow

Read this only when narration is selected. Music/effects-only films keep the existing flow.
Local generation currently supports one US-English stock voice (`af_heart`) on Apple Silicon
macOS 15+. Import supports the renderer's supported Macs. There is no cloud service, STT,
voice cloning, automatic translation or word-level alignment integration.

## Intake and direction

Ask once, alongside format/length: **Would you like a voiceover?**

- **Generate a voice** — downloads Kokoro on first use, then creates speech locally. No paid account needed.
- **Use my recording** — add your own audio; no voice-model download.
- **No voiceover** — music and sound effects only (default if the user leaves it unspecified).

Skip the question if already answered. Carry the answer through every handoff. For generated voice,
`bash ROOT/scripts/voice.sh status` is read-only; when ready, say “Uses your installed local voice engine.”
Before setup, explain approximately 153 MB of downloads, 1 GB free working space, Apple Silicon and
English support (measured native installation: about 227 MB, plus the download cache). Choosing generation with this disclosed setup authorizes setup; don't ask twice.
It downloads model/runtime assets, never sends the script or audio away. Run `voice.sh setup` only for
that route. Unsupported hardware/languages: offer a supplied take or no voice; never substitute silently.
No accounts, Python ML packages, STT or global package installs are needed. Python 3's standard library,
Swift and the C++ compiler from the command line tools prepare the optional helper.

Collect missing delivery direction, coverage (sparse/full), pronunciation notes and caption preference.
The first engine has a fixed voice and speed; emotional direction is expressed through writing,
punctuation, phrase breaks and pauses, not unsupported model controls. Don't promise a voice menu.

## Script, preview and timing

Add Voice and exact spoken copy to the treatment. Write natural sentences that complement the pictures.
Product claims need the same evidence as visual claims. Keep spoken wording separate from display text.
For a rough first draft, budget 20–28 English words in 15 seconds, 45–60 in 30; actual audio decides fit.
Approve the treatment/script through the existing approval. For a new generated performance, preview a
short candidate with the product name and a representative sentence, then create the full take when
its delivery is accepted. A supplied approved take or explicitly selected known performance can skip
that extra audition. Never describe audio as listened to if the available tools did not let you hear it.

Inside the film, write `assets/voice/script.json`:

```json
{
  "phrases": [
    {"id": "hook", "text": "Make room for better sleep.", "pauseAfter": 0.3},
    {"id": "benefit", "text": "A calmer start, every morning.", "pauseAfter": 0.25}
  ]
}
```

Each phrase is a coherent sentence or short passage (maximum 510 phoneme tokens). Do not split into
individual words just to animate captions. Local synthesis reports unfamiliar words before inference.
Add optional `spoken` with a reviewed pronunciation spelling or fully written number, price or URL;
`text` remains the readable caption spelling. These are alternate representations of the same meaning.
No automatic fallback to Apple's voice. No silent truncation or speed-up to fit the cut.

```sh
bash ROOT/scripts/voice.sh generate FILM FILM/assets/voice/script.json --offset 0.5
```

This prints a candidate manifest path and WAV preview path. Play the WAV, review the generated phrase
boundaries and measure the end time. Preserve breaths and comfortable pauses. Retiming or rewriting is
preferable to rushing. Candidates never replace the approved take until the explicit approval step. Preparation uses a script snapshot and stops if the source script changes before the candidate is saved.
To change mix gain, offset or ducking without synthesis, use `voice.sh revise` (below). Changes to
spoken text/pronunciation need a new take; layout and music changes reuse existing audio.

## Supplied recording

Copying/importing a recording requires no model setup. Keep the original intact. Inspect screen recording
audio separately: it is not automatically imported by Footage. Confirm whether to keep, extract or mute it;
use a separate audio file when it is to become narration, avoiding duplicate speech.

Write the script JSON as above with reviewed `start` and `end` source seconds for each phrase:

```json
{"phrases":[{"id":"hook","text":"Make room for better sleep.","start":0.2,"end":2.8}]}
```

```sh
bash ROOT/scripts/voice.sh import FILM FILM/assets/voice/script.json /path/to/recording.wav --offset 0.5
```

Supported inputs: WAV, M4A, MP3, AIFF, CAF; mono/stereo; up to ten minutes. The engine converts to 48 kHz.
Reject unintelligible or clipped takes rather than claiming volume normalization repairs them. No transcript?
Ask for the words or transcribe with a separately available, authorized tool and review them. This plugin
does not install transcription software. Don't fabricate timestamps from word counts.

## Approve, attach and export

After the user accepts the candidate's sound and timing:

```sh
bash ROOT/scripts/voice.sh approve FILM /printed/path/to/narration.json --duration 30
```

In `makeFilm()`, add the last optional argument:

```swift
Film(name: "product", /* existing arguments */,
     narration: "assets/voice/narration.json")
```

The approved manifest references the audio and original script by checksum. Editing either invalidates
approval. `check`, `storyboard` and rendered outputs validate this before using narration. If the film is too
short or files are missing, fix the issue explicitly. Existing films with private engine copies need an
explicit engine upgrade with a backup; updating the plugin does not rewrite them.

Run `audio`, preview `out/mix.m4a`, then `draft`. Check names, full words, clean phrase joins, comfortable
pace, intelligibility and music balance. One repair batch per feedback round; no endless regenerations.
If a replacement fails, the old approved take remains on disk. A script change still prevents exporting it
as current. Generated candidate reuse uses script/backend/settings identity; the renderer never synthesizes.

Outputs:

- `out/mix.m4a`: narration with ducked music/effects, used by normal `video` and `draft`.
- `out/narration.m4a`: narration stem on the film timeline.
- `out/music.m4a`: original unducked music/effects bed, still used by `compare.sh`.
- `out/captions.srt`: reviewed phrase timing, offset into film time. Sidecar only; nothing burned in automatically.
- `run.sh FILM video no-voice`: alternate without narration, named `-no-voice.mp4`.
- `run.sh FILM video effects`: existing effects-only variant, excluding narration and music.

For burned-in captions, use the existing scene text APIs with reviewed phrase times, reserve space and
inspect each layout; this is not automatic word highlighting. Users who want platform captions can use
the clean video and SRT. Format-only variants can share a take; shorter cuts or translations need fresh
script/timing decisions. Keep the approved audio and manifest with the film for portable offline export.

## Revision and maintenance

`voice.sh revise FILM CANDIDATE --offset 1 --gain 0.9 --duck-db 10` makes a new candidate using the
same audio; preview and approve it. Run `voice.sh status` to inspect availability; `setup` repairs a damaged
installation using verified cached downloads. `MOTIONABLE_VOICE_CACHE` overrides the shared cache
location. Removing that cache only removes optional generation tools/downloads; saved film audio still
renders. No renderer command fetches missing assets. Licenses: `ROOT/tools/voice/NOTICE.md`.
