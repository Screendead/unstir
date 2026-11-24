# Copyright © 2026 Jack Lusher. All rights reserved.
# The app in the slope's world (UNSTIR_SLOPE=1, RootView, docs/slope.md): the menu, play, the result and settings as a
# player meets them. A level's launch waits 6 s, as a cold launch draws black for its first two or three on a busy Mac.
# Sourced in order by scripts/shots.sh.
par27=plughole:000000000000000000000000000
thirteen=plughole:0000000000000
# The menu (piece A).
shot slope-world-fresh "A fresh install's menu on the slope: the overview, nothing solved, plughole 01 the way on." SLOPE=1 SCREEN=menu CLOCK=3
shot slope-world-menu "The overview with plughole done: its 27 lit, the daily (four days running) at the surface and endless at the foot with its best of 9." \
  SLOPE=1 SCREEN=menu BESTS=$par27,endless:9 DAILIES=4 CLOCK=3
shot slope-world-menu-ax3 "The same at accessibility3: the overview scrolling, its words whole." SLOPE=1 SCREEN=menu BESTS=$par27,endless:9 DAILIES=4 CLOCK=3 TYPESIZE=accessibility3
shot slope-world-dive "The dive on whirlpool, opened from UNSTIR_TIER, plughole done." SLOPE=1 SCREEN=menu TIER=whirlpool BESTS=$par27 CLOCK=3
shot slope-world-dive-ax3 "The same at accessibility3." SLOPE=1 SCREEN=menu TIER=whirlpool BESTS=$par27 CLOCK=3 TYPESIZE=accessibility3
shot slope-world-gate "Vortex's gate: whirlpool's pebbles as a tally on the sill, the runs still short." \
  SLOPE=1 SCREEN=menu TIER=vortex BESTS=$par27,whirlpool:00001000000200000100 CLOCK=3
hold=8 shot slope-world-lock-tap "A closed row tapped in the dive: its pebble rocks and the row says what opens it." \
  SLOPE=1 SCREEN=menu TIER=plughole BESTS=$thirteen LOCKTAP=L15 CLOCK=3
shot slope-world-run "Endless's saved run at the foot: tank 5, the brim at 3." SLOPE=1 SCREEN=menu BESTS=$par27,endless:9 MODE=endless RESUME= RESUMETANK=5 BRIM=3 CLOCK=3
shot slope-world-yours "Lens approved by Ask to Buy and landed: \"Lens is yours\" under the wordmark." SLOPE=1 SCREEN=menu APPROVED=lens OWNED=lens CLOCK=3
hold=8 shot slope-world-pick "A second and a half in, plughole 05 picked: the level comes in over the slope as the slope draws aside." \
  SLOPE=1 SCREEN=menu BESTS=$thirteen CLOCK=3 PICK=L5
hold=6 shot slope-world-return "Plughole 05 left solved a second in: the menu comes back in the dive on plughole 06." SLOPE=1 LEVEL=5 BESTS=$thirteen CLOCK=3 EXIT=solved
shot slope-world-settings "Settings opened over the menu from the stone on the bank." SLOPE=1 SCREEN=menu SETTINGS=1 CLOCK=3
shot slope-world-consent "The consent question over the menu's own ground at 0.35 of its light, its words hidden." SLOPE=1 SCREEN=menu CONSENT=ask CLOCK=3
# Packs (piece D).
shot slope-world-hollows "The dive on plughole with the packs' hollows in its wall, each cover still, its name and price." \
  SLOPE=1 SCREEN=menu TIER=plughole BESTS=$thirteen CLOCK=3
