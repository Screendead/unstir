#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Fails when a file every session reads grows past its limit, in characters. CLAUDE.md loads into every session and
# subagent whole, so it holds rules and pointers; description goes to docs/architecture.md and decisions to
# docs/decisions.md. Raise a limit only after shortening what is there.
set -euo pipefail
cd "$(dirname "$0")/.."
status=0
while read -r file limit; do
	size=$(wc -m < "$file" | tr -d ' ')
	if (( size > limit )); then
		echo "::error file=$file::$file is $size characters, over its limit of $limit. Shorten it before adding to it."
		status=1
	else
		echo "$file: $size of $limit"
	fi
done <<'LIMITS'
CLAUDE.md 30000
HANDOFF.md 150000
LIMITS
exit $status
