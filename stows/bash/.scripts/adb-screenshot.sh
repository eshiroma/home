#!/usr/bin/env bash
# Take an ADB screenshot and downscale to ≤1000px for conversation use.
# Usage: adb-screenshot.sh [device_serial] [output_path]
# Defaults: first connected device, /tmp/test_screen.png
set -euo pipefail

DEVICE="${1:-}"
OUTPUT="${2:-/tmp/test_screen.png}"
RAW="/tmp/test_screen_raw.png"

if [ -n "$DEVICE" ]; then
  adb.exe -s "$DEVICE" exec-out screencap -p > "$RAW"
else
  adb.exe exec-out screencap -p > "$RAW"
fi

python3 /home/erika/.scripts/resize-screenshot.py "$RAW" "$OUTPUT" 1000
rm -f "$RAW"
