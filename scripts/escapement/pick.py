#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
"""Picks Escapement problems from measured pools (scripts/escapement/pools.sh) for a plan of slots.

Usage: scripts/escapement/pick.py <pool dir> <plan.tsv> [first number]

Each plan row is: pool name (its file stem), par, `teach` or `hard`, and optionally `wait` (a line with a wait), `decoy` (one at least) or a
number, the most entries for that slot (MAX_ENTRIES unless given). A `hard` slot takes the deal whose hardness
is greatest: bits, decoys and how far a decoy runs before every move loses, which a player only sees by looking ahead;
a `teach` slot, a chapter's opener, the least. Every slot keeps to the four-tap budget's entries (MAX_ENTRIES) and no
seed is taken twice on one layout and set of clocks, as a seed dealt at more moves deals the same problem deeper. Prints book rows (number, layout, clocks, scramble) and, to stderr, each pick's measures.
"""
import os
import sys

MAX_ENTRIES = 34


def pool(path):
    with open(path) as f:
        rows = [line.rstrip("\n").split("\t") for line in f if not line.startswith("#")]
    scrambles = {}
    with open(path.replace(".measure.tsv", ".tsv")) as f:
        for line in f:
            seed, _, _, scramble = line.rstrip("\n").split("\t")
            scrambles[seed] = scramble
    out = []
    for r in rows:
        if len(r) < 15:
            continue
        seed, layout, clocks, par, ticks, entries, waits, lines, miss, forced, decoys, losses, reach, bits, line = r
        out.append(dict(seed=seed, layout=layout, clocks=clocks, par=int(par), ticks=int(ticks), entries=int(entries),
                        waits=int(waits), lines=int(lines), decoys=int(decoys), reach=int(reach), bits=float(bits),
                        line=line, scramble=scrambles[seed]))
    return out


def hardness(d):
    return d["bits"] + 0.5 * d["decoys"] + 0.5 * d["reach"]


def main():
    root, plan = sys.argv[1], sys.argv[2]
    n = int(sys.argv[3]) if len(sys.argv) > 3 else 31
    taken = set()
    for row in open(plan):
        if not row.strip() or row.startswith("#"):
            continue
        name, par, kind, *more = row.split()
        wait, decoy = "wait" in more, "decoy" in more
        most = next((int(m) for m in more if m.isdigit()), MAX_ENTRIES)
        deals = [d for d in pool(os.path.join(root, name + ".measure.tsv"))
                 if d["par"] == int(par) and d["entries"] <= most and (d["layout"], d["clocks"].replace("-", "+"), d["seed"]) not in taken
                 and (not wait or d["waits"] > 0) and (not decoy or d["decoys"] > 0)]
        if not deals:
            sys.exit(f"no deal for {row.strip()}")
        d = (min if kind == "teach" else max)(deals, key=hardness)
        taken.add((d["layout"], d["clocks"].replace("-", "+"), d["seed"]))
        print(f'{n}\t{d["layout"]}\t{d["clocks"]}\t{d["scramble"]}')
        print(f'{n}\t{name}\tseed {d["seed"]}\tpar {d["par"]}\tticks {d["ticks"]}\tentries {d["entries"]}\twaits {d["waits"]}'
              f'\tdecoys {d["decoys"]}\treach {d["reach"]}\tbits {d["bits"]}\t{d["line"]}', file=sys.stderr)
        n += 1


main()
