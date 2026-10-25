# Escapement: the problem book (draft for Jack, 2026-10-25)

Escapement's 30 problems, to-do 39, for Jack before any code. Nothing here is built in the app. Every problem was played
through the game's own `Array.commit` by the prover in `scripts/escapement.sh`, under Jack's calls: go with changes (E1),
the standing hint (E2), freeze on the +1 (E3), and the tick final once a move is made (round 2). The table behind this
page is `scripts/escapement/problems.tsv`; `scripts/escapement.sh book scripts/escapement/problems.tsv` proves it again
(about eight minutes).

"Checked" means the prover confirmed it on all 30. "Inferred" means it follows from the rule and was not separately
tested.

## 1. The rules as the player meets them

**Before the first stir.** Problem 1 opens on the lab's demonstration, on its own stack (`0:-3,1:+2` on tri): a ghost
finger turns knob 1 two steps back, the clock's core steps once; the ghost taps the ratchet, the core steps again. The
page dips to black and the problem winds in. Nothing of the problem's scramble shows during it (round 2: the first
level shows the clock working before the first stir).

**The page.** A bone-paper tank with one clock, or two or three. A clock is a rod with a ratchet wheel for a knob, a
vermilion sub-dial with a 12 index on its core, and a dashed vermilion edge round its disc, always drawn (E2). The
dashed edge marks every knob whose disc crosses it. Under the tank, in a serif: **Unstir in N.**

**A move** is one of two things:
- letting go of a working knob anywhere but where the drag began. Turning the same knob again straight after is a
  second move with its own tick (the tick is final once the move is made);
- tapping a ratchet: a wait.

A look that lets go where it began is no move and no tick. The clock can't be turned.

**The tick.** After every move, every running clock ticks one step: a forward clock clockwise, a wound-back clock
anticlockwise. Its pawl drops a tooth and its core steps 30°. The tick lands on the clock's newest seam and takes one
step off it, provided no stir on a knob crossing its dashed edge lies over that seam. A clock whose seams are all off
stops, with a chime. With two or three clocks, they tick in turn, clockwise from twelve (open point J3).

**Lost.** If a stir inside the dashed edge lies over the clock's newest seam, the tick can't reach it. It makes a new
+1 seam instead, which nothing can ever take off: the problem is lost. The +1 freezes on the clock's core in vermilion,
the ratchet flashes red and "lost." stamps the page (E3), over a card with undo (if the bank has one) and again. The
tick lands on the lift, so the loss shows on that lift (open point J2).

**Solved** when the picture is whole. A tick that empties the stack solves on the spot. If the clock stops with seams
still on the picture, the rest is plain unstirring, over par (open point J4).

**Variants.** Two Clocks and three: each move ticks every running clock, and either ratchet waits. Wound Back: a clock
whose seams were stirred the other way, ticking −1.

### What the rule leaves to the player

This part is analysis. It is inferred from the rule, and the prover found it true on every line of the 30.

- **A seam inside a dashed edge has a fixed move.** It can come off only once the clock seam over it has gone, and it
  must come off on the very next move, or that move's tick lands on it. The dial sets which move that is: a clock seam
  of k steps leaves k − 1 free moves before the inside seam under it falls due, since the inside seam itself takes the
  move after the clock seam's last tick.
- **A wait is never a choice.** Every move ticks every clock alike, so taking off a loose seam outside every edge is
  never worse than a tap. A tap is right exactly when nothing can be taken off. Checked: at every wait in the 30 lines,
  no seam on the picture could be taken off whole.
- **So the puzzle is triage.** Before each inside seam falls due, the seams that lie over it must be off, in the free
  moves the dial allows. Taking off a loose seam that isn't in the way spends a move the dial counted for one that is.
  Waiting where a seam was due misses par or loses.
- **Par is the dial.** Each move takes exactly one step off each running clock, and nothing else turns a clock, so a
  problem can't be solved in fewer moves than its clocks owe. Every par below equals what its clocks owe, so every
  "none shorter" is a proof, not the end of a search.

### Faces and overlaps

