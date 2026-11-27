# Copyright © 2026 Jack Lusher. All rights reserved.
# Cuts the Night Sky's real art into build/negative-space/glass/: the three packs' covers from the promoted-purchase
# images (scripts/promo.sh) and a tank and status bar from a play screenshot (scripts/shots.sh whirlpool14).
#   python3 assets.py <promo dir> <play shot.png>
import sys
from pathlib import Path
from PIL import Image

promo, shot = Path(sys.argv[1]), Path(sys.argv[2])
out = Path(__file__).resolve().parents[4] / 'build/negative-space/glass'
out.mkdir(parents=True, exist_ok=True)
for pack in ('lens', 'escapement', 'prism'):
    im = Image.open(promo / f'promo-{pack}-1024.png').convert('RGB')
    im.crop((60, 60, 964, 964)).resize((452, 452), Image.LANCZOS).save(out / f'sky-{pack}.png')
play = Image.open(shot).convert('RGB')
play.crop((40, 830, 1280, 2070)).save(out / 'sky-tank.png')
play.crop((0, 0, 1320, 150)).save(out / 'sky-status.png')
