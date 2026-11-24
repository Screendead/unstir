# Copyright © 2026 Jack Lusher. All rights reserved.
# The slope's candidate tank pictures (UNSTIR_ART, `SlopeArt`): a level of each tier on the slope as dealt and with
# nothing stirred, on today's picture and on each set's. Sourced by scripts/shots.sh.
for at in plughole:14 whirlpool:9 vortex:5 maelstrom:5; do
  for art in today a b c; do
    set=()
    [[ $art != today ]] && set=(ART=$art)
    hold=6 shot "slope-art-${at%:*}-$art" "${at%:*} ${at#*:} on the slope, ${art/today/today\'s picture}${set:+ (candidate set)}, as dealt." \
      SLOPE=1 TIER=${at%:*} LEVEL=${at#*:} CLOCK=3 ${set[@]+"${set[@]}"}
    hold=6 shot "slope-art-${at%:*}-$art-rest" "The same with nothing stirred." \
      SLOPE=1 TIER=${at%:*} LEVEL=${at#*:} STACK= CLOCK=3 ${set[@]+"${set[@]}"}
  done
done
