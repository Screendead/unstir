#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
# Cuts the Rings world's glass out of real pictures into build/negative-space/glass/, each as a disc on alpha:
#   crop.py <play screenshot, 1320 x 2868> <lens promo 1024> <escapement promo 1024> <prism promo 1024>
# The play screenshot is one of shots.sh's levels (its tank centred at 658, 1446, radius 610 px); the promos are
# promo.sh's. Needs Pillow.
import sys
from pathlib import Path
from PIL import Image, ImageDraw

out = Path(__file__).resolve().parents[4] / 'build/negative-space/glass'
out.mkdir(parents=True, exist_ok=True)

def disc(src, cx, cy, r, side, name):
    im = Image.open(src).convert('RGB').crop((cx - r, cy - r, cx + r, cy + r)).resize((side * 4, side * 4), Image.LANCZOS)
    mask = Image.new('L', im.size, 0)
    ImageDraw.Draw(mask).ellipse((2, 2, im.size[0] - 3, im.size[1] - 3), fill=255)
    im.putalpha(mask)
    im.resize((side, side), Image.LANCZOS).save(out / f'{name}.png')

tank, lens, escapement, prism = sys.argv[1:5]
disc(tank, 658, 1446, 612, 1228, 'rings-tank')
for name, src in (('lens', lens), ('escapement', escapement), ('prism', prism)):
    disc(src, 512, 512, 450, 300, f'rings-{name}')
