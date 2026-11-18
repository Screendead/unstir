#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/achievement-art.sh [--crop]   Makes Game Center's achievement images, shots/achievement-<id>-1024.png:
# 1024 x 1024 px, RGB with no alpha, 72 dpi, as App Store Connect asks. Each is a tank on black, its bezel at 84% of the
# side as the promoted-purchase images draw theirs (Game Center shows it in a circle): cut from the scripts/shots.sh
# ach- cases, and for the four pack achievements the offers' promoted-purchase images (scripts/promo.sh). --crop reuses
# the shots already taken. Needs Pillow.
set -euo pipefail
cd "$(dirname "$0")/.."
python3 -c 'import PIL' 2>/dev/null || { echo "needs Pillow: python3 -m pip install Pillow" >&2; exit 1; }
if [[ "${1:-}" != --crop ]]; then
  scripts/shots.sh ach-
  scripts/promo.sh
fi
python3 -I - <<'PY'
import glob
from PIL import Image, ImageDraw

def tank(im):
    """The tank's centre and width, glow and all: the bezel is round, so the row where the lit span is widest crosses
    its middle. Rows only through the screen's middle three fifths, clear of the chrome and the card."""
    w, h = im.size
    px = im.load()
    best = (0, 0, 0)
    for y in range(h // 5, 4 * h // 5, 2):
        xs = [x for x in range(0, w, 2) if sum(px[x, y]) > 60]
        if xs and xs[-1] - xs[0] > best[0]:
            best = (xs[-1] - xs[0], (xs[0] + xs[-1]) // 2, y)
    return best

for f in sorted(glob.glob("shots/ach-*.png")):
    name = f[len("shots/ach-"):-4]
    im = Image.open(f).convert("RGB")
    d, cx, cy = tank(im)
    side = round(d / 0.84)
    sq = im.crop((cx - side // 2, cy - side // 2, cx - side // 2 + side, cy - side // 2 + side))
    # Black outside the tank and its glow, so no caption or chrome beside it shows in the square's corners.
    mask = Image.new("L", (side * 2, side * 2), 0)
    r = d * 1.02
    ImageDraw.Draw(mask).ellipse((side - r, side - r, side + r, side + r), fill=255)
    sq = Image.composite(sq, Image.new("RGB", sq.size), mask.resize(sq.size, Image.LANCZOS))
    sq.resize((1024, 1024), Image.LANCZOS).save(f"shots/achievement-{name}-1024.png", dpi=(72, 72))
    print(f"shots/achievement-{name}-1024.png  tank {d} px at ({cx}, {cy})")
for offer, name in [("lens", "in-focus"), ("escapement", "time-well-spent"), ("prism", "white-light"), ("complete", "whole-shelf")]:
    Image.open(f"shots/promo-{offer}-1024.png").convert("RGB").save(f"shots/achievement-{name}-1024.png", dpi=(72, 72))
    print(f"shots/achievement-{name}-1024.png  from promo-{offer}")
PY
