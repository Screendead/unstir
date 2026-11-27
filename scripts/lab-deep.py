#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
"""Deals deep levels for the fifth chapter's candidate rules and proves each with `scripts/solve.sh lab ... deep`.

usage: scripts/lab-deep.py <layout> <entries> <rule> <seeds> [balanced]
  rule: flip, keel=n, or keys=w:k@m,... ; `balanced` deals steps summing to 0, as the keel needs.
Prints, per seed, the optimum with and without the rule, the steps forced, and the deal, best first. Its own seeded
deals, never the frozen generator's."""
import random, re, subprocess, sys

layout, n, rule, seeds = sys.argv[1], int(sys.argv[2]), sys.argv[3], int(sys.argv[4])
balanced = "balanced" in sys.argv[5:]
rods = {"tri": 3, "quad": 4, "eye": 4, "pent": 5, "hex": 7}[layout]
rows = []
for seed in range(seeds):
    rng = random.Random(seed)
    while True:
        deal, last = [], None
        for _ in range(n):
            r = rng.choice([x for x in range(rods) if x != last]); last = r
            deal.append([r, rng.choice([-1, 1]) * rng.randint(2, 8)])
        if not balanced:
            break
        total = sum(s for _, s in deal)
        deal[-1][1] -= total
        if 2 <= abs(deal[-1][1]) <= 8:
            break
    text = ",".join(f"{r}:{s:+d}" for r, s in deal)
    try:
        out = subprocess.run(["scripts/solve.sh", "lab", layout, text, rule, "deep"], capture_output=True, text=True,
                             timeout=120).stdout
    except subprocess.TimeoutExpired:
        print(f"seed {seed}: past 120 s", flush=True)
        continue
    found = re.findall(r"optimum (\d+) \(\d+ states, (\d+) ms\); (\d+) of \d+ steps forced", out)
    entries = re.search(r"entries (\d+)", out)
    if len(found) == 2:
        (bare, _, _), (opt, ms, forced) = found
        rows.append((int(opt) - int(bare), int(forced), int(opt), int(bare), int(entries.group(1)), int(ms), seed, text))
        print(f"seed {seed}: {opt} against {bare}, {forced} forced, {ms} ms", flush=True)
    else:
        print(f"seed {seed}: " + " / ".join(l for l in out.splitlines() if l.startswith("with")), flush=True)
for row in sorted(rows, reverse=True)[:5]:
    print("gap %d forced %d optimum %d bare %d entries %d %d ms seed %d %s" % row)
