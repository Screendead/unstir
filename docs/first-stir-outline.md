# First Stir: the story outline

Claude's outline for Jack's approval (2026-10-25). Nothing here is decided until Jack says so; his calls so far are
marked as his. It holds the story, the chapters and their palettes, the 25 scenes with their vignettes, the art spec,
and the points still open. It changes no code. The scrambles come later, solver-checked, with the art (to-do 43).

Jack's calls this outline builds on: Claude draws all 25 scenes (call 3); go (F1); time is made visible, the night
winding back, plus the caption (F2); each level opens on the wrecked, held-back picture (round 6); the heal ring is
magenta only for a heal that plays a beat, white for cancelling your own push (round 2); a vignette plays only after
the rods whose discs overlap it are healed (the lab's rule, F1).

Two words used throughout. **Held back** is a vignette's state while its tag is on the stack: the later moment, which
the level opens on. **Played** is its state once its tag has left the stack: the earlier moment. A heal winds a core
back in time. In the storm chapters "held back" is the wreckage; in Dusk Before it is only a later, quieter evening.

## 1. The story

One autumn night in a small harbour town under a lighthouse, told backwards. At dawn the town is wrecked: the
lighthouse lantern is boarded up, a fishing boat lies bailed out on the slip, the street is strewn with weed, and a child
kneels at a rock pool on the breakwater holding a green glass float that should have been on her kitchen windowsill.
Each heal winds the night back a little: the rescue undoes itself, the lifeboat backs out of the harbour, lantern-bearers
go home along the breakwater, the father wades back from the lighthouse, the flood drains out of the kitchen and the
float drifts back in at the door, the storm unbreaks the lantern and rights the boat, the washing goes back on the line,
the grandmother walks back from the lighthouse before she has lit its lamp, and the sky climbs back to sunset. The last
tank is the kitchen at golden dusk, an hour before any of it, where the child is stirring her tea; the swirl in her cup
is the night's first stir. The story never says the stir started the storm, and has no words at all: only pictures, the
night's sky and weather, and the time. After the last solve, the "night forwards" film (to-do 44) plays the whole
night in its own order, from the stir to the dawn, while the piano plays the motif forwards for the first time.

Every figure and place is invented for the pack: three people (the child, her father, her grandmother who keeps the
light), their dog, their neighbours and the town's lifeboat crew. Nobody has a name or a face.

**How the backwards telling pays off.** The player meets effects first and their causes later: the boarded lantern
(scene 1) before it smashes (16), the float in the rock pool (3) before it floats out of the door (13) and long before
it is given (24), the cup floating off the flooded table (14) before the tea is stirred in it (25). In Dawn After and the
Rescue, the earlier moment is often the worse one (the boat still swamped, the lighthouse window dark, the lifeboat still
out in the swell), so a heal there can't be read as repair, which answers the go/no-go's cold read.

## 2. Chapters and palettes

Five chapters of five scenes, in reverse story order. The time windows tile the night with no gaps: each scene's
played (earliest) moment is the next scene's held-back (latest) moment, so the sky carries on from one tank into the
next. Scene 1 opens at 6:40 am; scene 25 ends at 7:40 pm the evening before.

| Ch | Name | Scenes | Time (wound back) | Weather and light | Palette (lines on black; hex) | What says "earlier" here |
|---|---|---|---|---|---|---|
| 1 | Dawn After | 1–5 | 6:40 → 4:45 am | Calm, a low swell, the sky greying back to night | **Dawn pewter.** Sky 2B3550 → horizon F2B48C, sea 7D8FA6, line ink 9AA8C8, first light FFD9A0, the float 3FE0B0 | The sun and its glow sink below the sea; chimney smoke goes; work undoes itself |
| 2 | The Rescue | 6–10 | 4:45 → 2:30 am | Rain easing, wind still high, low cloud | **Rescue amber.** Sky 05050F, cloud 3A3550, torches FFB347, flame FFE2A0, sea 0E3A40, rain B7CEFF at 20% | Lanterns go home along the breakwater, one by one; the rain thickens |
| 3 | The Flood | 11–15 | 2:30 → 12:30 am | Steady rain, the surge over the quay | **Flood teal.** Sea 2CD5C4 over deep 0B2238, ink 8F9CFF, rain B7CEFF, the child's torch DFF6FF, drowned lamps FFA53A | The water falls back down the walls; the town clock's hands turn back |
| 4 | The Storm | 16–20 | 12:30 am → 9:30 pm | The peak: lightning, driving rain, the lighthouse beam | **Storm indigo with sodium** (the lab's): sky 000000 → 1E1960, cloud 5F59D6, ink 8F9CFF, sodium FFA53A, flame FFE2A0, lightning D9CCFF, rain B7CEFF | Lightning goes, the rain climbs back up its slant and thins, broken things mend |
| 5 | Dusk Before | 21–25 | 9:30 → 7:40 pm | Still air, one cloud bank on the horizon, then none | **Dusk rose**, ending in **kitchen gold** (scene 25): sky 03062A → 4A2C78 → C8605A, sea 2A3E6A, ink B0A6E8, windows FFC27A, sun FF8A5C; kitchen FFC94A, cream FFF1C8, tea D98B4A | The sun climbs back up from the sea; lamps unlight; the cloud bank sinks |

Dawn pewter is new; the other four are the pack entry's (storm indigo, flood teal, rescue amber, dusk rose, kitchen
gold). Within a chapter the palette is fixed and the sky's gradient moves along it with the time.

**Time inside a scene.** The sky, rain and caption are a function of the stack alone, as vignettes are: with *n* of the
scramble's *N* entries popped, the scene stands at its held-back time minus *n*/*N* of its window. A player's own push
moves no time; undo and reset move it forward again. Rain and sky may cross every disc (they are one field, so a turned
core shows its rain slanting wrong, which helps the read); anything that moves with time as a body (sun, moon, a cloud
bank) sits only where no disc reaches, as the lab's moon does.

## 3. The 25 scenes

Each vignette is written **held back → played**, in the core of the rod named. Rods: tri 0 top, 1 lower right, 2 lower
left; quad 0 top right, 1 bottom right, 2 bottom left, 3 top left; eye 0 left, 1 right (the big pair), 2 top, 3 bottom
(the small pair); pent 0 top, then clockwise 1 to 4. A rod with no vignette holds a still part of the picture, still
with up readable. Stirs are a band; the exact scramble comes with the art.

**Heal order.** "Clear" means the vignette is drawn in the part of its core that no other disc reaches, so it plays
whenever its rod is healed. "After rod k" means its drawing reaches into rod k's disc, so the scramble puts the
vignette's tagged entry below every entry of rod k and the stack forces rod k to heal first (the lab's harbour does
this: the doorway lies in the boat's shear ring, so the cottage heals after the boat). "Last" is an authored order: the
tagged entry is the scramble's bottom one.

| # | Scene (time) | Palette | What the picture shows | Layout, stirs | Vignette A | Vignette B | Vignette C | Heal order |
|---|---|---|---|---|---|---|---|---|
| **1** | **Sunrise** (6:40 → 6:15) | Dawn pewter | The lab harbour's own view at sunrise: lighthouse on the breakwater, the boat on the slip, the cottage on the quay, the sea flat and pale | tri, 4 | **Rod 0, the lantern:** boarded with planks, a gull on the rail → a neighbour on a ladder nailing up the first plank over the broken panes | **Rod 1, the boat:** bailed and upright, mast stepped, pennant flying → the father in it, bailing with a bucket | **Rod 2, the cottage:** door shut, window lit, smoke from the chimney → door open, someone sweeping water and weed out over the step | C after rod 1 (as the lab); A, B clear |
| **2** | **The Gallery** (6:15 → 5:50) | Dawn pewter | Close on the lighthouse top from the headland, the town's roofs below | quad, 4 | **Rod 3, the gallery:** a neighbour measuring the broken panes with a rule → the gallery empty, shards on the deck | **Rod 0, the rail:** three gulls back on it → bare, spray blowing over | **Rod 1, the roofs:** smoke from three chimneys → no smoke, one window lit by a candle | Clear |
| **3** | **The Rock Pool** (5:50 → 5:25) | Dawn pewter | The breakwater's rocks at low tide, pools among weed, the lighthouse door above | tri, 5 | **Rod 0, the door:** shut, a coil of rope on its hook → open, the rope trailing out across the rocks | **Rod 1, the pool:** the child kneeling, holding up the green float, whole → the float bobbing alone among the weed | **Rod 2, the dog:** sitting, tail up, by the child's boots → nose down, sniffing along to the pool | B after rod 2 (the pool's edge is in the dog's disc); A, C clear |
| **4** | **Righting the Boat** (5:25 → 5:05) | Dawn pewter | The beach beside the slip, the horizon high; townsfolk with a rope | eye, 5 | **Rod 0, the haulers:** three standing, rope slack, one waving → three leaning back, hauling | **Rod 1, the boat:** upright on the sand → keel up, dark | **Rod 2, the sky:** gulls coming back over a paling sky → the last stars, a gull asleep on a post | B after rod 0 (the bow reaches the haulers' disc); A, C clear. The rope between the cores is one line in both states |
| **5** | **Tea on the Quay** (5:05 → 4:45) | Dawn pewter | The quay at first grey light: the family on a bench in blankets, the lifeboat moored | quad, 6 | **Rod 3, the lifeboat:** moored, crew gone, lamp out → a crewman coiling rope on deck, searchlight still on | **Rod 2, the bench:** the three under one blanket, the child asleep against her father → the child awake, standing on the bench, pointing out to sea | **Rod 1, the neighbour:** three cups steaming on a crate → pouring from a flask into the first | Clear |
| **6** | **Home Light** (4:45 → 4:15) | Rescue amber | The harbour mouth from the quay at night; the cottage's upstairs window; blankets waiting | pent, 6 | **Rod 0, the harbour mouth:** the lifeboat just inside, nearly home → outside, high on a swell, searchlight out | **Rod 4, the upstairs window:** the torch left on the sill, pointing out → the child holding it out, the dog's ears at the sill | **Rod 2, the quay steps:** a neighbour holding out blankets → two neighbours carrying them out of a doorway | Clear |
| **7** | **Off the Breakwater** (4:15 → 3:50) | Rescue amber | The breakwater's end in surf, the lifeboat alongside its steps | eye, 6 | **Rod 0, the steps:** empty, a rope hanging, waves → the father helping the grandmother down, her arm over his shoulders | **Rod 1, the lifeboat:** alongside, two crew reaching up → further off, bow high on a wave | **Rod 2, the lighthouse:** dark → a glow at the stair window from the lamp she left | A after rod 1 (the steps meet the lifeboat's disc); B, C clear |
| **8** | **The Lantern Chain** (3:50 → 3:25) | Rescue amber | Townsfolk with lanterns along the breakwater path, a rope line beside them | quad, 7 | **Rod 3, the lifeboat house:** doors open, the slip empty → crew pushing the lifeboat off the slip, its lamp lit | **Rod 0, the far end:** the chain of lights reaching the lighthouse door → the chain ending halfway, one light at the door | **Rod 1, the bearers:** four lanterns held high in a row → two, and two figures running up with theirs unlit | Clear |
| **9** | **The Stair** (3:25 → 3:00) | Rescue amber | Inside the lighthouse, the spiral stair seen from below, its window, the door at the foot | tri, 7 | **Rod 0, the turn of the stair:** the hand-lamp left burning on a step → the grandmother sitting there, ankle bound with her shawl, the lamp beside her | **Rod 1, the window:** the lantern chain's lights far below → dark, rain | **Rod 2, the foot:** the storm lantern on the bottom step, the door open → the father there, lantern raised, looking up | Last: A (the stair's turn runs through both other discs) |
| **10** | **The Lighthouse Door** (3:00 → 2:30) | Rescue amber | The foot of the lighthouse on its rocks, waves breaking, the breakwater path running in | pent, 7 | **Rod 0, the gallery window:** dark → the hand-lamp in it, blinking a signal | **Rod 1, the path:** the rope tied off on an iron ring, stretched back along the path → the father on the path, the coil on his shoulder, bent into the spray | **Rod 3, the door:** open, light on the stair inside → shut, a wave breaking over the step | Clear |
| **11** | **The Breakwater Path** (2:30 → 2:05) | Flood teal | The path from the quay end, waves over it, the dark lighthouse at its end | eye, 7 | **Rod 0, the quay end:** the rope tied to its ring, running out → the father kneeling, tying it | **Rod 1, the path:** the father halfway, crouched against a wave → the path bare between waves | **Rod 2, the lantern:** the hand-lamp in the gallery window → dark (earlier is darker) | B after rod 0; A, C clear |
| **12** | **High Street Under Water** (2:05 → 1:40) | Flood teal | The high street flooded to the sills, shopfronts, a half-drowned street lamp | pent, 8 | **Rod 0, the town clock:** its hands at 2:05 → at 1:40 | **Rod 2, the street lamp:** drowned to its crossbar, dark → water at its foot, still lit, sparking | **Rod 3, the dinghy:** the father and a neighbour rowing it down the street, a coil of rope aboard → tied to a drainpipe, empty | Clear |
| **13** | **The Upstairs Window** (1:40 → 1:15) | Flood teal | The cottage from the street, water to the top of the door, the child at the window above | quad, 8 | **Rod 3, the window:** the child and the dog at it, the torch shining out → dark, a curtain blowing in | **Rod 0, the roof:** the weathervane bent, pointing down → upright, spinning | **Rod 1, the door:** open, water to the knocker, the float drifting out → water at the step, the float on the threshold | Clear |
| **14** | **The Kitchen, Flooded** (1:15 → 12:55) | Flood teal | The kitchen at night under water: the table, chairs, the stove, the stair going up | eye, 8 | **Rod 0, the table:** water over it, the teacup floating off on its saucer → water at the table's legs, the cup on the table, its spoon in it | **Rod 1, the stair:** water up four steps, the child's boots on the top one → the child on the stair, carrying the dog up | **Rod 3, the float:** drifting to the open door → caught on a chair leg | A after rod 1 (the tabletop reaches the stair's disc); B, C clear |
| **15** | **Over the Quay** (12:55 → 12:30) | Flood teal | The sea over the quay wall, bollards awash, the capsized boat at its mooring | pent, 9 | **Rod 1, the boat:** awash, the hull barely showing → keel up, high in the water | **Rod 3, the dropped lantern:** gone, its bail ring on the stones → on its side, its glass out | **Rod 4, the wall:** a wave over it, white → the sea a hand below the top, slopping | Clear |
| **16** | **The Harbour** (12:30 → 11:40) | Storm indigo | The lab's scene, redrawn only for the pack's time window: lighthouse, boat, cottage, the storm at its peak | tri, 8 | **Rod 0, the lantern:** smashed and dark, shards falling past the gallery → whole and lit | **Rod 1, the boat:** capsized, the buoy rope snapped, the oar adrift → moored upright, lamps lit | **Rod 2, the cottage:** door flung open, window dark, the lantern dropped on the quay → the father in the lit doorway, holding it up and out | C after rod 1 (the lab's) |
| **17** | **Lightning** (11:40 → 11:15) | Storm indigo | The upstairs room, its window over the bay, the lighthouse beam crossing the sky | quad, 9 | **Rod 0, the window's view:** a fork of lightning to the sea → no lightning, the beam sweeping | **Rod 3, the light:** a candle lit on the sill, the ceiling lamp dark → the lamp lit, the candle unlit | **Rod 2, the child:** in her father's arms, face hidden → kneeling on the window seat beside the dog, both looking out | Clear |
| **18** | **The Bell Buoy** (11:15 → 10:45) | Storm indigo | The bay from the headland: swell, the buoy, the breakwater, the beam, the boat's mast lamp at its mooring | pent, 9 | **Rod 0, the lighthouse:** spray reaching the gallery → the beam, no spray | **Rod 2, the bell buoy:** heeled hard over, its bell swinging → upright, bobbing | **Rod 3, the harbourmaster's hut:** a shutter torn off, hanging → the harbourmaster closing it | Clear |
| **19** | **High Street, Rain** (10:45 → 10:15) | Storm indigo | The high street in driving rain under sodium lamps, the café, a bicycle | eye, 10 | **Rod 0, the awning:** torn, flapping in strips → whole, a figure winding it in | **Rod 1, the bicycle:** blown over in the gutter, a wheel spinning → leaning on a lamp post | **Rod 2, the shop sign:** hanging by one chain → by two | Clear |
| **20** | **Washing** (10:15 → 9:30) | Storm indigo | The cottage's back yard: the washing line, the neighbour's shutters, the kennel, the gate | pent, 10 | **Rod 0, the line:** snapped, a shirt flying off over the roofs → shirts pegged, streaming hard | **Rod 1, the shutters:** shut and barred → the neighbour leaning out, pulling them to | **Rod 3, the kennel:** empty, its chain lying → the child unclipping the dog | Clear |
| **21** | **Lighting the Lamp** (9:30 → 9:00) | Dusk rose | The lighthouse at dusk from the breakwater, the town's windows, a cloud bank low on the sea | quad, 8 | **Rod 0, the lantern:** lit, the first beam out over the bay → dark, the grandmother in the lamp room with a taper | **Rod 3, the sky over the sea:** gulls flocking inland → clear, the evening star | **Rod 2, the town:** four windows lit → one | Clear |
| **22** | **The Path to the Light** (9:00 → 8:35) | Dusk rose | The breakwater path at dusk: the grandmother walking out with her storm lantern, the child on the quay | eye, 8 | **Rod 1, the grandmother:** at the lighthouse door, lantern raised → at the near end of the path, lantern swinging, shawl blowing | **Rod 0, the child:** at the quay rail, waving → running along the quay, arm up | **Rod 2, the sky:** a thin moon up beside the evening star → the afterglow alone, no moon yet | Clear |
| **23** | **Doubling the Lines** (8:35 → 8:10) | Dusk rose | The harbour at sunset: the boat, the harbourmaster's hut, the cottage window | pent, 7 | **Rod 1, the boat:** two lines out, lamps lit, nobody aboard → the father in the stern, tying the second line | **Rod 3, the barometer on the hut:** its needle on the storm glyph → on the sun glyph | **Rod 4, the cottage window:** the float hanging in it, the lamp lit → the float hanging, the lamp unlit | Clear |
| **24** | **The Float** (8:10 → 7:55) | Dusk rose | The kitchen at sunset: the window, the door with its pegs, the grandmother and the child | quad, 6 | **Rod 3, the window:** the float hanging in it, lit teal by the sunset → bare, a hook waiting | **Rod 0, the door:** the oilskin gone from its peg, the door ajar → the oilskin on its peg, boots below it | **Rod 2, the gift:** the child holding the float up to the light → the grandmother holding it out to her in both hands | Clear |
| **25** | **First Stir** (7:55 → 7:40) | Kitchen gold | The kitchen table at golden dusk from the child's seat: the cup, the teapot, the clock, the window over the sea | tri, 5 | **Rod 0, the window:** the sun touching the sea, one small curl of cloud → the sun a hand above the sea, clear | **Rod 1, the kitchen clock:** 7:55 → 7:40 | **Rod 2, the cup:** the spoon in the saucer, the tea still, steaming → the child's hand stirring, the tea's swirl | Last: C, so the stir is always the pack's last heal |

Layouts: tri 5 (1, 3, 9, 16, 25), quad 7, eye 6, pent 7. Stirs rise from 4 in the free taste (1 to 3) to 10 at the
storm's peak and ease to 5 for the teacup. 75 vignettes in all.

**Continuity**, checked scene by scene against the windows: the float (given 24, hung in the window 24 and 23, caught on a chair
leg and then adrift in the kitchen 14, over the threshold and out of the door 13, in the rock pool 3); the dog (brought in 20, at the window 17, 13 and 6, carried
upstairs 14, finds the float 3); the boat (lines doubled 23, moored lit 18 and 16, capsized 16, awash 15, righted 4,
bailed 1); the lantern (lit 21, smashed 16, the hand-lamp 11, 10 and 9, boarded 1 and 2); the lifeboat (launched 8,
alongside 7, home 6, moored 5); the grandmother (out to the light 22, lights it 21, signals 10, hurt on the stair 9,
helped down 7, on the bench 5).

## 4. The art spec

Every scene is drawn in code, as plughole's pictures and the lab's harbour are (`Pictures.swift`, `FirstStir.swift` on
`lab-firststir`), and baked per size in two states, held back and played. The picture under the stack is the held-back
image with each played core cut in from the played image.

- **Line.** One weight for every stroke: 0.0075 tank radii (about 4 px at a radius of 568 px), round caps and joins,
  with the shared `neon` glow (blurs of 0.03 and 0.008 radii). Fills are only black (silhouettes, the night behind a
  figure) and one flat lit fill per light (a flame, a lit pane). No gradients but the sky and sea.
- **Colour.** The chapter's palette and nothing else; at most six line colours in a scene. The family keep their colours
  through the night (the float always 3FE0B0 teal, lit lamps always sodium or flame) so they read across tanks.
- **No words.** No letters or numerals anywhere in a picture: clocks have hands, the barometer has glyphs, shopfronts
  have shapes.
- **Figures.** Silhouettes outlined in the line, no faces. The child (short, a bobble hat), the father (oilskin and a
  wide-brimmed rain hat), the grandmother (shawl and bun) and the dog are told apart by outline alone. A standing adult
  is at least 0.12 tank radii tall; no feature that must be read is under 0.02 (about 11 px). Draw a key object larger
  than life when it would read small, as the lab did with the lantern's storey (a fifth larger).
- **Up readable in every core**, held back and played, lit or dark: each core holds a horizon, an upright figure, a lit
  window, a hanging lamp, or the rain's slant. A turned core must look turned.
- **Each change in its own core.** Every pixel that differs between held back and played, glow included, lies inside
  its own rod's core (0.6 of the disc's radius), at least 0.02 inside the core's edge so no glow clips there (the lab
  tightened its lit lantern for this), and clear of the knob (radius 0.07 at the rod's centre, plus 0.015). Cores never
  overlap, so a beat can never show in another rod's core and light can't hint at the next move.
- **The overlap rule.** A vignette's change may reach into another rod's disc (that disc's shear ring passes through
  the core) only if the scramble makes that rod heal first: the vignette's tagged entry sits below every entry of every
  rod whose disc it reaches, and its own rod's tag sits on that rod's bottom entry. Otherwise the beat plays smeared, as
  the cottage did in the lab before its order was fixed. The share of each core that no other disc reaches:

  | Layout | Clear share of each core | Where the rest is overlapped |
  |---|---|---|
  | tri | 67% | the third nearest the tank's centre, by both neighbours |
  | quad | 91% | two slivers facing the neighbours |
  | eye, big rods | 78% | the inner edge, by the other big rod and both small ones |
  | eye, small rods | 63% | both flanks, by the big rods |
  | pent | 93% | two slivers facing the neighbours |

  On tri every pair of rods overlaps, so a tri scramble always forces an order; its vignettes are drawn clear and the
  order is used as authorship (scenes 9 and 25).
- **What may move outside the cores.** Only the time layer: the sky's gradient, the rain field (one direction over
  everything) and lightning may cross discs; a body that moves with the time (sun, moon, cloud bank) stays where no disc
  reaches. Nothing else differs between any two states of a scene.