Knobs are numbered as the game numbers rods; `k:+n` turns knob k n steps clockwise (30° each), and `wait` taps the
ratchet. Scrambles are in the game's `parse` form, bottom first: the first stir made is first.

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

Five chapters of six, as the pitch set them. Each opens on a problem that teaches without words (marked *teaches*).
Problems 1 to 3 are the free taste (to-do 46): the tick, the wait, the dashed edge. Ids are `escapement-1` to
`escapement-30`.

**Proof, for every problem.** *Exists*: the line, replayed through `Array.commit`. *None shorter*: absolute, because par
equals the steps the clocks owe. *Key and line*: a search over every turn of up to ±6 steps on every knob, and the wait,
at each move, found one first move that reaches par and one line. The two exceptions (9 and 11) are noted. *Lost is
lost*: playing on past a pushed tick, no line of whole heals and waits reaches par on any of the 30.

**Difficulty** is 1 to 5, Claude's grade. It is set from *bits*: minus log2 of the chance that a player who picks
uniformly among the whole heals and waits that don't lose at once solves at par. Seam count is weighed in too. Bits
measure planning only. Reading the seams, which is most of what makes a tank hard, is not in them.

### Chapter 1. The Clock

One forward clock. From problem 4 on, no move is spare: every move takes off a seam.

**1. The tick** (*teaches*, free). tri, clock knob 0. `0:-1,1:+3,0:-1,2:-4`. **Unstir in 2.**
Line: `2:+4` · `1:-3`.
Knob 2's seam lies over the clock's. Take it off, and the tick takes the clock's top seam with it. That leaves knob 1's
seam newest, and its heal and its tick finish together. What it teaches: every move is answered by one tick. Decoy: a
tap first ticks onto a covered seam and loses. Difficulty 1 (0.0 bits, 4 seams).

