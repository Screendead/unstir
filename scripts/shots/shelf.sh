# Copyright © 2026 Jack Lusher. All rights reserved.
# The pack shelf: the dock, each pack's card and its clip. Sourced in order by scripts/shots.sh.
# A Debug build bakes Lens's halftone some 20 s the first time a size is asked for; one launch caches it for the shots.
if [[ -z "$pattern" || card-lens == *$pattern* || clip-lens == *$pattern* || shelf == *$pattern* ]]; then
  SIMCTL_CHILD_UNSTIR_CARD=lens xcrun simctl launch --terminate-running-process "$udid" "$bundle" >/dev/null
  sleep 25
fi
# The pack shelf: a dock of live covers along the bottom of the menu, each opening its pack's card (UNSTIR_CARD). Clips
# held 5.4 s in. Prices are the StoreKit configuration's, as a US storefront shows them.
# The dock shows once plughole 09 is solved.
nine=000000000
shot shelf-menu "Menu with the pack dock, plughole 01 to 09 solved (a Debug build, which shows First Stir too): First Stir, Lens, Escapement, Prism and Triptych, nothing bought." \
  STORE=lens:unowned CLOCK=5.4 BESTS=plughole:$nine
shot shelf-menu-stirred "The dock 2.8 s into its loop, each cover its clip's level on its own picture, out of step: First Stir and Triptych (a wedge of each pack's) fully stirred, Lens's halftone unstirring, Escapement's engraved plate clean on bone, Prism's fern just stirring in." \
  STORE=lens:unowned CLOCK=2.8 BESTS=plughole:$nine
shot shelf-menu-clean "The dock at the top of its loop: First Stir and Triptych clean, Lens stirring in, Escapement and Prism unstirring." \
  STORE=lens:unowned CLOCK=0 BESTS=plughole:$nine
shot shelf-menu-states "The dock with Lens owned and Escapement waiting on Ask to Buy: a lime check and an amber hourglass." \
  OWNED=lens STORE=escapement:pending CLOCK=5.4 BESTS=plughole:$nine
shot shelf-new "Plughole all solved: Lens and Prism marked new on the dock, Escapement not (maelstrom is shut), nor First Stir." \
  BESTS=plughole:$par27 STORE=lens:unowned CLOCK=5.4
shot shelf-taste-count "Plughole 01 to 09 solved and Lens 01 and 02: 2/3 free under Lens." BESTS=plughole:000000000,lens:00 STORE=lens:unowned CLOCK=5.4
shot shelf-new-levels "Lens owned, its card last opened with 20 levels: new under Lens beside the check." \
  BESTS=plughole:000000000 OWNED=lens SEENLEVELS=lens:20 CLOCK=5.4
shot shelf-approved "The menu after Lens's Ask to Buy approval landed: Lens is yours in the dock's header." \
  BESTS=plughole:000000000 OWNED=lens APPROVED=lens CLOCK=1
for state in unowned owned pending failed revoked; do
  saves=": Triptych's line saves \$2.98 on its three packs"
  [[ $state == owned ]] && saves=""
  shot card-lens-$state "Lens's card, $state$saves." CARD=lens STORE=lens:$state CLOCK=5.4
done
shot f14-card "Lens's card before the launch's first read of the entitlements ends, as a promoted purchase at a cold launch opens it: \"checking purchases…\" in place of its status and buy." \
  CARD=lens STORE=lens:unowned,unread CLOCK=5.4
shot card-prism-no-complete "Prism's card with Lens and First Stir owned (First Stir is outside the bundle): no Triptych line, since \$5.99 is more than the two packs left." \
  CARD=prism OWNED=lens,first-stir CLOCK=5.4
shot shelf-menu-lens-owned "The dock with Lens and First Stir owned: no Triptych cover, since it costs more than the two packs left." \
  BESTS=plughole:000000000 OWNED=lens,first-stir CLOCK=5.4
shot card-first-stir "First Stir's card, unowned." CARD=first-stir STORE=lens:unowned CLOCK=5.4
shot card-escapement "Escapement's card, unowned." CARD=escapement STORE=lens:unowned CLOCK=5.4
shot card-prism "Prism's card, unowned: the fern printed off register in red, green and blue, its clip, letters for colour-blind play, in settings, and its 30 specimens under five tray headings." \
  CARD=prism STORE=lens:unowned CLOCK=5.4
