#!/bin/bash
# motionable: start a film project from the templates.
# usage: new.sh <project-dir> "<Product name>"
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ $# -ge 2 ] || { echo "usage: new.sh <project-dir> \"<Product name>\""; exit 2; }
PROJ="$1"; NAME="$2"
if [ -e "$PROJ/scenes" ]; then echo "$PROJ already has scenes/ — not overwriting."; exit 1; fi
mkdir -p "$PROJ/scenes" "$PROJ/assets" "$PROJ/out"
SLUG="$(echo "$NAME" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//; s/-$//')"
sed "s/{{PRODUCT}}/$NAME/g; s/{{SLUG}}/$SLUG/g" "$ROOT/templates/Film.swift" > "$PROJ/scenes/Film.swift"
sed "s/{{PRODUCT}}/$NAME/g" "$ROOT/templates/STYLE.md" > "$PROJ/STYLE.md"
sed "s/{{PRODUCT}}/$NAME/g" "$ROOT/templates/SCRIPT.md" > "$PROJ/SCRIPT.md"
printf 'out/\n.build/\n' > "$PROJ/.gitignore"
echo "created $PROJ (scenes/Film.swift, STYLE.md, SCRIPT.md, assets/)"
