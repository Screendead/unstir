# Copyright © 2026 Jack Lusher. All rights reserved.
# Lens: the zoom, its levels, glitter and order. Sourced in order by scripts/shots.sh.
# Lens: rod 0 of tri is a lens on the halftone panel. A best on Lens 01 keeps its lesson off the rig's stills.
hold=5 shot lens-plus "Lens: tri, rod 0 a lens, 0:+3: the top core magnified x8 at its centre inside a crisp rim, its dots swollen against the screen's pitch outside; the knob carries an iris. Pins the sign: a positive step, a drag up, magnifies." \
  PACK=lens LEVEL=1 BESTS=lens:0 STACK=0:+3
hold=5 shot lens-minus "Lens: the same at 0:-2: the top core shrunk to x0.25, its dots fine and close inside the rim." PACK=lens LEVEL=1 BESTS=lens:0 STACK=0:-2
for n in $(seq -w 1 25); do
  hold=5 shot "lens-$n" "Lens $n as dealt, on its halftone panel (docs/lens-tables.md), the pack owned." PACK=lens LEVEL=$n OWNED=lens \
    $([[ $n == 01 ]] && echo BESTS=lens:0)
done
# Each drawn panel's clue (LensArt*.swift): the level's layout drawn clean, only its lenses magnified, each as
# scripts/lens-art-sheet.py's table holds it. That script lays these out beside lens-NN, the level as dealt.
for clue in $(scripts/lens-art-sheet.py clues); do
  hold=5 shot "lens-${clue%%=*}-clue" "Lens ${clue%%=*}'s panel drawn clean, only its lenses magnified (${clue#*=}): what is seen through each." \
    PACK=lens LEVEL=${clue%%=*} OWNED=lens BESTS=lens:0 STACK=${clue#*=} CLEAN=1
done
hold=5 shot lens-over "Lens: 1:+2,0:+2, the lens newest: its rim whole, rod 1's lines cut dead at it." PACK=lens LEVEL=1 BESTS=lens:0 STACK=1:+2,0:+2
hold=5 shot lens-result "Lens 02's result card over par: in the pack's magenta, LENS small above the title, the way out reading ‹ Lens." \
  PACK=lens LEVEL=2 SCREEN=result CLOCK=0
hold=5 shot lens-under "Lens: 0:+2,1:+2, the twist newest: the lens's rim dragged into rod 1's swirl." PACK=lens LEVEL=1 BESTS=lens:0 STACK=0:+2,1:+2
hold=5 shot lens-live "Lens 1 held mid-drag, the lens dragged up 1.4 steps: its count reads the zoom's steps (+1), a dash a step up a short track beside the knob, away from the finger." \
  PACK=lens LEVEL=1 LIVE=0:+1.4 TOUCH=0,-0.42
hold=6 shot lens-lesson "Lens 01 as the tank becomes the player's: a ghost finger on the lens's knob halfway through its ride down, a lens step's travel, beside the track's rail, faint, on the right." \
  PACK=lens LEVEL=1 CLOCK=0.8
hold=5 shot lens-lesson-copied "Lens 01 held mid-drag where its lesson rides: landed on the knob's left edge and dragged two steps down, the count's -2 dashes on the lesson's rail." \
  PACK=lens LEVEL=1 LIVE=0:-2 TOUCH=-0.07,-0.42
# The rim band at each dealt step on each rod size, for glitter: tri's big rod 0 (0.58), quad's rod 0 (0.48) and eye's
# small top rod 2 (0.44), each beside a neighbour that overlaps it. Still, the lens held half a step short, and the
# neighbour held mid-twist over the lens.
for size in "big tri 0 1 0,-0.42" "mid quad 0 1 -0.35,-0.35" "small eye 2 0 0,-0.56"; do
  read -r name layout lens twist touch <<< "$size"
  for n in 1 2 3; do
    hold=5 shot "lens-glitter-$name-$n" "Lens on $layout rod $lens at +$n, still." \
      PACK=lens LEVEL=1 BESTS=lens:0 LAYOUT=$layout LENSES=$lens STACK=$lens:+$n
    below=$( ((n > 1)) && echo "$lens:+$((n - 1))" || true )
    hold=5 shot "lens-glitter-$name-$n-drag" "Lens on $layout rod $lens held at +$((n - 1)).5, mid-drag up." \
      PACK=lens LEVEL=1 LAYOUT=$layout LENSES=$lens STACK=$below LIVE=$lens:+0.5 TOUCH=$touch
    hold=5 shot "lens-glitter-$name-$n-twist" "Lens on $layout rod $lens at +$n, rod $twist held 1.5 steps into a twist over it." \
      PACK=lens LEVEL=1 LAYOUT=$layout LENSES=$lens STACK=$lens:+$n LIVE=$twist:+1.5
  done
  # A flip book at the screen's own pixels, for glitter in motion (a film records at half size): the lens dragged from
  # +2 to +3, then the neighbour twisted a step over it at +3, a tenth of a step a frame.
  for i in 00 01 02 03 04 05 06 07 08 09 10; do
    f=$((10#$i / 10)).$((10#$i % 10))
    hold=3 shot "lens-flip-$name-zoom-$i" "Lens on $layout rod $lens held at +2 and $f steps." \
      PACK=lens LEVEL=1 LAYOUT=$layout LENSES=$lens STACK=$lens:+2 LIVE=$lens:+$f
    hold=3 shot "lens-flip-$name-twist-$i" "Lens on $layout rod $lens at +3, rod $twist held $f steps into a twist." \
      PACK=lens LEVEL=1 LAYOUT=$layout LENSES=$lens STACK=$lens:+3 LIVE=$twist:+$f
  done
  # The order read at x2: the lens at +2 newest (its rim whole) or under a twist of 1 or 3 steps (its rim dragged).
  for k in 1 3; do
    hold=5 shot "lens-order-$name-over-$k" "Lens on $layout rod $lens, $twist:+$k,$lens:+2: the lens newest." \
      PACK=lens LEVEL=1 BESTS=lens:0 LAYOUT=$layout LENSES=$lens STACK=$twist:+$k,$lens:+2
    hold=5 shot "lens-order-$name-under-$k" "Lens on $layout rod $lens, $lens:+2,$twist:+$k: the twist newest." \
      PACK=lens LEVEL=1 BESTS=lens:0 LAYOUT=$layout LENSES=$lens STACK=$lens:+2,$twist:+$k
  done
done
