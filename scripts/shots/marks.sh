# Copyright © 2026 Jack Lusher. All rights reserved.
# The result's marks (Jack's calls C9 = B and D3 = A): one to three discs filled where a row's result stands, and on the
# result card. Sourced in order by scripts/shots.sh.
shot marks-menu "Plughole 01 to 07 solved, clean, at par, clean, +2, clean, at par and at par, 08 tried and 09 on locked: three, two or one disc filled at each row's right, three hollow on 08, a lock on 09 onwards." \
  BESTS=plughole:c0c2c00 TRIED=L8 CONSENT=yes
shot marks-menu-ax3 "The same at accessibility3: each row's marks or lock under its title." \
  BESTS=plughole:c0c2c00 TRIED=L8 CONSENT=yes TYPESIZE=accessibility3
shot marks-card-lens "Lens's card, owned, scrolled to its levels: 01 clean, 02 at par, 03 +2, 04 clean, 05 tried." \
  CARD=lens OWNED=lens BESTS=lens:c02c TRIED=lens-5 CARDSCROLL=1 CLOCK=5.4
shot marks-card-lens-locked "Lens's card, unowned, scrolled to its levels: 01 clean and 02 at par, 03 open, a lock on 04 onwards." \
  CARD=lens STORE=lens:unowned BESTS=lens:c0 CARDSCROLL=1 CLOCK=5.4
shot marks-result-par "Level 06 solved at par on a replay: two discs filled over at par, clean counts on the first try." \
  SCREEN=clean LEVEL=6 BESTS=plughole:000000
