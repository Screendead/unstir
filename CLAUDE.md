# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Unstir is an iPhone puzzle game (SwiftUI + Metal, iOS 17, Swift 6, portrait only). Rods under a tank of picture twist
it; the player unwinds the scramble by turning rods back in the right order.

## State and the current task

This file holds how the code works. `HANDOFF.md` holds the current task: the plan, where it stands, open thoughts,
and the options set aside with their reasons. Read it and `HANDOFF.private.md` at the start of a session. Update it when a step closes or Jack
makes a call, and keep its "Set aside" entries (note when one is picked back up). If the two files disagree about
state, `HANDOFF.md` wins. Record a recommendation as a recommendation until Jack decides it.

## Git, pull requests and CI

- **Branch and PR for every change.** Never commit to `master`. Jack has given standing permission to create branches
  and open PRs without asking.
- **Jack reviews at the PR.** When a feature or a round of ideation is finished, commit it and open the PR without
  asking first (Jack, 2026-09-28). Don't commit partway through the work.
- **Atomic commits.** Changes that belong together go in one commit. Separate changes go in separate commits, even when
  that means splitting one file's diff line by line (`git add -p` is interactive, so build the partial patch and use
  `git apply --cached`).
- **Merging.** Jack holds merge authority. Once he has seen the diff, a spoken OK from him is enough approval for Claude
  to merge the PR. Claude may also merge without asking (Jack, 2026-10-25) once CI passes, a check of the diff, commit
  messages and PR text finds nothing personal, and Claude is satisfied with the diff's quality; a PR that rests on a
  call Jack hasn't made still waits for him.
- **Push only when a build is needed.** `.github/workflows/test.yml` runs only on `pull_request` events: when a PR
  is opened, reopened or pushed to. It skips pushes that change only `*.md` files, and it stops any run at 10 minutes.
  Pushing to a branch with no open PR builds nothing. `test.yml` caches the StoreKit test build (`build/store`) between
  runs, keyed on the Xcode build and a hash of `project.yml`, `Sources/`, `UnstirTests/`, `StoreKit/`, `Config/`, the workflow and
  `scripts/test-store.sh`, so a file that sets the build's flags goes in that list. Checkout gives every file a new
  inode and the current time, so the job stamps each tracked file with a time drawn from its content and tells the
  build system to ignore inode changes; the restored build then stays incremental. A hit saves compile work but not
  time: `xcodebuild test` boots the simulator while it compiles, so the job's time is the boot, about 110 s, and the
  tests, about 45 s.
  `.github/workflows/codeql.yml` scans the workflows on every PR to
  `master`, `*.md`-only ones too, in case the `master` ruleset requires code scanning. It scans Swift, which takes
  about 18 minutes, only on pushes to `master` (only merges make them) and weekly. Never add a `push:` trigger for any
  other branch: it builds every push, PR or not. Keep
  commits local until the next build is worth paying for. If a build takes more than
  7 minutes, raise it with Jack: the approach to builds needs rethinking.
- **Watch CI spend.** Before each push that builds, run `scripts/ci-usage.sh`, which prints this month's GitHub Actions
  allowance left. Tell Jack when 50% is left, and warn him urgently at 25%. Public repos, this one included, don't
  use the allowance. macOS minutes in private repos count 10×.

## Keep the repo free of personal details

The repo is public. Nothing personal or confidential goes into a tracked file, a commit message or a PR: no device
UDIDs, account or membership status, money, usage history, email addresses, local paths or anything else about Jack
beyond his first name, except his full name in the copyright line below. Such notes go in `HANDOFF.private.md`, which
is gitignored and exists only on this Mac. Machine-specific values come from environment variables. Before committing,
check the staged diff for personal details.

Every `.swift`, `.metal` and `.sh` file opens with `Copyright © 2026 Jack Lusher. All rights reserved.` as a comment,
after a script's shebang. The code is all rights reserved: never add an open-source licence.

