# Copyright © 2026 Jack Lusher. All rights reserved.
# Piece D, the packs on the slope (docs/slope.md, 8; SlopePackHarness): the hollows in plughole's wall, a hollow's
# inside in every store state, and a pack's own slope. Sourced in order by scripts/shots.sh.
shot slope-hollows "The dive with the packs' hollows in plughole's wall: SLOPEAT=L14 STORE=lens:unowned BESTS=plughole:0000000000000." \
  SLOPE=hollows SLOPEAT=L14 STORE=lens:unowned CLOCK=3 BESTS=plughole:0000000000000
shot slope-hollows-states "The dive with the packs' hollows in plughole's wall: SLOPEAT=L9 OWNED=lens STORE=escapement:pending BESTS=plughole:000000000000000000000000000,prism:00." \
  SLOPE=hollows SLOPEAT=L9 OWNED=lens STORE=escapement:pending CLOCK=3 BESTS=plughole:000000000000000000000000000,prism:00
shot slope-hollows-new "The dive with the packs' hollows in plughole's wall: SLOPEAT=L18 STORE=lens:unowned BESTS=plughole:000000000000000000000000000,prism:00." \
  SLOPE=hollows SLOPEAT=L18 STORE=lens:unowned CLOCK=3 BESTS=plughole:000000000000000000000000000,prism:00
shot slope-hollows-ax3 "The dive with the packs' hollows in plughole's wall: SLOPEAT=L11 STORE=lens:unowned BESTS=plughole:000000000000000000000000000 TYPESIZE=accessibility3." \
  SLOPE=hollows SLOPEAT=L11 STORE=lens:unowned CLOCK=3 BESTS=plughole:000000000000000000000000000 TYPESIZE=accessibility3
shot slope-inside-prism "A pack's hollow opened: its inside: CARD=prism STORE=lens:unowned." \
  SLOPE=inside CARD=prism STORE=lens:unowned CLOCK=5.4
shot slope-inside-lens "A pack's hollow opened: its inside: CARD=lens STORE=lens:unowned." \
  SLOPE=inside CARD=lens STORE=lens:unowned CLOCK=5.4
shot slope-inside-escapement "A pack's hollow opened: its inside: CARD=escapement STORE=lens:unowned." \
  SLOPE=inside CARD=escapement STORE=lens:unowned CLOCK=5.4
shot slope-inside-complete "A pack's hollow opened: its inside: CARD=complete STORE=lens:unowned BESTS=lens:00c,prism:0." \
  SLOPE=inside CARD=complete STORE=lens:unowned CLOCK=1 BESTS=lens:00c,prism:0
shot slope-inside-unread "A pack's hollow opened: its inside: CARD=prism STORE=lens:unowned,unread." \
  SLOPE=inside CARD=prism STORE=lens:unowned,unread CLOCK=5.4
shot slope-inside-loading "A pack's hollow opened: its inside: CARD=prism STORE=lens:unowned PRICES=0." \
  SLOPE=inside CARD=prism STORE=lens:unowned PRICES=0 CLOCK=5.4
shot slope-inside-unreachable "A pack's hollow opened: its inside: CARD=prism STORE=lens:unowned PRICES=unreachable." \
  SLOPE=inside CARD=prism STORE=lens:unowned PRICES=unreachable CLOCK=5.4
shot slope-inside-pending "A pack's hollow opened: its inside: CARD=prism STORE=prism:pending." \
  SLOPE=inside CARD=prism STORE=prism:pending CLOCK=5.4
shot slope-inside-pending-offline "A pack's hollow opened: its inside: CARD=prism STORE=prism:pending FAILED=offline." \
  SLOPE=inside CARD=prism STORE=prism:pending FAILED=offline CLOCK=5.4
shot slope-inside-pending-escapement "A pack's hollow opened: its inside: CARD=escapement STORE=escapement:pending." \
  SLOPE=inside CARD=escapement STORE=escapement:pending CLOCK=5.4
shot slope-inside-failed "A pack's hollow opened: its inside: CARD=prism STORE=prism:failed FAILED=offline." \
  SLOPE=inside CARD=prism STORE=prism:failed FAILED=offline CLOCK=5.4
shot slope-inside-storefront "A pack's hollow opened: its inside: CARD=prism STORE=prism:failed FAILED=storefront." \
  SLOPE=inside CARD=prism STORE=prism:failed FAILED=storefront CLOCK=5.4
shot slope-inside-nopay "A pack's hollow opened: its inside: CARD=prism STORE=lens:unowned PAYMENTS=0." \
  SLOPE=inside CARD=prism STORE=lens:unowned PAYMENTS=0 CLOCK=5.4
shot slope-inside-revoked "A pack's hollow opened: its inside: CARD=lens STORE=lens:revoked." \
  SLOPE=inside CARD=lens STORE=lens:revoked CLOCK=5.4
shot slope-inside-unshared "A pack's hollow opened: its inside: CARD=lens STORE=lens:unshared." \
  SLOPE=inside CARD=lens STORE=lens:unshared CLOCK=5.4
shot slope-inside-owned "A pack's hollow opened: its inside: CARD=prism OWNED=prism BESTS=prism:0c01." \
  SLOPE=inside CARD=prism OWNED=prism CLOCK=5.4 BESTS=prism:0c01
shot slope-inside-owned-lens "A pack's hollow opened: its inside: CARD=lens OWNED=lens BESTS=lens:0c0010c." \
  SLOPE=inside CARD=lens OWNED=lens CLOCK=5.4 BESTS=lens:0c0010c
