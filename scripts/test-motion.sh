#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/motionable-motion.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
sources=()
for source in "$ROOT"/engine/*.swift; do
  [ "$(basename "$source")" = main.swift ] || sources+=("$source")
done
swiftc -O -swift-version 5 "${sources[@]}" "$ROOT/tests/motion/main.swift" -o "$WORK/motion"
"$WORK/motion"
