# Prism: the specimen table

Prism's rule is HANDOFF.md's "4. Prism": each rod carries a channel mask (red, green, blue, cyan, magenta, yellow or
white), shown by its knob's tint, and a stir moves only its channels. Channel c is sampled through the word of entries
whose mask holds c, so two entries commute when their discs miss, when their masks share no channel, or when their maps
commute on every channel they share. Each scramble's bottom entry is white, so no channel is ever clean on its own,
and the win is every channel looking solved. Each tray has its own plate (`Engraving.Plate`), white lines that split
into red, green and blue ghosts where the channels disagree.

Prism replaces First Stir as v1's third pack (Jack's call PK1, round 12), every specimen at depth 8 or less: the
prototype read well to depth 7, and at depth 9 the ghosts separated but single lines could no longer be followed. So
the later trays are harder by colour order, not depth. Specimens 1 to 3 are the free taste.

## Rules every row keeps

- No entry merges as it is dealt, so the depth is the string's length, and it is at most 8 (`testPrismLevels`).
- Par is the depth, and it is the solver's optimum (`scripts/prism-levels.sh table`, `testPrismParIsTheOptimum`): no
  detour beats untwisting, and untwisting on a real `Game` reaches it.
- The bottom entry sits on the one white rod, and that rod holds nothing else.
- Every rod is dealt at least once, so no tinted knob is a decoy.
- The stack keeps four taps under the per-channel shader's assumed cost (`Unstirred.channelCost`: 2, plus 1 per
  channel each entry holds, against `Tank.fourTaps`, 30). That cost is not yet measured on the phone.
- Readable: at most 72% of the glass shows ghosts (70% on hex, whose seven discs cover nearly all of it) and at most 8%
  splits three ways, where three colours part and read as mush (the prototype's three-ink shot is 15%).

The columns are `scripts/prism-levels.sh`'s. "Free" counts the entries that can come off at the start under the masks,
then with every rod read white: the gap is the lesson that an entry under another colour's stir is not buried.
"Blocked" counts the knobs whose newest entry would push if turned back first. "Right/step" is the right moves open
per step over the untwist, each taken as equally likely: 1 is a forced read throughout. Trays 2 to 5 come from seeded
searches (`scripts/prism-levels.sh search`, `scripts/prism-levels/pick.py`), each tray's six climbing from its easiest
readable row to its hardest by right moves, blocked knobs and colour-freed entries. The planning gap is 0 throughout:
with no motion, any untwisting order that keeps each channel's own order wins at par.

## Tray 1: Two Colours, on the fern

Red and cyan rods only, over the white bottom rod. Red and cyan share no channel, so a red and a cyan entry always commute, overlap or not: each channel's word is untwisted on its own, then the white entry last. The tray teaches the read (which colour a seam broke, from its ghosts and the knobs' tints) and that colour, not stacking order alone, decides what is free. Specimens 1 to 5 are the prototype's; 6, at depth 9 on hex, read too busy and is redealt at depth 8.

| # | Layout | Masks | Scramble | Depth | Free (masks / white) | Blocked | Right/step | Cost | Ghost | Triple |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | tri | 0 r, 1 c, 2 w | `2:+3,0:+4,1:-3` | 3 | 2 / 1 | 1 | 1.33 | 8 | 57% | 0% |
| 2 | quad | 0 r, 1 c, 2 r, 3 w | `3:+3,2:-4,1:+3,0:+5` | 4 | 3 / 1 | 1 | 1.83 | 9 | 61% | 0% |
| 3 | eye | 0 r, 1 c, 2 r, 3 w | `3:+4,0:-3,2:+2,1:+5,0:+3` | 5 | 2 / 1 | 2 | 1.35 | 10 | 45% | 0% |
| 4 | quad | 0 r, 1 r, 2 c, 3 w | `3:-3,0:+3,1:+4,2:-5,0:-2,1:+3` | 6 | 2 / 1 | 2 | 1.31 | 11 | 60% | 0% |
| 5 | pent | 0 r, 1 r, 2 c, 3 c, 4 w | `4:+3,0:+4,2:-3,1:+2,3:+4,0:-3,2:+5` | 7 | 2 / 2 | 3 | 1.66 | 14 | 67% | 0% |
| 6 | hex | 0 c, 1 c, 2 c, 3 r, 4 r, 5 w, 6 c | `5:-2,1:+5,6:+3,1:-5,4:-5,0:+3,2:-3,3:-4` | 8 | 2 / 1 | 5 | 1.58 | 17 | 69% | 0% |

