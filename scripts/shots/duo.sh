# Copyright © 2026 Jack Lusher. All rights reserved.
# The iPhone Duo: open, upright, folded, the menu wide and beside play. Sourced in order by scripts/shots.sh.
# The iPhone Duo opened like a book: a 951 x 669 pt window whatever the portrait lock, its status column on the trailing
# edge (84 pt assumed from the closed display). UNSTIR_FRAME draws that window shrunk to fit this simulator, without the
# system's bars or the fold. The tank takes the leading half with its chrome round it, the menu the trailing half
# (stage 5, s5-chrome = B).
# Launched straight into a level beside the menu, the Debug build draws the tank's first picture later than
# without the menu, so these wait longer.
duo=(FRAME=951x669 INSETS=24,0,21,84)
hold=10 shot duo-open-level "Duo open: plughole 11 five moves in, the tank wholly in the leading half, its header and title above it and its note and controls below, the menu in the trailing half." \
  "${duo[@]}" LEVEL=11 PLAYED=2:-6,1:+4,3:+5,0:+1,1:+2
hold=10 shot duo-open-result "Duo open: plughole 06 solved clean, the card headed by unstirred. over the menu in the trailing half, centred on the tank where it was played." \
  "${duo[@]}" SCREEN=clean LEVEL=6
hold=10 shot duo-open-fullest "Duo open: plughole 27's fullest card (new best, again, up a notch locked) whole over the menu in the trailing half." \
  "${duo[@]}" SCREEN=result LEVEL=27 BESTS=plughole:000000000000000000000000006 CLOCK=0
hold=10 shot duo-open-escapement "Duo open: Escapement 02 a move in, the ticks' counter over the tank, the leading half on paper and the trailing half the menu's black from the fold, the glass 9 pt smaller for the counter and the serif note." \
  "${duo[@]}" PACK=escapement OWNED=escapement LEVEL=2 PLAYED=2:4
hold=10 shot duo-open-prism "Duo open: Prism 01 with the colour letters, the swatches between the note and the controls under the tank, the glass 30 pt smaller for them." \
  "${duo[@]}" PACK=prism OWNED=prism LEVEL=1 LETTERS=1
hold=10 shot duo-open-endless "Duo open: endless at three notches, the brim round the tank between the title and the note, the menu beside it." \
  "${duo[@]}" MODE=endless BRIM=3
hold=10 shot duo-open-daily-result "Duo open: today's daily solved two over par, the card's again, share and next daily beside the tank, over the menu." \
  "${duo[@]}" SCREEN=result MODE=daily NOW=17:00
shot duo-open-upright "Duo open and turned upright (669 x 951 pt): today's column, its glass stopped at 1471 px (490 pt; duocap2 = D)." \
  FRAME=669x951 INSETS=59,0,34,0 LEVEL=11 PLAYED=2:-6,1:+4,3:+5,0:+1,1:+2
# At 1471 px the shader runs four taps only to 17 entries less a live picture's fill (Tank.fourTaps(pixels:)), so the
# deepest stacks draw with two, where a phone's 40 draws every stack dealt with four; the harness shrinks the window, so these show the tap switch, not
# the Duo's frame time.
upright=(FRAME=669x951 INSETS=59,0,34,0)
hold=8 shot duo-open-upright-whirlpool-27 "Duo upright at 1471 px: whirlpool 27, Estuary, its 28 stirs as dealt on the glass, two taps here where a phone runs four: with the glass's fill the work is 32." \
  "${upright[@]}" TIER=whirlpool LEVEL=27 CLOCK=3
hold=8 shot duo-open-upright-maelstrom-27 "Duo upright at 1471 px: maelstrom 27, its 26 stirs as dealt on the marbling's twin, two taps here." \
  "${upright[@]}" TIER=maelstrom LEVEL=27 CLOCK=3
hold=8 shot duo-open-upright-endless "Duo upright at 1471 px: endless's tank 20, 28 stirs deep, with 5 of the brim's 8 notches: the column keeps the brim to the screen's edges, the glass at the cap." \
  "${upright[@]}" MODE=endless RESUME= RESUMETANK=19 BRIM=5
