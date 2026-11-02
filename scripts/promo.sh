#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/promo.sh   Shoots each sold offer's promoted-purchase image (UNSTIR_PROMO, `PromoArt`) through
# scripts/shots.sh and crops each to shots/promo-<offer>-1024.png: 1024 x 1024 px, RGB with no alpha, square corners,
# 72 dpi, as App Store Connect asks of a promoted in-app purchase's image.
set -euo pipefail
cd "$(dirname "$0")/.."
python3 -c 'import PIL' 2>/dev/null || { echo "needs Pillow: python3 -m pip install Pillow" >&2; exit 1; }
scripts/shots.sh promo-
python3 -I - <<'PY'
import glob, re
from PIL import Image

for f in sorted(glob.glob("shots/promo-*.png")):
    if not re.fullmatch(r"shots/promo-[a-z-]+\.png", f) or f.endswith("-1024.png"):
        continue
    im = Image.open(f).convert("RGB")
    w, h = im.size
    x, y = (w - 1024) // 2, (h - 1024) // 2
    out = f[:-4] + "-1024.png"
    im.crop((x, y, x + 1024, y + 1024)).save(out, dpi=(72, 72))
    print(out)
PY
