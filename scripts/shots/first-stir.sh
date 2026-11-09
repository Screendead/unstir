# Copyright © 2026 Jack Lusher. All rights reserved.
# First Stir: each scene held and played, and the night forwards. Sourced in order by scripts/shots.sh.
# First Stir's chapters 1, Dawn After (scenes 1 to 5, 6:40 back to 4:45 am), 2, The Rescue (6 to 10, 4:45 back to
# 2:30 am), 3, The Flood (11 to 15, 2:30 back to 12:30 am), 4, The Storm (16 to 20, 12:30 am back to 9:30 pm), and
# 5, Dusk Before (21 to 25, 9:30 back to 7:40 pm), three vignettes a scene. UNSTIR_BARE draws the picture unstirred, so the art shows as the stack has played
# it: -held as dealt, at the scene's latest time, and -played with its last heal just made, at its earliest, a wave
# past the rim keeping the card away (UNSTIR_STACK replaces the scramble, so it gives only the bottom entry, which that
# heal clears). The pack is owned, so a level past its taste opens rather than its card.
held=("Sunrise: the lantern boarded, a gull on the rail; the boat bailed, mast stepped; the cottage door shut, its window lit; the sun on the sea, smoke from the neighbour's chimney."
      "The gallery: a neighbour measuring the smashed panes with a rule; three gulls on the rail; smoke from three chimneys."
      "The rock pool: the lighthouse door shut, rope coiled on its hook; the child kneeling at the pool, holding up the float; the dog sitting."
      "Righting the boat: three townsfolk, the rope slack, one waving; the boat upright on the sand; gulls coming back."
      "Tea on the quay: the lifeboat moored, crew gone, lamp out; the three on the bench under one blanket, the child asleep; three cups steaming on a crate."
      "Home light, 4:45 under the dawn's last sky: the lifeboat just inside the harbour mouth, the torch left on the sill, a neighbour holding out blankets at the steps; light rain."
      "Off the breakwater: the steps empty, a rope hanging, surf over the lower steps; the lifeboat alongside their foot, two crew reaching up them; the lighthouse dark."
      "The lantern chain: the lifeboat house open on an empty slip; the chain of lights reaching the lighthouse door; four bearers with lanterns held high."
      "The stair: the hand-lamp burning on the stair's turn; the lantern chain's lights far below the window; the storm lantern on the bottom step by the open door."
      "The lighthouse door: the gallery window dark; the rope tied off on its ring along the path; the door open on the lit stair."
      "The breakwater path, 2:30 under the Rescue's last sky: the rope hitched to its ring on the quay end; the father halfway out, crouched into a wave; the hand-lamp in the gallery window."
      "High street under water: the town clock at 2:05; the street lamp drowned to its crossbar, dark; the father and a neighbour rowing the dinghy down the street, a coil of rope aboard."
      "The upstairs window: the child and the dog at it, the torch shining out; the weathervane bent, pointing down; the door open, the water at its knocker, the float drifting out."
      "The kitchen, flooded: the table sunk under the water, the cup floating off it on its saucer; the water up the stair, the child's boots on a step; the float drifting to the open door."
      "Over the quay: the boat capsized and awash; only the dropped lantern's bail ring on the stones; a wave breaking white over the wall."
      "The harbour, 12:30 am at the storm's peak: the lantern smashed and dark, shards falling past the gallery; the boat capsized, its rope snapped, the oar adrift; the cottage door flung open, the window dark, the lantern dropped on the quay; far lightning, driving rain."
      "Lightning: a fork of lightning to the sea in the bay window; a candle lit on the small window's sill, the ceiling lamp dark; the child in her father's arms."
      "The bell buoy: spray up the lighthouse to its gallery; the buoy heeled hard over, its bell swinging; the hut's shutter torn off and hanging."
      "High street, rain: the café's awning torn to strips; the bicycle blown over in the gutter, a wheel spinning; the cobbler's sign hanging by one chain."
      "Washing: the line snapped, a shirt flying off over the roofs; the neighbour's shutters shut and barred; the kennel's chain lying empty."
      "Lighting the lamp, 9:30 pm, night blue, a cloud bank low on the sea: the lantern lit, its first beam out; gulls flocking inland; four of the town's windows lit."
      "The path to the light: the grandmother at the lighthouse door, lantern raised; the child at the quay rail, waving; a thin moon beside the evening star."
      "Doubling the lines: the boat's two lines out, its lamps lit, nobody aboard; the barometer's needle on the storm glyph; the float in the cottage window, the lamp lit."
      "The float, the kitchen at sunset: the float hanging in the window, lit teal; the oilskin gone, the door ajar on the sunset; the child reaching up to the window, hands empty."
      "First stir, the kitchen at golden dusk: the sun touching the sea, a small cloud over it; the clock at 7:55; the tea still and steaming, the spoon in the saucer.")
