#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Sourced by scripts/build-ios.sh and scripts/archive-ios.sh: the shell's build switches as xcodebuild settings, each
# only when set, so Config/Unstir.xcconfig's defaults and Config/Local.xcconfig hold otherwise.
settings=()
for name in ANALYTICS APTABASE_KEY ANALYTICS_PLAYTEST GAME_CENTER ICLOUD AGE_RANGE ADAPTIVE_TAPS SUPPORT_ADDRESS \
  POLICY_URL EDITORS PROBES; do
  if [[ -n "${!name:-}" ]]; then settings+=("$name=${!name}"); fi
done
