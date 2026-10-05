#!/bin/bash
# motionable: build (only when a .swift changed) and run a project.
# usage: run.sh <project-dir> audio|stills|sheet|video [seconds …]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ $# -ge 2 ] || { echo "usage: run.sh <project-dir> audio|stills|sheet|video [seconds …]"; exit 2; }
PROJ="$(cd "$1" && pwd)"; shift
BIN="$PROJ/.build/motionable"
mkdir -p "$PROJ/.build"
if [ ! -x "$BIN" ] || [ -n "$(find "$ROOT/engine" "$PROJ/scenes" -name '*.swift' -newer "$BIN" 2>/dev/null)" ]; then
  echo "building…"
  swiftc -O -swift-version 5 "$ROOT"/engine/*.swift "$PROJ"/scenes/*.swift -o "$BIN"
fi
exec "$BIN" "$PROJ" "$@"