## Pushing back

Claude is the implementer under Jack's supervision and also the project's advisor. Jack has asked for pushback,
hard if needed, whenever an idea of his looks wrong. Say so plainly, give the reasons, and propose something better.
Once Jack has heard the argument and still decides, carry out his decision.

## Commands

`project.yml` is the source of truth for the Xcode project; the scripts run `xcodegen generate` before building, so
edit `project.yml`, not `Unstir.xcodeproj`. Build products go to `build/` (gitignored).

- Build: `scripts/build-ios.sh [Debug|Release] [device|sim]` (defaults to Debug, device; prints only errors, warnings and the result).
  It passes the shell's `APTABASE_KEY`, Aptabase's app key, into Info.plist's `AptabaseKey`, over
  `Config/Local.xcconfig` (gitignored), which `Config/Unstir.xcconfig` includes for Xcode's own builds and archives;
  with neither analytics is off. `ANALYTICS_PLAYTEST=YES` sets Info.plist's `AnalyticsPlaytest`, which files a Release
  build's events as Debug.
- Install and launch on the reference phone: `scripts/run-ios.sh [Debug|Release]` (needs `UNSTIR_DEVICE`, the phone's
  UDID, set in the shell). Every build it installs is a playtest, so Jack's own play never lands in real players'
  numbers (Jack, 2026-10-27). `UNSTIR_UNLOCK=1 scripts/run-ios.sh Release` also opens every tier and level on the phone
  until a run with `UNSTIR_UNLOCK=0`.
- Tests (XCTest, on a simulator):
  ```
  xcodegen generate --quiet && xcodebuild test -project Unstir.xcodeproj -scheme Unstir \
    -destination 'platform=iOS Simulator,name=Unstir iPhone 17 Pro Max' -derivedDataPath build CODE_SIGNING_ALLOWED=NO
  ```
  To run one test, add `-only-testing:UnstirTests/UnstirTests/testPush`. The solver's tests that take seconds skip
  unless `UNSTIR_SLOW_TESTS=1` reaches the runner, which CI never sets: put `TEST_RUNNER_UNSTIR_SLOW_TESTS=1` before
  `xcodebuild` to run them too (about a minute and a half more).
- StoreKit tests: `scripts/test-store.sh [xcodebuild args]` runs the tests with `StoreTests` on, as CI does. They
  skip under `CODE_SIGNING_ALLOWED=NO`, since storekitd refuses a test session for a host app without
  `get-task-allow`; the script signs ad hoc with `StoreKit/Test.entitlements` into `build/store`.
- Solver: `scripts/solve.sh <layout> <scramble> [seized knobs, comma-separated]` (e.g. `quad 0:+3,2:-4 0`; a swirl
  layout by its name, `quadSwirl`, its swirl never seized) prints the optimum (and what untwisting alone takes when a
  detour beats it), the park rule's fewest and most moves over every way its ties go under each parking, fair or over
  by the most, the no-lookahead count and its planning gap, then the optimal moves, one commit or turn each. It
  compiles `build/solve` with `swiftc` when a source has changed, from Twist.swift, Solver.swift and `SplitMix64` cut
  out of Levels.swift, so that struct stays top-level there.
- Vortex's levels: `scripts/vortex-levels/pools.sh <dir>` deals seeded scrambles on the swirl layouts with the frozen
  generator through `scripts/vortex-levels.sh search` (built like `build/solve`, with the generator cut out of
  Levels.swift too), keeping those whose optimum is their entry count, one TSV per band; `scripts/vortex-levels/pick.py
  <dir>` picks the table from them by its slots. `scripts/vortex-levels.sh check <layout> <scramble>` measures one row.
- Plughole's levels: `scripts/plughole-levels.sh table` measures every plughole level in Levels.swift (entries, the
  solver's optimum, hidden stirs, rings whole as dealt, right moves per step and forced steps over the untwist, each
  right move taken as equally likely); `check <layout> <scramble>` measures one, and `search <layout> <depth>
  <inversions> <from> <to>` deals seeded scrambles with the frozen generator, keeping those whose optimum is their
  entry count. It builds `build/plughole-levels/measure` like `build/solve`.
