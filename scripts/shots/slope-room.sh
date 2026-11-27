# Copyright © 2026 Jack Lusher. All rights reserved.
# The overview at more room than one screen (UNSTIR_SLOPEROOM, SlopeMenuPlan.roominess): plughole done and whirlpool
# to 14, the scrolling overview opened at its top and further down (UNSTIR_SLOPEWADE). Sourced by
# scripts/shots.sh after slope-world.sh, whose par27 it reads.
room_bests=$par27,whirlpool:00000000000000,endless:9
shot slope-room-1-0 "The overview as built, the whole column on one screen." SLOPE=1 SCREEN=menu BESTS=$room_bests DAILIES=4 CLOCK=3
# Each screen 0.875 of a screen under the last, so a sheet can cut every later one's top, where the status bar and the
# words sinking under it stand.
for room in 2 4 7; do
  for k in 0 1 2 3 4; do
    ((room == 2 && k > 1 || room == 4 && k > 2)) && continue
    shot "slope-room-$room-$k" "The overview at $room times each tier's share, $k steps of 0.875 screens down." \
      SLOPE=1 SCREEN=menu BESTS=$room_bests DAILIES=4 CLOCK=3 SLOPEROOM=$room SLOPEWADE=$(echo "$k * 0.875" | bc)
  done
done
shot slope-room-dive-1 "The dive on whirlpool as built." SLOPE=1 SCREEN=menu TIER=whirlpool BESTS=$room_bests CLOCK=3
shot slope-room-dive-7 "The dive on whirlpool at room 7, which the room leaves as built." SLOPE=1 SCREEN=menu TIER=whirlpool BESTS=$room_bests CLOCK=3 SLOPEROOM=7
