# Copyright © 2026 Jack Lusher. All rights reserved.
# The rings (docs/rings.md), the menu behind UNSTIR_MENU=rings. Sourced in order by scripts/shots.sh.
ringsBests=plughole:000000010000000000100010000,whirlpool:00001000100100,escapement:0,prism:00
shot rings-launch "The rings at rest on whirlpool, 14 of 27 solved (05, 09 and 12 over par), Lens owned: the sun in the ring with the tier, its count and level 15 dark on it, the daily's star over the ring four days running, three covers under it." \
  MENU=rings TIER=whirlpool BESTS=$ringsBests DAILIES=4 OWNED=lens
shot rings-locked "The rings on vortex, shut: its sun down, a dusk disc rimmed in the tier's blue, with what opens it; every bead dark." \
  MENU=rings TIER=whirlpool BESTS=$ringsBests DAILIES=4 OWNED=lens RINGSPOSE=ring:2
shot rings-bead "The rings on whirlpool, bead 09 tapped: a halo round it, and the middle names it, its best and par, and says tap again to play." \
  MENU=rings TIER=whirlpool BESTS=$ringsBests DAILIES=4 OWNED=lens RINGSPOSE=pick:9
shot rings-swipe "The rings stopped halfway from whirlpool to vortex (UNSTIR_RINGSPOSE=place:1.5): whirlpool's ring grown and fading, vortex's coming up small, the suns crossing, the floor's lines mid-run." \
  MENU=rings TIER=whirlpool BESTS=$ringsBests DAILIES=4 OWNED=lens RINGSPOSE=place:1.5
shot rings-plughole "The rings on plughole, every level solved and three over par: its own sun, and the middle on the first level short of par." \
  MENU=rings TIER=whirlpool BESTS=$ringsBests DAILIES=4 OWNED=lens RINGSPOSE=ring:0
shot rings-fresh "The rings before plughole 01 is solved: the ring alone, with no daily and no packs yet, as the old menu shows neither." \
  MENU=rings
