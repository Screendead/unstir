#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
"""The twist oracle's reader (scripts/twist-oracle.sh runs it; needs numpy and Pillow).

  twist-oracle.py diff <ref dir> <set dir> [pattern]   holds each frame of a set against its reference by the pass rule
  twist-oracle.py control <ref dir> [pattern]          what the rule reads on references made worse on purpose

The pass rule, on the screenshot's own 8-bit values, both frames through the same gamma, inside the box that holds
either frame's lit pixels. A screenshot's bottom HOME rows are left out: the system's home indicator sits there and
comes and goes from shot to shot. A frame passes as `same` or as `alike`; one that does neither is not rejected: it goes to
Jack beside its reference.

same: the frame is the reference's, to within what no eye sees.
  p99.9  the per-channel difference 99.9% of values are within, at most P999 levels of 255
  mean   the mean per-channel difference, at most MEAN levels
  block  the worst 16 x 16 pixel block's mean difference, at most BLOCK levels (a seam or a patch p99.9 leaves out)
  sharp  the frame's gradient energy over the reference's (luma, squared neighbour differences), within SHARP of 1

alike: the frame differs only as the reference's own twins do. Deep in a stir a pixel's filaments are far thinner
than the pixel, and a map moved a hundredth of a pixel draws other values with the same look, so the reference is
shot three times: as it is, and twice with the whole stir drawn NUDGE of a pixel along each axis over the same
picture, down the two diagonals (ref/twin and ref/twin2, UNSTIR_NUDGE). Where the twins are the reference (the map
is the identity, or calm) the frame must be too; where they read as noise against it, the frame may.
  over   the worst block's mean difference past what the rule allows there, FLOOR + SLACK x the most either twin
         differs by in that block or one beside it, at most 0
  tone   the mean signed difference, each channel, at most TONE levels: light lost or gained across the glass
  sharp  as above: under 1 is blur, over is aliasing or noise
  deep   the same ratio over only the blocks where a twin differs by more than DEEP levels, within DEEPSHARP of 1:
         a blur inside the deep stir alone, which the whole frame's ratio dilutes

A sweep's frames (a held turn a small step on) are also read in pairs:
  moves  the frame-to-frame change over the reference's, within MOVES of 1: over it is shimmer, under it is lag
The worst single value (max) is printed and not judged. A case whose reference names a better one (two taps'
four-tap frame) passes if it matches either.
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image

P999, MEAN, BLOCK, SHARP, MOVES = 6, 0.35, 0.8, 0.03, 0.05
FLOOR, SLACK, TONE, DEEP, DEEPSHARP = 0.5, 1.5, 0.35, 3.0, 0.03
HOME = 68


def load(path):
    f = np.asarray(Image.open(path).convert("RGB")).astype(np.int16)
    # A screen is taller than it is wide; the bench's frames are square.
    if f.shape[0] > f.shape[1]:
        f[-HOME:] = 0
    return f


def box(*frames):
    lit = np.zeros(frames[0].shape[:2], bool)
    for f in frames:
        lit |= f.max(axis=2) > 8
    ys, xs = np.where(lit)
    if len(ys) == 0:
        return slice(0, 1), slice(0, 1)
    return slice(ys.min(), ys.max() + 1), slice(xs.min(), xs.max() + 1)


def energy(f, where=None):
    """The frame's gradient energy, over the pixels `where` marks if given."""
    luma = f @ np.array([0.299, 0.587, 0.114])
    down, across = np.diff(luma, axis=0) ** 2, np.diff(luma, axis=1) ** 2
    if where is None:
        return float(down.sum() + across.sum())
    return float((down * where[:-1]).sum() + (across * where[:, :-1]).sum())


