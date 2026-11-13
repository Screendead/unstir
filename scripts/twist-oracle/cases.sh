# Copyright © 2026 Jack Lusher. All rights reserved.
# The twist oracle's cases, sourced by scripts/twist-oracle.sh: each a launch of the harness with every clock held, so
# a rerun draws the same pixels.
#   still <name> KEY=VALUE...                 one frame
#   sweep <name> <KEY> "<v1> <v2>..." KEY=VALUE...   a frame a value of KEY, small steps of one held turn, read in pairs
#   film <name> <seconds> KEY=VALUE...        a take in motion, clocks running
# UNSTIR_CLEAN=1 draws the glass alone, so no knob, dial or count is in a frame. better=<case> before a still names a
# case whose reference this one may match instead (two taps drawing as four do is no worse).

# Maelstrom 24: hex, 23 stirs on the marbling's twin, a live picture; knobs 3 and 4 are seized.
m24=(TIER=maelstrom LEVEL=24 TANKTURNED=1 CLEAN=1)
still m24 "${m24[@]}" CLOCK=3
still m24-deep "${m24[@]}" CLOCK=3 DEEP=36
still m24-shallow "${m24[@]}" CLOCK=3 DEEP=4
# Two taps: the look past the four-tap budget, on a hot phone or the Duo.
better=m24-deep still m24-deep-two "${m24[@]}" CLOCK=3 DEEP=36 TAPS=12
# The live picture at rest, at other times: early, past the marbling's 10 s loop and near the twin's 60 s one.
still m24-clock-0.5 "${m24[@]}" CLOCK=0.5
still m24-clock-11.3 "${m24[@]}" CLOCK=11.3
still m24-clock-47.9 "${m24[@]}" CLOCK=47.9
# A rod in hand, inside its disc, and the tank's rim in hand.
sweep m24-rod LIVE "2:+1.40 2:+1.44 2:+1.48" "${m24[@]}" CLOCK=3
sweep m24-rod-deep LIVE "0:-2.30 0:-2.34" "${m24[@]}" CLOCK=3 DEEP=35
sweep m24-rim TANKLIVE "17.0 17.4 17.8" "${m24[@]}" CLOCK=3
# The opening's wind-in part way.
sweep m24-wind WIND "0.50 0.52 0.54" "${m24[@]}" CLOCK=3
# The solve's wave over the clean picture.
still m24-wave "${m24[@]}" CLOCK=3 WAVE=0.6
# With everything round the glass, so a change that moves or covers the knobs, dials and counts shows.
still m24-chrome TIER=maelstrom LEVEL=24 TANKTURNED=1 CLOCK=3
still m24-rod-chrome TIER=maelstrom LEVEL=24 TANKTURNED=1 CLOCK=3 LIVE=2:+1.4 TOUCH=0.3,-0.2
# Whirlpool 27, the deepest on the glass, and plughole 20's baked picture as deep as a stack goes.
still w27 TIER=whirlpool LEVEL=27 CLEAN=1 CLOCK=3
still p20-deep TIER=plughole LEVEL=20 CLEAN=1 DEEP=36
sweep p20-rod LIVE "1:+0.50 1:+0.54" TIER=plughole LEVEL=20 CLEAN=1
# Vortex 27: the swirl's entries, and its breath held mid-slosh.
still v27 TIER=vortex LEVEL=27 CLEAN=1 CLOCK=3
sweep v27-breath BREATH "2.20 2.24" TIER=vortex LEVEL=27 CLEAN=1 CLOCK=3
# Lens: 25 as dealt (four lenses), and Lens 1's lens in hand from x4 towards x8, where the detail is drawn.
still lens-25 PACK=lens OWNED=lens LEVEL=25 CLEAN=1
sweep lens-zoom LIVE "0:+2.00 0:+2.05 0:+2.90" PACK=lens LEVEL=1 CLEAN=1
sweep lens-out LIVE "0:-1.50 0:-1.54" PACK=lens LEVEL=1 CLEAN=1
# Escapement 2 after rod 2 +4: its clock's tick in the air.
sweep esc-tick TICKAT "0.40 0.44 0.48" PACK=escapement LEVEL=2 PLAYED=2:4 CLEAN=1
still esc-12 PACK=escapement OWNED=escapement LEVEL=12 CLEAN=1
# Prism: the last specimen as dealt, a rod in hand with its read drawn, and a swatch held.
still prism-30 PACK=prism OWNED=prism LEVEL=30 CLEAN=1
sweep prism-held LIVE "1:+1.50 1:+1.54" PACK=prism OWNED=prism LEVEL=8 CLEAN=1
still prism-swatch PACK=prism OWNED=prism LEVEL=8 CLEAN=1 SWATCH=r
# The menu's dock covers and a card's clips, which draw through the same shader at their own sizes. The menu's daily
# row on a fixed day, so a set shot past midnight matches.
still menu-dock SCREEN=menu CLOCK=3 DAILY=20261112
still card-lens CARD=lens CLOCK=3
# Reduce Motion: the live picture held on its rest frame with no clock given.
calm=1 still m24-calm "${m24[@]}"

# Takes in motion, for shimmer no still shows.
film open 7 "${m24[@]}" OPEN=1
film drag 14 "${m24[@]}" TAPDRAG=2
film play 12 "${m24[@]}" MOVES=2:8,-1:1,5:-3,u,-1:-1 PACE=1.2
# The rim in a finger's hand, carried round a step each way and let go.
film rim 14 "${m24[@]}" TAPDRAG=2 TAPFINGER=rim
film lens 9 PACK=lens LEVEL=1 CLEAN=1 MOVES=0:3,0:-5,0:2 PACE=1.5
film esc 9 PACK=escapement LEVEL=2 CLEAN=1 MOVES=2:4,w,1:-3 PACE=1.5
film prism 9 PACK=prism OWNED=prism LEVEL=8 CLEAN=1 MOVES=1:2,0:-3,u PACE=1.5
