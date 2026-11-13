#!/usr/bin/env python3
# Copyright © 2026 Jack Lusher. All rights reserved.
"""The App Store's captions (docs/store-page.md), drawn with Pillow: this ffmpeg has no drawtext.

  store-captions.py screens <shots dir> <out dir>   each store-NN-*.png as the store takes it (RGB, no alpha), and
                                                     captioned: the caption over the screen shrunk under it
  store-captions.py film <text> <out.png>           a caption for the preview, transparent, at the screen's size
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

# The App Store's 6.9-inch size, the Pro Max simulator's own.
W, H = 1320, 2868
FONT = "/System/Library/Fonts/SFNSMono.ttf"  # the app's monospaced face (Font.mono is .monospaced)

# Placeholder look, for Jack's call (the UI design pass sets the real type): every number here is a draft.
STYLE = {
    "band": 470,         # the screenshot's caption band, from the top; the screen shrinks into the rest
    "size": 58,          # the screenshot's caption, px at 1320 wide
    "weight": b"Medium",
    "ink": (242, 244, 250),
    "paid": (150, 154, 168),  # "Paid pack ·", quieter than the caption
    "film_y": 600,       # the film caption's centre, px down the 1320 x 2868 screen: the black over the tank
    "film_size": 54,
}

# docs/store-page.md's set, verbatim. A pack's shot is labelled as a paid add-on (guideline 2.3.2, assumed).
CAPTIONS = {
    "01": "Rods under the glass stirred this picture.",
    "02": "Turn a knob back. The newest seam goes first.",
    "03": "Get the order right and it snaps clean.",
    "04": "Vortex: one swirl as wide as the glass.",
    "05": "Maelstrom: knobs seize. Turn the whole tank.",
    "06": "A new daily every day, the same for everyone.",
    "07": "Endless: waste a stir and the brim rises.",
    "08": "Paid pack · Prism: three colours, one line",
    "09": "Paid pack · Lens: rods that zoom",
    "10": "Paid pack · Escapement: a clock in every problem",
}
PAID = "Paid pack · "


def font(size):
    f = ImageFont.truetype(FONT, size)
    f.set_variation_by_name(STYLE["weight"])
    return f


def lines(text, f, width):
    """Breaks at spaces into lines no wider than width, the paid label kept on a line of its own."""
    out = []
    if text.startswith(PAID):
        out.append(PAID.strip(" ·"))
        text = text[len(PAID):]
    words, line = text.split(), ""
    for w in words:
        trial = f"{line} {w}".strip()
        if line and f.getlength(trial) > width:
            out.append(line)
            line = w
        else:
            line = trial
    out.append(line)
    # Two lines of near even width rather than a word left hanging.
    rest = out[1:] if out[0] == PAID.strip(" ·") else out
    if len(rest) == 2:
        cuts = [(" ".join(words[:i]), " ".join(words[i:])) for i in range(1, len(words))]
        rest[:] = min(cuts, key=lambda c: max(f.getlength(c[0]), f.getlength(c[1])))
        out = out[:len(out) - 2] + rest
    return out


def draw_centred(d, text, f, cy, width, paid_first):
    ls = lines(text, f, width)
    step = f.size * 1.35
    y = cy - step * len(ls) / 2
    for i, l in enumerate(ls):
        ink = STYLE["paid"] if paid_first and i == 0 else STYLE["ink"]
        d.text((W / 2, y + step / 2), l, font=f, fill=ink, anchor="mm")
        y += step


def screens(src, out):
    out.mkdir(parents=True, exist_ok=True)
    f = font(STYLE["size"])
    for path in sorted(src.glob("store-[0-9][0-9]-*.png")):
        n = path.stem.split("-")[1]
        shot = Image.open(path).convert("RGB")
        assert shot.size == (W, H), f"{path.name} is {shot.size}, not {W} x {H}"
        name = path.stem.removeprefix("store-")
        shot.save(out / f"{name}.png")
        page = Image.new("RGB", (W, H), "black")
        band = STYLE["band"]
        scale = (H - band) / H
        small = shot.resize((round(W * scale), H - band), Image.LANCZOS)
        page.paste(small, ((W - small.width) // 2, band))
        text = CAPTIONS[n]
        draw_centred(ImageDraw.Draw(page), text, f, band / 2 + 20, W - 160, text.startswith(PAID))
        page.save(out / f"{name}-captioned.png")
        print(f"{name}: {text}")


def film(text, out):
    page = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw_centred(ImageDraw.Draw(page), text, font(STYLE["film_size"]), STYLE["film_y"], W - 200, False)
    page.save(out)


if __name__ == "__main__":
    if len(sys.argv) == 4 and sys.argv[1] == "screens":
        screens(Path(sys.argv[2]), Path(sys.argv[3]))
    elif len(sys.argv) == 4 and sys.argv[1] == "film":
        film(sys.argv[2], Path(sys.argv[3]))
    else:
        sys.exit(__doc__)
