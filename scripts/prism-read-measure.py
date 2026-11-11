#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/prism-read-measure.py [variant...]
# For each move `shots.sh prism-read-` holds, prints the share of the lit pixels in the held rod's rigid disc that are
# white (every channel lit) at each hold: a peak on the count is a picture that shows it, a flat row one that doesn't.
# Each hold is the rod in hand, "rest" unturned, so a variant is already drawn there. A variant that hides lines has
# fewer lit pixels to share, so the white pixels' share of the whole disc follows in brackets, per cent. A move whose
# shots are missing is left out.
# The glass is taken as 575 px of the 600 the crop holds, by eye, and the knob's cap is left out (needs Pillow).
import math, sys
from PIL import Image

def ring(n, r, z, a0=-90):
    return [(r * math.cos(math.radians(a0 + 360 * k / n)), r * math.sin(math.radians(a0 + 360 * k / n)), z) for k in range(n)]
layouts = {"tri": ring(3, 0.42, 0.58), "quad": ring(4, 0.5, 0.48, -45), "pent": ring(5, 0.56, 0.44)}
moves = [("01-cyan", "tri", 1), ("01-red", "tri", 0), ("01-white", "tri", 2), ("08-blue", "pent", 0),
         ("15-magenta", "quad", 2), ("30-yellow", "pent", 0), ("22-blue", "pent", 2)]
tags = ["rest", "short10", "short5", "on", "past5", "past10"]
import os
for variant in sys.argv[1:] or ["today"]:
    print(variant + "\t" + "\t".join(tags))
    for name, layout, rod in moves:
        if not os.path.exists(f"shots/prism-read-{variant}-{name}-rest.png"):
            continue
        x, y, z = layouts[layout][rod]
        row = []
        for tag in tags:
            im = Image.open(f"shots/prism-read-{variant}-{name}-{tag}.png").convert("RGB").crop((60, 820, 1260, 2020))
            px, area, lit, white = im.load(), 0, 0, 0
            cx, cy, r0, r1 = 600 + 575 * x, 600 + 575 * y, 575 * 0.12, 575 * 0.6 * z
            for j in range(int(cy - r1), int(cy + r1) + 1):
                for i in range(int(cx - r1), int(cx + r1) + 1):
                    d = math.hypot(i - cx, j - cy)
                    if r0 < d < r1:
                        p = px[i, j]
                        area += 1
                        if max(p) > 110:
                            lit += 1
                            white += min(p) > 0.6 * max(p)
            row.append(f"{white / max(lit, 1):.2f} ({100 * white / area:.1f})")
        print(name + "\t" + "\t".join(row))
