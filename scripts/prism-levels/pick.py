#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
"""Picks Prism's specimen 6 and trays 2 to 5's specimens from pools of `scripts/prism-levels.sh search` TSVs, and
trays 6 to 15's from `scripts/prism-levels/pools.sh`'s.

usage: scripts/prism-levels/pick.py <pool dir>
       scripts/prism-levels/pick.py --deep <pool dir>    trays 6 to 15
       scripts/prism-levels/pick.py --specs              the pools trays 6 to 15 need: layout, depth, palette
       scripts/prism-levels/pick.py --thin <pool dir>    those pools with fewer than three readable rows

Each slot names its tray's pool by layout and depth. A row is readable when at most 72% of the glass shows ghosts
(70% on hex) and at most 8% splits three ways, and keeps four taps under the shader's assumed cost. Within a tray the
slots climb: the first takes the row with the most right moves per step and the fewest blocked knobs, the last the
fewest and the most, the middle ones a share of the way between. A row is used once.
"""
import csv
import glob
import sys

SLOTS = {
    "t1": [("hex", 8)],
    "t2": [("quad", 4), ("pent", 5), ("pent", 6), ("pent", 6), ("pent", 7), ("pent", 8)],
    "t3": [("tri", 4), ("quad", 4), ("quad", 5), ("eye", 5), ("pent", 6), ("pent", 7)],
    "t4": [("quad", 6), ("eye", 6), ("eye", 7), ("pent", 7), ("pent", 8), ("pent", 8)],
    "t5": [("tri", 6), ("quad", 7), ("eye", 7), ("eye", 8), ("pent", 8), ("pent", 8)],
}


# Trays 6 to 15 (the pack trebled, Jack, 2026-11-27): depth climbs a step a tray, twice today's slope, from 8 to 20, by
# (layout, depth, palette). A palette of one primary and its ink (rc, gm, by) moves only two of the three channels' words,
# so it never splits three ways however deep; the mixed ones (rgb, rcgb, rgbcmy) buy colour order at the cost of mush,
# and on hex past 13 they split a fifth of the glass three ways or more (and take the solver minutes), so there hex keeps
# to pairs.
DEEP = {
    "t6": [("quad", 8, "gm"), ("eye", 9, "by"), ("pent", 9, "gm"), ("pent", 10, "by"), ("hex", 10, "gm"), ("hex", 11, "by")],
    "t7": [("pent", 9, "rgb"), ("eye", 10, "rc"), ("pent", 10, "rgb"), ("hex", 11, "rgb"), ("pent", 11, "rgb"), ("hex", 12, "rc")],
    "t8": [("eye", 10, "gm"), ("pent", 11, "rc"), ("pent", 11, "by"), ("hex", 12, "gm"), ("hex", 12, "rc"), ("hex", 13, "by")],
    "t9": [("tri", 11, "cmy"), ("quad", 12, "cmy"), ("eye", 12, "rgbcmy"), ("pent", 13, "rgbcmy"), ("pent", 13, "cmy"),
           ("pent", 14, "rgbcmy")],
    "t10": [("eye", 12, "rc"), ("pent", 13, "rcgb"), ("pent", 13, "rgbcmy"), ("hex", 14, "by"), ("hex", 14, "gm"),
            ("pent", 15, "rgbcmy")],
    "t11": [("pent", 13, "gm"), ("pent", 14, "rcgb"), ("hex", 14, "rc"), ("pent", 15, "rgb"), ("hex", 15, "rc"), ("hex", 16, "gm")],
    "t12": [("pent", 14, "by"), ("pent", 15, "rc"), ("pent", 15, "rgbcmy"), ("hex", 16, "rc"), ("hex", 16, "by"), ("hex", 17, "by")],
    "t13": [("eye", 15, "rc"), ("pent", 16, "gm"), ("pent", 16, "rcgb"), ("hex", 17, "rc"), ("hex", 17, "gm"), ("hex", 18, "gm")],
    "t14": [("pent", 16, "by"), ("pent", 17, "rc"), ("pent", 17, "rgbcmy"), ("hex", 18, "by"), ("pent", 18, "gm"), ("pent", 19, "rc")],
    "t15": [("pent", 17, "gm"), ("hex", 18, "gm"), ("pent", 18, "rcgb"), ("pent", 19, "by"), ("pent", 19, "gm"), ("pent", 20, "rc")],
}


def pct(s):
    return float(s.rstrip("%"))


def readable(r):
    return pct(r["ghost"]) <= (70 if r["layout"] == "hex" else 72) and pct(r["triple"]) <= 8 and int(r["cost"]) <= 30