**2. The wait** (*teaches*, free; the packs mock-up's problem). tri, clock knob 0. `0:-1,1:+3,0:-2,2:-4`. **Unstir in 3.**
Line: `2:+4` · `wait` · `1:-3`.
After knob 2, the clock's second seam still owes a step, and knob 1's seam lies under it: nothing can be turned. Tap the
ratchet. Decoy: turning knob 1 on move 2 lays a new seam over the clock and loses. Difficulty 1 (0.0 bits, 4 seams).

**3. The dashed edge** (*teaches*, free). quad, clock knob 0. `0:-1,1:+3,0:-1,2:-4`. **Unstir in 2.**
Line: `2:+4` · `1:-3`.
The same scramble as 1 on quad. Knob 2 sits opposite the clock, outside its dashed edge, so turning it ticks the clock
without covering it. The tap looks safe, since the clock's seam is bare, but it spends the one move knob 2's seam
needed: that seam lies over knob 1's, which falls due on move 2. Difficulty 1 (1.0 bit, 4 seams).

**4.** quad, clock knob 0. `0:-1,3:+2,0:-2,2:-4,1:-3,0:-1,2:-2`. **Unstir in 4.**
Line: `2:+2` · `1:+3` · `2:+4` · `3:-2`.
The dial is the budget. The clock's top seam is one step, so knob 1 falls due on move 2, and knob 2's top seam lies over
it: knob 2 takes move 1. The next clock seam owes two, so knob 3 falls due on move 4, and knob 2's second seam covers
it: knob 2 takes move 3. A tap anywhere misses par. Difficulty 2 (2.0 bits, 7 seams).

**5.** eye, clock knob 2 (top). `2:-2,3:-2,1:-4,2:-2,3:-3,1:+3,2:-1,3:-5`. **Unstir in 5.**
Line: `3:+5` · `1:-3` · `3:+3` · `1:+4` · `3:+2`.
The bottom knob is outside the clock's edge, and knob 1 crosses it. Their seams alternate under clock seams of one, two
and two steps, and each bottom seam lies over the next of knob 1's, so the order is bottom, 1, bottom, 1, bottom. A tap
breaks it. Difficulty 3 (3.0 bits, 8 seams).

**6.** hex, clock knob 1. `1:-3,4:-2,3:-4,6:+3,1:-2,5:+3,2:-3,1:-1,3:+2`. **Unstir in 6.**
Line: `3:-2` · `2:+3` · `5:-3` · `6:-3` · `3:+4` · `4:+2`.
Two loose seams outside the edge, one free move. Knob 5's seam is loose from the start, but knob 3's covers knob 2's,
which falls due on move 2, so knob 3 goes first. The same choice comes again on move 3, the other way round: knob 5's
seam now covers knob 6's, due on move 4, and knob 3's second seam doesn't. Difficulty 5 (5.2 bits, 9 seams).

### Chapter 2. The Waiting Move

Slack to burn, and each tap is placed where nothing can be taken off (see "A wait is never a choice").

**7. The quiet first move** (*teaches*). quad, clock knob 0. `0:-2,2:+3,1:-2,0:-1`. **Unstir in 3.**
Line: `wait` · `1:+2` · `2:-3`.
Nothing is loose: knob 1's seam lies under the clock's, and knob 2's under knob 1's. The first move is a tap. Decoys:
knob 1 first loses at once; turning knob 2 back by its seam's steps lays a new seam instead and misses par. Difficulty 1
(1.0 bit, 4 seams).

**8.** pent, clock knob 0. `0:-1,1:+4,0:-3,2:-4,3:-3,4:-5,0:-1`. **Unstir in 5.**
Line: `wait` · `4:+5` · `3:+3` · `2:+4` · `1:-4`.
A quiet key, then no slack. Knob 4's seam lies under the clock's one-step seam, and knobs 3 and 2 lie under knob 4's:
tap. After knob 4, the clock's three-step seam gives exactly the two moves that knobs 3 and 2 need before knob 1 falls
due. Difficulty 2 (2.0 bits, 7 seams).

**9.** eye, clock knob 2 (top). `2:-3,0:+3,2:-2,3:+4,0:-3,2:-1,3:+3`. **Unstir in 6.**
Line: `3:-3` · `0:+3` · `3:-4` · `0:-3` · `wait` · `wait`.
The last stir on the picture is the clock's own. After four heals it still owes two steps on its bottom seam, and only
taps take them off. Two taps are the finish, not a pause. One line in whole heals and waits; 13 at par if a detour may
stand in for the two taps (one step on the bottom knob and back). Difficulty 2 (2.0 bits, 7 seams).

**10.** pent, clock knob 0. `0:-3,3:+3,2:-3,1:-2,0:-2,1:-4,0:-1,2:+3`. **Unstir in 6.**
Line: `2:-3` · `1:+4` · `wait` · `1:+2` · `2:+3` · `3:-3`.
Knob 3's seam is loose at the start, since the stirs over it hold its disc still, but knob 2's covers knob 1's, due on
move 2. Knob 2 goes first. After knob 1 nothing is loose for a move: tap, then knob 1 again, knob 2, knob 3. Difficulty
3 (3.6 bits, 8 seams).

**11.** pent, clock knob 0. `0:-3,1:+2,0:-2,2:+3,4:+5,0:-2,3:+2,4:-3,0:-1,3:-2`. **Unstir in 8.**
Line: `3:+2` · `4:+3` · `3:-2` · `4:-5` · `2:-3` · `1:-2` · `wait` · `wait`.
Knob 3's two seams sandwich knob 4's first, so the opening is 3, 4, 3, 4 with no move to spare. All the while knob 2's
seam is loose and tempting from move 1, but its place is move 5. The clock's bottom seam owes three, so the
problem ends on two taps. One line in whole heals and waits; 25 at par counting detours. Difficulty 4 (3.6 bits, 10
seams).

**12.** hex, clock knob 1. `1:-2,5:+4,2:+5,1:-2,3:+3,2:-3,1:-2,3:-4,0:-5,1:-1`. **Unstir in 7.**
Line: `wait` · `0:+5` · `3:+4` · `2:+3` · `3:-3` · `2:-5` · `5:-4`.
The hub's seam lies under the clock's one step: tap first. From move 3 knob 5's seam is loose on every move and wrong
until the last one. Each free move belongs to the knob 3 seam over knob 2's next. Knob 5 is the decoy four times.
Difficulty 4 (4.2 bits, 10 seams).

### Chapter 3. Two Clocks

Each move ticks both, clockwise from twelve. The dials stop separately.

**13. Two dials** (*teaches*). quad, clocks knobs 0 and 2. `0:-1,2:-2,1:+3,0:-1,2:-1,3:+2`. **Unstir in 3.**
Line: `3:-2` · `1:-3` · `wait`.
Knob 3's seam covers both clocks, then knob 1's does. Clock 0 stops after the second move with a chime, and clock 2
still owes a step: a tap. What it teaches: both clocks tick, and one can stop before the other. Difficulty 1 (0.0 bits,
6 seams).

**14.** quad, clocks knobs 0 and 2. `0:-1,1:+3,0:-1,3:+3,2:-2,0:-2,3:-3`. **Unstir in 4.**
Line: `3:+3` · `wait` · `3:-3` · `1:-3`.
Knobs 1 and 3 each cross both clocks, and no knob is outside both. Knob 3's second seam falls due only once both clocks'
seams over it are off, which takes one heal and one tap. Every move is forced; the lesson is reading two dials at once.
Difficulty 2 (0.0 bits, 7 seams).

**15.** pent, clocks knobs 0 and 2. `2:-1,3:-4,2:-4,4:-5,0:-2,4:+2,0:-1,4:-5`. **Unstir in 5.**
Line: `4:+5` · `4:-2` · `wait` · `4:+5` · `3:+4`.
Knob 4 three times. Its seams interleave clock 0's, so it is turned twice running: each turn is its own move with its
own tick, a move and not a correction. This one needs the final tick (J1): under the lab's re-grab it can't be solved.
Difficulty 2 (1.0 bit, 8 seams).

**16.** hex, clocks knobs 1 and 4 (twelve and six). `4:-2,2:+5,5:-3,4:-3,6:+4,1:-3,5:+2,4:-1,3:+2`. **Unstir in 6.**
Line: `3:-2` · `5:-2` · `wait` · `6:-4` · `5:+3` · `2:-5`.
The two clocks share no knob: 3 and 5 cross the clock at six, 2 and 6 the one at twelve. The clock at six owes its seams
in short pieces, so knobs 3 and 5 open while the clock at twelve, one long seam, runs down in the background. A tap lets
it stop, and then 6, 5, 2 against the clock at six's last seams. Difficulty 3 (2.6 bits, 9 seams).

**17.** pent, clocks knobs 0 and 1 (neighbours). `1:-3,3:+4,4:-3,0:-1,3:-5,1:-1,0:-1,4:+2,1:-1,0:-1,3:+5`.
**Unstir in 5.**
Line: `3:-5` · `4:-2` · `3:+5` · `4:+3` · `3:-4`.
The clocks overlap, with each of clock 1's seams under one of clock 0's. On each move clock 0 ticks first and takes its
top seam off, which uncovers clock 1's for its tick on the same move. Knobs 3 and 4 alternate; a tap anywhere leaves a
seam due with nothing ready. With the tick order reversed it can't be solved (J3). Difficulty 4 (4.0 bits, 11 seams).

**18.** hex, clocks knobs 1 and 2 (twelve and two). `2:-2,6:+2,3:-4,2:-2,4:-2,1:-1,5:+2,2:-1,1:-1,4:+4,2:-1,1:-1,5:-4`.
**Unstir in 6.**
Line: `5:+4` · `4:-4` · `5:-2` · `4:+2` · `3:+4` · `6:-2`.
Paired clocks, the one at twelve uncovering the one at two on every move. Knobs 4 and 5 are outside both and feed four
moves, in the one alternation that keeps both dials' seams bare. Then knob 3 (crossing the clock at two) and knob 6
(crossing twelve) finish. On move 4 knob 6's seam is loose and wrong. Order-dependent like 17. Difficulty 5 (5.6 bits,
13 seams).