hold=8 shot duo-phone-whirlpool-27 "A phone, for comparison: whirlpool 27 as dealt in the Pro Max's 1171 px column, four taps: 28 stirs and the glass's fill of 4 make 32, within 40." \
  TIER=whirlpool LEVEL=27 CLOCK=3
# Folded, the fold as UNSTIR_FOLD draws it: a 19 pt band (assumed), where the system's division region would be.
# UNSTIR_THEN changes pose that many seconds in, as opening or folding the phone would.
played=(LEVEL=11 PLAYED=2:-6,1:+4,3:+5,0:+1,1:+2)
table=(FRAME=669x951 INSETS=59,0,34,0 FOLD=0,466,669,19)
closed=(FRAME=466x678 INSETS=0,0,34,84)
hold=10 shot duo-folded-book "Duo half open like a book: the split clear of the fold's band either side, the tank and its chrome wholly in the leading half, the menu in the trailing half." \
  "${duo[@]}" FOLD=466,0,19,669 "${played[@]}"
shot duo-tabletop "Duo upright and folded on a table: header, note and controls in the upright half, the tank filling the half lying flat." \
  "${table[@]}" "${played[@]}"
shot duo-tabletop-result "Duo tabletop: plughole 06 solved clean, the card and unstirred. in the upright half, above the fold." \
  "${table[@]}" SCREEN=clean LEVEL=6
shot duo-tabletop-daily-result "Duo tabletop: today's daily two over par, its card's again, share and next daily all above the fold." \
  "${table[@]}" SCREEN=result MODE=daily NOW=17:00
shot duo-tabletop-fullest "Duo tabletop: plughole 27 over par against a best of +6, the fullest card a tier level shows (new best, again, up a notch locked): the caption risen so the card ends above unstirred., clear of the fold." \
  "${table[@]}" SCREEN=result LEVEL=27 BESTS=plughole:000000000000000000000000006 CLOCK=0
shot duo-tabletop-pack-complete "Duo tabletop: Lens 25 solved, Lens complete and its pointer under the card, all above unstirred. and the fold." \
  "${table[@]}" PACK=lens LEVEL=25 SCREEN=clean OWNED=first-stir,lens BESTS=lens:000000000000000000000000- CLOCK=0
shot duo-tabletop-escapement "Duo tabletop: Escapement 02 a move in, the ticks' counter in the upright half." \
  "${table[@]}" PACK=escapement OWNED=escapement LEVEL=2 PLAYED=2:4
shot duo-tabletop-prism "Duo tabletop: Prism 01 with the colour letters, the swatches under the note in the upright half." \
  "${table[@]}" PACK=prism OWNED=prism LEVEL=1 LETTERS=1
# Stage 3: what each level draws round its glass (the brim, the rim lesson, counts, the night forwards) kept inside
# the tank's pane, the glass smaller where it needs the room.
hold=10 shot duo-folded-spill "Duo half open like a book, endless spilling 1.1 s in: the brim's pour, glow and drops whole inside the leading half, the glass smaller than other levels' so the brim clears the fold, the menu beside it." \
  "${duo[@]}" FOLD=466,0,19,669 MODE=endless BRIM=7 TURNED=1:1 CLOCK=1.1
shot duo-tabletop-brim "Duo tabletop: endless at seven notches, the pin's pulse at its peak, the brim's bloom whole in the lower half, clear of the fold." \
  "${table[@]}" MODE=endless BRIM=7 CLOCK=0.38
shot duo-tabletop-lesson "Duo tabletop: maelstrom 01, the tank never turned: the rim lesson's arc and ghost finger over twelve, below the fold, the glass sat on the half's foot to make room." \
  "${table[@]}" TIER=maelstrom LEVEL=1 CLOCK=3
shot duo-tabletop-lesson-count "Duo tabletop: whirlpool 25 with knobs 2 and 5 seized, rod 1 at the top turned +1: its count beside the lesson's arc, both below the fold." \
  "${table[@]}" TIER=whirlpool LEVEL=25 SEIZED=2,5 LIVE=1:+1 TOUCH=0,-0.3 CLOCK=3
