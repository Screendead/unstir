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

Jack trebled the pack on 2026-11-27: "At least treble the number of levels, and make them ramp up slightly faster in
difficulty, to a much higher maximum difficulty." Specimens 31 to 90 are ten more trays of six, each on its own new
plate, deeper tray by tray: depth 8 to 11 in tray 6, 15 to 16 in tray 15, a tray's mean rising 0.7 a tray against the
first five's half, to twice the old maximum. Past depth 8 lifts PK1's cap for those trays only, which goes back to
Jack with the shots. The section "The treble: trays 6 to 15" below has their rules, measures and tables.

## Rules every row keeps

- No entry merges as it is dealt, so the depth is the string's length, and it is at most 8 (`testPrismLevels`).
- Par is the depth, and it is the solver's optimum (`scripts/prism-levels.sh table`, `testPrismParIsTheOptimum`): no
  detour beats untwisting, and untwisting on a real `Game` reaches it.
- The bottom entry sits on the one white rod, and that rod holds nothing else, except in six specimens of trays 13 to
  15, which bury a second white stir mid-stack ("A buried white stir" below).
- Every rod is dealt at least once, so no tinted knob is a decoy.
- The stack keeps four taps under the per-channel shader's assumed cost (`Unstirred.channelCost`: 3, plus 1 per
  channel each entry holds, against `Tank.fourTaps`, 30). The constant was 2 until the phone bench of 2026-11-09
  (thermal fair) measured five specimens up to 7% over it; 3 covers every one, rounded up.
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
| 1 | tri | 0 r, 1 c, 2 w | `2:+3,0:+4,1:-3` | 3 | 2 / 1 | 1 | 1.33 | 9 | 57% | 0% |
| 2 | quad | 0 r, 1 c, 2 r, 3 w | `3:+3,2:-4,1:+3,0:+5` | 4 | 3 / 1 | 1 | 1.83 | 10 | 61% | 0% |
| 3 | eye | 0 r, 1 c, 2 r, 3 w | `3:+4,0:-3,2:+2,1:+5,0:+3` | 5 | 2 / 1 | 2 | 1.35 | 11 | 45% | 0% |
| 4 | quad | 0 r, 1 r, 2 c, 3 w | `3:-3,0:+3,1:+4,2:-5,0:-2,1:+3` | 6 | 2 / 1 | 2 | 1.31 | 12 | 60% | 0% |
| 5 | pent | 0 r, 1 r, 2 c, 3 c, 4 w | `4:+3,0:+4,2:-3,1:+2,3:+4,0:-3,2:+5` | 7 | 2 / 2 | 3 | 1.66 | 15 | 67% | 0% |
| 6 | hex | 0 c, 1 c, 2 c, 3 r, 4 r, 5 w, 6 c | `5:-2,1:+5,6:+3,1:-5,4:-5,0:+3,2:-3,3:-4` | 8 | 2 / 1 | 5 | 1.58 | 18 | 69% | 0% |

## Tray 2: Three Colours, on the seed heads

Red, green and blue rods. The primaries share no channel either, so three words untwist side by side, each over the white. Two rods of one primary block each other where they overlap. Tri and eye can't hold three primaries that deal deep enough without merging, so the tray opens on quad and moves to pent.

| # | Layout | Masks | Scramble | Depth | Free (masks / white) | Blocked | Right/step | Cost | Ghost | Triple |
|---|---|---|---|---|---|---|---|---|---|---|
| 7 | quad | 0 b, 1 g, 2 r, 3 w | `3:-4,2:-5,1:-4,0:-3` | 4 | 3 / 1 | 1 | 1.83 | 9 | 61% | 7% |
| 8 | pent | 0 b, 1 g, 2 r, 3 w, 4 r | `3:+3,1:-5,0:+4,4:-4,2:-2` | 5 | 4 / 2 | 1 | 2.33 | 10 | 67% | 8% |
| 9 | pent | 0 r, 1 g, 2 b, 3 w, 4 r | `3:-3,2:+2,1:-2,0:+3,4:+2,0:-2` | 6 | 3 / 1 | 2 | 1.93 | 11 | 67% | 5% |
| 10 | pent | 0 g, 1 g, 2 r, 3 b, 4 w | `4:+4,2:+4,1:+2,0:+2,3:+5,1:+3` | 6 | 3 / 2 | 2 | 1.93 | 11 | 67% | 5% |
| 11 | pent | 0 g, 1 w, 2 b, 3 b, 4 r | `1:-5,2:-4,3:-5,0:+3,2:-5,4:-5,3:+5` | 7 | 3 / 1 | 2 | 1.69 | 12 | 56% | 3% |
| 12 | pent | 0 b, 1 w, 2 r, 3 r, 4 g | `1:+5,2:-2,4:+3,0:+4,3:-2,2:-3,3:-3,2:+4` | 8 | 3 / 2 | 2 | 1.61 | 13 | 67% | 5% |

## Tray 3: Colour Order, on the medusae

Cyan, magenta and yellow rods. Each pair of inks shares one channel (cyan and magenta blue, and so on), so overlapping inks of different colours block each other as rods of one colour do: the order matters again, and only one entry is free at the start on every specimen. The read is which shared channel a ghost belongs to.