## Tray 2: Three Colours, on the seed heads

Red, green and blue rods. The primaries share no channel either, so three words untwist side by side, each over the white. Two rods of one primary block each other where they overlap. Tri and eye can't hold three primaries that deal deep enough without merging, so the tray opens on quad and moves to pent.

| # | Layout | Masks | Scramble | Depth | Free (masks / white) | Blocked | Right/step | Cost | Ghost | Triple |
|---|---|---|---|---|---|---|---|---|---|---|
| 7 | quad | 0 b, 1 g, 2 r, 3 w | `3:-4,2:-5,1:-4,0:-3` | 4 | 3 / 1 | 1 | 1.83 | 8 | 61% | 7% |
| 8 | pent | 0 b, 1 g, 2 r, 3 w, 4 r | `3:+3,1:-5,0:+4,4:-4,2:-2` | 5 | 4 / 2 | 1 | 2.33 | 9 | 67% | 8% |
| 9 | pent | 0 r, 1 g, 2 b, 3 w, 4 r | `3:-3,2:+2,1:-2,0:+3,4:+2,0:-2` | 6 | 3 / 1 | 2 | 1.93 | 10 | 67% | 5% |
| 10 | pent | 0 g, 1 g, 2 r, 3 b, 4 w | `4:+4,2:+4,1:+2,0:+2,3:+5,1:+3` | 6 | 3 / 2 | 2 | 1.93 | 10 | 67% | 5% |
| 11 | pent | 0 g, 1 w, 2 b, 3 b, 4 r | `1:-5,2:-4,3:-5,0:+3,2:-5,4:-5,3:+5` | 7 | 3 / 1 | 2 | 1.69 | 11 | 56% | 3% |
| 12 | pent | 0 b, 1 w, 2 r, 3 r, 4 g | `1:+5,2:-2,4:+3,0:+4,3:-2,2:-3,3:-3,2:+4` | 8 | 3 / 2 | 2 | 1.61 | 12 | 67% | 5% |

## Tray 3: Colour Order, on the medusae

Cyan, magenta and yellow rods. Each pair of inks shares one channel (cyan and magenta blue, and so on), so overlapping inks of different colours block each other as rods of one colour do: the order matters again, and only one entry is free at the start on every specimen. The read is which shared channel a ghost belongs to.

| # | Layout | Masks | Scramble | Depth | Free (masks / white) | Blocked | Right/step | Cost | Ghost | Triple |
|---|---|---|---|---|---|---|---|---|---|---|
| 13 | tri | 0 m, 1 c, 2 w | `2:-5,1:+5,0:-4,1:-5` | 4 | 1 / 1 | 2 | 1.00 | 11 | 39% | 8% |
| 14 | quad | 0 w, 1 m, 2 c, 3 y | `0:-5,1:+4,3:-4,2:-2` | 4 | 1 / 1 | 3 | 1.25 | 11 | 61% | 7% |
| 15 | quad | 0 y, 1 w, 2 m, 3 c | `1:-3,2:-3,0:+5,3:+3,2:+5` | 5 | 1 / 1 | 3 | 1.20 | 13 | 60% | 7% |
| 16 | eye | 0 c, 1 w, 2 y, 3 m | `1:+5,0:+5,2:-2,0:-5,3:+5` | 5 | 1 / 1 | 3 | 1.00 | 13 | 41% | 3% |
| 17 | pent | 0 c, 1 c, 2 m, 3 w, 4 y | `3:+3,0:+5,4:+3,0:+3,2:-2,1:+2` | 6 | 1 / 1 | 4 | 1.44 | 15 | 67% | 6% |
| 18 | pent | 0 m, 1 y, 2 c, 3 w, 4 y | `3:+3,2:+5,4:+5,1:+4,0:-3,1:-5,2:-3` | 7 | 1 / 1 | 4 | 1.21 | 17 | 67% | 8% |

