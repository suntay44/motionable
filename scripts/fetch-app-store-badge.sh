#!/bin/bash
# Explicitly invoked by the user; official artwork is never committed or redistributed.
set -euo pipefail
[ $# -eq 1 ] || { echo 'usage: fetch-app-store-badge.sh <film-directory>'; exit 2; }
film="$(cd "$1" && pwd)"
mkdir -p "$film/assets"
target="$film/assets/download-on-the-app-store-black-en-us.svg"
if [ -s "$target" ]; then echo "badge already present: $target"; exit 0; fi
tmp="$(mktemp "$film/assets/.badge.XXXXXX")"
trap 'rm -f "$tmp"' EXIT
curl --fail --location --silent --show-error \
  'https://toolbox.marketingtools.apple.com/api/v2/badges/download-on-the-app-store/black/en-us' -o "$tmp"
[[ "$(head -c 512 "$tmp")" == *'<svg'* || "$(head -c 512 "$tmp")" == *'<?xml'* ]] || { echo 'Apple did not return SVG artwork'; exit 1; }
mv "$tmp" "$target"
echo "downloaded official badge: $target"
