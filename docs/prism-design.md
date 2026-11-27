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
plate, each a step deeper than the last: depth 8 to 11 in tray 6, 17 to 20 in tray 15, a tray's mean rising one a
tray against the first five's half (twice the slope). Past depth 8 lifts PK1's cap for those trays only, which goes
back to Jack with the shots. The section "The treble: trays 6 to 15" below has their rules, measures and tables.

## Rules every row keeps

- No entry merges as it is dealt, so the depth is the string's length, and it is at most 8 (`testPrismLevels`).
- Par is the depth, and it is the solver's optimum (`scripts/prism-levels.sh table`, `testPrismParIsTheOptimum`): no
  detour beats untwisting, and untwisting on a real `Game` reaches it.
- The bottom entry sits on the one white rod, and that rod holds nothing else.
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

Specimens 31 to 90 (Jack, 2026-11-27). Every rule above holds, but two: depth climbs past PK1's 8, a step a tray to 20,
and the readability limits are the deep trays' own.

- **Depth.** Tray k (6 to 15) deals depths k+2, k+3, k+3, k+4, k+4, k+5: 8 to 11 in tray 6, 17 to 20 in tray 15. A
  tray's mean rises one a tray, where the first five's rose about half: twice the slope, to a maximum two and a half
  times the old one. The solver proves every one at par (`scripts/prism-levels.sh check`, seconds to a minute each with
  `-O` on the Mac; `testPrismParIsTheOptimum` runs them all, behind `UNSTIR_SLOW_TESTS`).
- **Readable.** At most 75% of the glass shows ghosts and at most 25% splits three ways, against 72% and 8% for the
  first five: the ten new plates keep their shapes through deeper ghosts (a tri deal of two inks at 23% still shows
  every diatom), and past depth 13 hex keeps to a primary and its ink (red and cyan, green and magenta, blue and
  yellow), whose two channels' words never split three ways. Hex's seven discs cover nearly all the glass, so most of
  the deepest specimens are on pent. Every once-stirred coloured rod's count shows over at least half its core
  (`least read`, `scripts/prism-levels.sh read`); a rod stirred more than once shows the sum of its stirs, the
  deduction tray 7 names.
- **Cost.** Each stack keeps four taps at `channelCost` 30 or under (the search's cap; `Tank.fourTaps` is 40). The
  deepest (cost 23 and up, 20 maps) are dealt past `StirMap.prismLeast`, so they draw through the stored map from the
  deal, as any Prism glass does once a player stirs that deep.
- **Hard to crack, not only deep.** Each slot names a layout, depth and palette (`scripts/prism-levels/pick.py`,
  `DEEP`), and takes the readable row of its pool (`scripts/prism-levels/pools.sh`) from the harder half, by fewer right
  moves a step, more blocked knobs (0.35 each), more moves read as a sum (0.15 each) and more forced steps (0.1 each),
  slot k of six k/5 of the way from the pool's middle to its hardest. No two of the sixty share rods and masks, as a
  deeper deal on the same knobs reads as a repeat.

Per tray, the means against the first five's (right moves a step, blocked knobs, forced steps over the untwist, moves
read as a sum, ghost and triple shares):

| Tray | Depth | Right/step | Blocked | Forced | Sums | Ghost | Triple |
|---|---|---|---|---|---|---|---|
| 1 | 3-8 | 1.51 | 2.3 | 2.8 | 1.0 | 60% | 0% |
| 2 | 4-8 | 1.89 | 1.7 | 2.6 | 1.2 | 64% | 6% |
| 3 | 4-7 | 1.18 | 3.2 | 4.2 | 1.0 | 56% | 6% |
| 4 | 6-8 | 1.44 | 2.7 | 3.9 | 2.5 | 59% | 6% |
| 5 | 6-8 | 1.28 | 2.5 | 5.3 | 3.2 | 51% | 6% |
| 6 | 8-11 | 1.41 | 3.2 | 5.9 | 4.2 | 65% | 0% |
| 7 | 9-12 | 1.60 | 2.7 | 5.8 | 5.0 | 70% | 5% |
| 8 | 10-13 | 1.55 | 3.3 | 6.2 | 5.7 | 66% | 0% |
| 9 | 11-14 | 1.28 | 2.8 | 8.9 | 8.2 | 59% | 14% |
| 10 | 12-15 | 1.36 | 2.7 | 9.3 | 8.3 | 64% | 4% |
| 11 | 13-16 | 1.66 | 3.2 | 6.9 | 8.5 | 68% | 3% |
| 12 | 14-17 | 1.63 | 2.8 | 7.8 | 9.8 | 68% | 2% |
| 13 | 15-18 | 1.38 | 2.7 | 11.1 | 11.3 | 65% | 0% |
| 14 | 16-19 | 1.32 | 2.0 | 13.5 | 12.5 | 67% | 0% |
| 15 | 17-20 | 1.35 | 2.3 | 13.1 | 13.5 | 66% | 0% |

