# The fifth chapter: groundwork and prototypes

Jack, 2026-11-27: "Mineral is the one I wanted to keep. Add a fifth chapter, harder than Maelstrom - and see if you
can find a new mechanic or skill to introduce in that one too." This is the record of the groundwork on
`chapter5/mineral`: Mineral's pictures on master's code, three candidate rules built as Debug prototypes and filmed,
the tier's name and length, and what a fifth `Tier` case touches.

Jack's calls (2026-11-28): Charybdis teaches keys, its prefix is C, and every free chapter has 30 levels. Built since:
keys are a level property (`Level.wards`, `Ward`; the keel, ebb and flow and `UNSTIR_LAB` are gone, their record
below), `Tier.charybdis` is the last tier, `scripts/solve.sh <layout> <scramble> keys=...` proves a level
(`KeySolver`, the lab mode folded in), and `scripts/charybdis-levels.py` deals and measures its 30 levels on its own
seeds. Where this record says `UNSTIR_LAB`, `LabRules` or `solve.sh lab`, read `UNSTIR_KEYS`, `Ward` and `keys=`.

## Mineral, lifted

`Sources/Mineral.metal` and the four `Picture` cases (strata, agate, lamellae, columns) are the candidate set's own,
unchanged; their colours come from `Picture.gradients`, salted per picture as the set's were, so no constant was
copied. Checked against the set's renders on one simulator (`scripts/shots/mineral.sh`'s twelve cases):

- With nothing stirred, all four are identical inside the glass to the set's own shots, and to a build of the set's
  branch.
- As dealt and at each tier's deepest stack, seven of the eight frames are identical to the bit against that build,
  whole screen. The eighth, strata as dealt, differs because that build draws plughole's glass a pixel lower: 1.7% of
  the glass by one or two levels, and 45 pixels by up to 10, all on the knobs' caps; strata at rest matches it exactly
  at that offset.
- The picture lab's bench, three runs on the Mac: fills of 1.8, 1.9, 4.6 and 4.4 entries against the glass's 4, so
  `Picture.fillEntries` stays 2, 2, 5 and 5, and four taps hold to 35 stirs on lamellae and columns.

## The three rules

Each is a limit on which turns a level allows (`Sources/LabRules.swift`), never on what a turn does to the picture,
so every merge is `Array.commit`'s, the shader and its Swift copy are untouched, and the GPU's cost is nil: what a
knob shows is a few SwiftUI paths beside the knob (`Sources/LabViews.swift`). A turn turned straight back is always
allowed under each (Jack's rule that a wrong stir turned straight back stays free). Looks are free within what a rule
allows, but as built a locked ward refuses a finger outright, and the keel and ebb and flow stop the drag at their
bound, so a look past it is cut short; refusing only at the let-go, with the knob springing back, would keep every
look free at the cost of a less physical stop.

A Debug launch sets one on any level: `UNSTIR_LAB="keys=2:0@3"`, `"keel=4"` or `"flip"`, with `UNSTIR_STACK`,
`UNSTIR_LAYOUT`, `UNSTIR_PICTURE`, `UNSTIR_PAR`, and `UNSTIR_TITLE` and `UNSTIR_LABEL` for the level's name; the
level's note is cleared, as each is taught without words. `scripts/film.sh lab-` films them.

`scripts/solve.sh lab <layout> <scramble> <rules> [exhaustive]` proves a level: A* over stacks with an admissible
heuristic (each rod whose entries don't sum to 0 needs a turn of its own; a key at rest, off a mark a ward still needs,
one more). Under the keel and ebb and flow it tries every count from -12 to +12 on every knob, a proof to that range:
their levels are won by splitting a turn at a count no short list names (a bounded search put the keel's hardest at
7; every count found 5), and their room keeps that cheap. Under keys alone it tries by default the counts that cancel
an entry, that overshoot onto the negation of another entry of its rod, that bring a key to a mark or a knob to where
it must end, and +-1, the solver's bounded optimum (maelstrom's par keeps that standard); `exhaustive` tries every
count there too, which agrees on every keys level it finished.

### Keys

- **What the player sees.** A ward's knob carries a keyhole and a ring in its pair's colour (gold, then rose, then
  green); its key's knob the same ring and a notch on its dial at the mark. While the key's pointer stands on the
  notch, the keyhole lights and the ward turns; otherwise the ward refuses a finger as a seized knob does.
- **Taught without words.** Level 1 (quad, `2:+4`, ward 2 keyed by knob 0 at +3, par 3): the only stirred rod is the
  ward, so the first try is refused; the notch says where its key must stand; turned there, the keyhole lights; the
  ward unstirs; the key goes home.