shot slope-inside-owned-escapement "A pack's hollow opened: its inside: CARD=escapement OWNED=escapement BESTS=escapement:0002." \
  SLOPE=inside CARD=escapement OWNED=escapement CLOCK=5.4 BESTS=escapement:0002
shot slope-inside-complete-owned "A pack's hollow opened: its inside: CARD=complete OWNED=complete BESTS=lens:0000." \
  SLOPE=inside CARD=complete OWNED=complete CLOCK=1 BESTS=lens:0000
shot slope-inside-bundle-waiting "A pack's hollow opened: its inside: CARD=lens STORE=complete:pending." \
  SLOPE=inside CARD=lens STORE=complete:pending CLOCK=5.4
shot slope-inside-bundle-failed "A pack's hollow opened: its inside: CARD=lens STORE=complete:failed FAILED=offline." \
  SLOPE=inside CARD=lens STORE=complete:failed FAILED=offline CLOCK=5.4
shot slope-inside-arrived "A pack's hollow opened: its inside: CARD=prism STORE=lens:unowned ARRIVED=1 BESTS=prism:000." \
  SLOPE=inside CARD=prism STORE=lens:unowned ARRIVED=1 BESTS=prism:000 CLOCK=5.4
shot slope-inside-restored-none "A pack's hollow opened: its inside: CARD=prism STORE=lens:unowned RESTORED=none." \
  SLOPE=inside CARD=prism STORE=lens:unowned RESTORED=none CLOCK=5.4
shot slope-inside-ax3 "A pack's hollow opened: its inside: CARD=prism STORE=lens:unowned TYPESIZE=accessibility3." \
  SLOPE=inside CARD=prism STORE=lens:unowned CLOCK=5.4 TYPESIZE=accessibility3
shot slope-inside-ax3-buy "A pack's hollow opened: its inside: CARD=prism STORE=prism:pending TYPESIZE=accessibility3 ARRIVED=1 BESTS=prism:000." \
  SLOPE=inside CARD=prism STORE=prism:pending CLOCK=5.4 TYPESIZE=accessibility3 ARRIVED=1 BESTS=prism:000
shot slope-inside-xxxl "A pack's hollow opened: its inside: CARD=escapement STORE=lens:unowned TYPESIZE=xxxLarge." \
  SLOPE=inside CARD=escapement STORE=lens:unowned CLOCK=5.4 TYPESIZE=xxxLarge
shot slope-pack-prism "A pack's own slope under its floor: CARD=prism STORE=lens:unowned CARDSCROLL=1 BESTS=prism:0c." \
  SLOPE=inside CARD=prism STORE=lens:unowned CLOCK=3 CARDSCROLL=1 BESTS=prism:0c
hold=5 shot slope-pack-escapement "A pack's own slope under its floor: CARD=escapement STORE=lens:unowned SLOPEFOCUS=escapement-3 BESTS=escapement:02 TRIED=escapement-3." \
  SLOPE=inside CARD=escapement STORE=lens:unowned CLOCK=3 SLOPEFOCUS=escapement-3 BESTS=escapement:02 TRIED=escapement-3
hold=6 shot slope-pack-lens-owned "A pack's own slope under its floor: CARD=lens OWNED=lens SLOPEFOCUS=lens-20 BESTS=lens:0c0010c00000102000." \
  SLOPE=inside CARD=lens OWNED=lens CLOCK=3 SLOPEFOCUS=lens-20 BESTS=lens:0c0010c00000102000
shot slope-pack-prism-ax3 "A pack's own slope under its floor: CARD=prism STORE=lens:unowned CARDSCROLL=1 BESTS=prism:0c TYPESIZE=accessibility3." \
  SLOPE=inside CARD=prism STORE=lens:unowned CLOCK=3 CARDSCROLL=1 BESTS=prism:0c TYPESIZE=accessibility3
shot slope-hollows-ax5 "The dive with the packs' hollows in plughole's wall: SLOPEAT=L11 OWNED=lens STORE=escapement:pending BESTS=plughole:000000000000000000000000000,prism:00 TYPESIZE=accessibility5." \
  SLOPE=hollows SLOPEAT=L11 OWNED=lens STORE=escapement:pending CLOCK=3 BESTS=plughole:000000000000000000000000000,prism:00 TYPESIZE=accessibility5
shot slope-hollows-ax5-lens "The dive with the packs' hollows in plughole's wall: SLOPEAT=L6 OWNED=lens STORE=escapement:pending BESTS=plughole:000000000000000000000000000,prism:00 TYPESIZE=accessibility5." \
  SLOPE=hollows SLOPEAT=L6 OWNED=lens STORE=escapement:pending CLOCK=3 BESTS=plughole:000000000000000000000000000,prism:00 TYPESIZE=accessibility5
shot slope-inside-375 "A pack's hollow opened: its inside: CARD=prism STORE=lens:unowned FRAME=375x667." \
  SLOPE=inside CARD=prism STORE=lens:unowned CLOCK=5.4 FRAME=375x667
shot slope-inside-375-escapement "A pack's hollow opened: its inside: CARD=escapement STORE=escapement:pending FRAME=375x667." \
  SLOPE=inside CARD=escapement STORE=escapement:pending CLOCK=5.4 FRAME=375x667
shot slope-pack-375 "A pack's own slope under its floor: CARD=lens STORE=lens:unowned CARDSCROLL=1 FRAME=375x667." \
  SLOPE=inside CARD=lens STORE=lens:unowned CLOCK=3 CARDSCROLL=1 FRAME=375x667
