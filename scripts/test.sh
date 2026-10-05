#!/bin/bash
# motionable: the maintainer's smoke test. Renders every engine ingredient once (tests/gallery → out/sheet.png),
# then builds every example film and runs its readability check. Takes a few minutes (each film compiles the engine).
# usage: test.sh
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
echo "== gallery: every element, type entrance, look and join"
if bash "$ROOT/scripts/run.sh" "$ROOT/tests/gallery" sheet 0.6 1.6 2.6 3.6 4.6 5.5 | tail -1; then
  echo "   look at tests/gallery/out/sheet.png (stills: run.sh tests/gallery stills 0.6 1.6 2.6 3.6 4.6 5.5)"
else echo "✗ the gallery didn't build"; fail=1; fi
for film in "$ROOT"/examples/*/; do
  name="$(basename "$film")"
  echo "== $name"
  out="$(bash "$ROOT/scripts/run.sh" "$film" check 2>&1)"
  if [ "$name" = "owly" ]; then                     # the v0.1 film, made before check existed: it only has to build
    echo "$out" | grep -q "verdict" && echo "   builds (v0.1 film; $(echo "$out" | grep -c "✗") notes from the newer check)" || { echo "$out" | tail -5; fail=1; }
    continue
  fi
  echo "$out" | grep -E "✗|⚠|verdict|error" || echo "$out" | tail -3
  echo "$out" | grep -q "verdict: readable" || fail=1
done
[ $fail = 0 ] && echo "all good" || { echo "something failed (above)"; exit 1; }