- Screenshots: `scripts/shots.sh [pattern]` builds for a Pro Max simulator, launches each harness case and writes
  `shots/<name>.png`, with a description of each in `shots/index.txt`.
- Films: `scripts/film.sh [pattern]` records animations to `shots/film/*.mp4` with a frame strip each (needs ffmpeg).
  Both take the first simulator named "Pro Max", or the one whose id `UNSTIR_SIM` gives.
  Git ignores `shots/` apart from `index.txt`: show pictures and films in a PR by attaching them to a comment through
  Chrome (GitHub has no API for attachments; videos under 10 MB), never by committing them.
- App icon: `scripts/shots.sh icon-` shoots each candidate (`UNSTIR_ICON=n`, `IconView` in Icon.swift), then
  `scripts/icon.sh [n]` crops them to `shots/icon-n-1024.png` without alpha, lays them out at 1024, 180 and 60 px on a
  dark and a light home screen in `shots/icon-candidates.png` and, with n, makes candidate n the app icon (needs Pillow).
- Picture lab: `scripts/picture-lab.sh render <picture> <out.png> [seed] [t] [side px] [layout stack]` draws a live
  picture on the Mac's GPU, stirred by a stack if given; `scripts/picture-lab.sh bench <picture>...` times each
  picture's fill against the glass and a stack entry of four-tap work. It knows the glass and vortex's family, and
  builds `build/picture-lab/lab` with `swiftc` from Twist.swift, VortexPictures.swift, `SplitMix64` cut out of
  Levels.swift and `Picture.cells` cut out of LivePictures.swift. The Mac's GPU clock wanders: read the
  scaled-to-glass column over a few runs. `scripts/vortex-family-sheet.py` lays the `vortex-family-*` shots out as
  one sheet (needs Pillow).