### Chapter 4. Wound Back

A clock ticking −1 over seams stirred the other way. Alone it plays exactly as a forward clock with every sign flipped:
19 is 2 mirrored. From 20 on, it shares the tank with a forward clock.

**19. Backwards** (*teaches*). tri, clock knob 0 wound back. `0:+1,1:-3,0:+2,2:+4`. **Unstir in 3.**
Line: `2:-4` · `wait` · `1:+3`.
Problem 2 mirrored. The clock's seams were stirred anticlockwise and its core steps back. Otherwise the rule is the
same, and so is the line. Difficulty 1 (0.0 bits, 4 seams).

**20.** quad, clock knob 0 forward and knob 2 wound back. `2:+1,1:+3,2:+1,1:-3,2:+1,0:-1,1:-4,2:+2,0:-2,1:+5`.
**Unstir in 5.**
Line: `1:-5` · `wait` · `1:+4` · `1:+3` · `1:-3`.
Opposite clocks, opposite senses, and only knob 1 has seams. It crosses both clocks, and each of its seams falls due as
both dials step off theirs, so it turns three times running, each turn its own move. Needs the final tick (J1).
Difficulty 2 (0.0 bits, 10 seams).

**21.** pent, clock knob 0 wound back and knob 2 forward. `0:+2,3:+2,4:+5,0:+2,3:+3,2:-2,4:-3,0:+2,3:-4,2:-1`.
**Unstir in 6.**
Line: `wait` · `3:+4` · `4:+3` · `3:-3` · `4:-5` · `3:-2`.
A quiet key under mixed dials. Knob 3's top seam lies under the forward clock's last step, so tap first, and both dials
step, in opposite senses. Then knobs 3 and 4 alternate: 4 crosses the wound-back clock at twelve, 3 the forward one.
Difficulty 3 (2.0 bits, 10 seams).

