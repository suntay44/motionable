#!/bin/bash
# motionable: measure a screenshot (sizes, colours, element edges), so redrawn UI lands exactly on the real UI.
# usage: inspect.sh <image> [pixel X,Y … | row Y [lo hi] | column X [lo hi] | find RRGGBB [tolerance]]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ $# -ge 1 ] || { echo "usage: inspect.sh <image> [pixel X,Y … | row Y [lo hi] | column X [lo hi] | find RRGGBB [tolerance]]"; exit 2; }
CACHE="${TMPDIR:-/tmp}/motionable-tools"
BIN="$CACHE/inspect"
mkdir -p "$CACHE"
if [ ! -x "$BIN" ] || [ "$ROOT/tools/inspect.swift" -nt "$BIN" ]; then
  swiftc -O "$ROOT/tools/inspect.swift" -o "$BIN" 2>&1 | grep -E "error" || true
fi
exec "$BIN" "$@"
