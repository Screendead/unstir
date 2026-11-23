#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
"""Lays out a screen's before beside each direction, for looking: sheet.py <screen> [scale] -> build/negative-space/sheet-<screen>.png.
Needs Pillow."""
import sys
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[2] / 'build/negative-space'
BEFORE = {'menu': 'menu-all-done', 'play': 'level01', 'result': 'result-fullest', 'prism': 'prism-dealt',
          'card': 'card-prism', 'settings': 'settings'}
screen = sys.argv[1]
scale = float(sys.argv[2]) if len(sys.argv) > 2 else 0.3
suffix = sys.argv[3] if len(sys.argv) > 3 else ''
paths = [root / 'before' / f'{BEFORE[screen]}.png'] + [root / 'stills' / f'{d}-{screen}{suffix}.png' for d in 'abc']
ims = [Image.open(p).convert('RGB') for p in paths]
w, h = int(1320 * scale), int(2868 * scale)
sheet = Image.new('RGB', ((w + 12) * len(ims), h), (60, 60, 60))
for k, im in enumerate(ims):
    sheet.paste(im.resize((w, h), Image.LANCZOS), (k * (w + 12), 0))
sheet.save(root / f'sheet-{screen}{suffix}.png')