shot duo-tabletop-lens-long "Duo tabletop: Lens 01's top lens held turned nine steps up (UNSTIR_LIVE, a held turn, not a drag), past the pane's top: the lens stops at +7, the last step its track shows inside the pane (d3-lenscap = B), its count and dashes clear of the fold." \
  "${table[@]}" PACK=lens LEVEL=1 LIVE=0:+9 TOUCH=0,-0.42
hold=25 shot duo-phone-lens-long "A phone, for comparison: the same held turn of nine steps up in the column, which caps nothing, so the lens zooms all nine." \
  PACK=lens LEVEL=1 LIVE=0:+9 TOUCH=0,-0.42
shot duo-tabletop-ending "Duo tabletop: the night forwards 1 s in, its lines (the beat, the time, tap to skip) at the foot of the upright half, where unstirred. stands, as the glass fills the lower half." \
  "${table[@]}" PACK=first-stir LEVEL=25 OWNED=first-stir SCREEN=clean ENDING=1.1
shot duo-tabletop-ladder-end-ax5 "Duo tabletop at the largest accessibility text size: maelstrom 27 over par, its more puzzles in the packs line at that size, the card whole above unstirred. and the fold." \
  "${table[@]}" SCREEN=result TIER=maelstrom LEVEL=27 OWNED=first-stir CLOCK=0 TYPESIZE=accessibility5
# Stage 4: the menu wide. The list keeps the leading half, its dock under it as on a phone; a pack's card or the archive
# opens in the trailing half beside it, not over it. A tall window, folded or not, keeps today's menu.
hold=10 shot duo-open-menu "Duo open: the menu with plughole 01 to 09 at par, the list and its dock at a phone's width in the leading half, the trailing half empty until a card opens." \
  "${duo[@]}" SCREEN=menu BESTS=plughole:$nine OWNED= CLOCK=1
hold=10 shot duo-open-card "Duo open: Prism's card from the dock, in the trailing half beside the list, which stays live, the dock's covers still turning; its way out reads ✕ close, as the menu is in sight (d4-menuback = B)." \
  "${duo[@]}" SCREEN=menu BESTS=plughole:$nine OWNED= CARD=prism CLOCK=1
hold=10 shot duo-open-card-gate "Duo open: Lens 04 opened past the taste, its card beside the list, scrolled to buying under you've played the free three." \
  "${duo[@]}" PACK=lens LEVEL=4 BESTS=plughole:$nine,lens:000 OWNED= CLOCK=1
hold=10 shot duo-open-card-owned "Duo open: Lens owned, its card home beside the list: done 3/25 at par, play 04, the levels." \
  "${duo[@]}" SCREEN=menu BESTS=plughole:$nine,lens:000 OWNED=lens CARD=lens CLOCK=1
hold=10 shot duo-open-archive "Duo open: the archive's calendar beside the list, Lens owned." \
  "${duo[@]}" SCREEN=menu TIER=whirlpool BESTS=plughole:$par27 DAILIES=4 OWNED=lens ARCHIVE=1 ARCHIVED=5:c,6:0,8:2,11:t
hold=16 shot duo-open-card-over-archive "Duo open: the archive beside the list, Lens's card opened from the dock 4.5 s in and closed again (UNSTIR_SHELFDEMO): the trailing half empty, as the card closed the archive rather than lying over it." \
  "${duo[@]}" SCREEN=menu TIER=whirlpool BESTS=plughole:$par27 DAILIES=4 OWNED=lens ARCHIVE=1 SHELFDEMO=1
shot duo-open-mid-switch "Duo open: the menu mid-switch, whirlpool's list unstirring into place inside the leading half (UNSTIR_TIERSPIN)." \
  "${duo[@]}" SCREEN=menu TIER=whirlpool BESTS=plughole:$par27 TIERSPIN=-2.5:0.33 OWNED= CLOCK=1
hold=10 shot duo-folded-book-menu "Duo half open like a book: the list in the leading half and Escapement's card in the trailing half, each clear of the fold's band." \
  "${duo[@]}" FOLD=466,0,19,669 SCREEN=menu BESTS=plughole:$nine OWNED= CARD=escapement CLOCK=1
