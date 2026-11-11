#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
"""Lens's drawn panels (Sources/LensArt*.swift) laid out for looking at. Needs Pillow.
Usage: scripts/lens-art-sheet.py proof <out dir> <level>...   each level's panel as the Mac bakes it
                                                              (scripts/lens-panels.sh), clean and with only its
                                                              lenses magnified (LEVELS), and each lens's core again at
                                                              three times the size
       scripts/lens-art-sheet.py sheet <out.png> <level>...   a column a level: the panel as drawn (the Mac's bake),
                                                              then the game's own shots of it as dealt and with only
                                                              its lenses magnified (scripts/shots.sh lens-NN),
                                                              over the level's name
       scripts/lens-art-sheet.py clues                        NN=stack for each drawn level, for scripts/shots/lens.sh
       scripts/lens-art-sheet.py check [level...]             scripts/lens-panels.sh check, each drawn panel on its level"""
import os
import subprocess
import sys

# A drawn level: its panel's name, its title, layout and lens rods (Pack.swift), and its lenses as the clue shot holds
# them: at what the deal nets on each, or at +2 (x4) where it nets +3, since the bake is soft at x8 and a lens passes x4
# on its way home.
LEVELS = {
    1: ("keyhole", "Keyhole", "tri", "0", "0:+2"),
    2: ("peephole", "Peephole", "tri", "0", "0:+1"),
    3: ("magnifier", "Magnifying glass", "tri", "0", "0:+2"),
    4: ("monocle", "Monocle", "tri", "1", "1:+2"),
    5: ("goggles", "Goggles", "eye", "2", "2:+2"),
    6: ("spyglass", "Spyglass", "eye", "0", "0:+2"),
    7: ("binoculars", "Binoculars", "tri", "0,1", "0:+2,1:+1"),
    8: ("spectacles", "Spectacles", "quad", "0,2", "0:+2,2:+2"),
    9: ("sunglasses", "Sunglasses", "eye", "2,3", "2:+2,3:+2"),
    10: ("pinhole", "Pinhole", "tri", "2", "2:+2"),
    11: ("bifocals", "Bifocals", "quad", "1,3", "1:+2,3:+2"),
    12: ("glasses3d", "3D glasses", "eye", "0,1", "0:+2,1:+2"),
    13: ("porthole", "Porthole", "hex", "1,4", "1:+2,4:+2"),
    14: ("periscope", "Periscope", "hex", "2,5", "2:+2,5:+2"),
    15: ("telescope", "Telescope", "eye", "2", "2:+2"),
    16: ("eyepiece", "Eyepiece", "tri", "0", "0:+2"),
    17: ("microscope", "Microscope", "hex", "1,3,5", "1:+2,3:+2,5:+2"),
    18: ("nightvision", "Night vision", "quad", "0,2", "0:+2,2:+2"),
    19: ("camera", "Camera", "hex", "0", "0:+2"),
    20: ("shutter", "Shutter", "hex", "0,1,4", "0:+2,1:+2,4:+2"),
    21: ("viewfinder", "Viewfinder", "eye", "0,3", "0:+2,3:+2"),
    22: ("wideangle", "Wide angle", "hex", "0,2,5", "0:+2,2:+2,5:+2"),
    23: ("fisheye", "Fisheye", "hex", "0", "0:+2"),
    24: ("telephoto", "Telephoto", "eye", "2,3", "2:+2,3:+2"),
    25: ("kaleidoscope", "Kaleidoscope", "hex", "0,1,3,5", "0:+2,1:+2,3:+2,5:+2"),
}
RODS = {
    "tri": [(0, -0.42, 0.58), (0.3637, 0.21, 0.58), (-0.3637, 0.21, 0.58)],
    "quad": [(0.3536, -0.3536, 0.48), (0.3536, 0.3536, 0.48), (-0.3536, 0.3536, 0.48), (-0.3536, -0.3536, 0.48)],
    "eye": [(-0.4, 0, 0.58), (0.4, 0, 0.58), (0, -0.56, 0.44), (0, 0.56, 0.44)],
    "hex": [(0, 0, 0.44), (0, -0.56, 0.44), (0.485, -0.28, 0.44), (0.485, 0.28, 0.44), (0, 0.56, 0.44),
            (-0.485, 0.28, 0.44), (-0.485, -0.28, 0.44)],
}
PLATEAU = 0.6


def bake(panel, path, side, *stirred):
    subprocess.run(["scripts/lens-panels.sh", "render", panel, path, str(side), *stirred], check=True,
                   stdout=subprocess.DEVNULL)


def disc(im, cell):
    from PIL import Image, ImageDraw
    im = im.convert("RGB").resize((cell, cell), Image.LANCZOS)
    mask = Image.new("L", (cell, cell), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, cell - 1, cell - 1), fill=255)
    out = Image.new("RGB", (cell, cell), "black")
    out.paste(im, (0, 0), mask)
    ImageDraw.Draw(out).ellipse((0, 0, cell - 1, cell - 1), outline=(90, 90, 100), width=2)
    return out


