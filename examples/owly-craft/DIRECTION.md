# Owly — capacity craft benchmark

A 15-second 16:9 internal test of the updated motionable workflow, authorized as part of the five craft improvements. No separate treatment approval is needed for this requested evaluation.

## Evidence board

| Signal | Evidence | Source in TODO-LIST-APP |
|---|---|---|
| Job | A day has a ceiling; plan to an honest capacity | README.md opening |
| Mechanism | Sum today's unfinished task sizes; compare against daily capacity | Shared/TaskLogic.swift:243–260 |
| Normal state | “Day is about full”; 2h 45m / 3h; 15m still free | Website/owly-today.png |
| Warning state | “More than fits”; 4h 5m / 3h | Website/owly-over-capacity.png, App/LoadMeter.swift:76–85 |
| Brand | Green 0F9B3E, restrained system typography, owl artwork | Shared/Design.swift, Website/owly-logo.png, Website/owly-mascot.png |
| Truth boundary | CloudKit/circle flow unverified end to end | README.md status table; excluded from this film |

Personality: honest, warm, calm, clear. Never frantic or boastful.

## Treatment

Feel: a calm piece of product evidence, with a result viewers can read.
Sound: quiet piano and low bass, sparse acoustic percussion; only two supporting effects.
Look: cream, deep green, system sans with italic Georgia on the benefit; untouched real UI.
Signature: the same Today screen moves across the composition and its capacity meter lifts into readable focus.

## Artwork specification

| Asset | Source | Role and treatment |
|---|---|---|
| today.png | Website/owly-today.png | Real UI, contained upright; no texture/effect |
| over.png | Website/owly-over-capacity.png | Real warning UI; a dissolve between verified states, not a screen recording |
| routine.png | Website/owly-routine.png | Available evidence; not needed for this single-message film |
| mascot.png | Website/owly-mascot.png | Supplied artwork, small supporting entrance; unchanged |
| logo.png | Website/owly-logo.png | Supplied brand asset, unchanged |
| Traveling dot | Original circle in scene code | One green supporting accent; restrained temporal blur; no text blurred |

Copied assets have SHA-256 provenance in assets/provenance.json. No borrowed reference artwork. Deliberate negative space surrounds the hook. One visual treatment persists throughout.

## Choreography

Primary actions: hook reading → persistent screen glide → capacity focus → warning state → brand payoff. Movement stops between those actions. The screen identity is drawn once during its glide; no competing scene replacement. Ease-in/out Bezier guides the screen; a strongly damped finite spring supports the small mascot. The moving dot uses matching Hermite velocity through its middle key. Temporal blur is confined to the dot and draws once outside its motion range. Type stays sharp.

Voiceover: none for this visual regression benchmark. No model download or unreviewed narration.

## Fingerprint

- tempo: 96 BPM
- mode: D lydian
- drums: sparse acoustic
- lead instrument: piano
- colour: cream and Owly green
- type face: system bold
- type mix: italic Georgia emphasis
- motion vocabulary: one persistent glide, focus lift, quiet fades
- hook device: capacity statement
- transitions: in-shot continuity and one screenshot state dissolve
- end card: large restrained lockup
- background: cream, no grain
- seed: 108
