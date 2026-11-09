# Copyright © 2026 Jack Lusher. All rights reserved.
# Vortex: the swirl, its lessons and pictures, the rim and the breath. Sourced in order by scripts/shots.sh.
# Vortex: the swirl, a last rod the size of the tank at its centre, held from the rim. Its 27 levels are provisional. The
# rim shows how to stir with the swirl until the player has once (UNSTIR_SWIRLED=1 is a player who has); with seized
# knobs too, both lessons show. The swirl-* shots are of the picture, so they read as a player who has. UNSTIR_CLOCK
# holds the swirl's breath still, so no shot catches it mid-slosh unless UNSTIR_BREATH asks.
shot menu-vortex "Menu on vortex with every row unlocked." TIER=vortex UNLOCK=1
for n in $(seq -w 1 27); do
  shot "vortex$n" "Vortex level $n with its full scramble, the swirl never stirred: the swirl's cyan lesson inside the glass at the bottom." TIER=vortex LEVEL=$n CLOCK=3
done
shot vortex01-swirled "Vortex 01 once the player has stirred with the swirl before: no lesson." TIER=vortex LEVEL=1 CLOCK=3 SWIRLED=1
shot vortex01-both "Vortex 01 with knob 1 seized (UNSTIR_SEIZED), neither ever used: the tank's amber lesson outside the bezel at the top, the swirl's cyan one inside the glass at the bottom." \
  TIER=vortex LEVEL=1 SEIZED=1 CLOCK=3
shot vortex21-both "Vortex 21 (hex) with knobs 2 and 5 seized, neither ever used: both lessons, the amber outside the bezel, the cyan inside the glass." TIER=vortex LEVEL=21 SEIZED=2,5 CLOCK=3
shot vortex-result "Vortex level 05 result card after a harness solve: two wasted stirs taken back, then the inverse word (+2 over par), next in vortex's blue." \
  TIER=vortex SCREEN=result LEVEL=5 CLOCK=3
# Vortex on plughole's grid (UNSTIR_PICTURE) instead of its own family, the option for its pictures set aside.
for n in 01 14 27; do
  shot "vortex-plughole-$n" "Vortex level $n with its full scramble on plughole's grid, the swirl never stirred." \
    TIER=vortex LEVEL=$n CLOCK=3 PICTURE=grid
done
# Vortex's own family: each picture clean in the sandbox, then on the shallowest, a middle and the deepest of its levels.
# scripts/vortex-family-sheet.py lays them out.
for p in isobars ephemeris cords; do
  shot "vortex-family-$p-clean" "Vortex's $p, clean: the sandbox's square with a swirl, nothing stirred." \
    MODE=sandbox LAYOUT=quadSwirl STACK= PICTURE=$p CLOCK=3 SWIRLED=1
