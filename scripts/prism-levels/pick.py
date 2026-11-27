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


# Trays 6 to 15 (the pack trebled, Jack, 2026-11-27): depth climbs from 8 to 16, by (layout, depth, palette), from pools
# dealt no rod more than three stirs (PRISM_ROD_CAP=3, the first five trays' most): a rod stirred more often shows only
# the sum of its stirs, its decoys reading nearly as strongly as its count, so its moves become guesses. That caps pent
# at 13 (four coloured rods) and hex at 19, and the solver's proofs on hex past 16 run to many minutes each. A palette of
# one primary and its ink (rc, gm, by) moves only two of the three channels' words, so it never splits three ways however
# deep; the mixed ones (rgb, rcgb, rgbcmy) buy colour order at the cost of mush.
DEEP = {
    "t6": [("quad", 8, "gm"), ("pent", 9, "by"), ("pent", 9, "gm"), ("pent", 10, "by"), ("hex", 10, "gm"), ("hex", 11, "by")],
    "t7": [("pent", 9, "rgb"), ("pent", 10, "rgb"), ("hex", 10, "rc"), ("pent", 11, "rgb"), ("hex", 11, "rgb"), ("hex", 12, "rc")],
    "t8": [("pent", 10, "rc"), ("pent", 11, "by"), ("hex", 11, "gm"), ("hex", 12, "by"), ("hex", 12, "gm"), ("hex", 12, "rc")],
    "t9": [("pent", 11, "cmy"), ("pent", 11, "rgbcmy"), ("pent", 12, "rgbcmy"), ("hex", 12, "rgbcmy"), ("pent", 12, "cmy"),
           ("hex", 13, "cmy")],
    "t10": [("hex", 12, "rc"), ("pent", 12, "rcgb"), ("hex", 13, "by"), ("pent", 13, "rgbcmy"), ("hex", 13, "gm"),
            ("hex", 13, "rcgb")],
    "t11": [("pent", 13, "gm"), ("hex", 13, "rc"), ("hex", 14, "by"), ("pent", 13, "rcgb"), ("hex", 14, "rgb"), ("hex", 14, "gm")],
    "t12": [("hex", 13, "gm"), ("pent", 13, "by"), ("hex", 14, "rc"), ("hex", 14, "by"), ("hex", 15, "rcgb"), ("hex", 15, "gm")],
    "t13": [("pent", 13, "rc"), ("hex", 14, "rc"), ("hex", 15, "by"), ("hex", 15, "gm"), ("hex", 15, "rc"), ("hex", 16, "by")],
    "t14": [("hex", 14, "gm"), ("hex", 15, "rc"), ("hex", 15, "by"), ("hex", 16, "gm"), ("hex", 16, "rc"), ("hex", 16, "by")],
    "t15": [("hex", 15, "gm"), ("hex", 16, "rc"), ("hex", 16, "gm"), ("hex", 16, "by"), ("hex", 16, "rc"), ("hex", 16, "gm")],
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
    return (pct(r["ghost"]) <= 75 and pct(r["triple"]) <= 25 and int(r["cost"]) <= 30 and least != "-"
            and float(least) >= 0.5 and int(r.get("most", 99)) <= 3)


def hardness(r):
    # Fewer right moves a step, more knobs that push if turned first, more forced steps. Moves read as a sum are the
    # depth less the rods, the same for every row of a pool, so they count for nothing here.
    return -float(r["right/step"]) + 0.35 * int(r["blocked"]) + 0.1 * float(r["forced"])


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
