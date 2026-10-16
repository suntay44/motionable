#!/bin/bash
# End-to-end craft benchmark: readability/layout, review artifacts, actual decoded exports and final hold.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILM="$ROOT/examples/owly-craft"
storyboard="$(bash "$ROOT/scripts/run.sh" "$FILM" storyboard)"
printf '%s\n' "$storyboard"
[[ "$storyboard" == *"verdict: the layout holds"* ]] || exit 1
check="$(bash "$ROOT/scripts/run.sh" "$FILM" check)"
printf '%s\n' "$check"
[[ "$check" == *"verdict: readable"* ]] || exit 1
bash "$ROOT/scripts/run.sh" "$FILM" motion
bash "$ROOT/scripts/run.sh" "$FILM" video
swift "$ROOT/tests/motion/inspect-video.swift" "$FILM/out"
