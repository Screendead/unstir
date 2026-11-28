#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
"""Deals Charybdis levels (keys and wards) on seeded scrambles and measures each through `scripts/solve.sh ... keys=`.

usage: scripts/charybdis-levels.py deal <layout> <entries> <seeds> [from=0] [pairs=1] [chain] [twomarks]
           [stirredkeys] [steps=2-8] [gap=0-99] [top=8] [prove=3] [timeout=60]
       scripts/charybdis-levels.py check <layout> <scramble> <ward>:<key>@<mark>,... [timeout=60]
       scripts/charybdis-levels.py table [id...] [timeout=120]

`deal` deals seeds from..from+seeds-1 on its own RNG, never the game's frozen generator. Each seed takes `pairs`
ward/key pairs whose discs don't touch, one ward per key (`chain` makes the second pair's ward the first pair's key;
`twomarks` gives the second pair the first pair's key at another mark; `stirredkeys` deals every key an entry). It
solves each deal in deep mode and keeps it when untwisting without the wards takes exactly its entries (so the keys
alone cost the moves over them), no entry merges under 2 or past 9 steps, the stack stays within 30 and par is over
the entries by `gap`. It prints the kept deals best first (stranded, then the share of forced steps, the moves that
lose par per step, and the fewest first moves), and runs the default and exhaustive modes on the best `prove`.
`check` measures one level in every mode. `table` re-measures Charybdis's levels below (or those named) in deep mode
and in the mode that proved each, and fails if a par has moved. Each run stops at `timeout` seconds."""
import os, random, re, signal, subprocess, sys

RODS = {"quad": 4, "pent": 5, "hex": 7}
MAX_STACK = 30

# id, layout, scramble as it stands after parse, wards, par, the strongest mode that proved it, and where it came from.
LEVELS = [
    ("C1", "quad", "2:+4", "2:0@3", 3, "exhaustive", "the prototype's first level"),
    ("C2", "quad", "0:+5,2:+4", "2:0@-2", 3, "exhaustive", "the prototype's second level"),
    ("C3", "quad", "2:+2,3:+4", "2:0@6,3:1@3", 6, "exhaustive", "deal quad 2 60 pairs=2 steps=2-5, seed 5"),
    ("C4", "pent", "3:+4,2:+3,1:+5", "1:3@2", 5, "exhaustive", "by hand"),
    ("C5", "pent", "0:+2,2:+3", "0:2@-1,2:4@-4", 7, "default",
     "deal pent 2 60 pairs=2 chain steps=2-5, seed 14; exhaustive agrees, 20 s to the optimum and 48 s in all"),
    ("C6", "pent", "0:-7,4:-7,3:-7,0:-3,2:-6,4:+4,1:-2,3:-6", "0:2@3,1:3@2", 11, "deep",
     "deal pent 8 40 pairs=2 stirredkeys steps=2-7, seed 26"),
    ("C7", "hex", "4:-3,2:+4,5:+6,0:+5,4:+5,1:+3,0:+7,2:+3,4:+7,5:-2,4:+5,1:-5,3:-5", "3:1@-5,4:2@-5", 18, "deep",
     "deal hex 13 40 pairs=2 stirredkeys steps=2-7, seed 36"),
    ("C8", "hex", "4:+3,6:-4,3:-3,5:+2,0:-7,4:+2,5:+4,0:-2,5:+7,1:-7,3:+6,2:+6,0:+3,6:+6,3:-3,1:+7,5:-6,0:-2",
     "1:5@2,3:1@-5", 25, "deep", "deal hex 18 40 pairs=2 chain stirredkeys steps=2-7, seed 23"),
    ("C9", "hex", "1:-6,4:-2,3:+3,0:-6,4:+7,6:-6,0:-2,1:-3,5:-5,2:+6,1:-7,3:+2,6:-5,5:+5,4:-7,2:+3,5:+2,0:-5,1:+5,"
     "0:-7,1:-3,0:+5", "4:6@3,5:3@5", 30, "deep", "deal hex 22 30 pairs=2 stirredkeys steps=2-7, seed 11"),
]


def touch(layout, a, b):
    if layout == "hex":
        if 0 in (a, b):
            return True
        return (a - b) % 6 in (1, 5)
    n = RODS[layout]
    return (a - b) % n in (1, n - 1)


