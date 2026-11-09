# Copyright © 2026 Jack Lusher. All rights reserved.
# Whirlpool and maelstrom: probes, grabs, twins, seized knobs and the rim lesson. Sourced in order by scripts/shots.sh.
# Whirlpool: the menu, each layout's first level and the last (all glass), probes on level 12's and level 27's top rods,
# a result card, then each other picture at its deepest level and, on maelstrom, each twin. The live background is held
# 3 s in, so the probes compare; level 12 is marbling, so its probes are pinned to the glass.
shot menu-whirlpool "Menu on whirlpool with every row unlocked." TIER=whirlpool UNLOCK=1
for n in 01 09 14 19 23 27; do
  shot "whirlpool$n" "Whirlpool level $n with its full scramble." TIER=whirlpool LEVEL=$n CLOCK=3
done
shot whirlpool-probe-short "Whirlpool level 12 (square) on the glass, mid-drag: top rod 3 turned back +3 of its 4 steps, one detent short of the heal." \
  TIER=whirlpool LEVEL=12 PICTURE=glass LIVE=3:+3 CLOCK=3
shot whirlpool-probe-heal "Whirlpool level 12 (square) on the glass, mid-drag: top rod 3 turned back all 4 steps, so its seam heals." \
  TIER=whirlpool LEVEL=12 PICTURE=glass LIVE=3:+4 CLOCK=3
shot whirlpool-probe-over "Whirlpool level 12 (square) on the glass, mid-drag: top rod 3 turned back 5 steps, one detent past the heal." \
  TIER=whirlpool LEVEL=12 PICTURE=glass LIVE=3:+5 CLOCK=3
# The deepest level's top twist is 2:+2: short, heal and over.
for s in 1 2 3; do
  shot "whirlpool27-probe-$s" "Whirlpool level 27 (hex, par 28), mid-drag: top rod 2 turned back $s steps; it heals at 2." TIER=whirlpool LEVEL=27 LIVE=2:-$s CLOCK=3
done
shot whirlpool-grab-neurons "Whirlpool 20 (pentagon, neurons), a finger just down deep in rod 0: its knob lit, its disc a dim hairline over the web." \
  TIER=whirlpool LEVEL=20 TOUCH=0.05,-0.62 CLOCK=3
shot whirlpool-grab-overlap-neurons "Whirlpool 20 (pentagon, neurons), a finger just down where rods 0 and 1 overlap, nearer rod 1's centre: rod 1's knob lit, its disc a dim hairline." \
  TIER=whirlpool LEVEL=20 TOUCH=0.3,-0.34 CLOCK=3
shot whirlpool-grab-marbling "Whirlpool 25 (hex, marbling), a finger just down deep in rod 1: its knob lit, its disc a dim hairline." \
  TIER=whirlpool LEVEL=25 TOUCH=0.05,-0.6 CLOCK=3
shot whirlpool-grab-overlap-marbling "Whirlpool 25 (hex, marbling), a finger just down where rods 1 and 2 overlap, clear of the hub, nearer rod 2's centre: rod 2's knob lit, its disc a dim hairline." \
  TIER=whirlpool LEVEL=25 TOUCH=0.27,-0.4 CLOCK=3
shot whirlpool-count-marbling "Whirlpool 22 (pentagon, marbling), finger down below rod 2 and carried +4 steps round: four dashes, +4 off the finger." \
  TIER=whirlpool LEVEL=22 LIVE=2:+4 TOUCH=0.329,0.753 CLOCK=3
shot whirlpool-count-hex-below "Whirlpool 25 (hex, marbling), finger down to the lower right of rod 4 and carried +2 steps round to just under it: +2 swung off the hub's knob straight above." \
  TIER=whirlpool LEVEL=25 LIVE=4:+2 TOUCH=0.2165,0.685 CLOCK=3
shot whirlpool-result "Whirlpool level 05 result card after a harness solve: two wasted stirs taken back, then the inverse word (+2 over par)." \
  TIER=whirlpool SCREEN=result LEVEL=5 CLOCK=3
