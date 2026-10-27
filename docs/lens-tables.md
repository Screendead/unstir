# Lens: the two level tables

Built 2026-10-27 for Jack's open question from the first phone session: lenses on rods of every size (table A, branch
`lens-levels-all`), or only on big rods, radius 0.58, which are tri's three and eye's two (table B, branch
`lens-levels-big`). Each is a complete 25-level set on `master`'s machinery, on the halftone test panel; the panels'
art (`docs/lens-design.md` section 1) is not drawn. Neither is decided.

Both tables follow `docs/lens-design.md` section 2's rules and teaching curve: four issues of six and a splash page,
the free taste (1 to 3) on tri as `master` has it, depth climbing from 1 to 12. A positive step magnifies and is a
drag up, as on `master` and in the draft, so the draft's strings keep their sign: a dealt lens is undone dragging down.
Each dealt lens entry is +1 to +3 (x2, x4, x8 at the centre), and each lens rod nets at most +3. Every twist dealt
over a lens drags its rim at least 4 dot pitches: any step on tri and hex, 2 or more of a small twist over a big lens
on eye, 3 or more on quad. No entry merges as it is dealt, so the depth is the string's length.

**Par is the depth on every row, and it is the solver's optimum** (`scripts/solve.sh`, which knows lenses): no detour
beats untwisting on any row. `scripts/lens-table.py docs/lens-tables.md --solve` checks every rule above and the
optimum, row by row; `testLensLevels` pins the table on its own branch and replays untwisting on a real game.

"Free" is how many entries can come off at the start.

## Table A: lenses on every rod size (`lens-levels-all`)

The draft table of `docs/lens-design.md` section 2 unchanged: every row already met the rules at x2, and the solver's
optimum is the depth on all 25. Its lenses sit on tri and eye's big rods (0.58), quad's (0.48), and eye's small rods
and every hex rod (0.44).

