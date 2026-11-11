#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
"""Usage: scripts/escapement/nowait-sheet.py <old shots dir> <new shots dir> <out.png>

One sheet of every problem the no-wait book deals again: the tank as problems.tsv dealt it beside the tank as
problems-nowait.tsv deals it, from each directory's escapement-book-NN.png (scripts/shots.sh), with its title, layout,
clocks and par, the old line with its waits and the new line of whole heals. Needs Pillow.
"""
import os
import re
import subprocess
import sys
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def rows(name):
    return [line.split("\t") for line in open(os.path.join(ROOT, "scripts/escapement", name)).read().splitlines()]


def line(row, waits):
    out = subprocess.run([os.path.join(ROOT, "scripts/escapement.sh"), "check", row[1], row[3], row[2], "6", "quick"],
                         env=dict(os.environ, ESC_WAIT="1" if waits else "0"), capture_output=True, text=True,
                         check=True).stdout.splitlines()
    at = next(i for i, text in enumerate(out) if text.startswith("clean lines at"))
    return out[at + 1].strip()


def tank(folder, n, side):
    # The tank on a 1320 x 2868 Pro Max screen, as film.sh crops it.
    shot = Image.open(os.path.join(folder, f"escapement-book-{n:02d}.png")).convert("RGB")
    return shot.crop((60, 820, 1260, 2020)).resize((side, side))


def main():
    old_dir, new_dir, out = sys.argv[1:4]
    titles = re.findall(r'level\.escapement-\d+\.title", defaultValue: "([^"]+)"',
                        open(os.path.join(ROOT, "Sources/Pack.swift")).read())
    pairs = [(o, n) for o, n in zip(rows("problems.tsv"), rows("problems-nowait.tsv")) if o != n]
    side, gap, foot, across = 330, 16, 118, 2
    cell = 2 * side + gap
    font = ImageFont.truetype("/System/Library/Fonts/SFNSMono.ttf", 22)
    small = ImageFont.truetype("/System/Library/Fonts/SFNSMono.ttf", 17)
    down = (len(pairs) + across - 1) // across
    sheet = Image.new("RGB", (across * (cell + 3 * gap) + gap, down * (side + foot + gap) + 60), (12, 12, 14))
    d = ImageDraw.Draw(sheet)
    d.text((gap, 16), "Escapement without the wait: each problem dealt again, as it was (left) and as it would be (right)",
           font=font, fill=(243, 234, 216))
    for i, (o, n) in enumerate(pairs):
        number = int(o[0])
        x, y = gap + (i % across) * (cell + 3 * gap), 60 + (i // across) * (side + foot + gap)
        sheet.paste(tank(old_dir, number, side), (x, y))
        sheet.paste(tank(new_dir, number, side), (x + side + gap, y))
        was, now = line(o, True), line(n, False)
        par = len(now.split())
        d.text((x, y + side + 8), f"{number:02d} {titles[number - 1]}  {o[1]}  clocks {o[2]}  par {par}", font=font,
               fill=(235, 235, 235))
        d.text((x, y + side + 40), f"was  {was}", font=small, fill=(216, 64, 42))
        d.text((x, y + side + 64), f"now  {now}", font=small, fill=(150, 210, 150))
        d.text((x, y + side + 88), f"one line of whole heals: all {par} moves forced", font=small, fill=(150, 150, 160))
    sheet.save(out)
    print(out)


if __name__ == "__main__":
    main()
