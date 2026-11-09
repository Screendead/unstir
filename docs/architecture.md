# Architecture

How each part of the code works, moved out of `CLAUDE.md` so it loads only when needed. Read the entry for a file before changing it.

- **Twist.swift** holds the core model and has no UI. A scramble is a stack of `Twist(rod, steps)` entries (30° per
  step), applied bottom first. `Tank.twist`/`Tank.profile` is the point map: a rigid disc core out to `plateau` (0.6),
  then a smoothstep shear ring; the swirl's (`swirlPlateau`, 0, picked by its radius of 1) has no core and shears from
  its edge, turned whole, to its still centre. `Array.commit` is the one rule for every rod stir. A turn merges into the rod's
  newest entry when everything above that entry commutes with the turn, and pushes a new entry otherwise. It runs on any
  `Stacked` entries, so what rides with an entry (`Game.Entry`'s mark of the player's push, and its tags, First Stir's
  vignettes) stays with it: the entry a turn lands on keeps its own and takes in what rode with the turn through
  `Stacked.absorb`, called on every merge, a fall's too, before a pop. `Game.Entry`'s unions the tags and leaves the mark
  the landing entry's, so endless's brim is as it was before the hook (`testTheMergeHookLeavesTheBrimAsItWas`). It
  hands `popped` every entry that merges to nothing, with all it absorbed, including one that an entry the merge lets
  fall cancels. Commutation is decided geometrically (non-overlapping discs), or by sampling the maps on
  `Tank.samples` when the discs overlap. An entry that merges to 0 steps pops. `Layout.looksSolved` checks the stack
  against the identity to half a pixel. The stack names the glass's own rods (slots), so a turn of the tank never
  touches it: `Layout.order`/`tankStep` are the layout's rotational symmetry (hex's hub held still), which sets each
  rod's twist exactly on a rod of the same size, and `slot(of:at:)`/`knob(over:at:)` map a physical knob to the slot
  under it at a tank position. Each layout has a swirl variant (`Layout.swirls`, `quadSwirl` and so on, for vortex):
  its base's rods, then one more (`Layout.swirl`) of radius 1 at the centre, its profile turned inside out (Jack,
  2026-10-26): the fluid sticks to the rim the finger turns, so the glass's edge goes round whole and the swirl lets go
  towards its centre, which stays put (`testASwirlTurnsTheGlassEdgeWhole`). The shader takes any disc of radius 1 or
  more for the swirl, so the menu's `Stirred` keeps its disc just under 1. It stacks and merges like any rod, decided by sampling as it overlaps every rod, and every
  turn of the tank leaves it on itself. On hex it commutes exactly with the hub, which shares its centre. It has no
  rigid core (`Tank.swirlPlateau`), so it shears through every other rod's and the core-clearance rule exempts it. `Layout.allCases` leaves the swirls out, so the
  frozen generator never deals one and the sandbox never cycles to one. A rod may instead be a lens (Lens's pack,
  `Level.lenses`, by slot): `Tank.lens` moves only its rigid core, on the flow of u (1 - (u / 0.6)^2) (`lensEdge`, 2),
  which magnifies the centre by 2 a step (`lensRate`, Jack's from the phone, 2026-10-26) for positive steps and fixes the core's rim, so the picture
  draws a crisp circle there and nothing outside it moves. Steps sum and cancel, so a lens's entries merge and pop
  through the same `Array.commit`, and a lens never wraps: +k needs exactly -k. Every call that maps points
  (`same`, `commutes`, `looksSolved`, `removable`, `landing`, `commit`, `parse`) takes the lens set,
  empty by default; a call that drops it treats a lens as a twist, which `testTheLensSetChangesHowAStackMerges` catches
  where it matters. Ported from the hard lens on local branch `lab-lens` (Jack's call, round 3, L1). A rod may also
  carry a channel mask (Prism's pack, `Level.masks`, by slot, `Channels`: red, green, blue, cyan, magenta, yellow or
  white): a stir moves only its channels, so each of red, green and blue is the word of the entries whose rod holds it.
  The same calls take the mask set after the lens set, empty by default, meaning every rod white, which is today's
  path untouched. `same` compares each channel's cut words (an all-white word costs one pass), so two entries commute
  when their discs miss, when their masks share no channel (`commutes`' early exit), or when their maps commute on
  every channel they share, and `looksSolved` is every channel back. `Channels.masks` reads `0:r,1:c`.
- **Unstir.metal** is the GPU copy of the same map. Each stitchable's body is a template over its layer (`unstirBody`,
  `unstirChannelsBody`), so the GPU bench's kernel runs the same code on a texture. It turns the sample point back by the glass's `turn`, then applies
  the stack's inverses to sample the picture. A lens's entry carries a negative radius and its flow's time
  (`steps * Tank.lensRate`) for the angle, and the rim's sharpness comes in as a uniform. The tests reach the Swift copy
  (`Tank.profile`/`Tank.twist`/`Tank.lens`) and only the shader's `lensFlow`, compiled on its own
  (`testLensShaderMatchesSwift`, 12 steps either way), so change the two together. The turn has no Swift copy: only the `seized-*` shots pin its sign against `Layout.behind`.
  The shader's tap count and the `Tank.maxStack` (36) and `Tank.fourTaps` (40) limits are tuned against 120 Hz on an
  iPhone 13 Pro Max's glass, about 1137 px (`Tank.tunedPixels`): on 2026-11-04 the most the game allows, a full stack of 36
  on a fill of 4 with the drag riding over, held 120 Hz there at four taps, checked from the screen's side, and no
  load the game reaches missed, so 40 is a held point, not the edge (Jack's call taps-keep = C). The level's glass draws the budget `Taps` learns on the phone (`Unstirred.budget`, below); every other
  draw, and every glass under the harness, the test host or the simulator, takes the four-tap limit for its glass's size (`Tank.fourTaps(pixels:)`, less the fill, `Unstirred.taps`): 40 on every glass
  up to 1300 px, so every iPhone and every pose drawn before the upright Duo's keeps one limit, and past that the
  phones' 40 and the entry in flight (`Tank.scaledFrom`, 41) scaled down by the area, less the one in flight, so the
  open Duo upright's 1471 px starts at 23 (Jack's call r16c-duoprior = B, round 16, which rescaled duocap2 = D's 17,
  scaled from the 31 measured before 2026-11-04); `Tank.maxStack` stays 36 at every size, so every level plays as on an iPhone, its stacks as deep, while the
  four-tap limit shrinks to 23 on the Duo upright, where every stack whose work is past 23 draws two taps (Jack's
  call r16c-duoprior = B). On a phone every level is dealt within 40 (whirlpool 27, the deepest on a live picture, has 28
  stirs on the glass's fill of 4, 32), so every stack dealt draws four taps there (Jack's calls taps-keep = C and
  wp27-table = B). The accepted risk: a deep stack on a live picture there may run up to 32% over the
  frame budget measured (a paper estimate; the Duo's GPU is unmeasured until stage 6's bench). The GPU bench keeps
  the constant, so its 24 entries time four taps. A live picture's own cost comes off the
  four-tap limit as `Picture.fillEntries`, scaled from Mac GPU costs and unconfirmed on the phone. Prism's stacks
  go to a second stitchable, `unstirChannels`, only when some entry's mask isn't white (`Unstirred.masks`), so every
  other level draws through `unstir` as measured: it carries red, green and blue each through the inverses of the
  entries whose mask (a float per entry, the `Channels` raw value) holds it, and samples each channel at its own point.
  Both share the per-entry map (`unmap`); `testTheShadersChannelChainsMatchTheModel` compiles the per-channel loop
  (`chains`) and checks it against the model's cut words on hex's swirl. Its cost against the four-tap limit
  (`Unstirred.channelCost`) is a map per channel each entry holds, plus two for a tap's extra samples: assumed, not
  benched on the phone, so a 12-entry stack of mixed masks may already run two taps.
- **TapLaw.swift** and **Taps.swift** hold the adaptive four-tap budget (Jack, round 16: step the graphics down where
  performance degrades, to keep 120 Hz). Only the look adapts: `Tank.maxStack`, what a level deals and "the tank is
  full" are the same everywhere, and `Tank.fourTaps` stays the rule the tables are dealt to. The budget B is in
  committed work, `Tank.fourTaps`' unit: a frame draws four taps where its work (`Unstirred.committedWork`: Prism's
  channel cost or the entry count, plus the fill, what is in flight riding over as it always has, `Unstirred.weigh`)
  is at most B, and two otherwise, as the shader can't split one chain. `Taps` learns B per glass (`TapKey`: the
  screen's top rate and the glass's side to 16 px) and drives only the level's glass, `LevelView.tank()`'s
  `Unstirred`; the dock's covers, the cards' clips, the icon, the menu's stir and the GPU bench keep their static
  limits. It runs where the build's `ADAPTIVE_TAPS` (`Config/Unstir.xcconfig`, YES: Jack's call taps-keep = C, the
  static 40 as the start and the law for heat and the Duo) sets Info.plist's `AdaptiveTaps`, read as `Taps.built`,
  or under `UNSTIR_TAPS`; otherwise every glass draws its static limit. So a phone draws full quality from launch,
  and the law steps down only where a phone really drops frames. `FrameWatch`, a display link alive only while a finger (or `UNSTIR_TAPDRAG`) turns a rod or the rim
  (`LevelView.tapWindow`: no opening, settle, card, slide or breath's fade), times each interval against the period
  the system grants and reads the main thread's CPU time in it (`TapLaw.classify`): late past 1.5 periods, the GPU's
  (`gpuMiss`) where the main thread was idle for at least half of it, the main thread's own where it was busy for all but
  half a period, and neither past 6 periods (a stall no frame of the shader's makes) or where the finger moved
  nothing. A live picture at rest isn't measured: whether a 60 Hz link moves a ProMotion panel is unchecked. `TapLaw`
  steps B down to the missed work less one after 4 late frames among a drag's last 30 counted four-tap frames within 4
  of B (`TapCuts.unattributed`'s `near`), once a drag, and only where that draws the missed work with two taps, so
  never from work at or under `floor` (12 on every device, Jack's call TAPS-FLOOR = A); misses further below step
  nothing, hot or cool (its `far` is unbounded; the attributed cuts would let 6 of them step while hot). It
  climbs one after 600 clean four-tap frames at its edge, never past `ceiling` (`Tank.maxStack` plus the largest fill,
  42, Jack's call TAPS-CEIL = A) nor to a cap. A first miss caps provisionally, probed once a launch after 1200 clean, confirmed
  by a second miss there or erased by 600 clean at it; a cap is always over the cool budget bar a probe's, and a
  stored one that isn't is dropped. Each step waits on its effect check: two-tap frames at its work or under it, or up
  to 4 over, that still miss 4 in 30 take back the oldest step they cover and every step since, and pause the steps
  down for the launch; 120 on time there confirm it. A thermal state of serious draws a quarter off the cool budget
  while it lasts (40 to 30; critical, the floor), never kept, and gives it back once the state drops below serious, as `Power` still halves a live picture's rate. The numbers are `TapCuts`', and `Taps.cuts` is `TapCuts.unattributed`: on the 13
  Pro Max a main-thread stall's late frames read gpu nearly as often as cpu (7 of 15), so every late frame counts,
  near the edge only, with the effect check behind it; the display link does see the render server's misses (a
  presentation probe, 2026-11-04). On that phone no load the game reaches misses, so the step down has never run
  there, and heat past fair is unchecked. A new B is drawn
  only at a still moment (`TapLaw.still`, from `TapHooks`: a move landing, the level appearing, a change of pose,
  and the end of a drag on a glass that had none yet, as one a change of pose brings mid-drag),
  never during a measured drag, and `Unstirred.budget` is a plain field outside `animatableData`: the glass draws what
  its last still moment chose, keyed by its side alone, and the screen's rate (the highest read this launch, so Low
  Power Mode's cap never keys a glass) is read again only as a drag opens and at a still moment. Frames say nothing
  under Low Power Mode or screen capture, at a granted rate below the screen's top one, or for a second after a change
  of pose. A plain launch on a phone keeps each glass's cool decision in `UserDefaults` (`taps.<hz>.<px>`, never synced,
  written only once its cool decision, cap or strikes move from what it was made with, so heat, drawn while it lasts,
  is never kept; no key holds glasses either side of `Tank.fourTapsKept`), so a launch killed before the next still
  moment keeps a step with its cap, dropped by a new build (its number and its executable's timestamp, as the
  halftone's cache) or OS. A glass with nothing kept starts at its key's static limit (`TapKey.limit`, the lowest
  `Tank.fourTaps(pixels:)` of the glasses a key holds, so none starts above its own), whatever any other glass has kept (Jack's call taps-keep = C: the fixed limit is the start), so no glass's start reads another's. Each decision goes to the flight recorder
  (`taps prior`; `taps drag` for every drag under `watch` or `adapt` without keeping, else one with a late or frozen
  frame or a decision; `taps down`, `up`, `probe`, `cap … erased`, `applied`, `reverted`, `held`, `two-tap misses`,
  `hot`, `cool`; and an `UNSTIR_TAPS` it can't read, which draws the static limit), never from the link's callback. The harness, the test host and the simulator draw the static limit and
  measure nothing, so no shot or test depends on timing, unless `UNSTIR_TAPS` (below; `scripts/taps-check.sh` runs
  the phone's checks).
- **Glass.metal**, **Chainmail.metal**, **Coral.metal**, **Neurons.metal** and **Marbling.metal** draw whirlpool's live
  pictures, one family per file: a stitchable named after each `Picture` case (`glass`, `glassTwin`, ...), maelstrom's
  twin being the same body with `twin` set. Each file stands alone. The twins' heartbeat lives in their own lines: each
  file's `heartbeat` reads the delay grid `Picture.delays` appended to the twin's data, and the lines swell and brighten
  as the beat passes, so it is stirred with the picture. A swollen line must keep inside its design's limits (neurons'
  regions, chainmail's early-out). `testNeuronsStayInTheirRegions` compiles Neurons.metal itself and checks its search
  against a brute force, the twin at the beat's peak; nothing else tests the shaders.
- **Brim.swift** and **Brim.metal** draw endless's brim as a measuring jug on the tank's own bezel, ported from the
  mockup Jack approved (2026-09-28) with its constants in its own units (`Brim.unit` to the glass's radius): ticks
  engraved on the steel, a brim pin at twelve, and a liquid in the picture's own colours climbing both sides from six
  o'clock to a level line with a glinting meniscus, the empty arc bare steel. `Game.brimEvents` records every change of
  the brim, and `Brim.frame` turns them into the shader's state: a change springs in and sloshes, a new notch's colour
  spreads outward across the bezel behind a glint and surges on onto the black (the last two notches each on their own
  clock, so a quick push never cuts the one before short), the filled arc blooms further as room runs out and pulses
  with the pin at the last notch, and a heal leaves a wet film. The glow is scaled (`BLOOM`) to the approved film's
  balance of bloom to band, fades out before `Brim.reach`, where the ring ends, and none of it lies on the empty jug.
  `BrimRing` strokes a ring from the glass's edge outward with the `brim` shader, so it shades no pixel of the glass
  and the tank's shader is untouched; its timeline runs only for `Brim.settle` after a change, through a spill and
  while the last notch is held, and it strikes with the picture (`PictureLayer.strike`). Its colours (`Brim.colours`)
  map points just inside the rim back through the glass's turn and the stack, as `unstir` does, and read the grid,
  endless's only picture (`Picture.gridLight`), off the main actor on each change of the stack; a spill changes no
  stack, so the rim keeps its colours. The push that fills the brim spills it: the fronts meet at the pin
  (`Brim.meet`), a crest swells over the lip at twelve and breaks, the liquid pours down the outside of the rim either
  way in a wave behind a bead at each head, dressed as the mockup's sheet, and the heads slow past three and nine
  o'clock, where two drops fall from each; the pin is drawn over all of it. The `murk` layer effect (disabled until
  then) stirs the picture together on `Brim.murk`'s stirs, carrying each pixel's footprint back through them (each
  stir is area-preserving, so it becomes a thin sliver) and averaging up to 48 taps along it in linear light, so
  lines finer than a pixel mix instead of glittering. `SpillWords` stamps "spilled." over the tank, whose caps stay,
  and the card follows at `Brim.card`, or at once under Reduce Motion (Jack's call R-spill, round 15). The tests reach only the Swift side.
- **Levels.swift** holds `Tier`, the difficulty ladder: plughole, whirlpool, vortex, maelstrom (charybdis will go past
  maelstrom). Declaration order is the ladder, and the raw value is stored as the menu's tier, so it
  never changes. Plughole is always open; any other tier opens when every level of the tier just below has a best at par
  (`Tier.isOpen`: `over == 0`). `Tier.store` keeps only an open tier, so a locked one opened to look at
  never comes back on launch, and `Tier.stored` falls back to the highest open tier below one that has closed.
  `Best.unlocked`, the developer unlock, opens every tier and level; a launch with `UNSTIR_UNLOCK=1` sets it and one
  with `UNSTIR_UNLOCK=0` clears it. Each `Level` carries its tier, and its id is the tier's `prefix` and its number
  (`L1`, `N1`, `V1`, `M1`: whirlpool's prefix is from its old name, nightmare; maelstrom's moved off nightmare+'s `N+` when
  its own set replaced those levels, so no old best lands on a new one). Progress is stored by id, so changing a prefix
  loses it unless the stored keys are remapped. Plughole has 27 levels, 1–18
  hand-written and 19–27 dealt by the frozen generator and picked for a gentler curve (`scripts/plughole-levels.sh`),
  all scramble strings like `"2:+3,0:-5"` fed through `parse`, so they merge exactly as play would; whirlpool
  deeper variants on live pictures that follow a table, vortex 27 provisional swirl levels (quad, tri, eye, pent,
  then hex) on its own family, nine levels each: no two neighbours alike, V1–V3 one of each, isobars opening each
  layout and taking the finale, the ephemeris only to 14 stirs (`testVortexTable`), no knob seized, so the tank never turns and par is the entry count, which the
  solver's optimum matches and plain untwisting reaches (`testVortexParIsTheOptimum`, slow), and maelstrom 27 of its
  own (quad, then pent, then hex) on the twins, each with one or two seized knobs, never the hub, and a `fixedPar` that counts the tank's turns: the
  solver's optimum, which the park rule reaches however its ties go (`testMaelstromIsFairAtPar`). Past quad, the park
  rule never goes more than a third of par, plus one, without a turn (`testMaelstromKeepsTheTankTurning`), so the
  seized knobs stay in the way. Daily and endless come from a `SplitMix64`-seeded generator, and count as plughole. The generator is ported draw for draw from an earlier
  prototype and is frozen: every past daily is its output, and `testDailyVectors` pins them. A daily's id and seed are
  its day's yyyymmdd (`Level.dailyID`), and `Daily.run` counts, once today's has a best, the days in a row ending today
  that have one: a practice try saves none, so only first tries count (Jack's call C18, round 13), and a best the archive
  saved (`Best.archived`) never counts. Endless changes only what
  it asks for (`Level.endless`: tank n has 5 + 5n/4 stirs up to 28, at least n/2 of them hidden, to half), which
  `testEndlessVectors` pins. A `Run` is endless's seed, tank and the brim's notches as that tank opens. Progress
  (`Best`, started flags, undo bank, and each unfinished level's resume) is kept in `UserDefaults`. The undo bank (`Best.undos`, 10 at most) refills by 2
  the first time a level other than the sandbox or endless opens on a local calendar day later than the stored day of
  its last refill (`Best.refill`, `Best.refilled`), so each day played refills once and a long absence once; a fresh
  install records the day without a refill, and a clock moved back never refills. The day is `Best.trustedNow`'s, in the
  current time zone: it stores an anchor (`Best.anchor`), the last time it vouched for with the uptime then
  (`CLOCK_MONOTONIC_RAW`, which counts sleep and which setting the clock never moves) and the boot session
  (`kern.bootsessionuuid`, nil where the sandbox refuses it); the sandbox and endless leave it alone. Within a boot, a
  wall clock more than `slack` (5 min) ahead of the anchor plus the uptime since gives way to that reckoning, and the
  anchor stays; otherwise the wall clock is believed, and the anchor follows it from as far as `slack` behind, but never
  further past the reckoning than a second plus `drift` (100 ppm) of the uptime since, so creeping the clock ahead gains
  about a second an opening. A new boot believes the wall clock, and anchors there unless it reads more than `slack`
  before the anchor's time, so a clock reset at boot and set right later still counts as a new boot. With the session
  unread, a new boot shows as the uptime going back, or as a jump at least the anchor's uptime, which is believed. The
  launch logs whether the session was read, never the uptime: the log can leave the phone, and a line's time less the
  uptime is the boot's instant. A `Level` has a `motion`, what the rim holds to carry the knobs round without a stir
  (`.none`; `.tank`, maelstrom's; `.crank`, charybdis's planets, not built), and a kind per knob (`kind(of:)`, from its `seized`, `sockets` and `ratchets`): a working knob stirs, a seized
  one or a socket refuses touch, and a ratchet is one of Escapement's clocks (`Level.clocks`, in tick order: clockwise from twelve by
  `Layout.clockwise`, each +1, or -1 if in `woundBack`), with a
  `demo` stack for the demonstration before the first stir. Every level today turns its tank exactly where a
  knob is seized (`testTheRimKeysOnMotionAndADiscOnItsKind`), and `UNSTIR_SEIZED` sets both. `par` is `fixedPar`, else
  `scramble.count`.
- **TankView.swift**, **Game.swift**, **Shader.swift**, **Lessons.swift**, **Rods.swift**, **ResultCard.swift** and
  **EscapementViews.swift** hold the play screen, split by type (Jack's call ARCH = A), and this one entry covers all
  seven. TankView.swift keeps `LevelView` whole, with `BackSwipe`, `Grab`, `ResetArm`, `Breath`, `Detent`, `Awake`,
  `Knock`, `Bezel`, `Knurl`, Prism's `ChannelSwatches`, `Letters` and channel tints, and the app's colours and
  `Font.mono`; Game.swift holds `Game`; Shader.swift `Unstirred` and `PictureLayer`; Lessons.swift `KnobLesson`,
  `LensLesson`, `RimLesson` and `GhostFinger`; Rods.swift `RodView`; ResultCard.swift `ResultCard`, `TierUp`,
  `Completion`, `Review` and Escapement's `LostCard`; EscapementViews.swift `ClockHint`, `RatchetView`, `FlipCounter`,
  `LostStamp` and `StopLook`. `Game` is the per-level state: stirs, moves against par, undo, clean-solve rules and
  endless's brim, which the rim shows (the header shows moves, and the title the tank). The header's count flashes red
  on a push, and otherwise reads amber at par and magenta past it (`LevelView.parTone`; VoiceOver adds "at par" or
  "over par"), and an over-par solve veils its picture under the card by 0.05 a move over, to 0.2 at most
  (`LevelView.haze`; Jack's call C11, round 13). `Game.commit` takes a physical
  knob and commits to the slot under it. Endless has no par, undo or reset: each red flash (a `.pushed` commit) adds a
  notch to `Game.brim`, each of the scramble's entries that pops settles one (the heal's `.cancelled` commit, or a push
  that the heal lets fall cancelling it), and at `Run.room` (8) the run spills. The stack's entries mark the player's
  pushes (`Game.Entry`) so that cancelling one is no heal, and flashes white as a merge does rather than the heal's
  magenta ring and heavy tap, which in every mode mark only a commit that pops one of the scramble's entries (Jack's call SND2 = A, round 16; Escapement's the move's own commit, not its ticks, and the sandbox, with no scramble, never rings); a win the fine pass calls also settles one, as the tank's
  last heal, while one of the scramble's entries is left and unless its move healed one. `Game.nextTank` carries it to
  the next tank. `Game.turnTank` is a move that pushes no entry: turns in a row join, and one netting a whole turn
  drops. The result card of a tier's last level, and of the solve that opens the next tier wherever it stands (`Game.opened`, read either side of the best's save), goes up a notch (`TierUp`): the next tier's name in its own sweep, glowing, opening its first level, or, while that tier is closed, as bright behind a lock with how many levels are short of par, opening the menu on that tier's gate. Any solve that isn't clean, but endless's (`Game.offersAgain`), offers "again ↺" on the card, a reset (the glass no longer eased home); on the daily, which counts only its first try's solve, it plays as practice, as a later visit does (`Game.firstTry` goes false, so `counts` saves no best and no streak day, and the caption, card and share line say practice; Jack's call P1 = B, round 13), and every solve that saves a best over an earlier one says how it stands: "new best · was +2" when what the card names improves (`Best.standing`), else "best · par". A best ranks by clean, then over par, never by time, a tie keeping the older (Jack's call C10, round 13), after a daily's best kept on its day first, over one the archive saved, whatever either's result, so `Daily.run` counts a day played on its day that another time zone or iCloud had already given an archive best (`Best.standing`, the one rank `save`, `Sync.beats` and the card read; the card says nothing of such an archive best, as on a first solve); the card shows no time, which only the log keeps. A run carries the best as it began (`Run.best`), so its spill card says "new best" in lime when it beat it. The solve that gives the last of a pack's levels a best, or of maelstrom's, says so under the best line in the card's colour, once (`Game.completed`, read either side of the save: "Lens complete · 25 panels", `Pack.noun`, or "every tier unstirred"; never a pack short of `Pack.planned`), and under it a quiet "try Escapement ›" opens the card of the first pack on the shelf the player doesn't own but the one completed (`Offer.pointer`, `LevelView.onOffer`), none once all are owned (Jack's call C8, round 13). Maelstrom 27's card, the end of the free ladder, says "more puzzles in the packs ›" once (`Best.packsPointed`, set as the card shows it, never by the harness) where no completion's pointer already does, opening the first pack on the shelf the player doesn't own, none once all are (`Offer.ladderEnd`; Jack's call M6, round 14). The solve that opens whirlpool asks for a rating once, 2 s after its card shows (`Review`, `requestReview`; Jack's call C20, round 13), and stores that it has (`Best.reviewAsked`): `RootView` makes the request (`Review.pending`), so a tap off the card within the wait doesn't lose it, and only while the app is in front, waiting again on its return; never in a harnessed launch or the test host, nor in one where a purchase landed on a card (`Store.landed`), which, as that solve comes once, never asks. The daily's card, practice too, says under its buttons when the next daily comes, at the local midnight that ends the card's own daily, read off its id (`Daily.untilNext`: "next daily in 7 h", minutes under an hour, and "next daily is out" once that midnight has passed; VoiceOver hears hours and minutes). `Game.history` holds rod stirs by slot and
  tank stirs as rod `Game.tank` (-1), so an entry is not always a rod index. `LevelView` plays it (drag on a knob →
  live twist → `Game.commit` on lift; where the level's motion is the tank, a drag on the rim or a two-finger twist → live tank turn →
  `Game.turnTank`), drawing the picture through the `Unstirred` shader modifier, and shows the result card. `LevelView.grab`, a pure function, decides what
  a finger holds where it lands, never by its motion: the rim first, else the disc whose centre is nearest in its own
  radius, overlapped or not, never the swirl; a seized winner or a socket is `.seized`, which holds nothing, and a
  ratchet `.ratchet`, which holds nothing: a tap on the ratchet's plate (a dark disc of radius `ratchetReach`, edge lit)
  waits (`Game.wait`), a tap elsewhere on its disc sends a ring from the finger closing on the plate, and a drag shakes
  it with a thud. A touch landing within 20 pt of the screen's left edge waits for its first 10 pt: rightward and
  mostly sideways, it is the back swipe (`BackSwipe`; Jack's call C19, round 13), which slides the level off over the
  menu, dimmed 0.4 at the start and less as it uncovers, and past a third of the width, or heading past half, leaves as
  ‹ levels does, else (or flicked back left, as iOS's own) springs back; otherwise the tank takes it up from where it landed (a vertical one a rim turn,
  Jack's call S2). The tank keeps that call for the whole touch, read by where it landed (`BackSwipe.edge`), as the
  slide moves the tank under it. It works wherever a level is up, cards and opening too; under Reduce Motion nothing slides, and a
  swipe past the threshold leaves through the dip. The rim, from
  `LevelView.rim` (0.93) out over the bezel, holds the level's motion where it has one and the swirl where the layout
  has one. Where it has both, the swirl holds the glass's own edge from `swirlBand` (0.86) and the motion the bezel and
  beyond. The rim lesson, the knurl, the bezel's hit area and the two-finger spin key on the motion, and touch on the
  knob's kind. The swirl has no knob: its dial is drawn just inside the bezel, as the tank's is. The held rod
  lights at once with a light tap, so the rod that lights is the rod that turns: its knob's ticks and a ring on the dark
  band round it, never past it, and one 0.5 pt hairline round its disc, dimmer until letting go would commit. On lift
  the disc's hairline flashes and fades, a twist that stacks an entry flashes the knob's ring red (the swirl's, a hairline `swirlFlash`, 5 pt, inside the glass's edge), and one that pops
  one of the scramble's entries sends a magenta hairline out from the knob. A drag the system cuts off (a call, Control Center, Siri, the lock), a
  second finger takes over or a change of pose moves the tank under (`PlayLayout`) lets go as the lift would, whichever of the phase change and the cancelled gesture comes
  first, and the phase change's at once, without the settle, whose completion waits on a frame (Jack's V26 call,
  2026-10-27, extended by his call C13, round 13). Every line a turn draws over the picture is a hairline but the count's
  dashes, 2 pt, and none has a glow or a dark band under it: the pictures are fine lines themselves, and whatever a
  heavy line covers the player cannot read. The opening replay's ring is not a hairline. A
  seized knob touched shakes a few degrees, plays `Knock.thud` (duller than the tank step's `Knock.clunk`, both on one
  haptic engine that a level able to knock starts as it appears and on coming back to the front, `Knock.warm`, so the
  first knock never hitches its frame, and stops once no such level is on screen) and pulses
  the rim's lesson (a turn a full stack refuses shakes its knob and thuds the same way, without the pulse, and the
  caption says "the tank is full: undo or reset" for three seconds): `RimLesson`, a two-headed amber arc just outside the bezel at the top and a ghost finger rocking
  along the rim under it, shown on any level whose rim turns the tank until the player's first turn of the tank commits. That
  turn sets `Game.tankTurned` and the stored flag (`Best.tankTurned`) behind it, on every level; a rod stir never does.
  The lesson never shows a way to turn, and after the flag only the pulse brings the arc back. A level with a swirl
  shows its own lesson the same way until the player's first stir of the swirl commits (`Game.swirled`,
  `Best.swirled`): a thin cyan arc at the bottom 10 pt inside the glass's edge, seated on a dark stroke
  and without the tank arc's glow since it lies on the picture, and its ghost finger there, in the middle of the
  swirl's grab. So on a level with both, each lesson points at its own ring: the tank's at the bezel, the swirl's
  inside the glass. It goes while the swirl is held. The lessons go once learnt, so two standing cues keep saying
  what the rim does. L1, until it has a best, shows the knob's verb with a lesson of its own (`KnobLesson`): left
  untouched for 4 s after its opening, a ghost finger rocks round knob 0 halfway out its disc until the first stir
  commits, gone while any finger is down and held mid-rock under Reduce Motion. Lens 01, until it has a best, shows
  the lens's verb with `LensLesson`, from the moment the tank is the player's, with no wait, as the rim's lessons: a
  ghost finger (`GhostFinger`, `KnobLesson`'s too) on the knob's left edge rides down the finger's real travel for the
  level's two steps (`2 * lensPitch` of the radius), eased, then fades and starts again at the top, every 2.2 s, beside
  the track's rail drawn faintly on the right, where a drag landing there draws its count (`trackSide`, `trackX`), so
  copying it solves (`testCopyingTheLensLessonSolvesLens01`). It fades in and out, each showing from the top, while no
  lens's stir is in the game's history (an undo of one brings it back), gone while any finger is down, and held
  halfway down under Reduce Motion.
  `Knurl` mills the bezel wherever the rim turns the tank: dark grooves between ridges every 4 pt or so,
  faintly amber at rest (the tank's colour, as its lesson), turning with the glass and brighter while the rim holds
  it, gone under the result card unless the run spilled. `Breath` shows the swirl: while the tank rests, on a layout
  with a swirl, until the player's first stir of the swirl commits (`Game.breathes`: the moment and the flag,
  `Best.swirled`, that retire its lesson, after which no level breathes again), the swirl sloshes the picture once through its own map and settles, a 12° sine damped by e^-t over
  `length` (3.2 s), so it peaks near 8° and ends at 0. The first slosh comes `first` (1.5 s) after the tank becomes
  the player's; after any lift the next waits `later` (10 s), so no move is answered by a slosh; then one every
  `every` (12 s). The rest ends on a touch (a finger on the rim or a knob, two fingers, a drawn fingertip), the
  opening, a win or Reduce Motion, which has no breath at all; a cut slosh fades out over `fade` (0.25 s) from where
  it stood, under any live turn, so the picture never jumps. An undo does not restart the rest. It moves only the
  picture: `Unstirred.breath` adds it to the shader's stack as one entry on top, only while its angle is off 0, and
  the four-tap budget counts it, a drag or both at once as one entry over; nothing of it reaches `Game`. The picture's timeline
  runs only while it moves, from `lead` (0.1 s) before each slosh (`testBreathSloshesFromRestAndBackToIt`,
  `testBreathFadesFromWhereACutCaughtIt`, `testBreathMovesOnlyWhileItSloshes`, `testBreathStopsOnceTheSwirlIsUsed`). A drag shows its own
  count: a long mark on the disc's hairline (on one just inside the rim, for the tank) where its stir began, a dash per
  step from there on a circle 14 pt inside the disc (16 pt inside the rim) over a fainter trace out to where the turn
  stands, and a signed count off the finger. The dashes and the count follow what letting go would commit
  (`Detent.steps`, the nearest step). Each change of that, at a half step either way, clicks: a rod's a selection
  haptic and no sound (Jack's call SND1 = B, round 16: the haptic and the dashes carry the steps), the tank's its clunk,
  a haptic and no sound either, a two-finger spin's and the lift's last step too (Jack's call snd1-clunk = B, round
  16). While `Game.openStir` is the rod's, the hairline, its dashes and the count stay faint after lift, until another
  rod or the tank is touched; they read only the history, never the stack. Wins run the coarse `looksSolved` pass on the
  main actor and the fine pass off it. Under Reduce Motion the opening fades through black (`curtain`, 0.2 s each way)
  in place of the wind-in, a replay level keeping its rod turns, which are the information; the solve swells the
  picture's contrast where it stands (not on Escapement's paper, where it would turn the bone white, so there the
  solve draws nothing on the picture), with no wave, pulse or glass easing home; the lessons' ghost fingers rest
  mid-sweep; the lost stamp lands without its scale. Under it or Dim Flashing Lights the picture fades on rather than
  flickering (`PictureLayer.strike(calm:)`). A live picture holds one frame (`Picture.rest`, between the twins' beats,
  `Picture.clock(_:still:)`), and endless's rim cuts to where each change comes to rest, a spill to its end, murk and
  words and all (`Brim.rest`), its card over it at once, with no bob or tremble as room runs short and the last notch's pulse held lit
  (`Brim.frame`'s `still`), so nothing moves without the player (Jack's call F2, round 14); the stirs themselves still
  turn. `Game.refill` runs as `LevelView` appears, never in `Game.init`, which SwiftUI
  reruns for a level already on screen on a game it then drops; a refill shows its "+2" over the undo count for three
  seconds once the opening ends or is skipped, as the control comes live, and not again on a reset. The first refill
  ever reads "+2 undos" (`Best.refillShown`), and VoiceOver announces each; one left unseen during its opening
  (`Best.unseenRefill`) shows on the next level opened that day. Undo greys and refuses with nothing to undo; with the
  bank empty it stays live only to put "undos refill +2 each day you play" in the caption for three seconds (the
  lost card's under its buttons), which plays the undo and reset sounds as the bottom controls do. An undo tapped
  while a let-go settles is taken once it has. A reset with nothing played only replays the opening and counts no
  reset, so it costs no clean. An unfinished level resumes (Jack's call C2, round 13): `Game` records each call that
  succeeds (`Resume.Action`: a knob's turn, a tank's, a wait, an undo, a reset with moves played; never the
  demonstration's) and saves it with the try's first-try flag and seconds (`resume.<id>`, Resume.swift) before the
  settle, and on leaving or going to the background; `RootView.show` replays the record through the same calls
  (`Game.resumed`) before the level appears, with no opening, the bank, flags and analytics untouched, the fine pass
  inline and the brim's replayed changes long settled. A save whose level no longer deals the same (`Level.print`)
  or that the level refuses is dropped, and a launch drops dailies the archive doesn't hold (`Archive.days`) and ids no level has (`Resume.prune`).
  A solve clears it; a tank out of ticks keeps it, the losing move too, and reopens on its lost card, its undo live
  and the loss's rings, sounds and analytics not played again, until "again" or a solve clears it, so a back swipe off
  the lost card loses nothing (Jack's call, 2026-11-01, on C19); a cleared tank of a run
  saves the next tank's, empty, so endless keeps its run from tank to tank, and a spill clears it. Only a plain
  launch's level saves (`storesResume`), and a harnessed launch reads none but `UNSTIR_RESUME`'s. `Level.print` is
  spelt out, never through a description, and pinned (`testThePrintNeverChanges`): a change drops every save. With moves played, the play screen's reset takes a second tap: the first only taps and
  arms it, "reset? tap again", for 2 s (`ResetArm`; under VoiceOver until focus leaves it), and any move, undo or
  finish disarms it; the cards' "again" resets
  at once (Jack's call C12, round 13). The opening (L1 to L3's stirs played forward at 0.2 s a step, then a beat on the
  stirred picture; every other level's wind-in) skips on a tap anywhere; a touch on the tank skips it as it lands and
  takes up what it landed on, and one that skips Escapement's demonstration holds nothing. A level counts as started
  (`Game.started`) on its first committed move, a turn, a tank turn or a wait, never on a touch nor on the
  demonstration's commits (Jack's call C3, round 13). A level with a best counts as started for `Game.firstTry`, so a
  best iCloud (`Sync`) brings without its level's started flag still makes a try there no first. A level's note shows at full strength for its first 4 s of play, then at
  0.55, as every caption rests. Plughole 01's first open hangs one line under it, at 0.55, pointing at the settings
  ("sound, haptics, colour letters: ⚙ on the menu", `LevelView.pointer`, Jack's call F3, round 14; it fits the SE's
  width with little to spare), and announces it to VoiceOver as the opening ends, when `Best.pointedAtSettings` is
  stored; the line stays the visit out. Beside the menu, where the gear is in sight, it neither shows nor announces,
  and is still stored as shown (Jack's call r16c-pointer = C, round 16). While a level is open and unfinished the screen stays awake (`Awake`) until two
  minutes after the last touch.
  Escapement's clocks live in `Game` too (`Game.Clock`, `escapement`). After every move each clock that holds an entry
  as its turn comes ticks its step through the ordinary commit, in `Level.clocks`' order (Jack's call D1, round 9), so
  one clock's tick can uncover the next's seam on the same move (the book's 17 and 18 need it), and the stack's last
  tick solves on the spot; a clock that can't tick (`canTick`) has stopped, and once all have there is nothing to wait for, and a tap that would wait thuds. A
  move is one working knob's stir or a wait, a tap on any ratchet. Every
  let-go is a move of its own and final (Jack's call E1, round 9): its tick lands with it, nothing joins it, and the
  same knob grabbed again is the next move with its own tick, so a stir's dial always counts from zero. Escapement has
  no par (Jack's calls EL1, round 11, which replaced round 9's E1/E2 loss rule, and ES2, round 12): each clock has its
  own count, what it owes on the stack (`Game.owed(_:)`, `Level.owed`), and each of its ticks spends one of it; the
  header's budget is every clock's together (`Game.budget`, `Level.budget(on:)`; `Level.budget` as dealt, which the note
  states: "Unstir in 9 ticks.", each chapter's opener adding its rule, problem 1's that a clock ticks after every move
  and each let-go is a move), so a move with three running clocks spends three. Only a clock's own ticks change its
  rod's steps, each by one whether it merges or pushes, so the counts are read off the stack and nothing stores them.
  A clock ticks while its rod holds an entry and its count is above 0 (`canTick`); at 0 it stops. A tick that pushes
  buries a clock entry of the wrong sign, `overdue(_:)`, that no continuation pops (`testAPushedTickNeverPops`), and
  still spends one of that clock's count, but the tank plays on, every later clock in the turn still ticking
  (`pushedClock`); once no clock can tick with twists still on the picture the tank is out of ticks (`lost`, which
  `finished` counts). Without a pushed tick a clock's count reaches 0 exactly as its rod empties, so it ends no proved
  line (`testTheBudgetIsWhatTheClocksOweAlongEveryProblemsLine`, `testEachHubCountsItsOwnClockAndTheHeaderIsTheirSum`,
  which also checks the counts through a wrong move and its undo before every move of every line). No clock in the
  book owes more than 9, so a hub shows one digit (`testEveryHubCountFitsOneDigit`). A solve spends the budget to the
  last tick, so `over` is always 0 and its best stores as solved; its wave, the tank's swell, the glass easing home and
  the chime wait for that tick, `tickBeat` and more after the lift, and the result card follows the wave by its usual
  1.4 s (`LevelView.landSolve`, `solveDelay`; Jack's call tk-finish = B, round 16). One clock stopping while another runs loses nothing.
  A full stack refuses a move whose tick it would refuse. Undo is the pack's, the stack and the clocks as the move found
  them, and works on a tank out of ticks; reset deals the counts afresh. The result card says "solved in N moves", as a solve always spends the budget. The header shows the budget, not moves against
  par: "ticks" and a split-flap numeral (`FlipCounter`), driven by the ticks' own keyframes, whose old digit's top half
  falls over the hinge as each clock's tick starts to turn, one flap per tick in turn; Reduce Motion swaps without the
  fall; it goes vermilion at 00 and stays up over the card. The view draws
  each clock's knob as a 12-tooth `RatchetView` read against a vermilion sub-dial fixed to the glass (a wound-back
  one mirrored), its hub a one-digit `FlipCounter` card of the clock's own count (unmirrored), flipping with the header
  as each of its ticks starts, so the header always reads as the hubs' sum; a clock at 0 greys its wheel, sub-dial,
  card and `ClockHint` as its last tick lands, the pawl and hub ring amber, with the stop ring in the plate's vermilion; its pawl riding out with each tick, the move's ticks a beat after the lift each turning its clock's
  core a step on screen in turn, `tickTurn` apart after `tickBeat` (`Game.tick` holds each with the stack it changed and whether it pushed; `Unstirred.tick`,
  one entry over in the four-tap budget, like the drag) and the wheel a tooth; `ClockHint` dashes the clock's disc at all
  times (Jack's call, 2026-10-25); a pushed tick flashes the ratchet red and stands as a vermilion +N, and the
  caption says at once that the line can't come back ("That tick can't come back. Undo, or again.", or "... Reset." with the undo bank empty, `Game.deadTickWords`,
  at a notice's strength and read off the stack, so it stays until an undo takes the tick back; Jack's call C14, round
  13); a
  tank out of ticks shows "out of ticks." (`LostStamp`) by the clock whose tick spent the last, with or without a +N
  (a −N for a wound-back clock), and with no push the look `UNSTIR_STOPLOOK` picks (`StopLook`: stamp, as built; left,
  the twists left as a count; rings, a ring on each knob still twisted), and `LostCard`'s "out of ticks on move N",
  undo and again, whose
  exit goes through `leave` as the result card's does. A clock stopping sends a ring out in the plate's vermilion as its last tick lands. A level with a
  `demo` plays it before the problem opens until the problem has been solved (always in the harness, unless it holds the
  tank still), and after a reset of a tank with nothing played, which replays the opening: a drawn fingertip
  heals the demo stack through the real rules, so the clock ticks, then taps the ratchet, and the picture fades to the bone paper
  and the problem winds in on `dealt(level)`; a tap skips it. Clock commits take the level's `lenses` like any other.
  Escapement plays on paper (Jack's call ESC-PAPER = B, round 16; **Page.swift**): `Level.page` is `.book` for its
  levels alone and `.night`, the play screen's own colours, for every other (`testOnlyEscapementPlaysOnPaper`).
  `LevelView` puts it in the environment (`page`) and draws from it: the ground, bone (#F3EAD8); ink (#1A1A1A) for the
  text, the turn's hairlines, dashes and counts, the lift's flash and the drawn fingertip; the plate's vermilion
  (#D8402A) for the clock's marks, `ClockHint`, `LostStamp`, the +N and the stop ring; no glows; and ink for the cards'
  lime, amber and magenta words, which don't read on bone. The status bar goes dark (`preferredColorScheme(.light)`),
  and the caption, the stipulation, is set in a serif (`Page.caption`). The shader is untouched: its solve wave only
  brightens what is lit, which on bone runs white, so the band is off and an ink ring runs out over it (`Page.wave`).
  The ratchet's dark plate, steel wheel and split-flap cards stay as they are. The clip and the bundle's cut draw on
  the same page.
- **Pack.swift** and **Store.swift** hold the paid packs, outside the tier ladder: `Pack` (First Stir, Lens,
  Escapement, Prism) has a name, a level-id prefix (its raw value: `lens-1`), a product id, a free taste of 3 and its levels (First Stir has
  25, five chapters; Lens 25 in four chapters of six, the last seven (`Level.lensChapters`); Escapement the problem book's 30 in its order and five chapters, `Level.chapter`, which the
  card's list heads, counting solved levels: each par, never shown, what its slowest clock owes and reached by the
  prover, its one key pinned,
  `EscapementTests`; the full ±11 key search is slow; Prism 30 in five trays, First Stir's replacement in v1, PK1):
  `Pack.levels` reads `Level.firstStir`, `Level.lens`, `Level.escapement` and `Level.prism`, numbered from
  1 by place under `Pack.id`; a `Level` names its `pack`. A pack's level plays in its pack's glow (`Level.colour`, the result card's accent) with the pack's name small above its title, and its way out reads "‹ Lens" (`Level.back`), as it goes back to the card, whose own reads "‹ menu" ("✕ close" beside the list in a wide window, or over a result card beside the menu), or "‹ Triptych" when the bundle's card opened it (`PackCard.backTo`), pinned over the card's scroll so it shows at every scroll position (Jack's call C1B = A, round 16). A pack's undo spends the shared bank like any other, but
  puts back the stack as the move found it, marks and tags and all, from `Game`'s snapshot of the stack as each stir
  began; the free tiers' commits the stir's negation (`testAPackUndoPutsTheStackBackWhole`). No pack best ever opens a tier. `PackTests` pins every stored
  level id, product id and storage key as literals, so never rename one. `Pack.access` says whether a level plays: the taste
  always, past it only a pack StoreKit grants, with `Best.unlocked` counted outside Release, in a playtest build
  (`Build.playtest`, what `scripts/run-ios.sh` installs) or in the editors' build (`Build.editors`), and the harness outside Release only.
  First Stir is out of v1, to be reworked (Jack's call FS17), and Prism takes its place (PK1): `Pack.ships` is
  false for First Stir alone, and `Pack.sold()`, the packs a build sells (Lens, Escapement and Prism in Release), leaves it out in Release only, so its code, levels,
  ids and tests stay and Debug and the harness (`UNSTIR_PACK=first-stir`) still reach them. In Release its every level, taste and all, is `.withheld`, which opens
  neither the level (`Store.opens`, checked by `RootView.show`) nor its card (nor `UNSTIR_CARD`), and `Pack.sold()`
  sets what StoreKit is asked for (`Pack.productIDs`) and analytics' snapshot (`testFirstStirIsOutOfV1`). The bundle
  (`Offer.complete`, sold as `Pack.completeID`, its old name Complete kept in its ids) is self-limiting (Jack's call
  M1 = B2, round 14): it grants a fixed `Pack.bundled`, Lens, Escapement and Prism, in every build, and no later pack
  ever joins it (`testNoLaterPackJoinsTheBundle`); a later bundle would be a product of its own. What it grants and
  needs, its cover, words (`Pack.named`; the card's "or all three in Triptych I" counts them, `Offer.countWord`) and clip
  all read `Pack.bundled`. Its name, wherever a player reads it, is `Offer.bundleName`, "Triptych I" (Jack's call M1, round 15: a numeral from day one, so a second bundle is Triptych II)
  (runner-up Folio), and the `.storekit` file's display name with it.
  `Store` is StoreKit 2 with no server and nothing that grants stored (`asked.<product>` only remembers an Ask to Buy
  made here, from `purchase`'s pending result until its approval is said or it is revoked, so the approval is said
  once: `Asked`, `Ledger.answers`, read after the launch's entitlements and each update): entitlements from `Transaction.currentEntitlements` at
  launch (`Store.ready` once that first read has finished: until then `RootView.show` waits on it, `Store.settled`,
  before it gates a pack's level, and the dock shows no state), a `Transaction.updates` listener (Ask to Buy approvals, refunds, other devices, Family Sharing),
  `purchase` and `restore` (`AppStore.sync`), and a `PurchaseIntent.intents` listener: a purchase started on the App
  Store's product page (a promoted purchase) sets `Store.promoted` to the offer this build sells (`Offer.promoted`),
  keeping its product, `RootView` opens that card over the menu, closing the settings sheet (an open level leaves
  through its own way out, `LevelView.leave`, its try saved and its quit sent as the back's are), and the card takes it and buys as its own buy does once `Store.settled`, unless owned or payments
  are off, landing as any purchase lands (Jack's call M6, round 14). `Store.bought`, any pack owned (the bundle or a
  family's share too), is the one check of whether the player has bought anything: the supporter mark reads it, as
  the daily archive does. Under the harness's states a purchase lands in them, never StoreKit. Only a verified transaction grants; the bundle (`Pack.completeID`) grants
  `Pack.bundled`, and a revocation takes back only what that product alone granted. `Ledger` keeps each product's
  `Purchase` (unowned, owned, pending, failed, revoked), and `Store.failures` why each failure failed (`Failure`:
  offline, a storefront without it, purchases turned off), which the card says under it. A pending pill reads
  "asked" and stays live, since StoreKit sends nothing for a declined Ask to Buy and a new purchase sends a new request;
  an ask again that fails leaves the product pending and says why under it. A pack waiting only on the bundle's request
  (`Store.asked`, its own product's state) says the bundle is the one waiting, and its pill buys the pack alone; the
  bundle's line under it waits too. Where
  `AppStore.canMakePayments` is false (`Store.canPay`) the card offers only the taste and says why; and a restore says
  what it found that wasn't owned (`Restored`, `Store.restoreNote`), and nothing on a cancelled sign-in. A revocation
  says, in grey, that the pack isn't on this Apple ID any more, or, where its transaction was family-shared
  (`Ledger.unshared`), that it is no longer shared, and that the progress is kept. A revoked pack keeps its bests; past the taste it needs the
  card again. `StoreKit/Unstir.storekit` sells each pack (First Stir too, since `StoreTests` run outside Release, where it is sold) and the bundle as family-shareable non-consumables at
  2.99 a pack and 5.99 for the bundle (Jack, 2026-10-25, when it held three packs, as it does again); the scheme's run action and `StoreTests` use it. Prices are
  never the app's own: `Store.prices` holds each product's `displayPrice` (and `amounts` its `price`, written in its
  `priceFormatStyle` for the bundle's saving, `Store.saving`), fetched at launch and again when a card
  opens without one, and a card with none says "price loading" beside buy, or "App Store unreachable" under it once the fetch
  has failed (`Store.pricing`; beside it, the SE wrapped it inside the pill), the pill still live, since the App Store's sheet shows the price.
  `Level.lens` holds the pack's 25 levels, table A of `docs/lens-tables.md` (lenses on rods of every size; table B, big
  rods only, is the alternative on branch `lens-levels-big`), on the halftone: each dealt lens entry +1 to +3, each lens
  netting at most +3, no entry merging as it is dealt, and par the depth (`testLensLevels`, which pins the table), the
  solver's optimum (`testLensParIsTheOptimum`, slow; `scripts/lens-table.py docs/lens-tables.md --solve` checks a
  table's rules and optima in seconds before it goes in). A lens's knob carries a magenta iris (`RodView.lens`). On a level with masks every knob is tinted its mask's
  colour (`Level.tint`, `Channels.colour`, the cover's red, green and blue and their mixes), a white rod white: its
  ticks, pointer and a jewel at the cap's centre. Under the settings' colour letters, which follow Differentiate
  Without Colour until chosen (`Letters`, stored as `letters`, absent until then; Jack's call C16, round 13), or
  `UNSTIR_LETTERS=1`, Prism reads without colour: each knob spells out the primaries it holds under its cap (`Channels.letters`: R, GB, RGB),
  and `ChannelSwatches` (R, G and B) sit under the caption; holding one draws that channel alone in its own
  colour (`Channels.tint`, its knob's; Jack, round 15) and hides the others (`Unstirred.isolate`, the `unstirChannels`
  shader's `isolate` and `tint`), in white instead under the system's Differentiate Without Colour, whatever the
  letters' choice (`Unstirred.whiteIsolate`), and VoiceOver toggles it. Neither shows
  otherwise, so the read stays by colour for everyone else, and Prism's card says "letters for colour-blind play, in
  settings" under its facts (`Offer.note`), owned or not. `scripts/colour-blind.py <out> <shots>...` lays shots out
  beside their protanopia, deuteranopia and tritanopia simulations. A lens follows the finger up and down, not round
  (Jack, 2026-10-26): `LevelView.lensTurn` counts `lensPitch` (0.15 tank units) of travel as a step, up a positive
  one, which magnifies, so the dealt entries are undone dragging down (`testALensDraggedUpZoomsIn`). The step goes
  through the rod's own `liveAngle` and detent, so its count, clicks and the iris's turn are a rod's, a step at a time,
  but its dashes run up a short vertical track beside the knob for a zoom in and down it for out (`track`, on the side
  away from the finger), not round the disc. A drawn fingertip (`UNSTIR_FINGER`) on a lens rides up and down too, and Lens 01
  teaches the drag with a ghost finger down that track (`LensLesson`).
  `Level.prism` holds Prism's 30 specimens from `docs/prism-design.md`, five trays of six (`Level.prismTrays`, each a
  `chapter` the card heads, on its own plate, `Level.prismPlates`, its opener's note saying the rule it adds): Two
  Colours (red and cyan), Three Colours (the primaries), Colour Order (the inks), Overprint (both) and Spectrum (any).
  Every rod is dealt, over one white rod that holds only the bottom entry, no entry merging as it is dealt, no stack
  deeper than 8 (Jack's call PK1: deeper reads too busy), par the depth (`testPrismLevels`, which pins the table and
  checks each stack keeps four taps under `channelCost`), the solver's optimum (`testPrismParIsTheOptimum`, slow,
  about 4 minutes).
- **FirstStir.swift** holds First Stir's table (`Level.firstStir`) and its scenes. A level with a `story` draws it in
  place of its `picture`: `Story.vignettes` names the rods whose rigid cores each hold one vignette, drawn held back
  (later in the night) and played (earlier). `Game` deals each of the scramble's entries on such a rod with that rod in
  its `tags`, and `Game.played` is the story's vignettes less every tag on the stack, so the picture is a function of
  the stack alone: a pop plays what it carried, a vignette waits for every entry on its rod, a win the fine pass calls
  plays the rest, and the pack's undo and a reset bring tags back with their entries. On a story, the heal ring
  (magenta and the heavy tap) marks only a commit that plays a vignette; cancelling the player's own push flashes
  white. `Harbour` holds what every scene shares: the line, `Harbour.fade` (0.4 s, a played core fading in on the
  rewind's clock), `Harbour.rewind` (1.6 s) and `Harbour.budget` (64 MB, not yet measured on the phone; about 51 MB at
  3x on the largest phone), past which the layers bake at a lower scale. The lab's harbour in the storm is scene 16 now,
  `Storm.harbour`, on the engine below; the tests play it under a test id. `testNoVignetteShowsTheNextMove` renders
  each vignette's two states at 512 px, and the baked layers again at the largest phone's own pixels (1263), checks the
  difference stays inside its own core (so the cut clips no glow), and over
  every heal order that `Layout.removable` allows, that no vignette's light reaches the core of a rod removable right
  after its heal and that the entries left move none of it by half a pixel; it allows no fault (F4 redrew the
  harbour's two, the lantern's shards and the boat's stern in the cottage's ring). Every scene must also keep every
  change 0.02 inside its core and clear of the knob (0.085 from the rod's centre), the outline's art spec
  (`docs/first-stir-outline.md`).
- **StoryScene.swift**, **FirstStirDawn.swift**, **FirstStirRescue.swift**, **FirstStirFlood.swift** and **FirstStirTheStorm.swift** hold the scenes on the pack's one night
  (Jack, F2). A `StoryScene` draws, in tank units, a sky and sea at a time in minutes after midnight (`drawSky`), the
  scene with some vignettes played (`draw`), the bodies that move with the time where no disc reaches, their line and
  glow (`Dawn.bodyGlow`) included (`drawLive`: the sunrise's sun and chimney smoke;
  `testTheBodiesStayClearOfEveryDisc`), and the weather that falls over everything, played cores included (`drawOver`:
  the Rescue's, the Flood's and the Storm's rain, the Storm's far lightning), between `late`, as the level opens, and `early`; `drawLive` and `drawOver` default to nothing.
  A chapter is an enum of its scenes conforming to it, one `Story` case (`Story.dawn`, `Story.rescue`, `Story.flood`, `Story.storm`) and an arm in
  `Story.scene` and `Story.vignettes`; `Level.firstStir` joins the chapters' levels and stamps each id and label from
  its place. `SceneLayer` draws a scene from four baked layers (the sky at `late` and at
  `early`, cross-faded, and the scene held back and played), the live bodies drawn over the sky and the weather over
  all. Its cores cut in through masks drawn without antialiasing
  (`SceneComposite.cores`): an antialiased edge showed a ring however it was composited, though both scenes held the
  same there (`testTheCutInCoresLeaveNoSeam`). Its time is a function of the stack: `Game.wound` counts
  the scramble's entries gone (the player's own pushes move no time; a solve has wound them all), and the scene stands
  that share of the way from `late` to `early`, winding there over `Harbour.rewind`. `Game.caption`, the line under
  the tank, is that time as a clock on a scene's level ("6:40 am", Jack's F3) and the note elsewhere. `Dawn` is
  chapter 1, Dawn After: five scenes, 6:40 back to 4:45 am, in dawn pewter, each scene's `early` the next one's `late`
  (`testTheTable`). `Rescue` is chapter 2, The Rescue: five scenes, 4:45 back to 2:30 am, in rescue amber, its ink the
  rain's B7CEFF at full strength. Its sky (low cloud lit from below, `Rescue.skyTones`) and sea open on Dawn After's
  4:45 tones (`Dawn.tones`, mixed as `Tone`s) and turn to the chapter's own by the end of its first scene
  (`testTheRescueOpensOnTheDawnsLastSky`); its rain climbs back up its slant and thickens as a function of the time.
  `Flood` is chapter 3, The Flood: five scenes, 2:30 back to 12:30 am, in flood teal, its ink 8F9CFF, drawn with the
  Rescue's `Brush` and `Cast`. It opens on the Rescue's 2:30 sky, sea and rain (`testTheFloodOpensOnTheRescuesLastSky`)
  and carries the same rain field on (`Rescue.rain(_:r:minutes:drops:through:)`, from 320 drops to 400), the sky
  kept to the flood's palette (chapter 4 turns it to storm indigo, as this chapter turns the Rescue's). Each scene's floodwater line is fixed outside the cores; a vignette that lowers it
  (the street lamp, the cottage door, the kitchen table) draws its own lower line inside its core. The kitchen's rain
  falls only through its window and back door (`Kitchen.windows`).
  Its vignettes draw through `Brush` (a pen in a figure's own units through `at`, each vignette laid down under one
  tight glow by `Brush.vignette`) and `Cast` (the family and townsfolk told apart by outline alone, the dog, the
  storm lantern, the lifeboat, a breaking wave). `Storm` is chapter 4, The Storm: five scenes, 12:30 am back to 9:30
  pm, in storm indigo with sodium (the lab's), its times negative past midnight (`Storm.times`, which `clock` wraps).
  Its levels are 16 to 20, after the Flood's. Scene 16, the harbour, is drawn from Dawn After's sunrise plan (the outline's continuity), its
  shards falling inside the lantern's core and its boat right of the cottage's disc. Its sky (`Storm.tones`) opens on the
  Flood's 12:30 sky and sea, turns to the lab's storm across scene 16, and warms late to Dusk Before's 9:30 sky, where
  that chapter opens (`testTheStormsSkyMeetsItsNeighbours`). Its rain thins to none by 9:30 as the night winds back and its far lightning
  (`Storm.flash`, drawn over all in scenes 16 and 18) is gone by about 10:50; scene 17 is indoors, its rain only
  through its windows. Its vignettes draw through the Rescue's `Brush` and `Cast` in the Storm's ink.
  `Dusk` (**FirstStirDuskBefore.swift**) is chapter 5, Dusk Before: five scenes, 9:30 back to 7:40 pm, in dusk rose (ink B0A6E8), the last in kitchen gold, drawn through `Brush` and
  `Cast` as the Rescue is, each scene's drawing a nested enum (`Dusk.Lamp`, `Walk`, `Lines`, `Gift`, `Stir`). Still
  air, so no `drawOver`: its sky (`Dusk.skyTones`, the palette's three sky tones and nothing between) climbs from
  night blue to the sunset's coral with an afterglow over where the sun went down, and the kitchens show the sky
  through their windows. Its one live body is the first scene's cloud bank (`Lamp.bank`), sinking below the horizon
  by 9:00 at the glass's left edge, the one stretch of the quad's horizon no disc reaches; `Dusk.bodies` feeds
  `testTheBodiesStayClearOfEveryDisc` as Dawn's do. A figure too tall for its core (scene 24's) is drawn whole outside
  the vignette, its arms alone inside it. Its levels are 21 to 25, the table's last five; its times run in the evening's own minutes (1290 back to 1180), a day on from the Storm's. The cup's one entry is the scene 25 scramble's bottom, so the stir is the pack's
  last heal. `Pen` draws in tank units at the one line weight with the shared `neon` glow; `Figure` (father,
  grandmother, child, neighbour, crew) and `Dog` build silhouettes from posed parts and outline their union.
  **FirstStirEnding.swift** holds the ending, the night forwards (Jack, round 9, D1): when the pack's last scene
  (`Level.endsFirstStir`) is solved, `NightForwardsFilm` plays over the glass before the card, every scene in story
  order (`NightForwards.levels`, 25 back to 1), each `length` (4.6 s) from its played state at `early` to its
  held-back one at `late`, the scramble's entries coming back bottom first, so every frame is a stack the game can
  stand in, and the next scene crossfading in over `blend` at the same minute; about two minutes, a tap skips it,
  Reduce Motion cuts instead of fading (`testTheNightForwardsPlaysTheNightInItsOwnOrder`). It draws through
  `SceneComposite`, baking two scenes at a time at no more than 2x and letting each go once passed.
  `scripts/first-stir-lab.sh <scene> <out.png> [side] [x y half-width]` draws a scene of chapters 1 to 3 on the Mac, held back, played
  and where they differ over the layout's cores and knobs, and prints each vignette's reach against its core less
  0.02, its nearest approach to the knob and the other discs it enters: the drawing loop, seconds a render. It counts a
  pixel changed past 14 in 255 (the Mac's renderer shifts bright glow by up to 12 when the rest of the drawing
  changes), the test past 8 at 512 px; the test is the judge. On the simulator one long cloud bank's flat base row came
  out a level different whichever vignettes had played, which the Mac never showed: keep a cloud bank inside the
  tank's width.
- **PlayLayout.swift** decides where the play screen puts the tank (`PlayLayout.of`, a pure function the tests pin):
  any window taller than wide keeps the column, header, tank, caption and controls stacked, with the glass at
  `min(width, height - 290) / 1.045`, as on every iPhone; a wider one (the iPhone Duo opened like a book, whatever the
  portrait lock) splits at the fold, 16 pt clear of it either side: the tank in the leading half with `LevelView`'s
  header and title above it and its caption, swatches and controls below, and the menu in the trailing half (stage 5,
  below). The fold is the system's division region (`GeometryProxy.reservedRegions(kind: .division)`, iOS 27.1, active only while
  the phone is folded; compiled in only from an SDK whose SwiftUI is 8.1 or later, as CI's older Xcode lacks it), else
  the window's middle. A tall window folded across (the Duo upright on a table) is the
  tabletop: the rest in the upright half (the cards hung from the caption, which stretches to hold them there, as
  `PlayStack` measures no overlay), the tank filling the half lying flat, and "unstirred." at the upright half's foot
  (`PlayLayout.words`), never on the fold; a tall window lying flat keeps the column. Neither half narrower or
  shorter than `minPane` (300 pt) splits. The glass never passes `maxPixels` (1471 px, Jack's call duocap2 = D), which
  only the Duo upright reaches, at 490 pt; the stack's limits were tuned at about 1137 px, and past 1300 the four-tap
  limit shrinks with the glass (see Unstir.metal above). The column is a `VStackLayout` and the split and tabletop
  `PlayStack`, through one `AnyLayout`, so a change of pose keeps every part's identity, the tank's picture, opening,
  demonstration and keyframes with it: the parts glide to their new places, and the tank, drawn at its new size at once,
  glides there by `Glide`'s scale, its old bake stretched until the new one lands (none under Reduce Motion, nor from a
  first measure; a bake that lands after a later change of size is dropped). A drag in flight lets go as a lift would
  (`LevelView.letGoOnResize`), and the finger then on the tank, taken up or not yet (an edge touch the back swipe hasn't
  decided), holds nothing more until it lifts. What a level draws past the rim stays inside the tank's pane in the split
  and the tabletop (the column leaves it to the screen's edges, as ever): `PlayLayout.Halo`, read from the level's
  shape alone so no state resizes the glass, is endless's brim all round (`ring`, out to `Brim.reach`, 0.229 of the
  radius past the rim) and the tank's rim lesson over twelve (`above`, `RimLesson.overRim`), and the glass shrinks to
  hold it: endless's to about 348 pt in the open split and 326 in the tabletop, whose glass sits on its half's foot
  with the room left above it. Counts and a lens's track keep inside the pane too (`PlayLayout.bounds`, the pane in the
  glass's frame, which `countSpot` clamps to; `trackBounds`, the same less the split's header and title, so a zoom the
  wrong way never draws through the count, which `track` clamps to), and a lens turns only as far as its track shows
  there (`LevelView.trackRoom`, each step's place on the track inside it, counting the open stir the turn joins;
  `lensCapped`), so what lands is what the track counts: travel past the end is dropped, the finger turning back
  turns the lens back at once, and every Lens level's unzoom fits in every pose (Jack's call d3-lenscap = B, round
  16; the column caps nothing). As the open stir counts, a lens lifted at its cap zooms further only once a move on
  another rod or the tank, or an undo, closes that stir; a drag that a change of pose lets go commits what its track
  showed, uncapped by the new pane. The tabletop's night forwards end their lines at the
  upright half's foot (`filmFoot`); its scenes bake again at a new side, drawn stretched meanwhile, as `SceneLayer`'s
  are. Knurl, clock hints and the out-of-ticks marks lie on the glass and rim already. `PlayStack`'s spacers give way
  before the chrome runs past its pane. `PlayPart.Tagged`'s sort priorities set VoiceOver's order to header, title,
  tank, caption, swatches, controls in every pose (not yet heard; the tabletop's places alone would end with the
  tank). The play screen's text is fixed in size bar the cards' pack pointers, and at the largest type the fullest
  cards fit each pane. The fold is read in one place (`PlayLayout.fold`, the harness's or the system's), for the menu
  too. `MenuLayout.of` splits the menu wherever play splits, by play's own rule: the
  list, its dock under it as on a phone, in the leading half (about 460 pt on the open Duo, a phone's width), and a
  pack's card or the archive in the trailing half beside it rather than over it, coming in from the trailing edge,
  neither modal to VoiceOver there, the list and dock staying live and the dock's covers turning (stage 4), and the
  card's way out reads "✕ close" (VoiceOver "Close"), as the menu is in sight, unless it goes back to the bundle's
  card (`PackCard.back`; Jack's call d4-menuback = B, round 16). It holds
  one at a time: whichever opens last, from the list, the dock or `RootView`, closes the other, and unfolding with a
  card over the archive keeps the card. With neither open the trailing half is empty. The tabletop's menu is the split
  turned on its side (stage 5, where d4-table left it): the title, strip and list in the upright half, and the dock at
  the foot of the half lying flat, where a card or the archive opens over it, each 16 pt clear of the fold
  (`MenuLayout.dock`); the settings sheet rises no higher than the dock's top, scrolling past it
  (`SettingsSheet.detents`; not shot, as the harness presents sheets at the simulator's size, and the policy's Safari
  view and the mail sheet over it are the system's, full height); a level opened in the tabletop covers the menu as on
  a phone, as only the split plays beside it (`MenuLayout.splits`). The column measures the layout with `onGeometryChange` on today's tree, so
  every iPhone's menu is unchanged, and a change of pose keeps the list's place, and a card's or the archive's: either
  is drawn in one place in the tree in every pose, over the menu or beside the list, so it is moved, not opened again
  (Jack's call d4-pose = B, round 16).
  Where play splits, a level opens beside the menu (stage 5; Jack's calls D-layout = 3, DUOMENU = B and s5-chrome = B,
  round 16): the tank in the leading half with its chrome round it, the header and title above it and the caption,
  swatches and controls below (`PlayStack.placeRound`), and the menu alone in the trailing half. The glass is as large
  as that chrome leaves it (`PlayLayout.Chrome`, from the level's shape and whether Prism's swatches show, fixed
  heights that `testTheChromesRoomBesideTheMenuIsWhatItsPartsMeasure` holds against the parts as `PlayStack` lays a
  level out and hands them to `chromeMeasured`; the play screen's text is fixed in size, so no type size changes
  it), the spare room half
  over the tank and half over the controls: stage 1's 424 pt for every level of plughole, whirlpool and vortex, the
  daily, Lens, and Prism read by colour; 5 pt less for maelstrom's rim lesson under the title, 9 less for
  Escapement's split-flap ticks and two lines of serif, 30 less for Prism's swatches under its colour letters, and
  endless's 348 as before, so every level of one list takes one glass, but Prism's follows its swatches: colour
  letters or Differentiate Without Colour turned on or off mid-level resizes it by 30 pt and lets go a drag, as a
  change of pose does
  (`testTheGlassShrinksBesideTheMenuOnlyWhereTheChromeNeedsIt`; every caption fits its two lines there,
  `testEveryCaptionFitsTheChromesTwoLinesBesideTheMenu`). A result or lost card goes over the menu in the trailing
  half, centred on the tank and headed by "unstirred." (`PlayLayout.words` is nil there): still hung from the caption
  and moved there (`LevelView.card`), so a change of pose moves it rather than showing it again. The list fades out
  under it with the card's reveal, out of touch and VoiceOver (`MenuView.covered`, from `LevelView.onCover` through
  `RootView.covering`, keyed by the level), and a pack's card that one of its pointers opens lies over it. On
  Escapement's paper the leading half is bone and the trailing half black from the fold (`LevelView.menuGround`) until
  a card takes it over on the level's paper. `LevelView` adds a `PlayPart.menu` part, which `PlayStack` places over
  the trailing half (`PlayLayout.menuPane`) and which reports its frame in `RootView.space`; `RootView` passes it to
  `MenuView` as `slot`, and the list glides there from its own half, and back
  as the level closes, in one 0.45 s move (none under Reduce Motion; a menu built beside play, on a launch into a level
  or the phone opening, waits unseen for the slot and appears there). Beside play the menu is the menu as it stands
  with no level open, title, gear, tier strip, list and dock, the title gliding with the list (Jack's call s5b-title =
  B), drawn over the level
  (`zIndex`) with only its own column black; the dock
  holds still (`PackDock.paused`) and a tier switch cuts to the new list without the stir (`MenuView.go`), so nothing
  of the menu takes GPU time from the tank. Back closes the level and the list returns to its half, the row left lit
  once however often it is left (`MenuView.followPlaying`, on the level leaving, not on a change of focus). A row, the
  tagline's next, an archive day or a card's level picked beside play is decided before anything leaves
  (`RootView.besidePick`): one that opens leaves the playing level through its own way out (`LevelView.switching`: a
  finger let go, its quit sent and its try saved, as `leave` does), then opens in the tank; a gate's or a withheld
  level leaves the playing level untouched, sending nothing, the gate's card over the trailing half (before the store
  has read what the player owns, decided again once it has); the playing level's own row opens nothing and doesn't tap
  (`MenuView.opens`, so endless's row never deals a run over the one playing; its new run does). A result card's next
  and up a notch open in place without the switch (`RootView.proceed`), as on a phone, so a cleared tank sends no run's
  quit. The list follows the playing level (`MenuView.playing`: its tier, switched to without the switch's sound; its
  row centred, again once the list has glided to a new slot, as the phone folds; its hairline at full and
  "playing" in place of its rods and par, as the frontier's hairline is lit too), and the menu, no longer built anew
  on each return, reads its rows, run and dailies afresh on `RootView.revision`, bumped by every level opened, left or
  finished. A pack's card or the archive opens over the whole trailing half, its ground running on to the fold, as a
  phone's covers the menu (its way out "‹ menu", modal
  to VoiceOver; "✕ close" over the playing level's result card, which covers the menu, `MenuView.closes`, Jack's call
  s5b-back = B), the level playing on under it: from the dock, a result card's pointer, a gate or a promoted purchase.
  A level opened from a card or the archive puts it away while it plays (`RootView.parked`) and brings it back as that
  level leaves, if its way out names it (`RootView.returns`), as on a phone it waits under the level; one left under a
  level in another pose is put away as the window becomes a split (the phone opened mid-level), before the menu is
  drawn there, and waits under the level again if the phone closes. `RootView.slot` goes with the menu beside play, so
  a later one waits for its level's own. The consent question waits for the level to close, as it would dim the tank. A back swipe beside the menu slides
  nothing, as the menu is in sight: past the threshold the level leaves through the dip, as under Reduce Motion.
  VoiceOver hears the level before the menu (`accessibilitySortPriority`; not yet heard on a device).
- **Archive.swift** holds the daily archive (to-do 47): `Archive.days`, the past dailies from 30 days (`backFill`)
  before daily #1 (`Share.firstDay`, or today while it is unset) to yesterday, local Gregorian days as the ids are, so
  today's daily stays on the menu. Any purchase opens it (`Store.bought`, a pack or the bundle owned), and the developer
  unlock where it opens packs (`Archive.opens`). `ArchiveRow` sits under today's daily on the menu: until then a quiet
  lock, "comes with any pack", which a tap shakes and answers as a closed row does, saying "unlocked by purchasing any
  pack" for 2 s (Jack's words, R-arch-lock, round 15), never opening the shelf.
  `ArchiveView` lies over the menu as a card does (beside the list in a wide window, `MenuLayout`, its way out reading "✕ close" there as the card's does, Jack's call archive-close = A, round 16), a month to a block on the player's week, each day's number over its
  result in the menu's words (`Archive.Mark`: clean, par, +n, tried), a list of days at accessibility sizes. A day
  opens `Level.daily(_:archived:)`, the day's own tank under its own id, whose back reads "‹ archive" and returns there
  (`RootView.archive`, `Level.focus(solved:)`), the day ringed once. It plays as any level: its best saves marked
  `archived`, again is no practice, and it has no share line or next daily's time; but a day that kept a best on its
  day keeps it, the archive replaying it as practice (`Game.counts`), so the archive never moves `Daily.run`.
  `Resume.known` holds its days, so a try left there survives a launch.
- **Shelf.swift** holds the shelf (Jack's pick, round 3, S2: a dock of live covers) and the cards. `Offer` is a pack or
  the bundle, with its card's words and colours. `PackDock` sits at the bottom of the menu, once plughole 09 is solved, a pack is owned or asked
  for, or under the developer unlock (`PackDock.shown`, Jack's call C5, round 13), with a cover per offer on
  `Offer.shelf`: in Release a pack only once it has levels past its taste and the bundle only once every pack it grants is there
  (Jack, 2026-10-26, S1), and never a pack it doesn't sell, so today Lens, Escapement, Prism and the bundle; outside Release every cover (`PackTank`), each its clip's level (`Offer.covers`) on its own picture as the game
  draws it (`LevelPicture`: the halftone, black until its bake lands, Escapement 2's engraved plate, the fern; the bundle a wedge of
  each of its packs', cut from the centre, `testEveryCoverStirsItsClipsLevel`), stirred and unstirred by `Unstirred` on
  the level's dealt stack, an entry at a time (`Unstirred.shares`), its knobs drawn over it as the game draws them,
  each turned by its rod's share of the stack and a clock's ratchet counting what it owes, so a cover shows how its pack
  plays (Jack, round 16; the bundle's wedges each turned to hold its key knob, `PackTank.turn`; the promoted-purchase
  images draw them too, Jack's call promo-knobs, round 16), on a 7 s loop, each out of step, held as dealt under
  Reduce Motion, at 30 Hz, paused where it stands under a card, the settings sheet or a level a back swipe slides off, while `Power` saves
  (Low Power Mode, or a thermal state of serious or worse) and once no finger has landed for 20 s (`Power.idle`, from a
  gesture recognizer on the window that fails at once, and from a drag on the list), each carrying on from the frame
  it held (`PausingTimeline`), a glyph by its name for its state (`Purchase.mark`: a check owned, an hourglass waiting on Ask
  to Buy, nothing else, a revocation being the card's to say). Under the name a line says "new", in the pack's glow,
  once its pack fits the player's progress (`Pack.fits`: Lens and Prism once every plughole level has a best,
  Escapement once maelstrom is open, First Stir never) until its card opens, and again when an update adds levels
  since it last opened (`Marks`, stored as `shelf.fit.<pack>` and `shelf.levels.<pack>`, never by a harnessed launch),
  owned or not; else, under an unowned pack once any free level is started or solved, "2/3 free", counting those with
  a best (`Pack.tastePlayed`), kept at "3/3 free"; the bundle's never marks (Jack's call C6, round 13). An Ask to Buy
  approval landing on its open card is said by the landing; otherwise the dock's header reads "Lens is yours"
  ("Triptych I is yours" for the bundle) in its glow for 5 s in sight, waiting while anything covers the dock, and
  VoiceOver hears it once (`Store.approved`, `Store.said`; Jack's call C21, round 13). `PackCard` grows out
  of its cover: the clip (`PackClip`), what it
  assumes, the taste, holds (`Pack.planned`), "More levels arrive in an update." while any of its levels aren't in, the
  purchase state, buy at the App Store's price, try free, the bundle beside an unowned pack it grants, and on the dock, only
  while it costs less than its packs left unowned, saying the saving ("or all three in Triptych I · $5.99 · save
  $2.98 ›", broken only before "· save", and a "save" fact on the bundle's own card; `Offer.saving`, from
  `Product.price`; the line and the fact wait for the prices, and the dock's cover too unless none of its packs is owned,
  `Offer.offersComplete`, read off the prices known and the packs owned, never whether a fetch is running, and hidden
  once the packs' prices are in without the bundle's, as where the App Store doesn't sell it; so with none of its packs
  owned the dock keeps its cover from launch however the fetch went and a card's fetch never moves it; the whole dock,
  header and covers, is laid out unseen from what is known so far until the launch's read and first price fetch
  have settled (`Store.shelved`, or `Store.shelfWait`, 3 s, after the read), then fades in once, so neither changes it in sight,
  but for a fetch that outlasts the wait and returns the packs without the bundle, which takes its cover off in sight;
  the approval's header waits for it too, VoiceOver's announcement with it) (Jack's call C7, round 13) (its own failure said under it, never as the pack's), restore, then the pack's levels, those past the taste
  locked. An owner's card is home, not a shop: no "PAID ADD-ON" or free taste, the pack's progress ("done 4/25 at
  par") for what it holds, restore only while something sold is unowned, and the pill "play 04 ›" until a level past
  the taste is solved, then "continue 06 ›", from the first level without a best, then the first not at par, and none
  once all are (`PackCard.pickUp`, `continues`); the bundle's owned card plays on in the first of its packs with a level
  left ("play Lens 04 ›"). The dock drops "PAID ADD-ONS" once any pack is owned, its taste line
  once every one is, and the bundle's cover once it saves nothing (the bundle owned, or the packs left cost no more than
  it), animating the shelf's change, its height kept whatever the covers' lines say; the bundle's card names each pack as a link to its
  card (`onOffer`, and a VoiceOver action per pack), so each taste is a tap away, and back from that card returns to
  the bundle's ("‹ Triptych I") while the bundle is still on offer, else to the menu (`UNSTIR_CARD=complete` opens it on the same terms, or
  owned). A purchase landing on an open card (bought, approved or restored)
  plays the solve's chime and a success haptic, slides the owned line in and dissolves the list's locks one after
  another, the card staying put; under Reduce Motion the state just changes. The launch's first read of the
  entitlements is no landing (`PackCard.lands`): an owner's card opened before `Store.ready` reads unowned, then owned,
  without a chime or an announcement. A failed attempt shows only on the card it was made on: `RootView` forgets every failure on each change of
  card (`Store.forgetFailures`) and as a level opens, and drops one that lands after its card changed. `Store.card(for:)` is the gate: `RootView.show`
  opens a level past its pack's taste that the player doesn't own as its card over the menu instead, from the level
  before it (a locked row scrolls to buying instead). The last taste level's result card says where its next goes
  ("more in Lens ›"; Jack's call C1 = B, round 13), and every pack level's next is in the pack's colour, owned or not.
  The card that gate opens (`RootView.arrived`, that showing only) is scrolled to buying, under a line for a pack
  never owned (`PackCard.arrival`): "You've played the free three. 22 more in Lens." once every free level has a best,
  else, for a player who skipped ahead, "The first three are free. 22 more in Lens." (Jack's call C1A = B, round 16); a
  refunded owner has only the revocation's line. "try 3 free ›" opens the taste's first level without a best, and is "replay 01–03 ›" once all have
  one (`PackCard.taste`); a locked row scrolls to buying and pulses the pill. VoiceOver follows: a locked row moves
  its focus to the pill, and the gate, once VoiceOver has settled on the screen, to the note (the pill without one). Text follows Dynamic Type (`Font.mono(_ style:)`; the card scrolls and stacks its facts
  and buttons at accessibility sizes, and its clip is no taller than 0.36 of the screen, so buy is on the first screen
  of an iPhone SE; the dock stops at `xxxLarge` and shows a name large on a long press). VoiceOver
  reads each cover's state or price and each button's price, hides the menu under a card (beside the list in a wide window it leaves the menu readable), and announces a change of
  state. Reduce Motion holds the covers and clip still, stills the pending dot and fades the card in.
  **Clip.swift** draws each card's clip live, never a committed video (to-do 50): a `Clip` is one or more `Reel`s,
  each a real level played by a drawn fingertip at `UNSTIR_FINGER`'s pace, every move through `Array.commit` and, on a
  clock, its tick through `Game.tick`, the rule `Game` itself ticks by, so `ClipTests` checks every stack against a real
  `Game`. A frame (`Reel.frame(at:)`) is a pure function of the clip's time, drawn by the level's own views (`Unstirred`,
  `SceneLayer` or `PictureLayer`, `RodView`, `RatchetView`, `ClockHint`, `Bezel`) with the game's heal, push, tick and
  stop rings and its solve wave timed as `LevelView`'s keyframes are; `ClipPlayer` loops it from when it appears, holds
  it at `UNSTIR_CLOCK`, under Reduce Motion holds `Clip.still`, and pauses while the card has it scrolled out of sight
  (`PackClip.seen`), carrying on from the frame it held. A reel that dips is black at both ends, so the
  seam never jumps. First Stir: level 1, the sunrise, healed top first, the time under the tank stepping back with each
  heal (F3) from 6:40 to 6:15 am and a vignette playing with each heal but the first, which leaves rod 1 an entry.
  Lens: level 3 as dealt, its lens newest, dragged down to clean and back up, let go where it began, so it loops with
  no dip on the order read (Jack, CL1). Escapement: problem 2, the mock-up's, in its three moves, its hub counting 3 down to 0. Prism: specimen 1
  in its par of three, the red stir buried under the cyan one first. The bundle (`Clip.cut(of:)`): each of its packs' first beat in turn, the zoom, the tick and
  Prism's red stir coming off, about 8 s, in every build (Jack, CL2; a cut can also take First Stir's vignette, the
  sunrise from just after its first heal, which plays nothing, through its second). Every reel stays drawn,
  the idle ones clear, so a cut never waits on a bake. The dock keeps its covers' own loops (`PackTank`).
- **Achievements.swift** and **GameCenter.swift** hold Game Center's achievements (Jack's call F5 = B, round 14: sign-in
  and achievements, no leaderboards; the list is the pitch's 16, 255 points, awaiting his pick, its pressure flags kept
  and marked `flagged`). `Achievement`'s raw value ends its id (`com.screendead.Unstir.achievement.first-drop`), and
  `AchievementTests` pins every id, title, point and hidden flag as literals: a live achievement can't be deleted nor
  its points changed, so never rename one. Each is earned from what the game already stores, read afresh
  (`Achievement.Record.stored()`: the bests, a clean one anywhere, dailies with a best, `Best.tankTurned`, `swirled`,
  `tanks`), never a counter of its own, so a late sign-in is reported all it has done; the one key kept for them is
  `Best.spilled` (`endless.spilled`), set by a spill that stores progress. Tiers read `isOpen(unlocked: false)`, so the
  developer unlock earns nothing; a pack's needs every planned level with a best, and Whole Shelf the three fixed packs
  (`Achievement.shelf`). Only A Week of Tanks and Brim report a share on the way, and `due` sends only a rise past 0,
  so a hidden one never shows unearned. The build's `GAME_CENTER` (`Config/Unstir.xcconfig`, NO until the sign-in
  overlay test on an iOS 26.2 phone passes) sets Info.plist's `GameCenter`, read as `GameCenter.built`; off, no GameKit
  call is made. On, a plain launch (`GameCenter.plays`: never the harness or the test host) signs in once the menu has
  been up with nothing over it for `settle` (`RootView.calm`, the age check's moment), holding a sign-in sheet GameKit
  hands over until the menu is calm again, hides the access point, loads what Game Center has, and reports after every
  finish and the first turn of the tank or the swirl. It needs the Game Center capability and entitlement, which
  aren't set up.
- **Sync.swift** keeps the bests in step with the player's iCloud key-value store (Jack's call ICLOUD = A, round 16):
  bests, endless's best (`Best.tanks`) and the started flags (`Best.started`) (Jack's calls icloud-endless and
  icloud-started = A, round 16), never the undo bank, its anchor or any other key. The build's `ICLOUD` (`Config/Unstir.xcconfig`, NO
  until the App ID has iCloud's key-value storage, as a device build signing with the entitlement fails to provision
  without it) sets Info.plist's `iCloudSync`, read as `Sync.built`, and picks `CODE_SIGN_ENTITLEMENTS`
  (`Config/iCloud.entitlements` on YES, none on NO); off, no call reaches the store. On, a plain launch
  (`Sync.plays`: never the harness, the test host or the editors' build) reconciles as it starts, on every change iCloud sends (an
  account's change merges the phone's bests into the new account's store, dropping none) and after every best
  `Game` saves, every endless tank cleared and every level's first start. The store holds `bests` (`Sync.key`, pinned: the store takes 1024 keys,
  and the dailies add a best a day), a dictionary of level id to the bytes `best.<id>` holds on the phone, and
  `endless` (`Sync.tanksKey`, pinned), the most tanks cleared, which the higher of phone and store sets on both, and
  `tried` (`Sync.triedKey`, pinned), the ids of every level started on any phone, a union that sync never takes a flag
  out of, so a level tried anywhere reads tried, and its next try is no first try, everywhere. `Sync.reconcile` reads only the
  stored domain, never the harness's registered bests, merges both ways by `Sync.beats` (`Best.standing`, the rank
  `Best.save` keeps: a daily kept on its day before one the archive saved, so a synced archive solve never moves
  `Daily.run`, then clean, then over par; a tie keeps the side's own), stores what the phone takes as the store's own bytes and never writes over a store entry or value it
  can't read. A best that lands makes no card, sound or report: `Best.load`, `Best.tanks` and `Best.started` read
  `Sync.revision` where the build syncs, so every view that shows a best or tried draws again, and the menu re-derives what it keeps (`daily`, `past`, `leading`). Before
  `ICLOUD` turns YES for a release, as its comment lists: the App ID's capability, a two-device test, and the privacy
  policy and store page, which say the bests stay on the phone and that sync isn't built. The editors' build never
  syncs, nor does any phone while the developer unlock (`Best.unlocked`) is on: `Sync.reconcile` reads the unlock from
  the stored domain and then neither reads nor writes the store (Jack's call icloud-editors = A, round 16), so
  progress made with every level open stays on that phone while it is. Clearing the unlock (`UNSTIR_UNLOCK=0`) syncs
  again, and the first reconcile then sends what was made under it with the rest. `run-ios.sh`'s playtests without the
  unlock sync as any build with `ICLOUD` on does.
- **Analytics.swift** holds anonymous counts for Aptabase (the app key names its region, EU or US), behind `Consent`
  (undecided, yes, no; stored as `analytics.consent`). v1 ships without them: the build's `ANALYTICS`
  (`Config/Unstir.xcconfig`, NO) sets Info.plist's `Analytics`, read as `Analytics.built`, and while it is off a plain
  launch never asks, settings has no switch (`Analytics.shown`), `start` leaves the mode off whatever the key, and
  nothing reaches `analytics` or `analytics.consent` (`testABuildWithoutAnalyticsAsksAndKeepsNothing`); the privacy
  manifest declares no collected data, so a build with `ANALYTICS = YES` must declare analytics's three types again.
  The rest of this paragraph is that build. Until yes nothing is queued or sent and no `Sender` exists, and a
  no deletes the queue. `Analytics.configure` runs in `RootView.init`, before `start` (which waits for the store), so
  the question shows as soon as the menu does (after plughole 01 on a fresh install, C4) and an answer given before `start` is stored. **Consent.swift** asks it and holds every
  word it and settings say (`ConsentWords`): on a plain launch while undecided,
  `ConsentCard` covers the menu, which waits for the answer (hidden from VoiceOver meanwhile): a title, one line and a
  link, "What does it send?", that opens and closes the full list of what is sent under it; Yes and No the same
  control, neither preselected. The gear beside the menu's title opens `SettingsSheet`, sized to what it holds:
  "music", "sounds" and "haptics" (`Settings`, stored as `music.off`, `sounds.off` and `haptics.off`, each absent while
  on; Jack's call C17, round 13; a harnessed launch holds them and the letters in memory, `Settings.held`, never
  stored), "colour letters" (`Letters`), "supporter mark" once `Store.bought` (`Settings.supporter`, stored as
  `supporter.off`, on until switched off), the analytics switch (`NeonToggle`, which calls
  `decide`) where the build has analytics, "restore purchases" (`Store.restore`, saying what it found as the cards do),
  "report a problem", a mail (`MailSheet`) to Info.plist's `SupportAddress` with `Log.url` attached as
  `unstir-log.txt` and `UnstirApp.device` in the body, or, with no account in Apple's Mail, `Log.url` handed to the
  share sheet with that subject and body and the address on its first line (with no address, the log alone), and
  "privacy policy", which opens `SettingsSheet.policy` (Apple's guideline 5.1.1(i)) in Safari's view
  (`SafariSheet`): Info.plist's `PolicyURL`, Jack's own domain, or the github.com page of `docs/privacy-policy.md` where
  the build has none, then the version and build ("Unstir 1.0 (1)"); it scrolls, with a large detent, only where
  its content outgrows the screen, or in the tabletop the half lying flat. No ID leaves the phone. `Tally` (stored as `analytics`) keeps the install's local day, the days opened, what has gone out
  once and an undo count; undecided records, a no records nothing and `decide(false)` forgets all of it but the
  install's day (`Tally.forgotten`), so day numbers stay right and a later yes starts clean (re-sending `installed`);
  bests and started flags are the game's own and stay (Jack, 2026-10-26, N). Its `opened` gives `installed` once,
  `returned` with the day number (day 1 the install's) on the first opening of any later day number not yet sent, at
  launch or on coming to the front, so a clock set ahead and back costs no real return, and on the first opening on or
  after days 2, 7 and 30 the newest `snapshot` due, every one due marked sent, so a late yes or a clock jumped ahead
  sends one (Jack, 2026-10-26, K). Days are plain `Best.day`, not `trustedNow`. A level sends `level` (id, `daily` for any daily, outcome solved, lost (Escapement out of ticks) or quit, moves, par (Escapement's budget), undos, resets)
  as it is solved, lost or left for the menu (a lost tank left is no quit); endless sends `run` (spilled or quit, tanks cleared, moves); the sandbox
  nothing. Since resume (C2), a level left unfinished is paused, not quit, as it reopens where it was: the build that
  turns analytics on must say so in `level`'s outcome. A level open as the app leaves the front writes its quit to the tally, which the next launch sends if the app
  was killed. `card`, `taste` and `purchased` go once per pack: `cardSeen` waits for the pack card, `tasteFinished`
  fires once a pack's taste levels all have bests, `purchased` on a verified purchase in `Store.purchase`. The snapshot
  reads the bests, started flags, bank, endless best, dailies solved on the first try, packs owned and the tally.
  `Sender` posts batches of 25 to `/api/v0/events` from `Library/analytics-queue.json`; it is built at launch under a
  yes, so what an earlier launch left queued goes out with no new event to carry it. It keeps a batch on no answer, a
  5xx or 429 and retries a minute later, drops one refused, and drops events over 23 hours old (the server refuses a
  day's). `Sender.body` is everything on the wire: name, props, time, a session renewed after an hour with no event, as
  Aptabase's SDK does (the snapshot its own) and `isDebug` (a Debug or playtest build), `osName`, the app's versions and `sdkVersion`. The server
  takes property keys of up to 40 characters and event names of up to 60, cuts strings at 180, and drops without an
  error, answering 200, an event over a day old or one whose session began over 7 days ago.
- **Spoken.swift** holds what VoiceOver says where the screen shows glyphs, short counts or colour, as pure functions
  the tests read (`testRowsSpeakTheirNameResultAndShape`, `testTheFinishIsSpoken`): each menu row's label ("Level 1,
  ..."; the daily, endless and the sandbox by name), value (its result, "not played", "tried" (started, no best), "run in progress" (endless with a run saved),
  "new" (the daily and endless until either opens), "locked, solve level 6 first", or in a closed tier "locked, par
  every Plughole level first") and hint (its rods and par), the menu's next button (`Spoken.next`: "Next:
  level 2, Drip"), the header's "3 moves, par 7", the tank's value (`tankSpoken`: the same, with endless's brim, "brim 3 of 8", or Escapement's ticks left), and
  the finish ("Unstirred. 7 moves, par 7. Clean.", "Out of ticks on move 9.", "Spilled. 6 tanks cleared.", a completion after it in words: "Lens complete, 25 panels."), which
  labels the result or lost card's summary, where VoiceOver's focus lands as the card shows, so no announcement is cut
  short by a focus move. The pack clip is labelled with its pack's pitch. The tank is one element that allows direct interaction, so a
  VoiceOver user plays it by sight; full play without sight is Eyes Shut's, after v1. The opening's caption is the skip
  button while it shows (`SkipButton`), VoiceOver's escape leaves a level, and the back, undo, reset, next and share
  buttons read as words, not glyphs.
- **Menu.swift** holds `MenuView`. What it leads with follows plughole 01 and 23 (`MenuView.lead`, Jack's call C4,
  round 13): until 01 has a best, the tank's rule as a tagline over the tier's list, with the sandbox under the list;
  then "next: 07 · Sprinkle ›" in the tagline's place, a button opening the shown tier's frontier (none once it has
  none), and the sandbox over the list. The sandbox is out of v1 (Jack's call snd2-sandbox, round 16: it needs
  rethinking, so that a pack's mechanics join it once the pack is owned), as First Stir is: `Level.playsSandbox` is false
  in Release, so there the lead has no sandbox (`Lead.sandbox` nil), the menu no row, `Store.opens` refuses it and a
  harnessed `UNSTIR_MODE=sandbox` opens the menu, while Debug and the harness outside Release keep it, its code, tests and
  shots with it (`testTheSandboxIsOutOfV1`). The daily and endless rows show only once open, each marked new, in plain
  white, until either is first opened (`Best.modesSeen`, `RootView.seesModes`). A row whose level is started
  (`Best.started`) and has no best reads tried, faint, as a pack card's list does (Jack's call C3, round 13; endless
  and the sandbox have none, and a daily left on its first visit stays tried all day, as practice saves no best); the daily's adds "4 days running" (`Daily.run`) to its detail from two. With a run saved, endless's row
  continues it, "continue · tank 6 · brim 3 · best 9" in place of its detail, and "new run" on its title's line in
  place of the best: a first tap arms it, "new run? tap again", for 2 s (`ResetArm`'s; under VoiceOver until focus
  leaves, as reset), the second drops the run and starts another, and a touch that ends a stir does neither. Under the title, a strip names every tier, dimmed with a lock while locked, and
  keeps the picked name in view itself; VoiceOver reads it as one adjustable element. Tapping a name, or dragging the
  list, the strip or the title sideways, stirs the list away round the middle of its visible part with the tank's own shader
  (`Stirred`, one rod, a low plateau), then unstirs the next tier's into place; the title cuts to the new tier's sweep
  at the swap. A drag is the switcher's only if its first 15 points run at least twice as far sideways as up or down
  (`isSideways`); then the list stops scrolling, and a row lifted over doesn't open. While it turns, the list is drawn
  again over the scroll view, cut to its visible part, and that copy is what stirs; the scroll view's own list
  (`listed`) catches up only once the stir has settled, since rebuilding it stalls a frame. At the swap the scroll
  view lands on the new tier's landing, its header while it is locked, or else its top: the copy reports where that
  row lies in its list, a mark in the outgoing list moves there, and the scroll view scrolls to it once it is laid out, so the jump
  happens under the stir's peak. Tapping the picked tier scrolls to its landing. A locked tier can be
  looked at: its rows dimmed and closed, over the gate, a tick per level of the tier below, lit at par, and under the
  ticks the levels short of par as runs (`Tier.short`: "short: 05 · 12 · 21–27"), each a button opening its first,
  which is always open. A closed row
  still takes a tap: it shakes, sounds `seized` and says for two seconds what opens it ("solve 06 to open", or on a
  locked tier "par every plughole level to open"), which VoiceOver reads as its value. Once the player owns a pack (`Store.bought`) and until the settings' switch is off, the title carries the supporter mark (`SupporterMark`; Jack's call M6, round 14, the thank-you, as there is no tip jar): a hairline four-pointed glint after it in the tier's sweep, still, which VoiceOver reads as "Unstir, supporter", and the daily's share line puts the same glyph, ✦ (`Share.supporter`), after its name. The daily's title names its day in the locale's words ("Daily ·
  Sun 1 Nov"; its id stays `daily-yyyymmdd`), and the menu deals it afresh on coming to the front and at midnight
  (`NSCalendarDayChanged`), so a menu left up overnight opens the new day's. The first level without a best (`Tier.frontier`) keeps its
  hairline lit. A hidden stir in
  the background builds the shader's pipeline before the first switch. The pack dock (`PackDock`) is a bottom inset of
  the list, and the card (`RootView`'s, bound in) lies over the whole menu, or beside the list in a wide window
  (`MenuLayout`), or over the trailing half beside a playing level, as the archive does. The list opens centred, unanimated under
  the dip, on `RootView.focus`: the row just left, or after a solve the one after it (`Level.focus(solved:)`, which
  `LevelView`'s exit feeds), and on a launch the tier's landing (`Tier.landing`: the first level without a best, else
  the first short of par, else the top). The daily, endless and the sandbox leave it at the top. That row's hairline,
  in the list's left margin, lights once and fades (not under Reduce Motion). The menu opens on the tier of a level
  of a tier left, and a tier's level opening stores its tier (`Tier.store`, so only an open one), so "up a notch" then
  back lands on the new tier, and so does a launch after the app dies in it. Back from a pack's level, the card over
  the menu opens centred on its row the same way (`PackCard.focus`), but a gate's card opens on buying
  (`arrived`), and `UNSTIR_CARDSCROLL` on the list: arrived first, then scrolled, then the row.
- **Pictures.swift** bakes plughole's neon pictures once per size. They are designed so that "up" is readable inside
  every rigid core. Whirlpool's five (glass, chainmail, coral, neurons, marbling) and their twins (maelstrom's) withhold
  it and are drawn live instead: `PictureLayer` hands each shader the clock mod the picture's `period` (a minute for a
  twin, its heartbeat's loop) and the floats from **LivePictures.swift**, seeded by level. The glass's cells take the
  raw clock; the neural web is static per seed, built once off the main actor. The tank redraws a live picture at 60 Hz, 30 while `Power` saves. Vortex's own family (isobars, ephemeris,
  cords; **VortexPictures.swift**, **Flow.metal**, **Sky.metal**, **Loom.metal**) is drawn live the same way, with no
  twins; the ephemeris's period is 30 s, in which each planet goes round a whole number of times. The sandbox's cycle
  (`Picture.next`) takes plughole's pictures, whirlpool's and then vortex's family, and skips the twins and Lens's
  halftone; its header's two controls read "picture: grid ›" and "rods: 3 ›", or "grid ›" and "3 rods ›" where the
  width is short (`ViewThatFits`); quad and eye, which share a count, add their name ("rods: 4 · eye ›", short "eye ›",
  `LevelView.layoutLabel`). The halftone (**Halftone.swift**) is pure geometry baked a pixel at a time off the main actor: three dot
  screens at one pitch (0.03 tank units) in clean-picture coordinates, so a lens's swollen dots read against the pitch
  outside, and white linework that keeps every core asymmetric (`testEveryStepMovesContrastingPixelsOnTheHalftone`, slow).
  It takes some 20 s unoptimised and 0.9 s optimised on an M2 Max (unmeasured on a phone), so every build keeps it in
  Caches, per size, under the build's number and its executable's timestamp, removing older keys, and logs each bake's
  time. The opening waits for a picture to strike and settle, so a slow bake never winds in over black or through
  the flicker; only one that never lands lets it go on, after 30 s. Prism's plates
  (**Engraving.swift**, `Engraving.Plate`: the fern, seed heads, Haeckel's medusae, Haeckel's radiolarians and a
  nautilus, each a `Picture` of its name) are polylines in tank units, baked through `draw` as plughole's are, in white
  lines only, so a channel out of register shows as its colour and an aligned line is white
  (`testEveryPlateIsWhiteLinesOnBlack`). Each fills the glass and breaks every rotation a core could fall on, so a step
  moves most of the light in every core of every layout (`testEveryPlateShowsAStepInEveryCore`); the sandbox skips them.
  Escapement's plate (`Picture.engineTurned`, drawn by `Picture.engineTurning` in Page.swift) is the packs mock-up's
  engine-turning in ink on bone: ninety straight rays fanned from a point off the glass's lower left, whose cone just
  holds the glass, over barleycorn, upward chevrons on a 0.08 lattice, with no glow and no concentric figure. Its lines
  are at least 2.2 px wide, as the shader's four taps average in squared light, which thins dark lines on a light
  ground, so below a 230 px radius (the dock's 66 pt cover) its lattice and rays' spacing grow with the lines, or the
  ink fills the bone. It fades in over paper rather than striking (`Picture.paper`), and the sandbox skips it
  (`testThePlateIsInkOnBoneAndShowsAStepInEveryCore`).
- **Sound.swift** plays the glass set on an `AVAudioEngine` that only its own queue touches. Effects take a pool of
  twelve players, so quick ones overlap; a heal (`Game.heals`) climbs a note for each move since the level opened or was
  reset that popped one of the scramble's entries (`Game.Entry.pushed`), so cancelling the player's own push is no heal,
  and the heal that solves sounds as the solve. An undo's negation that brings back one of the scramble's entries marks
  it the scramble's again. The `seized` sound plays with `Knock.thud` whenever a finger lands on a knob that can't be
  turned. Escapement's clocks tick in steel, a pawl snapping onto its ratchet wheel (Jack's call soundsk2 = D, round
  16; `ratchet-1` to `-4`, taken in turn as the taps are): each of a move's ticks, pushed or not, sounds, with its
  rigid haptic, as its clock's core starts to turn, `tickBeat` after the lift and `tickTurn` apart (`Game.tickCues`),
  the demonstration's too (Jack's call soundsk-haptic = B, round 16). A tick that pushed lands the error haptic instead,
  and the move's first push sounds the push over its ratchet at the same instant: the first pushed tick's, unless the
  move's own stir pushed at the lift, so later pushed ticks sound only their ratchet (`Game.stirPushed`; Jack's calls
  tk-push = B and tk-multi = C, round 16). The move that solves sounds its ticks, and the solve's chime and success
  haptic land with its last tick, the wave with them (`Game.solveAt`, tk-finish = B); a solve with no tick after its lift,
  or one the fine pass calls past its last tick, lands at once. Either way the chime plays only from
  `LevelView.landSolve`, once, never from the tick's own cue. A move that runs the tank out of ticks plays its ticks
  as any other move does, after the out-of-ticks sound at the lift. One task that leaving
  the level cancels plays them, timed from the ticks' landing (`Game.landed`); an undo or a reset silences the ticks still to come, and a resumed try's last ticks,
  landed before the view appeared, stay silent and still. Beds loop under the menu and each tier (`Level.bed`;
  daily, endless, the sandbox and the packs take plughole's), and a new one crossfades in over the old at equal power
  across two decks. Only a bed that is playing stays decoded, and none in the background.
  `Sounding`, set on `RootView`, is the app's button style: a button taps as
  it acts, and undo and reset have sounds of their own; the undo's body peaks about 0.2 s after the press (Jack,
  SN1). A button that sets its own `.plain` style has none, so every
  such button that acts takes `Sounding` instead: the gear, the consent card's answers and its link, the settings
  sheet's switch and log, the pack cards' and the dock's buttons and the tier-up. The share buttons (the daily card's,
  settings' log without Mail) are `ShareButton`s, which tap and present the system share sheet themselves over
  whatever is in front (`ShareSheet`), as a ShareLink's tap went unheard on a device (Jack's call SND3 = B, round 16).
  The menu's tier names and rows
  stay plain: `go` plays `switch` once as a switch starts, by tap or drag (never as the list follows a level beside it), and a row taps only when it opens, never as
  a tier swipe lifts over it. A bare text button's label, and the play screen's capsules, take `hit()`, which grows the
  target to 44 pt round it without moving anything. Nothing sounds during a drag, and a sound never tells the player anything the picture doesn't. Settings' music switch takes the bed
  out over the crossfade and back (`Sound.music`), its sounds switch every effect and button (`Sound.sounds`), and its
  haptics switch `Knock` and every system haptic, which all go through `haptic(_:trigger:when:)` (or `haptic(trigger:_:)`, which picks the feedback); none of the three is
  read anywhere else. The session is ambient, and while
  another app plays music the bed steps aside and the effects still sound. A harness launch or the test host is silent
  unless `UNSTIR_SOUND=1`. An undo steps the heal notes back, so the next heal plays the undone one's note again
  (Jack, SN1).
- **UnstirApp.swift** holds `RootView` and the `Harness`. `RootView` carries Apple's age-range check (**AgeRange.swift**,
  `AgeCheck`), which the US states' app store laws ask for: on iOS 26.2 and later, where `isEligibleForAgeFeatures` says
  the law reaches the player, it requests the range once a launch while the menu is up with nothing over it (a card,
  the consent question, the settings sheet, whose state `RootView` holds for this), never under the harness or the
  test host, and drops the answer, as every level is for all ages: nothing is kept, logged or sent. It waits
  `AgeCheck.settle` (0.3 s, past the dip) first, and a request cut off by the menu being covered or left leaves the
  launch's ask standing (`testACancelledRequestLeavesTheLaunchsAskStanding`); a failure is dropped and not retried.
  The entitlement Apple's docs require is a HANDOFF item. DeclaredAgeRange links weak, as the app runs from iOS 17.
  A fresh install's first launch opens straight into plughole 01 (`RootView.opening`, Jack's call C4, round 13), once:
  `Best.welcomed` is stored as it appears, so a player who backs out without a move gets the menu next time. Never
  under the harness or the test host, but `UNSTIR_FRESH=1` takes that first screen, settings line and all, without
  storing it. While a back swipe slides a level off, `RootView` draws the menu under it (`LevelView.onPeek`,
  `RootView.peeking`), focused as leaving would focus it, first in its `ZStack`, so the menu uncovered is the one that
  stays up. The harness
  reads `UNSTIR_*` environment variables at launch
  (passed as `SIMCTL_CHILD_UNSTIR_*` by the scripts). They pick a screen, tier (`UNSTIR_TIER`, which the menu opens on
  even when locked), level, mode, stack, lens slots (`UNSTIR_LENSES=0,2`, parsed before the stack, which they change), channel masks (`UNSTIR_MASKS=0:r,1:c`, the same, never the swirl; `UNSTIR_SWATCH=r` holds a Prism swatch, `UNSTIR_LETTERS=1` shows the colour letters and swatches, and `UNSTIR_LETTERSCHOICE=0` or `1` sets the settings' choice for the launch), seized knobs (`UNSTIR_SEIZED`, never a swirl, so `UNSTIR_TIER=vortex UNSTIR_LEVEL=1 UNSTIR_SEIZED=1` opens a level with both) or tank position (`UNSTIR_TANK`), and can hold a
  mid-drag turn of a rod (`UNSTIR_LIVE`) or the tank (`UNSTIR_TANKLIVE`), a finger just down (`UNSTIR_TOUCH=x,y` in tank
  units, run through `LevelView.grab`; with a held turn, where that finger went down), a turn just let go and still open
  (`UNSTIR_TURNED=rod:steps`), endless's brim (`UNSTIR_BRIM=n`, never stored), a touch on a seized knob held that
  many seconds into its shake (`UNSTIR_SHAKE`, with `UNSTIR_TOUCH`), the solve wave (`UNSTIR_WAVE`, solved by the reachable seams, or by `UNSTIR_PLAYED`'s line where one is given, as Escapement's clocks need), autoplay or a frame-time bench
  (`UNSTIR_BENCH`). `UNSTIR_PACE=s` sets autoplay's and `UNSTIR_MOVES`' wait before each move (0.3 s unset), and
  `UNSTIR_BARE=1` draws the picture unstirred, so a story's art shows as the stack has played it. `UNSTIR_CLEAN=1` draws a level as its glass and picture in the bezel alone, for App Store art that may show no interface (the Today card's video): the header, title, caption and notes, controls, swatches and cards are kept in the layout but not drawn, so the tank stays where `film.sh` crops it, and nothing else over the glass is drawn (knobs, dials, dashes, counts, rings, lessons, the knurl, the brim, the stamps and the drawn fingertip), nor the status bar or home indicator; the picture still turns, winds and waves as played. `UNSTIR_ENDING=s` with `UNSTIR_SCREEN=clean` opens First Stir's last scene solved with the night forwards held s seconds in (-1 runs it). In Debug, `UNSTIR_PACK=lens` opens that pack's level `UNSTIR_LEVEL`, or past its levels a placeholder, which keeps no
  best or started flag (`Level.keepsProgress`); Prism's is tri on the fern, rod 0 red and rod 1 cyan, dealt
  `2:+3,0:+4,1:-3`, as specimen 1 is. And
  `UNSTIR_OWNED=lens,complete` and `UNSTIR_STORE=lens:pending,complete:revoked` (or `lens:unshared`, revoked as a family's share) set the store's states for the launch
  in place of StoreKit's, never stored, with the StoreKit file's prices, in dollars (none with `UNSTIR_PRICES=0`, as while they load, or `UNSTIR_PRICES=unreachable`, as after a failed fetch);
  `UNSTIR_FAILED=offline` (`storefront`, `refused`) says why a failed product failed, or a pending one's ask again, `UNSTIR_PAYMENTS=0` turns
  purchases off, and `UNSTIR_RESTORED=lens,prism` (`none`, `failed`) sets what the last restore found;
  `UNSTIR_APPROVED=lens` (or `complete`) has that Ask to Buy approval wait to be said (held under `UNSTIR_CLOCK`), and
  `UNSTIR_SEENLEVELS=lens:20` has that pack's card last opened when it had 20 levels, for the launch only.
  `UNSTIR_CARD=lens` (or `complete`) opens that card over the menu; in Debug `UNSTIR_CARDLEVELS=n` lists n placeholder
  levels on a pack's card while it has none, and `UNSTIR_CARDSCROLL=1` opens it scrolled to its list; `UNSTIR_BESTS`
  takes a pack's prefix as it takes a tier's, and `endless:9` the run's best. A pack level past
  the taste needs `UNSTIR_OWNED` too, or it opens the card. `UNSTIR_STOPLOOK=left` picks how an Escapement tank out of
  ticks as its last clock stops looks. `UNSTIR_SHELFDEMO=1` opens Lens's card from the dock and closes it, `UNSTIR_LANDS=s`
  buys the open card's product s seconds in (with the store's states set), `UNSTIR_PROMOTED=lens` (or `complete`)
  starts a promoted purchase of it a second in, `UNSTIR_PROMO=lens` shows that offer's promoted-purchase image alone,
  `UNSTIR_SUPPORTER=0` switches the supporter mark off for the launch, and
  `UNSTIR_TYPESIZE=accessibility5` sets Dynamic Type (a `DynamicTypeSize` case). `UNSTIR_MOVES=-1:-1,1:-8` plays a line of moves at autoplay's pace, each a knob's turn or the
  tank's (rod -1) in `parse`'s rod:steps form, a ratchet's turn a tap on it (a wait); `UNSTIR_PLAYED` commits such a
  line through the real path as the level opens, for stills; with `UNSTIR_FINGER=1` it rests `UNSTIR_REST` seconds (2 when unset), then plays at a hand's
  pace, each move by a drawn fingertip that lands where `grab` gives it the move's rod or the rim and rides the turn
  round, for films. `UNSTIR_PAR=n` sets a stack's par. `UNSTIR_CLOCK` also holds the rim,
  knob and lens lessons' ghost fingers, a refill's "+2", and endless's brim that many seconds after its last change (a spill's too),
  and it holds the swirl's breath at 0. `UNSTIR_BREATH=s` holds the breath s seconds into the tank's first rest, whose
  first slosh starts at 1.5 s, for stills, even under `UNSTIR_CLOCK`, and never with `UNSTIR_SWIRLED=1`, which has none. `UNSTIR_BRIMDEMO=1` plays the approved film's run of the brim through the same calls a finger makes: two heals, then
  pushes until it spills. `UNSTIR_RESETARMED=1` holds the reset control armed, "reset? tap again". `UNSTIR_REVIEW=log` logs the rating request in place of making it, as a plain launch would make it. `UNSTIR_NOW=HH:mm` sets the clock the daily's card reads the next daily from. `UNSTIR_RESUME=2:+5,0:+2,u,1:+3` is the harness's one save, for the launch, so whatever a plain launch left stored never reaches a shot: the level's try with that line (`UNSTIR_MOVES`'s form, plus `u` an undo and `r` a reset), so it opens resumed, and with `UNSTIR_MODE=endless` `UNSTIR_RESUMETANK=n` puts the saved run on tank n (from 0; empty `UNSTIR_RESUME` is the run with no move yet), which the menu's endless row continues. `UNSTIR_UNDOS=n` sets the undo bank and `UNSTIR_TODAY=yyyy-MM-dd` the day the level opens on;
  a harnessed launch never stores the bank, the refill's day or its anchor, and with `UNSTIR_TODAY` and no day stored it
  takes the last refill as long ago, so the level opens on a refill. Nor does it store the tank flag or the swirl's: they
  read as never turned unless `UNSTIR_TANKTURNED=1` or `UNSTIR_SWIRLED=1`, and whatever the launch turns lasts only that launch. Nor
  does the harness's level store a best, a started flag or endless's best (`Game.storesProgress`): a solve registers
  its best for that launch only, as `UNSTIR_BESTS` does, so the menu it exits to sees it. So shot order never
  matters. For the menu, `UNSTIR_BESTS=plughole:0001,...` registers bests for that launch only (a digit per level, that
  many over par; `-` for none), `UNSTIR_TIERSPIN=angle:fade` holds the list mid-stir and `UNSTIR_TIERDEMO` switches
  tiers through the same calls a finger makes. `UNSTIR_EXIT=left` leaves the harness's level for the menu a second
  after it opens, through `RootView`'s own exit (`=solved` as its result card does after a solve; `=up` opens the next
  tier's first level, as "up a notch" does, then leaves that; `=swipe` leaves through the back swipe's commit).
  `UNSTIR_BACKSWIPE=0.4` holds the level that share of the way into a back swipe, the menu under it, and `=run` plays
  the swipe a second in by a drawn fingertip. `UNSTIR_LOCKTAP=L8` holds that closed row as a tap
  leaves it, saying what opens it. `UNSTIR_PICK=L12` picks that level (a tier's or a pack's, by id) a second and a half
  in, as its row would, the harness's flags carried over (beside play, the playing level leaves for it), and
  `UNSTIR_PICK=archive` opens the archive then, as its row does. `UNSTIR_TRIED=L14,lens-2` reads those levels as started, and `UNSTIR_DAILIES=n`
  today's daily and the n-1 days before it as solved at par (so the modes' rows as seen), for that launch only.
  `UNSTIR_ARCHIVE=1` opens the archive over the menu, `UNSTIR_ARCHIVED=1:c,3:0,6:2,9:t` gives the daily that many days
  back a best from the archive (clean, that many over par) or a try, and `UNSTIR_MODE=archive UNSTIR_DAY=n` opens the
  daily n days back from the archive. `UNSTIR_ICON=n` shows app-icon candidate n alone. `UNSTIR_FRAME=951x669` lays the app out in a window of that size, shrunk to fit the simulator, with `UNSTIR_INSETS=top,leading,bottom,trailing` as its safe area: the iPhone Duo's inner display, which no simulator can be driven to headlessly (`HarnessWindow`; the system's bars are not drawn; `duo-*` shots). `UNSTIR_FOLD=x,y,w,h` (window points) folds it there, standing in for the system's division region, and draws the fold as a grey band. `UNSTIR_THEN=s` changes pose s seconds in, to `UNSTIR_THENFRAME`, `UNSTIR_THENINSETS` and `UNSTIR_THENFOLD` (each the first pose's unless given; `none` lies it flat), as opening, closing or folding the phone would; every pose is drawn at one scale. In a build with
  analytics, `UNSTIR_ANALYTICS=log` writes each analytics event to the flight recorder instead of sending it, as if the player had said yes, and stores no consent or tally; like
  `UNSTIR_UNLOCK` it leaves the launch otherwise a plain one, and `scripts/run-ios.sh` passes it to the phone.
  `UNSTIR_TAPS=n` pins the level's four-tap budget at n, `=watch:n` pins it and logs every drag's frames, and `=adapt`
  runs `Taps`' law from the glass's static limit keeping nothing (`=adapt:n`, from n), in any build; a value it can't read
  draws the static limit. It too leaves the launch a plain one
  and `scripts/run-ios.sh` passes it. For it on the phone, `UNSTIR_TAPDRAG=n` drags the first working knob n times,
  4 s each, through the real let-go, each landing a step, alternately each way; `UNSTIR_TAPSTALL=ms` busies the main
  thread that long every half second of a drag; and `UNSTIR_DEEP=n` cuts the level's stack, or repeats it as it
  stands, to n entries, a full stack at most, without merging where the copies meet. Under
  any other harness flag analytics is off and the menu never asks, unless `UNSTIR_CONSENT=ask` (or `=sends`, which
  opens the card's list); `UNSTIR_CONSENT=yes`
  or `=no` answers for the launch, never stored; in any build, `UNSTIR_CONSENT` alone draws the card and the switch, and `UNSTIR_SETTINGS=1` opens the menu with the gear's sheet up (in Debug `UNSTIR_EDITORS=1` shows the editors' switch in it) (`UNSTIR_MUSIC=0`, `UNSTIR_SOUNDS=0` and `UNSTIR_HAPTICS=0` set its switches off for the launch). `UNSTIR_UNLOCK` alone
  is the developer unlock above; alongside any other `UNSTIR_` variable, leaving it unset clears it, so no shot leaves
  the next unlocked. Any other `UNSTIR_` variable also silences the launch, as the test host is silenced, unless
  `UNSTIR_SOUND=1`. This is how screenshots and films
  are taken without touch; see `scripts/shots.sh` for examples. To show a visual change, add a `shot` line there.
- **UnstirTests/Solver.swift** plays turning-tank levels for the tests and `scripts/solve.sh`; it never ships in the
  app. It has three players, whose moves count as `Game.history` counts them (`Play.count`). The optimum is the fewest
  moves that empty the stack: a breadth-first search over (stack, tank position) that untwists whole seams and turns
  the tank (only where `turns`, the level's motion, says it turns: by default wherever a knob is seized; the rules of thumb
  below always turn when blocked, as they are defined only for turning tanks), then a search
  for anything shorter with detours (a push or partial merge can build a word that holds a
  disc still, and save a move). It tries only the detours its class comment lists, so it is a bounded search, not a
  proof; `exhaustive` checks it on small cases. Its pruning reads which rods interact (`interacts`: discs that overlap
  and maps that fail to commute, judged by the maps), so a swirl interacts with every rod but hex's hub, which shares
  its centre; whether a word commutes is still `Layout.commutes`'s call. `Solver(layout, lenses:)` maps a lens's slots
  as the game does, so on tri a lens interacts with both its neighbours, and two lenses, whose cores never meet, never
  interact. `Solver(layout, masks:)` takes Prism's masks the same way: two rods whose masks share no channel never
  interact, and `parts`, which maps the whole picture, steps aside under masks, so every overlap goes to
  `Layout.commutes`. The swirl is a slot like any other, held at
  every position and never seized. With no knob seized, as on every vortex level, the tank never turns, so every
  player untwists and the planning gap is 0: there the solver's job is the optimum, and whether a detour beats
  untwisting. The park rule (`park`) untwists the newest whole seam a working knob
  reaches; when none is, it turns to a position where one is, choosing by where the seized knobs land (`Parking`:
  `.fewest` or `.all`), then the nearest. The rule has no tie-break (Jack's call): `parkTies` gives its fewest and
  most moves over every way its ties go, and `park` breaks them by `Tie` (`.clockwise` or `.lowest`) only to name one
  play. No lookahead (`noLookahead`) turns to the nearest, clockwise on a tie. A level is fair when the park rule's
  most moves over its ties is the optimum under both parkings; its planning gap is no lookahead minus the optimum.
  `home:` asks for the tank back at 0, the old end rule. Several tests replay plays on a real `Game`, which must empty
  the stack in the moves the play counts. Escapement's prover (`Solver.escapement`) is a breadth-first search over
  stacks where a move is a wait or one commit to a working slot, by ±1 to ±11 or an entry's exact inverse, then the
  clock's forced tick, a line dropped where that tick pushes or stops the clock with twists left (lines that can only run
  out of ticks); the same slot may be
  stirred twice running, as every let-go is final. So its first line is a fewest, and no shorter line exists among
  those counts: the proof each problem ships with. `Move.wait` is its tap.

Many tests are regressions from real play (e.g. `testWhirlpool11UnstirsToEmpty`, `testVisibleSmudgeIsNotSolved`).
Others check the level tables against the design tables (par, inversion counts, whirlpool's and vortex's pictures).