def solve(args, timeout):
    # Its own process group, so a timeout also stops the solver solve.sh started.
    p = subprocess.Popen(["scripts/solve.sh", *args], stdout=subprocess.PIPE, text=True, start_new_session=True)
    try:
        return p.communicate(timeout=timeout)[0]
    except subprocess.TimeoutExpired:
        os.killpg(p.pid, signal.SIGKILL)
        p.communicate()
        return None


def measure(layout, scramble, keys, mode, timeout):
    out = solve([layout, scramble, "keys=" + keys] + ([mode] if mode else []), timeout)
    if out is None:
        return {"mode": mode or "default", "timeout": True}
    m = {"mode": mode or "default", "timeout": False}
    e = re.search(r"entries (\d+) on \w+: (\S+);", out)
    m["entries"], m["scramble"] = (int(e.group(1)), e.group(2)) if e else (None, scramble)
    o = re.search(r"optimum (\d+) \(\d+ states, (\d+) ms\)", out)
    if not o:
        m["none"] = True
        return m
    m["par"], m["ms"] = int(o.group(1)), int(o.group(2))
    u = re.search(r"untwisting alone under the wards: (.*)", out).group(1)
    m["untwist"] = "stranded" if u.startswith("stranded") else u
    f = re.search(r"first moves that reach it: (.*) \((\d+) of (\d+) tried\)", out)
    m["firsts"], m["tried"] = f.group(1), int(f.group(3))
    # A count and the same count a whole turn round leave the key on one mark: one idea, counted once.
    m["firsts_n"] = len({(t.split(":")[0], int(t.split(":")[1]) % 12) for t in f.group(1).split(", ")})
    s = re.search(r"forced (\d+) of \d+ steps; (\d+) moves tried along the line lose par", out)
    m["forced"], m["wrong"] = int(s.group(1)), int(s.group(2))
    m["deepest"] = int(re.search(r"deepest stack along the line (\d+)", out).group(1))
    m["line"] = re.search(r"a line: (\S+)", out).group(1)
    return m


def bare(layout, scramble, timeout):
    out = solve([layout, scramble], timeout)
    o = out and re.search(r"^optimum (\d+)", out, re.M)
    return int(o.group(1)) if o else None


def pick_wards(rng, layout, pairs, chain, twomarks):
    knobs = list(range(1, 7)) if layout == "hex" else list(range(RODS[layout]))
    marks = [m for m in range(-5, 7) if m]
    for _ in range(200):
        wards, used_keys = {}, {}
        for i in range(pairs):
            free = [w for w in knobs if w not in wards]
            if chain and i == 1:
                free = [k for k, _ in wards.values() if k not in wards]
            w = rng.choice(free)
            keys = [k for k in knobs if k != w and not touch(layout, w, k)
                    and (twomarks and i == 1 or k not in used_keys)]
            if twomarks and i == 1:
                keys = [k for k in keys if k in used_keys]
            keys = [k for k in keys if not reaches(wards, k, w)]
            if not keys:
                break
            k = rng.choice(keys)
            mark = rng.choice([m for m in marks if m != used_keys.get(k)])
            wards[w], used_keys[k] = (k, mark), mark
        else:
            return wards
    return None


def reaches(wards, start, target):
    """Whether keying `target` by `start` would close a cycle of wards."""
    k = start
    while k in wards:
        k = wards[k][0]
        if k == target:
            return True
    return start == target


def parse_wards(text):
    out = {}
    for item in text.split(","):
        w, rest = item.split(":")
        k, mark = rest.split("@")
        out[int(w)] = (int(k), int(mark))
    return out


def spell(wards):
    return ",".join(f"{w}:{k}@{m}" for w, (k, m) in sorted(wards.items()))


def deal(rng, layout, n, lo, hi, must):
    while True:
        out, last = [], None
        for _ in range(n):
            r = rng.choice([x for x in range(RODS[layout]) if x != last])
            last = r
            out.append((r, rng.choice([-1, 1]) * rng.randint(lo, hi)))
        if must <= {r for r, _ in out}:
            return ",".join(f"{r}:{s:+d}" for r, s in out)


def row(m):
    if m.get("timeout"):
        return f"{m['mode']}: past the timeout"
    if m.get("none"):
        return f"{m['mode']}: no line"
    return (f"{m['mode']}: par {m['par']} ({m['ms']} ms), entries {m['entries']}, untwisting {m['untwist']}, "
            f"forced {m['forced']} of {m['par']}, {m['wrong']} lose par, first moves {len(m['firsts'].split(', '))} of "
            f"{m['tried']} tried, {m['firsts_n']} places ({m['firsts']}), deepest {m['deepest']}\n    line {m['line']}")


