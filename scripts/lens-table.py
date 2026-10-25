#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
"""Checks the draft level table in docs/lens-design.md against the hard lens's rules, with no app code: a lens moves
only its rod's core (0.6 of the disc), so two lenses always commute and a lens commutes with every disc that misses its
core. Rows are the table's lines whose first cell is a number, read as # | issue | layout | lens rods | scramble | ...
Each scramble is parsed as Array.commit would parse it once rods have kinds (a turn merges into its rod's newest entry
when everything above commutes, and pops at 0), commutation decided by overlap alone. Per row it prints the depth,
the lens entries, how many entries come off at the start, and every rule broken: a dealt lens entry outside +1 to +3,
a lens rod netting past +3 or out of every twist rod's reach, an entry the parse merges, or a twist dealt over a lens that drags its rim less than
--pitches dot pitches (0.03 tank units) at the rim's deepest point inside the twist's disc.
Usage: scripts/lens-table.py [docs/lens-design.md] [--pitches 4]"""
import math
import re
import sys

PLATEAU, PITCH, STEP = 0.6, 0.03, math.pi / 6


def ring(n, r, radius, a0=-90):
    return [(r * math.cos(math.radians(a0 + 360 * k / n)), r * math.sin(math.radians(a0 + 360 * k / n)), radius)
            for k in range(n)]


LAYOUTS = {
    "tri": ring(3, 0.42, 0.58),
    "quad": ring(4, 0.5, 0.48, -45),
    "eye": [(-0.4, 0, 0.58), (0.4, 0, 0.58), (0, -0.56, 0.44), (0, 0.56, 0.44)],
    "pent": ring(5, 0.56, 0.44),
    "hex": [(0, 0, 0.44)] + ring(6, 0.56, 0.44),
}


def profile(s):
    t = min(max((s - PLATEAU) / (1 - PLATEAU), 0), 1)
    return 1 - t * t * (3 - 2 * t)


def interacts(rods, lenses, a, b):
    if a in lenses and b in lenses:
        return False
    (xa, ya, ra), (xb, yb, rb) = rods[a], rods[b]
    reach_a = ra * PLATEAU if a in lenses else ra
    reach_b = rb * PLATEAU if b in lenses else rb
    return math.hypot(xa - xb, ya - yb) < reach_a + reach_b


def rim_drag(rods, lens, twist, steps):
    """How far a twist of `steps` carries the lens's rim at its deepest point inside the twist's disc."""
    (xa, ya, ra), (xb, yb, rb) = rods[lens], rods[twist]
    best = 0
    for i in range(1440):
        th = 2 * math.pi * i / 1440
        d = math.hypot(xa + ra * PLATEAU * math.cos(th) - xb, ya + ra * PLATEAU * math.sin(th) - yb)
        if d < rb:
            best = max(best, 2 * d * abs(math.sin(steps * STEP * profile(d / rb) / 2)))
    return best


def check(layout, lenses, scramble, pitches):
    rods = LAYOUTS[layout]
    deal = [(int(r), int(s)) for r, s in (e.split(":") for e in scramble.split(","))]
    problems, stack = [], []
    for rod, steps in deal:
        if not 0 <= rod < len(rods):
            problems.append(f"no rod {rod}")
            return [], problems
        if rod in lenses and not 1 <= steps <= 3:
            problems.append(f"lens {rod}:{steps:+d} is not +1 to +3")
        newest = max((i for i, e in enumerate(stack) if e[0] == rod), default=None)
        if newest is not None and all(not interacts(rods, lenses, rod, e[0]) for e in stack[newest + 1:]):
            problems.append(f"{rod}:{steps:+d} merges into {rod}:{stack[newest][1]:+d}")
            merged = stack[newest][1] + steps
            if merged:
                stack[newest] = (rod, merged)
            else:
                del stack[newest]
        else:
            stack.append((rod, steps))
    for rod in sorted(lenses):
        net = sum(s for r, s in stack if r == rod)
        if net > 3:
            problems.append(f"lens {rod} nets {net:+d}")
        if not any(t not in lenses and interacts(rods, lenses, rod, t) for t in range(len(rods))):
            problems.append(f"no twist rod reaches lens {rod}")
    for i, (lens, _) in enumerate(stack):
        if lens not in lenses:
            continue
        for twist, steps in stack[i + 1:]:
            if twist not in lenses and interacts(rods, lenses, lens, twist):
                drag = rim_drag(rods, lens, twist, steps) / PITCH
                if drag < pitches:
                    problems.append(f"{twist}:{steps:+d} drags lens {lens}'s rim {drag:.1f} pitches")
    return stack, problems


def main():
    args = sys.argv[1:]
    pitches = 4.0
    if "--pitches" in args:
        i = args.index("--pitches")
        pitches = float(args[i + 1])
        del args[i:i + 2]
    path = args[0] if args else "docs/lens-design.md"
    rows = 0
    failed = False
    for line in open(path, encoding="utf-8"):
        cells = [c.strip().strip("`") for c in line.strip().strip("|").split("|")]
        if len(cells) < 5 or not cells[0].isdigit() or cells[2] not in LAYOUTS:
            continue
        rows += 1
        n, layout = int(cells[0]), cells[2]
        lenses = {int(x) for x in re.findall(r"\d+", cells[3])}
        stack, problems = check(layout, lenses, cells[4], pitches)
        rods = LAYOUTS[layout]
        free = sum(all(not interacts(rods, lenses, e[0], f[0]) for f in stack[i + 1:]) for i, e in enumerate(stack))
        lens_entries = sum(r in lenses for r, _ in stack)
        print(f"{n:2d} {layout:4s} lenses {','.join(map(str, sorted(lenses))):7s} depth {len(stack):2d}, "
              f"lens entries {lens_entries}, free at start {free}" + ("".join(f"\n     {p}" for p in problems)))
        failed |= bool(problems)
    if not rows:
        sys.exit(f"no table rows in {path}")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