shot card-prism-levels "Prism's card, owned, scrolled to its specimens under the five trays." CARD=prism OWNED=prism CARDSCROLL=1 CLOCK=5.4
shot card-complete "Triptych's card, unowned: save \$2.98 on the packs you don't have." CARD=complete STORE=lens:unowned CLOCK=5.4
shot card-complete-saves-nothing "UNSTIR_CARD=complete with Lens and First Stir owned: Triptych saves nothing on the two left, so no card opens, as none does going back to it, and the dock has no Triptych cover." \
  CARD=complete OWNED=lens,first-stir CLOCK=5.4
# Each card's clip (`Clip`) held on the frame Reduce Motion holds, and a few frames either side of it.
shot clip-first-stir-still "First Stir's clip on its still: level 1 with two vignettes played, its time 11:57 pm." \
  CARD=first-stir STORE=lens:unowned CLOCK=4.2
for t in 1.4 2.1 3.3 5.4 6.2; do
  shot clip-first-stir-$t "First Stir's clip $t s in." CARD=first-stir STORE=lens:unowned CLOCK=$t
done
shot clip-lens-still "Lens's clip on its still: level 3 as dealt, the lens newest, its rim whole through both twists." \
  CARD=lens STORE=lens:unowned CLOCK=0.5
for t in 2.4 3.2 4.3; do
  shot clip-lens-$t "Lens's clip $t s in, the lens dragged down and back up." CARD=lens STORE=lens:unowned CLOCK=$t
done
shot clip-escapement-still "Escapement's clip on its still: rod 2 +4 let go, its tick landed, the ratchet a tooth on." \
  CARD=escapement STORE=lens:unowned CLOCK=2.55
for t in 1.6 2.2 3.6 5.1 5.9; do
  shot clip-escapement-$t "Escapement's clip $t s in." CARD=escapement STORE=lens:unowned CLOCK=$t
done
shot clip-prism-still "Prism's clip on its still: specimen 1 as dealt, red ghosts round the red rod and cyan round the cyan." \
  CARD=prism STORE=lens:unowned CLOCK=0.5
for t in 1.4 2.4 3.6 5.0; do
  shot clip-prism-$t "Prism's clip $t s in: the buried red stir off first, then the cyan, then the white." CARD=prism STORE=lens:unowned CLOCK=$t
done
shot card-lens-complete-failed "Lens's card after Triptych, bought from it, failed: the line under Triptych's button says so." \
  CARD=lens STORE=complete:failed CLOCK=5.4
shot card-complete-owned "Triptych's card, owned: BUNDLE, no taste or restore, each pack's name opening its card, playing on in Lens." \
  CARD=complete OWNED=complete CLOCK=5.4
shot card-lens-complete-pending "Lens's card while Triptych waits on Ask to Buy: Triptych is waiting, buy Lens alone, Triptych's line disabled." \
  CARD=lens STORE=complete:pending CLOCK=5.4
shot card-lens-asked-offline "Lens's card after asking again offline: still waiting for approval, asked, no connection under it." \
  CARD=lens STORE=lens:pending FAILED=offline CLOCK=5.4
shot card-lens-progress "Lens's card, owned, 01 to 05 played and 04 one over: PACK, done 4/25 at par, continue 06, no restore." \
  CARD=lens OWNED=complete BESTS=lens:00010 CLOCK=5.4
shot card-lens-tried "Lens's card, owned, 01 solved and 02 tried: tried, faint, on 02's row, ‹ menu pinned over the scroll." \
  CARD=lens OWNED=lens BESTS=lens:0 TRIED=lens-2 CARDSCROLL=1 CLOCK=5.4
shot shelf-menu-owned "The dock with every pack owned, the three through Triptych and First Stir (outside it) on its own: PACKS alone, no taste line, Triptych's cover gone." \
  OWNED=complete,first-stir CLOCK=5.4
shot card-lens-noprice "Lens's card before the App Store answers: buy, price loading, and no Triptych line until the prices say what it saves." CARD=lens STORE=lens:unowned PRICES=0 CLOCK=5.4
shot card-lens-unreachable "Lens's card after the price fetch failed: buy, App Store unreachable, the pill still live, no Triptych line." \
  CARD=lens STORE=lens:unowned PRICES=unreachable CLOCK=5.4
