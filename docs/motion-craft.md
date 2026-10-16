# Motion craft

Use this when planning artwork, timing, continuity and moving-sequence review. A reference is useful for observed design and timing; it does not establish the author's tools or source code. Record what was observed and what is inferred. Build original work from the product's evidence.

## Artwork before animation

Write an artwork specification in DIRECTION.md: each asset's source, role, palette, material or texture, line weight, crop and scale, and whether it is product evidence or an illustration. Use supplied logos, mascots and screenshots unchanged. Pick one treatment for newly drawn illustrations and judge them together at delivery size. A texture such as halftone is optional, chosen for the brand; applying it to all UI can destroy evidence and readability. Avoid adding a new material or visual style for every shot.

Design each settled frame first: a primary focal point, a readable type hierarchy, consistent spacing and deliberate negative space. An empty margin is not a defect. Use an accent font, colour or drawing only when it has a specific role. Depth and 3D are optional; use them when the story needs spatial relationships, not as proof of professionalism.

## Choreograph actions

For each shot record the primary action, supporting movement, move/settle/read-hold intervals, and the element identity carried into the next shot. Anticipation is optional. Overlap supporting movement with the main action without making them compete. Let the result settle long enough to understand it. Holds can happen before the end card too. Music supplies a rhythm, but not every beat needs movement or an effect; speech and real UI events may fall off the beat.

Specify curves and durations by object rather than assigning one entrance to everything. `show(..., curve: .bezier(0.22, 1, 0.36, 1), exitCurve: .easeIn)` overrides the legacy curve. A `MotionCurve.spring(response: 0.45, damping: 0.8)` settles exactly at the chosen end; it is an authored finite spring, not a physics simulation. Low damping can wobble substantially. Use sparingly, check the actual result, and keep text readable.

`MotionPath` uses timed point/velocity keys (canvas units/second). Adjacent segments share a key's velocity, preserving motion through that point. Zero velocities make stops; use zero endpoint velocities before and after holds. Arbitrary tangents can overshoot, so inspect the whole path. `SharedElement` carries a visual between two bounds: draw that identity once outside scene crossfades, and do not instantiate a replacement at the boundary. Keep screenshots upright and use the framing helpers within the supplied bounds.

`temporalLayer(t:fps:shutter:samples:moving:)` optionally averages actual subframes of selected moving artwork. `shutter: 0.5` samples half an output frame interval. It uses the actual output fps automatically (including 30 fps drafts); an explicit `fps` override is available, keep text outside, and limit its moving range to avoid sampling a cut. It increases rendering cost approximately with sample count for that layer. It draws just the nominal time for audits and outside movement. Closures must be deterministic, safe at arbitrary times, and free of persistent scene-state mutations. This is distinct from a directional image filter.

## Review motion, not just frames

Set `Film(motionMoments:)` to action and settling centers. Run `run.sh <film> motion`: it produces a draft MP4 and dense film-frame sequences around those moments, joins, keyframes and the final hold in `out/motion/`. Optional numeric arguments select review centers. `review.json` records sampled timestamps, not a quality score. A 30 fps draft can reveal pacing; inspect full-rate output when judging fine motion or blur.

Watch the draft at normal speed when playback is available. Use dense sequences to inspect acceleration, overlaps and handoffs; use `check` and `storyboard` for measurable readability/layout faults. Confirm attention follows the intended primary action, carried identities do not jump, text has a comfortable hold, and the final hold is sharp. Listen separately for voice/music balance when audio is available. Record timestamps and actual observations in SCRIPT.md, fix in a batch, then review affected sequences again. If only stills were inspected, say so; if audio was not heard, say so. Neither an automated pass nor a contact sheet certifies natural motion, professional quality or good sound.

## When the brief asks for hype

Honor an explicit high-energy brief. A warm product can still have a dense, playful launch film. Plan a series of meaningful visual discoveries: scale changes, paired devices, lifted annotations, progressive numbers, camera details, illustrated accents and musical setup/payoff. Choose the subset that explains this product, vary shot lengths, and develop supporting actions inside each shot. A faster cut alone does not fix repeated compositions or long inactive holds. Preserve readable proof pauses; energy is a creative requirement, not permission to invent UI or bury information. Record the reference links and distinguish observed treatment from toolchain claims.
