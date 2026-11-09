# Copyright © 2026 Jack Lusher. All rights reserved.
# The menu: tiers, gates, the daily archive and where the list lands. Sourced in order by scripts/shots.sh.
shot menu "Menu before plughole 01 is solved, where backing out of it lands (a fresh install's first launch opens 01; in a build with analytics, the question answered): plughole's list under the tagline, only level 01 unlocked, no daily or endless row, the sandbox under the tier list, no pack dock." CONSENT=yes
shot menu-unlocked "Menu with every row unlocked (UNSTIR_UNLOCK)." UNLOCK=1 CONSENT=yes
# The tier strip and its gates. UNSTIR_BESTS registers bests for the one launch: a digit per level, that many over par.
par27=$(printf '0%.0s' {1..27})
some=00001000000200000100  # whirlpool 01 to 20 played, 17 of them at par
shot menu-whirlpool-locked "Menu before plughole 01 is solved, looking at whirlpool: locked, its rows dimmed, no plughole tick lit." TIER=whirlpool
shot menu-whirlpool-open "Menu on whirlpool, opened by every plughole level at par: its level 01 playable, vortex still locked." \
  TIER=whirlpool BESTS=plughole:$par27
shot menu-vortex-locked "Menu looking at vortex, 17 of whirlpool's 27 at par: ticks 01 to 20 lit but 05, 12 and 18 (over par), and under them short: 05 · 12 · 18 · 21–27, each opening its level (21 the first not played)." \
  TIER=vortex BESTS=plughole:$par27,whirlpool:$some
shot menu-vortex-open "Menu on vortex, opened by every whirlpool level at par: its level 01 playable, maelstrom still locked." \
  TIER=vortex BESTS=plughole:$par27,whirlpool:$par27
shot menu-maelstrom-locked "Menu looking at maelstrom, vortex 01 at par and 02 over: one of vortex's 27 ticks lit." \
  TIER=maelstrom BESTS=plughole:$par27,whirlpool:$par27,vortex:01
shot menu-maelstrom "Menu on maelstrom with every row unlocked (UNSTIR_UNLOCK)." TIER=maelstrom UNLOCK=1
shot menu-mid-switch "Menu mid-switch: whirlpool's list unstirring into place, held 0.4 turns short and a third faded (UNSTIR_TIERSPIN)." \
  TIER=whirlpool BESTS=plughole:$par27 TIERSPIN=-2.5:0.33
# Where the list opens: a cold launch, and back from a level through RootView's own exit (UNSTIR_EXIT).
upto13=0000000000000
# What the menu leads with (C4, C5, C18, C3's tried mark).
shot first-launch "A fresh install's first screen (UNSTIR_FRESH): plughole 01 once its opening has played, as a plain launch opens it, its note lit and under it, once ever, the line pointing at the settings." FRESH=1 OPEN=1
hold=9 shot first-launch-pointer "The same, its note at rest after 4 s: the note and the settings line under it at one strength, the knob lesson's ghost finger on knob 0 clear of both." FRESH=1 OPEN=1
shot menu-after-01 "Menu with 01 solved: next: 02 · Drip in the tagline's place, the sandbox back above the list." BESTS=plughole:0
shot menu-modes-new "Menu on whirlpool with every plughole level at par: the daily and endless rows appear, each marked new, under next: 01 and over the sandbox." \
  TIER=whirlpool BESTS=plughole:$par27
shot menu-daily-run "The same with today's daily and the three before it solved: 4 days running on the daily row, neither row new any more." \
  TIER=whirlpool BESTS=plughole:$par27 DAILIES=4
# The daily archive (to-do 47): a row under today's daily, shut until any purchase.
shot menu-archive-locked "The same, nothing bought: the archive's row under the daily, dimmed with a lock, saying it comes with any pack." \
  TIER=whirlpool BESTS=plughole:$par27 DAILIES=4
