# Copyright © 2026 Jack Lusher. All rights reserved.
# App Store art: the clean looks and the screenshots. Sourced in order by scripts/shots.sh.
# App Store art with no interface (UNSTIR_CLEAN): each look mid-turn with a finger down on rod 0, which would draw its
# dial, count and fingertip, the glass and its picture alone in the bezel.
hold=5 shot clean-plughole-05 "Plughole 05 on the sunset, rod 0 held mid-turn, drawn clean (UNSTIR_CLEAN): the glass and picture in the bezel, no header, caption, controls, knobs, dial, count or status bar." \
  LEVEL=5 CLEAN=1 LIVE=0:+2 TOUCH=0,-0.8
# The live glass compiles its shader on its first draw after an install, which takes longer than a baked picture.
hold=9 shot clean-whirlpool-01 "Whirlpool 01 on the live glass, rod 0 held mid-turn, drawn clean: nothing but the picture." \
  TIER=whirlpool LEVEL=1 CLEAN=1 LIVE=0:+2 TOUCH=0,-0.8
hold=5 shot clean-lens-03 "Lens 03 on the halftone, its lens held mid-zoom, drawn clean: no iris, track or count." \
  PACK=lens LEVEL=3 CLEAN=1 LIVE=0:+1 TOUCH=0,-0.8
hold=5 shot clean-prism-01 "Prism 01 on the fern, rod 0 held mid-turn, drawn clean: no tinted knobs, swatches or caption." \
  PACK=prism LEVEL=1 CLEAN=1 LIVE=0:+2 TOUCH=0,-0.8
# The App Store's screenshots (Jack's calls ST4 = A, docs/store-page.md): seven of the free game, then one per sold pack,
# each a pack's taste so none needs owning. scripts/store-media.sh shoots them (shots.sh store-) and captions them.
# Live pictures wait longer, as their shaders compile on the first draw after an install.
hold=8 shot store-01-marbling "Store 1: whirlpool 25 (hex, marbling) with its full scramble." TIER=whirlpool LEVEL=25 CLOCK=3
shot store-02-count "Store 2: plughole 12, rod 1 carried -2 steps round, its dashes and count off the finger." \
  LEVEL=12 LIVE=1:-2 TOUCH=0.354,0.7
shot store-03-wave "Store 3: plughole 13 solved, the solve wave at radius 0.8." LEVEL=13 WAVE=0.8
hold=8 shot store-04-vortex "Store 4: vortex 14, Monsoon (pent, isobars), with its full scramble, its lesson learnt." \
  TIER=vortex LEVEL=14 CLOCK=3 SWIRLED=1
hold=8 shot store-05-maelstrom "Store 5: maelstrom 23 (hex), knobs 2 and 5 seized, the tank held half a step round from the rim." \
  TIER=maelstrom LEVEL=23 SEIZED=2,5 TANKLIVE=30 CLOCK=3
shot store-06-daily "Store 6: today's daily, its result card, share and next daily in 7 h." SCREEN=result MODE=daily NOW=17:00
hold=8 shot store-07-endless "Store 7: endless's first tank with 5 of the brim's 8 notches." MODE=endless BRIM=5
hold=5 shot store-08-prism "Store 8: Prism 01, the red stir healed and the cyan held halfway back, its ghosts closing on the white line." \
  PACK=prism LEVEL=1 PLAYED=0:-4 LIVE=1:+1.5
hold=5 shot store-09-lens "Store 9: Lens 03, its lens held mid-zoom, dragged down 1.4 steps of the 3 it heals at." \
  PACK=lens LEVEL=3 LIVE=0:-1.4 TOUCH=0,-0.8
hold=5 shot store-10-escapement "Store 10: Escapement 02 after rod 1 -3: its tick landed, the ratchet a tooth on, 02 ticks left." \
  PACK=escapement LEVEL=2 PLAYED=1:-3
