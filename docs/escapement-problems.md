# Escapement: the problem book (draft for Jack, 2026-10-25; Jack's round 9 calls, 2026-10-26; round 11's tick budget; dealt again without the wait, 2026-11-11)

**2026-11-11: no waiting move.** Jack's call: a clock can never be touched. A clock ticks only after a knob's turn, and
a touch on a ratchet shakes it with a thud, as a seized knob's does. The twenty problems whose lines waited (2, 7 to
16, 19 to 22 and 25 to 29) were dealt again on their own layouts, clocks and par, under their ids and titles, by
`scripts/escapement/nowait-book.py`; the other ten stand as they were. Everything below is the book as the app plays
it, `Level.escapement` in `Sources/Pack.swift`, mirrored by `scripts/escapement/problems-nowait.tsv` (a test pins them
equal). `scripts/escapement/problems.tsv` is the book as it was under the waiting move. Every figure in sections 1
and 2 was measured again under the no-wait rule (`ESC_WAIT=0`) on 2026-11-11; a claim of the earlier drafts that
could not be measured again was dropped. Section 3 keeps the pitches as they were put, figures and all.

**Round 11 (Jack's call EL1).** "Par" is not a thing for Escapement. Each tank deals a tick budget, what its clocks owe
in all, and every tick of every clock spends one, so a move with three running clocks spends three. A wrong move no
longer loses at once: its pushed tick buries a seam nothing can take off, and the tank plays on until the budget is spent
with seams left, out of ticks, which only an undo or a reset gets out of. Without a pushed tick the budget is what the
clocks still owe after every move, spent exactly as the last clock stops, so every line, key and proof below stands
(checked on all 30 in the app's `testTheBudgetIsWhatTheClocksOweAlongEveryProblemsLine`). Below, "par" and "lost" are the
analysis's words: par is the moves the slowest clock owes, which no player sees, and a line that "loses" is one that can
only run out of ticks. The player sees the stipulation, **Unstir in N ticks.**, and the ticks left.

Escapement's 30 problems. Every problem was played through the game's own `Array.commit` by the prover in
`scripts/escapement.sh`, under Jack's calls: go with changes (E1), the standing hint (E2), freeze on the +1 (E3), and
the tick final once a move is made (round 2), and since round 9: every let-go final, its loss shown on that lift (round
9 E1, open points J1 and J2), and the problem lost when the last clock stops with twists still on the picture (round 9
E2, open point J4); since 2026-11-11, no waiting move. `ESC_WAIT=0 scripts/escapement.sh book
scripts/escapement/problems-nowait.tsv` proves it again, but its search on 11 was stopped after about six minutes (see 11);
rows 12 to 30, proved one at a time with `check`, took 54 s.

"Checked" means the prover confirmed it on all 30. "Inferred" means it follows from the rule and was not separately
tested.

## 1. The rules as the player meets them

**Before the first stir.** Problem 1 opens on the lab's demonstration, on its own stack (`0:-2,1:+2,0:-1,2:-3` on tri):
a ghost finger heals knob 2's seam and the clock's core steps once; it heals knob 1's and the core steps again, the
clock's last step left on. The picture fades to the bone paper and the problem winds in. Nothing of the problem's
scramble shows during it (round 2: the first level shows the clock working before the first stir).

**The page.** A bone-paper tank with one clock, or two or three. A clock is a rod with a ratchet wheel for a knob, a
vermilion sub-dial with a 12 index on its core, and a dashed vermilion edge round its disc, always drawn (E2). The
dashed edge marks every knob whose disc crosses it. Under the tank, in a serif: **Unstir in N ticks.**, N the budget;
in the corner, the ticks left on a split-flap clock, flipping down one for each clock's tick as it lands.

**A move** is letting go of a working knob anywhere but where the drag began. Turning the same knob again straight
after is a second move with its own tick (the tick is final once the move is made). A look that lets go where it began
is no move and no tick. A clock can't be turned or tapped: a touch on a ratchet shakes it with a thud and is no move.

**The tick.** After every move, every running clock ticks one step: a forward clock clockwise, a wound-back clock
anticlockwise. Its pawl drops a tooth and its core steps 30°. The tick lands on the clock's newest seam and takes one
step off it, provided no stir on a knob crossing its dashed edge lies over that seam. (That is how it looks to the player.
The game's exact test is `Array.commit`'s: everything over the seam must commute with the clock, and now and then a
word of stirs holds a disc still. The proofs used the exact test.) A clock whose seams are all off stops, with a chime.
With two or three clocks, they tick in turn, clockwise from twelve (open point J3).

**A pushed tick.** If a stir inside the dashed edge lies over the clock's newest seam, the tick can't reach it. It makes
a new +1 seam instead, which nothing can ever take off, so the picture can't come whole: the +1 stands by the clock in
vermilion and the ratchet flashes red (E3), but play goes on (round 11, EL1), the clock still running and spending
the budget, until it is out of ticks.

**Out of ticks.** Once the budget is spent with seams still on the picture, no move is left: "out of ticks." stamps the
page by the clock that spent the last, over a card with undo (if the bank has one) and again.

**Solved** when the picture is whole. A tick that empties the stack solves on the spot. If the last clock stops with
seams still on the picture, its tick spent the last of the budget: out of ticks. So a problem is solved at par, with
the budget spent to the last tick, or not at all: without a pushed tick every move takes one step off each running
clock, so the clock that owes most stops on exactly its par-th move (inferred from the rule).

**Variants.** Two Clocks and three: each move ticks every running clock. Wound Back: a clock whose seams were stirred
the other way, ticking −1.

### What the rule leaves to the player

This part is analysis, inferred from the rule.

- **No move is spare.** Every move is a turn, and every turn ticks every running clock, so a problem takes exactly the
  moves its slowest clock owes, and each of them must take a seam off or set one up. There is no move that passes.
- **A seam inside a dashed edge has a fixed move.** It can come off only once the clock seam over it has gone, and it
  must come off on the very next move, or that move's tick finds the clock's next seam covered. The dial sets which
  move that is. A clock seam of k steps that is bare when the problem opens leaves k free moves before the inside seam
  under it falls due. Every seam below that leaves k − 1, because the tick of the inside heal that uncovered it has
  already taken one step off.
- **So the puzzle is triage.** Before each inside seam falls due, the seams that lie over it must be off, in the free
  moves the dial allows. Taking off a loose seam that isn't in the way spends a move the dial counted for one that is.
- **Par is the dial.** Each move takes exactly one step off each running clock, and nothing else turns a clock, so a
  problem can't be solved in fewer moves than its clocks owe. Every par below equals what its clocks owe, so every
  "none shorter" is a proof, not the end of a search (checked: the prover's bound is par on all 30).

### Faces and overlaps

Knobs are numbered as the game numbers rods; `k:+n` turns knob k n steps clockwise (30° each). Scrambles are in the
game's `parse` form, bottom first: the first stir made is first.

| Layout | Knobs by clock position | Discs that overlap |
|---|---|---|
| tri | 0 at 12, 1 at 4, 2 at 8 | every pair |
| quad | 0 at 1:30, 1 at 4:30, 2 at 7:30, 3 at 10:30 | neighbours only; 0 and 2, 1 and 3 never |
| eye | 0 left and 1 right (large), 2 top and 3 bottom (small) | 0 and 1 with everything; 2 and 3 never |
| pent | 0 at 12, then 1, 2, 3, 4 clockwise, 72° apart | neighbours only |
| hex | 0 the hub, 1 at 12, 2 at 2, 3 at 4, 4 at 6, 5 at 8, 6 at 10 | the hub with everything; ring neighbours |

A clock's dashed edge is crossed by exactly the knobs whose discs overlap its own. On tri, on eye's large knobs and on
hex's hub every other knob crosses it, so nothing is ever free there.

## 2. The 30 problems

Five chapters of six, as the pitch set them. Each chapter's first problem adds the chapter's rule to the stipulation
(Jack's call N1, round 13). Problems 1 to 3 are the free taste (to-do 46). Ids are `escapement-1` to `escapement-30`.
The titles are the app's (Jack's call N1: a clock taken apart, Mainspring to Midnight). Problems marked *dealt again*
are the 2026-11-11 deals.

**Proof, for every problem.** *Exists*: the line, replayed through `Array.commit`. *None shorter*: absolute, because par
equals the steps the clocks owe. *Key and line*: a search over every turn of up to ±6 steps on every knob, at each
move, found one first move that reaches par and one line, on every problem but 11, whose search did not finish (see
11). *Lost is lost*: playing on past a pushed tick (`ESC_PUSHED=1`) adds no line of whole heals at par on any of the 30.

**Difficulty** is given in *bits*: minus log2 of the chance that a player who picks uniformly among the whole heals
whose own tick doesn't push solves at par. Bits measure planning only. Reading the seams, which is most of what makes a
tank hard, is not in them. Without the wait most problems leave one safe whole heal a move, so 18 of the 30 measure
0.0 bits and none more than 3.0. The earlier drafts' grades of 1 to 5 were set from bits that counted the wait as a
choice, and are dropped.

Below, a decoy that "loses" pushes a tick on that move; one that "dooms" pushes nothing at once but leaves no line to
par. Each entry names the decoys the prover found along its line; where none is named, no other whole heal is open.

### Chapter 1. The Clock

One forward clock. The opener's rule: "A clock ticks after every move. Each let-go is a move."

**1. Mainspring** (free). tri, clock knob 0. `0:-1,1:+3,0:-1,2:-4`. **Unstir in 2 ticks.**
Line: `2:+4` · `1:-3`.
Knob 2's seam lies over the clock's. Take it off, and the tick takes the clock's top seam with it. That leaves knob 1's
seam newest, and its heal and its tick finish together. What it teaches: every move is answered by one tick. 0.0 bits,
4 seams.

**2. Pendulum** (free, *dealt again*). tri, clock knob 0. `0:-1,2:+4,0:-1,2:+2,0:-1,1:+3`. **Unstir in 3 ticks.**
Line: `1:-3` · `2:-2` · `2:-4`.
Knob 2 is turned twice running, and each turn is its own move with its own tick: the final tick (J1). Under the lab's
re-grab no line of whole heals solves it. 0.0 bits, 6 seams.

**3. Clock face** (free). quad, clock knob 0. `0:-1,1:+3,0:-1,2:-4`. **Unstir in 2 ticks.**
Line: `2:+4` · `1:-3`.
The same scramble as 1 on quad. Knob 2 sits opposite the clock, outside its dashed edge, so turning it ticks the clock
without covering it. 0.0 bits, 4 seams.

**4. Cogwheel.** quad, clock knob 0. `0:-1,3:+2,0:-2,2:-4,1:-3,0:-1,2:-2`. **Unstir in 4 ticks.**
Line: `2:+2` · `1:+3` · `2:+4` · `3:-2`.
The dial is the budget. The clock's top seam is one step, so knob 1 falls due on move 2, and knob 2's top seam lies over
it: knob 2 takes move 1. The next clock seam owes two, so knob 3 falls due on move 4, and knob 2's second seam covers
it: knob 2 takes move 3. 0.0 bits, 7 seams.

**5. Winding key.** eye, clock knob 2 (top). `2:-2,3:-2,1:-4,2:-2,3:-3,1:+3,2:-1,3:-5`. **Unstir in 5 ticks.**
Line: `3:+5` · `1:-3` · `3:+3` · `1:+4` · `3:+2`.
The bottom knob is outside the clock's edge, and knob 1 crosses it. Their seams alternate under clock seams of one, two
and two steps, and each bottom seam lies over the next of knob 1's, so the order is bottom, 1, bottom, 1, bottom. 0.0
bits, 8 seams.

**6. Clockwork.** hex, clock knob 1. `1:-3,4:-2,3:-4,6:+3,1:-2,5:+3,2:-3,1:-1,3:+2`. **Unstir in 6 ticks.**
Line: `3:-2` · `2:+3` · `5:-3` · `6:-3` · `3:+4` · `4:+2`.
Two loose seams outside the edge, one free move. Knob 5's seam is loose from the start, but knob 3's covers knob 2's,
which falls due on move 2, so knob 3 goes first; knob 5 first dooms, and on move 2 it loses. The same choice comes
again on move 3, the other way round: knob 5's seam now covers knob 6's, due on move 4, and knob 3's second seam
doesn't: knob 3 there dooms, and on move 4 it loses. 2.0 bits, 9 seams.

### Chapter 2. Tempo

One forward clock, deeper. The opener's rule: "No move is spare."

**7. Counterweight** (*dealt again*). quad, clock knob 0. `0:-2,2:+3,1:+2,0:-1,3:-3`. **Unstir in 3 ticks.**
Line: `3:+3` · `1:-2` · `2:-3`.
Three seams on working knobs, three ticks owed: every move takes one off, top down. 0.0 bits, 5 seams.

**8. Snooze** (*dealt again*). pent, clock knob 0. `0:-3,2:+3,3:+2,4:-5,0:-2,3:-2,1:-4`. **Unstir in 5 ticks.**
Line: `1:+4` · `3:+2` · `4:+5` · `3:-2` · `2:-3`.
Knob 3's top seam first loses: knob 1 goes first. On move 2 knob 2's seam is loose and dooms. Knob
3's two seams sandwich knob 4's. 1.0 bit, 7 seams.

**9. Hourglass** (*dealt again*). eye, clock knob 2 (top). `2:-2,3:-3,1:+5,2:-2,3:+4,1:-2,2:-2,3:-5,0:+3`.
**Unstir in 6 ticks.**
Line: `0:-3` · `3:+5` · `1:+2` · `3:-4` · `1:-5` · `3:+3`.
The large left knob's seam lies on top: first. Then the bottom knob and knob 1 alternate, bottom, 1, bottom, 1,
bottom. 0.0 bits, 9 seams.

**10. Egg timer** (*dealt again*). pent, clock knob 0. `0:-4,2:+3,3:+2,2:-3,1:+4,0:-2,2:+3,4:+3`. **Unstir in 6 ticks.**
Line: `4:-3` · `2:-3` · `1:-4` · `2:+3` · `3:-2` · `2:-3`.
Knob 2 three times, between knobs 4, 1 and 3. Knob 2 first loses; on move 2, knob 3's seam is loose and dooms. 1.0 bit,
8 seams.

**11. Stopwatch** (*dealt again*). pent, clock knob 0. `0:-6,2:+2,3:+4,2:-2,3:+4,2:-3,1:+3,0:-2,2:+3,4:+5`.
**Unstir in 8 ticks.**
Line: `4:-5` · `2:-3` · `1:-3` · `2:+3` · `3:-4` · `2:+2` · `3:-4` · `2:-2`.
The clock's bottom seam owes six. Knob 2 four times, its seams interleaved with knob 1's and knob 3's two. Knob 2 first
loses; on move 2, knob 3's top seam is loose and dooms. 1.0 bit, 10 seams. **Proof:** the line exists, none is shorter
(absolute), and it is the one line of whole heals; the search over every turn of up to ±6 steps for a second line or
key did not finish (stopped after about six minutes of the book run, and in `nowait-book.py`'s 40 s limit), so 11 rests on its one proved line.

**12. Standstill** (*dealt again*). hex, clock knob 1. `1:-2,3:-3,6:+3,1:-2,5:-2,2:+5,1:-3,3:+5,4:+3,0:+2`.
**Unstir in 7 ticks.**
Line: `0:-2` · `4:-3` · `3:-5` · `2:-5` · `5:+2` · `6:-3` · `3:+3`.
The hub's seam lies on top: first. Knob 5's seam is loose from move 3 and wrong until move 5 (it dooms on 3 and loses
on 4); knob 3's bottom seam is loose from move 5 and wrong until move 7 (dooms on 5, loses on 6). 2.0 bits, 10 seams.

### Chapter 3. Two Clocks

Each move ticks both, clockwise from twelve. The dials stop separately. The opener's rule: "Two clocks tick in turn."

**13. Twin dials** (*dealt again*). quad, clocks knobs 0 and 2. `0:-1,1:+5,2:-1,0:-1,3:+3,2:-1,0:-1,1:-5`.
**Unstir in 5 ticks.**
Line: `1:+5` · `3:-3` · `1:-5`.
Knobs 1 and 3 each cross both clocks. Clock 2 owes two and stops after the second move; clock 0 owes three and ticks
on through the last. 0.0 bits, 8 seams.

**14. Hour hand** (*dealt again*). quad, clocks knobs 0 and 2. `2:-1,1:+5,2:-1,1:+4,2:-1,0:-1,1:-5,2:-1,0:-1,3:+5`.
**Unstir in 6 ticks.**
Line: `3:-5` · `1:+5` · `1:-4` · `1:-5`.
Knob 3, then knob 1 three times running, each turn its own move. Clock 0 owes two and stops after move 2; clock 2 owes
four. Under the lab's re-grab no line of whole heals solves it. 0.0 bits, 10 seams.

**15. Minute hand** (*dealt again*). pent, clocks knobs 0 and 2. `2:-4,4:+2,0:-1,4:+5,0:-1,4:-4,0:-2,3:+5,2:-1,1:+5`.
**Unstir in 9 ticks.**
Line: `1:-5` · `3:-5` · `4:+4` · `4:-5` · `4:-2`.
Knob 4 three times running to finish, its seams interleaved with clock 0's. Clock 0 owes four, clock 2 five. Under the
lab's re-grab no line of whole heals solves it. 0.0 bits, 10 seams.

**16. Metronome** (*dealt again*). hex, clocks knobs 1 and 4 (twelve and six).
`4:-2,2:-2,5:+4,4:-2,6:+2,1:-2,3:-4,4:-2,6:+5,1:-1,0:-3`. **Unstir in 9 ticks.**
Line: `0:+3` · `6:-5` · `3:+4` · `6:-2` · `5:-4` · `2:+2`.
The hub's seam covers both clocks: first. The clock at twelve owes three and stops after move 3; the clock at six owes
six. Knob 2's seam is loose from move 4 and is the last move (it dooms on 4 and loses on 5). 1.0 bit, 11 seams.

**17. Chime.** pent, clocks knobs 0 and 1 (neighbours). `1:-3,3:+4,4:-3,0:-1,3:-5,1:-1,0:-1,4:+2,1:-1,0:-1,3:+5`.
**Unstir in 8 ticks.**
Line: `3:-5` · `4:-2` · `3:+5` · `4:+3` · `3:-4`.
The clocks overlap, with each of clock 1's seams under one of clock 0's. On each move clock 0 ticks first and takes its
top seam off, which uncovers clock 1's for its tick on the same move. Knobs 3 and 4 alternate. With the tick order
reversed no line of whole heals solves it (J3). 0.0 bits, 11 seams.

**18. Cuckoo clock.** hex, clocks knobs 1 and 2 (twelve and two).
`2:-2,6:+2,3:-4,2:-2,4:-2,1:-1,5:+2,2:-1,1:-1,4:+4,2:-1,1:-1,5:-4`. **Unstir in 9 ticks.**
Line: `5:+4` · `4:-4` · `5:-2` · `4:+2` · `3:+4` · `6:-2`.
Paired clocks, the one at twelve uncovering the one at two on every move. Knobs 4 and 5 are outside both and feed four
moves, in the one alternation that keeps both dials' seams bare. Then knob 3 (crossing the clock at two) and knob 6
(crossing twelve) finish. On move 4 knob 6's seam is loose and dooms; on move 5 it loses. Order-dependent like 17. 1.0
bit, 13 seams.

### Chapter 4. Wound Back

A clock ticking −1 over seams stirred the other way. From 20 on, it shares the tank with a forward clock. The opener's
rule: "A wound-back clock ticks the other way."

**19. Rewind** (*dealt again*). tri, clock knob 0 wound back. `0:+1,2:+4,0:+1,2:+2,0:+1,1:+3`. **Unstir in 3 ticks.**
Line: `1:-3` · `2:-2` · `2:-4`.
Problem 2 with the clock's seams stirred anticlockwise: its core steps back, and the working knobs' seams and the line
are the same. Under the lab's re-grab no line of whole heals solves it. 0.0 bits, 6 seams.

**20. Fall back** (*dealt again*). quad, clock knob 0 forward and knob 2 wound back.
`2:+1,1:+5,2:+1,1:+4,2:+1,0:-1,1:-5,2:+1,0:-1,3:+5,2:+1,0:-1,3:+3`. **Unstir in 8 ticks.**
Line: `3:-3` · `3:-5` · `1:+5` · `1:-4` · `1:-5`.
Opposite clocks, opposite senses. Knob 3 twice running, then knob 1 three times, each turn its own move. The forward
clock owes three and stops after move 3; the wound-back one owes five. Under the lab's re-grab no line of whole heals
solves it. 0.0 bits, 13 seams.

**21. Mirror dial** (*dealt again*). pent, clock knob 0 wound back and knob 2 forward.
`2:-2,4:+2,3:-3,2:-4,4:-3,0:+1,4:-5,0:+1,4:-3,0:+1,1:-3`. **Unstir in 9 ticks.**
Line: `1:+3` · `4:+3` · `4:+5` · `4:+3` · `3:+3` · `4:-2`.
Knob 1 sits between the clocks: first. Then knob 4 three times running. The wound-back clock at twelve owes three and
stops after move 3; the forward one owes six. Under the lab's re-grab no line of whole heals solves it. 0.0 bits, 11
seams.

**22. Anticlockwise** (*dealt again*). hex, clock knob 1 forward and knob 4 wound back.
`4:+2,6:+5,3:+4,4:+3,2:+4,1:-1,2:+4,1:-3,5:-2,4:+1,5:+5,4:+1,0:+5`. **Unstir in 11 ticks.**
Line: `0:-5` · `5:-5` · `5:+2` · `2:-4` · `2:-4` · `3:-4` · `6:-5`.
The hub first, then knobs 5 and 2 each twice running. The clock at twelve owes four and stops after move 4; the
wound-back clock at six owes seven. Knob 6's seam is loose from move 5 and is the last move (it dooms on 5 and loses
on 6). Under the lab's re-grab no line of whole heals solves it. 1.0 bit, 13 seams.

**23. Overwound.** pent, clock knob 0 wound back. `0:+2,3:-5,4:-5,0:+3,2:-2,3:+4,4:-3,0:+1,3:-4`. **Unstir in 6 ticks.**
Line: `3:+4` · `4:+3` · `3:-4` · `2:+2` · `4:+5` · `3:+5`.
Wound back, counted as ever. Knob 2's seam is loose at the start and dooms, since knob 3's covers knob 4's, due on
move 2. The order is 3, 4, 3, then knob 2 in its one free move, then 4, 3. 1.0 bit, 9 seams.

**24. Reverse.** hex, clock knob 1 wound back. `1:+3,4:-2,5:+4,2:+2,1:+2,3:+3,2:-5,1:+2,3:+2,6:-2`. **Unstir in 7 ticks.**
Line: `6:+2` · `3:-2` · `2:+5` · `3:-3` · `2:-2` · `5:-4` · `4:+2`.
Knob 6's seam covers the clock, so it goes first, though knob 3's looks newer and is loose: knob 3 first loses at once.
Then knobs 3 and 2 alternate. Knob 5 is loose on every move from the second and wrong until the sixth. 2.0 bits, 10
seams.

### Chapter 5. Grand Complication

Deep pent and hex, and three clocks. The opener's rule: "Three clocks."

**25. Moon phase** (*dealt again*). hex, clocks knobs 1, 3 and 5. `5:-2,2:+4,3:-1,1:-2,4:+2,5:-1,3:-1,6:-5`.
**Unstir in 7 ticks.**
Line: `6:+5` · `4:-2` · `2:-4`.
Three dials owing two, two and three: each move ticks every one still running. The clocks at twelve and four stop
after move 2, the clock at eight after move 3. 0.0 bits, 8 seams.

**26. Calendar** (*dealt again*). pent, clocks knobs 0 and 2.
`0:-2,3:-4,4:+3,0:-1,1:-5,0:-2,3:+5,2:-4,4:+3,0:-1,4:-4,0:-1,4:-3,0:-1,4:+5`. **Unstir in 12 ticks.**
Line: `4:-5` · `4:+3` · `4:+4` · `4:-3` · `3:-5` · `1:+5` · `4:-3` · `3:+4`.
Knob 4 four times running to open, while clock 2, owing four, runs down and stops after move 4; clock 0 owes eight.
Under the lab's re-grab no line of whole heals solves it. 0.0 bits, 15 seams.

**27. Time zones** (*dealt again*). pent, clock knob 0. `0:-5,3:-2,2:-4,3:-2,2:-2,1:-2,0:-2,2:+2,1:+3,0:-1,1:-4,0:-1,4:+3`.
**Unstir in 9 ticks.**
Line: `4:-3` · `1:+4` · `1:-3` · `2:-2` · `1:+2` · `2:+2` · `3:+2` · `2:+4` · `3:+2`.
Thirteen seams in nine moves. Knob 1 twice running on moves 2 and 3. Knob 3's top seam is open on moves 2 to 4 and
wrong there (it loses on 2 and 3 and dooms on 4), covered on 5 and 6, and played on 7. Under the lab's re-grab no line of whole heals solves it. 1.0
bit, 13 seams.

**28. Leap year** (*dealt again*). hex, clock knob 1.
`1:-1,2:-3,1:-3,4:-4,5:-3,2:+3,1:-2,3:-2,6:-2,1:-2,5:-3,6:+5,1:-1,5:+5`. **Unstir in 9 ticks.**
Line: `5:-5` · `6:-5` · `5:+3` · `6:+2` · `3:+2` · `2:-3` · `5:+3` · `4:+4` · `2:+3`.
Knobs 5 and 6 alternate for four moves while knob 3's seam is loose and wrong (it dooms on moves 1 and 3, loses on 2
and 4); then knob 5's last seam is loose and wrong for two (dooms on 5, loses on 6). The book's most bits: 3.0, 14
seams.

**29. Eleventh hour** (*dealt again*). hex, clocks knobs 1, 3 and 5.
`5:-2,2:-3,0:-5,5:-2,2:+5,4:+5,5:-2,3:-1,1:-1,2:+3,3:-2,1:-1,6:+3,5:-1,1:-2,4:-3,5:-1,3:-1,0:+5`.
**Unstir in 16 ticks.**
Line: `0:-5` · `4:+3` · `6:-3` · `2:-3` · `4:-5` · `2:-5` · `0:+5` · `2:+3`.
Three clocks cross every knob, and the work is reading which turn is safe. The clocks at
twelve and four owe four each and stop after move 4; the clock at eight owes eight. The hub opens and comes back on
move 7. On move 5 knob 2's seam is open and loses. 0.0 bits, 19 seams.

**30. Midnight** (finale). hex, clocks knobs 1 and 3 (twelve and four).
`1:-4,5:+2,4:+2,5:+3,6:-4,3:-2,1:-4,5:-4,4:+5,3:-2,5:-3,0:+2`. **Unstir in 12 ticks.**
Line: `0:-2` · `5:+3` · `4:-5` · `5:+4` · `6:+4` · `5:-3` · `4:-2` · `5:-2`.
The hub's seam covers both clocks: first. Knob 5 is outside both and has four seams. They are the tempo between knob 4's
seams (crossing four o'clock) and knob 6's (crossing twelve), each taken in the one move that fits. 0.0 bits, 12 seams.

### The book at a glance

| # | Title | Layout | Clocks | Moves | Ticks | Seams | Key | Bits | Lines at par (whole / over turns to ±6) |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Mainspring | tri | 0 | 2 | 2 | 4 | 2:+4 | 0.0 | 1 / 1 |
| 2 | Pendulum | tri | 0 | 3 | 3 | 6 | 1:-3 | 0.0 | 1 / 1 |
| 3 | Clock face | quad | 0 | 2 | 2 | 4 | 2:+4 | 0.0 | 1 / 1 |
| 4 | Cogwheel | quad | 0 | 4 | 4 | 7 | 2:+2 | 0.0 | 1 / 1 |
| 5 | Winding key | eye | 2 | 5 | 5 | 8 | 3:+5 | 0.0 | 1 / 1 |
| 6 | Clockwork | hex | 1 | 6 | 6 | 9 | 3:-2 | 2.0 | 1 / 1 |
| 7 | Counterweight | quad | 0 | 3 | 3 | 5 | 3:+3 | 0.0 | 1 / 1 |
| 8 | Snooze | pent | 0 | 5 | 5 | 7 | 1:+4 | 1.0 | 1 / 1 |
| 9 | Hourglass | eye | 2 | 6 | 6 | 9 | 0:-3 | 0.0 | 1 / 1 |
| 10 | Egg timer | pent | 0 | 6 | 6 | 8 | 4:-3 | 1.0 | 1 / 1 |
| 11 | Stopwatch | pent | 0 | 8 | 8 | 10 | 4:-5 | 1.0 | 1 / not finished |
| 12 | Standstill | hex | 1 | 7 | 7 | 10 | 0:-2 | 2.0 | 1 / 1 |
| 13 | Twin dials | quad | 0, 2 | 3 | 5 | 8 | 1:+5 | 0.0 | 1 / 1 |
| 14 | Hour hand | quad | 0, 2 | 4 | 6 | 10 | 3:-5 | 0.0 | 1 / 1 |
| 15 | Minute hand | pent | 0, 2 | 5 | 9 | 10 | 1:-5 | 0.0 | 1 / 1 |
| 16 | Metronome | hex | 1, 4 | 6 | 9 | 11 | 0:+3 | 1.0 | 1 / 1 |
| 17 | Chime | pent | 0, 1 | 5 | 8 | 11 | 3:-5 | 0.0 | 1 / 1 |
| 18 | Cuckoo clock | hex | 1, 2 | 6 | 9 | 13 | 5:+4 | 1.0 | 1 / 1 |
| 19 | Rewind | tri | 0 back | 3 | 3 | 6 | 1:-3 | 0.0 | 1 / 1 |
| 20 | Fall back | quad | 0, 2 back | 5 | 8 | 13 | 3:-3 | 0.0 | 1 / 1 |
| 21 | Mirror dial | pent | 0 back, 2 | 6 | 9 | 11 | 1:+3 | 0.0 | 1 / 1 |
| 22 | Anticlockwise | hex | 1, 4 back | 7 | 11 | 13 | 0:-5 | 1.0 | 1 / 1 |
| 23 | Overwound | pent | 0 back | 6 | 6 | 9 | 3:+4 | 1.0 | 1 / 1 |
| 24 | Reverse | hex | 1 back | 7 | 7 | 10 | 6:+2 | 2.0 | 1 / 1 |
| 25 | Moon phase | hex | 1, 3, 5 | 3 | 7 | 8 | 6:+5 | 0.0 | 1 / 1 |
| 26 | Calendar | pent | 0, 2 | 8 | 12 | 15 | 4:-5 | 0.0 | 1 / 1 |
| 27 | Time zones | pent | 0 | 9 | 9 | 13 | 4:-3 | 1.0 | 1 / 1 |
| 28 | Leap year | hex | 1 | 9 | 9 | 14 | 5:-5 | 3.0 | 1 / 1 |
| 29 | Eleventh hour | hex | 1, 3, 5 | 8 | 16 | 19 | 0:-5 | 0.0 | 1 / 1 |
| 30 | Midnight | hex | 1, 3 | 8 | 12 | 12 | 0:-2 | 0.0 | 1 / 1 |

All 30: exists, none shorter (absolute); all but 11, one key and one line over every turn of up to ±6 steps.

**How they were made.** Problems 1 and 3 were composed by hand. The other 28 were dealt by the prover's `build` mode,
which works backwards from a random line, so every deal is solvable at exactly its dial. The eight that stand from the
first draft (4, 5, 6, 17, 18, 23, 24 and 30) were kept with one line in whole heals and chosen by hand for an idea
each. The twenty dealt again on 2026-11-11 were picked by `nowait-book.py`, which takes, for each slot, the deal on its
layout, clocks and par that measures hardest (most bits, then most heals on its line that would miss par, then the
other tie-breaks its header lists) among those with one line of whole heals, passing over any that a search over every
turn of up to ±6 steps shows has a second line or key. None was edited after the deal, so the lines are what the search
found, not a composer's polish.

## 3. Open points for Jack

These are the pitches as they were put, with Jack's calls under them. Figures measured again without the wait are
added under each, dated.

**J1. A second turn of the knob just moved.**
- A: a new move with its own tick. This is the round-2 call read literally; the book is proved under it.
- B: the lab's re-grab. Taking the open stir's knob again lifts its tick out, and letting go lands one tick for the net
  turn, so a wrong turn turned straight back costs nothing.

Under B, 27 of the 30 keep their par and line. 15, 20 and 27 can't be solved, because their lines turn one knob twice
running. B is also free turn-backs by another name, which round 2 ruled out. **Recommendation: A**, and take the lab's
lift-out out when the pack is built (to-do 34 still describes it).

**Jack's call (2026-10-26, round 9 E1): A.** Every let-go is final: the clock clicks on the lift, and no re-grab takes
it back.

*Measured again without the wait (2026-11-11):* under B, nine problems have no line of whole heals: 2, 14, 15, 19, 20,
21, 22, 26 and 27, each of whose lines turns one knob twice running.

**J2. When a loss shows.** The tick lands on the lift, final.
- A: "lost." stamps on the lift whose tick pushes, frozen on the +1.
- B: it stamps on the next move, as the lab plays (there, a re-grab could still lift the tick out).

Under J1's A there is nothing the next move can undo, so B only delays the news. **Recommendation: A.**

**Jack's call (2026-10-26, round 9 E1): A.** A losing click shows "lost." at once.

**J3. Tick order with two or three clocks.** "The clock nearer twelve first" ties on every layout: quad's 0 and 3, pent's
1 and 4, hex's 2 and 6, 3 and 5.
- A: clockwise from twelve, the hand's sweep.
- B: nearer twelve, with clockwise breaking a tie.
- C: one clock per move, alternating.

The order matters only where clocks overlap. 17 and 18 can't be solved with their order reversed; every other two- or
three-clock problem is unaffected. A and B give the same order for every pair in the book. **Recommendation: A**, shown by
the clocks' sub-dials lighting in a sweep from twelve as they tick.

*Measured again without the wait (2026-11-11):* with the order reversed, 17 and 18 have no line of whole heals; the
other eleven two- and three-clock problems keep a line of whole heals at par.

**J4. The clock stops on an unfinished picture.** A player who taps where a seam was due can see every clock stop with
seams still on the picture.
- A: finish over par, as in the tiers; the best shows the over.
- B: the problem is failed when the last clock stops, since the stipulation is "in N", and the card offers undo and
  again, as for "lost.".

**Recommendation: A.** The pack already has one harsh end, and over par reads the same as everywhere else in the game.

**Jack's call (2026-10-26, round 9 E2): B.** If the last clock stops with twists still on the picture, the problem
fails, shown as lost like a bad click. Re-proved under it: every par, key and line stands; every problem is now solved
at par or lost, and 15 measure one bit less (see Difficulty).

**J5. Waits are forced, never chosen.** Every move ticks every clock alike, so a tap is right exactly when nothing can be
taken off. The pitch's "knowing when to wait" is really knowing when nothing is loose. The decision the rule leaves is
triage: which loose seams to take in the moves the dial allows.
- A: keep the rule; The Waiting Move is about the quiet move, often the key, as drafted.
- B: change the rule so a wait can be a choice.

Any rule that ticks every move alike keeps waits forced. B means giving moves different tempo, for example ticking by
the steps turned, which breaks the "always the same +1, known before the first move" that answers R5. **Recommendation:
A.** Triage under the dial reaches 4 to 5 bits on hex (5 to 6 in the first draft, before E2), and Jack called go on the lab's rule (E1).

*Superseded (2026-11-11):* Jack's call took the waiting move out; a clock can never be touched. Chapter 2 now plays as Tempo.

**J6. The finale.** Three clocks on hex cross every knob, so 25 and the three-clock hex have at most one safe turn a
move: a reading test, 2.0 bits.
- A: end on 30, the three-clock hex, as the pitch planned.
- B: end on 29, two clocks on hex at 4.0 bits, with the three-clock problem as 29.

**Recommendation: B.** A book should end on its hardest problem, and three dials still get their moment one page before.
Since E2, the two-clock hex (then 29) measures 4.0 bits (5.0 in the first draft) and 28 4.6, so by bits alone 28 is now the chapter's hardest;
Jack's play of the book (E3) settles the order of the last problems.

**Jack's call (2026-10-28, round 11 J6): B.** The book ends on the two-clock hex, now 30, the finale; the three-clock
hex is 29, one page before.

*Measured again without the wait (2026-11-11):* 30 measures 0.0 bits, 29 (dealt again) 0.0, and 28 (dealt again) 3.0,
the book's most.

**J7. Wound Back mirrors The Clock.** A wound-back clock alone plays exactly as a forward one with every sign flipped
(19 is 2 mirrored).
- A: keep the chapter, with one teacher, two single wound-back clocks and three that mix directions. Reading two dials
  turning opposite ways is its own difficulty.
- B: fold the mixed problems into Two Clocks and give chapter 4 a new idea.

**Recommendation: A.** It costs no new rule, and the mixed dials are the chapter's real content.

*Since 2026-11-11:* 19 and 2 were both dealt again; 19 is 2 with only the clock's seams stirred the other way, and its
line is 2's.

**J8. Lines with detours in 9 and 11.** Each has one line in whole heals and waits, but 13 and 25 lines at par once a
detour may stand in for two taps (one step on a free knob and back).
- A: accept them; the idea is the same.
- B: replace both with problems that have one line at par counting detours, which rules out most problems ending on two
  or more taps.

**Recommendation: A.**

*Superseded (2026-11-11):* no problem waits; 9 and 11 were dealt again. 9 has one line over every turn of up to ±6
steps; 11's search did not finish (see 11).

**J9. How "composed" they are.** 23 of the 30 were dealt by search and chosen by hand, not composed move by move.
- A: accept the method. Jack plays the draft on the phone in the lab, vetoes any that feel dealt, and replacements come
  from the same search.
- B: compose every problem by hand.

B costs days for problems the prover already shows are sound. **Recommendation: A**, with the cold read of 1 to 3 on a new
player (to-do 46) before the free taste is fixed.

**Jack's call (2026-10-26, round 9 E3): A.** Searched problems are fine once Jack has played them on the phone and
vetoed any that feel random; replacements come from the same search.

*Since 2026-11-11:* 28 of the 30 are dealt; the twenty dealt again were picked by `nowait-book.py`, not by hand.
