#!/bin/bash
# motionable: start a film. Copies the engine into the film (so plugin updates never change a finished film),
# and the plain templates: scenes/Film.swift, DIRECTION.md, SCRIPT.md.
# usage: new.sh <film-dir> "<Product name>"
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ $# -ge 2 ] || { echo "usage: new.sh <film-dir> \"<Product name>\""; exit 2; }
PROJ="$1"; NAME="$2"
if [ -e "$PROJ/scenes" ]; then echo "$PROJ already has scenes/ — not overwriting."; exit 1; fi
mkdir -p "$PROJ/scenes" "$PROJ/assets/drawn" "$PROJ/assets/fonts" "$PROJ/out" "$PROJ/engine"
cp "$ROOT"/engine/*.swift "$PROJ/engine/"
VERSION="$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$ROOT/.claude-plugin/plugin.json")"
echo "$VERSION" > "$PROJ/engine/VERSION"
SLUG="$(echo "$NAME" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//; s/-$//')"
sed "s/{{PRODUCT}}/$NAME/g; s/{{SLUG}}/$SLUG/g" "$ROOT/templates/Film.swift" > "$PROJ/scenes/Film.swift"
sed "s/{{PRODUCT}}/$NAME/g" "$ROOT/templates/DIRECTION.md" > "$PROJ/DIRECTION.md"
sed "s/{{PRODUCT}}/$NAME/g" "$ROOT/templates/SCRIPT.md" > "$PROJ/SCRIPT.md"
printf 'out/\n.build/\n' > "$PROJ/.gitignore"
echo "created $PROJ (engine $VERSION copied in; scenes/Film.swift, DIRECTION.md, SCRIPT.md, assets/drawn, assets/fonts)"
