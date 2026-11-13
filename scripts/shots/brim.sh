# Copyright © 2026 Jack Lusher. All rights reserved.
# A level's brim: the stack's twists of the $limit the tank holds (Tank.maxStack), filling the bezel from six o'clock to
# the pin at twelve. Sourced in order by scripts/shots.sh.
hold=5 shot brim-m27-dealt "Maelstrom 27 as dealt: 26 of $limit, the brim's liquid in the level's colour part way up the bezel, under the knurl." \
  TIER=maelstrom LEVEL=27 CLOCK=3
hold=5 shot brim-m27-40 "Maelstrom 27, its stack repeated to 40 of $limit." TIER=maelstrom LEVEL=27 DEEP=40 CLOCK=3
hold=5 shot brim-m27-$((limit - 1)) "Maelstrom 27, its stack repeated to $((limit - 1)) of $limit: the liquid a notch under the pin, which pulses." \
  TIER=maelstrom LEVEL=27 DEEP=$((limit - 1)) CLOCK=3
hold=5 shot brim-m27-full "Maelstrom 27 at $limit of $limit: the brim full to the pin, no spill." TIER=maelstrom LEVEL=27 DEEP=$limit CLOCK=3
hold=4 shot brim-m27-refused "Maelstrom 27 at $limit of $limit, a rod turn just refused: the knob shakes and the caption says the tank is full." \
  TIER=maelstrom LEVEL=27 DEEP=$limit MOVES=0:+1 PACE=0.1
hold=5 shot brim-plughole-11 "Plughole 11 five moves in: a low brim in plughole's colour." LEVEL=11 PLAYED=2:-6,1:+4,3:+5,0:+1,1:+2 CLOCK=3
hold=5 shot brim-escapement-02 "Escapement 02 a move in, on paper: the brim on the bezel over the paper ground." \
  PACK=escapement OWNED=escapement LEVEL=2 PLAYED=2:4 CLOCK=3
hold=5 shot brim-prism-01 "Prism specimen 1 as dealt: the brim in Prism's colour." PACK=prism OWNED=prism LEVEL=1 CLOCK=3
hold=5 shot brim-lens-01 "Lens 01, 1:+2,0:+2: a two-twist brim over the halftone." PACK=lens LEVEL=1 BESTS=lens:0 STACK=1:+2,0:+2 CLOCK=3
hold=5 shot brim-frost "A frost day's daily (2026-10-15): two knobs frozen, the knurl over the brim." MODE=daily DAILY=20261015 CLOCK=3
hold=10 shot brim-duo "Duo open: plughole 11 five moves in, the tank in the leading half with its brim." \
  FRAME=951x669 INSETS=24,0,21,84 LEVEL=11 PLAYED=2:-6,1:+4,3:+5,0:+1,1:+2 CLOCK=3
hold=5 shot brim-endless "Endless as it was: its own brim of eight notches, untouched." MODE=endless CLOCK=3
hold=10 shot brim-duo-upright "Duo upright: maelstrom 27 as dealt, its glass the size it was before the brim." \
  FRAME=669x951 INSETS=59,0,34,0 TIER=maelstrom LEVEL=27 CLOCK=3
