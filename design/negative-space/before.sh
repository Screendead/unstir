#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Shoots the chrome-heaviest harness cases on this checkout into build/negative-space/before/, the "before" of the
# design pass's mock-ups. shots.sh takes one pattern, so it runs once a case; each run after the first builds nothing.
set -euo pipefail
cd "$(dirname "$0")/../.."
out=build/negative-space/before
mkdir -p "$out"
cases=(menu-after-01 menu-all-done level01 prism-dealt result-clean result-fullest card-prism settings)
for c in "${cases[@]}"; do
  scripts/shots.sh "$c" >/dev/null
  cp shots/"$c"*.png "$out"/
done
git checkout -q -- shots/index.txt
ls "$out"
