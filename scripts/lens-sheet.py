#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
"""Lays the lens-01 to lens-25 shots (scripts/shots.sh lens-) out as one contact sheet, each tank labelled with its
number, layout, lens rods and depth from the doc's table (default docs/lens-tables.md, table A or B), and nothing
drawn over the glass, so every rim reads as the game draws it. Needs Pillow.
Usage: scripts/lens-sheet.py <A|B> <out.png> [doc]"""
import re
import sys

from PIL import Image, ImageDraw, ImageFont

def rows(doc, table):
    part = open(doc, encoding="utf-8").read().split(f"## Table {table}")[1].split("## Table")[0]
    for line in part.splitlines():
        c = [x.strip().strip("`") for x in line.strip().strip("|").split("|")]
        if len(c) > 5 and c[0].isdigit():
            yield int(c[0]), c[2], [int(x) for x in re.findall(r"\d+", c[3])], len(c[4].split(","))


def main():
    table, out = sys.argv[1], sys.argv[2]
    doc = sys.argv[3] if len(sys.argv) > 3 else "docs/lens-tables.md"
    cell, cols, pad = 400, 5, 12
    sheet = Image.new("RGB", (cols * (cell + pad) + pad, 5 * (cell + 44 + pad) + pad), "black")
    draw = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Menlo.ttc", 22)
    except OSError:
        font = ImageFont.load_default()
    for n, layout, lenses, depth in rows(doc, table):
        # The tank on a 1320 x 2868 Pro Max screen: a 1200-point square, the glass's radius 600 px.
        tank = Image.open(f"shots/lens-{n:02d}.png").convert("RGB").crop((60, 820, 1260, 2020)).resize((cell, cell), Image.LANCZOS)
        x, y = pad + (n - 1) % cols * (cell + pad), pad + (n - 1) // cols * (cell + 44 + pad)
        sheet.paste(tank, (x, y + 44))
        draw.text((x + 4, y + 8), f"{n:02d} {layout} lens {','.join(map(str, lenses))} · {depth}", fill="white", font=font)
    sheet.save(out)


if __name__ == "__main__":
    main()
