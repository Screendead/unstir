#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
"""Lens's levels measured for how hard they are to crack, and dealt to targets, by scripts/lens-table.py's model (a
lens moves only its core, so overlap decides commutation). Every deal it makes keeps lens-table.py's rules: each dealt
lens entry +1 to +3, each lens netting at most +3 and reached by a twist, no entry merging as it is dealt, every twist
dealt over a lens dragging its rim at least 4 dot pitches.
Measures, per level:
  rods      the layout's rods, every one a candidate for the next move
  depth     the entries, par
  lensE     lens entries; buried: those dealt under a twist that reaches the lens (a broken rim)
  stacked   lenses holding two or more entries, so the zoom shows their sum and the first undo leaves a zoom behind
  faint     entries of one step (a +1 lens, a twist of 1), the least a step shows
  whole     entries whole as dealt, the right moves on the first step
  right     right moves per step, averaged over the untwist, each right move at each step taken as equally likely
  forced    the share of steps with only one right move, likewise expected
  drag      the least rim drag of a twist dealt over a lens, in dot pitches
Usage: scripts/lens-levels.py table [doc]          a row per level of a doc's table (docs/lens-tables.md)
       scripts/lens-levels.py deal <layout> <lens slots> <depth> <seed> [count] [--lens-entries n] [--max-whole n]
                                                    seeded deals meeting the rules, measured, one TSV line each
       scripts/lens-levels.py pick <spec.tsv> [first n] [last n]
                                                    for each spec row (n, layout, lens slots, depth, lens entries,
                                                    chain, faint), seeded deals until `tries` pass scripts/solve.sh
                                                    at par, the best kept: most lenses stacked, most entries buried,
                                                    the twists spread over their rods; one TSV line each
       scripts/lens-levels.py time <layout> <lens slots> <depth>...
                                                    one deal at each depth through scripts/solve.sh, timed"""
import importlib.util
import math
import os
import random
import re
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("lens_table", os.path.join(HERE, "lens-table.py"))
lt = importlib.util.module_from_spec(spec)
spec.loader.exec_module(lt)


def parse(s):
    return [(int(r), int(v)) for r, v in (e.split(":") for e in s.split(","))]


def text(deal):
    return ",".join(f"{r}:{s:+d}" for r, s in deal)


def whole(rods, lenses, stack, alive):
    """Indices of alive entries with no alive entry above interacting with their rod."""
    out = []
    for i in alive:
        if all(not lt.interacts(rods, lenses, stack[i][0], stack[j][0]) for j in alive if j > i):
            out.append(i)
    return out


def expected(rods, lenses, stack, samples=400, seed=1):
    """Mean right moves per step and the share of forced steps over the untwist, exact by memo while the states stay
    few, else sampled."""
    memo = {}
    limit = 200_000

    def go(alive):
        if not alive:
            return 0.0, 0.0
        if alive in memo:
            return memo[alive]
        if len(memo) > limit:
            raise OverflowError
        w = whole(rods, lenses, stack, alive)
        right, forced = float(len(w)), 1.0 if len(w) == 1 else 0.0
        sr = sf = 0.0
        for i in w:
            a, b = go(tuple(j for j in alive if j != i))
            sr += a
            sf += b
        memo[alive] = (right + sr / len(w), forced + sf / len(w))
        return memo[alive]

    n = len(stack)
    try:
        r, f = go(tuple(range(n)))
        return r / n, f / n
    except OverflowError:
        rng = random.Random(seed)
        tr = tf = 0.0
        for _ in range(samples):
            alive = list(range(n))
            while alive:
                w = whole(rods, lenses, stack, alive)
                tr += len(w)
                tf += len(w) == 1
                alive.remove(rng.choice(w))
        return tr / (samples * n), tf / (samples * n)


def measure(layout, lenses, deal):
    rods = lt.LAYOUTS[layout]
    stack, problems = lt.check(layout, lenses, text(deal), 4.0)
    lens_e = [i for i, (r, _) in enumerate(stack) if r in lenses]
    buried = sum(any(stack[j][0] not in lenses and lt.interacts(rods, lenses, stack[i][0], stack[j][0])
                     for j in range(i + 1, len(stack))) for i in lens_e)
    stacked = sum(sum(r == l for r, _ in stack) > 1 for l in lenses)
    faint = sum(abs(s) == 1 for _, s in stack)
    w = len(whole(rods, lenses, stack, tuple(range(len(stack)))))
    right, forced = expected(rods, lenses, stack)
    drags = [lt.rim_drag(rods, stack[i][0], t, s) / lt.PITCH for i in lens_e for t, s in stack[i + 1:]
             if t not in lenses and lt.interacts(rods, lenses, stack[i][0], t)]
    return dict(rods=len(rods), depth=len(stack), lensE=len(lens_e), buried=buried, stacked=stacked, faint=faint,
                whole=w, right=right, forced=forced, drag=min(drags) if drags else float("nan"), problems=problems)


