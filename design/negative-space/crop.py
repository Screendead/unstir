#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
"""Cuts the real glass out of the before shots for the mock-ups: each tank, the card's clip and the dock's covers,
masked to their circles, and the status bar. Nothing is redrawn. Needs Pillow."""
import sys
from pathlib import Path
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[2] / 'build/negative-space'
src, out = root / 'before', root / 'glass'
out.mkdir(parents=True, exist_ok=True)


def lit(im, x0, y0, x1, y1, floor=40):
    """Columns and rows in the box whose pixels rise over the black ground."""
    px = im.load()
    cols = [sum(1 for y in range(y0, y1, 2) if sum(px[x, y]) > floor) for x in range(x0, x1)]
    rows = [sum(1 for x in range(x0, x1, 2) if sum(px[x, y]) > floor) for y in range(y0, y1)]
    return cols, rows


def disc(name, box, dest, need=0.25):
    """The circle inside box: the span of columns and rows lit over a share of the box, made square and masked."""
    im = Image.open(src / f'{name}.png').convert('RGB')
    x0, y0, x1, y1 = box
    cols, rows = lit(im, x0, y0, x1, y1)
    cmax, rmax = max(cols), max(rows)
    xs = [x0 + i for i, c in enumerate(cols) if c > cmax * need]
    # The circle's width is its lit columns' span; its centre row is the middle of what is lit just inside its left
    # edge, where only the rim's equator shows.
    side = xs[-1] + 1 - xs[0]
    px = im.load()
    edge = [y for y in range(y0, y1) if sum(px[xs[0] + 4, y]) > 40]
    cy = (edge[0] + edge[-1]) / 2
    l, t = xs[0], round(cy - side / 2)
    crop = im.crop((l, t, l + side, t + side)).convert('RGBA')
    mask = Image.new('L', (side * 4, side * 4), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, side * 4 - 1, side * 4 - 1), fill=255)
    crop.putalpha(mask.resize((side, side), Image.LANCZOS))
    crop.save(out / dest)
    print(f'{dest}: {side}px at ({l}, {t}) from {name}')


def covers(name, band, names):
    """The dock's covers: runs of lit columns along the band, one per cover."""
    im = Image.open(src / f'{name}.png').convert('RGB')
    y0, y1 = band
    cols, _ = lit(im, 0, y0, im.width, y1, floor=60)
    runs, start = [], None
    for x, c in enumerate(cols + [0]):
        if c > 20 and start is None:
            start = x
        elif c <= 20 and start is not None:
            if x - start > 60:
                runs.append((start, x))
            start = None
    for (a, b), n in zip(runs, names):
        disc(name, (a - 6, y0, b + 6, y1), f'cover-{n}.png', need=0.15)


im = Image.open(src / 'menu-all-done.png').convert('RGB')
bar = im.crop((0, 0, im.width, 162)).resize((440, 54), Image.LANCZOS)
# The status bar over any ground: its black made clear, each pixel's light kept as alpha over its own colour.
alpha = bar.convert('L').point(lambda v: min(255, v * 2))
bar.putalpha(alpha)
bar.save(out / 'status.png')
disc('level01', (0, 560, 1320, 1700), 'play01.png')
disc('result-fullest', (0, 560, 1320, 1640), 'drain-solved.png')
disc('prism-dealt', (0, 560, 1320, 1700), 'prism01.png')
disc('card-prism', (200, 650, 1120, 1640), 'prism-clip.png')
covers('menu-all-done', (2400, 2580), ['first-stir', 'lens', 'escapement', 'prism', 'triptych'])