- **The skill.** Planning around a dependency: a key's turn stirs the picture, so it costs moves unless the key's own
  unstirring passes through the mark at the right moment (level 2, `0:+5,2:+4` keyed at -2: stop the key halfway,
  par 3, not 4). With keys that overlap their wards, and chains (a key that is itself a ward), the order matters
  several moves ahead.
- **Hardest found.** Pent on columns, `2:+3,0:+4,1:-3,3:+5`, ward 3 keyed by knob 1 at +2 and ward 1 keyed by knob
  4 at -3: 9 moves for 4 entries, one first move of 11 reaches it (`4:-3`), untwisting alone is stranded. That is the
  bounded optimum (20 s); over every count, no shorter line was ruled out in 15 minutes. The hardest proved over every
  count is pent on lamellae, `0:+4,1:-3,2:+5,3:-2`, ward 2 keyed by knob 0 at -2: 6 for 4 entries (3 s). Hex chains
  ran past two minutes even bounded, so a tier's hex levels would need a faster proof.

### The keel

- **What the player sees.** A scale across the bezel's top, a notch a step either side of upright, and a bead at the
  tank's list: every knob's turns summed. A turn that would carry the bead past an end stops there; at the end the
  bead goes amber.
- **Taught without words.** Level 1 (quad, `0:+4,2:-3`, keel 3, par 2): the first knob tried stops a step short and
  knocks; the other one first brings the bead the other way, and then the first goes all the way.
- **The skill.** Keeping a running sum within bounds: choosing the order of the free choices, and turning a knob the
  wrong way for a while to make room. Every turn on the tank matters to every other.