- Workflows: `actionlint .github/workflows/*.yml` (Homebrew's `actionlint`) before pushing a change to one.
- Device log: `scripts/pull-log.sh [--sim] [dest]` copies `Library/unstir-log.txt`, the flight recorder written by `Log.write`.
  Each touch logs what it holds and where it landed, and each drag one line when it ends: its path in tank units from
  the landing to the lift, with ms since the drag was taken up (usually the landing), thinned by `Trail` (a twist logs
  its rotation), so a pick or turn can be checked against the finger.

## Architecture

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
  frozen generator never deals one and the sandbox never cycles to one.
- **Unstir.metal** is the GPU copy of the same map. It turns the sample point back by the glass's `turn`, then applies
  the stack's inverses to sample the picture. The tests only reach the Swift copy (`Tank.profile`/`Tank.twist`), so
  change the two together. The turn has no Swift copy: only the `seized-*` shots pin its sign against `Layout.behind`.
  The shader's tap count and the `Tank.maxStack` (36) and `Tank.fourTaps` (30) limits are tuned against 120 Hz on an
  iPhone 13 Pro Max, before the turn was added; its cost per tap is unmeasured. A live picture's own cost comes off the
  four-tap limit as `Picture.fillEntries`, scaled from Mac GPU costs and unconfirmed on the phone.
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
  and the card follows at `Brim.card`. The tests reach only the Swift side.
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
  prototype and is frozen: every past daily is its output, and `testDailyVectors` pins them. Endless changes only what
  it asks for (`Level.endless`: tank n has 5 + 5n/4 stirs up to 28, at least n/2 of them hidden, to half), which
  `testEndlessVectors` pins. A `Run` is endless's seed, tank and the brim's notches as that tank opens. Progress
  (`Best`, started flags, undo bank) is kept in `UserDefaults`. The undo bank (`Best.undos`, 10 at most) refills by 2
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
  launch logs whether the session was read, the uptime and `kern.monotonicclock`. A `Level` has a `motion`, what the rim
  holds to carry the knobs round without a stir (`.none`; `.tank`, maelstrom's; `.crank`, charybdis's planets, not
  built), and a kind per knob (`kind(of:)`, from its `seized`, `sockets` and `ratchets`): a working knob stirs, a seized
  one or a socket refuses touch, and a ratchet is Escapement's clock. Every level today turns its tank exactly where a
  knob is seized (`testTheRimKeysOnMotionAndADiscOnItsKind`), and `UNSTIR_SEIZED` sets both. `par` is `fixedPar`, else
  `scramble.count`.
- **TankView.swift** holds `Game`, the per-level state: stirs, moves against par, undo, clean-solve rules and
  endless's brim, which the rim shows (the header shows moves, and the title the tank). `Game.commit` takes a physical
  knob and commits to the slot under it. Endless has no par, undo or reset: each red flash (a `.pushed` commit) adds a
  notch to `Game.brim`, each of the scramble's entries that pops settles one (the heal's `.cancelled` commit, or a push
  that the heal lets fall cancelling it), and at `Run.room` (8) the run spills. The stack's entries mark the player's
  pushes (`Game.Entry`) so that cancelling one is no heal, and flashes white as a merge does rather than the heal's
  magenta ring and heavy tap, which in a run mark only a commit that pops one of the scramble's entries; a win the fine pass calls also settles one, as the tank's
  last heal, while one of the scramble's entries is left and unless its move healed one. `Game.nextTank` carries it to
  the next tank. `Game.turnTank` is a move that pushes no entry: turns in a row join, and one netting a whole turn
  drops. The result card of a tier's last level goes up a notch (`TierUp`): the next tier's name in its own sweep, glowing, opening its first level, or dimmed with a lock while that tier is closed, going back to the levels. `Game.history` holds rod stirs by slot and
  tank stirs as rod `Game.tank` (-1), so an entry is not always a rod index. It also holds `LevelView` (drag on a knob →
  live twist → `Game.commit` on lift; where the level's motion is the tank, a drag on the rim or a two-finger twist → live tank turn →
  `Game.turnTank`), the `Unstirred` shader modifier and the result card. `LevelView.grab`, a pure function, decides what
  a finger holds where it lands, never by its motion: the rim first, else the disc whose centre is nearest in its own
  radius, overlapped or not, never the swirl; a seized winner or a socket is `.seized`, which holds nothing, and a
  ratchet `.ratchet`, which holds nothing and on lift calls `Game.wait`, a stub until Escapement's tick. The rim, from
  `LevelView.rim` (0.93) out over the bezel, holds the level's motion where it has one and the swirl where the layout
  has one. Where it has both, the swirl holds the glass's own edge from `swirlBand` (0.86) and the motion the bezel and
  beyond. The rim lesson, the knurl, the bezel's hit area and the two-finger spin key on the motion, and touch on the
  knob's kind. The swirl has no knob: its dial is drawn just inside the bezel, as the tank's is. The held rod
  lights at once with a light tap, so the rod that lights is the rod that turns: its knob's ticks and a ring on the dark
  band round it, never past it, and one 0.5 pt hairline round its disc, dimmer until letting go would commit. On lift
  the disc's hairline flashes and fades, a twist that stacks an entry flashes the knob's ring red (the swirl's, a hairline `swirlFlash`, 5 pt, inside the glass's edge), and one that cancels
  sends a magenta hairline out from the knob. Every line a turn draws over the picture is a hairline but the count's
  dashes, 2 pt, and none has a glow or a dark band under it: the pictures are fine lines themselves, and whatever a
  heavy line covers the player cannot read. The opening replay's ring is not a hairline. A
  seized knob touched shakes a few degrees, plays `Knock.thud` (duller than the tank step's `Knock.clunk`) and pulses
  the rim's lesson: `RimLesson`, a two-headed amber arc just outside the bezel at the top and a ghost finger rocking
  along the rim under it, shown on any level whose rim turns the tank until the player's first turn of the tank commits. That
  turn sets `Game.tankTurned` and the stored flag (`Best.tankTurned`) behind it, on every level; a rod stir never does.
  The lesson never shows a way to turn, and after the flag only the pulse brings the arc back. A level with a swirl
  shows its own lesson the same way until the player's first stir of the swirl commits (`Game.swirled`,
  `Best.swirled`): a thin cyan arc at the bottom 10 pt inside the glass's edge, seated on a dark stroke
  and without the tank arc's glow since it lies on the picture, and its ghost finger there, in the middle of the
  swirl's grab. So on a level with both, each lesson points at its own ring: the tank's at the bezel, the swirl's
  inside the glass. It goes while the swirl is held. The lessons go once learnt, so two standing cues keep saying
  what the rim does. `Knurl` mills the bezel wherever the rim turns the tank: dark grooves between ridges every 4 pt or so,
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
  (`Detent.steps`, the nearest step). Each change of that, at a half step either way, clicks: the rod's tick, the tank's
  clunk. While `Game.openStir` is the rod's, the hairline, its dashes and the count stay faint after lift, until another
  rod or the tank is touched; they read only the history, never the stack. Wins run the coarse `looksSolved` pass on the
  main actor and the fine pass off it. `Game.refill` runs as `LevelView` appears, never in `Game.init`, which SwiftUI
  reruns for a level already on screen on a game it then drops; a refill shows its "+2" over the undo count for three
  seconds once the opening ends or is skipped, as the control comes live, and not again on a reset.
