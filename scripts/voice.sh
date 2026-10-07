#!/bin/bash
# Optional voice preparation; never called by a normal render or doctor.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec python3 "$ROOT/tools/voice/voice.py" "$@"