| # | Layout | Masks | Scramble | Depth | Free (masks / white) | Blocked | Right/step | Cost | Ghost | Triple |
|---|---|---|---|---|---|---|---|---|---|---|
| 13 | tri | 0 m, 1 c, 2 w | `2:-5,1:+5,0:-4,1:-5` | 4 | 1 / 1 | 2 | 1.00 | 12 | 39% | 8% |
| 14 | quad | 0 w, 1 m, 2 c, 3 y | `0:-5,1:+4,3:-4,2:-2` | 4 | 1 / 1 | 3 | 1.25 | 12 | 61% | 7% |
| 15 | quad | 0 y, 1 w, 2 m, 3 c | `1:-3,2:-3,0:+5,3:+3,2:+5` | 5 | 1 / 1 | 3 | 1.20 | 14 | 60% | 7% |
| 16 | eye | 0 c, 1 w, 2 y, 3 m | `1:+5,0:+5,2:-2,0:-5,3:+5` | 5 | 1 / 1 | 3 | 1.00 | 14 | 41% | 3% |
| 17 | pent | 0 c, 1 c, 2 m, 3 w, 4 y | `3:+3,0:+5,4:+3,0:+3,2:-2,1:+2` | 6 | 1 / 1 | 4 | 1.44 | 16 | 67% | 6% |
| 18 | pent | 0 m, 1 y, 2 c, 3 w, 4 y | `3:+3,2:+5,4:+5,1:+4,0:-3,1:-5,2:-3` | 7 | 1 / 1 | 4 | 1.21 | 18 | 67% | 8% |

## Tray 4: Overprint, on the radiolarians

Primaries and inks together. A primary passes the ink that lacks it (red passes cyan) and blocks the two that hold it, so a knob's tint decides, entry by entry, what it can pass.

| # | Layout | Masks | Scramble | Depth | Free (masks / white) | Blocked | Right/step | Cost | Ghost | Triple |
|---|---|---|---|---|---|---|---|---|---|---|
| 19 | quad | 0 c, 1 b, 2 y, 3 w | `3:-5,2:-2,1:-4,0:+3,1:-3,0:-3` | 6 | 2 / 1 | 2 | 1.51 | 14 | 43% | 0% |
| 20 | eye | 0 w, 1 m, 2 g, 3 b | `0:-2,2:+3,3:+4,1:+3,3:-2,1:-4` | 6 | 2 / 1 | 2 | 1.31 | 13 | 60% | 8% |
| 21 | eye | 0 w, 1 b, 2 y, 3 m | `0:-4,3:+5,1:-2,2:-3,3:+5,1:+3,3:-4` | 7 | 2 / 1 | 2 | 1.28 | 16 | 60% | 8% |
| 22 | pent | 0 c, 1 w, 2 b, 3 m, 4 g | `1:+3,4:-2,0:+2,2:-2,3:+5,4:-5,2:+5` | 7 | 2 / 2 | 3 | 1.66 | 14 | 67% | 8% |
| 23 | pent | 0 m, 1 r, 2 c, 3 b, 4 w | `4:+5,3:+2,0:-5,2:-3,1:+3,0:-5,1:-2,0:+2` | 8 | 2 / 1 | 3 | 1.46 | 17 | 67% | 7% |
| 24 | pent | 0 y, 1 w, 2 g, 3 c, 4 m | `1:-2,4:-5,3:-5,0:+3,2:+3,3:+3,4:+2,3:+2` | 8 | 1 / 1 | 4 | 1.40 | 19 | 55% | 7% |

## Tray 5: Spectrum, on the nautilus

Any mask on any rod: the finale, every rule at once at depth 6 to 8.

| # | Layout | Masks | Scramble | Depth | Free (masks / white) | Blocked | Right/step | Cost | Ghost | Triple |
|---|---|---|---|---|---|---|---|---|---|---|
| 25 | tri | 0 w, 1 m, 2 r | `0:+2,1:+5,2:+3,1:-2,2:-2,1:-3` | 6 | 1 / 1 | 2 | 1.00 | 14 | 35% | 0% |
| 26 | quad | 0 y, 1 c, 2 r, 3 w | `3:+5,2:+4,1:-4,0:-4,1:-4,0:+2,1:-4` | 7 | 2 / 1 | 2 | 1.42 | 17 | 53% | 8% |
| 27 | eye | 0 b, 1 w, 2 m, 3 y | `1:-4,0:+3,2:-2,3:-3,0:+5,2:+3,0:+3` | 7 | 2 / 1 | 2 | 1.28 | 15 | 60% | 8% |
| 28 | eye | 0 w, 1 r, 2 m, 3 b | `0:-3,2:-2,3:-3,1:-5,2:+4,1:+5,2:-2,1:-2` | 8 | 2 / 1 | 2 | 1.25 | 16 | 50% | 5% |
| 29 | pent | 0 c, 1 m, 2 b, 3 y, 4 w | `4:-4,3:+5,0:-3,2:+2,1:+4,2:-3,1:+3,0:-4` | 8 | 2 / 1 | 3 | 1.44 | 18 | 67% | 8% |
| 30 | pent | 0 y, 1 m, 2 r, 3 w, 4 g | `3:-3,2:+2,1:-2,2:-2,0:+3,4:+2,1:+2,0:-2` | 8 | 1 / 1 | 4 | 1.28 | 17 | 40% | 6% |

## The treble: trays 6 to 15

Specimens 31 to 90 (Jack, 2026-11-27). Every rule above holds, but two: depth climbs past PK1's 8, to 16, and the
readability limits are the deep trays' own.

