#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
"""Usage: scripts/store-header.py <backdrop.png> <shot.png> <out dir>

Composes the App Store's product page header (21:9, 3840 x 1646), search results asset (3:2, 3840 x 2560) and
universal asset (16:9, 5244 x 2950), each a PNG without alpha, from a picture the picture lab rendered past the
universal canvas's diagonal (`picture-lab.sh render cords <png> 7 0 6100`) and a play shot whose tank it cuts out
(`shots.sh vortex-family-cords-03`). In each the tank sits whole in that placement's art safe area, over the picture
unstirred, softened and dimmed. Apple doesn't say how it crops the universal asset into the other two, so each placement
gets its own; `check-*.png` outline each safe area. Specs: App Store Connect Help, "Creative assets specifications",
read 2026-11-18. Needs Pillow.
"""
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

# Each placement's canvas and art safe area (left, top, width, height).
PLACEMENTS = {
    "universal": ((5244, 2950), (1921, 660, 1402, 962)),
    "header": ((3840, 1646), (1097, 493, 1646, 661)),
    "search": ((3840, 2560), (836, 765, 2168, 1030)),
}


def tank_bounds(shot):
    """The tank's disc, bezel included, as a square box. The column centres the tank across the shot, so each row's lit
    pixels nearest either edge give its chord where they sit symmetrically about the middle; the disc is the circle,
    centred across, whose chords best match the rows' over its height. Its top and bottom are found from the fit, not
    scanned for, as lit chrome above or below the bezel (the title, the caption) would join it."""
    w, h = shot.size
    grey = shot.convert("L")
    px = grey.load()
    half = [None] * h
    for y in range(h):
        left = next((x for x in range(w) if px[x, y] > 20), None)
        if left is None:
            continue
        right = next(x for x in range(w - 1, -1, -1) if px[x, y] > 20)
        if abs(left + right + 1 - w) <= 4:
            half[y] = (right + 1 - left) / 2
    best = None
    for cy in range(h):
        r = half[cy]
        if r is None or r < w / 4:
            continue
        span = int(r * 0.95)
        if cy - span < 0 or cy + span >= h:
            continue
        rows = range(cy - span, cy + span + 1, 4)
        hits = sum(1 for y in rows if half[y] is not None and abs(half[y] ** 2 + (y - cy) ** 2 - r * r) <= 6 * r)
        score = hits / len(rows)
        if best is None or (score, r) > (best[0], best[2]):
            best = (score, cy, r)
    if best is None or best[0] < 0.9:
        sys.exit(f"no tank found in the shot (best fit {best and round(best[0], 2)}): is it a play shot?")
    # Refine over every row the fit matched: on the circle, half² + y² = 2·cy·y + (r² − cy²), a line in y.
    _, cy, r = best
    ys = [y for y in range(h) if half[y] is not None and abs(half[y] ** 2 + (y - cy) ** 2 - r * r) <= 6 * r]
    zs = [half[y] ** 2 + y * y for y in ys]
    my, mz = sum(ys) / len(ys), sum(zs) / len(zs)
    slope = sum((y - my) * (z - mz) for y, z in zip(ys, zs)) / sum((y - my) ** 2 for y in ys)
    cy = slope / 2
    r = (mz - slope * my + cy * cy) ** 0.5
    return round(w / 2 - r), round(cy - r), round(w / 2 + r), round(cy + r)


def compose(backdrop, tank, size, safe):
    W, H = size
    sx, sy, sw, sh = safe
    bw, bh = backdrop.size
    # The backdrop at one scale for every placement, so the cords are as wide in each.
    back = backdrop.crop(((bw - W) // 2, (bh - H) // 2, (bw + W) // 2, (bh + H) // 2))
    back = back.filter(ImageFilter.GaussianBlur(14))
    back = Image.eval(back, lambda v: int(v * 0.42))

    # Darker toward the edges, so the glass reads first.
    cx, cy = sx + sw // 2, sy + sh // 2
    small = Image.new("L", (W // 8, H // 8), 0)
    d = ImageDraw.Draw(small)
    for i in range(60):
        f = 1 - i / 60
        rx, ry = W / 16 * (0.4 + 1.2 * f), H / 16 * (0.4 + 1.6 * f)
        d.ellipse((cx / 8 - rx, cy / 8 - ry, cx / 8 + rx, cy / 8 + ry), fill=int(255 * (0.35 + 0.65 * (1 - f))))
    shade = small.resize((W, H), Image.BICUBIC).filter(ImageFilter.GaussianBlur(40))
    back = ImageChops.multiply(back, Image.merge("RGB", [shade] * 3))

    side = min(sw, sh) - 40
    mask = Image.new("L", (tank.width * 4, tank.height * 4), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, mask.width - 1, mask.height - 1), fill=255)
    glass = tank.resize((side, side), Image.LANCZOS)
    mask = mask.resize((side, side), Image.LANCZOS)

    # A soft black halo lifts the glass off the backdrop.
    halo = Image.new("L", (W, H), 0)
    hx, hy = cx - side // 2, cy - side // 2
    ImageDraw.Draw(halo).ellipse((hx - 30, hy - 10, hx + side + 30, hy + side + 50), fill=200)
    halo = halo.filter(ImageFilter.GaussianBlur(60))
    back = Image.composite(Image.new("RGB", (W, H), 0), back, halo)
    back.paste(glass, (hx, hy), mask)
    return back


def main(backdrop_path, shot_path, out):
    out = Path(out)
    out.mkdir(parents=True, exist_ok=True)
    Image.MAX_IMAGE_PIXELS = None
    backdrop = Image.open(backdrop_path).convert("RGB")
    shot = Image.open(shot_path).convert("RGB")
    tank = shot.crop(tank_bounds(shot))
    for name, (size, safe) in PLACEMENTS.items():
        image = compose(backdrop, tank, size, safe)
        image.save(out / f"{name}.png", optimize=True)
        sx, sy, sw, sh = safe
        ImageDraw.Draw(image).rectangle((sx, sy, sx + sw, sy + sh), outline=(255, 0, 0), width=6)
        image.save(out / f"check-{name}.png")


if __name__ == "__main__":
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    main(*sys.argv[1:])
