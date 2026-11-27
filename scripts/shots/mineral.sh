# Copyright © 2026 Jack Lusher. All rights reserved.
# Mineral's four pictures (UNSTIR_PICTURE), a tier's level each from plughole down, as the candidate sets were shot: the
# level as dealt, with nothing stirred, and the tier's last level, the deepest stirs it would meet. Sourced by
# scripts/shots.sh.
for at in plughole:14:strata whirlpool:9:agate vortex:5:lamellae maelstrom:5:columns; do
  IFS=: read -r tier level picture <<< "$at"
  hold=6 shot "mineral-$picture" "$tier $level on $picture, as dealt." TIER=$tier LEVEL=$level CLOCK=3 PICTURE=$picture
  hold=6 shot "mineral-$picture-rest" "The same with nothing stirred." TIER=$tier LEVEL=$level STACK= CLOCK=3 PICTURE=$picture
  hold=6 shot "mineral-$picture-deep" "$tier 27 on $picture, as dealt." TIER=$tier LEVEL=27 CLOCK=3 PICTURE=$picture
done
