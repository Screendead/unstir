#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/icon.sh [n]   Crops shots/icon-*.png (from scripts/shots.sh icon-) to shots/icon-*-1024.png and lays them out
# in shots/icon-candidates.png at 1024, 180 and 60 px on a dark and a light home screen; with n, also copies candidate n
# into the asset catalog as the app icon.
set -euo pipefail
cd "$(dirname "$0")/.."
python3 -c 'import PIL' 2>/dev/null || { echo "needs Pillow: python3 -m pip install Pillow" >&2; exit 1; }
python3 -I - "${1:-}" <<'EOF'
import glob, re, shutil, sys
from PIL import Image, ImageDraw

shots = sorted(f for f in glob.glob("shots/icon-*.png") if re.fullmatch(r"shots/icon-\d+\.png", f))
icons = []
for f in shots:
    im = Image.open(f).convert("RGB")
    w, h = im.size
    # The screen's centre, where IconView draws.
    x, y = (w - 1024) // 2, (h - 1024) // 2
    icon = im.crop((x, y, x + 1024, y + 1024))
    # App Store Connect refuses an icon with an alpha channel, even an opaque one.
    icon.save(f[:-4] + "-1024.png")
    icons.append(icon)

def masked(icon, size, bg):
    # The home screen's continuous-corner squircle, approximated by a rounded square of 22.37% radius.
    small = icon.resize((size, size), Image.LANCZOS)
    k = 4
    mask = Image.new("L", (size * k, size * k), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size * k - 1, size * k - 1), radius=0.2237 * size * k, fill=255)
    tile = Image.new("RGB", (size, size), bg)
    tile.paste(small, (0, 0), mask.resize((size, size), Image.LANCZOS))
    return tile

tones = [(28, 30, 36), (226, 228, 234)]
pad = 48
col = 1024 + pad + 2 * (180 + 60 + 3 * pad)
sheet = Image.new("RGB", (pad + col, pad + len(icons) * (1024 + pad)), (12, 12, 14))
for i, icon in enumerate(icons):
    top = pad + i * (1024 + pad)
    sheet.paste(icon, (pad, top))
    x = pad + 1024 + pad
    for tone in tones:
        block = Image.new("RGB", (180 + 60 + 3 * pad, 1024), tone)
        sheet.paste(block, (x - pad // 2, top))
        sheet.paste(masked(icon, 180, tone), (x, top + 200))
        sheet.paste(masked(icon, 60, tone), (x + 180 + pad, top + 260))
        # The 60 px one again, doubled with no smoothing, to judge its pixels.
        sheet.paste(masked(icon, 60, tone).resize((120, 120), Image.NEAREST), (x + 30, top + 600))
        x += 180 + 60 + 3 * pad
sheet.save("shots/icon-candidates.png")
print("shots/icon-candidates.png:", len(icons), "candidates")

if sys.argv[1]:
    shutil.copy(f"shots/icon-{sys.argv[1]}-1024.png", "Sources/Assets.xcassets/AppIcon.appiconset/icon.png")
    print("candidate", sys.argv[1], "is the app icon")
EOF
