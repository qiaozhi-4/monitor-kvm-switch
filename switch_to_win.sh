#!/bin/bash
set -euo pipefail

APP="/Applications/BetterDisplay.app"
DISPLAY_NAME="VG27AQML1A"
INPUT_CODE="15" # DisplayPort (VCP inputSelect)

if [[ ! -d "$APP" ]]; then
  printf 'BetterDisplay is not installed at %s\n' "$APP" >&2
  exit 127
fi

CLI="$(command -v betterdisplaycli || true)"
if [[ -z "$CLI" && -x /opt/homebrew/bin/betterdisplaycli ]]; then
  CLI="/opt/homebrew/bin/betterdisplaycli"
fi
if [[ -z "$CLI" || ! -x "$CLI" ]]; then
  printf 'betterdisplaycli was not found. Install the official BetterDisplay CLI first.\n' >&2
  exit 127
fi

if "$CLI" set \
  "--namelike=$DISPLAY_NAME" \
  --feature=ddc \
  --vcp=0x60 \
  "--value=$INPUT_CODE"; then
  printf 'Sent DisplayPort input selection to %s (VCP 0x60=%s).\n' "$DISPLAY_NAME" "$INPUT_CODE"
else
  status=$?
  printf 'BetterDisplay CLI command failed. Check the CLI diagnostic above and verify that the app responds to CLI/notification integration.\n' >&2
  exit "$status"
fi