- **Pack.swift** and **Store.swift** hold the paid packs, outside the tier ladder: `Pack` (First Stir, Lens,
  Escapement) has a name, a level-id prefix (its raw value: `lens-1`), a product id, a free taste of 3 and, until its
  content lands, no levels: `Pack.levels` reads `Level.firstStir`, `Level.lens` and `Level.escapement`, numbered from
  1 by place under `Pack.id`; a `Level` names its `pack`. A pack's undo spends the shared bank like any other, but
  puts back the stack as the move found it, marks and tags and all, from `Game`'s snapshot of the stack as each stir
  began; the free tiers' commits the stir's negation (`testAPackUndoPutsTheStackBackWhole`). No pack best ever opens a tier. `PackTests` pins every stored
  level id, product id and storage key as literals, so never rename one. `Pack.access` says whether a level plays: the taste
  always, past it only a pack StoreKit grants, with `Best.unlocked` and the harness counted outside Release only.
  `Store` is StoreKit 2 with no server and nothing stored: entitlements from `Transaction.currentEntitlements` at
  launch, a `Transaction.updates` listener (Ask to Buy approvals, refunds, other devices, Family Sharing),
  `purchase` and `restore` (`AppStore.sync`). Only a verified transaction grants; Complete (`Pack.completeID`) grants
  every pack, and a revocation takes back only what that product alone granted. `Ledger` keeps each product's
  `Purchase` (unowned, owned, pending, failed, revoked). A revoked pack keeps its bests; past the taste it needs the
  card again. `StoreKit/Unstir.storekit` sells each pack and Complete as family-shareable non-consumables at
  2.99 a pack and 5.99 for Complete (Jack, 2026-10-25); the scheme's run action and `StoreTests` use it. Prices are
  never the app's own: `Store.prices` holds each product's `displayPrice`, fetched at launch and again when a card
  opens without one, and a card with none says "buy" alone.
