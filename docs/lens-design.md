# Lens: design drafts

Drafts for Jack, 2026-10-25. Nothing here is decided except Jack's round 3 call L1: **the hard lens, phone test
next**. Everything else is Claude's recommendation. "Checked" marks a claim computed or read from code; "inferred"
marks one that wasn't, and says what would check it.

## 0. The rod Jack chose

The hard lens as built on local branch `lab-lens` (f6dfc8b to 5928602), read from its code and commit messages:

- A lens rod moves only its rigid core (out to `Tank.plateau`, 0.6 of its disc). Inside, the fluid flows on
  u (1 - (u/a)^e), which scales the centre by the rate each step (x1.3) and fixes the rim; the ring outside the core
  never moves. Rim sharpness e = 2 (`Lab.hardEdge`), which reads at +1 where 1 barely does.
- Steps form a group: turns merge by summing and an entry pops at 0, through the ordinary `Array.commit`. A lens
  never wraps: +k needs exactly -k. Play is uncapped; only the deal is capped (every dealt lens entry +1 to +3).
- Clockwise magnifies. The deal only magnifies, so a dealt core always shows swollen dots, x1.3, x1.69 or x2.2 the
  screen's pitch (0.03 tank units).
- The read: a whole rim means the lens is on top; a newer twist drags the rim into its swirl, and a newer lens cuts
  the twist's lines dead at its rim. The bead covers 36% of the disc.

Four consequences that shape everything below:

1. **Two lenses never interact** (checked: their supports are cores, and cores never overlap). A level of lenses
   alone has no order puzzle. Every order puzzle in Lens is a twist against a lens, or a twist against a twist.
2. **A lens commutes with every disc that misses its core**, so a lens rod interacts with fewer rods than a twist on
   the same rod. Hex's hub is the exception that matters: its core lies under all six ring discs.
