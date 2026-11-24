# Copyright © 2026 Jack Lusher. All rights reserved.
# The slope's eggs (SlopeEggs.swift, UNSTIR_EGG): each shown without its finger, on the menu a player has with plughole
# done. Sourced in order by scripts/shots.sh.
eggs="SLOPE=1 SCREEN=menu BESTS=plughole:000000000000000000000000000,endless:9 DAILIES=4"
hold=10 shot slope-egg-still "Still water: the menu left alone (two seconds here, twenty in play), its surface flat, its light reaching down and the far ridges out of the haze." \
  $eggs EGG=still
hold=6 shot slope-egg-night "The night above: the overview pulled down past the surface, stars over the dusk and the moon at its phase for the day, full on 24 November 2026." \
  $eggs EGG=night DAILY=20261124
hold=6 shot slope-egg-night-crescent "The same four days after the new moon of 9 November: a waxing crescent, lit on the right as the north sees it." \
  $eggs EGG=night DAILY=20261113
hold=6 shot slope-egg-skim "Skimming stone: a stone flicked along the water line in its fourth hop, a ring where each touch was." $eggs EGG=skim EGGAT=1.52 CLOCK=3
hold=6 shot slope-egg-skim-count "The same gone under after five touches, its count over the water where it sank." $eggs EGG=skim EGGAT=3.2 CLOCK=3
hold=8 shot slope-egg-pebble "The unnumbered pebble: the dive's foot, a dull stone on a spur of rock under maelstrom's last ledge, tapped, and its one line of credits beside it." \
  $eggs EGG=pebble CLOCK=3
hold=6 shot slope-egg-seam "The seam: plughole all at par, a thread of gold wandering down its rock at the overview." $eggs CLOCK=3
hold=6 shot slope-egg-seam-dive "The same in the dive: the thread in the wall behind plughole's ledges, flecks of gold beside it." $eggs TIER=plughole CLOCK=3
hold=9 shot slope-egg-deep "The sky at the bottom: the overview pulled up past endless and held, the sky's stars upside down in the black under the best run's lights." \
  $eggs EGG=deep
