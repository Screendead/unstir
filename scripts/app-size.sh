#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/app-size.sh <Unstir.app> [limit MB]   Prints the bundle's size and its largest parts, and fails past
# the limit (100 MB unless given). Sizes are the files' own bytes, in MB of 10^6 bytes, as App Store Connect counts.
# A test host carries the test bundle and Xcode's testing frameworks, which never ship, so they are left out: a
# framework counts as Xcode's when the iOS Simulator platform's Developer folder holds one of its name.
set -euo pipefail
app=${1:?usage: scripts/app-size.sh <Unstir.app> [limit MB]}
limit=${2:-100}
[[ -d "$app" ]] || { echo "no app at $app" >&2; exit 2; }
bytes() { find "$1" -type f -print0 | xargs -0 stat -f %z | awk '{ s += $1 } END { print s + 0 }'; }
mb() { awk -v b="$1" 'BEGIN { printf "%.1f", b / 1e6 }'; }
developer="$(xcrun --sdk iphonesimulator --show-sdk-platform-path)/Developer"
xcode() {
  case "$1" in PlugIns/*.xctest) return 0 ;; Frameworks/*) [[ -n "$(find "$developer" -maxdepth 3 -name "$(basename "$1")" -print -quit)" ]] ;; *) return 1 ;; esac
}
total=0 left=0
lines=$(for part in "$app"/* "$app"/Frameworks/* "$app"/PlugIns/* "$app"/Sounds/*/*; do
  name=${part#"$app"/}
  [[ -e "$part" ]] || continue
  [[ "$name" == Frameworks || "$name" == PlugIns || "$name" == Sounds ]] && continue
  echo "$(bytes "$part") $name"
done)
while read -r b name; do
  [[ -n "$name" ]] || continue
  if xcode "$name"; then left=$((left + b)); fi
done <<< "$lines"
total=$(( $(bytes "$app") - left ))
echo "$(basename "$app"): $(mb "$total") MB (limit $limit MB)"
[[ $left -eq 0 ]] || echo "  left out: $(mb "$left") MB of the test bundle and Xcode's testing frameworks"
while read -r b name; do
  if [[ -n "$name" ]] && ! xcode "$name"; then echo "$b $name"; fi
done <<< "$lines" | sort -rn | head -12 | while read -r b name; do printf '  %7s MB  %s\n' "$(mb "$b")" "$name"; done
awk -v t="$total" -v l="$limit" 'BEGIN { exit !(t > l * 1e6) }' && { echo "error: the app is past $limit MB" >&2; exit 1; }
exit 0
