# Copyright © 2026 Jack Lusher. All rights reserved.
# Charybdis: its keys on the menu and in play, every level as dealt and solved at par along the solver's line
# (`scripts/charybdis-levels.py line`), and the whole free game's curtain call it now ends. Sourced by scripts/shots.sh.
count=$(grep -c '"level\.C[0-9]*\.title"' Sources/Levels.swift)
# A best at par for every level of a tier, however many it has: the harness reads one character a level and drops the rest.
all=$(printf '0%.0s' {1..36})
shot menu-charybdis "Menu on charybdis with every row unlocked (UNSTIR_UNLOCK)." TIER=charybdis UNLOCK=1
shot menu-charybdis-locked "Menu looking at charybdis, maelstrom not yet solved: its gate line in charybdis's ink." TIER=charybdis \
  BESTS=plughole:$all,whirlpool:$all,vortex:$all,maelstrom:01
shot charybdis01-open "Charybdis 01 with its key turned to the notch: the keyhole lit, both rings glowing." \
  TIER=charybdis LEVEL=1 PLAYED=0:3 CLOCK=3
shot charybdis01-ax5 "Charybdis 01 at the largest accessibility type: the title, count and buttons whole, the tank scaled." \
  TIER=charybdis LEVEL=1 CLOCK=3 TYPESIZE=accessibility5
for n in $(seq "$count"); do
  nn=$(printf '%02d' "$n")
  shot "charybdis$nn" "Charybdis level $nn as dealt." TIER=charybdis LEVEL=$n CLOCK=3
  if [[ -z "${pattern:-}" || "charybdis$nn-solved" == *$pattern* ]]; then
    line=$(scripts/charybdis-levels.py line "$n")
    shot "charybdis$nn-solved" "Charybdis level $nn solved at par along the solver's line: $line." \
      TIER=charybdis LEVEL=$n SCREEN=clean PLAYED="$line" CLOCK=0
  fi
done
# The game's curtain: every other free level at par, the last one solved along its line, held as the credit is up.
others=plughole:$all,whirlpool:$all,vortex:$all,maelstrom:$all
last=$(printf '0%.0s' $(seq $((count - 1))))-
line=$(scripts/charybdis-levels.py line "$count")
for size in large accessibility5; do
  shot "charybdis-curtain-$size" "The whole free game's curtain call after charybdis $count, at $size type: five tiers' names, every tier unstirred, the credit." \
    TIER=charybdis LEVEL=$count SCREEN=clean PLAYED="$line" OWNED=first-stir BESTS=$others,charybdis:$last PAYOFFAT=6 \
    TYPESIZE=$size CLOCK=0
done