So the treble is harder by length and by reading, not by scarcer moves: right moves a step stay near the first five's
(1.3 to 1.7 against 1.2 to 1.9), while forced steps over the untwist climb from 6 to 13 (the first five's 3 to 5) and
the moves read as a sum, where the glass shows a rod's total and not the move, from 4 to 13 (1 to 3). Hex's seven
discs give the most blocked knobs (4 to 5) but read worst, so the last trays lean on pent pairs.

The proofs take 35 minutes on the Mac with `-O` under load (`scripts/prism-levels.sh table`), against 16 seconds for
the first five; the deepest pent pairs take seconds each, mixed palettes on pent and pairs on hex up to four minutes.

### Tray 6: Complements, on the leaves

Green with magenta and blue with yellow, the pairs tray 1 taught with red and cyan: a primary and its ink share no channel, so they always pass, and two words untwist side by side. Rods of one colour block each other where they meet. Depth 8 to 11.

| # | Layout | Masks | Scramble | Depth | Free (masks / white) | Blocked | Right/step | Forced | Sums | Least read | Cost | Ghost | Triple |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 31 | quad | 0 g, 1 m, 2 w, 3 g | `2:-5,0:+5,1:-3,3:+4,0:+5,3:+4,0:-3,3:+2` | 8 | 2 / 1 | 2 | 1.37 | 5.0 | 4 | 0.96 | 14 | 61% | 0% |
| 32 | eye | 0 w, 1 b, 2 b, 3 y | `0:+4,2:-4,3:-4,1:+3,2:+2,1:+4,2:-5,1:+2,2:-5` | 9 | 2 / 1 | 2 | 1.22 | 7.0 | 5 | 0.88 | 15 | 57% | 0% |
| 33 | pent | 0 w, 1 m, 2 g, 3 m, 4 m | `0:-3,2:+2,1:+4,4:+5,3:-3,4:-3,3:-3,4:+5,3:+2` | 9 | 3 / 2 | 2 | 1.55 | 5.5 | 4 | 0.95 | 21 | 67% | 0% |
| 34 | pent | 0 y, 1 w, 2 b, 3 b, 4 b | `1:-4,0:+2,4:-3,2:-4,3:-5,4:-2,3:+3,2:-4,3:+5,2:+3` | 10 | 2 / 1 | 3 | 1.35 | 6.5 | 5 | 0.95 | 16 | 67% | 0% |
| 35 | hex | 0 m, 1 g, 2 w, 3 m, 4 m, 5 m, 6 g | `2:-5,4:+2,0:+5,5:+2,1:+2,0:+2,3:+3,4:-2,0:-4,6:+5` | 10 | 2 / 1 | 5 | 1.49 | 5.1 | 3 | 0.59 | 22 | 70% | 0% |
| 36 | hex | 0 y, 1 y, 2 y, 3 y, 4 b, 5 w, 6 y | `5:-4,0:-5,6:-5,3:+5,2:+3,1:+3,3:+2,6:+5,4:+3,0:-5,2:-4` | 11 | 2 / 1 | 5 | 1.48 | 6.1 | 4 | 0.58 | 25 | 67% | 0% |

### Tray 7: Second Pass, on the moths

Primaries, and red with cyan: more rods stirred twice and three times, each showing the sum of its stirs, so the count read off the glass is not the move. Depth 9 to 12.

| # | Layout | Masks | Scramble | Depth | Free (masks / white) | Blocked | Right/step | Forced | Sums | Least read | Cost | Ghost | Triple |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 37 | pent | 0 b, 1 b, 2 w, 3 r, 4 g | `2:+3,0:+3,1:+4,0:-4,4:-4,3:+5,1:-2,0:-5,1:-5` | 9 | 3 / 2 | 2 | 1.66 | 4.6 | 4 | 0.97 | 14 | 68% | 5% |
| 38 | eye | 0 c, 1 r, 2 c, 3 w | `3:-2,1:+5,0:-3,2:-5,0:+4,2:-5,0:+4,2:-4,0:+5,2:-4` | 10 | 2 / 1 | 2 | 1.20 | 8.0 | 6 | 0.65 | 23 | 70% | 0% |
| 39 | pent | 0 w, 1 r, 2 g, 3 b, 4 b | `0:+5,4:+5,3:+2,1:+3,4:+4,3:+4,4:-4,3:-4,4:+5,2:-3` | 10 | 3 / 2 | 2 | 1.50 | 6.5 | 5 | 0.97 | 15 | 67% | 5% |
| 40 | hex | 0 b, 1 b, 2 g, 3 g, 4 w, 5 r, 6 b | `4:+3,1:-4,3:+2,0:-2,1:+2,6:-2,1:-5,6:-3,5:+5,2:+5,1:-5` | 11 | 3 / 2 | 4 | 1.76 | 4.9 | 4 | 0.71 | 16 | 75% | 17% |
| 41 | pent | 0 r, 1 b, 2 w, 3 g, 4 r | `2:+2,0:+4,1:+4,3:-5,4:-5,0:-2,4:-4,0:-2,4:-5,0:+5,4:+5` | 11 | 3 / 1 | 2 | 1.63 | 5.6 | 6 | 0.97 | 16 | 67% | 5% |
| 42 | hex | 0 w, 1 r, 2 r, 3 c, 4 c, 5 c, 6 c | `0:+4,1:+2,4:+2,3:+2,6:-4,2:-2,4:+4,3:-5,4:+5,5:+3,6:+4,5:-3` | 12 | 3 / 2 | 4 | 1.85 | 5.0 | 5 | 0.65 | 26 | 72% | 0% |

### Tray 8: One Ink, on the reef

Pairs again, deeper and wider, where several rods of one colour overlap and block: the knob tinted alike is the trap. Depth 10 to 13.

| # | Layout | Masks | Scramble | Depth | Free (masks / white) | Blocked | Right/step | Forced | Sums | Least read | Cost | Ghost | Triple |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 43 | eye | 0 g, 1 w, 2 g, 3 m | `1:-2,3:-4,0:-3,2:-5,0:+5,2:+2,0:-4,2:+2,0:+5,2:+3` | 10 | 2 / 1 | 2 | 1.20 | 8.0 | 6 | 0.80 | 16 | 60% | 0% |
| 44 | pent | 0 r, 1 w, 2 r, 3 c, 4 r | `1:+4,0:-4,3:+5,4:+4,2:-5,0:-3,4:-4,0:-5,4:-4,0:-4,4:-2` | 11 | 3 / 2 | 2 | 1.45 | 7.5 | 6 | 0.95 | 17 | 68% | 0% |
| 45 | pent | 0 b, 1 y, 2 y, 3 y, 4 w | `4:+5,2:+4,3:+2,2:+2,1:-5,0:-3,2:-5,1:+5,2:-2,1:-5,3:-2` | 11 | 3 / 3 | 2 | 1.42 | 7.3 | 6 | 0.97 | 25 | 52% | 0% |
| 46 | hex | 0 m, 1 g, 2 g, 3 m, 4 w, 5 m, 6 m | `4:-3,6:+2,1:-5,2:+3,0:-4,5:-3,6:+3,0:+4,1:-5,3:-5,5:+3,0:+2` | 12 | 2 / 1 | 5 | 1.73 | 4.6 | 5 | 0.59 | 25 | 70% | 0% |
| 47 | hex | 0 w, 1 r, 2 r, 3 r, 4 c, 5 c, 6 r | `0:-4,1:-3,3:+4,6:-2,5:-4,4:-5,1:-2,2:+4,5:-5,1:-3,4:-2,3:-4` | 12 | 3 / 2 | 4 | 1.98 | 3.3 | 5 | 0.65 | 21 | 74% | 0% |
| 48 | hex | 0 b, 1 y, 2 y, 3 w, 4 b, 5 b, 6 b | `3:+5,0:+2,1:-3,2:+2,5:-2,4:+3,6:-4,5:+2,4:+4,5:+5,6:+3,5:-5,1:-4` | 13 | 2 / 2 | 5 | 1.55 | 6.2 | 6 | 0.59 | 21 | 72% | 0% |

### Tray 9: Trapping, on the diatoms

Inks over primaries and over each other: an ink blocks both its primaries and every ink it shares a channel with, so most knobs push if turned first. Depth 11 to 14, the deepest ink deals, some splitting a fifth of the glass three ways.

| # | Layout | Masks | Scramble | Depth | Free (masks / white) | Blocked | Right/step | Forced | Sums | Least read | Cost | Ghost | Triple |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 49 | tri | 0 y, 1 w, 2 c | `1:-2,2:-4,0:-4,2:-4,0:+3,2:+3,0:-4,2:-2,0:+2,2:+3,0:+3` | 11 | 1 / 1 | 2 | 1.00 | 11.0 | 8 | 1.00 | 26 | 41% | 13% |
| 50 | quad | 0 m, 1 w, 2 c, 3 y | `1:-5,0:-3,2:+2,3:-2,2:-3,3:+5,2:-5,3:-5,0:+2,2:-5,3:-4,2:-4` | 12 | 1 / 1 | 3 | 1.17 | 10.0 | 8 | 0.97 | 28 | 60% | 18% |
| 51 | eye | 0 w, 1 y, 2 b, 3 g | `0:+3,3:-5,2:+4,1:-2,3:+3,1:+4,3:+4,1:+2,3:-5,1:+2,3:-5,1:-4` | 12 | 2 / 1 | 2 | 1.17 | 10.0 | 8 | 0.94 | 22 | 60% | 14% |
| 52 | pent | 0 g, 1 c, 2 r, 3 w, 4 y | `3:+3,1:-5,0:+5,4:-2,1:+2,0:+2,2:+5,1:+3,4:+3,0:+4,1:-5,0:+4,4:+2` | 13 | 2 / 1 | 3 | 1.44 | 7.4 | 8 | 0.97 | 25 | 68% | 9% |
| 53 | pent | 0 w, 1 m, 2 y, 3 c, 4 y | `0:+5,1:-5,3:+2,2:-4,1:-4,4:+5,3:-3,2:+2,3:-4,4:+2,1:+2,2:-4,3:+5` | 13 | 1 / 1 | 4 | 1.48 | 6.7 | 8 | 0.98 | 30 | 59% | 15% |
| 54 | pent | 0 w, 1 b, 2 r, 3 y, 4 g | `0:+3,2:-2,1:-4,4:-3,3:+5,2:-5,3:-2,2:-5,4:-5,3:+3,4:+3,2:-3,3:-4,4:-2` | 14 | 2 / 1 | 3 | 1.41 | 8.6 | 9 | 0.98 | 23 | 68% | 12% |

### Tray 10: Registration, on the fungi

Any colours, depth 12 to 15; the held read (a rod in hand drawn in its own colour) is how the deeper ones are cracked.

| # | Layout | Masks | Scramble | Depth | Free (masks / white) | Blocked | Right/step | Forced | Sums | Least read | Cost | Ghost | Triple |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 55 | eye | 0 r, 1 w, 2 r, 3 c | `1:+4,0:+2,2:-2,3:+5,0:+3,2:+2,0:-4,2:-2,0:-2,2:-5,0:+4,2:+5` | 12 | 2 / 1 | 2 | 1.17 | 10.0 | 8 | 0.80 | 18 | 60% | 0% |
| 56 | pent | 0 g, 1 w, 2 b, 3 c, 4 r | `1:+3,2:+3,3:+3,4:-5,2:+2,3:+2,2:-3,3:+3,2:+2,3:+3,0:-5,2:+3,3:-5` | 13 | 3 / 2 | 2 | 1.38 | 9.5 | 8 | 0.98 | 23 | 68% | 10% |
| 57 | pent | 0 w, 1 b, 2 g, 3 m, 4 y | `0:-3,2:+2,4:+2,1:+5,3:+3,4:+3,3:+2,4:-5,3:-5,4:-2,3:+5,4:+3,3:+2` | 13 | 3 / 2 | 2 | 1.38 | 9.5 | 8 | 0.98 | 28 | 67% | 10% |
| 58 | pent | 0 b, 1 b, 2 y, 3 w, 4 b | `3:+3,0:-3,1:+5,4:-2,2:+2,0:+2,4:+2,1:-5,0:+4,1:-4,0:+3,1:+4,0:+2,1:+5` | 14 | 2 / 1 | 3 | 1.38 | 8.8 | 9 | 0.97 | 20 | 52% | 0% |
| 59 | hex | 0 g, 1 g, 2 g, 3 g, 4 m, 5 m, 6 w | `6:+5,3:+5,5:+2,2:-3,3:-4,0:-4,3:-2,0:-3,3:-4,2:+3,4:+3,0:+3,1:+2,0:+4` | 14 | 2 / 1 | 5 | 1.41 | 8.3 | 7 | 0.55 | 21 | 68% | 0% |
| 60 | pent | 0 y, 1 r, 2 c, 3 w, 4 b | `3:-2,4:+4,1:+5,2:+5,0:+2,1:+5,0:+5,1:-3,0:-2,1:-2,0:-4,1:+2,0:+2,1:+2,0:+4` | 15 | 3 / 1 | 2 | 1.47 | 9.5 | 10 | 0.97 | 27 | 68% | 7% |

### Tray 11: Misregister, on the feathers

Depth 13 to 16, pent and hex: on hex's seven discs, those that miss pass whatever their colours.

| # | Layout | Masks | Scramble | Depth | Free (masks / white) | Blocked | Right/step | Forced | Sums | Least read | Cost | Ghost | Triple |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 61 | pent | 0 m, 1 w, 2 m, 3 g, 4 g | `1:-4,3:-3,0:-3,4:-5,3:-3,2:-2,4:-4,3:+3,4:+3,3:-2,4:-4,3:+3,4:-4` | 13 | 3 / 1 | 2 | 1.54 | 7.5 | 8 | 0.95 | 20 | 67% | 0% |
| 62 | pent | 0 c, 1 g, 2 b, 3 r, 4 w | `4:+2,3:-5,1:+3,2:-5,0:+4,1:+4,0:+5,1:+2,0:+2,1:-3,0:-2,1:+3,0:-2,1:-3` | 14 | 3 / 1 | 2 | 1.43 | 9.5 | 9 | 0.97 | 24 | 68% | 13% |
| 63 | hex | 0 c, 1 c, 2 c, 3 r, 4 r, 5 w, 6 r | `5:-3,4:+4,3:+4,4:+3,3:-2,0:+2,1:+3,0:-4,1:+3,2:-4,1:-3,6:-2,0:-4,4:+5` | 14 | 3 / 1 | 4 | 1.91 | 4.1 | 7 | 0.58 | 26 | 75% | 0% |
| 64 | pent | 0 w, 1 g, 2 g, 3 r, 4 b | `0:-2,3:+4,1:-4,4:+5,2:-4,1:+3,2:-4,1:-3,2:+4,1:+4,2:+5,1:+5,2:-3,1:-2,2:+2` | 15 | 3 / 2 | 2 | 1.33 | 11.5 | 10 | 0.97 | 20 | 58% | 3% |
| 65 | hex | 0 r, 1 r, 2 c, 3 c, 4 r, 5 w, 6 r | `5:+2,0:-4,3:+2,2:-2,1:+3,6:+5,1:-4,3:+3,6:-4,2:-3,0:+3,1:+5,3:-5,6:+3,4:-3` | 15 | 3 / 2 | 4 | 1.84 | 4.7 | 8 | 0.71 | 25 | 69% | 0% |
| 66 | hex | 0 m, 1 w, 2 g, 3 g, 4 g, 5 g, 6 m | `1:+2,0:+3,2:-3,3:+4,6:+2,0:+5,6:+4,0:-3,4:-3,2:+4,6:-4,0:+4,5:-2,4:+5,6:-2,3:+2` | 16 | 2 / 2 | 5 | 1.89 | 4.3 | 9 | 0.58 | 29 | 72% | 0% |

### Tray 12: Chromatic, on the starfish

Depth 14 to 17: a stir under another colour is not buried, and the long lines are mostly reading which is.

| # | Layout | Masks | Scramble | Depth | Free (masks / white) | Blocked | Right/step | Forced | Sums | Least read | Cost | Ghost | Triple |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 67 | pent | 0 b, 1 w, 2 b, 3 y, 4 b | `1:-4,3:+5,4:+4,2:-2,0:-5,4:-3,0:-4,4:+5,0:-3,4:+3,0:-2,4:+2,0:-5,4:+2` | 14 | 3 / 2 | 2 | 1.43 | 9.5 | 9 | 0.97 | 20 | 68% | 0% |
| 68 | pent | 0 r, 1 c, 2 r, 3 r, 4 w | `4:-3,3:+5,2:-5,1:-5,0:+5,3:-5,2:-5,3:+4,2:+2,3:-3,2:-4,3:+2,2:-5,3:-2,2:-4` | 15 | 3 / 2 | 2 | 1.33 | 11.5 | 10 | 0.97 | 21 | 67% | 0% |
| 69 | pent | 0 y, 1 g, 2 m, 3 r, 4 w | `4:-2,2:-4,0:-5,3:-2,1:-5,2:-3,0:-4,1:+4,0:+5,1:-3,0:-2,3:+3,2:-2,1:-2,3:-4` | 15 | 2 / 2 | 3 | 1.73 | 4.1 | 10 | 0.98 | 27 | 68% | 10% |
| 70 | hex | 0 r, 1 c, 2 r, 3 c, 4 c, 5 c, 6 w | `6:-5,4:+3,5:-4,2:-5,0:+3,1:+4,2:-4,4:+3,3:+5,0:+3,4:+5,5:+4,3:-4,2:-3,0:+3,4:-4` | 16 | 3 / 1 | 4 | 2.13 | 3.1 | 9 | 0.53 | 30 | 68% | 0% |
| 71 | pent | 0 w, 1 g, 2 g, 3 m, 4 g | `0:-3,3:+5,4:+4,1:+5,2:-4,1:-3,2:-2,1:+5,2:+2,1:-5,2:-3,1:-4,2:-4,1:-4,2:-4,1:-4` | 16 | 3 / 2 | 2 | 1.31 | 12.5 | 11 | 0.95 | 22 | 68% | 0% |
| 72 | hex | 0 b, 1 y, 2 w, 3 b, 4 y, 5 b, 6 y | `2:+3,3:+2,5:+5,4:-3,0:-4,1:-5,5:+3,0:+3,5:-5,3:+2,6:-5,0:+4,3:-5,1:-3,6:+5,0:+3,5:-4` | 17 | 3 / 1 | 4 | 1.87 | 5.8 | 10 | 0.58 | 27 | 70% | 0% |

### Tray 13: Separations, on the beetles

Depth 15 to 18: pairs, red with cyan and green with magenta, every ink read as its two primaries.

| # | Layout | Masks | Scramble | Depth | Free (masks / white) | Blocked | Right/step | Forced | Sums | Least read | Cost | Ghost | Triple |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 73 | eye | 0 w, 1 r, 2 r, 3 c | `0:+5,1:+2,3:-2,2:+3,1:+3,2:+2,1:+3,2:+5,1:-5,2:-3,1:-2,2:+5,1:+2,2:-5,1:+2` | 15 | 2 / 1 | 2 | 1.13 | 13.0 | 11 | 0.80 | 21 | 60% | 0% |
| 74 | pent | 0 m, 1 w, 2 g, 3 g, 4 m | `1:-2,3:-4,2:+4,3:+3,4:-5,0:+4,2:-2,3:-3,4:+2,2:-5,3:+5,2:+5,3:+3,0:+5,2:-2,4:-2` | 16 | 2 / 2 | 3 | 1.67 | 5.3 | 11 | 0.97 | 26 | 55% | 0% |
| 75 | pent | 0 b, 1 y, 2 b, 3 w, 4 b | `3:+4,1:+3,2:-3,4:-2,0:-5,4:-4,0:+5,4:-2,0:+4,4:-5,0:+4,4:-5,0:-2,4:+3,0:+5,4:+2` | 16 | 3 / 2 | 2 | 1.31 | 12.5 | 11 | 0.95 | 22 | 68% | 0% |
| 76 | hex | 0 r, 1 r, 2 r, 3 c, 4 r, 5 r, 6 w | `6:-2,2:-5,5:+5,4:+5,5:+3,4:+5,0:-2,3:-4,1:-2,2:+2,5:+5,4:-5,0:-4,5:+2,4:-3,1:-2,2:+3` | 17 | 3 / 2 | 4 | 1.60 | 8.7 | 10 | 0.53 | 23 | 73% | 0% |
| 77 | pent | 0 r, 1 r, 2 c, 3 r, 4 w | `4:-4,0:+4,3:+2,2:-4,1:-4,0:+4,1:-3,0:-3,1:+3,0:+2,1:-3,0:+4,1:-5,0:-3,1:+5,0:-5,1:+2` | 17 | 3 / 1 | 2 | 1.29 | 13.5 | 12 | 0.95 | 23 | 67% | 0% |
| 78 | pent | 0 g, 1 g, 2 m, 3 w, 4 g | `3:-3,2:-5,1:-3,4:-5,0:-5,4:+4,0:-4,4:-5,0:+2,4:-4,0:+4,1:+2,0:-5,4:-2,1:+4,0:+5,4:+5,0:-2` | 18 | 2 / 1 | 3 | 1.25 | 13.5 | 13 | 0.95 | 24 | 68% | 0% |

### Tray 14: Interference, on the seahorses

Depth 16 to 19, all on pent but one: the longest lines read by sums, nearly every move on a rod still holding another stir.

| # | Layout | Masks | Scramble | Depth | Free (masks / white) | Blocked | Right/step | Forced | Sums | Least read | Cost | Ghost | Triple |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 79 | pent | 0 b, 1 y, 2 w, 3 y, 4 b | `2:-5,0:-2,1:+3,4:+3,0:-2,4:+5,3:-2,0:-5,4:-5,0:-5,4:+3,0:+2,4:-4,0:+5,4:+2,0:-4` | 16 | 3 / 1 | 2 | 1.44 | 10.5 | 11 | 0.97 | 23 | 67% | 0% |
| 80 | pent | 0 r, 1 r, 2 w, 3 r, 4 c | `2:+2,0:+5,4:-3,1:+4,0:+4,1:+5,0:-3,3:-3,1:+2,0:+3,1:-3,0:+5,1:-2,0:+4,1:+2,0:+2,1:-5` | 17 | 3 / 2 | 2 | 1.35 | 12.5 | 12 | 0.97 | 23 | 67% | 0% |
| 81 | pent | 0 g, 1 m, 2 g, 3 g, 4 w | `4:-4,0:+2,3:-5,1:-4,2:+4,3:-2,2:+4,3:+2,2:+3,3:+4,2:-3,3:-4,2:-5,3:-2,2:+4,3:-3,2:-3` | 17 | 3 / 1 | 2 | 1.29 | 13.5 | 12 | 0.95 | 23 | 67% | 0% |
| 82 | pent | 0 g, 1 w, 2 g, 3 m, 4 g | `1:-5,3:+4,2:-5,0:+2,4:+4,0:+3,4:+3,0:-2,4:-4,0:+3,4:-4,0:+2,4:+3,0:+4,4:+2,0:-3,4:-3,0:-4` | 18 | 3 / 2 | 2 | 1.28 | 14.5 | 13 | 0.95 | 24 | 67% | 0% |
| 83 | pent | 0 g, 1 w, 2 g, 3 g, 4 m | `1:-4,2:-5,0:-5,4:-5,3:-2,2:-3,3:-2,2:-4,3:-2,2:+3,3:+5,2:+3,3:-5,2:-4,3:-4,2:+5,3:-5,2:-4` | 18 | 3 / 1 | 2 | 1.28 | 14.5 | 13 | 0.95 | 24 | 68% | 0% |
| 84 | pent | 0 y, 1 b, 2 b, 3 w, 4 b | `3:+3,2:+5,4:-5,0:-3,1:-4,2:-5,1:+5,2:-4,1:-4,2:-5,1:+5,2:-5,1:+3,2:+5,1:+5,2:+4,1:+5,2:-3,1:+4` | 19 | 3 / 1 | 2 | 1.26 | 15.5 | 14 | 0.95 | 25 | 68% | 0% |

### Tray 15: Full Spectrum, on the octopus

Depth 17 to 20, the pack's deepest.

| # | Layout | Masks | Scramble | Depth | Free (masks / white) | Blocked | Right/step | Forced | Sums | Least read | Cost | Ghost | Triple |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 85 | pent | 0 g, 1 g, 2 m, 3 w, 4 m | `3:-3,4:-3,0:+3,1:-2,2:+3,0:+4,1:-5,0:-2,1:-5,0:-3,1:+3,0:+4,1:-2,0:-3,1:-2,0:-2,1:+2` | 17 | 3 / 1 | 2 | 1.41 | 11.5 | 12 | 0.97 | 24 | 67% | 0% |
| 86 | pent | 0 c, 1 r, 2 w, 3 r, 4 r | `2:+3,4:+2,3:-3,0:+4,1:+3,4:-5,3:-5,4:-5,3:-3,4:-4,3:+5,4:+3,3:-2,4:+3,3:-4,4:+2,3:-2,4:+5` | 18 | 3 / 2 | 2 | 1.33 | 13.5 | 13 | 0.97 | 24 | 67% | 0% |
| 87 | pent | 0 w, 1 r, 2 r, 3 c, 4 r | `0:-5,2:-3,3:-5,1:+5,4:+3,2:+2,1:+3,2:+4,1:+5,2:-2,1:+3,2:-5,1:+2,2:+3,1:-4,2:+3,1:-3,2:-2` | 18 | 3 / 2 | 2 | 1.33 | 13.5 | 13 | 0.97 | 24 | 57% | 0% |
| 88 | pent | 0 b, 1 y, 2 w, 3 b, 4 b | `2:+5,0:+4,4:+5,3:-5,4:+4,3:+4,0:-2,1:-3,4:-5,3:-5,4:-3,0:-4,3:-5,4:+5,0:+3,4:+4,0:-5,3:+3,4:-2` | 19 | 2 / 1 | 3 | 1.36 | 12.7 | 14 | 0.97 | 25 | 68% | 0% |
| 89 | pent | 0 m, 1 g, 2 g, 3 m, 4 w | `4:+3,3:+5,0:-2,1:+5,2:-2,1:-3,2:-4,1:-2,2:+4,1:+5,2:+2,1:+4,2:+5,1:-2,2:-5,1:-3,2:-5,1:-2,2:-2` | 19 | 3 / 1 | 2 | 1.37 | 13.5 | 14 | 0.95 | 26 | 67% | 0% |
| 90 | pent | 0 w, 1 r, 2 r, 3 r, 4 c | `0:+2,4:+2,1:+3,2:-3,1:+4,3:-5,2:+2,1:+2,3:-5,2:-5,3:-4,1:-3,2:+5,1:+5,3:-5,2:-2,3:-2,2:-2,1:+3,2:-2` | 20 | 2 / 1 | 3 | 1.30 | 14.0 | 15 | 0.95 | 26 | 68% | 0% |

