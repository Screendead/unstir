#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
"""Picks vortex's 27 levels from pools that scripts/vortex-levels.sh search wrote, one TSV per band, named
<layout>-<depth>-<inversions>.tsv in the directory given (pools.sh there writes them). Each slot takes the lowest seed
that meets it, scanning its bands in order. The top swirl's undo never runs the same way three levels in a row, no two
levels open on the same three stirs (one seed deals the same start at every depth), and the swirl is rarely 240°: at
most a third of a level's swirls, and none before the sixth level, is 8 steps either way. From four stirs on, no more
than two thirds of a level's stirs go one way, so its undos can't be guessed by direction.
Prints the table as TSV."""

import pathlib
import sys

SWIRL = {"triSwirl": 3, "quadSwirl": 4, "eyeSwirl": 4, "pentSwirl": 5, "hexSwirl": 7}
FIELDS = ["seed", "entries", "hidden", "hiddenSwirls", "swirls", "above", "undo", "sizes", "widest", "hub", "optimum",
          "untwisting", "ms", "scramble"]

# (layout, depth, hidden, swirls, entries above the top swirl, least hidden swirls, picture, hub and swirl together)
SLOTS = [
    ("quadSwirl", 2, 0, 1, (0, 0), 0, "glass", None),
    ("quadSwirl", 3, 0, 1, (1, 1), 0, "coral", None),
    ("quadSwirl", 4, 0, 1, (3, 3), 0, "chainmail", None),
    ("quadSwirl", 5, 0, 2, (0, 1), 0, "coral", None),
    ("quadSwirl", 6, 1, 2, (0, 2), 1, "neurons", None),
    ("quadSwirl", 8, 2, 3, (0, 3), 0, "marbling", None),
    ("triSwirl", 5, 1, 2, (0, 2), 0, "glass", None),
    ("triSwirl", 6, 2, 2, (0, 3), 1, "coral", None),
    ("triSwirl", 8, 2, 3, (0, 3), 0, "chainmail", None),
    ("eyeSwirl", 7, 2, 2, (0, 3), 0, "glass", None),
    ("eyeSwirl", 8, 2, 3, (0, 3), 1, "neurons", None),
    ("eyeSwirl", 10, 3, 3, (0, 4), 0, "marbling", None),
    ("eyeSwirl", 12, 4, 4, (0, 4), 1, "chainmail", None),
    ("pentSwirl", 8, 2, 2, (0, 3), 0, "glass", None),
    ("pentSwirl", 10, 3, 3, (0, 4), 0, "neurons", None),
    ("pentSwirl", 12, 3, 3, (0, 4), 1, "chainmail", None),
    ("pentSwirl", 13, 4, 4, (0, 4), 0, "marbling", None),
    ("pentSwirl", 14, 4, 4, (0, 5), 1, "neurons", None),
    ("pentSwirl", 16, 5, 4, (0, 5), 1, "chainmail", None),
    ("pentSwirl", 18, 6, 5, (0, 5), 1, "marbling", None),
    ("hexSwirl", 12, 3, 3, (0, 4), 0, "glass", True),
    ("hexSwirl", 14, 4, 3, (0, 4), 1, "chainmail", None),
    ("hexSwirl", 16, 4, 4, (0, 5), 1, "marbling", None),
    ("hexSwirl", 18, 5, 4, (0, 5), 1, "chainmail", None),
    ("hexSwirl", 20, 6, 5, (0, 6), 1, "glass", None),
    ("hexSwirl", 22, 7, 5, (0, 6), 2, "marbling", None),
    ("hexSwirl", 24, 8, 6, (0, 6), 2, "glass", None),
]


def load(pool, layout, depth):
    rows = []
    for path in sorted(pool.glob(f"{layout}-{depth}-*.tsv"), key=lambda p: int(p.stem.split("-")[2])):
        for line in path.read_text().splitlines():
            row = dict(zip(FIELDS, line.split("\t")))
            row["band"] = path.stem
            rows.append(row)
    return rows


def spread(row, layout):
    """With three swirls or more, one in the stack's bottom third and one in its top third."""
    rods = [int(t.split(":")[0]) for t in row["scramble"].split(",")]
    at = [i for i, r in enumerate(rods) if r == SWIRL[layout]]
    n = len(rods)
    return len(at) < 3 or (min(at) < n / 3 and max(at) >= n - n / 3)


def sizes_ok(row, i):
    sizes = [abs(int(n)) for n in row["sizes"].split()]
    if sizes.count(8) > (0 if i < 5 else len(sizes) // 3):
        return False
    steps = [int(t.split(":")[1]) for t in row["scramble"].split(",")]
    ahead = sum(1 for n in steps if n > 0)
    return len(steps) < 4 or max(ahead, len(steps) - ahead) * 3 <= 2 * len(steps)


def main():
    pool = pathlib.Path(sys.argv[1])
    picked, undos = [], []
    for i, (layout, depth, hidden, swirls, above, hidden_swirls, picture, hub) in enumerate(SLOTS):
        if i == 0:
            rows = [dict(zip(FIELDS, ["-", "2", "0", "0", "1", "0", "-", "+4", "1", ".", "2", "2", "0", "0:+3,4:+4"]),
                         band="fixed")]
        else:
            rows = load(pool, layout, depth)
        for row in rows:
            if (int(row["hidden"]), int(row["swirls"])) != (hidden, swirls):
                continue
            if not above[0] <= int(row["above"]) <= above[1] or int(row["hiddenSwirls"]) < hidden_swirls:
                continue
            if hub is not None and (row["hub"] == "hub") != hub:
                continue
            if len(undos) >= 2 and undos[-1] == undos[-2] == row["undo"]:
                continue
            if not spread(row, layout) or not sizes_ok(row, i):
                continue
            start = row["scramble"].split(",")[:3]
            if any(p["layout"] == layout and p["scramble"].split(",")[:3] == start for p in picked):
                continue
            row.update(layout=layout, picture=picture)
            picked.append(row)
            undos.append(row["undo"])
            break
        else:
            sys.exit(f"V{i + 1}: no row meets {SLOTS[i]}")
    print("\t".join(["level", "layout", "picture", "band"] + FIELDS))
    for i, row in enumerate(picked):
        print("\t".join([f"V{i + 1}", row["layout"], row["picture"], row["band"]] + [row[f] for f in FIELDS]))


main()
