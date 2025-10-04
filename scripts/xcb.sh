#!/usr/bin/env bash
# xcb.sh — consistent build/test with short logs to clipboard
# Usage:
#   scripts/xcb.sh build
#   scripts/xcb.sh test
set -euo pipefail
SCHEME="${SCHEME:-YourScheme}"
DEST="${DEST:-platform=iOS Simulator,name=iPhone SE (3rd generation),arch=arm64}"
CMD="${1:-build}"
shift || true
xcodebuild -scheme "$SCHEME" -destination "$DEST" "$CMD" "$@" 2>&1 | head -n 200 | pbcopy
echo "xcb.sh: copied $CMD output to clipboard"

