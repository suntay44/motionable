#!/bin/bash
# motionable: does this film sound like the other films in the studio? (Builds the comparer once, then runs it.)
# usage: compare.sh <film-dir>
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ $# -ge 1 ] || { echo "usage: compare.sh <film-dir>"; exit 2; }
CACHE="${TMPDIR:-/tmp}/motionable-tools"
BIN="$CACHE/compare"
mkdir -p "$CACHE"
if [ ! -x "$BIN" ] || [ "$ROOT/tools/compare.swift" -nt "$BIN" ]; then
  swiftc -O "$ROOT/tools/compare.swift" -o "$BIN" 2>&1 | grep -E "error" || true
fi
exec "$BIN" "$1"