- **Continuity between tanks.** Scene *k*'s played sky is scene *k* + 1's held-back sky, and a place drawn in two
  scenes (the harbour in 1 and 16, the kitchen in 14, 24 and 25, the breakwater path in 8, 11 and 22) is drawn from the
  same plan.
- **Checks.** The tests to-do 41 asks for become: for every scene, at any one time stage the held-back and played
  pictures differ only inside the cores, each change inside its own; and over every heal order, no vignette plays while an entry of a rod whose disc reaches
  its change is on the stack.

## 5. Open points for Jack

Each has options and one recommendation. None is built before Jack answers.

1. **The story.** A: approve it as written. B: approve with changes to named scenes. C: a different spine (for
   example no one in danger, only the town weathering the storm).
   **Recommended: A.** It keeps the pack's arc (the wrecked dawn first, the stir last), every scene has a figure the
   player follows across tanks, and its peril stays gentle: a sprained ankle, a swamped boat, a flooded kitchen.

2. **Vignettes per scene.** A: three (75 in all), the rest of the scramble plain puzzle. B: one per rod (3 to 5, 102 in
   all). C: one per scramble entry (4 to 10, about 180), as the pack entry first had it.
   **Recommended: A.** It is what the lab proved reads at phone size; each beat gets a core of its own with room to be
   drawn well; it holds Claude's art to 150 drawings (two states each) instead of about 350. C puts several beats in
   one core, where only the rod's last heal can show one.