hold=10 shot duo-open-upright-menu "Duo open and turned upright (669 x 951 pt): today's menu, Prism's card over it, its way out ‹ menu as on a phone." \
  FRAME=669x951 INSETS=59,0,34,0 SCREEN=menu BESTS=plughole:$nine OWNED= CARD=prism CLOCK=1
hold=10 shot duo-tabletop-menu "Duo tabletop: the title, strip and list in the upright half, ending 16 pt above the fold, and the dock at the foot of the half lying flat." \
  "${table[@]}" SCREEN=menu BESTS=plughole:$nine OWNED= CLOCK=1
hold=10 shot duo-folding-menu "Duo open with Prism's card beside the list, half folded a second in: the list and the card each drew back clear of the fold's band." \
  "${duo[@]}" THEN=1 THENFOLD=466,0,19,669 SCREEN=menu BESTS=plughole:$nine OWNED= CARD=prism CLOCK=1
hold=5 shot duo-opened-menu "Duo closed with Prism's card over the menu, opened a second in: the card moved beside the list, the list where it was." \
  "${closed[@]}" THEN=1 THENFRAME=951x669 THENINSETS=24,0,21,84 SCREEN=menu BESTS=plughole:$nine OWNED= CARD=prism CLOCK=1
# A card keeps its scroll through a change of pose (d4-pose = B): the same card, moved, not opened again.
hold=5 shot duo-opened-card-scrolled "Duo closed with Prism's card over the menu scrolled to its specimens, opened a second in: the card beside the list, still on its specimens." \
  "${closed[@]}" THEN=1 THENFRAME=951x669 THENINSETS=24,0,21,84 SCREEN=menu BESTS=plughole:$nine OWNED=prism CARD=prism CARDSCROLL=1 CLOCK=1
hold=5 shot duo-closed-card-scrolled "Duo open with Prism's card beside the list scrolled to its specimens, closed a second in: the card over the menu, still on its specimens." \
  "${duo[@]}" THEN=1 THENFRAME=466x678 THENINSETS=0,0,34,84 SCREEN=menu BESTS=plughole:$nine OWNED=prism CARD=prism CARDSCROLL=1 CLOCK=1
hold=5 shot duo-opened "Duo closed (466 x 678 pt), opened a second in: the same game glided into the split, its five moves kept, the menu faded in beside it." \
  "${closed[@]}" THEN=1 THENFRAME=951x669 THENINSETS=24,0,21,84 "${played[@]}"
hold=4 shot duo-opened-mid-drag "Duo closed with rod 1 held two steps round, opened 1.5 s in: the turn let go as a lift would (moves 1), nothing held, the menu beside." \
  "${closed[@]}" THEN=1.5 THENFRAME=951x669 THENINSETS=24,0,21,84 LEVEL=11 LIVE=1:+2 TOUCH=0.3,0.2
hold=5 shot duo-folded-to-tabletop "Duo upright, folded a second in: the tank glided down into the lower half." \
  FRAME=669x951 INSETS=59,0,34,0 THEN=1 THENFOLD=0,466,669,19 "${played[@]}"
# Stage 5: the menu beside play (Jack's calls D-layout = 3, DUOMENU = B and s5-chrome = B, round 16, and s5b-title = B).
# Where play splits, the tank and its chrome round it keep the leading half and the menu, title and gear too, takes the
# trailing half; the list glides between halves, and a result or lost card goes over the menu.
hold=8 shot duo-beside-level "Duo open: plughole 11 five moves in beside the menu: header and title over the tank, note and controls under it at stage 1's glass, the menu in the trailing half under its title and gear, the list centred on 11, its hairline at full and playing in place of its rods and par, 10's frontier hairline above it, and the dock held still." \
  "${duo[@]}" "${played[@]}" BESTS=plughole:$nine OWNED= CLOCK=1
hold=8 shot duo-beside-opened-from-menu "Duo open: the menu, plughole 05 picked 1.5 s in (UNSTIR_PICK): the list glided to the trailing half with its title and gear, 05's tank and chrome in the leading half." \
  "${duo[@]}" SCREEN=menu BESTS=plughole:$nine OWNED= CLOCK=1 PICK=L5
