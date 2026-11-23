#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
"""Gathers the second pitch page (Still Water and the three redesign worlds) into build/negative-space/page2/:
each screen at 660 px wide as WebP, the films, and pitch2.html. Needs Pillow."""
import shutil
from pathlib import Path
from PIL import Image

here = Path(__file__).resolve().parent
root = here.parents[1] / 'build/negative-space'
page = root / 'page2'
shutil.rmtree(page, ignore_errors=True)
(page / 'img').mkdir(parents=True)
(page / 'film').mkdir()

# Row name -> (today's shot, Still Water's still, the worlds' shot name).
ROWS = {
    'midway': ('menu-landing', 'b-landing', 'menu'),
    'today': ('menu-all-done', 'b-menu', 'menu-today'),
    'play': ('level01', 'b-play', 'play'),
    'result': ('result-fullest', 'b-result', 'result'),
    'prism': ('prism-dealt', 'b-prism', 'prism'),
    'pack': ('card-prism', 'b-card', 'pack'),
    'settings': ('settings', 'b-settings', 'settings'),
}
WORLDS = ['descent', 'ink', 'basin']


def small(src, dest):
    Image.open(src).convert('RGB').resize((660, 1434), Image.LANCZOS).save(page / 'img' / dest, quality=84)


for row, (before, still, shot) in ROWS.items():
    small(root / 'before' / f'{before}.png', f'today-{row}.webp')
    small(root / 'stills' / f'{still}.png', f'water-{row}.webp')
    for w in WORLDS:
        small(root / 'world' / w / f'{shot}.png', f'{w}-{row}.webp')
for w in WORLDS:
    for extra in ['menu-rm', 'result-rm', 'menu-ax']:
        small(root / 'world' / w / f'{extra}.png', f'{w}-{extra}.webp')
    shutil.copy(root / 'world' / w / 'film.mp4', page / 'film' / f'{w}.mp4')
small(root / 'stills' / 'b-result-rm.png', 'water-result-rm.webp')
small(root / 'stills' / 'b-menu-ax.png', 'water-menu-ax.webp')
shutil.copy(root / 'film-b.mp4', page / 'film' / 'water.mp4')
shutil.copy(here / 'pitch2.html', page / 'pitch2.html')
print(sum(f.stat().st_size for f in page.rglob('*') if f.is_file()) // 1024, 'KB')
