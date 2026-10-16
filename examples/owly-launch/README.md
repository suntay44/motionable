# owly-launch

30-second vertical master and15-second cut,1080×1920 at60fps. Music and effects only. Real product imagery; see DIRECTION.md and SCRIPT.md for evidence, timing and review limits. App artwork belongs to its owner and is not covered by the engine’s MIT license.

From the repository root:

```bash
bash scripts/run.sh examples/owly-launch check
bash scripts/run.sh examples/owly-launch motion
bash scripts/run.sh examples/owly-launch video
OWLY_SHORT=1 bash scripts/run.sh examples/owly-launch video
```

Apple’s official badge artwork is excluded. To download it explicitly from Apple:

```bash
bash scripts/fetch-app-store-badge.sh examples/owly-launch
```

Without the downloaded asset, the example uses text availability. The badge, when present, cuts in and stays still. The output is a social launch film, not an App Store preview. GIF demo: ../../docs/demos/owly-launch.gif.
