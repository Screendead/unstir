# Prism: the specimen table

Prism's rule is HANDOFF.md's "4. Prism": each rod carries a channel mask (red, green, blue, cyan, magenta, yellow or
white), shown by its knob's tint, and a stir moves only its channels. Channel c is sampled through the word of entries
whose mask holds c, so two entries commute when their discs miss, when their masks share no channel, or when their maps
commute on every channel they share. Each scramble's bottom entry is white, so no channel is ever clean on its own,
and the win is every channel looking solved. The picture is the fern engraving (`Picture.fern`), white lines that split
into red, green and blue ghosts where the channels disagree.

The design plans 30 specimens in five trays of six: Two Colours, Three Colours, Colour Order, Overprint and Spectrum.
Only the first tray is built. Specimens 1 to 3 are the free taste. The pack is held off the Release shelf
(`Pack.held`) while it is a prototype.

## Rules every row keeps

- No entry merges as it is dealt, so the depth is the string's length (`testPrismLevels`).
- Par is the depth, and it is the solver's optimum (`scripts/solve.sh ... masks=`, `testPrismParIsTheOptimum`): no
  detour beats untwisting, and untwisting on a real `Game` reaches it.
- The bottom entry sits on the one white rod, and that rod holds nothing else.
- Every rod is dealt at least once, so no tinted knob is a decoy.
- The stack keeps four taps under the per-channel shader's assumed cost (`Unstirred.channelCost`: 2, plus 1 per
  channel each entry holds, against `Tank.fourTaps`, 30). That cost is not measured on the phone.

"Free" counts the entries that can come off at the start, under the masks and with every rod read white. The gap
between the two is the lesson: an entry under another colour's stir is not buried.

## Tray 1: Two Colours

Red and cyan rods only, over the white bottom rod. Red and cyan share no channel, so a red and a cyan entry always
commute, overlap or not: each channel's word is untwisted on its own, then the white entry last. The tray teaches the
read (which colour a seam broke, from its ghosts and the knobs' tints) and that colour, not stacking order alone,
decides what is free.

| # | Layout | Masks | Scramble | Depth | Free (masks / white) | Cost | What it adds | Par |
|---|---|---|---|---|---|---|---|---|
| 1 | tri | 0 r, 1 c, 2 w | `2:+3,0:+4,1:-3` | 3 | 2 / 1 | 8 | The whole lesson: the red stir is buried under the cyan one on an overlapping rod, and still comes off first | 3 |
| 2 | quad | 0 r, 1 c, 2 r, 3 w | `3:+3,2:-4,1:+3,0:+5` | 4 | 3 / 1 | 9 | Everything but the white is free at once: read white it is a strict top-down order | 4 |
| 3 | eye | 0 r, 1 c, 2 r, 3 w | `3:+4,0:-3,2:+2,1:+5,0:+3` | 5 | 2 / 1 | 10 | Two red rods that overlap: the red word has an order of its own, the cyan rod is free throughout | 5 |
| 4 | quad | 0 r, 1 r, 2 c, 3 w | `3:-3,0:+3,1:+4,2:-5,0:-2,1:+3` | 6 | 2 / 1 | 11 | A red word of four over two rods, one rod twice; the cyan seam sits under it and is free | 6 |
| 5 | pent | 0 r, 1 r, 2 c, 3 c, 4 w | `4:+3,0:+4,2:-3,1:+2,3:+4,0:-3,2:+5` | 7 | 2 / 2 | 14 | Both channels have words of their own on neighbouring rods, interleaved | 7 |
| 6 | hex | 0 w, 1 r, 2 r, 3 c, 4 c, 5 r, 6 c | `0:+3,1:+4,3:-3,2:-2,5:+2,4:+5,1:+3,6:-4,3:+2` | 9 | 4 / 2 | 17 | The white hub under everything, the ring split three and three; four seams free at once | 9 |

The planning gap is 0 on every row: in Two Colours any untwisting order that keeps each channel's own order wins at
par. The later trays are where order starts to cost moves (Colour Order, where a seam is freed only because the stir
above it is another colour, and the shared channels of Three Colours).

## Still to come

- Trays 2 to 5, 24 specimens, with the remaining engravings (seed heads, a cathedral elevation, a clock movement).
- To-do 61: the per-channel line styles under Differentiate Without Colour, the swatch that shows one channel, and a
  colour-blind simulation of every specimen.
- To-do 60: the per-channel shader's cost measured on the phone, which decides how deep the later trays can go.
