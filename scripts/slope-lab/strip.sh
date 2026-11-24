#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: UNSTIR_SIM=<udid> scripts/slope-lab/strip.sh <out.png> [shots] [seconds between]
# Shoots a booted simulator `shots` (6) times, `seconds` (1.5) apart, and lays the frames side by side at a quarter
# size: a look at whatever is on it while something else moves it, a finger's path or a harness case (needs Pillow).
set -euo pipefail
udid=${UNSTIR_SIM:?set UNSTIR_SIM to a simulator udid}
out=$1 shots=${2:-6} gap=${3:-1.5}
dir=$(mktemp -d)
for i in $(seq "$shots"); do
  sleep "$gap"
  xcrun simctl io "$udid" screenshot "$dir/$i.png" >/dev/null 2>&1
done
python3 - "$dir" "$shots" "$out" <<'PY'
import sys
from PIL import Image
frames = [Image.open(f"{sys.argv[1]}/{i}.png") for i in range(1, int(sys.argv[2]) + 1)]
w, h = frames[0].width // 4, frames[0].height // 4
strip = Image.new("RGB", ((w + 4) * len(frames) - 4, h))
for i, frame in enumerate(frames):
    strip.paste(frame.resize((w, h)), ((w + 4) * i, 0))
strip.save(sys.argv[3])
PY
