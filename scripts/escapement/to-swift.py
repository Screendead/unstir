#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
"""Prints Pack.swift's `problem(...)` lines for book rows, from problems.tsv and a titles file.

Usage: scripts/escapement/to-swift.py <problems.tsv> <titles.txt> <first> <last>

titles.txt holds one title a line, the first for problem <first>. Each row's par is what its slowest clock owes, read
off the scramble, so the line states what the prover proved.
"""
import sys

rows = {int(r.split("\t")[0]): r.rstrip("\n").split("\t") for r in open(sys.argv[1]) if r.strip()}
titles = [t.strip() for t in open(sys.argv[2]) if t.strip()]
first, last = int(sys.argv[3]), int(sys.argv[4])
for n in range(first, last + 1):
    _, layout, clocks, scramble = rows[n]
    cl = [(int(c[:-1]), c[-1]) for c in clocks.split(",")]
    owed = {}
    for e in scramble.split(","):
        rod, steps = e.split(":")
        owed[int(rod)] = owed.get(int(rod), 0) + int(steps)
    par = max(max(0, -(1 if d == "+" else -1) * owed.get(r, 0)) for r, d in cl)
    back = [r for r, d in cl if d == "-"]
    title = titles[n - first]
    pad = " " * (len(str(n)) - 1)
    print(f'        problem({n}, String(localized: "level.escapement-{n}.title", defaultValue: "{title}",')
    print(f'                {pad}          comment: "Escapement level title, a part of a clock or a word for time"),')
    args = f'.{layout}, "{scramble}", clocks: [{", ".join(str(r) for r, _ in cl)}]'
    if back:
        args += f', back: [{", ".join(map(str, back))}]'
    print(f'                {args}, par: {par}),')
