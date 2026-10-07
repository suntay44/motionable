#!/bin/bash
# Focused engine and footage-tool regressions; all fixtures are temporary.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/motionable-regression.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
sources=()
for source in "$ROOT"/engine/*.swift; do
  [ "$(basename "$source")" = main.swift ] || sources+=("$source")
done
swiftc -O "$ROOT/tools/footage.swift" -o "$WORK/footage"
swiftc -O -swift-version 5 "${sources[@]}" "$ROOT/tests/regression/main.swift" -o "$WORK/regression"
"$WORK/regression" "$WORK" "$WORK/footage"
original="$(shasum -a 256 "$WORK/sparse.mov")"
for mode in same-source invalid-range invalid-time unknown-mode; do
  case "$mode" in
    same-source) args=(trim 0 1 "$WORK/sparse.mov");;
    invalid-range) args=(trim 2 1 "$WORK/trim.mov");;
    invalid-time) args=(frame nan "$WORK/frame.png");;
    unknown-mode) args=(typo);;
  esac
  if "$WORK/footage" "$WORK/sparse.mov" "${args[@]}"; then
    echo "regression failed: accepted $mode"; exit 1
  fi
done
[ "$original" = "$(shasum -a 256 "$WORK/sparse.mov")" ]
"$WORK/footage" "$WORK/sparse.mov" sheet 0 1.5 3.5 5.5
"$WORK/footage" "$WORK/sparse.mov" trim 0 2 "$WORK/trim.mov"
echo "footage CLI: invalid input rejected, source preserved, sheet and trim passed"

# A failed recompile must never fall through to an older cached executable.
mkdir -p "$WORK/plugin/scripts" "$WORK/plugin/tools" "$WORK/bin" "$WORK/cache/motionable-tools"
cp "$ROOT/scripts/footage.sh" "$WORK/plugin/scripts/footage.sh"
printf 'exit 19\n' > "$WORK/bin/swiftc"
printf '#!/bin/bash\ntouch "$0.ran"\n' > "$WORK/cache/motionable-tools/footage"
chmod +x "$WORK/bin/swiftc" "$WORK/cache/motionable-tools/footage"
touch -t 200001010000 "$WORK/cache/motionable-tools/footage"
touch "$WORK/plugin/tools/footage.swift"
if PATH="$WORK/bin:$PATH" TMPDIR="$WORK/cache" bash "$WORK/plugin/scripts/footage.sh" unused; then
  echo "regression failed: compilation error was swallowed"; exit 1
fi
[ ! -e "$WORK/cache/motionable-tools/footage.ran" ]
echo "footage wrapper: failed compilation cannot run a stale binary"