played=("a neighbour on a stepladder nailing the first plank; the father bailing; a neighbour sweeping out the door; the sun under the sea, no smoke."
        "the gallery empty, shards on the deck; spray over the bare rail; no smoke, one window lit by a candle."
        "the door open, the rope trailing over the rocks; the float alone in the pool; the dog sniffing."
        "the three leaning back, hauling; the boat keel up, dark; the last stars, a gull asleep on the beacon."
        "a crewman coiling rope, the searchlight on; the child standing on the bench, pointing; a neighbour pouring from a flask."
        "the lifeboat outside on a swell, searchlight out; the child at the window with the torch and the dog; two neighbours carrying blankets out of the lifeboat house; the low cloud lit, heavier rain."
        "the father helping the grandmother down the steps; the lifeboat further off, bow high on a wave; a glow at the lighthouse's stair window; heavier rain."
        "the crew pushing the lifeboat out of the house and down the slip; the chain ending short of the lighthouse, one light at the door; two bearers, two more running up unlit; heavier rain."
        "the grandmother sitting at the turn, her ankle bound, the lamp beside her; the window dark; the father at the foot, lantern raised, looking up; heavier rain at the window and door."
        "the hand-lamp signalling from the gallery window; the father out on the path, the coil on his shoulder, bent into the spray; the door shut, a wave over its step; the night's heaviest rain."
        "the father kneeling at the ring, tying the rope; the path bare; the gallery window dark; the flood's deep blue sky, thicker rain."
        "the clock at 1:40; the water at the lamp's foot, the lamp still lit and sparking; the dinghy tied to the drainpipe, empty."
        "the window dark, a curtain blowing in; the weathervane upright, spinning; the water down at the step, the float on the threshold."
        "the table standing clear, the water at its legs, the cup on it with its spoon; the child carrying the dog up the stair; the float caught on the chair's leg."
        "the boat keel up, high in the water; the lantern on its side, its glass out; the sea a hand below the wall's top, slopping; the sky leaning to the storm's indigo, the rain at its thickest."
        "the lantern whole and lit; the boat moored upright, its lamps lit; the father in the lit doorway holding the lantern up and out; 11:40 pm, the lightning fading, the rain thinner."
        "the lighthouse beam sweeping in, no lightning; the ceiling lamp lit, the candle out; the child kneeling on the window seat beside the dog, both looking out."
        "the lighthouse beam out, no spray; the buoy upright; the harbourmaster pulling the shutter to."
        "the awning whole, the café's owner winding it in; the bicycle leaning on the lamp post; the sign hanging by two chains."
        "shirts pegged on the line, streaming hard; the neighbour leaning out to pull the shutters to; the child unclipping the dog; 9:30 pm, the sky at dusk's night blue, the rain gone."
        "the lantern dark, the grandmother reaching a taper to the lamp; the evening star; one window lit; the cloud bank sunk, the afterglow rising."
        "the grandmother just out on the path, lantern swinging, shawl blowing; the child running along the quay, arm up; the afterglow alone."
        "the father in the stern tying the second line; the needle on the sun glyph; the window dark, the float still hanging."
        "the hook bare; the oilskin and hat on their pegs, boots below, the door shut; the grandmother holding the float out to the child."
        "the sun a hand above the sea, clear; the clock at 7:40; the child's hand stirring, the tea's swirl.")
bottom=(2:+5 3:+4 1:+4 0:+3 2:+4 1:+3 0:+4 3:+4 0:+4 3:-4 1:+4 0:+3 1:-4 0:+4 4:-3 2:+5 3:+4 0:+4 0:+4 3:+4 3:+4 0:+3 4:+3 0:+4 2:+4)
for n in $(seq 1 25); do
  last=${bottom[$((n - 1))]} name=firststir-$(printf %02d "$n")
  fs="PACK=first-stir LEVEL=$n OWNED=first-stir"
  shot "$name" "First Stir $n as dealt: every core turned, the time under the tank." $fs
  shot "$name-held" "First Stir $n drawn unstirred, held back. ${held[$((n - 1))]}" $fs BARE=1
  shot "$name-played" "First Stir $n drawn unstirred, every vignette played: ${played[$((n - 1))]}" $fs BARE=1 STACK="$last" TURNED="${last%%:*}:$((-${last#*:}))" WAVE=2
done
# Sunrise (2:+5,1:-4,0:+3,1:+2) part healed: the first heal plays nothing and steps the clock back; the second plays the
# lantern.
fs="PACK=first-stir LEVEL=1"
shot firststir-01-healed-1 "First Stir 01 after the first heal (1:-2): no vignette, the clock at 6:34 am." $fs TURNED=1:-2
hold=9 shot firststir-01-healed-2 "First Stir 01 after the second heal (0:-3): the neighbour nailing the first plank in a still core, the clock at 6:28 am." \
  $fs MOVES=1:-2,0:-3
# The night forwards (UNSTIR_ENDING), after First Stir 25's solve: every scene in story order, 6.4 s each with a 0.6 s
# crossfade, held at moments through it.
fs="PACK=first-stir LEVEL=25 OWNED=first-stir SCREEN=clean"
shot firststir-ending-02 "The night forwards 1 s in: scene 25 played, the tea stirring at 7:40 pm, the time under the glass." $fs ENDING=1.1
shot firststir-ending-05 "The night forwards 7 s in: scene 25 at its end, the tea still, crossfading to scene 24 at 7:55 pm." $fs ENDING=7.1
shot firststir-ending-60 "The night forwards 83 s in: the Flood's upstairs window, 1:39 am, the water rising." $fs ENDING=83.4
shot firststir-ending-end "The night forwards' last frame: scene 1 held back, the town at sunrise as the pack opened, 6:40 am." $fs ENDING=162
