#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/app-size.sh <Unstir.app> [limit MB]   Prints the bundle's size and its largest parts, and fails past
# the limit (100 MB unless given). Sizes are the files' own bytes, in MB of 10^6 bytes, as App Store Connect counts.
set -euo pipefail
app=${1:?usage: scripts/app-size.sh <Unstir.app> [limit MB]}
limit=${2:-100}
[[ -d "$app" ]] || { echo "no app at $app" >&2; exit 2; }
bytes() { find "$1" -type f -print0 | xargs -0 stat -f %z | awk '{ s += $1 } END { print s + 0 }'; }
mb() { awk -v b="$1" 'BEGIN { printf "%.1f", b / 1e6 }'; }
total=$(bytes "$app")
echo "$(basename "$app"): $(mb "$total") MB (limit $limit MB)"
for part in "$app"/* "$app"/Sounds/*/*; do
  [[ -e "$part" && "$part" != "$app/Sounds" ]] || continue
  echo "$(bytes "$part") ${part#"$app"/}"
done | sort -rn | head -12 | while read -r b name; do printf '  %7s MB  %s\n' "$(mb "$b")" "$name"; done
awk -v t="$total" -v l="$limit" 'BEGIN { exit !(t > l * 1e6) }' && { echo "error: the app is past $limit MB" >&2; exit 1; }
exit 0