shot menu-archive-open "The same with Lens owned: the archive's row open, 30 past dailies and how many are at par." \
  TIER=whirlpool BESTS=plughole:$par27 DAILIES=4 OWNED=lens
archived=5:c,6:0,8:2,11:t,14:c,17:1,22:0
shot archive "The archive's calendar, Lens owned: the 30 days before today a month to a block, the three days before today solved on their day at par, others from the archive clean, par, +2, +1 or tried, today's number marked today." \
  TIER=whirlpool BESTS=plughole:$par27 DAILIES=4 OWNED=lens ARCHIVE=1 ARCHIVED=$archived
shot archive-large "The same at accessibility type (accessibility3): a list of days in place of the week grid." \
  TIER=whirlpool BESTS=plughole:$par27 DAILIES=4 OWNED=lens ARCHIVE=1 ARCHIVED=$archived TYPESIZE=accessibility3
shot archive-day "The daily from five days ago, opened from the archive: its own tank, and its way out reads archive." \
  MODE=archive DAY=5 OWNED=lens
shot menu-tried "Plughole 01 to 13 solved and 14 tried: tried, faint, on 14's row." BESTS=plughole:$upto13 TRIED=L14
shot menu-no-dock "Plughole 01 to 08 solved: no pack dock yet." BESTS=plughole:00000000
shot menu-landing "A cold launch with plughole 01 to 13 solved: the list centred on 14, the first level without a best." \
  BESTS=plughole:$upto13
shot menu-locktap "Plughole 01 to 13 solved, 15 tapped though locked: it shakes and says solve 14 to open for two seconds (held by UNSTIR_LOCKTAP); 14, the frontier, keeps its hairline lit." \
  BESTS=plughole:$upto13 LOCKTAP=L15
shot menu-back-left "Back from plughole 12 left mid-level, a replay with 01 to 20 solved: the list centred on 12." \
  LEVEL=12 EXIT=left BESTS=plughole:00000000000000000000
shot back-swipe "Plughole 05 held 40% into an edge swipe back: the level sliding right over the menu, centred on 05, 01 to 04 solved." LEVEL=5 BACKSWIPE=0.4 BESTS=plughole:0000
shot menu-back-swiped "Back from plughole 12 by the edge swipe: the list centred on 12." LEVEL=12 EXIT=swipe BESTS=plughole:00000000000000000000
shot menu-back-solved "Back from plughole 14's result card after a solve: the list centred on 15, the row next › opens." \
  SCREEN=clean LEVEL=14 EXIT=solved BESTS=plughole:$upto13
shot menu-mid-switch-scrolled "The list launched onto 14 (01 to 13 solved) and held a little way into a stir: the stirred copy shows the rows on screen, 10 to 19, not the list's top, and 14's hairline in the margin." \
  BESTS=plughole:$upto13 TIERSPIN=0.25:0.1
# A switch lands on the new tier's first level without a best, a locked tier's header over its gate, or the top.
hold=3.9 shot menu-switch-landing "Plughole all at par, swiped to whirlpool (UNSTIR_TIERDEMO), 01 to 20 played: the list landed centred on 21, scrolled under the stir." \
  TIERDEMO=1 BESTS=plughole:$par27,whirlpool:$some
hold=8.5 shot menu-switch-locked "Plughole all at par, swiped to whirlpool and on to vortex (UNSTIR_TIERDEMO), 17 of whirlpool's 27 at par: vortex is locked, so the list landed on its header, over the gate and its short list." \
  TIERDEMO=1 BESTS=plughole:$par27,whirlpool:$some
shot menu-back-up "Up a notch from plughole 27 into whirlpool 01, then back: the menu on whirlpool, not plughole." \
  LEVEL=27 EXIT=up BESTS=plughole:$par27
shot card-back-solved "Back from Lens 02's result card after a solve, Lens's card up (UNSTIR_CARD): the card centred on 03, the row next › opens." \
  SCREEN=clean PACK=lens LEVEL=2 CARD=lens EXIT=solved