3. **How time runs across the pack.** A: the night tiled, each scene a 15 to 50 minute slice, the sky continuous from
   tank to tank. B: every scene winds a whole night back, as the lab does in three heals. C: A, plus a clock drawn in
   every scene.
   **Recommended: A.** B repeats the same arc 25 times, so "told backwards" is lost; C spends a core on a clock in
   every scene. Under A a short slice moves the sky little, so each chapter's own cue (the second table's last column)
   carries it, with clocks only where they are part of the story (scenes 12 and 25).

4. **The caption.** No caption text exists yet on any branch. A: the time alone, under the title, stepping back with
   each of the scramble's entries healed ("6:40", then "6:34"...). B: a short line per scene in words ("the lighthouse
   goes dark"). C: none in the level; the pack card's one line only.
   **Recommended: A.** Numerals keep the story wordless and need no translation, and a clock going backwards says
   "earlier" where a still sky can't (the go/no-go's cold reader got "earlier" only from a caption).

5. **What a heal with no vignette does.** Under 2A most heals carry no tag. A: it steps the time back (caption, sky,
   rain) and flashes white. B: it flashes white and nothing else moves.
   **Recommended: A.** Every heal then visibly winds the night back, the beats stay the magenta ones (Jack's ring rule
   unchanged), and the time stays a function of the stack. The cost stays two baked images a scene: the sky,
   rain and caption are drawn live over them, as the lab already draws its rain and moon, so a 10-stir scene is not
   11 sky stages times two bakes against to-do 42's memory budget.

6. **Where light may fall.** The pack entry lets a vignette's light reach anywhere, with a test that it never reaches a
   core that can heal next. The lab keeps every difference, glow included, inside its own core. A: the lab's rule. B:
   the pack entry's.
   **Recommended: A.** Cores never overlap, so under A no beat can hint at a move, the picture is just cores cut in, the
   baking is simplest and the test is a geometry check. B buys bigger glows at the cost of a test over every heal order
   that can fail late in drawing.

7. **The lab harbour.** A: it becomes scene 16, and its dawn view scene 1. B: scene 16 only. C: both drawn new.
   **Recommended: A.** The lab's drawing is already judged at phone size, and the same view at both ends of the night
   (wrecked dawn first, the wrecking itself at the storm's peak) is the clearest way to show the player they are going
   back in time.

8. **The night forwards film.** A: the 25 scenes' baked states played in story order (scene 25 played to scene 1 held
   back), each beat crossfading in its own order, about two minutes, the motif forwards over it. B: a new drawing of
   the whole night as one continuous pan. **Recommended: A.** It needs no new art, every frame is one the player has
   earned, and its last frame is the town at sunrise, the pack's first picture.
