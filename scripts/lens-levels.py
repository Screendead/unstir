#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
"""Lens's levels measured for how hard they are to crack, and dealt to targets, by scripts/lens-table.py's model (a
lens moves only its core, so overlap decides commutation). Every deal it makes keeps lens-table.py's rules: each dealt
lens entry +1 to +3 (from Lens 62, ±1 to ±3, every running sum within ±3 and never 0), each lens netting at most +3
(from 62, within ±3 and not 0) and reached by a twist, no entry merging as it is dealt, every twist
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
                                                    chain, faint, kept, and signs: in, out or mixed, -last for a lens
                                                    entry of two or three dealt last; in if left out), seeded deals
                                                    until `tries` pass scripts/solve.sh at par, the best kept: with
                                                    zoom-outs, most lens entries of two or three steps; then most
                                                    lenses stacked, most entries buried, the twists spread over their
                                                    rods; one TSV line each
       scripts/lens-levels.py nets <first n> <last n>     NN=stack for those levels of docs/lens-tables.md, each lens at
                                                    what it nets as dealt and no twist, for scripts/shots/lens.sh
       scripts/lens-levels.py summary <first n> <last n> [doc]
                                                    docs/lens-tables.md's chapter measures over those levels: lens
                                                    share, buried, stacked, faint twists, lens steps of 2 or 3, zoom
                                                    outs, right moves, forced steps
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


def measure(layout, lenses, deal, out=False):
    rods = lt.LAYOUTS[layout]
    stack, problems = lt.check(layout, lenses, text(deal), 4.0, out)
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


def lens_split(k, signs, rng, tries=200):
    """A lens's `k` entries, bottom first, for a deal that zooms out: each ±1 to ±3, two or three steps twice as likely
    as one, every running sum from the bottom within ±3 and never 0, so no state of the untwist shows the lens past x8
    or x1/8, or plain. `out` deals only zoom-outs; `mixed` either sign."""
    for _ in range(tries):
        split, total = [], 0
        for _ in range(k):
            options = [m * s for s in (1, 2, 2, 3, 3) for m in ((-1,) if signs == "out" else (1, -1))
                       if 0 < abs(total + m * s) <= 3]
            if not options:
                break
            split.append(rng.choice(options))
            total += split[-1]
        if len(split) == k:
            return split
    return None


def deal(layout, lenses, depth, rng, lens_entries=None, max_whole=None, chain=0.0, tries=4000, faint=None, signs="in",
         lens_last=False):
    """A random deal of `depth` entries keeping the rules, or None. `chain` is the chance that each entry must reach the
    one before it, which leaves fewer right moves at each step and fewer stacks for the solver to prove. `lens_entries`
    fixes how many lens entries there are, shared out among the lenses as evenly as it goes, each lens's steps a split
    of what it nets; `faint` is the chance that a twist is of one step. `signs` is `in`, every lens entry a zoom in, as
    Lens 1 to 61 are dealt; `out`, every one a zoom out; or `mixed`, either, some lens holding both (`lens_split`).
    `lens_last` deals a lens entry of two or three steps last, the whole rim the first move reads."""
    rods = lt.LAYOUTS[layout]
    twists = [r for r in range(len(rods)) if r not in lenses]
    # Twist counts each pair allows over a lens: enough rim drag.
    ok = {(l, t): [s for s in range(-5, 6) if s and lt.rim_drag(rods, l, t, s) / lt.PITCH >= 4]
          for l in lenses for t in twists if lt.interacts(rods, lenses, l, t)}
    for _ in range(tries):
        n_lens = lens_entries if lens_entries is not None else rng.randint(len(lenses), min(3 * len(lenses), depth // 2))
        if n_lens > (5 if signs == "mixed" else 3) * len(lenses) or n_lens < len(lenses):
            return None
        order = sorted(lenses)
        rng.shuffle(order)
        counts = {l: n_lens // len(lenses) + (k < n_lens % len(lenses)) for k, l in enumerate(order)}
        steps = {}
        if signs != "in":
            steps = {l: lens_split(k, signs, rng) for l, k in counts.items()}
            if any(v is None for v in steps.values()):
                continue
            if signs == "mixed" and not any(min(v) < 0 < max(v) for v in steps.values()):
                continue
        for l, k in counts.items() if signs == "in" else ():
            # A lens of one or two entries nets +3 where it can, so some entry zooms by two steps or three and the
            # player counts the zoom; three entries can only be +1 each.
            net = 3 if k == 2 else rng.randint(max(k, 2), 3) if k == 1 else rng.randint(k, 3)
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
        if lens_last and not (stack[-1][0] in lenses and abs(stack[-1][1]) > 1):
            continue
        m = measure(layout, lenses, stack, signs != "in")
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
            print(f"{n}\t{layout}\t{fmt(measure(layout, lenses, parse(scramble), n >= lt.OUT))}")
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
        for row in rows:
            n, layout, slots, depth, n_lens, chain, faint, keep = row[:8]
            signs = row[8] if len(row) > 8 else "in"
            if not lo <= int(n) <= hi or n in done:
                continue
            lenses = {int(x) for x in slots.split(",")}
            rng = random.Random(int(n))
            passed, tried, start = [], 0, time.time()
            while len(passed) < int(keep) and tried < 400:
                tried += 1
                found = deal(layout, lenses, int(depth), rng, int(n_lens), chain=float(chain), faint=float(faint),
                             signs=signs.removesuffix("-last"), lens_last=signs.endswith("-last"))
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
                big = sum(abs(st) > 1 for r, st in stack if r in lenses)
                passed.append((((big,) if signs != "in" else ()) + (m["stacked"], m["buried"], spread, -m["right"]), stack, m))
            if not passed:
                print(f"{n}\t{layout}\t{slots}\tnone in {tried}", flush=True)
                continue
            _, stack, m = max(passed, key=lambda p: p[0])
            print(f"{n}\t{layout}\t{slots}\t{fmt(m)}\t{text(stack)}\t{len(passed)} of {tried}, {time.time() - start:.0f} s", flush=True)
    elif mode == "nets":
        lo, hi = int(args[1]), int(args[2])
        seen = set()
        for n, layout, lenses, scramble in table_rows(os.path.join(HERE, "../docs/lens-tables.md")):
            if n in seen:
                break
            seen.add(n)
            if lo <= n <= hi:
                nets = {l: sum(st for r, st in parse(scramble) if r == l) for l in sorted(lenses)}
                print(f"{n:02d}=" + ",".join(f"{l}:{v:+d}" for l, v in nets.items() if v))
    elif mode == "summary":
        lo, hi = int(args[1]), int(args[2])
        path = args[3] if len(args) > 3 else os.path.join(HERE, "../docs/lens-tables.md")
        rows, seen = [], set()
        for n, layout, lenses, scramble in table_rows(path):
            if n in seen:
                break
            seen.add(n)
            if lo <= n <= hi:
                deal_ = parse(scramble)
                m = measure(layout, lenses, deal_, n >= lt.OUT)
                lens_s = [st for r, st in deal_ if r in lenses]
                twist_s = [st for r, st in deal_ if r not in lenses]
                rows.append(dict(share=len(lens_s) / len(deal_), buried=m["buried"] / len(lens_s), stacked=m["stacked"],
                                 faint=sum(abs(t) == 1 for t in twist_s) / len(twist_s),
                                 big=sum(abs(t) > 1 for t in lens_s) / len(lens_s),
                                 out=sum(t < 0 for t in lens_s) / len(lens_s), right=m["right"], forced=m["forced"]))
        keys = ["share", "buried", "stacked", "faint", "big", "out", "right", "forced"]
        print("levels\t" + "\t".join(keys))
        print(f"{lo}-{hi}\t" + "\t".join(f"{sum(r[k] for r in rows) / len(rows):.2f}" for k in keys))
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
