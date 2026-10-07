#!/bin/bash
# motionable: read a screen recording before editing it: its timeline of changes, contact sheets of moments, trims.
# usage: footage.sh <video> [sheet <s> … | frame <s> <out.png> | trim <from> <to> <out>]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ $# -ge 1 ] || { echo "usage: footage.sh <video> [sheet <s> … | trim <from> <to> <out>]"; exit 2; }
CACHE="${TMPDIR:-/tmp}/motionable-tools"
BIN="$CACHE/footage"
mkdir -p "$CACHE"
if [ ! -x "$BIN" ] || [ "$ROOT/tools/footage.swift" -nt "$BIN" ]; then
  swiftc -O "$ROOT/tools/footage.swift" -o "$BIN"
fi
exec "$BIN" "$@"