3. **The rim break is weak on quad and pent** (checked by `scripts/lens-table.py`'s model of `Tank.profile`). How far
   a neighbour's twist drags a lens's rim, at the rim's deepest point inside the twist's disc, in dot pitches:

   | Layout, lens under twist | 1 step | 2 steps | 3 steps | Rim inside the twist's disc |
   |---|---|---|---|---|
   | tri, any pair | 6.2 | | 17.2 | 29% |
   | eye, small lens under big twist | 5.5 | | 15.7 | 31% |
   | hex, any neighbours (hub or ring) | 4.7 | | 13.0 | 28% |
   | eye, big lens under big twist | 4.5 | | 13.2 | 22% |
   | eye, big lens under small twist | 3.5 | | 10.3 | 18% |
   | quad, neighbours | 1.7 | 3.5 | 5.2 | 17% |
   | pent, neighbours | 1.1 | 2.3 | 3.4 | 15% |

   Quad's and pent's discs only graze each other's cores, in the outer ring where the twist has nearly faded, so a
   1-step twist over a lens there leaves its rim nearly whole, and "whole rim, lens on top" misleads. Inferred, for the
   phone test to settle: a drag of about 4 pitches (about 70 px at Pro Max size) reads. The draft table holds every
   twist dealt over a lens to at least 4 pitches, which rules out pent and needs 3 steps or more over a lens on quad.
4. **Magnification piles up just inside the rim.** There the radial scale is 1.3^-2 a step (lab commit f6dfc8b), so a
   rod netting +3 squashes the clean dots radially to 0.21 of their pitch (about 3.6 px at Pro Max size), and the lab's
   hard lens 1, whose top rod nets +5 across two entries, to about 0.07 (about 1.3 px, inferred to glitter). The draft
   caps each lens rod's net at +3.

## 1. The story: an original wordless heist in 25 panels

**Premise: "The Switch".** A gallery shows a blue diamond. A woman cases it, breaks in at night, and is chased out. Only
on the last page does the reader see what the lens kept showing: the diamond on show was a fake, marked by its forger
with a tiny star, and she broke in to put the real one back. The stone was her grandfather's. A heist that puts things
back fits a game about putting things back.

**What the lens reveals.** Each panel's lens core holds one clue drawn in hairline white ink, finer than the dot
screen: a speck in the wide shot, legible only magnified. The deal opens every panel with its lens magnified, so the
player starts on the comic's cut-in close-up, reads the clue at x1.3 to x2.2, and the solve shrinks it back into the
wide shot, where the story beat reads whole. The clue is the thief's eye; the solved panel is the reader's.

**Look.** Neon halftone on black, as on `lab-lens`: fluoro cyan, magenta and yellow dot screens at 15, 75 and 0
degrees, one pitch of 0.03 tank units in clean-picture coordinates, white ink outlines, a registration-mark bezel.
Objects and close-ups, not figures in melodrama: no speech or thought balloons, no faces in tears, no lettering, so it
is pop art without being Lichtenstein pastiche. Every core keeps asymmetric linework so a turn can't hide in the
square screen, and every clue is drawn to read at x1.3, the smallest dealt step.

Positions: tri's rod 0 is the top disc, then clockwise; eye's 0 and 1 are the big left and right discs, 2 the small top
and 3 the small bottom; hex's 0 is the hub and 1 the top of the ring, then clockwise. The panel numbers are the level
numbers in section 2.

**Issue 1, Close-up: casing the gallery.** Panels 1 to 3 are the free taste and end on the hook.

| # | Beat | Lens core holds | What the lens reveals |
|---|---|---|---|
| 1 | Her eye, close, at the gallery | the iris (top) | the diamond's case reflected in the iris |
| 2 | The diamond on its velvet stand | the stone (top) | a tiny star scratched on one facet |
| 3 | She opens a locket | the locket (top) | an old man in the photo, the same diamond as his tie-pin, no star |
| 4 | Her watch against the gallery clock | the watch face (lower right) | an inked tick at the minute the guards change |
| 5 | The floor plan on her table | the vent (small top) | a pencilled cross on one grille |
| 6 | The guard's belt, his keyring | the keyring (big left) | the teeth of the service key, matched against a soap impression |

**Issue 2, Cut-in: the night.**

| # | Beat | Lens cores hold | What the lenses reveal |
|---|---|---|---|
| 7 | The skylight under a clouded moon | the latch (top), the moon (lower right) | the latch's screw, unscrewed; cloud over the moon's face |
| 8 | Her gloved hand at the vent | the screw head (upper right), the grille (lower left) | the screwdriver's tip in the slot; a camera reflected in the grille |
| 9 | The security camera | the camera (small top), a photo (small bottom) | the camera's lens; the photo, of the empty room, taped in front of it |
| 10 | The laser grid | her compact mirror (lower left) | the beam bent round by the mirror |
| 11 | Suction cups on the case's glass | the cutter (lower right), the alarm clip (upper left) | the cutter's wheel in its groove; the clip bridging the alarm wire |
| 12 | Two diamonds, one in each glove | the left glove (big left), the right glove (big right) | a star on the left stone, none on the right. The right one goes into the case |

**Issue 3, Double-take: the getaway.**

| # | Beat | Lens cores hold | What the lenses reveal |
|---|---|---|---|
| 13 | The guard wakes | his eye (top), his cup (bottom) | her silhouette reflected in his eye; a tablet fizzing in the cup |
| 14 | The alarm | the bell (upper right), his torch (lower left) | the hammer mid-strike; the torch's beam finding a footprint |
| 15 | The stairwell | her heel (small top) | an earring falling, with the locket's crest |
| 16 | The rope from the roof | the knot (top) | a slipknot that frees from below |
| 17 | The getaway on a scooter | the wing mirror (top), the tail light (lower right), the moon (lower left) | the guard in the mirror, holding the earring; the light out; the cloud gone |
| 18 | The guard in his locker room | the earring (upper right), a photo (lower left) | the crest; the same old man, younger, in a guard's cap. He smiles and pockets the earring |

**Issue 4, Splash: the morning after.**

| # | Beat | Lens cores hold | What the lenses reveal |
|---|---|---|---|
| 19 | The gallery opens; crowds at the case | the diamond (hub) | no star: the real stone |
| 20 | The curator with a jeweller's loupe | the stone (hub), his eyebrow (top), the loupe (bottom) | flawless; the brow raised; her face reflected in the loupe's rim |
| 21 | Her windowsill | the fake (big left), a magpie (small bottom) | the star; the magpie's eye on it |
| 22 | The magpie's nest | the fake in its beak (hub), the nest (upper right), a spoon (lower left) | the star; bottle caps and a thimble; her reflection, waving |
| 23 | The old man's portrait on her wall | the tie-pin (hub) | the real stone, painted with its own flaw, which matches the gallery's |
| 24 | A parcel at her door | the stamp (small top), the postmark (small bottom) | the diamond on the stamp; the crest as the postmark: the guard sends the earring back |

**Splash page.**

| # | Beat | Lens cores hold | What the lenses reveal |
|---|---|---|---|
| 25 | The grand hall: the stone in its case, her in the crowd wearing both earrings | the stone (hub), her earring (top), the guard (lower right), the skylight (lower left) | every earlier panel, tiny, in the stone's facets; the crest; his wink; the magpie on the glass |

Each solved issue lays its six panels out as a comic page (as HANDOFF has it); the splash page stands alone, and its
solve closes the pack.

## 2. The level table (draft)

Four issues of six and a splash page, as HANDOFF's structure, with the Spiral issue gone (open point 1) and hex
brought forward in its place. Rules the draft keeps, all but the first enforced by
`scripts/lens-table.py docs/lens-design.md`, which reads the rows below and exits non-zero on a break:

- Layouts tri, eye, quad and hex; no pent (consequence 3, open point 3). This one is a choice, not a check: the drag
  rule below would let a pent row through with twists of 4 steps or more over each lens. A rod is a lens or a twist for the whole level, and every
  level keeps at least one twist rod in reach of each lens, or it has no order to read.
- Every dealt lens entry is +1 to +3, and each lens rod nets at most +3 (consequence 4).
- Every twist dealt over a lens drags its rim at least 4 pitches: any step on tri and hex, 2 or more of a small twist
  over a big lens on eye, 3 or more on quad.
- No entry merges as it is parsed, so the depth is the string's length.

The scramble strings are design intent. `master`'s `parse` treats every rod as a twist, so the depths here come from
the script's overlap model (a lens reaches only its core) and are confirmed only once rods have kinds (to-do 27).
**Par is TBD on every row**: with no knob seized the tank never turns and untwisting reaches the depth, so par is at
most the depth; whether a detour beats it is the solver's call once it learns rod kinds (to-do 29). The lab's solver
knows nothing of lenses, so no par here comes from it.

"Free" is how many entries can come off at the start, the script's count; plughole's levels mostly have one.

| # | Issue | Layout | Lens rods | Scramble (intent) | Depth | Free | What it adds | Par |
|---|---|---|---|---|---|---|---|---|
| 1 | Close-up | tri | 0 | `0:+2` | 1 | 1 | The ringed knob: clockwise swells the dots, anticlockwise brings them back to the screen's pitch, and the rim goes at 0 | TBD |
| 2 | Close-up | tri | 0 | `0:+1,1:+3` | 2 | 1 | A broken rim: the twist is on top. Untwist, the rim comes whole, then shrink; the faintest step, +1 | TBD |
| 3 | Close-up | tri | 0 | `1:-2,2:+4,0:+3` | 3 | 1 | A whole rim over twists, their lines cut dead at it: the lens first, and +3 to count by the dots | TBD |
| 4 | Close-up | tri | 1 | `0:+3,1:+2,2:-4,1:+1` | 4 | 1 | One lens twice, a twist between: two separate entries | TBD |
| 5 | Close-up | eye | 2 | `0:-4,2:+2,1:+5,3:-3` | 4 | 1 | Mixed sizes; a twist whose disc misses the lens | TBD |
| 6 | Close-up | eye | 0 | `2:+3,0:+2,1:-4,3:+5,0:+1` | 5 | 1 | A big lens under both kinds of neighbour | TBD |
| 7 | Cut-in | tri | 0, 1 | `2:+4,0:+2,1:+1` | 3 | 2 | Two whole rims at once: lenses never meet, so either first | TBD |
| 8 | Cut-in | quad | 0, 2 | `1:+4,0:+2,3:-3,2:+3,1:-5,0:+1` | 6 | 1 | Quad's grazing discs, with twists of 3 or more over each lens | TBD |
| 9 | Cut-in | eye | 2, 3 | `0:+3,2:+2,1:-4,3:+3,0:+2,2:+1` | 6 | 1 | Two small lenses under the big twists | TBD |
| 10 | Cut-in | tri | 2 | `0:+3,2:+2,1:-5,0:-2,2:+1,1:+4` | 6 | 1 | A long tri, one lens netting +3 | TBD |
| 11 | Cut-in | quad | 1, 3 | `0:+3,1:+3,2:-4,3:+2,0:-3,3:+1,2:+5` | 7 | 1 | | TBD |
| 12 | Cut-in | eye | 0, 1 | `2:+3,0:+2,3:-4,1:+3,2:-2,0:+1,3:+5` | 7 | 1 | Both big discs lenses, read only through the small twists | TBD |
| 13 | Double-take | hex | 1, 4 | `0:+3,1:+2,2:-4,4:+3,6:+2,0:-2,5:+4` | 7 | 1 | Hex: the hub twist reaches every lens | TBD |
| 14 | Double-take | hex | 2, 5 | `3:-3,2:+2,0:+4,5:+1,6:-3,2:+1,4:+5,5:+2` | 8 | 2 | | TBD |
| 15 | Double-take | eye | 2 | `1:+4,2:+1,0:-5,3:+3,2:+2,1:-3,0:+4,3:-2` | 8 | 1 | | TBD |
| 16 | Double-take | tri | 0 | `1:+3,0:+1,2:-4,1:-2,0:+1,2:+5,1:+4,0:+1` | 8 | 1 | One lens in three entries of +1, each read from the faintest step | TBD |
| 17 | Double-take | hex | 1, 3, 5 | `0:+2,1:+3,2:-4,3:+2,4:+3,5:+1,6:-5,0:+4,5:+2` | 9 | 1 | Every other ring rod a lens | TBD |
| 18 | Double-take | quad | 0, 2 | `1:+3,0:+1,3:-4,2:+2,1:+5,0:+2,3:+3,2:+1,1:-4` | 9 | 1 | | TBD |
| 19 | Splash | hex | 0 | `1:+3,0:+2,4:-3,2:+4,0:+1,5:-3,3:+2,6:+4` | 8 | 2 | The hub a lens: every ring twist breaks its rim | TBD |
| 20 | Splash | hex | 0, 1, 4 | `2:+3,0:+2,1:+3,5:-4,4:+2,3:+4,0:+1,6:-3,2:-2` | 9 | 2 | Hub and ring lenses together | TBD |
| 21 | Splash | eye | 0, 3 | `2:+4,0:+2,1:-5,3:+2,2:-3,0:+1,1:+4,3:+1,2:+3` | 9 | 2 | | TBD |
| 22 | Splash | hex | 0, 2, 5 | `1:+3,0:+1,2:+2,3:-4,6:+5,5:+3,4:-3,0:+2,1:-3,2:+1` | 10 | 1 | | TBD |
| 23 | Splash | hex | 0 | `3:+4,0:+1,6:-3,1:+5,0:+1,2:-4,4:+3,0:+1,5:-5,3:+2` | 10 | 2 | The hub in three entries | TBD |
| 24 | Splash | eye | 2, 3 | `0:+4,2:+2,1:-3,3:+1,0:-4,3:+2,1:+5,2:+1,0:+3,1:-2` | 10 | 1 | | TBD |
| 25 | Splash page | hex | 0, 1, 3, 5 | `2:+3,0:+1,1:+2,4:-4,3:+3,6:+3,0:+1,5:+2,2:-5,1:+1,4:+4,0:+1` | 12 | 2 | Four lenses, seven of the twelve entries | TBD |

Depth climbs from 1 to 12, plughole's range (its finale is 14), held at 12 because HANDOFF expects mixed stacks may murk
past about 10 entries (unchecked; the phone test's step 3 is the first look). Layouts by issue: tri only for the taste, then tri and eye; quad enters with two lenses; hex takes
the back half, where the hub lens carries the splash.

**The free taste teaches the rule without words** (to-do 46), all on tri, where a twist drags a rim furthest:
level 1 is the knob and the dot ruler alone, level 2 a broken rim (not on top), level 3 a whole rim (on top) and
counting by the dots. A player who has those three has the pack. Each wants a cold read on a new player once built.

## 3. The phone test for the hard lens

L1's own condition: commit a v1 slot to Lens only if it reads under Jack's thumb on the phone; if it doesn't, shelve
Lens and Prism takes the slot. Everything below runs on `lab-lens` as it stands, with no new levels.

**Setup.** Build `lab-lens` in its own worktree and install it Release (its halftone bake holds every core for
seconds in Debug): `scripts/run-ios.sh Release` there. Each trial is a launch with the harness's variables, which
`lab-lens` reads on a lab level: `UNSTIR_LAB` (`lens-hard-1`, x1.3, sharpness 2), `UNSTIR_LAYOUT` (`triZoom`, whose top
rod is a lens; `quadZoom` and `pentZoom`, whose rods 0 and 2 are) and `UNSTIR_STACK`. Claude runs the launches and
keeps the answers; Jack only looks and plays. For example:

```
xcrun devicectl device process launch --device "$UNSTIR_DEVICE" --terminate-existing \
  --environment-variables '{"UNSTIR_LAB":"lens-hard-1","UNSTIR_LAYOUT":"triZoom","UNSTIR_STACK":"1:+2,0:+1"}' \
  com.screendead.Unstir
```

Unchecked: that `--terminate-existing` is the flag's name in this Xcode's `devicectl`. About 30 minutes.

**What Jack does, in this order:**

1. **Count.** 16 stills in shuffled order, `triZoom`, `1:+2,0:+k` for k = 1, 2, 3 and `1:+2` alone for k = 0, four of each. Jack says k
   without touching. This checks that +1 shows at all and that the dots count.
2. **Order.** On each of `triZoom`, `quadZoom` and `pentZoom`: the lens at +2 and its neighbour rod 1 twisted k = 1, 2,
   3, in both orders (`1:+k,0:+2`, lens on top; `0:+2,1:+k`, twist on top), each twice, 36 stills shuffled. Jack says
   whether the lens is on top, without touching. The stills span rim drags of 1.1 to 17 pitches (consequence 3), so
   they set the table's threshold directly.
3. **Play.** `lens-hard-1` (tri, depth 4) and `lens-hard-2` (quad, depth 6) from the lab's list, once each, probing
   as he likes. Claude reads moves, undos and time from the flight recorder (`scripts/pull-log.sh`).
4. **Look.** `triZoom` at `0:+3`, then `lens-hard-1` as dealt (its top rod nets +5): still, and while a neighbour's
   twist drags the rim. Glitter or moire in the band just inside the rim? Then `0:+1`, turned back 3 (net -2): does
   an over-shrink read as a mistake, and come back cleanly?
5. **Verdict.** Would he put his name on a pack of this?

**What we watch for.** Order calls that go wrong on one layout and not another (consequence 3's prediction: right on
tri at every k, wrong on quad at k = 1 and on pent at k = 1 and 2). Counting that confuses +2 with +3 (x1.69 against
x2.2). Glitter in the rim band at +3 (3.6 px dots) or +5 (1.3 px). A drag that stutters (the lens's shader cost is
unmeasured; to-do 23 benches it properly). Probing that turns the lens first by habit, which pushes an entry: does the
red flash teach, or annoy?

**Go/no-go.**

- **Go** if all of: count 14 of 16 or better, every k = 0 against k = 1 right; order every call right on tri at k = 1;
  both lab levels solved within par + 1 (par 4 and 6, untwisting's count); no glitter at +3; and Jack's yes.
- **Go with fewer layouts** if tri passes and quad or pent fails: the threshold moves to the smallest drag that read
  every time, the script takes it (`--pitches`), and quad's rows move to eye or hex.
- **No-go** if counting or tri's order read fails, or the rim band glitters at +3 and sharpness 1.5 or a 1.25 rate
  (the lab's `UNSTIR_LENSEDGE`, `UNSTIR_ZOOMRATE`) doesn't clear it on a second look: L1's fallback, Lens to Set aside
  with the reason and Prism into the v1 slot.

## 4. Open points for Jack

1. **Spiral rods.** HANDOFF's third issue had spiral rods, the soft zoom's field added to the twist's. The soft zoom
   is gone, so the spiral has no design.
   A: drop it from v1; Lens is one new rod kind against twists, in four issues as drafted.
   B: design a hard spiral (the lens's flow plus a rotation of the core, which commute on one rod) and film it before
   it takes an issue.
   **Recommend A**: the hard lens is unproven on the phone, and a second new read doubles what the test must clear.
   B can come later as a free update to the pack.
2. **The story.**
   A: "The Switch", a reverse heist, as drafted.
   B: a straight heist that goes wrong.
   C: five unrelated capers, one per issue.
   **Recommend A**: the lens's clues build to one reveal (the star), and putting things back is the game's own act.
3. **Quad and pent.**
   A: the phone test sets the drag threshold; pent is out, quad only with 3 steps or more over a lens, as drafted.
   B: all five layouts, trusting players to probe.
   C: tri, eye and hex only.
   **Recommend A**: quad's three levels are cheap to move if the test fails it, and B makes "whole rim" lie on pent.
4. **How far a lens may magnify in the deal.**
   A: each lens rod nets at most +3 across the deal, as drafted.
   B: +3 an entry only, as the lab does (its hard lens 1 nets +5).
   **Recommend A**: it caps the rim band's squash at 0.21 of a pitch, and keeps the count at three dot sizes.
5. **Shrinking past 0 in play.**
   A: allow it, as the lab does, so no turn is ever refused.
   B: the detent stops at the rod's net 0.
   C: refuse the turn.
   **Recommend A**, settled by what step 4 of the test shows: a stop or a refusal tells the player something the
   picture doesn't, which the game never does.
6. **Words on the levels.**
   A: none; each level shows only its panel number.
   B: a one-line caption per panel, as plughole's titles.
   **Recommend A**: the heist is wordless by design, and the taste teaches without words; a caption would compete
   with the clue.
7. **This table's shape.** Approve the issues, layouts and depth curve so rod kinds (to-do 27 to 29) can be built
   against them; the scrambles are then regenerated or confirmed by the kind-aware parse and the solver, and pars
   filled. **Recommend approving the shape after the phone test**, since its threshold may move quad's rows.