- **Three stirs a rod.** A rod stirred more than once shows only the sum of its stirs (`read`: its count reads 0 and
  a wrong turn registers 0.8 to 0.97 of its core), so each of its moves but the last is read by deduction. The first
  five trays hold at most three stirs on a rod, and so does every new specimen (`PRISM_ROD_CAP=3` in the search,
  `testPrismLevels`). A first pick without the cap ran pent to depth 20 with seven stirs on one rod and 14 of its 20
  moves unreadable: long, not hard, and a guess at every step. The cap holds pent to 13 (four coloured rods) and hex
  to 19; hex proofs past 16 take the solver many minutes each, so the treble stops at 16.
- **Depth.** Tray 6 deals 8 to 11 and tray 15 15 to 16; a tray's mean rises 0.7 a tray, where the first five's rose
  about half, to twice the old maximum. Most of the deepest are on hex, the only layout the cap lets past 13.
- **Readable.** A deal with a three-way split shows at most 75% ghosts and splits at most 25% three ways; a pair's deal
  (a primary and its ink: red and cyan, green and magenta, blue and yellow), which never splits three ways, up to 90%
  ghosts, as across the whole glass one colour and its opposite still read (a hex 14 of red and cyan at 86% shows every
  animal of the octopus plate). The first five kept 72% (70% on hex) and 8%: the ten new plates keep their shapes
  through deeper ghosts (an ink deal on tri splitting 23% three ways still shows every diatom). Every once-stirred
  coloured rod's count shows over at least half its core (`least read`).
