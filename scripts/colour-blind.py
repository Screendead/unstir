#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
"""Simulates protanopia, deuteranopia and tritanopia on screenshots (Machado, Oliveira and Fernandes 2009, severity 1,
applied in linear sRGB) and lays each shot out beside its three simulations.

usage: scripts/colour-blind.py <out.png> <shot.png>... [--crop x0,y0,x1,y1 in fractions of the shot]
"""
import sys

import numpy as np
from PIL import Image, ImageDraw

MATRICES = {
    "protanopia": [[0.152286, 1.052583, -0.204868], [0.114503, 0.786281, 0.099216], [-0.003882, -0.048116, 1.051998]],
    "deuteranopia": [[0.367322, 0.860646, -0.227968], [0.280085, 0.672501, 0.047413], [-0.011820, 0.042940, 0.968881]],
    "tritanopia": [[1.255528, -0.076749, -0.178779], [-0.078411, 0.930809, 0.147602], [0.004733, 0.691367, 0.303900]],
}


def linear(c):
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def encoded(c):
    c = np.clip(c, 0, 1)
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * c ** (1 / 2.4) - 0.055)


def simulate(image, matrix):
    rgb = linear(np.asarray(image.convert("RGB"), dtype=np.float64) / 255)
    out = encoded(rgb @ np.array(matrix).T)
    return Image.fromarray((out * 255 + 0.5).astype(np.uint8))


def main(argv):
    crop = None
    if "--crop" in argv:
        i = argv.index("--crop")
        crop = [float(v) for v in argv[i + 1].split(",")]
        argv = argv[:i] + argv[i + 2:]
    out, shots = argv[0], argv[1:]
    rows = []
    for path in shots:
        im = Image.open(path).convert("RGB")
        if crop:
            w, h = im.size
            im = im.crop((int(crop[0] * w), int(crop[1] * h), int(crop[2] * w), int(crop[3] * h)))
        im.thumbnail((520, 520))
        rows.append([("normal", im)] + [(name, simulate(im, m)) for name, m in MATRICES.items()])
    w, h = rows[0][0][1].size
    sheet = Image.new("RGB", (4 * w + 50, len(rows) * (h + 30) + 10), "black")
    draw = ImageDraw.Draw(sheet)
    for r, row in enumerate(rows):
        for c, (name, im) in enumerate(row):
            x, y = 10 + c * (w + 10), 10 + r * (h + 30)
            sheet.paste(im, (x, y + 20))
            draw.text((x, y), f"{shots[r].split('/')[-1]} · {name}", fill="white")
    sheet.save(out)


if __name__ == "__main__":
    main(sys.argv[1:])
