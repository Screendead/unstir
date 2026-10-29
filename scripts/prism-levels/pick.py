#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
"""Picks Prism's specimen 6 and trays 2 to 5's specimens from pools of `scripts/prism-levels.sh search` TSVs.

usage: scripts/prism-levels/pick.py <pool dir>

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


if __name__ == "__main__":
    main(sys.argv[1])
