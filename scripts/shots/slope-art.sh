# Copyright © 2026 Jack Lusher. All rights reserved.
# The slope's candidate tank pictures (UNSTIR_ART, `SlopeArt`): a level of each tier on the slope as dealt and with
# nothing stirred, on today's picture and on each set's, then each set on its tier's last level, the deepest stirs it
# would meet; then set a with the tank's bezel and knobs in the slope's colours (UNSTIR_ART=a+chrome). Sourced by
# scripts/shots.sh.
for at in plughole:14 whirlpool:9 vortex:5 maelstrom:5; do
  tier=${at%:*} level=${at#*:}
  for art in today a b c; do
    set=() what="today's picture"
    [[ $art != today ]] && set=(ART=$art) what="candidate set $art"
    hold=6 shot "slope-art-$tier-$art" "$tier $level on the slope, $what, as dealt." \
      SLOPE=1 TIER=$tier LEVEL=$level CLOCK=3 ${set[@]+"${set[@]}"}
    hold=6 shot "slope-art-$tier-$art-rest" "The same with nothing stirred." \
      SLOPE=1 TIER=$tier LEVEL=$level STACK= CLOCK=3 ${set[@]+"${set[@]}"}
    [[ $art != today ]] && hold=6 shot "slope-art-$tier-$art-deep" "$tier 27 on candidate set $art, as dealt." \
      SLOPE=1 TIER=$tier LEVEL=27 CLOCK=3 ART=$art
  done
done
hold=6 shot slope-art-chrome-plughole "Plughole 14 on set a, the bezel and knobs in the slope's stone and cream." SLOPE=1 LEVEL=14 CLOCK=3 ART=a+chrome
hold=6 shot slope-art-chrome-vortex "Vortex 5 the same, its swirl's arc as ever." SLOPE=1 TIER=vortex LEVEL=5 CLOCK=3 ART=a+chrome
hold=6 shot slope-art-chrome-maelstrom "Maelstrom 5 the same, its seized knobs and the tank's knurled rim as ever." SLOPE=1 TIER=maelstrom LEVEL=5 CLOCK=3 ART=a+chrome
hold=6 shot slope-art-chrome-drag "Plughole 12 the same, a knob in hand." SLOPE=1 LEVEL=12 CLOCK=3 ART=a+chrome LIVE=1:2
