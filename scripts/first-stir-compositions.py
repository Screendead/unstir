#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/first-stir-compositions.py   Draws rough composition plans for three of docs/first-stir-outline.md's
# scenes as shots/first-stir-composition-<n>.png, and all three side by side as shots/first-stir-compositions.png: the
# tank, each rod's disc and core, the part of each core another disc reaches (tinted), the knobs, the scene's main
# lines and where each vignette sits. Plans, not the art. Needs Pillow.
import math
import os
from PIL import Image, ImageDraw, ImageFont

SIDE = 900
R = SIDE * 0.45
C = SIDE / 2
PLATEAU = 0.6
KNOB = 0.07


def ring(n, r, radius, a0=-90):
    return [(r * math.cos(math.radians(a0 + 360 * k / n)), r * math.sin(math.radians(a0 + 360 * k / n)), radius)
            for k in range(n)]


# Layout.table in Sources/Twist.swift: (x, y, disc radius), tank radius 1, y down.
LAYOUTS = {
    "tri": ring(3, 0.42, 0.58),
    "quad": ring(4, 0.5, 0.48, -45),
    "eye": [(-0.4, 0, 0.58), (0.4, 0, 0.58), (0, -0.56, 0.44), (0, 0.56, 0.44)],
    "pent": ring(5, 0.56, 0.44),
}

# Each scene: its layout, horizon (None indoors), polylines of its main shapes, and vignettes as (letter, rod, dx, dy,
# label), placed by an offset from the rod's centre in tank units.
SCENES = {
    1: ("Sunrise", "tri", 0.0, [
        [(-0.27, 0.03), (0.28, 0.03)],
        [(-0.10, -0.025), (-0.062, -0.51), (0.062, -0.51), (0.10, -0.025)],
        [(0.20, 0.30), (0.62, 0.30), (0.55, 0.38), (0.26, 0.38), (0.20, 0.30)],
        [(0.40, 0.30), (0.40, 0.02)],
        [(-0.62, 0.42), (-0.62, 0.16), (-0.42, 0.04), (-0.22, 0.16), (-0.22, 0.42)],
        [(-0.95, 0.42), (0.95, 0.42)],
    ], [("A", 0, 0.0, -0.17, "lantern: boarded / ladder, first plank"),
        ("B", 1, 0.03, 0.17, "boat: bailed, mast up / father bailing"),
        ("C", 2, -0.03, 0.17, "door: shut, smoke / sweeping the step")]),
    12: ("High Street Under Water", "pent", -0.05, [
        [(-0.95, 0.12), (0.95, 0.12)],
        [(-0.10, -0.72), (-0.10, -0.40), (0.10, -0.40), (0.10, -0.72), (0.0, -0.82), (-0.10, -0.72)],
        [(-0.80, 0.12), (-0.80, -0.30), (-0.45, -0.45), (-0.10, -0.30)],
        [(0.10, -0.30), (0.45, -0.45), (0.80, -0.30), (0.80, 0.12)],
        [(0.33, 0.62), (0.33, 0.25), (0.42, 0.25)],
    ], [("A", 0, 0.0, -0.16, "town clock: 2:05 / 1:40"),
        ("B", 2, 0.0, -0.16, "street lamp: drowned / lit, sparking"),
        ("C", 3, 0.0, 0.16, "dinghy: rowing, rope / tied up, empty")]),
    14: ("The Kitchen, Flooded", "eye", None, [
        [(-0.95, 0.10), (0.95, 0.10)],
        [(-0.62, 0.0), (-0.22, 0.0)],
        [(-0.58, 0.0), (-0.58, 0.28)], [(-0.26, 0.0), (-0.26, 0.28)],
        [(0.20, 0.30), (0.30, 0.18), (0.40, 0.06), (0.50, -0.06), (0.60, -0.18), (0.70, -0.30)],
        [(-0.20, 0.80), (-0.20, 0.35), (0.20, 0.35), (0.20, 0.80)],
    ], [("A", 0, -0.04, -0.17, "table: cup floats off / cup on table"),
        ("B", 1, 0.12, -0.14, "stair: boots on top step / child carrying dog"),
        ("C", 3, -0.15, 0.05, "float: to the door / caught on chair leg")]),
}

SKY = {1: (0x2B3550, 0xF2B48C), 12: (0x05050F, 0x0B2238), 14: (0x05050F, 0x0B2238)}
LINE = {1: 0x9AA8C8, 12: 0x2CD5C4, 14: 0x2CD5C4}


