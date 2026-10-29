#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/ci-times.sh <xcodebuild-log>   Prints each suite's time and the 30 slowest tests from a non-quiet log.
set -euo pipefail
echo "== suites =="
awk '/^Test Suite .* (passed|failed) at/ { n = $3 } /^[ \t]*Executed [0-9]+ tests?, with/ { print $(NF-2), n }' "$1" | sort -rn
echo "== slowest 30 tests =="
grep -E "^Test Case .* (passed|failed) \(" "$1" | sed -E "s/.*\[(.*)\]'.*\(([0-9.]+) seconds\).*/\2 \1/" | sort -rn | head -30