- **Cost.** Each stack keeps four taps at `channelCost` 30 or under (the search's cap; `Tank.fourTaps` is 40).
- **A buried white stir** (Jack, 2026-11-28: "About one specimen in three in trays 13 to 15 buries a white stir
  mid-stack"). Specimens 76, 77, 79, 82, 87 and 88 give their white rod a second stir near the middle of the stack. It
  moves every channel alike, so it shows no colour, only white lines sheared, and every coloured entry over it whose
  disc meets its own must come off first. Each is its first deal with one of its coloured stirs swapped for the white
  one (or, on 79, the white one added), kept where every measure is as hard or harder: fewer right moves a step, more
  forced steps, and on four of them more blocked knobs (`scripts/prism-levels.sh bury`, which tries the white stir at
  every place, then `check` proves the pick). Its count is chosen by eye, never one that nearly cancels the bottom stir,
  which would leave the white rod's core looking unsheared. On hex the hub's white stir meets every disc, so 79, 82
  and 88 bury the whole stack above it. Specimen 76's note says it: "White blocks every colour stirred over it."
- **Hard to crack, not only deep.** Each slot names a layout, depth and palette (`scripts/prism-levels/pick.py`,
  `DEEP`) and takes the readable row of its pool (`scripts/prism-levels/pools.sh <dir> 20`, 37 minutes on a loaded Mac)
  from the hardest third: fewer right moves a step, more blocked knobs (0.35 each), more forced steps (0.1 each). Moves
  read as a sum are the depth less the rods, the same through a pool, so they don't rank. Each specimen takes rods and
  masks no earlier one has where its depth's pools allow (a pair on hex has few ways to colour six rods).

Per tray, the means against the first five's (right moves a step, blocked knobs, forced steps over the untwist, moves
read as a sum, ghost and triple shares):

| Tray | Depth | Right/step | Blocked | Forced | Sums | Ghost | Triple |
|---|---|---|---|---|---|---|---|
| 1 | 3-8 | 1.51 | 2.3 | 2.8 | 1.0 | 60% | 0% |
| 2 | 4-8 | 1.89 | 1.7 | 2.6 | 1.2 | 64% | 6% |
| 3 | 4-7 | 1.18 | 3.2 | 4.2 | 1.0 | 56% | 6% |
| 4 | 6-8 | 1.44 | 2.7 | 3.9 | 2.5 | 59% | 6% |
| 5 | 6-8 | 1.28 | 2.5 | 5.3 | 3.2 | 51% | 6% |
| 6 | 8-11 | 1.43 | 3.5 | 5.4 | 4.0 | 65% | 0% |
| 7 | 9-12 | 1.69 | 3.5 | 5.2 | 4.2 | 73% | 5% |
| 8 | 10-12 | 1.65 | 3.7 | 5.4 | 5.0 | 71% | 0% |
| 9 | 11-13 | 1.46 | 3.5 | 6.5 | 6.5 | 65% | 12% |
| 10 | 12-13 | 1.84 | 4.5 | 4.4 | 5.7 | 77% | 0% |
| 11 | 13-14 | 1.90 | 3.8 | 4.2 | 6.8 | 76% | 3% |
| 12 | 13-15 | 1.91 | 3.8 | 4.0 | 7.3 | 78% | 0% |
| 13 | 13-16 | 1.88 | 4.0 | 5.0 | 8.0 | 76% | 0% |
| 14 | 15-16 | 1.74 | 4.8 | 6.6 | 8.5 | 80% | 0% |
| 15 | 15-16 | 1.73 | 4.5 | 6.1 | 8.8 | 79% | 0% |

So the treble is harder by depth and by traps more than by scarcer moves: blocked knobs rise from 2.5 to 4.8, depth
and the moves read as a sum (4 to 9 against 1 to 3) with it, while right moves a step stay at the first five's 1.4 to
1.9, near 1.9 in the hex trays of 10 to 12, whose seven discs leave more of the stack free at once. The buried white
stirs of trays 13 to 15 bring them back down to 1.7 to 1.9 and add a forced step or two a specimen.

### Tray 6: Complements, on the leaves

Green with magenta and blue with yellow, the pairs tray 1 taught with red and cyan: a primary and its ink share no channel, so they always pass, and two words untwist side by side; rods of one colour block each other where they meet. Depth 8 to 11.

| # | Layout | Masks | Scramble | Depth | Free (masks / white) | Blocked | Right/step | Forced | Sums | Least read | Most | Cost | Ghost | Triple |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 31 | quad | 0 m, 1 w, 2 g, 3 m | `1:-4,2:+4,0:-5,3:-5,0:-3,3:-4,0:+2,3:-2` | 8 | 2 / 1 | 2 | 1.25 | 6.0 | 4 | 0.92 | 3 | 19 | 61% | 0% |
| 32 | pent | 0 y, 1 y, 2 y, 3 b, 4 w | `4:+4,1:+3,2:+4,3:+2,0:-5,1:-2,0:+5,1:-5,2:-2` | 9 | 2 / 1 | 3 | 1.47 | 4.8 | 4 | 0.97 | 3 | 21 | 53% | 0% |
| 33 | pent | 0 w, 1 g, 2 m, 3 m, 4 m | `0:-5,1:+5,3:-4,2:+2,4:+4,3:-2,2:+2,3:-2,4:-3` | 9 | 2 / 1 | 3 | 1.47 | 4.8 | 4 | 0.95 | 3 | 21 | 67% | 0% |
| 34 | pent | 0 y, 1 b, 2 b, 3 b, 4 w | `4:+2,0:-5,3:+3,2:+5,1:-5,3:+2,2:+4,1:+4,2:+4,3:-3` | 10 | 2 / 1 | 3 | 1.30 | 7.0 | 5 | 0.94 | 3 | 16 | 67% | 0% |
| 35 | hex | 0 m, 1 g, 2 g, 3 m, 4 w, 5 m, 6 m | `4:-3,6:+2,1:-5,2:+3,0:-4,5:-3,6:+3,0:+4,1:-5,3:-5` | 10 | 2 / 2 | 5 | 1.68 | 3.4 | 3 | 0.59 | 2 | 21 | 74% | 0% |
| 36 | hex | 0 b, 1 b, 2 b, 3 b, 4 b, 5 y, 6 w | `6:+4,3:+2,2:+2,5:-3,0:-3,1:+2,4:-5,0:+3,3:-2,0:+4,4:-3` | 11 | 2 / 1 | 5 | 1.41 | 6.5 | 4 | 0.54 | 3 | 17 | 70% | 0% |

### Tray 7: Second Pass, on the moths

Primaries, pairs and inks, more rods stirred twice and three times, each showing the sum of its stirs, so the count read off the glass is the move only on a rod's last stir. Depth 9 to 12.

| # | Layout | Masks | Scramble | Depth | Free (masks / white) | Blocked | Right/step | Forced | Sums | Least read | Most | Cost | Ghost | Triple |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 37 | pent | 0 w, 1 r, 2 g, 3 b, 4 b | `0:+5,4:+5,3:+2,1:+3,4:+4,3:+4,4:-4,3:+3,2:+5` | 9 | 3 / 1 | 2 | 1.55 | 5.5 | 4 | 0.97 | 3 | 14 | 68% | 5% |
| 38 | hex | 0 m, 1 w, 2 m, 3 m, 4 g, 5 m, 6 m | `1:+3,4:+5,6:+3,0:-5,5:-4,6:-4,2:+2,5:+5,3:-4,6:-3` | 10 | 3 / 2 | 4 | 1.70 | 5.2 | 3 | 0.58 | 3 | 23 | 79% | 0% |
| 39 | hex | 0 w, 1 r, 2 r, 3 r, 4 c, 5 c, 6 r | `0:-4,1:-3,3:+4,6:-2,5:-4,4:-5,1:-2,2:+4,5:-5,1:-3` | 10 | 2 / 2 | 5 | 1.80 | 3.4 | 3 | 0.65 | 3 | 18 | 86% | 0% |
| 40 | pent | 0 c, 1 y, 2 w, 3 m, 4 m | `2:+2,1:-3,4:+5,3:+2,4:-3,0:+2,4:+4,3:-5,0:+4,1:+3,0:+2` | 11 | 2 / 2 | 3 | 1.40 | 6.6 | 6 | 0.97 | 3 | 26 | 53% | 9% |
| 41 | hex | 0 b, 1 g, 2 g, 3 g, 4 w, 5 b, 6 r | `4:-5,3:-4,6:+4,2:-2,0:-3,3:+5,1:-2,5:+5,2:+2,3:+2,1:+4` | 11 | 4 / 3 | 3 | 2.03 | 4.5 | 4 | 0.71 | 3 | 16 | 72% | 18% |
| 42 | hex | 0 c, 1 r, 2 w, 3 c, 4 r, 5 c, 6 c | `2:-2,5:-2,1:+2,6:+2,0:+3,3:-3,4:+2,5:+3,0:-4,5:+2,0:+3,3:-4` | 12 | 3 / 1 | 4 | 1.63 | 6.1 | 5 | 0.59 | 3 | 26 | 79% | 0% |

### Tray 8: One Ink, on the reef

Pairs, wider: several rods of one colour overlapping, each blocking the next, so a knob tinted like its neighbour is the trap. Depth 10 to 12.

| # | Layout | Masks | Scramble | Depth | Free (masks / white) | Blocked | Right/step | Forced | Sums | Least read | Most | Cost | Ghost | Triple |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 43 | pent | 0 w, 1 r, 2 c, 3 c, 4 c | `0:+2,1:-2,3:-3,4:+4,2:+2,3:+2,4:+4,2:-4,3:-3,2:+2` | 10 | 2 / 1 | 3 | 1.54 | 4.9 | 5 | 0.95 | 3 | 23 | 56% | 0% |
| 44 | pent | 0 y, 1 w, 2 b, 3 b, 4 b | `1:-4,0:+2,4:-3,2:-4,3:-5,4:-2,3:+3,2:-4,3:+5,4:-3,2:+3` | 11 | 3 / 2 | 2 | 1.47 | 6.8 | 6 | 0.95 | 3 | 17 | 67% | 0% |
| 45 | hex | 0 m, 1 g, 2 g, 3 w, 4 m, 5 m, 6 g | `3:+5,2:-3,5:-4,4:+4,1:+5,2:+3,0:+2,6:+5,4:+3,1:-2,0:-5` | 11 | 2 / 1 | 5 | 1.91 | 2.7 | 4 | 0.57 | 2 | 21 | 70% | 0% |
| 46 | hex | 0 b, 1 y, 2 y, 3 y, 4 b, 5 w, 6 y | `5:+2,1:+5,0:-5,6:-4,1:-4,6:-4,1:-4,6:-2,2:-2,3:+4,4:-3,0:-4` | 12 | 3 / 1 | 4 | 1.80 | 4.5 | 5 | 0.70 | 3 | 25 | 79% | 0% |
| 47 | hex | 0 g, 1 w, 2 g, 3 g, 4 g, 5 g, 6 m | `1:+4,0:-4,2:-3,4:+2,5:+2,6:+5,4:+4,5:+5,0:+4,3:-4,5:-4,2:+2` | 12 | 3 / 2 | 4 | 1.53 | 7.1 | 5 | 0.61 | 3 | 18 | 76% | 0% |
| 48 | hex | 0 r, 1 r, 2 r, 3 c, 4 r, 5 r, 6 w | `6:-2,2:-5,5:+5,4:+5,5:+3,4:+5,0:-2,3:-4,1:-2,2:+2,5:+5,4:+3` | 12 | 3 / 2 | 4 | 1.65 | 6.2 | 5 | 0.53 | 3 | 18 | 79% | 0% |

### Tray 9: Trapping, on the diatoms

Inks over primaries and over each other: an ink blocks both its primaries and every ink it shares a channel with, so most knobs push if turned first. The tray splits the glass three ways the most (up to a quarter). Depth 11 to 13.

| # | Layout | Masks | Scramble | Depth | Free (masks / white) | Blocked | Right/step | Forced | Sums | Least read | Most | Cost | Ghost | Triple |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 49 | pent | 0 m, 1 y, 2 c, 3 w, 4 y | `3:-2,1:+3,0:+4,1:-2,4:-5,0:+5,4:+4,0:+5,1:-4,2:-3,4:-2` | 11 | 2 / 2 | 3 | 1.38 | 6.9 | 6 | 1.00 | 3 | 26 | 67% | 14% |
| 50 | pent | 0 g, 1 c, 2 r, 3 w, 4 y | `3:+3,1:-5,0:+5,4:-2,1:+2,0:+2,2:+5,1:+3,4:+3,0:+3,4:-5` | 11 | 2 / 1 | 3 | 1.53 | 5.5 | 6 | 0.97 | 3 | 22 | 56% | 4% |
| 51 | pent | 0 y, 1 g, 2 m, 3 r, 4 w | `4:-2,2:-4,0:-5,3:-2,1:-5,2:-3,0:-4,1:+4,0:+5,3:-2,1:+5,2:-4` | 12 | 2 / 1 | 3 | 1.72 | 3.3 | 7 | 0.98 | 3 | 23 | 68% | 9% |
| 52 | pent | 0 m, 1 w, 2 y, 3 c, 4 m | `1:+2,4:-2,3:+4,2:+4,4:+4,0:+4,4:+5,0:-2,3:+4,2:+5,3:+5,2:-2` | 12 | 2 / 2 | 3 | 1.45 | 6.6 | 7 | 0.98 | 3 | 28 | 68% | 12% |
| 53 | pent | 0 y, 1 y, 2 c, 3 m, 4 w | `4:-5,1:+2,3:-2,0:-4,2:-3,1:-5,3:-3,2:-2,0:-2,1:+3,2:-4,3:+2` | 12 | 1 / 1 | 4 | 1.44 | 6.8 | 7 | 0.98 | 3 | 28 | 57% | 11% |
| 54 | hex | 0 m, 1 m, 2 m, 3 y, 4 c, 5 w, 6 m | `5:-4,0:+5,4:-3,3:+4,4:+2,0:-4,2:+4,1:+3,3:-4,2:+2,1:+5,6:+3,4:-3` | 13 | 2 / 2 | 5 | 1.22 | 10.2 | 6 | 0.71 | 3 | 30 | 74% | 23% |

### Tray 10: Registration, on the fungi

Mostly hex from here on, pairs on seven discs; the held read (a rod in hand drawn in its own colour) is how they are cracked. Depth 12 to 13.

| # | Layout | Masks | Scramble | Depth | Free (masks / white) | Blocked | Right/step | Forced | Sums | Least read | Most | Cost | Ghost | Triple |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 55 | hex | 0 w, 1 r, 2 r, 3 c, 4 c, 5 c, 6 c | `0:+4,1:+2,4:+2,3:+2,6:-4,2:-2,4:+4,3:-5,4:+5,3:-4,5:+3,6:-5` | 12 | 3 / 2 | 4 | 1.77 | 5.6 | 5 | 0.65 | 3 | 26 | 86% | 0% |
| 56 | hex | 0 b, 1 y, 2 y, 3 y, 4 b, 5 w, 6 b | `5:-2,2:-5,0:-3,3:+2,4:-3,1:-5,6:+2,2:-3,1:+3,0:+2,2:+2,4:-4` | 12 | 2 / 2 | 5 | 2.02 | 2.3 | 5 | 0.71 | 3 | 23 | 79% | 0% |
| 57 | hex | 0 b, 1 y, 2 w, 3 b, 4 y, 5 b, 6 y | `2:+3,3:+2,5:+5,4:-3,0:-4,1:-5,5:+3,0:+3,5:-5,6:+2,1:+5,3:+5,0:+2` | 13 | 3 / 1 | 4 | 2.02 | 4.2 | 6 | 0.58 | 3 | 22 | 69% | 0% |
| 58 | hex | 0 r, 1 r, 2 c, 3 c, 4 r, 5 w, 6 r | `5:+2,0:-4,3:+2,2:-2,1:+3,6:+5,1:-4,3:+3,6:-4,2:-3,0:+3,1:+5,4:-5` | 13 | 3 / 2 | 4 | 1.75 | 4.8 | 6 | 0.71 | 3 | 22 | 79% | 0% |
| 59 | hex | 0 g, 1 g, 2 g, 3 g, 4 m, 5 m, 6 w | `6:+5,3:+5,5:+2,2:-3,3:-4,0:-4,3:-2,1:-3,4:-2,5:-4,4:+3,5:+3,0:+4` | 13 | 2 / 1 | 5 | 1.89 | 2.8 | 6 | 0.55 | 3 | 23 | 73% | 0% |
| 60 | hex | 0 c, 1 r, 2 c, 3 c, 4 w, 5 c, 6 r | `4:-5,5:+4,1:+2,0:-3,2:-5,3:-2,5:+2,2:+2,0:+5,5:-5,2:-3,0:+5,6:+4` | 13 | 2 / 1 | 5 | 1.59 | 6.7 | 6 | 0.59 | 3 | 28 | 78% | 0% |

### Tray 11: Misregister, on the feathers

Hex and pent: discs that miss pass whatever their colours, and one deals the three primaries. Depth 13 to 14.

| # | Layout | Masks | Scramble | Depth | Free (masks / white) | Blocked | Right/step | Forced | Sums | Least read | Most | Cost | Ghost | Triple |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 61 | pent | 0 m, 1 m, 2 g, 3 g, 4 w | `4:+2,1:-4,0:+3,3:+5,2:+4,1:+4,0:+2,1:-5,0:+4,3:-5,2:-2,3:+4,2:+5` | 13 | 2 / 2 | 3 | 1.75 | 3.2 | 8 | 0.95 | 3 | 24 | 68% | 0% |
| 62 | hex | 0 c, 1 c, 2 c, 3 r, 4 r, 5 w, 6 r | `5:-3,4:+4,3:+4,4:+3,3:-2,0:+2,1:+3,0:-4,1:+3,2:-4,1:-3,2:+5,6:+2` | 13 | 3 / 2 | 4 | 1.87 | 4.6 | 6 | 0.58 | 3 | 25 | 79% | 0% |
| 63 | hex | 0 b, 1 y, 2 y, 3 y, 4 y, 5 w, 6 b | `5:+4,4:+5,0:+4,6:-2,1:-4,0:-2,2:-3,1:-2,3:-3,6:-5,0:+5,6:+4,4:+3,2:-4` | 14 | 3 / 3 | 4 | 2.16 | 3.0 | 7 | 0.59 | 3 | 26 | 79% | 0% |
| 64 | hex | 0 w, 1 g, 2 g, 3 m, 4 g, 5 g, 6 g | `0:+2,3:-4,6:+4,1:-2,2:+4,6:+3,4:+4,5:+3,1:+3,4:+3,2:-5,5:+5,4:+2` | 13 | 3 / 2 | 4 | 1.84 | 5.0 | 6 | 0.65 | 3 | 19 | 86% | 0% |
| 65 | hex | 0 b, 1 b, 2 g, 3 g, 4 w, 5 r, 6 b | `4:+3,1:-4,3:+2,0:-2,1:+2,6:-2,1:-5,5:-3,2:+5,6:+5,0:-2,3:-2,6:+4,0:-5` | 14 | 3 / 1 | 4 | 1.76 | 6.0 | 7 | 0.71 | 3 | 19 | 66% | 17% |
| 66 | hex | 0 m, 1 w, 2 g, 3 g, 4 g, 5 g, 6 m | `1:+2,0:+3,2:-3,3:+4,6:+2,0:+5,6:+4,0:-3,4:+4,2:-3,3:-4,2:+5,3:+4,5:-2` | 14 | 3 / 2 | 4 | 2.04 | 3.7 | 7 | 0.58 | 3 | 24 | 79% | 0% |

### Tray 12: Chromatic, on the starfish

A stir under its opposite colour (red under cyan, green under magenta, blue under yellow) is not buried; the long lines are mostly reading which is. Depth 13 to 15.

| # | Layout | Masks | Scramble | Depth | Free (masks / white) | Blocked | Right/step | Forced | Sums | Least read | Most | Cost | Ghost | Triple |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 67 | hex | 0 m, 1 m, 2 g, 3 w, 4 g, 5 g, 6 g | `3:+3,6:-2,5:-5,2:+4,0:+3,6:+5,5:-2,4:-3,6:+5,5:+2,4:+4,1:+2,0:-4` | 13 | 3 / 1 | 4 | 2.00 | 3.7 | 6 | 0.53 | 3 | 21 | 79% | 0% |
| 68 | pent | 0 b, 1 y, 2 y, 3 w, 4 b | `3:-3,1:+3,4:-2,0:-3,2:+2,4:-2,0:-5,1:-3,2:-5,4:-3,0:-3,1:-5,2:-5` | 13 | 2 / 1 | 3 | 1.75 | 3.2 | 8 | 0.95 | 3 | 24 | 68% | 0% |
| 69 | hex | 0 c, 1 r, 2 w, 3 r, 4 r, 5 c, 6 c | `2:-2,3:-2,5:-5,0:+5,6:+3,4:+5,1:-4,5:-3,0:-4,6:+4,5:+2,3:-3,4:-3,0:+3` | 14 | 3 / 1 | 4 | 1.88 | 4.4 | 7 | 0.59 | 3 | 27 | 79% | 0% |
| 70 | hex | 0 w, 1 y, 2 y, 3 y, 4 b, 5 b, 6 b | `0:-3,1:+3,4:+4,5:+5,2:-2,4:-5,1:-4,5:-4,2:+2,1:-2,2:-2,4:+3,6:-5,3:-2` | 14 | 3 / 2 | 4 | 1.82 | 4.0 | 7 | 0.66 | 3 | 26 | 85% | 0% |
| 71 | hex | 0 w, 1 r, 2 r, 3 c, 4 r, 5 r, 6 r | `0:+2,2:-2,1:+5,4:+3,5:+3,2:-2,6:+5,5:-2,6:+3,1:-3,4:-3,5:-4,4:-3,2:+4,3:-4` | 15 | 3 / 1 | 4 | 1.81 | 5.8 | 8 | 0.66 | 3 | 21 | 78% | 0% |
| 72 | hex | 0 g, 1 m, 2 g, 3 m, 4 m, 5 w, 6 g | `5:+2,1:-2,2:+3,3:-3,0:-5,6:+4,2:-2,4:-4,0:+3,2:-4,3:+2,4:-5,6:+2,0:-2,3:-4` | 15 | 3 / 1 | 4 | 2.20 | 2.9 | 8 | 0.59 | 3 | 26 | 79% | 0% |

### Tray 13: Separations, on the beetles

Every ink read as its two primaries, against the primary it passes; 76 and 77 bury a white stir, and 76's note says so. Depth 13 to 16.

| # | Layout | Masks | Scramble | Depth | Free (masks / white) | Blocked | Right/step | Forced | Sums | Least read | Most | Cost | Ghost | Triple |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 73 | pent | 0 w, 1 r, 2 r, 3 c, 4 c | `0:+2,1:+4,3:-5,2:+4,4:-4,3:-3,4:-4,1:-3,3:+3,2:+5,4:-5,1:+3,2:+3` | 13 | 2 / 2 | 3 | 1.75 | 3.2 | 8 | 0.95 | 3 | 24 | 61% | 0% |
| 74 | hex | 0 r, 1 c, 2 r, 3 w, 4 r, 5 c, 6 c | `3:-5,5:-4,6:-3,5:-2,0:-3,2:-2,0:+2,4:+2,2:+3,6:-5,0:-3,5:+5,1:-5,2:+2` | 14 | 3 / 2 | 4 | 1.98 | 3.1 | 7 | 0.59 | 3 | 25 | 79% | 0% |
| 75 | hex | 0 b, 1 y, 2 y, 3 b, 4 y, 5 y, 6 w | `6:-3,2:+5,3:-2,1:+4,0:+2,5:+2,4:-4,3:+4,5:+5,4:-4,5:-5,2:-4,0:+5,1:+3,4:+3` | 15 | 3 / 2 | 4 | 2.36 | 3.0 | 8 | 0.58 | 3 | 30 | 79% | 0% |
| 76 | hex | 0 m, 1 w, 2 g, 3 g, 4 m, 5 g, 6 m | `1:+5,0:-2,5:+4,6:+5,4:+3,0:-5,2:-2,6:-4,4:+2,0:-5,1:+3,6:+3,3:+2,2:+5,3:+2` | 15 | 3 / 2 | 4 | 1.75 | 6.5 | 8 | 0.58 | 3 | 30 | 79% | 0% |
| 77 | hex | 0 c, 1 c, 2 c, 3 r, 4 r, 5 r, 6 w | `6:+5,3:-5,0:-3,4:+3,3:-4,4:-2,3:-2,4:+4,5:-3,6:+3,0:+4,2:-4,0:+2,2:-2,1:+2` | 15 | 1 / 1 | 6 | 1.26 | 11.1 | 8 | 0.70 | 3 | 28 | 82% | 0% |
| 78 | hex | 0 b, 1 y, 2 w, 3 y, 4 b, 5 y, 6 y | `2:+2,4:-3,5:-5,3:+5,0:+5,6:+2,5:-3,6:+3,1:+3,4:-5,6:+3,5:-2,1:-2,0:+4,4:+2,0:-3` | 16 | 4 / 1 | 3 | 2.20 | 2.8 | 9 | 0.58 | 3 | 30 | 79% | 0% |

### Tray 14: Interference, on the seahorses

All hex: rods stirred three times, their sums read and deduced; 79 and 82 bury the hub's white stir mid-stack. Depth 15 to 16.

| # | Layout | Masks | Scramble | Depth | Free (masks / white) | Blocked | Right/step | Forced | Sums | Least read | Most | Cost | Ghost | Triple |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 79 | hex | 0 w, 1 g, 2 g, 3 m, 4 g, 5 m, 6 m | `0:-4,5:+5,3:-5,2:-2,6:+5,4:+3,0:-3,1:+3,2:+5,1:+2,5:-4,2:-3,1:+5,6:+2,5:+3` | 15 | 2 / 1 | 5 | 1.85 | 6.0 | 8 | 0.62 | 3 | 28 | 79% | 0% |
| 80 | hex | 0 r, 1 r, 2 r, 3 w, 4 r, 5 c, 6 c | `3:-4,2:-3,0:+2,2:-4,0:-3,6:+3,2:-4,0:+2,4:+2,1:+4,5:-2,6:+2,5:-5,6:+4,5:-3` | 15 | 3 / 1 | 4 | 1.86 | 3.6 | 8 | 0.59 | 3 | 26 | 79% | 0% |
| 81 | hex | 0 r, 1 c, 2 r, 3 c, 4 c, 5 w, 6 c | `5:+2,0:-5,4:+5,3:-5,4:-4,3:-4,4:-4,3:+3,2:-2,6:-2,1:+4,6:-2,0:+3,2:-4,1:-3` | 15 | 3 / 1 | 4 | 2.33 | 3.4 | 8 | 0.59 | 3 | 30 | 79% | 0% |
| 82 | hex | 0 w, 1 g, 2 g, 3 m, 4 g, 5 g, 6 g | `0:+2,3:-4,6:+4,1:-2,2:+4,0:+4,4:+4,5:+3,1:+3,4:+3,2:-5,5:+5,4:+2,5:+5,1:+4,6:+4` | 16 | 1 / 1 | 6 | 1.46 | 8.7 | 9 | 0.66 | 3 | 24 | 86% | 0% |
| 83 | hex | 0 r, 1 r, 2 r, 3 c, 4 r, 5 r, 6 w | `6:-2,2:-5,5:+5,4:+5,5:+3,4:+5,0:-2,3:-4,1:-2,2:+2,5:+5,4:+3,1:+4,2:-5,0:+4,1:-4` | 16 | 2 / 1 | 5 | 1.49 | 8.7 | 9 | 0.53 | 3 | 22 | 79% | 0% |
| 84 | hex | 0 b, 1 b, 2 b, 3 b, 4 b, 5 y, 6 w | `6:+4,3:+2,2:+2,5:-3,0:-3,1:+2,4:-5,0:+3,3:-2,0:+4,4:-3,2:+5,1:+5,3:+2,2:-4,1:-4` | 16 | 2 / 1 | 5 | 1.44 | 9.4 | 9 | 0.54 | 3 | 22 | 79% | 0% |

### Tray 15: Full Spectrum, on the octopus

The pack's deepest, every one on hex; 87 and 88 bury a white stir. Depth 15 to 16.

| # | Layout | Masks | Scramble | Depth | Free (masks / white) | Blocked | Right/step | Forced | Sums | Least read | Most | Cost | Ghost | Triple |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 85 | hex | 0 r, 1 c, 2 r, 3 c, 4 c, 5 c, 6 w | `6:-5,4:+3,5:-4,2:-5,0:+3,1:+4,2:-4,4:+3,3:+5,0:+3,4:+5,5:+2,2:-4,3:+3,0:-4` | 15 | 4 / 1 | 3 | 2.17 | 2.8 | 8 | 0.53 | 3 | 28 | 79% | 0% |
| 86 | hex | 0 w, 1 r, 2 r, 3 c, 4 r, 5 r, 6 r | `0:+2,2:-2,1:+5,4:+3,5:+3,2:-2,6:+5,5:-2,6:+3,1:-3,4:-3,5:-4,4:-3,2:+4,3:-4,1:+2` | 16 | 3 / 2 | 4 | 1.81 | 6.0 | 9 | 0.66 | 3 | 22 | 79% | 0% |
| 87 | hex | 0 g, 1 g, 2 g, 3 g, 4 m, 5 m, 6 w | `6:+5,3:+5,5:+2,2:-3,3:-4,0:-4,3:-2,1:-3,6:+4,5:-4,4:+3,5:+3,0:+4,1:-2,4:-5,2:-3` | 16 | 2 / 2 | 5 | 1.65 | 5.9 | 9 | 0.55 | 3 | 28 | 80% | 0% |
| 88 | hex | 0 w, 1 y, 2 y, 3 y, 4 b, 5 b, 6 b | `0:-3,1:+3,4:+4,5:+5,2:-2,4:-5,1:-4,5:-4,2:+2,1:-2,2:-2,0:-4,6:-5,3:-2,5:-3,6:-5` | 16 | 2 / 2 | 5 | 1.55 | 7.2 | 9 | 0.62 | 3 | 30 | 83% | 0% |
| 89 | hex | 0 r, 1 r, 2 c, 3 c, 4 r, 5 w, 6 r | `5:+2,0:-4,3:+2,2:-2,1:+3,6:+5,1:-4,3:+3,6:-4,2:-3,0:+3,1:+5,4:-5,3:+3,0:-2,2:-4` | 16 | 2 / 1 | 5 | 1.83 | 4.2 | 9 | 0.71 | 3 | 27 | 79% | 0% |
| 90 | hex | 0 g, 1 w, 2 g, 3 g, 4 g, 5 g, 6 m | `1:+4,0:-4,2:-3,4:+2,5:+2,6:+5,4:+4,5:+5,0:+4,3:-4,5:-4,2:+2,3:+2,4:-3,3:+5,2:-2` | 16 | 2 / 1 | 5 | 1.36 | 10.4 | 9 | 0.61 | 3 | 22 | 75% | 0% |