def blocks(d):
    """Each 16 x 16 block's mean of d, on two grids half a block apart, so a patch on one grid's lines lies inside
    the other's blocks."""
    flat, out = d.mean(axis=2), []
    for o in (0, 8):
        f = flat[o:, o:]
        h, w = max(f.shape[0] // 16, 1) * 16, max(f.shape[1] // 16, 1) * 16
        f = np.pad(f, ((0, max(h - f.shape[0], 0)), (0, max(w - f.shape[1], 0))))[:h, :w]
        out.append(f.reshape(h // 16, 16, w // 16, 16).mean(axis=(1, 3)))
    return out


def spread(grid):
    """Each block's most among itself and its eight neighbours."""
    p = np.pad(grid, 1, mode="edge")
    h, w = grid.shape
    return np.max([p[i:i + h, j:j + w] for i in range(3) for j in range(3)], axis=0)


def deep(r, twins, b):
    """The pixels of r's blocks where a twin's mean difference is over DEEP levels: the deep stir."""
    most = np.max([blocks(np.abs(r - t[b]))[0] for t in twins], axis=0) > DEEP
    where = np.zeros(r.shape[:2], bool)
    full = np.kron(most, np.ones((16, 16), bool))
    where[:min(full.shape[0], where.shape[0]), :min(full.shape[1], where.shape[1])] = full[:where.shape[0], :where.shape[1]]
    return where


class Reading:
    def __init__(self, ref, got, twins):
        b = box(ref, got, *twins)
        r, g = ref[b], got[b]
        d = np.abs(r - g)
        mine = blocks(d)
        self.max, self.p999, self.mean = int(d.max()), float(np.percentile(d, 99.9)), float(d.mean())
        self.block = max(float(m.max()) for m in mine)
        self.sharp = energy(g) / max(energy(r), 1e-9)
        self.tone = float(np.abs((g - r).mean(axis=(0, 1))).max())
        self.over = self.deep = None
        if twins:
            theirs = [blocks(np.abs(r - t[b])) for t in twins]
            self.over = max(float((m - (FLOOR + SLACK * spread(np.max([t[k] for t in theirs], axis=0)))).max())
                            for k, m in enumerate(mine))
            # Where the twins read as noise the block rule lets a frame differ freely, so sharpness is read again
            # over those blocks alone: a blur only there is lost in the whole frame's.
            where = deep(r, twins, b)
            if where.sum() >= 16 * 256:
                self.deep = energy(g, where) / max(energy(r, where), 1e-9)

    @property
    def verdict(self):
        sharp = abs(self.sharp - 1) <= SHARP
        if self.p999 <= P999 and self.mean <= MEAN and self.block <= BLOCK and sharp:
            return "same"
        if (self.over is not None and self.over <= 0 and self.tone <= TONE and sharp
                and (self.deep is None or abs(self.deep - 1) <= DEEPSHARP)):
            return "alike"
        return "FAIL"


def measure(ref, got, twins=()):
    return None if got is None or ref.shape != got.shape else Reading(ref, got, twins)


def passes(m):
    return m is not None and m.verdict != "FAIL"


def moves(ref_a, ref_b, got_a, got_b):
    b = box(ref_a, ref_b, got_a, got_b)
    return float(np.abs(got_b[b] - got_a[b]).sum()) / max(float(np.abs(ref_b[b] - ref_a[b]).sum()), 1e-9)


def twins_of(ref, name):
    return [load(p) for p in (ref / "twin" / f"{name}.png", ref / "twin2" / f"{name}.png") if p.exists()]


def show(name, m, note=""):
    if m is None:
        print(f"{name:28} missing or another size  FAIL")
        return
    over = "     -" if m.over is None else f"{m.over:6.2f}"
    deep = "     -" if m.deep is None else f"{m.deep:6.3f}"
    print(f"{name:28} max {m.max:3d}  p99.9 {m.p999:6.2f}  mean {m.mean:6.3f}  block {m.block:6.2f}  sharp {m.sharp:6.3f}  "
          f"over {over}  tone {m.tone:5.2f}  deep {deep}  {m.verdict}{note}")


def cases(ref):
    rows = []
    for line in (ref / "cases.tsv").read_text().splitlines():
        name, sweep, better = (line.split("\t") + ["", ""])[:3]
        rows.append((name, sweep, better))
    return rows


def diff(ref, got, pattern):
    failed = 0
    rows = [r for r in cases(ref) if pattern in r[0]]
    frames = {}
    for name, sweep, better in rows:
        r = load(ref / f"{name}.png")
        g = load(got / f"{name}.png") if (got / f"{name}.png").exists() else None
        frames[name] = (r, g)
        m = measure(r, g, twins_of(ref, name))
        note = ""
        if not passes(m) and better and g is not None and (ref / f"{better}.png").exists():
            alt = measure(load(ref / f"{better}.png"), g, twins_of(ref, better))
            if passes(alt):
                m, note = alt, f"  (against {better})"
        show(name, m, note)
        failed += not passes(m)
    by_sweep = {}
    for name, sweep, _ in rows:
        if sweep:
            by_sweep.setdefault(sweep, []).append(name)
    for sweep, names in by_sweep.items():
        for a, b in zip(names, names[1:]):
            (ra, ga), (rb, gb) = frames[a], frames[b]
            if ga is None or gb is None or ga.shape != ra.shape or gb.shape != rb.shape:
                continue
            ratio = moves(ra, rb, ga, gb)
            ok = abs(ratio - 1) <= MOVES
            print(f"{a + ' > ' + b:44} moves {ratio:6.3f}  {'pass' if ok else 'FAIL'}")
            failed += not ok
    print(f"{len(rows)} frames and their sweeps, {failed} failed. same: p99.9 <= {P999}, mean <= {MEAN}, block <= {BLOCK}; "
          f"alike: over <= 0 (block <= {FLOOR} + {SLACK} x the twins'), tone <= {TONE}; deep within {DEEPSHARP} of 1; both: sharp within {SHARP} of 1; "
          f"moves within {MOVES} of 1")
    return 1 if failed else 0


def control(ref, pattern):
    """The same measures on each reference blurred, shifted, dithered, seamed and patched: all should fail but the
    0.02 px drift and the 0.15 px blur, which sit at the rule's edge."""
    from PIL import ImageFilter
    for name, _, _ in cases(ref):
        if pattern not in name:
            continue
        image = Image.open(ref / f"{name}.png").convert("RGB")
        r = np.asarray(image).astype(np.int16)
        twins = twins_of(ref, name)
        rng = np.random.default_rng(1)
        worse = {
            "blur 0.35 px": np.asarray(image.filter(ImageFilter.GaussianBlur(0.35))).astype(np.int16),
            "blur 0.5 px": np.asarray(image.filter(ImageFilter.GaussianBlur(0.5))).astype(np.int16),
            "shift 1 px": np.roll(r, 1, axis=1),
            "noise +-3": np.clip(r + rng.integers(-3, 4, r.shape), 0, 255).astype(np.int16),
        }
        # A seam a pixel wide round a disc a third of the frame across, and a 24 px patch of another frame's pixels.
        ys, xs = np.mgrid[:r.shape[0], :r.shape[1]]
        ring = np.abs(np.hypot(ys - r.shape[0] / 2, xs - r.shape[1] / 2) - r.shape[1] / 6) < 0.5
        for lift in (12, 40):
            seam = r.copy()
            seam[ring] = np.clip(seam[ring] + lift, 0, 255)
            worse[f"seam +{lift}"] = seam
        patch = r.copy()
        cy, cx = r.shape[0] // 2, r.shape[1] // 2
        patch[cy:cy + 24, cx:cx + 24] = r[cy + 40:cy + 64, cx + 40:cx + 64]
        worse["patch 24 px"] = patch
        for d in (0.02, 0.05):
            worse[f"drift {d} px"] = np.rint((1 - d) * r + d * np.roll(r, 1, axis=1)).astype(np.int16)
        worse["blur 0.15 px"] = np.asarray(image.filter(ImageFilter.GaussianBlur(0.15))).astype(np.int16)
        if twins:
            # Blurred only where the stir is deep, where the block rule lets a frame differ.
            where = np.zeros(r.shape[:2], bool)
            b = box(r, *twins)
            where[b] = deep(r[b], twins, b)
            for sigma in (0.35, 0.5):
                soft = np.asarray(image.filter(ImageFilter.GaussianBlur(sigma))).astype(np.int16)
                worse[f"deep blur {sigma} px"] = np.where(where[..., None], soft, r)
        for what, g in worse.items():
            show(f"{name}: {what}", measure(r, g, twins))
    return 0


def main():
    a = sys.argv[1:]
    if len(a) >= 3 and a[0] == "diff":
        return diff(Path(a[1]), Path(a[2]), a[3] if len(a) > 3 else "")
    if len(a) >= 2 and a[0] == "control":
        return control(Path(a[1]), a[2] if len(a) > 2 else "")
    print(__doc__)
    return 2


sys.exit(main())