hold=8 shot duo-beside-pick "Duo open: plughole 11 beside the menu, row 07 tapped 1.5 s in (UNSTIR_PICK): 11 left through its own way out, 07 in the tank, the list following it." \
  "${duo[@]}" LEVEL=11 BESTS=plughole:$nine OWNED= CLOCK=1 PICK=L7
hold=8 shot duo-beside-back "Duo open: plughole 11 beside the menu, left by its back a second in: the list back in the leading half under its title and gear, the trailing half empty." \
  "${duo[@]}" LEVEL=11 BESTS=plughole:$nine OWNED= CLOCK=1 EXIT=left
hold=8 shot duo-beside-result "Duo open: plughole 06 solved clean beside the menu: the result card headed by unstirred. over the menu in the trailing half, centred on the tank, the list gone under it." \
  "${duo[@]}" SCREEN=clean LEVEL=6 BESTS=plughole:$nine OWNED= CLOCK=1
hold=8 shot duo-beside-card "Duo open: plughole 11 beside the menu, Lens's card opened from the dock 4.5 s in (UNSTIR_SHELFDEMO) over the whole trailing half, its way out ‹ menu, the tank and its chrome playing on." \
  "${duo[@]}" "${played[@]}" BESTS=plughole:$nine OWNED= SHELFDEMO=1 CLOCK=1
hold=35 shot duo-beside-gate "Duo open: Lens 03 solved, Lens 04 picked past the taste: the gate's card over 03's result card in the trailing half on buying, its way out ✕ close (s5b-back = B), Lens 03 still in the tank." \
  "${duo[@]}" PACK=lens LEVEL=3 SCREEN=clean BESTS=plughole:$nine,lens:00 OWNED= CLOCK=1 PICK=lens-4
hold=10 shot duo-beside-archive "Duo open: whirlpool 11 beside the menu, the archive opened 1.5 s in as its row opens it (UNSTIR_PICK=archive), over the trailing half, Lens owned." \
  "${duo[@]}" TIER=whirlpool LEVEL=11 BESTS=plughole:$par27 DAILIES=4 OWNED=lens PICK=archive CLOCK=1
# Solved live, not through SCREEN=clean, which solves before the first layout: the slot shrinks under the card.
hold=12 shot duo-beside-live-solve "Duo open: plughole 19 solved live at par (UNSTIR_MOVES), whirlpool's up a notch on the card over the menu." \
  "${duo[@]}" LEVEL=19 MOVES=4:-7,1:+7,0:+4,3:+5,2:-4 BESTS=plughole:000000000000000000600000000 OWNED= CLOCK=1
hold=8 shot duo-beside-ax3 "Duo open at accessibility3: plughole 27's fullest card over the menu at that size, the chrome round the tank fixed in size." \
  "${duo[@]}" SCREEN=result LEVEL=27 BESTS=plughole:000000000000000000000000006 OWNED= CLOCK=0 TYPESIZE=accessibility3
hold=8 shot duo-beside-ax5 "Duo open at the largest accessibility size: maelstrom 27 over par, its more puzzles in the packs line at that size, the card whole over the menu, the chrome round the tank as at every size." \
  "${duo[@]}" SCREEN=result TIER=maelstrom LEVEL=27 OWNED=first-stir CLOCK=0 TYPESIZE=accessibility5
hold=10 shot duo-beside-pack-complete "Duo open: Lens 25 solved, Lens complete and its pointer on the card over the menu." \
  "${duo[@]}" PACK=lens LEVEL=25 SCREEN=clean OWNED=first-stir,lens BESTS=lens:000000000000000000000000- CLOCK=0
hold=10 shot duo-beside-lost "Duo open: Escapement 02 out of ticks beside the menu: the lost card over the trailing half on the level's paper, the stamp on the glass." \
  "${duo[@]}" PACK=escapement OWNED=escapement LEVEL=2 PLAYED=0:1,0:1,0:1 CLOCK=1