COLUMNS = ["rods", "depth", "lensE", "buried", "stacked", "faint", "whole", "right", "forced", "drag"]


def fmt(m):
    return "\t".join(f"{m[c]:.2f}" if isinstance(m[c], float) else str(m[c]) for c in COLUMNS)


def deal(layout, lenses, depth, rng, lens_entries=None, max_whole=None, chain=0.0, tries=4000, faint=None):
    """A random deal of `depth` entries keeping the rules, or None. `chain` is the chance that each entry must reach the
    one before it, which leaves fewer right moves at each step and fewer stacks for the solver to prove. `lens_entries`
    fixes how many lens entries there are, shared out among the lenses as evenly as it goes, each lens's steps a split
    of what it nets; `faint` is the chance that a twist is of one step."""
    rods = lt.LAYOUTS[layout]
    twists = [r for r in range(len(rods)) if r not in lenses]
    # Twist counts each pair allows over a lens: enough rim drag.
    ok = {(l, t): [s for s in range(-5, 6) if s and lt.rim_drag(rods, l, t, s) / lt.PITCH >= 4]
          for l in lenses for t in twists if lt.interacts(rods, lenses, l, t)}
    for _ in range(tries):
        n_lens = lens_entries if lens_entries is not None else rng.randint(len(lenses), min(3 * len(lenses), depth // 2))
        if n_lens > 3 * len(lenses) or n_lens < len(lenses):
            return None
        order = sorted(lenses)
        rng.shuffle(order)
        counts = {l: n_lens // len(lenses) + (k < n_lens % len(lenses)) for k, l in enumerate(order)}
        steps = {}
        for l, k in counts.items():
            net = rng.randint(k, 3)
            split = [1] * k
            for _ in range(net - k):
                split[rng.randrange(k)] += 1
            rng.shuffle(split)
            steps[l] = split
        # Lens entries never reach each other, so a chain keeps a twist between any two.
        n_twist = depth - n_lens
        if chain >= 1 and n_lens > n_twist + 1:
            return None
        if chain >= 1:
            gaps = set(rng.sample(range(n_twist + 1), n_lens))
            kinds = []
            for g in range(n_twist + 1):
                kinds += [True] * (g in gaps) + [False] * (g < n_twist)
        else:
            kinds = [True] * n_lens + [False] * n_twist
            rng.shuffle(kinds)
        stack = []
        for k in range(depth):
            options = []
            for r in range(len(rods)):
                if (r in lenses) != kinds[k]:
                    continue
                newest = max((i for i, e in enumerate(stack) if e[0] == r), default=None)
                if newest is not None and all(not lt.interacts(rods, lenses, r, e[0]) for e in stack[newest + 1:]):
                    continue
                if r in lenses:
                    if steps[r]:
                        options.append((r, steps[r][0]))
                else:
                    under = {e[0] for e in stack if e[0] in lenses and lt.interacts(rods, lenses, e[0], r)}
                    counts_ok = [s for s in range(-5, 6) if s and all(s in ok[(l, r)] for l in under)]
                    if faint is not None and counts_ok:
                        ones = [s for s in counts_ok if abs(s) == 1]
                        if ones and rng.random() < faint:
                            counts_ok = ones
                        else:
                            counts_ok = [s for s in counts_ok if abs(s) > 1] or counts_ok
                    options += [(r, s) for s in counts_ok]
            if stack and rng.random() < chain:
                linked = [o for o in options if lt.interacts(rods, lenses, o[0], stack[-1][0])]
                options = linked
            if not options:
                break
            r, s = rng.choice(options)
            stack.append((r, s))
            if r in lenses:
                steps[r].pop(0)
        if len(stack) < depth:
            continue
        m = measure(layout, lenses, stack)
        if m["problems"] or m["depth"] != depth:
            continue
        if max_whole is not None and m["whole"] > max_whole:
            continue
        return stack, m
    return None


def solve(layout, lenses, scramble, limit=None, *extra):
    """solve.sh's output and its time; empty past `limit` seconds."""
    t = time.time()
    run = subprocess.Popen([os.path.join(HERE, "solve.sh"), layout, scramble, "lenses=" + ",".join(map(str, sorted(lenses))), *extra],
                           stdout=subprocess.PIPE, text=True, start_new_session=True)
    try:
        out = run.communicate(timeout=limit)[0]
    except subprocess.TimeoutExpired:
        os.killpg(run.pid, 9)
        run.wait()
        out = ""
    return out, time.time() - t


def table_rows(path):
    for line in open(path, encoding="utf-8"):
        cells = [c.strip().strip("`") for c in line.strip().strip("|").split("|")]
        if len(cells) < 5 or not cells[0].isdigit() or cells[2] not in lt.LAYOUTS:
            continue
        yield int(cells[0]), cells[2], {int(x) for x in re.findall(r"\d+", cells[3])}, cells[4]


def main():
    args = sys.argv[1:]
    mode = args[0] if args else "table"
    if mode == "table":
        path = args[1] if len(args) > 1 else os.path.join(HERE, "../docs/lens-tables.md")
        print("#\tlayout\t" + "\t".join(COLUMNS))
        seen = set()
        for n, layout, lenses, scramble in table_rows(path):
            if n in seen:
                break
            seen.add(n)
            print(f"{n}\t{layout}\t{fmt(measure(layout, lenses, parse(scramble)))}")
    elif mode == "deal":
        layout, lenses, depth, seed = args[1], {int(x) for x in args[2].split(",")}, int(args[3]), int(args[4])
        count = int(args[5]) if len(args) > 5 and args[5].isdigit() else 1
        opt = lambda k: int(args[args.index(k) + 1]) if k in args else None
        rng = random.Random(seed)
        for _ in range(count):
            found = deal(layout, lenses, depth, rng, opt("--lens-entries"), opt("--max-whole"),
                         float(args[args.index("--chain") + 1]) if "--chain" in args else 0.0)
            if found:
                print(f"{layout}\t{args[2]}\t{fmt(found[1])}\t{text(found[0])}")
    elif mode == "pick":
        rows = [l.rstrip("\n").split("\t") for l in open(args[1]) if l.strip() and not l.startswith("#")]
        lo = int(args[2]) if len(args) > 2 else 0
        hi = int(args[3]) if len(args) > 3 else 10 ** 9
        done = {l.split("\t")[0] for l in open(os.path.join(HERE, "lens-levels/picked.tsv"))} if "PICKED" in os.environ else set()
        for n, layout, slots, depth, n_lens, chain, faint, keep in rows:
            if not lo <= int(n) <= hi or n in done:
                continue
            lenses = {int(x) for x in slots.split(",")}
            rng = random.Random(int(n))
            passed, tried, start = [], 0, time.time()
            while len(passed) < int(keep) and tried < 400:
                tried += 1
                found = deal(layout, lenses, int(depth), rng, int(n_lens), chain=float(chain), faint=float(faint))
                if not found:
                    continue
                stack, m = found
                # Most deals that miss par miss it because untwists join, which a fraction of the proof's time shows.
                quick, _ = solve(layout, lenses, text(stack), None, "untwisting")
                if f"entries {len(stack)}\nuntwisting {len(stack)}" not in quick:
                    continue
                out, _ = solve(layout, lenses, text(stack), limit=int(os.environ.get("PROOF_LIMIT", "60")))
                entries = re.search(r"^entries (\d+)", out, re.M)
                opt = re.search(r"^optimum (\d+)", out, re.M)
                if not entries or not opt or int(entries.group(1)) != len(stack) or int(opt.group(1)) != len(stack):
                    continue
                uses = [sum(r == t for r, _ in stack) for t in range(len(lt.LAYOUTS[layout])) if t not in lenses]
                spread = min(uses) / max(uses)
                passed.append(((m["stacked"], m["buried"], spread, -m["right"]), stack, m))
            if not passed:
                print(f"{n}\t{layout}\t{slots}\tnone in {tried}", flush=True)
                continue
            _, stack, m = max(passed, key=lambda p: p[0])
            print(f"{n}\t{layout}\t{slots}\t{fmt(m)}\t{text(stack)}\t{len(passed)} of {tried}, {time.time() - start:.0f} s", flush=True)
    elif mode == "time":
        layout, lenses = args[1], {int(x) for x in args[2].split(",")}
        for depth in map(int, args[3:]):
            found = deal(layout, lenses, depth, random.Random(depth), chain=float(os.environ.get("CHAIN", "0")),
                         lens_entries=int(os.environ["LENS"]) if "LENS" in os.environ else None)
            if not found:
                print(f"{depth}: no deal")
                continue
            out, took = solve(layout, lenses, text(found[0]))
            opt = re.search(r"^optimum .*$", out, re.M)
            stacks = re.search(r"^(\d+) stacks, ([\d.]+) ms", out, re.M)
            print(f"depth {depth}: right {found[1]['right']:.2f}; {opt and opt.group(0)}; {stacks and stacks.group(0)}; wall {took:.1f} s", flush=True)
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