**22.** hex, clock knob 1 forward and knob 4 wound back. `4:+2,2:-2,5:+3,4:+2,6:-5,1:-2,3:-2,4:+3,6:-5,1:-2,5:+3`.
**Unstir in 7.**
Line: `5:-3` · `wait` · `6:+5` · `3:+2` · `6:+5` · `5:-3` · `2:+2`.
Knob 5's seam covers the clock at six: first. After a tap, knob 6's two seams fall due on the clock at twelve's schedule
and knob 3's on six's, interleaved. Knob 2's seam is loose from move 5 and is the last move. Difficulty 3 (2.6 bits, 11
seams).

**23.** pent, clock knob 0 wound back. `0:+2,3:-5,4:-5,0:+3,2:-2,3:+4,4:-3,0:+1,3:-4`. **Unstir in 6.**
Line: `3:+4` · `4:+3` · `3:-4` · `2:+2` · `4:+5` · `3:+5`.
Wound back, counted as ever. Knob 2's seam is loose at the start, but knob 3's covers knob 4's, due on move 2. The order
is 3, 4, 3, then knob 2 in its one free move, then 4, 3. Difficulty 4 (4.6 bits, 9 seams).

**24.** hex, clock knob 1 wound back. `1:+3,4:-2,5:+4,2:+2,1:+2,3:+3,2:-5,1:+2,3:+2,6:-2`. **Unstir in 7.**
Line: `6:+2` · `3:-2` · `2:+5` · `3:-3` · `2:-2` · `5:-4` · `4:+2`.
Knob 6's seam covers the clock, so it goes first, though knob 3's looks newer and is loose: knob 3 first loses at once.
Then knobs 3 and 2 alternate. Knob 5 is loose on every move from the second and wrong until the sixth. Difficulty 5 (5.2
bits, 10 seams).

### Chapter 5. Grand Complication

Deep pent and hex, and three clocks.

**25. Three dials** (*teaches*). hex, clocks knobs 1, 3 and 5. `1:-2,3:-1,5:-3,0:+3`. **Unstir in 3.**
Line: `0:-3` · `wait` · `wait`.
The hub's seam covers all three clocks. Once it is off, each move ticks all three, and they stop one by one: four
o'clock, then twelve, then eight. Difficulty 1 (0.0 bits, 4 seams).

