#!/bin/bash
# motionable: checks this Mac can render. Prints one line per check; exits 1 if anything blocks.
ok=1
os="$(sw_vers -productVersion 2>/dev/null || echo 0)"
major="${os%%.*}"
if [ "$(uname)" != "Darwin" ]; then echo "✗ motionable runs on macOS only (this is $(uname))."; exit 1; fi
if [ "$major" -ge 15 ]; then echo "✓ macOS $os"; else echo "✗ macOS $os — motionable needs macOS 15 or later."; ok=0; fi
if xcrun --find swiftc >/dev/null 2>&1; then echo "✓ Swift $(xcrun swiftc --version 2>&1 | sed -n 's/.*Swift version \([0-9.]*\).*/\1/p' | head -1)"
else echo "✗ No Swift compiler. Install the free command line tools: xcode-select --install"; ok=0; fi
free_kb=$(df -k "${1:-.}" | awk 'NR==2 {print $4}')
if [ "$free_kb" -gt 1048576 ]; then echo "✓ $((free_kb / 1048576)) GB free"; else echo "✗ Less than 1 GB free — a render needs room for frames and the MP4."; ok=0; fi
[ $ok = 1 ] && echo "ready" || exit 1
