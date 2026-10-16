# motionable critique checklist

Render a contact sheet: `run.sh <film> sheet` with no times shows the whole film plus the edges and middle of every join. Look at it, then score each category from 1 to 10. **Fix anything below 8**, re-render the sheet, and score again. Stop when everything is 8 or higher, or after three rounds. Then tell the user what's still weak. Scores are subjective: justify them with observed timestamps and frames, and state what was not assessed.

| Category | 8+ means |
|---|---|
| **Hook** | `check` prints "frame 1: ✓"; the problem, question or promise lands within 3 s; the product or mascot is on screen by about 2 s; 2+ shots (or one big visual change) in the first 5 s |
| **Composition** | `storyboard`: every keyframe ✓, one focal point each, a shared margin, nothing empty, cut or touching an edge by accident; `check`'s layout section has no ✗ and only ⚠ that DIRECTION.md explains |
| **Readability** | `run.sh <film> check` says "readable": every line stays fully on screen for its reading time (15 characters/s + 0.4 s, at least 1 s), no text sits in the button zones, and every line has 3:1 contrast with what's behind it. Nothing overlaps |
| **Story** | One core message; at most 3 benefits (2 in 15 s), each shown on real UI; the end card has icon, name, one line and a true text CTA |
| **Motion** | Playback has a clear primary action, supporting movement and intentional pauses; acceleration and settling fit the object; shared elements keep their identity across layouts; nothing jitters; `check` prints "flashing: ✓" and "rhythm: ✓" |
| **Brand** | Real colours, logo and screenshots; the type mix and colour accents match the product's voice, each accent with a job; looks like *this* product, not a template |
| **Rules** | Everything in rules.md holds: claims verified, badges untouched, screens never sliced, phones upright, safe zones clear, final hold still |
| **Sound** | The audio levels print sanely: muffled stretches read quieter than just before; effects line up with meaningful `T` events; silence and music-only beats are intentional; nothing of the stock "startup" formula (ukulele, whistling, swoosh-and-claps) |
| **Variety** | Framings and joins serve the story; repeated layouts establish continuity; the signature moment is there and reads instantly; no effect exists only to satisfy a quota |
| **Distinctiveness** | The product has its own visual identity; sound similarity and the fingerprint inform review rather than enforce arbitrary differences; deliberate series reuse is documented |
| **Direction** | It feels like DIRECTION.md's personality (and never like its "Never"); every dial is visible in the cut |

Before scoring motion, run `run.sh <film> motion` and inspect the draft in playback plus the dense sequence sheets in `out/motion/`. Record observed timestamps, fixes and any unreviewed audio or timing in SCRIPT.md. Automated checks and contact sheets do not prove natural motion or good sound.

Also check:
- Headline anchors and hierarchy stay consistent; each intentional exception helps the composition.
- A carried element keeps its identity through handoffs, and the change explains the next idea.
- Product information arrives in a clear sequence; supporting motion directs attention rather than competing with the main action.
- Musical accents support recognition, handoff, interaction and result, rather than arbitrary decoration.
- Compare the moving film with any user-selected reference. A passing audit or a high self-score does not override the user’s judgment of typography and motion.
- Mid-transition stills: shapes and text shouldn't look broken or collide in an ugly way. Briefly odd is fine; a mess is not.
- The final hold frame: is it a good thumbnail on its own?
- The longest line at the auto-fit size: is it still big enough?

**If narrated:** names and claims correct; no missing words or awkward joins; speech fits the cut; voice intelligible over music; caption phrases match the recording; approved manifest current. Preview dry and mixed takes. Do not claim listening validation from levels alone.
