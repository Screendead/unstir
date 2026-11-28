# Copyright © 2026 Jack Lusher. All rights reserved.
"""Ranks `scripts/prism-levels.sh bury` output against the specimen's row in docs/prism-design.md.

  python3 scripts/prism-levels/bury-rank.py <dir> [top]

<dir> holds one `bury` TSV a specimen, named <number>.tsv. Keeps the deals in their tray's depth band and the deep
trays' readability limits, the white stir in the middle of the stack (0.3 to 0.7 of its depth), and prints the
hardest first by pick.py's hardness (fewer right moves a step, 0.35 a blocked knob, 0.1 a forced step), as a gain over
the specimen as dealt today.
"""
import os
import re
import sys

root = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
doc = open(os.path.join(root, 'docs', 'prism-design.md')).read()
base = {}
for m in re.finditer(r'^\| (\d+) \| \w+ \| [^|]+\| `[^`]+` \| (\d+) \| [^|]+\| (\d+) \| ([\d.]+) \| ([\d.]+) \|', doc, re.M):
    n, depth, blocked, right, forced = m.groups()
    base[int(n)] = (int(depth), int(blocked), float(right), float(forced))
band = {12: (13, 16), 13: (14, 16), 14: (15, 16)}


def hardness(blocked, right, forced):
    return -right + 0.35 * blocked + 0.1 * forced


folder, top = sys.argv[1], int(sys.argv[2]) if len(sys.argv) > 2 else 3
for name in sorted(os.listdir(folder)):
    if not re.fullmatch(r'\d+\.tsv', name):
        continue
    n = int(name[:-4])
    d0, b0, r0, f0 = base[n]
    lo, hi = band.get((n - 1) // 6, (1, 16))
    picks = []
    for line in open(os.path.join(folder, name)).read().splitlines()[1:]:
        f = line.split('\t')
        how, at, depth = f[0], int(f[1]), int(f[5])
        blocked, right, forced = int(f[9]), float(f[10]), float(f[11])
        ghost, triple, least = int(f[13][:-1]), int(f[14][:-1]), f[16]
        if not lo <= depth <= hi or not 0.3 <= at / depth <= 0.7:
            continue
        if (triple > 0 and (ghost > 75 or triple > 25)) or ghost > 90:
            continue
        if least != '-' and float(least) < 0.5:
            continue
        gain = hardness(blocked, right, forced) - hardness(b0, r0, f0)
        picks.append((gain, how, at, depth, blocked, right, forced, ghost, triple, f[18]))
    picks.sort(reverse=True)
    print(f'== {n}: depth {d0}, blocked {b0}, right/step {r0}, forced {f0} ({len(picks)} kept)')
    for p in picks[:top]:
        print('  %+.2f %-9s at %2d depth %d blocked %d right/step %.2f forced %.1f ghost %d%% triple %d%%  %s' % p)
