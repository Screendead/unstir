#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
"""Gathers the pitch page and its pictures into build/negative-space/page/: each before shot and still at 660 px wide
as WebP, the films as they are, and pitch.html. Needs Pillow."""
import shutil
from pathlib import Path
from PIL import Image

here = Path(__file__).resolve().parent
root = here.parents[1] / 'build/negative-space'
page = root / 'page'
shutil.rmtree(page, ignore_errors=True)
(page / 'img').mkdir(parents=True)
(page / 'film').mkdir()
BEFORE = {'menu': 'menu-all-done', 'play': 'level01', 'result': 'result-fullest', 'prism': 'prism-dealt',
          'card': 'card-prism', 'settings': 'settings'}


def small(src, dest):
    Image.open(src).convert('RGB').resize((660, 1434), Image.LANCZOS).save(page / 'img' / dest, quality=84)


for s, b in BEFORE.items():
    small(root / 'before' / f'{b}.png', f'today-{s}.webp')
for p in sorted((root / 'stills').glob('*.png')):
    small(p, p.stem + '.webp')
for d in 'abc':
    shutil.copy(root / f'film-{d}.mp4', page / 'film' / f'{d}.mp4')
shutil.copy(here / 'pitch.html', page / 'pitch.html')
print(sum(f.stat().st_size for f in page.rglob('*') if f.is_file()) // 1024, 'KB')