def score(m):
    return (m["untwist"] == "stranded", m["forced"] / m["par"], m["wrong"] / m["par"], -m["firsts_n"])


def main(argv):
    opts = dict(a.split("=", 1) for a in argv if "=" in a and ":" not in a)
    flags = {a for a in argv if a in ("chain", "twomarks", "stirredkeys")}
    words = [a for a in argv if a not in flags and a not in {f"{k}={v}" for k, v in opts.items()}]
    timeout = int(opts.get("timeout", 120 if words[:1] == ["table"] else 60))
    if words[:1] == ["check"] and len(words) == 4:
        layout, scramble, keys = words[1:]
        print(f"{layout} {scramble} keys={keys}; without the wards {bare(layout, scramble, timeout)}")
        for mode in ("deep", "", "exhaustive"):
            print(row(measure(layout, scramble, keys, mode, timeout)), flush=True)
        return
    if words[:1] == ["table"]:
        moved, slow = False, False
        for id, layout, scramble, keys, par, proof, source in LEVELS:
            if words[1:] and id not in words[1:]:
                continue
            # Every pointer starts at 0, so a ward whose mark isn't 0 refuses the first try.
            locked = [w for w, (k, mark) in parse_wards(keys).items() if mark % 12]
            print(f"\n{id}: {layout} {scramble} keys={keys}, par {par} by {proof} ({source}); "
                  f"locked as dealt: {', '.join(map(str, locked)) or 'none'}")
            for mode in dict.fromkeys(("deep", proof)):
                m = measure(layout, scramble, keys, "" if mode == "default" else mode, timeout)
                print("  " + row(m), flush=True)
                if mode == proof:
                    slow |= m["timeout"]
                    moved |= not m["timeout"] and m.get("par") != par
        sys.exit("a par has moved" if moved else "a proof ran past the timeout" if slow else 0)
    if words[:1] != ["deal"] or len(words) != 4:
        sys.exit(__doc__)
    layout, n, seeds = words[1], int(words[2]), int(words[3])
    start, pairs = int(opts.get("from", 0)), int(opts.get("pairs", 1))
    lo, hi = map(int, opts.get("steps", "2-8").split("-"))
    gap = tuple(map(int, opts.get("gap", "0-99").split("-")))
    chain, twomarks = "chain" in flags, "twomarks" in flags
    kept = []
    for seed in range(start, start + seeds):
        rng = random.Random(seed)
        wards = pick_wards(rng, layout, pairs, chain, twomarks)
        if wards is None:
            print(f"seed {seed}: no wards fit the rule", flush=True)
            continue
        keys = spell(wards)
        must = set(wards) | ({k for k, _ in wards.values()} if "stirredkeys" in flags else set())
        scramble = deal(rng, layout, n, lo, hi, must)
        m = measure(layout, scramble, keys, "deep", timeout)
        if m.get("timeout") or m.get("none"):
            print(f"seed {seed}: {row(m)}", flush=True)
            continue
        if any(not 2 <= abs(int(t.split(":")[1])) <= 9 for t in m["scramble"].split(",")):
            print(f"seed {seed}: an entry merged under 2 or past 9 steps; dropped", flush=True)
            continue
        b = bare(layout, m["scramble"], timeout)
        if b != m["entries"] or m["deepest"] > MAX_STACK or not gap[0] <= m["par"] - b <= gap[1]:
            print(f"seed {seed}: par {m['par']}, without the wards {b} for {m['entries']} entries, "
                  f"deepest {m['deepest']}; dropped", flush=True)
            continue
        print(f"seed {seed}: par {m['par']} for {m['entries']}, forced {m['forced']}, {m['wrong']} lose par, "
              f"untwisting {m['untwist']}", flush=True)
        kept.append((score(m), seed, keys, m))
    kept.sort(key=lambda k: k[0], reverse=True)
    print(f"\nbest of {len(kept)} kept:")
    for i, (_, seed, keys, m) in enumerate(kept[:int(opts.get("top", 8))]):
        print(f"\nseed {seed}: {layout} {m['scramble']} keys={keys}\n  {row(m)}")
        if i < int(opts.get("prove", 3)):
            for mode in ("", "exhaustive"):
                print("  " + row(measure(layout, m["scramble"], keys, mode, timeout)), flush=True)


if __name__ == "__main__":
    main(sys.argv[1:])
