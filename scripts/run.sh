#!/bin/bash
# motionable: build (only when a .swift changed) and run a film. Uses the film's own engine/ copy when it has one
# (films made by new.sh do), else the plugin's engine (films made before v0.2).
# usage: run.sh <film-dir> audio|stills|sheet|video [seconds …]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ $# -ge 2 ] || { echo "usage: run.sh <film-dir> audio|stills|sheet|video [seconds …]"; exit 2; }
PROJ="$(cd "$1" && pwd)"; shift
ENGINE="$ROOT/engine"
if ls "$PROJ"/engine/*.swift >/dev/null 2>&1; then ENGINE="$PROJ/engine"; fi
BIN="$PROJ/.build/motionable"
mkdir -p "$PROJ/.build"
if [ ! -x "$BIN" ] || [ -n "$(find "$ENGINE" "$PROJ/scenes" -name '*.swift' -newer "$BIN" 2>/dev/null)" ]; then
  echo "building…"
  swiftc -O -swift-version 5 "$ENGINE"/*.swift "$PROJ"/scenes/*.swift -o "$BIN"
fi
exec "$BIN" "$PROJ" "$@"
