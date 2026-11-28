# Lens: the two level tables

Built 2026-10-27 for Jack's open question from the first phone session: lenses on rods of every size (table A, branch
`lens-levels-all`), or only on big rods, radius 0.58, which are tri's three and eye's two (table B, branch
`lens-levels-big`). Each is a complete 25-level set on `master`'s machinery, on the halftone test panel; the panels'
art (`docs/lens-design.md` section 1) is not drawn. Neither is decided.

Since then table A is the pack's (`Level.lens`), and each level has its own panel, its name drawn (`LensArt*.swift`,
Jack's call LENSART = B, 2026-11-10) in place of section 1's story.

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

## Levels 26 to 75

Jack, 2026-11-27: at least treble the pack, ramping a little faster to a much higher top, harder to crack without
changing what the pack is. Rows 26 to 75 go on table A below; the first 25 stay as they were. The rules are table A's,
and one more the first 25 met without saying: every lens is reached by a twist. Each row is a deal that
`scripts/lens-levels.py pick` drew to `scripts/lens-levels/plan.tsv` and proved at par with `scripts/solve.sh`
(`scripts/lens-levels/picked.tsv` keeps its measures). `scripts/lens-levels.py table` measures any table's rows.

Depth climbs from 13 at 26 to 36 by 53, nearly twice the first 25's slope, and holds at 33 to 36 from there to 75:
past that a level is longer, not harder, and the free game's deepest is 26. Levels whose hub is a lens sit at 29 to
32, as one proof at par on them past that takes the solver twenty minutes and more (a hub lens reaches every twist, and
the detours the proof must rule out multiply). The rest of the climb is in how hard each
level is to crack. Without a seized knob the solver's planning measures are flat on Lens (needs a plan no, planning
gap 0, no decoys, on all of the first 25: untwisting any whole entry first is always as good), so these are the
measures that move:

| Levels | Depth | Rods | Lens share | Buried | Stacked lenses | Faint twists | Lens steps of 2 or 3 | Right moves a step | Forced steps |
|---|---|---|---|---|---|---|---|---|---|
| 1–6 Close-up | 1–5 | 3.3 | 0.42 | 0.50 | 0.3 | 0.00 | 0.62 | 1.00 | 1.00 |
| 7–12 Cut-in | 3–7 | 3.3 | 0.49 | 0.76 | 1.0 | 0.00 | 0.59 | 1.10 | 0.90 |
| 13–18 Double-take | 7–9 | 5.2 | 0.41 | 0.75 | 1.2 | 0.00 | 0.45 | 1.19 | 0.85 |
| 19–25 Big Picture | 8–12 | 6.1 | 0.43 | 0.86 | 1.6 | 0.00 | 0.48 | 1.30 | 0.71 |
| 26–31 Wide shot | 13–18 | 4.8 | 0.30 | 1.00 | 2.0 | 0.05 | 0.29 | 1.01 | 0.98 |
| 32–37 Long take | 19–24 | 5.5 | 0.27 | 1.00 | 2.3 | 0.19 | 0.20 | 1.03 | 0.97 |
| 38–43 Jump cut | 24–29 | 6.5 | 0.25 | 0.95 | 2.8 | 0.20 | 0.28 | 1.00 | 1.00 |
| 44–49 Freeze frame | 29–34 | 7.0 | 0.26 | 0.98 | 3.3 | 0.27 | 0.08 | 1.00 | 1.00 |
| 50–55 Split screen | 30–36 | 7.0 | 0.32 | 1.00 | 4.5 | 0.30 | 0.12 | 1.00 | 1.00 |
| 56–61 Slow motion | 30–36 | 7.0 | 0.29 | 0.95 | 4.3 | 0.37 | 0.14 | 1.00 | 1.00 |
| 62–67 Dolly zoom | 31–35 | 7.0 | 0.29 | 0.98 | 4.3 | 0.39 | 0.12 | 1.00 | 1.00 |
| 68–75 Final cut | 31–36 | 7.0 | 0.30 | 0.94 | 4.6 | 0.41 | 0.21 | 1.00 | 1.00 |

Lens share is lens entries over depth; buried, lens entries dealt under a twist that reaches the lens (a broken rim);
stacked, lenses holding two or more entries, so the zoom shows their sum; faint twists, twists of one step, the least
a turn shows; lens steps of 2 or 3, the lens entries a player undoes by counting the zoom rather than one step down;
right moves, the whole entries at each step of the untwist on average, one being a forced read among every rod.

