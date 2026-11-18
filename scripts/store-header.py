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
    """The tank's disc, bezel included: the first and last lit pixels across and down through the shot's middle."""
    w, h = shot.size
    lit = lambda p: sum(p) > 60
    cy = h // 2
    xs = [x for x in range(w) if lit(shot.getpixel((x, cy)))]
    cx = (xs[0] + xs[-1]) // 2
    ys = [y for y in range(h // 4, 3 * h // 4) if lit(shot.getpixel((cx, y)))]
    return xs[0], ys[0], xs[-1] + 1, ys[-1] + 1


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
