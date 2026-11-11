#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
"""Usage: scripts/escapement/nowait-book.py [seeds] > scripts/escapement/problems-nowait.tsv

The problem book under the no-wait rule (ESC_WAIT=0): every row of problems.tsv whose line holds no wait stands as it
is, and each of the others is dealt again on its own layout, clocks and par by `escapement.sh build` as a line of whole
heals. A slot takes the deal that measures hardest: most bits, then most heals on its line that would miss par, then
a key under the newest seam, then most knobs turned, then the depth nearest the problem it replaces. Every deal has
one line of whole heals and as many seams on working knobs as its clocks owe ticks, so a turn that takes no seam off
whole leaves more seams than moves. `escapement.sh check` then searches every turn of up to six steps for a second
line or key, for LIMIT seconds of processor time: a deal it finds one for is passed over, and one it can't finish is
kept as "unfinished", for `escapement.sh book` to prove. Seeded, so a rerun deals the same book; what it picked goes
to stderr.
"""
import os
import resource
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PROVER = os.path.join(ROOT, "scripts/escapement.sh")
ENV = dict(os.environ, ESC_WAIT="0")
LIMIT = 40


def run(*args, inside=None):
    env = dict(ENV, ESC_INSIDE=inside) if inside else ENV
    return subprocess.run([PROVER, *args], env=env, capture_output=True, text=True, check=True).stdout.splitlines()


def needs_wait(layout, clocks, scramble):
    out = run("check", layout, scramble, clocks, "6", "quick")
    return any(line.startswith("owed") and "unsolvable" in line for line in out)


def pool(layout, clocks, par, depth, seeds):
    deals = {}
    for inside in ("0.3", "0.6", "0.9"):
        for row in run("build", layout, clocks, str(par), "0-0", "1", str(seeds), inside=inside):
            f = row.split("\t")
            if len(f) == 13 and f[8] == "1" and int(f[5]) == par:
                knobs = len({m.split(":")[0] for m in f[12].split()})
                deals.setdefault(f[11], (float(f[10]), int(f[1]), f[0] == "under", knobs, -abs(int(f[6]) - depth),
                                         inside, f[4], f[12]))
    return sorted(deals.items(), key=lambda d: d[1][:5], reverse=True)


def proof(layout, clocks, scramble):
    """"proved", "refuted", or "unfinished" within LIMIT."""
    done = subprocess.run([PROVER, "check", layout, scramble, clocks, "6"], env=ENV, capture_output=True, text=True,
                          preexec_fn=lambda: resource.setrlimit(resource.RLIMIT_CPU, (LIMIT, LIMIT)))
    out = done.stdout.splitlines()
    lines = [line for line in out if line.startswith("lines at")]
    keys = [line for line in out if line.startswith("keys at")]
    if not keys or not any(line.startswith("chance at par") for line in out):
        return "unfinished"
    one = (lines[0].endswith(": 1") and len(keys[0].split(": ")[1].split()) == 1
           and any(line.startswith("none shorter, absolute") for line in out))
    return "proved" if one else "refuted"


def main():
    seeds = int(sys.argv[1]) if len(sys.argv) > 1 else 20000
    taken = set()
    for row in open(os.path.join(ROOT, "scripts/escapement/problems.tsv")).read().splitlines():
        n, layout, clocks, scramble = row.split("\t")
        if not needs_wait(layout, clocks, scramble):
            print(row, flush=True)
            continue
        par = max(int(line.split()[1]) for line in run("check", layout, scramble, clocks, "6", "quick")
                  if line.startswith("owed"))
        depth = scramble.count(",") + 1
        for deal, (bits, traps, _, knobs, _, inside, seed, line) in pool(layout, clocks, par, depth, seeds):
            if deal in taken:
                continue
            found = proof(layout, clocks, deal)
            if found == "refuted":
                continue
            taken.add(deal)
            print("\t".join([n, layout, clocks, deal]), flush=True)
            print(f"{n}\t{layout}\t{clocks}\tpar {par}\tbits {bits}\ttraps {traps}\tknobs {knobs}\t"
                  f"entries {deal.count(',') + 1}\tinside {inside}\tseed {seed}\t{found}\t{line}", file=sys.stderr,
                  flush=True)
            break
        else:
            sys.exit(f"no deal for {n}: {layout} {clocks} par {par}")


if __name__ == "__main__":
    main()