done
for pn in isobars:01 isobars:14 isobars:27 ephemeris:02 ephemeris:13 ephemeris:22 cords:03 cords:16 cords:26; do
  p=${pn%:*} n=${pn#*:}
  shot "vortex-family-$p-$n" "Vortex level $n with its full scramble on its own $p, its lesson learnt." TIER=vortex LEVEL=$n \
    CLOCK=3 SWIRLED=1
done
# What the rim does, shown before it is touched: the swirl alone (vortex 01), the glass's turn alone (maelstrom 01, knob
# 1 seized) and both (vortex 01 with knob 1 seized), each once its lessons are learnt and with them, then held: the
# swirl from the rim, and where there are both, the swirl from the glass's edge and the tank from the bezel.
shot rim-swirl "Rim: vortex 01, the swirl alone, its lesson learnt." TIER=vortex LEVEL=1 CLOCK=3 SWIRLED=1
shot rim-swirl-lesson "Rim: vortex 01, the swirl never stirred: its cyan lesson too, inside the glass." TIER=vortex LEVEL=1 CLOCK=3
shot rim-swirl-held "Rim: vortex 01, the swirl held from the rim, 1.5 steps clockwise." \
  TIER=vortex LEVEL=1 CLOCK=3 SWIRLED=1 LIVE=4:1.5 TOUCH=0.7,-0.7
shot rim-seized "Rim: maelstrom 01, the glass's turn alone (knob 1 seized), its lesson learnt." TIER=maelstrom LEVEL=1 CLOCK=3 TANKTURNED=1
shot rim-seized-lesson "Rim: maelstrom 01, the tank never turned: its amber lesson too." TIER=maelstrom LEVEL=1 CLOCK=3
shot rim-both "Rim: vortex 01 with knob 1 seized, both lessons learnt." TIER=vortex LEVEL=1 SEIZED=1 CLOCK=3 SWIRLED=1 TANKTURNED=1
shot rim-both-lesson "Rim: vortex 01 with knob 1 seized, neither ever used: both lessons too, each on its own ring." \
  TIER=vortex LEVEL=1 SEIZED=1 CLOCK=3
shot rim-both-swirl-held "Rim: vortex 01 with knob 1 seized, the swirl held from the glass's edge, 1.5 steps clockwise." \
  TIER=vortex LEVEL=1 SEIZED=1 CLOCK=3 SWIRLED=1 TANKTURNED=1 LIVE=4:1.5 TOUCH=0.66,-0.66
shot rim-both-tank-held "Rim: vortex 01 with knob 1 seized, the tank held from the bezel, 30 degrees round." \
  TIER=vortex LEVEL=1 SEIZED=1 CLOCK=3 SWIRLED=1 TANKTURNED=1 TANKLIVE=30 TOUCH=0,-1.03
# The swirl's count, inside the glass on the far side from the finger, clear of its dashes.
shot rim-swirl-held-low "Rim: vortex 01, the swirl held from the rim at six and carried 1.5 steps counterclockwise: -2 on the far side from the finger, inside the dashes." \
  TIER=vortex LEVEL=1 CLOCK=3 SWIRLED=1 LIVE=4:-1.5 TOUCH=0,0.97
shot rim-swirl-turned "Rim: vortex 01, the swirl just let go 2 steps clockwise, its stir still open: +2 faint inside the dashes at twelve." \
  TIER=vortex LEVEL=1 CLOCK=3 SWIRLED=1 TURNED=4:+2
# The swirl's breath (UNSTIR_BREATH), held 0.4 s into its first slosh, where it has turned the picture furthest: a still
# of the tank at rest shows nothing. It runs only until the swirl is first stirred, so these never set UNSTIR_SWIRLED
# and its lesson shows with it. On vortex 01 (quad), 14 (pent) and 21 (hex), and on vortex 01 with knob 1 seized, for
# the bezel's knurl beside it.
for n in 01 14 21; do
  shot "breath-$n" "Breath: vortex $n at rest, the swirl never stirred, 0.4 s into its first slosh, its cyan lesson inside the glass." \
    TIER=vortex LEVEL=$n CLOCK=3 BREATH=1.9
done
shot breath-both "Breath: vortex 01 with knob 1 seized, the tank's lesson learnt and the swirl never stirred, 0.4 s into its first slosh, its cyan lesson inside the glass: the knurl for the glass's turn beside it." \
  TIER=vortex LEVEL=1 SEIZED=1 CLOCK=3 TANKTURNED=1 BREATH=1.9
# A sheet of what reads before a move, cut to the tank: the swirl alone, the glass's turn alone and both, learnt along
# the top and with their lessons under. Not a shot, so not in the index.
if [[ -z "$pattern" || "rim-" == *$pattern* ]]; then
  inputs=()
  for s in swirl seized both swirl-lesson seized-lesson both-lesson; do inputs+=(-i "shots/rim-$s.png"); done
  ffmpeg -loglevel error -y "${inputs[@]}" -filter_complex \
    "concat=n=6:v=1,crop=iw:ih*0.56:0:ih*0.21,scale=440:-1,tile=3x2:padding=8:color=0x303030" -frames:v 1 "shots/vortex-rim.png"
  echo "sheet vortex-rim"
fi
shot swirl-quad-one "Square with a swirl, one stir of it alone (4:+3): the glass's edge turned 90 degrees, sheared all the way in to the centre, which stays still." LAYOUT=quadSwirl STACK=4:+3 SWIRLED=1 CLOCK=3
swirl=0:+3,4:+2,2:-4,1:+3,4:-3,3:+5
shot swirl-quad "Square with a swirl (rod 4), $swirl." LAYOUT=quadSwirl STACK="$swirl" SWIRLED=1 CLOCK=3
shot swirl-quad-live "The same held mid-drag from the rim, the swirl 1.5 steps clockwise." LAYOUT=quadSwirl STACK="$swirl" LIVE=4:1.5 TOUCH=0.7,-0.7 SWIRLED=1 CLOCK=3
shot swirl-quad-seized "The same with knob 1 seized and the tank turned one step (90 degrees clockwise)." LAYOUT=quadSwirl STACK="$swirl" \
  SEIZED=1 TANK=1 SWIRLED=1 CLOCK=3
shot swirl-tri "Triangle with a swirl (rod 3), 0:+3,3:+2,1:-4,3:-3." LAYOUT=triSwirl STACK=0:+3,3:+2,1:-4,3:-3 SWIRLED=1 CLOCK=3
shot swirl-eye "Eye with a swirl (rod 4), 0:+3,4:+2,2:-4,4:-3." LAYOUT=eyeSwirl STACK=0:+3,4:+2,2:-4,4:-3 SWIRLED=1 CLOCK=3
shot swirl-pent "Pentagon with a swirl (rod 5), 0:+3,5:+2,2:-4,5:-3." LAYOUT=pentSwirl STACK=0:+3,5:+2,2:-4,5:-3 SWIRLED=1 CLOCK=3
shot swirl-hex "Hex with a swirl (rod 7), 1:+3,7:+2,4:-4,7:-3." LAYOUT=hexSwirl STACK=1:+3,7:+2,4:-4,7:-3 SWIRLED=1 CLOCK=3
