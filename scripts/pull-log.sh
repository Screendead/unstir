#!/bin/bash
# Usage: scripts/pull-log.sh [--sim] [destination]   Copies the recorder's log off the phone (or the booted simulator).
# UNSTIR_DEVICE overrides the reference device. The default destination is unstir-log.txt in the current directory.
set -euo pipefail
bundle=com.screendead.Unstir
if [[ "${1:-}" == --sim ]]; then
  out="${2:-unstir-log.txt}"
  cp "$(xcrun simctl get_app_container booted "$bundle" data)/Library/unstir-log.txt" "$out"
else
  out="${1:-unstir-log.txt}"
  xcrun devicectl device copy from --device "${UNSTIR_DEVICE:-1B834EFE-A784-5F98-9B7A-CF6D83E2123A}" \
    --domain-type appDataContainer --domain-identifier "$bundle" --source Library/unstir-log.txt --destination "$out" --quiet
fi
echo "$out"
