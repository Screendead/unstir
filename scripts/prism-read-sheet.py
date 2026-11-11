#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/prism-read-sheet.py <out.png> <move> [variant...] [--box x,y,side]
# Lays the `shots.sh prism-read-` holds of one move (01-cyan, 15-magenta...) out a variant a row (today unless given):
# at rest, a step and half a step short of the count, on it, half a step and a step past. --box crops each to a square
# of the tank instead, in tank pixels of 1200. Each row is captioned as the films are, each column with its hold
# (needs Pillow).
import sys
from PIL import Image, ImageDraw, ImageFont

args = sys.argv[1:]
box = None
if "--box" in args:
    i = args.index("--box")
    box = [int(v) for v in args[i + 1].split(",")]
    del args[i:i + 2]
out, move, variants = args[0], args[1], args[2:] or ["today"]
tags = ["rest", "short10", "short5", "on", "past5", "past10"]
holds = ["in hand, unturned", "1 short", "half short", "on the count", "half past", "1 past"]
words = {"today": "today", "a": "the other colours dim", "b": "white only", "c": "out of register dims",
         "d": "own colour, white on overlap", "e": "own colour, white fades in near"}
font = ImageFont.truetype("/System/Library/Fonts/SFNSMono.ttf", 15)
side, gap = 400, 6
sheet = Image.new("RGB", (len(tags) * (side + gap) - gap, len(variants) * (side + gap) - gap), (40, 40, 40))
for r, v in enumerate(variants):
    for c, tag in enumerate(tags):
        tank = Image.open(f"shots/prism-read-{v}-{move}-{tag}.png").convert("RGB").crop((60, 820, 1260, 2020))
        if box:
            tank = tank.crop((box[0], box[1], box[0] + box[2], box[1] + box[2]))
        sheet.paste(tank.resize((side, side), Image.LANCZOS), (c * (side + gap), r * (side + gap)))
        draw = ImageDraw.Draw(sheet)
        draw.text((c * (side + gap) + 6, r * (side + gap) + side - 22), holds[c], font=font, fill=(255, 255, 255))
        if c == 0:
            draw.text((6, r * (side + gap) + 4), words[v], font=font, fill=(255, 255, 255))
sheet.save(out)
