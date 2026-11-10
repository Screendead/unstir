# Copyright © 2026 Jack Lusher. All rights reserved.
# Reduce Motion. Sourced in order by scripts/shots.sh.
# Under Reduce Motion (set on the simulator, as film.sh's calm films do): every live picture holds Picture.rest's frame,
# the brim holds where a change settles, and a spill cuts to its end, its card at once.
calm() { xcrun simctl spawn "$udid" defaults write com.apple.Accessibility ReduceMotionEnabled -bool "$1"; }
# Off again however the shots end, or every later shot records the calm look.
trap 'calm false' EXIT
calm true
for picture in glass chainmail coral neurons marbling glassTwin chainmailTwin coralTwin neuronsTwin marblingTwin isobars ephemeris cords; do
  hold=5 shot "calm-$picture" "Reduce Motion: the sandbox on $picture, stirred twice, held on its still frame (Picture.rest)." \
    MODE=sandbox PICTURE=$picture STACK=1:+5,2:-4
done
hold=9 shot calm-chainmailTwin-later "Reduce Motion: the same, 9 s in: the same frame, the heartbeat at rest between beats." \
  MODE=sandbox PICTURE=chainmailTwin STACK=1:+5,2:-4
shot calm-endless-brim-7 "Reduce Motion: endless opened at 7 notches, one from spilling: the rim still, no bob or tremble, the pin's pulse held lit." \
  MODE=endless BRIM=7
shot calm-endless-notch "Reduce Motion: endless opened at 4 notches, then rod 1 turned +1, a push: notch 5 in place at once, settled, no slosh or surge." \
  MODE=endless BRIM=4 TURNED=1:1
shot calm-endless-spilled "Reduce Motion: endless opened at 7 notches, then a push spills it: cut straight to the end, the picture stirred together, the rim brimful and still, spilled. over the tank, and the card, up at once rather than 2 s after the spill (R-spill)." \
  MODE=endless BRIM=7 TURNED=1:1
calm false
trap - EXIT
