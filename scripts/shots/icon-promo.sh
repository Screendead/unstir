# Copyright © 2026 Jack Lusher. All rights reserved.
# The app-icon candidates and the promoted-purchase images. Sourced in order by scripts/shots.sh.
# App-icon candidates, each a 1024-pixel square centred on the screen; scripts/icon.sh crops them and lays out the sheet.
shot icon-1 "App icon candidate 1: plughole's grid, zoomed in, under one rod's swirl, a knob at its centre." ICON=1
shot icon-2 "App icon candidate 2: maelstrom's marbling twin mid-heartbeat under one knob's swirl." ICON=2
shot icon-3 "App icon candidate 3: the sunset wound into one whole-tank swirl inside the bezel, a knob at its centre." ICON=3
# Each sold offer's promoted-purchase image, a 1024-pixel square centred on the screen; scripts/promo.sh crops them.
hold=30 shot promo-lens "Lens's promoted-purchase image: its dock cover, level 3 on the halftone as dealt, its knobs as the game draws them, inside the bezel on black." PROMO=lens
shot promo-escapement "Escapement's promoted-purchase image: its dock cover, problem 2 on its engraved plate as dealt, its ratchet, dial and knobs, inside the bezel on black." PROMO=escapement
shot promo-prism "Prism's promoted-purchase image: its dock cover, specimen 1 on the fern as dealt, its tinted knobs, inside the bezel on black." PROMO=prism
hold=12 shot promo-complete "Triptych's promoted-purchase image: a wedge of each of its three packs' covers with their knobs, inside the bezel on black." PROMO=complete
hold=4 shot promoted-menu "A purchase of Lens started on its App Store page (UNSTIR_PROMOTED), the menu up: a second in, Lens's card opens over it and buys, landing in the harness's states as owned." \
  PROMOTED=lens STORE=lens:unowned BESTS=plughole:000000000
hold=4 shot promoted-level "The same from inside plughole 05: the level gives way to the menu with Lens's card over it, owned." \
  PROMOTED=lens STORE=lens:unowned LEVEL=5