- **Shelf.swift** holds the shelf (Jack's pick, round 3, S2: a dock of live covers) and the cards. `Offer` is a pack or
  Complete, with its card's words and colours. `PackDock` sits at the bottom of the menu with a cover per offer on
  `Offer.shelf`: in Release a pack only once it has levels past its taste and Complete only once every pack is there
  (Jack, 2026-10-26, S1), so today none and no dock; outside Release every cover (`Cover`, drawn in code in each pack's look until it has art) stirred and unstirred by the tank's own shader
  (`Swirled`) on a 7 s loop, each out of step, at 30 Hz, paused under a card, a dot for its state. `PackCard` grows out
  of its cover: the clip (`PackClip`: `<key>-clip.mp4` from the bundle once filmed, else the cover's loop), what it
  assumes, the taste, holds (`Pack.planned`), "More levels arrive in an update." while any of its levels aren't in, the
  purchase state, buy at the App Store's price, try free, Complete beside an unowned pack while Complete is on the
  shelf (its own failure said under it, never as the pack's), restore, then the pack's levels, those past the taste
  locked. A failed attempt shows only on the card it was made on: `RootView` forgets every failure on each change of
  card (`Store.forgetFailures`), and drops one that lands after its card changed. `Store.card(for:)` is the gate: `RootView.show`
  opens a level past its pack's taste that the player doesn't own as its card over the menu instead, from a row or
  from the level before it. Text follows Dynamic Type (`Font.mono(_ style:)`; the card scrolls and stacks its facts
  and buttons at accessibility sizes; the dock stops at `xxxLarge` and shows a name large on a long press). VoiceOver
  reads each cover's state or price and each button's price, hides the menu under a card, and announces a change of
  state. Reduce Motion holds the covers and clip still, stills the pending dot and fades the card in.
- **Analytics.swift** holds anonymous counts for Aptabase (the app key names its region, EU or US), behind `Consent`
  (undecided, yes, no; stored as `analytics.consent`): until yes nothing is queued or sent and no `Sender` exists, and a
  no deletes the queue. `Analytics.configure` runs in `RootView.init`, before `start` (which waits for the store), so
  the question shows at once and an answer given before `start` is stored. **Consent.swift** asks it and holds every
  word it and settings say (`ConsentWords`): on a plain launch while undecided,
  `ConsentCard` covers the menu, which waits for the answer (hidden from VoiceOver meanwhile): a title, one line and a
  link, "What does it send?", that opens the full list of what is sent under the line; Yes and No the same
  control, neither preselected. The gear beside the menu's title opens `SettingsSheet`, sized to what it holds: the
  analytics switch (`NeonToggle`, which calls `decide`) and "send log", which hands `Log.url` to the share sheet. No ID
  leaves the phone. `Tally` (stored as `analytics`) keeps the install's local day, the days opened, what has gone out
  once and an undo count; undecided records, a no records nothing and `decide(false)` forgets all of it but the
  install's day (`Tally.forgotten`), so day numbers stay right and a later yes starts clean (re-sending `installed`);
  bests and started flags are the game's own and stay (Jack, 2026-10-26, N). Its `opened` gives `installed` once,
  `returned` with the day number (day 1 the install's) on the first opening of any later day number not yet sent, at
  launch or on coming to the front, so a clock set ahead and back costs no real return, and on the first opening on or
  after days 2, 7 and 30 the newest `snapshot` due, every one due marked sent, so a late yes or a clock jumped ahead
  sends one (Jack, 2026-10-26, K). Days are plain `Best.day`, not `trustedNow`. A level sends `level` (id, `daily` for any daily, outcome solved or quit, moves, par, undos, resets)
  as it is solved or left for the menu; endless sends `run` (spilled or quit, tanks cleared, moves); the sandbox
  nothing. A level open as the app leaves the front writes its quit to the tally, which the next launch sends if the app
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
- **Menu.swift** holds `MenuView`. Under the title, a strip names every tier, dimmed with a lock while locked, and
  scrolls sideways once there are more than fit; VoiceOver reads it as one adjustable element. Tapping a name, or
  dragging the list sideways, stirs the list away round the middle of its visible part with the tank's own shader
  (`Stirred`, one rod, a low plateau), then unstirs the next tier's into place; the title cuts to the new tier's sweep
  at the swap. A drag is the switcher's only if its first 15 points run at least twice as far sideways as up or down
  (`isSideways`); then the list stops scrolling, and a row lifted over doesn't open. While it turns, the list is drawn
  again over the scroll view, cut to its visible part, and that copy is what stirs; the scroll view's own list
  (`listed`) catches up only once the stir has settled, since rebuilding it stalls a frame. A locked tier can be
  looked at: its rows dimmed and closed, over the gate, a tick per level of the tier below, lit at par. A hidden stir in
  the background builds the shader's pipeline before the first switch. The pack dock (`PackDock`) is a bottom inset of
  the list, and the card (`RootView`'s, bound in) lies over the whole menu.
- **Pictures.swift** bakes plughole's neon pictures once per size. They are designed so that "up" is readable inside
  every rigid core. Whirlpool's five (glass, chainmail, coral, neurons, marbling) and their twins (maelstrom's) withhold
  it and are drawn live instead: `PictureLayer` hands each shader the clock mod the picture's `period` (a minute for a
  twin, its heartbeat's loop) and the floats from **LivePictures.swift**, seeded by level. The glass's cells take the
  raw clock; the neural web is static per seed, built once off the main actor. Vortex's own family (isobars, ephemeris,
  cords; **VortexPictures.swift**, **Flow.metal**, **Sky.metal**, **Loom.metal**) is drawn live the same way, with no
  twins; the ephemeris's period is 30 s, in which each planet goes round a whole number of times. The sandbox's cycle
  (`Picture.next`) takes plughole's pictures, whirlpool's and then vortex's family, and skips the twins.
- **UnstirApp.swift** holds `RootView` and the `Harness`. The harness reads `UNSTIR_*` environment variables at launch
  (passed as `SIMCTL_CHILD_UNSTIR_*` by the scripts). They pick a screen, tier (`UNSTIR_TIER`, which the menu opens on
  even when locked), level, mode, stack, seized knobs (`UNSTIR_SEIZED`, never a swirl, so `UNSTIR_TIER=vortex UNSTIR_LEVEL=1 UNSTIR_SEIZED=1` opens a level with both) or tank position (`UNSTIR_TANK`), and can hold a
  mid-drag turn of a rod (`UNSTIR_LIVE`) or the tank (`UNSTIR_TANKLIVE`), a finger just down (`UNSTIR_TOUCH=x,y` in tank
  units, run through `LevelView.grab`; with a held turn, where that finger went down), a turn just let go and still open
  (`UNSTIR_TURNED=rod:steps`), endless's brim (`UNSTIR_BRIM=n`, never stored), a touch on a seized knob held that
  many seconds into its shake (`UNSTIR_SHAKE`, with `UNSTIR_TOUCH`), the solve wave, autoplay or a frame-time bench
  (`UNSTIR_BENCH`). In Debug, `UNSTIR_PACK=lens` opens that pack's level `UNSTIR_LEVEL`, or past its levels a placeholder, which keeps no
  best or started flag (`Level.keepsProgress`), and
  `UNSTIR_OWNED=lens,complete` and `UNSTIR_STORE=lens:pending,complete:revoked` set the store's states for the launch
  in place of StoreKit's, never stored, with the StoreKit file's prices (none with `UNSTIR_PRICES=0`).
  `UNSTIR_CARD=lens` (or `complete`) opens that card over the menu; in Debug `UNSTIR_CARDLEVELS=n` lists n placeholder
  levels on a pack's card while it has none. `UNSTIR_SHELFDEMO=1` opens Lens's card from the dock and closes it, and
  `UNSTIR_TYPESIZE=accessibility5` sets Dynamic Type (a `DynamicTypeSize` case). `UNSTIR_MOVES=-1:-1,1:-8` plays a line of moves at autoplay's pace, each a knob's turn or the
  tank's (rod -1) in `parse`'s rod:steps form; with `UNSTIR_FINGER=1` it rests `UNSTIR_REST` seconds (2 when unset), then plays at a hand's
  pace, each move by a drawn fingertip that lands where `grab` gives it the move's rod or the rim and rides the turn
  round, for films. `UNSTIR_PAR=n` sets a stack's par. `UNSTIR_CLOCK` also holds the rim
  lesson's ghost finger, a refill's "+2", and endless's brim that many seconds after its last change (a spill's too),
  and it holds the swirl's breath at 0. `UNSTIR_BREATH=s` holds the breath s seconds into the tank's first rest, whose
  first slosh starts at 1.5 s, for stills, even under `UNSTIR_CLOCK`, and never with `UNSTIR_SWIRLED=1`, which has none. `UNSTIR_BRIMDEMO=1` plays the approved film's run of the brim through the same calls a finger makes: two heals, then
  pushes until it spills. `UNSTIR_UNDOS=n` sets the undo bank and `UNSTIR_TODAY=yyyy-MM-dd` the day the level opens on;
  a harnessed launch never stores the bank, the refill's day or its anchor, and with `UNSTIR_TODAY` and no day stored it
  takes the last refill as long ago, so the level opens on a refill. Nor does it store the tank flag or the swirl's: they
  read as never turned unless `UNSTIR_TANKTURNED=1` or `UNSTIR_SWIRLED=1`, and whatever the launch turns lasts only that launch, so shot order never
  matters. For the menu, `UNSTIR_BESTS=plughole:0001,...` registers bests for that launch only (a digit per level, that
  many over par; `-` for none), `UNSTIR_TIERSPIN=angle:fade` holds the list mid-stir and `UNSTIR_TIERDEMO` switches
  tiers through the same calls a finger makes. `UNSTIR_ICON=n` shows app-icon candidate n alone. `UNSTIR_ANALYTICS=log` writes each analytics event to the
  flight recorder instead of sending it, as if the player had said yes, and stores no consent or tally; like
  `UNSTIR_UNLOCK` it leaves the launch otherwise a plain one, and `scripts/run-ios.sh` passes it to the phone. Under
  any other harness flag analytics is off and the menu never asks, unless `UNSTIR_CONSENT=ask` (or `=sends`, which
  opens the card's list); `UNSTIR_CONSENT=yes`
  or `=no` answers for the launch, never stored, and `UNSTIR_SETTINGS=1` opens the menu with the gear's sheet up. `UNSTIR_UNLOCK` alone
  is the developer unlock above; alongside any other `UNSTIR_` variable, leaving it unset clears it, so no shot leaves
  the next unlocked. This is how screenshots and films
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
  its centre; whether a word commutes is still `Layout.commutes`'s call. The swirl is a slot like any other, held at
  every position and never seized. With no knob seized, as on every vortex level, the tank never turns, so every
  player untwists and the planning gap is 0: there the solver's job is the optimum, and whether a detour beats
  untwisting. The park rule (`park`) untwists the newest whole seam a working knob
  reaches; when none is, it turns to a position where one is, choosing by where the seized knobs land (`Parking`:
  `.fewest` or `.all`), then the nearest. The rule has no tie-break (Jack's call): `parkTies` gives its fewest and
  most moves over every way its ties go, and `park` breaks them by `Tie` (`.clockwise` or `.lowest`) only to name one
  play. No lookahead (`noLookahead`) turns to the nearest, clockwise on a tie. A level is fair when the park rule's
  most moves over its ties is the optimum under both parkings; its planning gap is no lookahead minus the optimum.
  `home:` asks for the tank back at 0, the old end rule. Several tests replay plays on a real `Game`, which must empty
  the stack in the moves the play counts.

Many tests are regressions from real play (e.g. `testWhirlpool11UnstirsToEmpty`, `testVisibleSmudgeIsNotSolved`).
Others check the level tables against the design tables (par, inversion counts, whirlpool's and vortex's pictures).
