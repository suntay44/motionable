#!/bin/bash
# Offline regression checks. No model download or synthesis in the test suite.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/motionable-voice-tests.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
sources=()
for source in "$ROOT"/engine/*.swift; do
  [ "$(basename "$source")" = main.swift ] || sources+=("$source")
done
swiftc -O -swift-version 5 "${sources[@]}" "$ROOT/tests/narration/main.swift" -o "$WORK/test"
"$WORK/test" "$WORK/film"
MOTIONABLE_VOICE_CACHE="$WORK/cache" python3 "$ROOT/tests/narration/test_cli.py"
