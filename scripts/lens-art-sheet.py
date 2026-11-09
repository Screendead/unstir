#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
"""Lays the lensart shots (scripts/shots.sh lensart-) out as one contact sheet for Jack's call on Lens's art: a column
per option's level, its tank as dealt, then drawn clean with only its lens magnified, then the whole clean panel as the
Mac bakes it (scripts/lens-panels.sh render, into the clean directory given). Needs Pillow.
Usage: scripts/lens-art-sheet.py <clean dir> <out.png>"""
import sys

from PIL import Image, ImageDraw, ImageFont

COLUMNS = [
    ("A  The Switch, panel 2", "switch02", "02"),
    ("B  Keyhole, its own scene", "keyhole", "01"),
    ("C  Close-up panel, level 1", "closeup", "01"),
    ("C  same panel, level 4", "closeup", "04"),
    ("C  same panel, level 6", "closeup", "06"),
    ("D  test panel, level 2", "test", "02"),
]
ROWS = ["as dealt", "lens only", "clean panel"]


def tank(path, cell):
    # The tank on a 1320 x 2868 Pro Max screen: a 1200-point square, the glass's radius 600 px.
    return Image.open(path).convert("RGB").crop((60, 820, 1260, 2020)).resize((cell, cell), Image.LANCZOS)


def disc(path, cell):
    im = Image.open(path).convert("RGB").resize((cell, cell), Image.LANCZOS)
    mask = Image.new("L", (cell, cell), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, cell - 1, cell - 1), fill=255)
    out = Image.new("RGB", (cell, cell), "black")
    out.paste(im, (0, 0), mask)
    ImageDraw.Draw(out).ellipse((0, 0, cell - 1, cell - 1), outline=(90, 90, 100), width=3)
    return out


def main():
    clean, out = sys.argv[1], sys.argv[2]
    cell, pad, head, side = 420, 14, 46, 170
    sheet = Image.new("RGB", (side + len(COLUMNS) * (cell + pad) + pad, head + len(ROWS) * (cell + pad) + pad), "black")
    draw = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Menlo.ttc", 21)
    except OSError:
        font = ImageFont.load_default()
    for r, label in enumerate(ROWS):
        draw.text((pad, head + r * (cell + pad) + cell // 2 - 12), label, fill="white", font=font)
    for c, (label, panel, level) in enumerate(COLUMNS):
        x = side + pad + c * (cell + pad)
        draw.text((x + 4, 12), label, fill="white", font=font)
        images = [tank(f"shots/lensart-{panel}-{level}.png", cell), tank(f"shots/lensart-{panel}-{level}-clue.png", cell),
                  disc(f"{clean}/{panel}-clean.png", cell)]
        for r, im in enumerate(images):
            sheet.paste(im, (x, head + r * (cell + pad)))
    sheet.save(out)


if __name__ == "__main__":
    main()
