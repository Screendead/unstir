#!/bin/bash
# Usage: scripts/pull-log.sh [--sim] [destination]   Copies the recorder's log off the phone (or the booted simulator).
# UNSTIR_DEVICE names the phone (a UDID from `xcrun devicectl list devices`). The default destination is unstir-log.txt in the current directory.
set -euo pipefail
bundle=com.screendead.Unstir
if [[ "${1:-}" == --sim ]]; then
  out="${2:-unstir-log.txt}"
  cp "$(xcrun simctl get_app_container booted "$bundle" data)/Library/unstir-log.txt" "$out"
else
  out="${1:-unstir-log.txt}"
  xcrun devicectl device copy from --device "${UNSTIR_DEVICE:?set UNSTIR_DEVICE to a UDID from xcrun devicectl list devices}" \
    --domain-type appDataContainer --domain-identifier "$bundle" --source Library/unstir-log.txt --destination "$out" --quiet
fi
echo "$out"
