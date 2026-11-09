# Copyright © 2026 Jack Lusher. All rights reserved.
# Sourced by the scripts that launch the app with harness variables and read its flight recorder, on the phone
# UNSTIR_DEVICE names or, given its udid, a simulator: taps-check.sh and duo-feel.sh.

# harness_pull <sim udid or empty> <file>: copies the recorder's log to file, leaving it as it was if there is none yet.
harness_pull() {
  if [[ -n $1 ]]; then
    cp "$(xcrun simctl get_app_container "$1" com.screendead.Unstir data)/Library/unstir-log.txt" "$2" 2>/dev/null || true
  else
    scripts/pull-log.sh "$2" >/dev/null 2>&1 || true
  fi
}

# harness_launch <sim udid or empty> <"KEY":"value" pairs, comma-separated>: launches the app afresh with them.
harness_launch() {
  if [[ -n $1 ]]; then
    local args=()
    while IFS= read -r pair; do args+=("SIMCTL_CHILD_$pair"); done < <(echo "{$2}" | python3 -c \
      'import json, sys; [print(f"{k}={v}") for k, v in json.load(sys.stdin).items()]')
    env "${args[@]}" xcrun simctl launch --terminate-running-process "$1" com.screendead.Unstir >/dev/null
  else
    xcrun devicectl device process launch --device "${UNSTIR_DEVICE:?set UNSTIR_DEVICE to a UDID from xcrun devicectl list devices}" \
      --terminate-existing --environment-variables "{$2}" com.screendead.Unstir >/dev/null
  fi
}