- **Hardest proved.** Pent on agate, `4:+4,1:-3,2:-5,1:-2,4:+3` (knob 4's two merge as dealt), keel 3: 5 moves for
  4 entries, proved over every count; one first move of 30 reaches it (`1:+2`), and the line splits knob 4's turn in
  two round knob 2's to keep the bead on the scale. Quad on agate, `0:+5,1:+4,2:-3,3:-6`, keel 4: 6 for 4, proved.

### Ebb and flow

- **What the player sees.** Once a knob has turned, an arrow over its dial points the way it must turn next: each knob
  turns the other way from its own last turn. The knob stops at upright the wrong way and knocks.
- **Taught without words.** Level 1 (quad, `0:+3,1:-2,0:+4,2:-3`, par 5): the natural line turns knob 0 the same
  way twice and is refused; the answer is to overshoot its first turn, so that taking the overshoot back is the
  opposite turn the arrow asks for.
- **The skill.** Choosing each turn's size for the turn after it: an overshoot now buys the opposite turn later. It is
  the answer to the benched one-way knobs, whose flaw (a wrong stir couldn't be turned straight back) it doesn't have.
- **Hardest proved.** Pent on lamellae, `1:+4,0:-3,1:+2,2:-5,4:+3`: 6 moves for 5 entries, proved over every count
  (no line of 5), untwisting alone stranded.

### At maelstrom's depth

A chapter past maelstrom deals 20 to 26 entries, so each rule was dealt that deep (`scripts/lab-deep.py`, its own seeded
deals, never the frozen generator's) and proved with `scripts/solve.sh lab ... deep`: A* over the turns that take a
whole entry off plus the rule's own turns (a key to its mark, a whole turn round counting as the mark; an overshoot of
one to three steps under ebb and flow; a part of an entry under the keel), never a detour pushed for its own sake,
with the entry count as its heuristic. That is a bounded search, maelstrom's standard; on every small level proved over
every count that needs no detour it gives the same optimum (keys 3, 6 and 9, ebb and flow 5 and 6, keel 5).

- **Keys scale.** Hex, 24 entries, `6:-5,2:-2,1:+8,6:+4,0:+5,2:+6,5:-3,4:+7,5:-8,3:+2,2:+8,3:+7,0:-7,6:+2,0:-8,6:+5,1:-7,3:-6,4:+4,5:-2,4:-2,5:+4,6:-5,3:-3`,
  ward 2 keyed by knob 4 at +3 and ward 5 by knob 1 at -2 (each pair clear of the other's disc): 29 moves against 24
  without the rule; along the line 20 of 29 steps have one move of several that keeps par, and 76 moves tried there
  lose it, against none without the rule (this deal untwists one way only). 44 ms.
- **Ebb and flow scales.** Hex, 20 entries, `2:-5,6:-2,4:-4,5:-6,1:-2,4:+2,1:-6,4:-8,5:-3,6:-6,4:+2,1:-6,2:+5,1:-6,3:-2,5:-4,0:-6,1:-5,6:+8,2:+6,4:+4,1:-7`:
  30 against 20, 16 steps forced; 0.8 s. On pent, maelstrom's own 18-entry deal
  (`0:-4,4:-5,2:-2,3:-7,2:-8,4:+2,1:+2,2:-3,3:+4,4:+3,3:+3,1:-2,4:-5,2:-3,1:-5,0:-4,4:-7,2:+3`): 31 against 18, 16 forced, 1.6 s.
- **The keel doesn't.** Its final list is fixed by the deal, so a deep deal must balance; balanced deals of 20 to 26
  entries on pent and hex came out at par or one over wherever a line existed (100 deals, keel 8 to 14), and a tighter keel left them with no
  line but detours pushed for their own sake, which neither the player can read nor the deep search proves. The keel
  is out of the pitch.

### Tried and dropped

Each was run through the same solver before any UI was built.

- **Detents** (a knob that clicks two or three steps at a time). It strands, by reasoning (the search on the first
  level tried never returned): a remainder can only go onto a deeper entry of its rod by a fall, and an entry between
  two of one rod's entries comes off only after the newer one has.
- **The relay** (each turn must be of a knob overlapping the last one turned). Solvable, but its lines run to two or
  three times the entries through detours that mean nothing (quad, 3 entries: 7 moves, proved), and the proofs blow
  up past that.
- **Rest** (a knob can't be turned again for two moves). The same: on quad with 4 entries the best line found took 13
  moves, and the proof never finished.

### The standing plan for the rung past maelstrom

Jack's calls already give the rung past maelstrom a name and a mechanic: charybdis (2026-09-28), with Orrery's orbits
(2026-10-24, a crank carrying knobs round at their own rates to sockets) and a rim that turns the tank and swirls it
in one gesture (V4 and R1, 2026-10-25). `Level.Motion.crank` and `sockets` are its stubs; neither has a solver or a
level. The three rules above are alternatives to it or additions to it, and the pitch says so.

## Name and length

- **Charybdis (C)**: the name Jack set aside for this rung on 2026-09-28; the whirlpool of myth, past every real one.
- **Gyre (G)**: an ocean's whole circulation, the largest turning water there is.
- **Abyss (A)**: the deep under the water, where Mineral's rock is; a benched pack's name, never used.

None of the letters is a tier's or a pack's prefix. Length: 27, as every tier has, so the ladder, the menu's
gates, "every tier at par" and the curtain call treat it as the others; 18 if its hex levels can't be proved in time.

## What a fifth `Tier` case touches

Stored values, never to change once shipped: the new raw value (saved as the menu's tier and in analytics' snapshot
keys) and its prefix (every level id, best, started flag and resume). Declaration order is the ladder, so it goes
last.

- `Sources/Levels.swift`: the exhaustive switches `name`, `word`, `prefix`, `levels` and a new level table, with
  `level.C1.title`-style keys. `isOpen` opens it when every maelstrom level has a best, with no change; `store` and
  `stored` follow `allCases`.
- `Sources/Menu.swift` (master's menu, which the slope's redesign will replace): `Level.colour`, `Tier.colours`,
  `Tier.glow` (switches); the chips are a scrolling row, so a fifth fits. `Sources/Tone.swift`: `Tier.ink`, which `ToneTests` holds to 4.5:1. `Sources/Sound.swift`: `Level.bed`
  and, for a bed of its own, a `Bed` case and its file.
- Last-tier logic moves from maelstrom 27 to the new last level: `Completion.free` (Game.swift, `allCases.last`),
  the payoff's whole-game curtain (Payoff.swift, `whole`; its heal notes are a four-item literal, so the fifth name
  gets none until a fifth note is added), and the shelf's ladder-end pointer (Shelf.swift, `ladderEnd`).
- Achievements: only `unstirred` ("every level of every tier at par") reads every tier; it gets harder, keeps its
  meaning, and a player who has earned it keeps it (`due` reports only rises). The per-tier ones open whirlpool,
  vortex and maelstrom; opening the fifth would be a new achievement, a new id with its points, title and shot.
- Daily and endless: untouched; neither reads `Tier` (`testDailyVectors`, `testEndlessVectors` pin them).
- Escapement's tie to maelstrom is its cover's "new" mark once maelstrom is open (`Pack.fits`), not a lock and not
  "the last tier", so it stays as it is.
- Tests to update: `PackTests` (the prefixes' pin), the open-tier arrays in `UnstirTests` (four entries each), the
  ladder-end test, `AchievementTests`' tier pairs, `PayoffTests` and `PlayLayoutTests`' whole-game card (both name
  maelstrom), the per-tier solver tables, and `testTheRimKeysOnMotionAndADiscOnItsKind`, which holds that no level has a crank or sockets, if the tier uses orbits.
- Scripts: `scripts/shots/tiers.sh`, `scripts/film.sh`'s whole-game payoff (its `BESTS`), and a measuring script like
  `scripts/maelstrom-levels.sh`.