## Table A: lenses on every rod size (`lens-levels-all`)


The draft table of `docs/lens-design.md` section 2, every row of which already met the rules at x2, but for rows 8, 11
and 18: the draft dealt them on quad (`1:+4,0:+2,3:-3,2:+3,1:-5,0:+1` with lenses 0 and 2, `0:+3,1:+3,2:-4,3:+2,0:-3,3:+1,2:+5`
with 1 and 3, `1:+3,0:+1,3:-4,2:+2,1:+5,0:+2,3:+3,2:+1,1:-4` with 0 and 2), where a neighbour's disc reaches too little of
a lens's rim for the order to read (16% of the band round it, against 18 to 22% on eye and 29% on tri). All three are
on tri at the same depths: 8 keeps its entries, its two twisting rods folded into rod 1 (table B's row 8, on eye, opens
on a big twist over a lens at +1, which read weakly), and 11 and 18 take table B's rows. The solver's optimum is the
depth on all 25. Its lenses sit on
tri and eye's big rods (0.58), and eye's small rods and every hex rod (0.44); no level is on quad.

| # | Issue | Layout | Lens rods | Scramble | Depth | Free | What it adds | Par |
|---|---|---|---|---|---|---|---|---|
| 1 | Close-up | tri | 0 | `0:+2` | 1 | 1 | The ringed knob: up swells the dots, down brings them back to the screen's pitch, and the rim goes at 0 | 1 |
| 2 | Close-up | tri | 0 | `0:+1,1:+3` | 2 | 1 | A broken rim: the twist is on top. Untwist, the rim comes whole, then shrink; the faintest step, +1 | 2 |
| 3 | Close-up | tri | 0 | `1:-2,2:+4,0:+3` | 3 | 1 | A whole rim over twists, their lines cut dead at it: the lens first, and +3 to count by the dots | 3 |
| 4 | Close-up | tri | 1 | `0:+3,1:+2,2:-4,1:+1` | 4 | 1 | One lens twice, a twist between: two separate entries | 4 |
| 5 | Close-up | eye | 2 | `0:-4,2:+2,1:+5,3:-3` | 4 | 1 | Mixed sizes; a twist whose disc misses the lens | 4 |
| 6 | Close-up | eye | 0 | `2:+3,0:+2,1:-4,3:+5,0:+1` | 5 | 1 | A big lens under both kinds of neighbour | 5 |
| 7 | Cut-in | tri | 0, 1 | `2:+4,0:+2,1:+1` | 3 | 2 | Two whole rims at once: lenses never meet, so either first | 3 |
| 8 | Cut-in | tri | 0, 2 | `1:+4,0:+2,1:-3,2:+3,1:-5,0:+1` | 6 | 1 | Two lenses under tri's one twist rod, a faint +1 dealt last over it | 6 |
| 9 | Cut-in | eye | 2, 3 | `0:+3,2:+2,1:-4,3:+3,0:+2,2:+1` | 6 | 1 | Two small lenses under the big twists | 6 |
| 10 | Cut-in | tri | 2 | `0:+3,2:+2,1:-5,0:-2,2:+1,1:+4` | 6 | 1 | A long tri, one lens netting +3 | 6 |
| 11 | Cut-in | tri | 1, 2 | `0:+3,1:+2,2:+1,0:-4,2:+2,1:+1,0:+5` | 7 | 1 | Two lenses on tri, one twist rod between them | 7 |
| 12 | Cut-in | eye | 0, 1 | `2:+3,0:+2,3:-4,1:+3,2:-2,0:+1,3:+5` | 7 | 1 | Both big discs lenses, read only through the small twists | 7 |
| 13 | Double-take | hex | 1, 4 | `0:+3,1:+2,2:-4,4:+3,6:+2,0:-2,5:+4` | 7 | 1 | Hex: the hub twist reaches every lens | 7 |
| 14 | Double-take | hex | 2, 5 | `3:-3,2:+2,0:+4,5:+1,6:-3,2:+1,4:+5,5:+2` | 8 | 2 |  | 8 |
| 15 | Double-take | eye | 2 | `1:+4,2:+1,0:-5,3:+3,2:+2,1:-3,0:+4,3:-2` | 8 | 1 |  | 8 |
| 16 | Double-take | tri | 0 | `1:+3,0:+1,2:-4,1:-2,0:+1,2:+5,1:+4,0:+1` | 8 | 1 | One lens in three entries of +1, each read from the faintest step | 8 |
| 17 | Double-take | hex | 1, 3, 5 | `0:+2,1:+3,2:-4,3:+2,4:+3,5:+1,6:-5,0:+4,5:+2` | 9 | 1 | Every other ring rod a lens | 9 |
| 18 | Double-take | tri | 0, 2 | `1:+3,0:+2,2:+1,1:-4,2:+1,1:+2,0:+1,1:-5,2:+1` | 9 | 1 | Two lenses on tri, five lens entries | 9 |
| 19 | Splash | hex | 0 | `1:+3,0:+2,4:-3,2:+4,0:+1,5:-3,3:+2,6:+4` | 8 | 2 | The hub a lens: every ring twist breaks its rim | 8 |
| 20 | Splash | hex | 0, 1, 4 | `2:+3,0:+2,1:+3,5:-4,4:+2,3:+4,0:+1,6:-3,2:-2` | 9 | 2 | Hub and ring lenses together | 9 |
| 21 | Splash | eye | 0, 3 | `2:+4,0:+2,1:-5,3:+2,2:-3,0:+1,1:+4,3:+1,2:+3` | 9 | 2 |  | 9 |
| 22 | Splash | hex | 0, 2, 5 | `1:+3,0:+1,2:+2,3:-4,6:+5,5:+3,4:-3,0:+2,1:-3,2:+1` | 10 | 1 |  | 10 |
| 23 | Splash | hex | 0 | `3:+4,0:+1,6:-3,1:+5,0:+1,2:-4,4:+3,0:+1,5:-5,3:+2` | 10 | 2 | The hub in three entries | 10 |
| 24 | Splash | eye | 2, 3 | `0:+4,2:+2,1:-3,3:+1,0:-4,3:+2,1:+5,2:+1,0:+3,1:-2` | 10 | 1 |  | 10 |
| 25 | Splash page | hex | 0, 1, 3, 5 | `2:+3,0:+1,1:+2,4:-4,3:+3,6:+3,0:+1,5:+2,2:-5,1:+1,4:+4,0:+1` | 12 | 2 | Four lenses, seven of the twelve entries | 12 |
| 26 | Wide shot | tri | 0, 2 | `1:+3,2:+1,1:+4,2:+1,1:-3,2:+1,1:-2,0:+1,1:-5,0:+1,1:+1,0:+1,1:-5` | 13 | 1 |  | 13 |
| 27 | Wide shot | eye | 2, 3 | `0:-4,2:+1,0:-5,1:+2,3:+2,1:+4,0:+4,2:+2,1:+3,3:+1,0:-3,1:+2,0:+3,1:-4` | 14 | 1 |  | 14 |
| 28 | Wide shot | hex | 1, 4 | `0:-5,4:+1,3:+3,2:-4,0:+3,3:+2,0:+4,1:+1,6:-5,5:+2,4:+2,3:-4,2:+5,1:+2,0:-2` | 15 | 1 |  | 15 |
| 29 | Wide shot | eye | 0, 2 | `3:-3,1:-5,2:+1,3:-2,0:+1,1:+5,3:+5,1:+4,2:+2,1:-3,3:+3,1:+5,3:+2,1:+3,0:+2,3:+2` | 16 | 1 |  | 16 |
| 30 | Wide shot | hex | 0, 3 | `2:+5,1:-2,0:+1,1:+3,0:+1,1:-4,6:-1,5:-5,4:+5,3:+1,4:+5,3:+2,2:+5,1:-5,0:+1,6:-5,5:-5` | 17 | 1 |  | 17 |
| 31 | Wide shot | eye | 1, 3 | `3:+1,0:-4,2:-3,0:-3,1:+1,2:+5,0:-2,3:+2,0:-1,2:+5,1:+1,2:+3,0:-3,2:-4,0:+2,2:-4,1:+1,0:+3` | 18 | 1 |  | 18 |
| 32 | Long take | eye | 1, 2, 3 | `0:-5,1:+1,0:-4,2:+1,0:+5,2:+1,0:+4,1:+1,0:+5,3:+1,0:+1,3:+1,0:-4,3:+1,0:+5,2:+1,0:+1,1:+1,0:+1` | 19 | 1 |  | 19 |
| 33 | Long take | hex | 2, 6 | `2:+2,0:-2,2:+1,0:-4,1:-5,0:-3,5:+5,6:+1,1:-3,0:+2,5:+3,4:-1,5:-2,0:+2,6:+1,1:+3,6:+1,5:+5,0:-5,5:+4` | 20 | 1 |  | 20 |
| 34 | Long take | eye | 0, 3 | `2:-5,1:-3,3:+1,1:+1,2:-3,1:-2,3:+2,1:-2,2:+4,0:+1,2:-4,0:+1,1:-2,0:+1,1:-5,2:+2,1:+2,2:+2,1:+1,2:+5,1:+2` | 21 | 1 |  | 21 |
| 35 | Long take | hex | 3, 5 | `3:+1,2:+1,1:-2,2:+3,0:+1,2:-3,1:-5,4:-5,5:+1,4:+5,3:+1,2:+4,3:+1,4:+2,0:-1,4:-4,5:+2,6:-2,0:-3,1:+2,2:-2,0:-4` | 22 | 1 |  | 22 |
| 36 | Long take | eye | 2, 3 | `0:-3,1:+4,0:-5,2:+1,1:-3,0:-2,1:+5,0:-4,2:+2,0:+3,1:+1,3:+1,1:+2,0:-1,3:+1,0:+1,1:+3,0:-4,1:-1,3:+1,1:+2,0:+4,1:+1` | 23 | 1 |  | 23 |
| 37 | Long take | hex | 1, 3, 5 | `1:+1,0:-4,6:+2,4:+3,0:-3,2:-4,1:+2,2:-5,3:+1,0:-1,6:-3,5:+2,4:-3,0:-1,4:+3,0:+5,2:+4,0:+5,6:-1,5:+1,0:-2,2:+1,3:+2,4:+3` | 24 | 1 |  | 24 |
| 38 | Jump cut | eye | 1, 2 | `3:-4,1:+1,0:+2,3:+5,1:+1,3:+5,0:-4,3:+5,0:+1,1:+1,3:-4,0:-1,3:-4,0:+3,2:+2,0:+1,3:+4,0:+2,3:-4,0:+1,2:+1,0:-3,3:+2,0:-4` | 24 | 1 |  | 24 |
| 39 | Jump cut | hex | 0, 2, 5 | `5:+1,4:-5,5:+2,4:+2,3:+4,4:-5,3:-4,4:-4,3:+1,4:+2,3:-2,4:+4,3:+1,4:+1,3:+5,2:+1,1:-5,0:+2,3:-4,0:+1,1:+5,6:-5,1:-1,2:+1,1:+3,2:+1` | 26 | 1 |  | 26 |
| 40 | Jump cut | hex | 0, 1, 4 | `0:+1,3:+3,2:+3,3:+1,2:-1,3:+4,2:-2,3:-4,0:+2,5:+4,6:-2,5:+4,4:+1,3:+5,2:+5,1:+1,2:+3,3:+3,4:+1,5:-2,4:+1,5:+5,6:-2,5:+3,6:+1,1:+2,6:+2` | 27 | 1 |  | 27 |
| 41 | Jump cut | hex | 2, 4, 6 | `4:+2,3:+1,0:-3,1:-3,0:-1,2:+1,3:+3,2:+1,3:+5,0:-1,2:+1,3:+3,0:-4,1:+5,6:+1,1:-5,0:+3,3:+4,0:-3,4:+1,3:-4,0:-2,3:-2,0:-1,6:+2,1:-3,0:-1,5:+3` | 28 | 1 |  | 28 |
| 42 | Jump cut | hex | 1, 3, 6 | `5:+1,0:+4,3:+1,0:+5,2:-1,1:+1,2:+3,0:+1,5:-2,6:+1,5:+2,4:-1,0:-4,5:-4,0:+3,2:+3,0:+5,5:+3,6:+2,0:-1,5:-5,4:-4,3:+2,0:+3,1:+1,2:+4,1:+1,2:+4` | 28 | 1 |  | 28 |
| 43 | Jump cut | hex | 0, 3, 6 | `5:+5,4:-5,5:+3,4:+2,5:-3,4:-5,5:+4,4:-5,5:-4,4:-1,3:+1,4:-1,3:+2,4:-1,0:+2,5:+1,6:+1,5:+3,0:+1,5:-4,4:+3,5:+4,6:+1,1:-3,2:-2,1:+4,2:-5,1:-2,6:+1` | 29 | 1 |  | 29 |
| 44 | Freeze frame | hex | 1, 2, 4 | `2:+1,3:+4,4:+1,3:+3,2:+1,0:+5,6:+4,5:+5,6:+2,5:-5,0:-2,1:+1,6:-1,0:+4,3:-5,0:-1,3:-3,2:+1,3:+4,0:+3,4:+2,0:-1,3:-4,0:-2,3:+3,0:-1,1:+1,6:-5,0:-4,1:+1` | 30 | 1 |  | 30 |
| 45 | Freeze frame | hex | 0, 1, 3 | `6:+2,5:-3,0:+1,5:+5,4:-2,3:+1,4:+1,3:+1,4:+5,5:-1,4:+3,0:+1,5:-1,6:+2,5:-1,4:-5,5:-4,6:-1,5:-4,4:+3,5:+3,6:-4,5:+4,0:+1,2:-4,1:+1,2:-3,1:+1,6:+3,1:+1,6:+5` | 31 | 1 |  | 31 |
| 46 | Freeze frame | hex | 2, 4, 5 | `3:-1,0:-3,6:-1,0:+5,4:+2,3:+1,0:+1,5:+1,6:+1,5:+1,6:-4,5:+1,6:-4,1:+2,2:+1,1:+4,6:-4,0:+1,3:-5,2:+1,0:-2,2:+1,0:-5,6:-2,1:-4,0:+2,3:+3,0:+1,3:+2,0:+4,4:+1,0:+4` | 32 | 1 |  | 32 |
| 47 | Freeze frame | hex | 2, 3, 6 | `4:+5,3:+1,0:-4,2:+1,1:-2,0:-1,5:+3,4:-1,5:+2,4:-5,5:-3,0:+1,4:-1,5:-4,6:+1,0:+1,1:+1,0:-2,1:-4,2:+1,1:+5,0:-1,3:+1,0:-3,6:+1,1:-1,0:+4,2:+1,1:+2,6:+1,1:+4,0:-2,5:-1` | 33 | 1 |  | 33 |
| 48 | Freeze frame | hex | 0, 2, 4, 5 | `6:-4,1:+1,6:+1,1:-3,6:+4,0:+1,3:+4,4:+2,3:-3,4:+1,3:+5,2:+1,3:-1,2:+1,3:+4,0:+1,6:+5,1:+2,6:+5,1:-5,6:+4,5:+1,6:-2,1:+1,0:+1,1:-5,6:+4,5:+2,6:-1` | 29 | 1 |  | 29 |
| 49 | Freeze frame | hex | 1, 2, 4, 5 | `5:+1,6:+1,0:-2,6:-3,1:+1,6:+3,5:+1,0:+2,6:-3,0:-1,4:+1,3:+5,0:-1,5:+1,0:+5,3:-1,4:+1,3:-1,2:+1,3:+4,0:+5,6:+2,0:+3,3:+5,0:+1,1:+1,0:-2,2:+1,3:-5,0:-2,3:-2,0:-1,6:-5,0:+2` | 34 | 1 |  | 34 |
| 50 | Split screen | hex | 2, 3, 5, 6 | `1:-3,0:-2,6:+1,1:+1,6:+1,0:-2,4:+5,0:-3,5:+2,4:-2,5:+1,0:+5,4:-3,0:-1,2:+1,1:+3,2:+1,0:-5,4:-3,3:+1,0:+3,1:-3,0:-1,1:-1,0:+1,1:+4,0:+1,3:+1,0:+5,4:+2,0:-4,2:+1,1:-1,0:+2` | 34 | 1 |  | 34 |
| 51 | Split screen | hex | 1, 2, 3, 4, 5, 6 | `0:+5,5:+1,0:-4,5:+2,0:+2,1:+1,0:+1,6:+1,0:+4,1:+1,0:+4,1:+1,0:+1,3:+1,0:-5,2:+1,0:-5,4:+1,0:+1,3:+1,0:+3,2:+1,0:-5,6:+1,0:-5,3:+1,0:-5,6:+1,0:-2,2:+1,0:-1,4:+1,0:-2,4:+1,0:+4` | 35 | 1 |  | 35 |
| 52 | Split screen | hex | 0, 1, 3, 4 | `5:-1,6:+1,5:+2,6:+2,5:-4,4:+2,5:+5,0:+1,6:+1,0:+1,6:-1,5:+4,4:+1,5:-1,6:-4,5:-3,6:+1,5:-1,6:+4,5:-1,6:-3,1:+1,2:-4,1:+1,6:-1,1:+1,2:-1,3:+1,2:-3,3:+1,2:-3` | 31 | 1 |  | 31 |
| 53 | Split screen | hex | 1, 3, 4, 6 | `5:-4,6:+1,5:-1,0:-3,2:+5,0:-3,1:+1,0:+3,1:+1,2:-1,1:+1,0:+4,2:-4,0:+1,5:-3,6:+1,0:+2,2:+4,0:-4,4:+1,5:+3,0:-3,2:+1,0:-1,5:+5,0:-1,2:+4,0:+3,4:+1,0:-1,3:+1,2:+5,0:+4,2:-4,3:+1,2:-3` | 36 | 1 |  | 36 |
| 54 | Split screen | hex | 0, 1, 2, 4 | `5:+3,0:+1,6:-1,5:-1,0:+1,5:-2,6:+3,1:+2,6:-1,5:+3,4:+1,5:+4,6:+2,5:-3,6:+3,5:+5,6:+1,1:+1,6:+4,5:+4,6:-5,5:+3,4:+1,3:+1,2:+1,3:-4,2:+1,3:-1,2:+1,3:-1` | 30 | 1 |  | 30 |
| 55 | Split screen | hex | 1, 2, 3, 5, 6 | `1:+1,0:+3,4:+4,3:+1,0:-2,4:-5,0:-2,2:+2,0:-4,6:+2,0:+3,4:-4,0:-4,6:+1,0:-1,4:+3,0:+3,3:+2,0:+2,1:+2,0:+3,4:+1,0:+4,4:-2,0:+1,5:+1,0:-5,2:+1,0:-1,5:+1,0:-1,4:+3,0:+1,5:+1,0:+2,4:+4` | 36 | 1 |  | 36 |
| 56 | Slow motion | hex | 0, 3, 4, 6 | `1:-2,2:-2,3:+2,2:-4,1:+2,2:+3,1:+1,0:+1,5:+4,4:+1,5:+5,0:+1,1:-5,2:-1,1:-1,2:-1,3:+1,2:+2,1:+1,6:+2,5:+4,0:+1,2:-4,1:-3,2:-1,1:-5,6:+1,5:+1,4:+1,5:+3` | 30 | 1 |  | 30 |
| 57 | Slow motion | hex | 1, 2, 4, 5, 6 | `3:-1,0:-1,6:+1,0:+5,6:+2,0:-2,2:+1,3:-1,0:-4,3:-5,0:-2,3:+1,0:-3,1:+1,0:-2,3:+5,0:+3,5:+1,0:-2,3:-5,4:+1,0:-5,3:+1,4:+2,3:-5,2:+1,0:+2,5:+2,0:-1,1:+1,0:-5,3:-2,0:+4,1:+1` | 34 | 1 |  | 34 |
| 58 | Slow motion | hex | 1, 2, 3, 4 | `6:-4,5:+4,6:+2,0:-3,5:+1,6:+1,0:+5,5:+2,4:+1,0:-3,3:+1,0:-5,5:-5,0:-4,5:-5,4:+1,5:+1,6:+5,5:+1,6:+5,0:+1,2:+1,0:+5,5:-1,4:+1,0:+3,6:+5,1:+1,0:+3,2:+1,0:+3,3:+1,0:+1,1:+1,6:-3` | 35 | 1 |  | 35 |
| 59 | Slow motion | hex | 1, 3, 4, 5, 6 | `0:+2,3:+1,2:-1,1:+1,0:+5,2:+1,1:+1,0:-5,2:-1,0:+4,3:+1,2:+5,3:+1,2:-2,0:-1,4:+1,0:+4,2:+1,0:-1,6:+1,0:+3,4:+1,0:+1,2:+3,0:-5,6:+1,0:-1,5:+1,0:+3,2:-1,0:-1,2:+3,0:+1,2:+1,0:+1,5:+1` | 36 | 1 |  | 36 |
| 60 | Slow motion | hex | 0, 1, 2, 4 | `6:-1,1:+1,6:+2,5:-1,0:+1,6:-2,5:+1,6:-1,5:+1,6:+1,5:+1,4:+1,5:+5,6:+5,5:+4,0:+1,5:+2,6:-3,1:+1,6:-1,5:-1,6:-5,1:+1,6:-3,5:-5,4:+1,3:-1,2:+1,3:-1,2:+1,3:-3` | 31 | 1 |  | 31 |
| 61 | Slow motion | hex | 2, 3, 5, 6 | `4:+1,0:-3,3:+1,4:-3,0:+5,1:-1,2:+1,0:-5,1:-1,0:-5,1:+5,0:-1,3:+1,0:-1,2:+2,0:+5,1:+5,6:+2,1:-1,0:-1,4:+4,0:+5,1:-2,0:+2,4:-4,3:+1,0:-1,5:+1,0:-5,1:+5,0:-1,1:-5,6:+1,1:-4,0:-3,5:+2` | 36 | 1 |  | 36 |
| 62 | Dolly zoom | hex | 1, 2, 3, 5 | `6:+1,0:-1,4:-2,3:-2,0:-4,2:-1,0:-4,4:+4,0:-5,4:-5,0:-3,1:-1,0:+5,4:+3,0:-4,4:-1,0:-1,6:-4,0:-1,6:-2,0:+1,6:-1,0:+2,5:-2,4:-5,5:-1,6:-5,0:+1,3:-1,0:+5,2:-2,0:+4,6:+4,1:-2` | 34 | 1 |  | 34 |
| 63 | Dolly zoom | hex | 1, 2, 3, 4, 6 | `5:-2,4:+2,0:+1,3:-2,0:+1,4:-3,0:+4,1:+1,0:+1,6:+2,0:+3,5:+3,0:+1,5:-4,4:-1,0:+2,1:-2,0:+4,2:-2,0:-2,1:-2,0:-5,5:-4,6:-1,0:-3,6:-2,5:+5,0:-5,2:+3,0:-1,2:-3,0:-3,3:-1,0:-2,3:+2` | 35 | 1 |  | 35 |
| 64 | Dolly zoom | hex | 0, 1, 3, 6 | `6:+1,5:-1,4:+2,5:-1,4:-3,5:+5,4:+1,5:-1,0:+1,2:-1,1:+1,2:+3,1:+1,2:+3,3:+1,4:+4,3:+1,2:-5,0:+2,5:+5,6:+1,5:-1,4:+1,5:+2,6:+1,5:-5,4:-1,5:-2,4:-5,5:-1,4:+5,5:-3` | 32 | 1 |  | 32 |
| 65 | Dolly zoom | hex | 2, 3, 4, 5, 6 | `4:-3,0:-4,1:+3,2:+2,0:-3,5:+3,0:+5,4:+2,0:+1,6:-3,1:+3,6:+2,0:+4,1:-3,2:+1,0:+4,6:+2,1:-2,2:-2,1:-1,0:-2,3:+1,0:-2,1:-1,0:+3,3:-2,0:-4,4:-2,0:-2,3:+2,0:-5,5:-2,0:-3,5:+2` | 34 | 1 |  | 34 |
| 66 | Dolly zoom | hex | 0, 2, 4, 5 | `5:+2,6:+3,1:-1,0:+1,1:-2,6:-1,1:+1,6:+5,1:-2,6:+1,1:+1,6:-2,0:+1,3:-5,4:+1,3:-3,4:+1,3:+1,2:+1,1:+3,6:+5,5:+1,6:+1,1:+1,6:+1,1:-4,2:+2,1:-3,0:+1,6:+4,1:-2` | 31 | 1 |  | 31 |
| 67 | Dolly zoom | hex | 0, 1, 4, 5 | `3:+5,0:+1,3:+2,0:+2,3:+4,2:+4,1:+1,2:-3,3:-3,2:+1,3:-3,2:-4,3:-3,2:-1,3:+2,4:+1,3:+4,2:+1,3:-1,4:+1,3:-4,2:-4,3:-2,4:+1,3:-1,2:+1,1:+1,6:+2,5:+1,6:+3,5:+1,6:+3` | 32 | 1 |  | 32 |
| 68 | Final cut | hex | 1, 2, 3, 4, 5 | `3:-3,0:-2,2:-2,0:-1,3:+2,0:-4,2:+1,0:+1,2:-2,0:+1,4:+1,0:-4,1:-2,0:-1,6:+1,1:+3,6:-5,0:-2,5:+2,0:+1,6:-1,1:-3,0:-5,5:-3,6:-3,5:-2,0:-5,6:-4,0:-1,3:+2,0:-1,4:-2,0:-5,4:+2` | 34 | 1 |  | 34 |
| 69 | Final cut | hex | 0, 1, 2, 5 | `6:-2,0:+1,6:+4,5:+1,4:+1,3:-4,4:+4,3:+1,2:+2,3:+1,4:+3,3:-3,4:+1,3:-1,4:-1,3:-1,4:-4,5:+1,6:+3,5:+1,4:+2,3:+3,2:+1,3:+4,4:-1,3:-3,0:+1,6:-3,1:+1,6:+1,1:+1` | 31 | 1 |  | 31 |
| 70 | Final cut | hex | 0, 3, 5, 6 | `2:+1,3:+1,4:-2,5:+2,4:-5,0:+1,1:+4,2:+3,1:-5,2:-4,1:+2,2:+1,1:+1,2:+2,3:+2,4:-5,5:+1,4:-1,0:+1,1:-2,2:+3,1:-2,2:+1,1:+1,2:+5,0:+1,2:-1,1:-3,6:+2,1:-3,6:+1,1:+1` | 32 | 1 |  | 32 |
| 71 | Final cut | hex | 1, 2, 3, 5, 6 | `2:-3,0:-1,4:-1,5:+2,0:-4,2:+1,0:-5,2:+3,0:-1,3:-3,0:-1,4:+5,3:+1,0:-3,1:-2,0:-1,4:+1,3:+3,4:-5,5:-3,0:-1,6:-3,0:-1,4:-4,5:-2,0:-4,6:+2,0:+2,5:+2,0:+1,1:+3,0:-5,6:+2,0:-1,1:+2` | 35 | 1 |  | 35 |
| 72 | Final cut | hex | 1, 2, 4, 5, 6 | `1:+3,0:+5,4:+2,0:+4,5:-2,0:-1,4:-3,0:+3,4:-2,3:-1,0:+2,1:-2,0:+4,5:+3,0:+4,2:-1,3:-1,0:+1,6:+2,0:+4,5:+2,0:-1,6:-1,0:-1,6:+2,0:+4,3:+1,2:+3,0:+3,1:+2,0:+2,6:-1,0:-1,3:-1,2:+1,0:-2` | 36 | 1 |  | 36 |
| 73 | Final cut | hex | 1, 3, 4, 5, 6 | `5:+3,0:+1,5:-2,0:-2,2:+3,1:-1,2:-1,0:-4,5:-3,0:-2,3:-2,2:-4,3:+3,2:-5,1:-1,2:+1,1:+3,0:-2,4:+1,0:-2,3:+1,2:-5,0:+3,6:-1,0:+3,6:+3,0:+2,4:-2,0:-1,6:-3,0:+5,2:-1,0:-2,4:+2,0:-1,6:-1` | 36 | 1 |  | 36 |
| 74 | Final cut | hex | 0, 1, 2, 4 | `4:+1,5:+5,6:-5,5:+4,6:-1,5:+3,6:+1,5:+5,6:+4,5:-1,6:-1,1:+2,6:-1,0:+1,5:-5,6:-5,1:+1,6:-1,0:+1,6:-3,0:+1,5:-4,6:-1,5:-1,6:+1,5:-5,4:+1,3:+1,2:+2,3:-3,2:+1` | 31 | 1 |  | 31 |
| 75 | Final cut | hex | 1, 2, 3, 4, 6 | `0:-5,2:+1,0:+3,3:+2,0:+1,3:+1,0:+4,1:+2,0:+4,5:-1,4:+3,5:+5,4:-2,5:+3,6:+2,5:-2,6:-3,0:-2,6:-2,0:-4,5:+2,4:-3,0:+1,1:-3,0:-5,5:+1,0:-1,1:+3,0:-1,2:+2,0:+3,2:-2,0:+1,1:-3,0:-5,3:-2` | 36 | 1 |  | 36 |

## Table B: lenses on big rods only (`lens-levels-big`)

Only tri and eye have big rods, so every level is on one of them: 12 on tri, 13 on eye. The draft's big-rod rows stay
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