| # | Issue | Layout | Lens rods | Scramble | Depth | Free | What it adds | Par |
|---|---|---|---|---|---|---|---|---|
| 1 | Close-up | tri | 0 | `0:+2` | 1 | 1 | The ringed knob: up swells the dots, down brings them back to the screen's pitch, and the rim goes at 0 | 1 |
| 2 | Close-up | tri | 0 | `0:+1,1:+3` | 2 | 1 | A broken rim: the twist is on top. Untwist, the rim comes whole, then shrink; the faintest step, +1 | 2 |
| 3 | Close-up | tri | 0 | `1:-2,2:+4,0:+3` | 3 | 1 | A whole rim over twists, their lines cut dead at it: the lens first, and +3 to count by the dots | 3 |
| 4 | Close-up | tri | 1 | `0:+3,1:+2,2:-4,1:+1` | 4 | 1 | One lens twice, a twist between: two separate entries | 4 |
| 5 | Close-up | eye | 2 | `0:-4,2:+2,1:+5,3:-3` | 4 | 1 | Mixed sizes; a twist whose disc misses the lens | 4 |
| 6 | Close-up | eye | 0 | `2:+3,0:+2,1:-4,3:+5,0:+1` | 5 | 1 | A big lens under both kinds of neighbour | 5 |
| 7 | Cut-in | tri | 0, 1 | `2:+4,0:+2,1:+1` | 3 | 2 | Two whole rims at once: lenses never meet, so either first | 3 |
| 8 | Cut-in | quad | 0, 2 | `1:+4,0:+2,3:-3,2:+3,1:-5,0:+1` | 6 | 1 | Quad's grazing discs, with twists of 3 or more over each lens | 6 |
| 9 | Cut-in | eye | 2, 3 | `0:+3,2:+2,1:-4,3:+3,0:+2,2:+1` | 6 | 1 | Two small lenses under the big twists | 6 |
| 10 | Cut-in | tri | 2 | `0:+3,2:+2,1:-5,0:-2,2:+1,1:+4` | 6 | 1 | A long tri, one lens netting +3 | 6 |
| 11 | Cut-in | quad | 1, 3 | `0:+3,1:+3,2:-4,3:+2,0:-3,3:+1,2:+5` | 7 | 1 |  | 7 |
| 12 | Cut-in | eye | 0, 1 | `2:+3,0:+2,3:-4,1:+3,2:-2,0:+1,3:+5` | 7 | 1 | Both big discs lenses, read only through the small twists | 7 |
| 13 | Double-take | hex | 1, 4 | `0:+3,1:+2,2:-4,4:+3,6:+2,0:-2,5:+4` | 7 | 1 | Hex: the hub twist reaches every lens | 7 |
| 14 | Double-take | hex | 2, 5 | `3:-3,2:+2,0:+4,5:+1,6:-3,2:+1,4:+5,5:+2` | 8 | 2 |  | 8 |
| 15 | Double-take | eye | 2 | `1:+4,2:+1,0:-5,3:+3,2:+2,1:-3,0:+4,3:-2` | 8 | 1 |  | 8 |
| 16 | Double-take | tri | 0 | `1:+3,0:+1,2:-4,1:-2,0:+1,2:+5,1:+4,0:+1` | 8 | 1 | One lens in three entries of +1, each read from the faintest step | 8 |
| 17 | Double-take | hex | 1, 3, 5 | `0:+2,1:+3,2:-4,3:+2,4:+3,5:+1,6:-5,0:+4,5:+2` | 9 | 1 | Every other ring rod a lens | 9 |
| 18 | Double-take | quad | 0, 2 | `1:+3,0:+1,3:-4,2:+2,1:+5,0:+2,3:+3,2:+1,1:-4` | 9 | 1 |  | 9 |
| 19 | Splash | hex | 0 | `1:+3,0:+2,4:-3,2:+4,0:+1,5:-3,3:+2,6:+4` | 8 | 2 | The hub a lens: every ring twist breaks its rim | 8 |
| 20 | Splash | hex | 0, 1, 4 | `2:+3,0:+2,1:+3,5:-4,4:+2,3:+4,0:+1,6:-3,2:-2` | 9 | 2 | Hub and ring lenses together | 9 |
| 21 | Splash | eye | 0, 3 | `2:+4,0:+2,1:-5,3:+2,2:-3,0:+1,1:+4,3:+1,2:+3` | 9 | 2 |  | 9 |
| 22 | Splash | hex | 0, 2, 5 | `1:+3,0:+1,2:+2,3:-4,6:+5,5:+3,4:-3,0:+2,1:-3,2:+1` | 10 | 1 |  | 10 |
| 23 | Splash | hex | 0 | `3:+4,0:+1,6:-3,1:+5,0:+1,2:-4,4:+3,0:+1,5:-5,3:+2` | 10 | 2 | The hub in three entries | 10 |
| 24 | Splash | eye | 2, 3 | `0:+4,2:+2,1:-3,3:+1,0:-4,3:+2,1:+5,2:+1,0:+3,1:-2` | 10 | 1 |  | 10 |
| 25 | Splash page | hex | 0, 1, 3, 5 | `2:+3,0:+1,1:+2,4:-4,3:+3,6:+3,0:+1,5:+2,2:-5,1:+1,4:+4,0:+1` | 12 | 2 | Four lenses, seven of the twelve entries | 12 |

## Table A capped at +2 (`lens-levels-cap2`)

