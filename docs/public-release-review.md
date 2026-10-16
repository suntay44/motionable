# Public release review — October 16, 2026

## Scope and status

Reviewed the plugin manifests, shell entry points, generation templates, rendering/export path, motion and text/audit interfaces, optional narration preparation and asset notices. This is a bounded release-readiness review, not a claim that every possible generated film or every OS/model combination has been tested. No remote publication is performed by this review.

The supplied original Owly MP4 is added to the README alongside existing demos. Its copied file has the same SHA-256 hash as the owner’s original. The 270×480 GIF is a silent preview. Both are historical showcase media; the MP4 is not a new generation or a claim that current instructions reliably recreate it. Availability wording in the preserved original must be checked before reuse. Source: `examples/owly`, with its legacy audit limitations retained.

## Findings and fixes

| Finding | Change | Verification |
|---|---|---|
| A failed render deleted the previous export before the replacement was ready | Render/mux to unique temporary files, replace only after successful export; check writer startup, append failure and missing tracks | Regression: missing audio preserves sentinel export; success replaces it with a valid half-second film; normal thrown failures clean temporary files |
| Compare and inspect wrappers swallowed compiler errors and could run a stale helper | Compilation now fails immediately | Failure-injection regression covers footage, compare and inspect helpers |
| Product names containing slashes, ampersands, quotes or backslashes broke scaffold substitution/Swift literals | Separate document/sed and Swift escaping; non-Latin names get a safe file-name fallback; reject multiline names | Generated names are parsed by Swift, and actual names are preserved in documents |
| Existing folders without scenes could have their plan files overwritten | Refuse any existing destination, including symbolic links | Existing-folder preservation regression |
| Legacy Owly crashed without an ignored badge asset on a clean checkout; it also exposed an animated-badge variant | Optional badge with text fallback; official artwork always stays still | Clean-asset rendering checked separately; legacy readability exceptions remain documented |
| README conflated heuristic checks with visual/listening quality and promised consistently sub-minute renders | Describe audit limits, observed render variability, model variability and separate asset/voice licences | README/source link checks and manual documentation review |
| Guidance encouraged motion tools without enough emphasis on explanation | Five principles integrated into planning, skill entrypoint, templates and critique | Instruction/reference checks; no fresh model-run reproduction benchmark claimed |

## Checks

A macOS 15 CI workflow is added for pushes to main and pull requests, with read-only repository permissions and a pinned checkout action. It has not run on GitHub until these changes are pushed.

- Local Claude CLI validates both plugin and marketplace manifests.
- Scaffold tests pass for punctuation, Swift escaping, non-Latin names, version stamping, multiline rejection and existing-folder/symlink preservation.
- Motion/export regressions pass, including prior-export preservation on failure and replacement on success.
- Narration regressions and failure-injected helper compilation checks pass without model downloads.
- Shell syntax, Python syntax and diff whitespace checks pass. Local Markdown links resolve and asset provenance hashes match.
- Modified skill passes the Codex structural validator on a temporary copy excluding Claude’s supported routing extensions (`user-invocable` / `argument-hint`); the real plugin retains those fields. CI YAML parses.
- Credential-pattern checks found no matches in tracked text; this is a limited automated check, not a comprehensive secret-history audit.
- The original Owly demo’s SHA-256 matches the supplied MP4; GIF preview contains 120 frames at 270×480 over 30 seconds.

The complete `scripts/test.sh` suite passed, including gallery/audit fixtures and every maintained example. Legacy Owly built with its 86 documented modern-audit notes. Its binary also rendered the closing frame using a clean asset folder containing only the logo, without an Apple SVG; the text fallback was inspected. Version 0.7.0 is prepared locally; no GitHub release is published by this work. Detailed local logs are ignored under `.build/validation/public-*`.

## Remaining limits

- Visual quality depends on the model, direction and review. The five principles are operational guidance, not a guarantee of comparable output from every run.
- The original Owly source predates modern readability/layout auditing and intentionally remains a legacy example. The smoke test checks that it runs, not that it passes every current heuristic.
- Optional generated voice is Apple Silicon / US English; supplied recordings have a broader supported Mac path. Offline regression tests do not download or run the model.
- This review is on the available Mac. It does not establish a macOS 15 or Intel compatibility matrix, install the plugin into a fresh Claude account, or provide subjective listening review.
- Product screenshots/logos and finished demo media are showcase assets, separate from the MIT code/docs. Standalone Apple badge artwork, generated binaries, voice auditions, downloaded models and local scratch films are excluded from the distributed source.

Installation commands were checked against the local `claude plugin --help` and [official installation documentation](https://code.claude.com/docs/en/discover-plugins). The local CLI manifest validator is used without installing or changing user plugin settings.
