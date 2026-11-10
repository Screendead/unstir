# Copyright © 2026 Jack Lusher. All rights reserved.
# The type scale at large Dynamic Type sizes (Jack's call DESIGN5 = A): every screen follows Text Size, the play screen
# capped at xxxLarge. Sourced in order by scripts/shots.sh, after the menu's (par27).
shot type-menu-xxxl "Menu on whirlpool at xxxLarge type, the daily run four days and endless beside it: rows at body size, numbers, details and results scaled with them." \
  TIER=whirlpool BESTS=plughole:$par27 DAILIES=4 TYPESIZE=xxxLarge
shot type-menu-ax3 "The same at accessibility3: each row's result under its title, so the title keeps the row's width." \
  TIER=whirlpool BESTS=plughole:$par27 DAILIES=4 TYPESIZE=accessibility3
shot type-level-xxxl "Level 01 at xxxLarge type: the header, title, note and controls grown, the tank still the screen's width." \
  LEVEL=1 CLOCK=0 TYPESIZE=xxxLarge
shot type-level-ax5 "Level 01 at accessibility5: the play screen capped at xxxLarge, the same frame as type-level-xxxl." \
  LEVEL=1 CLOCK=0 TYPESIZE=accessibility5
shot type-result-xxxl "Level 05's result card at xxxLarge, over par against a stored best of +6: its lines and buttons at the larger size." \
  SCREEN=result LEVEL=5 BESTS=plughole:00006 TYPESIZE=xxxLarge
shot type-result-fullest-xxxl "Plughole 27's fullest card at xxxLarge: the new best's line, again, and up a notch locked, the card's type stepped down a size at a time until it stands whole over the screen's foot, the glass the size it was played at." \
  SCREEN=result LEVEL=27 BESTS=plughole:000000000000000000000000006 CLOCK=0 TYPESIZE=xxxLarge
shot type-result-clean-xxxl "Level 06's clean result card at xxxLarge." SCREEN=clean LEVEL=6 TYPESIZE=xxxLarge
shot type-result-par-xxxl "Level 06 solved at par on a replay, at xxxLarge." SCREEN=clean LEVEL=6 BESTS=plughole:000000 TYPESIZE=xxxLarge
shot type-tier-up-xxxl "Vortex 27's result card at xxxLarge, maelstrom open: up a notch to MAELSTROM." \
  SCREEN=clean TIER=vortex LEVEL=27 UNLOCK=1 CLOCK=0 TYPESIZE=xxxLarge
shot type-daily-result-xxxl "Today's daily's result card at xxxLarge, two over par: again, share and next daily in 7 h." \
  SCREEN=result MODE=daily NOW=17:00 TYPESIZE=xxxLarge
shot type-menu-marks-xxxl "Plughole 01 to 07 solved and 08 tried at xxxLarge: each row's marks at its right." \
  BESTS=plughole:c0c2c00 TRIED=L8 CONSENT=yes TYPESIZE=xxxLarge
shot type-lost-xxxl "Escapement 2 out of ticks at xxxLarge: the lost card's line and buttons at the larger size." \
  PACK=escapement LEVEL=2 PLAYED=2:4,1:-3,0:1 TYPESIZE=xxxLarge
shot type-settings-ax3 "Settings at accessibility3: the title, rows and details scaled, the sheet scrolling." SETTINGS=1 TYPESIZE=accessibility3
