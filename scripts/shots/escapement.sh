# Copyright © 2026 Jack Lusher. All rights reserved.
# Escapement: the problem book, ticks, the lost card and the tick budget. Sourced in order by scripts/shots.sh.
# Escapement's problem book, each problem as dealt: its clocks' discs dashed vermilion, each ratchet read against its
# sub-dial (a wound-back clock's mirrored), the stipulation under the tank. Clocks are rods, + forward, - wound back.
while IFS=$'\t' read -r n layout clocks scramble; do
  shot "escapement-book-$(printf %02d "$n")" "Escapement $n as dealt: $layout, clocks $clocks, scramble $scramble." PACK=escapement OWNED=escapement LEVEL="$n"
done < scripts/escapement/problems-nowait.tsv
shot escapement-card "Escapement's card, owned, scrolled to its levels under the book's five chapter headings." \
  CARD=escapement OWNED=escapement CARDSCROLL=1 CLOCK=5.4
# Escapement 2: tri 0:-1,2:+4,0:-1,2:+2,0:-1,1:+3, rod 0 the clock with a ratchet for a knob, unstirred in 3 by 1:-3,
# 2:-2 and 2:-4, each move's tick taking one of the clock's seams. UNSTIR_PLAYED plays a line through the real path as
# it opens.
shot escapement-2-ticked "Escapement 2 after rod 1 -3 heals: its tick has taken the clock's top seam, one tooth on, and the budget's flaps read 02." \
  PACK=escapement LEVEL=2 PLAYED=1:-3
shot escapement-2-pushed "Escapement 2, then a wrong rod 1 +2 over the clock's seam: its tick finds the seam covered and pushes, the vermilion +1, and the tank plays on with 01 tick left, the caption saying That tick can't come back. Undo, or again." \
  PACK=escapement LEVEL=2 PLAYED=1:-3,1:2
shot escapement-dead-tick "Escapement 04 after 1:+1, whose tick pushed: +1 stands vermilion and the caption says That tick can't come back. Undo, or again." \
  PACK=escapement OWNED=escapement LEVEL=4 PLAYED=1:1
shot escapement-2-out "Escapement 2, then rod 1 +2 and rod 1 +1: the last tick spent with twists left, out of ticks. stamped by the clock, the budget's flaps vermilion at 00, the card's undo and again." \
  PACK=escapement LEVEL=2 PLAYED=1:-3,1:2,1:1
# Jack's call (2026-11-01, on C19): a tank out of ticks keeps its save, so a level left on its lost card reopens there.
shot escapement-2-lost-resumed "Escapement 2 reopened on the line that ran it out of ticks (1:-3, 1:+2, 1:+1): straight onto the lost card, out of ticks on move 3 with undo and again, the clock's +2 and out of ticks. stamped by it, the budget at 00, no opening or demonstration: the same frame as escapement-2-out." \
  PACK=escapement LEVEL=2 RESUME=1:-3,1:2,1:1
shot escapement-2-won "Escapement 2 won in 3: 1:-3, 2:-2, 2:-4, the last tick emptying the stack." PACK=escapement LEVEL=2 PLAYED=1:-3,2:-2,2:-4
# The bone-paper page (Jack's call ESC-PAPER = B, round 16): the turn's hairlines, dashes and count in ink, and the solve
# wave an ink ring, as the shader's band would run the paper white.
shot escapement-2-drag "Escapement 2 mid-drag on paper: rod 2 turned +2.6, its disc's hairline, dashes and +3 count in ink." \
  PACK=escapement LEVEL=2 LIVE=2:+2.6
shot escapement-2-wave "Escapement 2 solved in 3, its solve wave an ink ring held at radius 0.6 from the last-turned rod." \
  PACK=escapement LEVEL=2 PLAYED=1:-3,2:-2,2:-4 WAVE=0.6