def rgb(h):
    return (h >> 16 & 255, h >> 8 & 255, h & 255)


def px(x, y):
    return (C + x * R, C + y * R)


def font(size):
    for path in ("/System/Library/Fonts/Menlo.ttc", "/System/Library/Fonts/Supplemental/Courier New.ttf"):
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def plan(n):
    title, layout, horizon, lines, vignettes = SCENES[n]
    rods = LAYOUTS[layout]
    img = Image.new("RGB", (SIDE, SIDE + 200), (0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    top, bottom = SKY[n]
    for row in range(int(C - R), int(C + R)):
        y = (row - C) / R
        if horizon is not None and y > horizon:
            col = tuple(int(c * (1 - (y - horizon) / (1 - horizon)) * 0.25) for c in rgb(0x7D8FA6))
        else:
            t = (y + 1) / 2 if horizon is None else (y + 1) / (horizon + 1)
            col = tuple(int(a + (b - a) * t) for a, b in zip(rgb(top), rgb(bottom)))
        half = math.sqrt(max(0, 1 - y * y)) * R
        d.line([(C - half, row), (C + half, row)], fill=col)
    if horizon is not None:
        half = math.sqrt(1 - horizon * horizon)
        d.line([px(-half, horizon), px(half, horizon)], fill=rgb(0x2CD5C4), width=2)
    for pts in lines:
        d.line([px(*p) for p in pts], fill=rgb(LINE[n]) + (210,), width=3, joint="curve")
    # The part of each core another disc reaches, tinted point by point.
    step = 4
    for k, (x, y, r) in enumerate(rods):
        core = PLATEAU * r
        for i in range(int(-core * R), int(core * R), step):
            for j in range(int(-core * R), int(core * R), step):
                u, v = x + i / R, y + j / R
                if (u - x) ** 2 + (v - y) ** 2 > core * core:
                    continue
                if any(m != k and (u - a) ** 2 + (v - b) ** 2 < rr * rr for m, (a, b, rr) in enumerate(rods)):
                    d.rectangle([px(u, v), (px(u, v)[0] + step - 1, px(u, v)[1] + step - 1)], fill=(255, 70, 90, 70))
    for x, y, r in rods:
        d.ellipse([px(x - r, y - r), px(x + r, y + r)], outline=(160, 170, 190, 120), width=1)
        core = PLATEAU * r
        d.ellipse([px(x - core, y - core), px(x + core, y + core)], outline=(230, 235, 245, 220), width=2)
        d.ellipse([px(x - KNOB, y - KNOB), px(x + KNOB, y + KNOB)], fill=(60, 64, 74, 255), outline=(30, 213, 196))
    d.ellipse([C - R, C - R, C + R, C + R], outline=(200, 200, 210), width=3)
    small, big = font(20), font(30)
    for letter, rod, dx, dy, _ in vignettes:
        x, y, _ = rods[rod]
        cx, cy = px(x + dx, y + dy)
        d.ellipse([cx - 26, cy - 26, cx + 26, cy + 26], fill=(255, 201, 74, 230))
        d.text((cx, cy), letter, fill=(0, 0, 0), font=big, anchor="mm")
    d.text((24, SIDE + 6), f"{n}. {title} ({layout})", fill=(255, 255, 255), font=big)
    for i, (letter, rod, _, _, label) in enumerate(vignettes):
        d.text((24, SIDE + 50 + 34 * i), f"{letter}  rod {rod}: {label}", fill=(220, 220, 230),
               font=small)
    d.text((24, SIDE + 152), "held back / played; tinted: core another disc reaches", fill=(255, 120, 135), font=small)
    return img


def main():
    root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "shots")
    os.makedirs(root, exist_ok=True)
    plans = [plan(n) for n in sorted(SCENES)]
    for n, img in zip(sorted(SCENES), plans):
        img.save(os.path.join(root, f"first-stir-composition-{n}.png"))
    sheet = Image.new("RGB", (sum(p.width for p in plans) + 20 * (len(plans) - 1), plans[0].height), (0, 0, 0))
    x = 0
    for p in plans:
        sheet.paste(p, (x, 0))
        x += p.width + 20
    sheet.save(os.path.join(root, "first-stir-compositions.png"))


if __name__ == "__main__":
    main()