def tank(path, cell):
    # The tank on a 1320 x 2868 Pro Max screen: a 1200-pixel square.
    from PIL import Image
    return Image.open(path).convert("RGB").crop((60, 820, 1260, 2020)).resize((cell, cell), Image.LANCZOS)


def font(size):
    from PIL import ImageFont
    try:
        return ImageFont.truetype("/System/Library/Fonts/Menlo.ttc", size)
    except OSError:
        return ImageFont.load_default()


def proof(out, levels):
    from PIL import Image, ImageDraw
    os.makedirs(out, exist_ok=True)
    side = 1171
    for n in levels:
        panel, title, layout, lenses, stack = LEVELS[n]
        clean, seen = f"{out}/{panel}-clean.png", f"{out}/{panel}-lens.png"
        bake(panel, clean, side)
        bake(panel, seen, side, layout, lenses, stack)
        cell, crops = 900, []
        through = Image.open(seen).convert("RGB")
        for k in map(int, lenses.split(",")):
            x, y, r = RODS[layout][k]
            reach = PLATEAU * r * 1.15 * side / 2
            cx, cy = (x + 1) * side / 2, (y + 1) * side / 2
            crops.append(through.crop((int(cx - reach), int(cy - reach), int(cx + reach), int(cy + reach)))
                         .resize((cell, cell), Image.LANCZOS))
        sheet = Image.new("RGB", ((2 + len(crops)) * cell, cell), "black")
        sheet.paste(disc(Image.open(clean), cell), (0, 0))
        sheet.paste(disc(through, cell), (cell, 0))
        for i, crop in enumerate(crops):
            sheet.paste(crop, ((2 + i) * cell, 0))
        draw = ImageDraw.Draw(sheet)
        # Each rod's rigid core on the clean bake, a lens's brighter, to draw against.
        for k, (x, y, r) in enumerate(RODS[layout]):
            reach = PLATEAU * r * cell / 2
            cx, cy = (x + 1) * cell / 2, (y + 1) * cell / 2
            lens = str(k) in lenses.split(",")
            draw.ellipse((cx - reach, cy - reach, cx + reach, cy + reach), outline=(255, 90, 90) if lens else (90, 140, 90))
        sheet.save(f"{out}/proof-{n:02d}.png")
        print(f"{out}/proof-{n:02d}.png")


def sheet(out, levels):
    from PIL import Image, ImageDraw
    cell, pad, head, foot, side = 520, 16, 20, 64, 250
    rows = ["as drawn", "in the game,\nas dealt", "in the game,\nonly its lenses\nturned up,\nto x4 at most"]
    image = Image.new("RGB", (side + len(levels) * (cell + pad) + pad, head + len(rows) * (cell + pad) + foot), "black")
    draw = ImageDraw.Draw(image)
    for r, label in enumerate(rows):
        draw.multiline_text((pad, head + r * (cell + pad) + cell // 2 - 50), label, fill="white", font=font(24), spacing=8)
    os.makedirs("build/lens-art", exist_ok=True)
    for c, n in enumerate(levels):
        panel, title = LEVELS[n][:2]
        x = side + pad + c * (cell + pad)
        clean = f"build/lens-art/{panel}-clean.png"
        bake(panel, clean, 1171)
        cells = [disc(Image.open(clean), cell), tank(f"shots/lens-{n:02d}.png", cell), tank(f"shots/lens-{n:02d}-clue.png", cell)]
        for r, im in enumerate(cells):
            image.paste(im, (x, head + r * (cell + pad)))
        draw.text((x + cell // 2, head + len(rows) * (cell + pad) + 8), f"{n}  {title}", fill="white", font=font(30), anchor="ma")
    image.save(out)


def main():
    mode, args = (sys.argv[1] if len(sys.argv) > 1 else ""), sys.argv[2:]
    if mode == "clues":
        print(" ".join(f"{n:02d}={LEVELS[n][4]}" for n in sorted(LEVELS)))
    elif mode == "check":
        failed = False
        for n in [int(a) for a in args] or sorted(LEVELS):
            panel, _, layout, lenses, _ = LEVELS[n]
            done = subprocess.run(["scripts/lens-panels.sh", "check", panel, layout, lenses], capture_output=True, text=True)
            print(f"{n:02d} {panel}: {done.stdout.strip().splitlines()[-1]}")
            failed = failed or done.returncode != 0
        sys.exit(1 if failed else 0)
    elif mode == "proof" and len(args) > 1:
        proof(args[0], [int(a) for a in args[1:]])
    elif mode == "sheet" and len(args) > 1:
        sheet(args[0], [int(a) for a in args[1:]])
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