shot escapement-2-back-swipe "Escapement 2 held 40% into an edge swipe back: the paper page sliding right over the menu on black, the status bar's glyphs dark across the whole width, the menu's side too." \
  PACK=escapement LEVEL=2 BACKSWIPE=0.4
# The tick budget on 16 (clocks 1, owing 3, and 4, owing 6, so 9; line 0:+3, 6:-5, 3:+4, 6:-2, 5:-4, 2:+2): as dealt,
# after the move that stops clock 1, and one move from the end.
shot escapement-budget-16-dealt "Escapement 16 as dealt: 09 ticks, clock 1 owing 3 and clock 4 owing 6." PACK=escapement OWNED=escapement LEVEL=16
shot escapement-budget-16-mid "Escapement 16 after 0:+3, 6:-5 and 3:+4, two ticks a move: clock 1 stopped, 03 ticks left." \
  PACK=escapement OWNED=escapement LEVEL=16 PLAYED=0:3,6:-5,3:4
shot escapement-budget-16-late "Escapement 16 after 0:+3, 6:-5, 3:+4, 6:-2 and 5:-4: 01 tick left, clock 4's last." \
  PACK=escapement OWNED=escapement LEVEL=16 PLAYED=0:3,6:-5,3:4,6:-2,5:-4
# Each clock's own flip count in its hub, the header their sum (Jack's call ES2, round 12): 16 as dealt (3 and 6), after
# the move that runs clock 1 out with its rod, after a wrong 2:+1 instead, whose ticks both push, clock 1's its last,
# run out over its +1, and that wrong line turned out of ticks; 22's wound-back clock 4 reads unmirrored.
shot escapement-hubs-16-dealt "Escapement 16 as dealt: hubs 3 and 6, header 09." PACK=escapement OWNED=escapement LEVEL=16
shot escapement-hubs-16-mid "Escapement 16 after 0:+3, 6:-5 and 3:+4: clock 1 run out, grey at 0; clock 4 at 3; header 03." \
  PACK=escapement OWNED=escapement LEVEL=16 PLAYED=0:3,6:-5,3:4
shot escapement-hubs-16-wrong "Escapement 16 after 0:+3, 6:-5 and a wrong 2:+1: both ticks pushed, clock 1's its last, grey at 0 over its +1, clock 4 at 3 over its own; header 03." \
  PACK=escapement OWNED=escapement LEVEL=16 PLAYED=0:3,6:-5,2:1
shot escapement-hubs-16-out "Escapement 16, the wrong 2:+1 then three more steps of knob 2: both hubs grey at 0, header 00, out of ticks." \
  PACK=escapement OWNED=escapement LEVEL=16 PLAYED=0:3,6:-5,2:1,2:1,2:1,2:1
shot escapement-hubs-22-dealt "Escapement 22 as dealt: clock 1 at 4, wound-back clock 4 at 7, its digit unmirrored; header 11." \
  PACK=escapement OWNED=escapement LEVEL=22
# Out of ticks as the clocks stop with twists left, each of the three looks (UNSTIR_STOPLOOK): on 3, knob 2 turned a
# step short, then knob 1, which pushes under knob 2's seam; on 17, two clocks, the last heal two steps short.
for look in stamp left rings; do
  shot "escapement-stopped-3-$look" "Escapement 3 after 2:+1 and 1:-3: the clock stopped with knob 1's push and knob 2's seam still on the picture, out of ticks; look $look." \
    PACK=escapement LEVEL=3 PLAYED=2:1,1:-3 STOPLOOK=$look
  shot "escapement-stopped-17-$look" "Escapement 17 after 3:-5, 4:-2, 3:+5, 4:+3 and 3:-2: both clocks stopped with knob 3's twist left, out of ticks; look $look." \
    PACK=escapement OWNED=escapement LEVEL=17 PLAYED=3:-5,4:-2,3:5,4:3,3:-2 STOPLOOK=$look
done