hold=6 shot slope-world-pack "Lens's hollow opened over the menu: its inside, the cover, the store's state on its ledge." SLOPE=1 SCREEN=menu CARD=lens CLOCK=3
hold=6 shot slope-world-pack-slope "The same on Lens's own slope under the floor, a ledge per level." SLOPE=1 SCREEN=menu CARD=lens CARDSCROLL=1 CLOCK=3
# Play (piece B).
hold=8 shot slope-world-first-launch "A fresh install's first launch: plughole 01 on the slope, its note and the line to settings." SLOPE=1 FRESH=1 OPEN=1 CLOCK=3
hold=6 shot slope-world-level "Plughole 14: the ground under the level, its header, title and note, the stones on its terrace." SLOPE=1 LEVEL=14 BESTS=$thirteen CLOCK=3
hold=6 shot slope-world-level-xxxl "The same at xxxLarge." SLOPE=1 LEVEL=14 BESTS=$thirteen CLOCK=3 TYPESIZE=xxxLarge
hold=6 shot slope-world-level-ax5 "The same at accessibility5, the play screen's type stopping at xxxLarge." SLOPE=1 LEVEL=14 BESTS=$thirteen CLOCK=3 TYPESIZE=accessibility5
hold=6 shot slope-world-reset-armed "Plughole 12, two moves played, reset tapped once: the stone armed, \"reset? tap again\"." SLOPE=1 LEVEL=12 PLAYED=0:+1,1:+1 RESETARMED=1 CLOCK=1
hold=6 shot slope-world-undo-refill "Plughole 12 on a new day with 6 undos banked." SLOPE=1 LEVEL=12 UNDOS=6 TODAY=2026-10-01 CLOCK=1
hold=6 shot slope-world-daily "Today's daily on the slope, its way back \"↑ menu\"." SLOPE=1 MODE=daily CLOCK=3
hold=6 shot slope-world-endless "Endless, first tank, in the open water under the brink." SLOPE=1 MODE=endless CLOCK=3
hold=6 shot slope-world-sandbox "The sandbox on the slope." SLOPE=1 MODE=sandbox CLOCK=3
hold=6 shot slope-world-lesson "Plughole 12 with knob 1 seized: the lesson on the slope." SLOPE=1 LEVEL=12 SEIZED=1 CLOCK=3
hold=6 shot slope-world-back-swipe "Plughole 12 held 40% into the back swipe over the slope's menu." SLOPE=1 LEVEL=12 BACKSWIPE=0.4 BESTS=$thirteen CLOCK=3
hold=6 shot slope-world-prism "Prism 01 on the slope: its clear water and pale stones, colour letters on." SLOPE=1 PACK=prism LEVEL=1 LETTERSCHOICE=1 CLOCK=3
hold=6 shot slope-world-lens "Lens 01 on the slope." SLOPE=1 PACK=lens LEVEL=1 CLOCK=3
hold=6 shot slope-world-escapement "Escapement 02 after 2:+4 on the slope's paper: undo, wait and reset on the terrace." SLOPE=1 PACK=escapement LEVEL=2 PLAYED=2:4 CLOCK=3
hold=6 shot slope-world-escapement-ax5 "The same at accessibility5: the wait on a second terrace." SLOPE=1 PACK=escapement LEVEL=2 PLAYED=2:4 CLOCK=3 TYPESIZE=accessibility5
# The result (piece C).
shot slope-world-result "Plughole 05 solved two over par through the real commit path: the result's lines on the water and its stones on the terrace." \
  SLOPE=1 SCREEN=result LEVEL=5 CLOCK=3
shot slope-world-clean "Plughole 06 solved clean." SLOPE=1 SCREEN=clean LEVEL=6 CLOCK=3
shot slope-world-lost "Escapement 02 run out of ticks: the lost screen on the slope." SLOPE=1 PACK=escapement LEVEL=2 PLAYED=2:4,1:-3,0:1 CLOCK=3
# The archive (piece E): its ledge and calendar alone (UNSTIR_SLOPEARCHIVE), and opened from the menu.
recent=daily-$(date -v-3d +%Y%m%d)
shot slope-archive "The archive's calendar on its own stretch of the shallows: a month to a stretch, a week to a terrace of seven seats, three days ago focused." \
  SLOPEARCHIVE=calendar CLOCK=3 SLOPEAT=$recent
shot slope-archive-ax3 "The same at accessibility3: a ledge a day, newest first." SLOPEARCHIVE=calendar CLOCK=3 SLOPEAT=$recent TYPESIZE=accessibility3
shot slope-archive-ledge "The archive's ledge on open water: shut, open with 12 at par, and before the store has read." SLOPEARCHIVE=ledge
shot slope-world-archive "The archive opened over the menu, Lens owned, the last six dailies solved at par." \
  SLOPE=1 SCREEN=menu BESTS=$par27 DAILIES=6 OWNED=lens ARCHIVE=1 CLOCK=3
hold=6 shot slope-world-archive-day "A past daily opened from the archive: its way back \"↑ archive\"." \
  SLOPE=1 MODE=archive DAY=3 OWNED=lens CLOCK=3
