# Copyright © 2026 Jack Lusher. All rights reserved.
# A level's brim: the stack's twists of the 36 the tank holds, filling the bezel from six o'clock to the pin at twelve.
# Sourced in order by scripts/shots.sh.
hold=5 shot brim-m27-dealt "Maelstrom 27 as dealt: 26 of 36, the brim's liquid in the level's colour most of the way up the bezel, under the knurl." \
  TIER=maelstrom LEVEL=27 CLOCK=3
hold=5 shot brim-m27-35 "Maelstrom 27, its stack repeated to 35 of 36: the liquid a notch under the pin, which pulses." \
  TIER=maelstrom LEVEL=27 DEEP=35 CLOCK=3
hold=5 shot brim-m27-full "Maelstrom 27 at 36 of 36: the brim full to the pin, no spill." TIER=maelstrom LEVEL=27 DEEP=36 CLOCK=3
hold=4 shot brim-m27-refused "Maelstrom 27 at 36 of 36, a rod turn just refused: the knob shakes and the caption says the tank is full." \
  TIER=maelstrom LEVEL=27 DEEP=36 MOVES=0:+1 PACE=0.1
hold=5 shot brim-plughole-11 "Plughole 11 five moves in: a low brim in plughole's colour." LEVEL=11 PLAYED=2:-6,1:+4,3:+5,0:+1,1:+2 CLOCK=3
hold=5 shot brim-escapement-02 "Escapement 02 a move in, on paper: the brim on the bezel over the paper ground." \
  PACK=escapement OWNED=escapement LEVEL=2 PLAYED=2:4 CLOCK=3
hold=5 shot brim-prism-01 "Prism specimen 1 as dealt: the brim in Prism's colour." PACK=prism OWNED=prism LEVEL=1 CLOCK=3
hold=5 shot brim-lens-01 "Lens 01, 1:+2,0:+2: a two-twist brim over the halftone." PACK=lens LEVEL=1 BESTS=lens:0 STACK=1:+2,0:+2 CLOCK=3
hold=5 shot brim-frost "A frost day's daily (2026-10-15): two knobs frozen, the knurl over the brim." MODE=daily DAILY=20261015 CLOCK=3
hold=10 shot brim-duo "Duo open: plughole 11 five moves in, the tank in the leading half with its brim." \
  FRAME=951x669 INSETS=24,0,21,84 LEVEL=11 PLAYED=2:-6,1:+4,3:+5,0:+1,1:+2 CLOCK=3
hold=5 shot brim-endless "Endless as it was: its own brim of eight notches, untouched." MODE=endless CLOCK=3