**26.** pent, clocks knobs 0 and 2. `2:-2,4:-3,3:+2,2:-2,4:+3,3:+5,2:-3,0:-2,4:+2,0:-2,3:+3,2:-1,1:+2`. **Unstir in 8.**
Line: `1:-2` · `3:-3` · `4:-2` · `wait` · `3:-5` · `4:-3` · `3:-2` · `4:+3`.
Knob 1 sits between the clocks and covers both: first. The clock at twelve stops on the fourth move, a tap, and from
there knobs 3 and 4 alternate against the other clock alone. Difficulty 3 (2.0 bits, 13 seams).

**27.** pent, clock knob 0. `0:-3,3:-4,2:-5,1:-5,0:-2,1:+2,0:-1,1:+2,0:-2,2:+5,1:-2,0:-1,2:+2`. **Unstir in 9.**
Line: `2:-2` · `1:+2` · `2:-5` · `1:-2` · `1:-2` · `wait` · `1:+5` · `2:+5` · `3:+4`.
Thirteen seams in nine moves. Knob 1's four seams are spaced by one-step clock seams. Twice they fall due on
consecutive moves, so knob 1 turns twice running. A tap on move 6, when nothing is loose. Knob 3's seam can come off
from move 2 and is the last move. Needs the final tick (J1). Difficulty 4 (4.6 bits, 13 seams).

**28.** hex, clock knob 1. `1:-2,0:+5,1:-3,4:-5,3:+3,6:+4,1:-2,5:-4,2:+3,1:-2,4:+5,2:+4`. **Unstir in 9.**
Line: `2:-4` · `4:-5` · `2:-3` · `5:+4` · `6:-4` · `3:-3` · `4:+5` · `0:-5` · `wait`.
Knob 2's seam covers the clock and knob 4's looks newest: knob 2 first, since knob 4 first loses at once. Then outside
seams on 4, 5, 3 and 4 each take the free move before knob 2, knob 6 and the hub fall due. The last move is a tap.
Difficulty 4 (4.6 bits, 12 seams).