## Tray 4: Overprint, on the radiolarians

Primaries and inks together. A primary passes the ink that lacks it (red passes cyan) and blocks the two that hold it, so a knob's tint decides, entry by entry, what it can pass.

| # | Layout | Masks | Scramble | Depth | Free (masks / white) | Blocked | Right/step | Cost | Ghost | Triple |
|---|---|---|---|---|---|---|---|---|---|---|
| 19 | quad | 0 c, 1 b, 2 y, 3 w | `3:-5,2:-2,1:-4,0:+3,1:-3,0:-3` | 6 | 2 / 1 | 2 | 1.51 | 13 | 43% | 0% |
| 20 | eye | 0 w, 1 m, 2 g, 3 b | `0:-2,2:+3,3:+4,1:+3,3:-2,1:-4` | 6 | 2 / 1 | 2 | 1.31 | 12 | 60% | 8% |
| 21 | eye | 0 w, 1 b, 2 y, 3 m | `0:-4,3:+5,1:-2,2:-3,3:+5,1:+3,3:-4` | 7 | 2 / 1 | 2 | 1.28 | 15 | 60% | 8% |
| 22 | pent | 0 c, 1 w, 2 b, 3 m, 4 g | `1:+3,4:-2,0:+2,2:-2,3:+5,4:-5,2:+5` | 7 | 2 / 2 | 3 | 1.66 | 13 | 67% | 8% |
| 23 | pent | 0 m, 1 r, 2 c, 3 b, 4 w | `4:+5,3:+2,0:-5,2:-3,1:+3,0:-5,1:-2,0:+2` | 8 | 2 / 1 | 3 | 1.46 | 16 | 67% | 7% |
| 24 | pent | 0 y, 1 w, 2 g, 3 c, 4 m | `1:-2,4:-5,3:-5,0:+3,2:+3,3:+3,4:+2,3:+2` | 8 | 1 / 1 | 4 | 1.40 | 18 | 55% | 7% |

## Tray 5: Spectrum, on the nautilus

Any mask on any rod: the finale, every rule at once at depth 6 to 8.

| # | Layout | Masks | Scramble | Depth | Free (masks / white) | Blocked | Right/step | Cost | Ghost | Triple |
|---|---|---|---|---|---|---|---|---|---|---|
| 25 | tri | 0 w, 1 m, 2 r | `0:+2,1:+5,2:+3,1:-2,2:-2,1:-3` | 6 | 1 / 1 | 2 | 1.00 | 13 | 35% | 0% |
| 26 | quad | 0 y, 1 c, 2 r, 3 w | `3:+5,2:+4,1:-4,0:-4,1:-4,0:+2,1:-4` | 7 | 2 / 1 | 2 | 1.42 | 16 | 53% | 8% |
| 27 | eye | 0 b, 1 w, 2 m, 3 y | `1:-4,0:+3,2:-2,3:-3,0:+5,2:+3,0:+3` | 7 | 2 / 1 | 2 | 1.28 | 14 | 60% | 8% |
| 28 | eye | 0 w, 1 r, 2 m, 3 b | `0:-3,2:-2,3:-3,1:-5,2:+4,1:+5,2:-2,1:-2` | 8 | 2 / 1 | 2 | 1.25 | 15 | 50% | 5% |
| 29 | pent | 0 c, 1 m, 2 b, 3 y, 4 w | `4:-4,3:+5,0:-3,2:+2,1:+4,2:-3,1:+3,0:-4` | 8 | 2 / 1 | 3 | 1.44 | 17 | 67% | 8% |
| 30 | pent | 0 y, 1 m, 2 r, 3 w, 4 g | `3:-3,2:+2,1:-2,2:-2,0:+3,4:+2,1:+2,0:-2` | 8 | 1 / 1 | 4 | 1.28 | 16 | 40% | 6% |