for level in 24:chainmail 16:coral 20:neurons 25:marbling; do
  n=${level%:*} picture=${level#*:}
  shot "whirlpool$n-$picture" "Whirlpool level $n ($picture) with its full scramble." TIER=whirlpool LEVEL=$n CLOCK=3
done
for level in 27:glass 22:chainmail 8:coral 18:neurons 24:marbling; do
  n=${level%:*} picture=${level#*:}
  shot "maelstrom$n-$picture" "Maelstrom level $n ($picture twin) with its full scramble." TIER=maelstrom LEVEL=$n CLOCK=3
done
# The turning tank: maelstrom levels on their twins, at home and turned one step, where every seam should sit
# concentric on the knob it lands under. The bezel is knurled wherever knobs are seized (the rim-* shots show it beside
# the lessons).
shot seized-m01-home "Maelstrom 01 (square, coral twin) with knob 1 seized, tank at home." TIER=maelstrom LEVEL=1 CLOCK=3
shot seized-m01-turned "Maelstrom 01 (square) with knob 1 seized, tank turned one step (90 degrees clockwise): the seams around knob 1 now ring knob 2." \
  TIER=maelstrom LEVEL=1 TANK=1 CLOCK=3
shot seized-m09-home "Maelstrom 09 (pentagon, marbling twin) with knobs 0 and 4 seized, tank at home." TIER=maelstrom LEVEL=9 CLOCK=3
shot seized-m09-turned "Maelstrom 09 (pentagon) with knobs 0 and 4 seized, tank turned one step (72 degrees clockwise): each seam moves one knob on." \
  TIER=maelstrom LEVEL=9 TANK=1 CLOCK=3
shot seized-m23-home "Maelstrom 23 (hex) with knobs 2 and 5 seized, tank at home." TIER=maelstrom LEVEL=23 SEIZED=2,5 CLOCK=3
shot seized-m23-turned "Maelstrom 23 (hex) with knobs 2 and 5 seized, tank turned one step (60 degrees clockwise): each ring seam moves one knob on, the hub's stays." \
  TIER=maelstrom LEVEL=23 SEIZED=2,5 TANK=1 CLOCK=3
shot seized-m23-half "Maelstrom 23 (hex) with knobs 2 and 5 seized, mid-drag on the rim: the tank held half a step (30 degrees) round." \
  TIER=maelstrom LEVEL=23 SEIZED=2,5 TANKLIVE=30 CLOCK=3
shot seized-m23-count "Maelstrom 23 (hex) with knobs 2 and 5 seized, finger down on the rim at lower left and carried two tank steps (120 degrees) round: two dashes inside the rim's hairline, +2 off the finger." \
  TIER=maelstrom LEVEL=23 SEIZED=2,5 TANKLIVE=120 TOUCH=-0.5,0.84 CLOCK=3
# How to turn the tank, shown on any level with seized knobs until the player has turned it once: a two-headed arc just
# outside the rim and a ghost finger rocking on it. UNSTIR_TANKTURNED=1 is a player who has, for the launch only. The ghost
# is held by UNSTIR_CLOCK, and UNSTIR_SHAKE holds a touch on a seized knob that far into its shake and the rim's pulse.
shot lesson-quad-grid "Level 12 (square, grid) with knob 1 seized, the tank never turned: the rim's two-headed arc and ghost finger." \
  LEVEL=12 SEIZED=1 CLOCK=3
shot lesson-hex-marbling "Whirlpool 25 (hex, marbling) with knobs 2 and 5 seized, the tank never turned: the rim's arc and ghost finger over a live picture." \
  TIER=whirlpool LEVEL=25 SEIZED=2,5 CLOCK=3
shot lesson-shake "Level 12 (square) with knob 1 seized, a finger just down on it, 0.15 s in: the knob turned a few degrees, the rim's arc swollen." \
  LEVEL=12 SEIZED=1 TOUCH=0.38,0.37 SHAKE=0.15 CLOCK=3
shot lesson-shake-turned "The same once the player has turned the tank before: no ghost, the arc back only for the pulse." \
  LEVEL=12 SEIZED=1 TOUCH=0.38,0.37 SHAKE=0.15 CLOCK=3 TANKTURNED=1
shot lesson-turned "Level 12 (square) with knob 1 seized, the tank turned before: no arc, no ghost, only the knurled bezel." LEVEL=12 SEIZED=1 CLOCK=3 TANKTURNED=1
shot lesson-count "Whirlpool 25 (hex, marbling) with knobs 2 and 5 seized, the tank never turned: rod 1 at the top turned +1 by a finger just below its knob, its count swung off the rim's arc." \
  TIER=whirlpool LEVEL=25 SEIZED=2,5 LIVE=1:+1 TOUCH=0,-0.3 CLOCK=3
shot lesson-maelstrom01 "Maelstrom 01 (square, coral twin) as the game loads it, the tank never turned: knob 1 seized, the rim's arc and ghost finger, and the note to turn the tank." \
  TIER=maelstrom LEVEL=1 CLOCK=3
# Can a finished ring be read on hex glass? 14 entries, as whirlpool 23 has, with one ring left without any, and the same
# stack with a 2-step twist on that ring buried under its neighbours.
ring3="1:+4,0:-3,2:+5,6:-4,4:+3,0:+5,5:-3,1:-5,2:-3,6:+4,0:-4,4:-5,5:+4,1:+3"
ring3buried="1:+4,0:-3,2:+5,3:+2,6:-4,4:+3,0:+5,5:-3,1:-5,2:-3,6:+4,0:-4,4:-5,5:+4,1:+3"
hub="2:+4,3:-3,5:+5,1:-4,4:+3,6:-5,2:-3,3:+5,1:+4,6:+3,4:-4,5:-3,2:+5,3:-4"
hubburied="2:+4,3:-3,0:+2,5:+5,1:-4,4:+3,6:-5,2:-3,3:+5,1:+4,6:+3,4:-4,5:-3,2:+5,3:-4"
shot seized-ring3-finished "Hex twin glass, 14 entries ($ring3), none on rod 3: its ring is finished." TIER=maelstrom LEVEL=23 SEIZED=2,5 STACK="$ring3" CLOCK=3
shot seized-ring3-buried "The same with 3:+2 buried fourth from the bottom ($ring3buried): rod 3's ring is not finished." \
  TIER=maelstrom LEVEL=23 SEIZED=2,5 STACK="$ring3buried" CLOCK=3
shot seized-hub-finished "Hex twin glass, 14 entries ($hub), none on the hub: its ring is finished." TIER=maelstrom LEVEL=23 SEIZED=2,5 STACK="$hub" CLOCK=3
shot seized-hub-buried "The same with 0:+2 buried third from the bottom ($hubburied): the hub's ring is not finished." \
  TIER=maelstrom LEVEL=23 SEIZED=2,5 STACK="$hubburied" CLOCK=3