def ease(r):
    # More right moves and fewer traps is easier; colour-freed entries (free under the masks, not read white) teach.
    free, white = (int(v) for v in r["free"].split("/"))
    return float(r["right/step"]) - 0.35 * int(r["blocked"]) + 0.1 * (free - white)


def main(pool):
    used = set()
    for tray, slots in SLOTS.items():
        for k, (layout, depth) in enumerate(slots):
            rows = []
            for f in glob.glob(f"{pool}/{tray}-{layout}-{depth}*.tsv"):
                rows += [r for r in csv.DictReader(open(f), delimiter="\t") if readable(r)]
            rows = [r for r in rows if r["scramble"] not in used]
            if not rows:
                print(f"{tray} {layout} {depth}: nothing readable")
                continue
            rows.sort(key=ease, reverse=True)
            # Slot k of n takes the row k/(n-1) of the way from the easiest to the hardest.
            share = k / (len(slots) - 1) if len(slots) > 1 else 1
            r = rows[round(share * (len(rows) - 1))]
            used.add(r["scramble"])
            print("\t".join([tray, r["layout"], r["masks"], r["scramble"], r["free"], r["blocked"], r["right/step"],
                             r["ghost"], r["triple"], r["cost"]]))


def deep_readable(r):
    # Past the prototype's limits, as the plates drawn for the treble keep their shapes through deeper ghosts (an ink
    # deal on tri splitting 23% three ways still shows every diatom, looked at 2026-11-27): at most 75% ghosts and 25%
    # split three ways, cost within the four-tap budget the search keeps, and every once-stirred coloured rod's count
    # showing over at least half its core (today's 30 read 0.58 at least).
    least = r.get("least read", "-")
    return pct(r["ghost"]) <= 75 and pct(r["triple"]) <= 25 and int(r["cost"]) <= 30 and least != "-" and float(least) >= 0.5


def hardness(r):
    # Fewer right moves a step, more knobs that push if turned first, more moves read as a sum, more forced steps.
    return -float(r["right/step"]) + 0.35 * int(r["blocked"]) + 0.15 * int(r["sums"]) + 0.1 * float(r["forced"])


def deep(pool):
    used, seen = set(), set()
    for tray, slots in DEEP.items():
        for k, (layout, depth, palette) in enumerate(slots):
            # The slot's own pool, or when nothing in it reads, every pool of its depth. Two specimens on the same rods
            # and masks read as one dealt deeper, so each takes rods and masks no earlier one has, unless no pool of its
            # depth has any.
            own = [p for p in [f"{pool}/{layout}-{depth}-{palette}.tsv"] if glob.glob(p)]
            every = sorted(glob.glob(f"{pool}/*-{depth}-*.tsv"))
            for paths, fresh in ((own, True), (every, True), (own, False), (every, False)):
                rows = [r for path in paths for r in csv.DictReader(open(path), delimiter="\t") if deep_readable(r)]
                rows = [r for r in rows if r["scramble"] not in used]
                if fresh:
                    rows = [r for r in rows if (r["layout"], r["masks"]) not in seen]
                if rows:
                    break
            if not rows:
                print(f"{tray} {layout} {depth} {palette}: nothing readable")
                continue
            rows.sort(key=hardness)
            # Every slot from the harder half; slot k of six k/5 of the way from its middle to the hardest.
            share = 0.5 + 0.5 * k / (len(slots) - 1)
            r = rows[round(share * (len(rows) - 1))]
            used.add(r["scramble"])
            seen.add((r["layout"], r["masks"]))
            print("\t".join([tray, r["layout"], r["masks"], r["scramble"], r["free"], r["blocked"], r["right/step"],
                             r["forced"], r["sums"], r["least read"], r["ghost"], r["triple"], r["cost"]]))


if __name__ == "__main__":
    if sys.argv[1] == "--specs":
        for spec in sorted({s for slots in DEEP.values() for s in slots}, key=lambda s: (s[1], s[0], s[2])):
            print(*spec)
    elif sys.argv[1] == "--thin":
        for spec in sorted({s for slots in DEEP.values() for s in slots}, key=lambda s: (s[1], s[0], s[2])):
            path = f"{sys.argv[2]}/{spec[0]}-{spec[1]}-{spec[2]}.tsv"
            try:
                rows = [r for r in csv.DictReader(open(path), delimiter="\t") if deep_readable(r)]
            except FileNotFoundError:
                continue
            if len(rows) < 3:
                print(*spec)
    elif sys.argv[1] == "--deep":
        deep(sys.argv[2])
    else:
        main(sys.argv[1])