The glitter check at x2 (2026-10-27, simulator stills at the screen's own pixels): at +3 the band just inside a lens's
rim squashes the dots to stripes finer than a pixel, a band a few points wide that shimmers as the lens or a
neighbour's twist moves; at +2 the dots there still read as slivers. This is table A with every dealt lens entry +1 or
+2 and each lens netting at most +2 (x4 at the centre at most), the rows recomposed only where a +3 forced it, at the
same depths. Level 3 teaches counting by +2, not +3. The same cap would apply to table B.

| # | Issue | Layout | Lens rods | Scramble | Depth | Free | Par |
|---|---|---|---|---|---|---|---|
| 1 | Close-up | tri | 0 | `0:+2` | 1 | 1 | 1 |
| 2 | Close-up | tri | 0 | `0:+1,1:+3` | 2 | 1 | 2 |
| 3 | Close-up | tri | 0 | `1:-2,2:+4,0:+2` | 3 | 1 | 3 |
| 4 | Close-up | tri | 1 | `0:+3,1:+1,2:-4,1:+1` | 4 | 1 | 4 |
| 5 | Close-up | eye | 2 | `0:-4,2:+2,1:+5,3:-3` | 4 | 1 | 4 |
| 6 | Close-up | eye | 0 | `2:+3,0:+1,1:-4,3:+5,0:+1` | 5 | 1 | 5 |
| 7 | Cut-in | tri | 0, 1 | `2:+4,0:+2,1:+1` | 3 | 2 | 3 |
| 8 | Cut-in | quad | 0, 2 | `1:+4,0:+1,3:-3,2:+2,1:-5,0:+1` | 6 | 1 | 6 |
| 9 | Cut-in | eye | 2, 3 | `0:+3,2:+1,1:-4,3:+2,0:+2,2:+1` | 6 | 1 | 6 |
| 10 | Cut-in | tri | 2 | `0:+3,2:+1,1:-5,0:-2,2:+1,1:+4` | 6 | 1 | 6 |
| 11 | Cut-in | quad | 1, 3 | `0:+3,1:+2,2:-4,3:+1,0:-3,3:+1,2:+5` | 7 | 1 | 7 |
| 12 | Cut-in | eye | 0, 1 | `2:+3,0:+1,3:-4,1:+2,2:-2,0:+1,3:+5` | 7 | 1 | 7 |
| 13 | Double-take | hex | 1, 4 | `0:+3,1:+2,2:-4,4:+2,6:+2,0:-2,5:+4` | 7 | 1 | 7 |
| 14 | Double-take | hex | 2, 5 | `3:-3,2:+1,0:+4,5:+1,6:-3,2:+1,4:+5,5:+1` | 8 | 2 | 8 |
| 15 | Double-take | eye | 2 | `1:+4,2:+1,0:-5,3:+3,2:+1,1:-3,0:+4,3:-2` | 8 | 1 | 8 |
| 16 | Double-take | tri | 0 | `1:+3,0:+1,2:-4,1:-2,0:+1,2:+5,1:+4,2:-3` | 8 | 1 | 8 |
| 17 | Double-take | hex | 1, 3, 5 | `0:+2,1:+2,2:-4,3:+2,4:+3,5:+1,6:-5,0:+4,5:+1` | 9 | 1 | 9 |
| 18 | Double-take | quad | 0, 2 | `1:+3,0:+1,3:-4,2:+1,1:+5,0:+1,3:+3,2:+1,1:-4` | 9 | 1 | 9 |
| 19 | Splash | hex | 0 | `1:+3,0:+1,4:-3,2:+4,0:+1,5:-3,3:+2,6:+4` | 8 | 2 | 8 |
| 20 | Splash | hex | 0, 1, 4 | `2:+3,0:+1,1:+2,5:-4,4:+2,3:+4,0:+1,6:-3,2:-2` | 9 | 2 | 9 |
| 21 | Splash | eye | 0, 3 | `2:+4,0:+1,1:-5,3:+1,2:-3,0:+1,1:+4,3:+1,2:+3` | 9 | 2 | 9 |
| 22 | Splash | hex | 0, 2, 5 | `1:+3,0:+1,2:+1,3:-4,6:+5,5:+2,4:-3,0:+1,1:-3,2:+1` | 10 | 1 | 10 |
| 23 | Splash | hex | 0 | `3:+4,0:+1,6:-3,1:+5,0:+1,2:-4,4:+3,5:-5,3:+2,1:-2` | 10 | 3 | 10 |
| 24 | Splash | eye | 2, 3 | `0:+4,2:+1,1:-3,3:+1,0:-4,3:+1,1:+5,2:+1,0:+3,1:-2` | 10 | 1 | 10 |
| 25 | Splash page | hex | 0, 1, 3, 5 | `2:+3,0:+1,1:+1,4:-4,3:+1,6:+3,0:+1,5:+2,2:-5,1:+1,4:+4,3:+1` | 12 | 2 | 12 |

## Table B: lenses on big rods only (`lens-levels-big`)

Only tri and eye have big rods, so every level is on one of them: 11 on tri, 14 on eye. The draft's big-rod rows stay
(1 to 4, 6, 7, 10, 12, 16); the rest, its quad and hex rows and its eye rows with small lenses, are recomposed on tri
and eye with their lenses on the big rods, at the draft's depth for the slot. Two things go with quad and hex: hex's
hub lens (under all six ring twists, the draft's splash) and three or four lenses in one level (tri and eye have
room for two). On eye with both big rods lenses, the small rods are the only twists and never meet each other, so
those levels alternate between the pairs.

| # | Issue | Layout | Lens rods | Scramble | Depth | Free | What it adds | Par |
|---|---|---|---|---|---|---|---|---|
| 1 | Close-up | tri | 0 | `0:+2` | 1 | 1 | The knob and the dot ruler: up swells the dots, down brings them back | 1 |
| 2 | Close-up | tri | 0 | `0:+1,1:+3` | 2 | 1 | A broken rim: the twist is on top | 2 |
| 3 | Close-up | tri | 0 | `1:-2,2:+4,0:+3` | 3 | 1 | A whole rim over twists: the lens first, and +3 to count by the dots | 3 |
| 4 | Close-up | tri | 1 | `0:+3,1:+2,2:-4,1:+1` | 4 | 1 | One lens twice, a twist between | 4 |
| 5 | Close-up | eye | 0 | `2:-4,0:+2,1:+5,3:-3` | 4 | 1 | Eye: a big lens under the other big twist and both small ones | 4 |
| 6 | Close-up | eye | 0 | `2:+3,0:+2,1:-4,3:+5,0:+1` | 5 | 1 | A big lens under both kinds of neighbour | 5 |
| 7 | Cut-in | tri | 0, 1 | `2:+4,0:+2,1:+1` | 3 | 2 | Two whole rims at once: lenses never meet, so either first | 3 |
| 8 | Cut-in | eye | 1 | `0:+4,1:+2,2:-3,3:+3,1:+1,0:-5` | 6 | 1 | The right big rod a lens, twice | 6 |
| 9 | Cut-in | eye | 0, 1 | `2:+3,0:+2,3:-4,1:+1,2:+2,0:+1` | 6 | 1 | Both big rods lenses, read only through the small twists | 6 |
| 10 | Cut-in | tri | 2 | `0:+3,2:+2,1:-5,0:-2,2:+1,1:+4` | 6 | 1 | A long tri, one lens netting +3 | 6 |
| 11 | Cut-in | tri | 1, 2 | `0:+3,1:+2,2:+1,0:-4,2:+2,1:+1,0:+5` | 7 | 1 | Two lenses on tri, one twist rod between them | 7 |
| 12 | Cut-in | eye | 0, 1 | `2:+3,0:+2,3:-4,1:+3,2:-2,0:+1,3:+5` | 7 | 1 | Both big rods lenses, seven deep | 7 |
| 13 | Double-take | tri | 0 | `2:+3,0:+1,1:-4,2:+5,0:+2,1:+3,2:-2` | 7 | 1 |  | 7 |
| 14 | Double-take | eye | 0 | `1:+3,0:+2,2:-3,3:+4,1:-5,0:+1,2:+2,3:-2` | 8 | 2 |  | 8 |
| 15 | Double-take | eye | 1 | `0:-4,1:+1,3:+3,2:-2,0:+5,1:+2,3:-3,2:+4` | 8 | 2 |  | 8 |
| 16 | Double-take | tri | 0 | `1:+3,0:+1,2:-4,1:-2,0:+1,2:+5,1:+4,0:+1` | 8 | 1 | One lens in three entries of +1 | 8 |
| 17 | Double-take | eye | 0, 1 | `2:+4,0:+1,1:+2,3:-3,0:+2,2:-2,1:+1,3:+5,2:+3` | 9 | 2 |  | 9 |
| 18 | Double-take | tri | 0, 2 | `1:+3,0:+2,2:+1,1:-4,2:+1,1:+2,0:+1,1:-5,2:+1` | 9 | 1 | Two lenses on tri, five lens entries | 9 |
| 19 | Splash | tri | 1 | `0:+4,1:+2,2:-3,0:+2,2:-5,1:+1,0:-3,2:+4` | 8 | 1 |  | 8 |
| 20 | Splash | eye | 0, 1 | `3:+4,1:+2,2:-3,0:+2,3:-2,1:+1,2:+5,0:+1,3:+3` | 9 | 1 |  | 9 |
| 21 | Splash | eye | 0 | `1:+4,0:+2,2:-5,3:+2,1:-3,0:+1,3:+3,2:+4,1:+2` | 9 | 1 |  | 9 |
| 22 | Splash | tri | 0, 1 | `2:+3,0:+1,2:-4,1:+1,2:+5,0:+1,2:-2,1:+2,2:+4,0:+1` | 10 | 1 | Two lenses on tri, ten deep | 10 |
| 23 | Splash | eye | 1 | `0:+3,1:+1,2:-3,3:+4,1:+1,0:-5,2:+2,1:+1,3:-2,0:+4` | 10 | 1 | One lens in three entries of +1 | 10 |
| 24 | Splash | eye | 0, 1 | `2:+4,0:+2,3:-3,1:+1,2:-2,0:+1,3:+5,1:+2,2:+3,3:-4` | 10 | 2 |  | 10 |
| 25 | Splash page | eye | 0, 1 | `3:+3,0:+1,2:-4,1:+1,3:+2,0:+1,2:+5,1:+1,3:-3,0:+1,2:+2,1:+1` | 12 | 1 | Both big rods lenses, twelve deep: six lens entries | 12 |