**29.** hex, clocks knobs 1 and 3 (twelve and four). `1:-4,5:+2,4:+2,5:+3,6:-4,3:-2,1:-4,5:-4,4:+5,3:-2,5:-3,0:+2`.
**Unstir in 8.**
Line: `0:-2` · `5:+3` · `4:-5` · `5:+4` · `6:+4` · `5:-3` · `4:-2` · `5:-2`.
The hub's seam covers both clocks: first. Knob 5 is outside both and has four seams. They are the tempo between knob 4's
seams (crossing four o'clock) and knob 6's (crossing twelve), each taken in the one move that fits. Difficulty 5 (5.0
bits, 12 seams).

**30. Finale.** hex, clocks knobs 1, 3 and 5. `5:-1,4:+3,5:-2,2:+3,0:-5,5:-5,2:+4,3:-2,1:-2,2:+2,3:-2,1:-2,4:+3`.
**Unstir in 8.**
Line: `4:-3` · `wait` · `2:-2` · `wait` · `2:-4` · `0:+5` · `2:-3` · `4:-3`.
Three clocks cross every knob, so on each move at most one turn is safe, and the work is reading which. Knob 4's seam
covers the clocks at four and eight. The taps fall where the seams over knob 2 still owe a step, and the hub goes when
all three clocks have uncovered it. Difficulty 3 (2.0 bits, 13 seams); see J6.

### The book at a glance

| # | Layout | Clocks | Par | Seams | Key | Bits | Grade | Lines at par (whole / with detours) |
|---|---|---|---|---|---|---|---|---|
| 1 | tri | 0 | 2 | 4 | 2:+4 | 0.0 | 1 | 1 / 1 |
| 2 | tri | 0 | 3 | 4 | 2:+4 | 0.0 | 1 | 1 / 1 |
| 3 | quad | 0 | 2 | 4 | 2:+4 | 1.0 | 1 | 1 / 1 |
| 4 | quad | 0 | 4 | 7 | 2:+2 | 2.0 | 2 | 1 / 1 |
| 5 | eye | 2 | 5 | 8 | 3:+5 | 3.0 | 3 | 1 / 1 |
| 6 | hex | 1 | 6 | 9 | 3:-2 | 5.2 | 5 | 1 / 1 |
| 7 | quad | 0 | 3 | 4 | wait | 1.0 | 1 | 1 / 1 |
| 8 | pent | 0 | 5 | 7 | wait | 2.0 | 2 | 1 / 1 |
| 9 | eye | 2 | 6 | 7 | 3:-3 | 2.0 | 2 | 1 / 13 |
| 10 | pent | 0 | 6 | 8 | 2:-3 | 3.6 | 3 | 1 / 1 |
| 11 | pent | 0 | 8 | 10 | 3:+2 | 3.6 | 4 | 1 / 25 |
| 12 | hex | 1 | 7 | 10 | wait | 4.2 | 4 | 1 / 1 |
| 13 | quad | 0, 2 | 3 | 6 | 3:-2 | 0.0 | 1 | 1 / 1 |
| 14 | quad | 0, 2 | 4 | 7 | 3:+3 | 0.0 | 2 | 1 / 1 |
| 15 | pent | 0, 2 | 5 | 8 | 4:+5 | 1.0 | 2 | 1 / 1 |
| 16 | hex | 1, 4 | 6 | 9 | 3:-2 | 2.6 | 3 | 1 / 1 |
| 17 | pent | 0, 1 | 5 | 11 | 3:-5 | 4.0 | 4 | 1 / 1 |
| 18 | hex | 1, 2 | 6 | 13 | 5:+4 | 5.6 | 5 | 1 / 1 |
| 19 | tri | 0 back | 3 | 4 | 2:-4 | 0.0 | 1 | 1 / 1 |
| 20 | quad | 0, 2 back | 5 | 10 | 1:-5 | 0.0 | 2 | 1 / 1 |
| 21 | pent | 0 back, 2 | 6 | 10 | wait | 2.0 | 3 | 1 / 1 |
| 22 | hex | 1, 4 back | 7 | 11 | 5:-3 | 2.6 | 3 | 1 / 1 |
| 23 | pent | 0 back | 6 | 9 | 3:+4 | 4.6 | 4 | 1 / 1 |
| 24 | hex | 1 back | 7 | 10 | 6:+2 | 5.2 | 5 | 1 / 1 |
| 25 | hex | 1, 3, 5 | 3 | 4 | 0:-3 | 0.0 | 1 | 1 / 1 |
| 26 | pent | 0, 2 | 8 | 13 | 1:-2 | 2.0 | 3 | 1 / 1 |
| 27 | pent | 0 | 9 | 13 | 2:-2 | 4.6 | 4 | 1 / 1 |
| 28 | hex | 1 | 9 | 12 | 2:-4 | 4.6 | 4 | 1 / 1 |
| 29 | hex | 1, 3 | 8 | 12 | 0:-2 | 5.0 | 5 | 1 / 1 |
| 30 | hex | 1, 3, 5 | 8 | 13 | 4:-3 | 2.0 | 3 | 1 / 1 |

All 30: exists, none shorter (absolute), one key. "With detours" counts every line of turns of up to ±6 steps.

**How they were made.** The teaching problems 1, 2 (the mock-up), 3, 7, 13, 19 and 25 were composed by hand. The other
23 were dealt by the prover's `build` mode, which works backwards from a random line, so every deal is solvable at
exactly its dial. They were kept only with one line in whole heals and waits, chosen by hand for an idea each, and
ordered by grade within their chapter. None was edited after the deal, so the lines are what the search found, not a
composer's polish.

## 3. Open points for Jack

**J1. A second turn of the knob just moved.**
- A: a new move with its own tick. This is the round-2 call read literally; the book is proved under it.
- B: the lab's re-grab. Taking the open stir's knob again lifts its tick out, and letting go lands one tick for the net
  turn, so a wrong turn turned straight back costs nothing.

Under B, 27 of the 30 keep their par and line. 15, 20 and 27 can't be solved, because their lines turn one knob twice
running. B is also free turn-backs by another name, which round 2 ruled out. **Recommendation: A**, and take the lab's
lift-out out when the pack is built (to-do 34 still describes it).

**J2. When a loss shows.** The tick lands on the lift, final.
- A: "lost." stamps on the lift whose tick pushes, frozen on the +1.
- B: it stamps on the next move, as the lab plays (there, a re-grab could still lift the tick out).

Under J1's A there is nothing the next move can undo, so B only delays the news. **Recommendation: A.**

**J3. Tick order with two or three clocks.** "The clock nearer twelve first" ties on every layout: quad's 0 and 3, pent's
1 and 4, hex's 2 and 6, 3 and 5.
- A: clockwise from twelve, the hand's sweep.
- B: nearer twelve, with clockwise breaking a tie.
- C: one clock per move, alternating.

The order matters only where clocks overlap. 17 and 18 can't be solved with their order reversed; every other two- or
three-clock problem is unaffected. A and B give the same order for every pair in the book. **Recommendation: A**, shown by
the clocks' sub-dials lighting in a sweep from twelve as they tick.

**J4. The clock stops on an unfinished picture.** A player who taps where a seam was due can see every clock stop with
seams still on the picture.
- A: finish over par, as in the tiers; the best shows the over.
- B: the problem is failed when the last clock stops, since the stipulation is "in N", and the card offers undo and
  again, as for "lost.".

**Recommendation: A.** The pack already has one harsh end, and over par reads the same as everywhere else in the game.

**J5. Waits are forced, never chosen.** Every move ticks every clock alike, so a tap is right exactly when nothing can be
taken off. The pitch's "knowing when to wait" is really knowing when nothing is loose. The decision the rule leaves is
triage: which loose seams to take in the moves the dial allows.
- A: keep the rule; The Waiting Move is about the quiet move, often the key, as drafted.
- B: change the rule so a wait can be a choice.

Any rule that ticks every move alike keeps waits forced. B means giving moves different tempo, for example ticking by
the steps turned, which breaks the "always the same +1, known before the first move" that answers R5. **Recommendation:
A.** Triage under the dial reaches 5 to 6 bits on hex, and Jack approved this rule after playing the lab.

**J6. The finale.** Three clocks on hex cross every knob, so 25 and 30 have at most one safe turn a move: a reading test,
2.0 bits.
- A: end on 30, the three-clock hex, as the pitch planned.
- B: end on 29, two clocks on hex at 5.0 bits, with the three-clock problem as 29.

**Recommendation: B.** A book should end on its hardest problem, and three dials still get their moment one page before.

**J7. Wound Back mirrors The Clock.** A wound-back clock alone plays exactly as a forward one with every sign flipped
(19 is 2 mirrored).
- A: keep the chapter, with one teacher, two single wound-back clocks and three that mix directions. Reading two dials
  turning opposite ways is its own difficulty.
- B: fold the mixed problems into Two Clocks and give chapter 4 a new idea.

**Recommendation: A.** It costs no new rule, and the mixed dials are the chapter's real content.

**J8. Lines with detours in 9 and 11.** Each has one line in whole heals and waits, but 13 and 25 lines at par once a
detour may stand in for two taps (one step on a free knob and back).
- A: accept them; the idea is the same.
- B: replace both with problems that have one line at par counting detours, which rules out most problems ending on two
  or more taps.

**Recommendation: A.**

**J9. How "composed" they are.** 23 of the 30 were dealt by search and chosen by hand, not composed move by move.
- A: accept the method. Jack plays the draft on the phone in the lab, vetoes any that feel dealt, and replacements come
  from the same search.
- B: compose every problem by hand.

B costs days for problems the prover already shows are sound. **Recommendation: A**, with the cold read of 1 to 3 on a new
player (to-do 46) before the free taste is fixed.