shot shelf-menu-unreachable "The dock after the price fetch failed, nothing bought: Triptych's cover stays, since with none of its packs owned it holds them all for less, so a card's fetch never moves it while none is owned." \
  STORE=lens:unowned PRICES=unreachable CLOCK=5.4 BESTS=plughole:$nine
shot card-lens-unshared "Lens's card after a family stopped sharing it: no longer shared with you, your progress is kept, in grey." \
  CARD=lens STORE=lens:unshared CLOCK=5.4
shot card-lens-offline "Lens's card after a purchase failed offline: no connection, try again when you're online." \
  CARD=lens STORE=lens:failed FAILED=offline CLOCK=5.4
shot card-lens-nopay "Lens's card with in-app purchases turned off on the iPhone: no buy and no Triptych, try free kept." \
  CARD=lens STORE=lens:unowned PAYMENTS=0 CLOCK=5.4
shot card-lens-restored "Lens's card, owned, after a restore found it: restored Lens." CARD=lens OWNED=lens RESTORED=lens CLOCK=5.4
shot card-lens-restored-none "Lens's card after a restore found nothing: nothing to restore on this Apple ID." \
  CARD=lens STORE=lens:unowned RESTORED=none CLOCK=5.4
shot card-lens-levels "Lens's card, unowned, scrolled to its levels under the four chapter headings: 04 on locked, ‹ menu still pinned at the top." \
  CARD=lens STORE=lens:unowned CARDSCROLL=1 CLOCK=5.4
shot card-lens-levels-owned "The same, owned: every level open." CARD=lens OWNED=lens CARDSCROLL=1 CLOCK=5.4
shot card-gate "Lens's level 5, unowned, opened (UNSTIR_PACK): its card shows in the level's place, scrolled to buying under the free three's note, ‹ menu pinned over the scroll." \
  PACK=lens LEVEL=5 STORE=lens:unowned BESTS=lens:000 CARDLEVELS=6 CLOCK=5.4
shot card-gate-ax "The same at accessibility3: the Triptych line under buy wraps only before · save." \
  PACK=lens LEVEL=5 STORE=lens:unowned BESTS=lens:000 CARDLEVELS=6 CLOCK=5.4 TYPESIZE=accessibility3
shot card-gate-fewer "Lens's level 5, unowned, opened with only 03 solved (01 and 02 skipped): scrolled to buying under The first three are free. 22 more in Lens." \
  PACK=lens LEVEL=5 STORE=lens:unowned BESTS=lens:--0 CARDLEVELS=6 CLOCK=5.4
shot card-gate-refunded "Lens's level 5 opened by a refunded owner, the free three at par: no free-three line, the revocation's own grey line in its place, buy again." \
  PACK=lens LEVEL=5 STORE=lens:revoked BESTS=lens:000 CARDLEVELS=6 CLOCK=5.4
shot card-lens-taste-end "Lens 03 solved, unowned: the result card's button says more in Lens, in Lens's magenta." \
  PACK=lens LEVEL=3 SCREEN=clean STORE=lens:unowned CLOCK=5.4
shot card-lens-taste-end-owned "The same, owned: next again, still in Lens's magenta." \
  PACK=lens LEVEL=3 SCREEN=clean OWNED=lens CLOCK=5.4
shot card-lens-replay "Lens's card, unowned, the taste played: replay 01-03 in try free's place." \
  CARD=lens STORE=lens:unowned BESTS=lens:000 CLOCK=5.4
shot shelf-menu-ax "The dock at the largest accessibility text size (UNSTIR_TYPESIZE=accessibility5)." \
  STORE=lens:unowned CLOCK=5.4 TYPESIZE=accessibility5 BESTS=plughole:$nine
shot card-lens-ax "Lens's card at the largest accessibility text size, its facts stacked." \
  CARD=lens STORE=lens:unowned CLOCK=5.4 TYPESIZE=accessibility5
shot card-lens-xxxl "Lens's card at xxxLarge, the largest size short of the accessibility ones: each key whole beside its fact." \
  CARD=lens STORE=lens:unowned CLOCK=5.4 TYPESIZE=xxxLarge