# A fresh install opened like a book (s5b-title = B): no settings line beside the menu, its gear in sight (r16c-pointer = C).
hold=9 shot duo-beside-pointer "Duo open: a fresh install's first screen, plughole 01 beside the menu, its note at rest and no settings line under it: the gear is beside the menu's title." \
  "${duo[@]}" FRESH=1 OPEN=1
hold=8 shot duo-beside-lesson "Duo open: maelstrom 01, the tank never turned: the rim lesson's arc between the title and the glass, 5 pt smaller for it." \
  "${duo[@]}" TIER=maelstrom LEVEL=1 CLOCK=3
# A pack card over a result card, opened as the card's pointer opens one; the shelf tour closes it 7.2 s later.
hold=12 shot duo-beside-over-result "Duo open: Lens 25 solved beside the menu, Lens's card opened 4.5 s in (UNSTIR_SHELFDEMO) over the result card, which covers the menu: its way out ✕ close (s5b-back = B)." \
  "${duo[@]}" PACK=lens LEVEL=25 SCREEN=clean OWNED=first-stir,lens BESTS=plughole:$nine,lens:000000000000000000000000- SHELFDEMO=1 CLOCK=0
hold=20 shot duo-beside-over-result-closed "Duo open: the same, the card closed again 7.2 s later by ✕ close: the result card back over the menu." \
  "${duo[@]}" PACK=lens LEVEL=25 SCREEN=clean OWNED=first-stir,lens BESTS=plughole:$nine,lens:000000000000000000000000- SHELFDEMO=1 CLOCK=0
hold=12 shot duo-beside-lens-long "Duo open: Lens 01's top lens held turned nine steps up beside the menu: all nine fit its track, which ends between the title and the rim, clear of both." \
  "${duo[@]}" PACK=lens LEVEL=1 LIVE=0:+9 TOUCH=0,-0.42 OWNED=lens
hold=12 shot duo-beside-lens-wrong "Duo open: Lens 08's top lens held fourteen steps up, the wrong way, beside the menu: capped at +9, where its track meets the title, clear of moves / par." \
  "${duo[@]}" PACK=lens LEVEL=8 LIVE=0:+14 TOUCH=0.25,-0.354 OWNED=lens
hold=10 shot duo-beside-prism-letters "Duo open: Prism 01 read by its colour letters beside the menu: the R G B swatches under the note, the glass 30 pt smaller for them." \
  "${duo[@]}" PACK=prism LEVEL=1 OWNED=prism LETTERS=1 CLOCK=1
hold=6 shot duo-beside-opened "Duo closed with plughole 11 five moves in, opened a second in: the tank and its chrome glided into the leading half and the menu faded in beside them." \
  "${closed[@]}" THEN=1 THENFRAME=951x669 THENINSETS=24,0,21,84 "${played[@]}" BESTS=plughole:$nine OWNED= CLOCK=1
hold=8 shot duo-beside-opened-card "Duo closed with Lens's card left under Lens 01 as its try free left it, opened a second in: the card put away, the list in sight beside the level; it comes back as the level leaves." \
  "${closed[@]}" THEN=1 THENFRAME=951x669 THENINSETS=24,0,21,84 PACK=lens LEVEL=1 CARD=lens BESTS=plughole:$nine OWNED= CLOCK=1
hold=6 shot duo-beside-closed "Duo open with plughole 11 beside the menu, closed a second in: today's column, the menu gone with the window's split." \
  "${duo[@]}" THEN=1 THENFRAME=466x678 THENINSETS=0,0,34,84 "${played[@]}" BESTS=plughole:$nine OWNED= CLOCK=1
hold=6 shot duo-beside-folding "Duo open with plughole 11 beside the menu, half folded a second in: the tank, its chrome and the list drew back clear of the fold's band." \
  "${duo[@]}" THEN=1 THENFOLD=466,0,19,669 "${played[@]}" BESTS=plughole:$nine OWNED= CLOCK=1
hold=10 shot duo-tabletop-menu-card "Duo tabletop: Prism's card in the half lying flat over the dock, ✕ close, the list above the fold." \
  "${table[@]}" SCREEN=menu BESTS=plughole:$nine OWNED= CARD=prism CLOCK=1
