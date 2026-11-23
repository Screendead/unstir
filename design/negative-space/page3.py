#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
"""Gathers the third pitch page (three versions of the Descent) into build/negative-space/page3/: each screen at
660 px wide as WebP, the films, and pitch3.html. Needs Pillow."""
import shutil
from pathlib import Path
from PIL import Image

here = Path(__file__).resolve().parent
root = here.parents[1] / 'build/negative-space'
page = root / 'page3'
shutil.rmtree(page, ignore_errors=True)
(page / 'img').mkdir(parents=True)
(page / 'film').mkdir()

# Row name -> (today's shot, the worlds' shot name).
ROWS = {
    'midway': ('menu-landing', 'menu'),
    'today': ('menu-all-done', 'menu-today'),
    'play': ('level01', 'play'),
    'result': ('result-fullest', 'result'),
    'prism': ('prism-dealt', 'prism'),
    'pack': ('card-prism', 'pack'),
    'settings': ('settings', 'settings'),
}
WORLDS = ['plumb', 'lamplight', 'shelf', 'descent']


def small(src, dest):
    Image.open(src).convert('RGB').resize((660, 1434), Image.LANCZOS).save(page / 'img' / dest, quality=84)


for row, (before, shot) in ROWS.items():
    small(root / 'before' / f'{before}.png', f'today-{row}.webp')
    for w in WORLDS:
        small(root / 'world' / w / f'{shot}.png', f'{w}-{row}.webp')
for w in WORLDS[:3]:
    for extra in ['menu-rm', 'play-rm', 'menu-ax', 'play-ax']:
        if (root / 'world' / w / f'{extra}.png').exists():
            small(root / 'world' / w / f'{extra}.png', f'{w}-{extra}.webp')
    shutil.copy(root / 'world' / w / 'film.mp4', page / 'film' / f'{w}.mp4')
shutil.copy(here / 'pitch3.html', page / 'pitch3.html')
print(sum(f.stat().st_size for f in page.rglob('*') if f.is_file()) // 1024, 'KB')
