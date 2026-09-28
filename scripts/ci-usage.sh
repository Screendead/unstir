#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Prints how much of this month's GitHub Actions allowance is left. Needs `gh` with the `user` scope.
# Public repos run free, so only private-repo minutes count, at GitHub Free's 2,000 and its multipliers
# (Linux 1x, Windows 2x, macOS 10x).
set -euo pipefail
user=$(gh api user -q .login)
allowance=2000
usage=$(gh api "/users/$user/settings/billing/usage?year=$(date +%Y)&month=$((10#$(date +%m)))" \
  --jq '.usageItems[] | select(.product == "actions" and (.sku | test("Linux|Windows|macOS"))) | [.repositoryName, .sku, .quantity] | @tsv')
used=0
while IFS=$'\t' read -r repo sku minutes; do
  [ -n "$repo" ] || continue
  [ "$(gh repo view "$user/$repo" --json visibility -q .visibility)" = PRIVATE ] || continue
  case $sku in *macOS*) x=10 ;; *Windows*) x=2 ;; *) x=1 ;; esac
  used=$(echo "$used + $minutes * $x" | bc)
done <<< "$usage"
echo "used $used of $allowance minutes, $(echo "100 - $used * 100 / $allowance" | bc)% left"
