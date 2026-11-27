# Copyright © 2026 Jack Lusher. All rights reserved.
# Cuts the wheel world's glass out of real pictures of the game, never redrawn:
#   python3 crop.py <promo dir> <tank shot> <out dir>
# <promo dir> holds scripts/promo.sh's promo-{lens,escapement,prism}-1024.png, <tank shot> is a 1320 x 2868 shot of a
# level in play (scripts/shots.sh), <out dir> is build/negative-space/glass. Each disc is cut to its bezel with a
# round mask, so it composes over any ground.
import sys
from PIL import Image, ImageDraw

promo, shot, out = sys.argv[1:4]


def disc(im, name, side):
    grey = im.convert('L').point(lambda v: 255 if v > 40 else 0)
    box = grey.getbbox()
    d = max(box[2] - box[0], box[3] - box[1])
    cx, cy = (box[0] + box[2]) / 2, (box[1] + box[3]) / 2
    im = im.convert('RGBA').crop((round(cx - d / 2), round(cy - d / 2), round(cx + d / 2), round(cy + d / 2)))
    mask = Image.new('L', (d * 2, d * 2), 0)
    ImageDraw.Draw(mask).ellipse((2, 2, d * 2 - 3, d * 2 - 3), fill=255)
    im.putalpha(mask.resize((d, d), Image.LANCZOS))
    im.resize((side, side), Image.LANCZOS).save(f'{out}/{name}.png')


for pack in ('lens', 'escapement', 'prism'):
    disc(Image.open(f'{promo}/promo-{pack}-1024.png'), f'wheel-cover-{pack}', 420)
play = Image.open(shot).convert('RGB')
disc(play.crop((0, 700, 1320, 2200)), 'wheel-tank', 1240)
status = play.crop((0, 0, 1320, 162)).convert('RGBA')
r, g, b = play.crop((0, 0, 1320, 162)).split()
status.putalpha(Image.merge('RGB', (r, g, b)).convert('L').point(lambda v: min(255, v * 2)))   # the shot's ground is black
status.save(f'{out}/wheel-status.png')
