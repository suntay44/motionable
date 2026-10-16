# Owly — original design reference

A 30-second vertical film at 1080×1920 / 60 fps. One card connects a parent’s list, a child’s widget, family circles, daily capacity, decisions and the app identity. The stable headline grid and action-led sound are explained in STYLE.md and SCRIPT.md.

The README’s [original MP4](../../docs/demos/owly-original.mp4) is the owner-supplied historical export, preserved as supplied. This example is its legacy engine adaptation. It predates the current readability audit; `check` reports known timing/layout notes, so the smoke suite checks that it runs rather than treating it as a modern audit pass. Use it to study visual relationships, then apply current checks to new work.

From the repository root:

```bash
bash scripts/run.sh examples/owly video
```

Output: `examples/owly/out/owly-hype.mp4`.

A clean checkout uses text availability. To include Apple’s official badge, explicitly download it:

```bash
bash scripts/fetch-app-store-badge.sh examples/owly
bash scripts/run.sh examples/owly video
```

The badge cuts in and remains still. The original product/availability copy is historical; verify it for any new release. The app logo is showcase artwork, excluded from the code’s MIT licence. See the repository’s LICENSE and examples/README.md.
