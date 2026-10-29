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
- **PR and nightly tests.** A PR skips `StoreTests` and `FirstStirTests` (`-skip-testing`; First Stir is out of v1 and
  its vignette render takes two minutes), which `.github/workflows/nightly.yml` runs with every other test, bar the
  `UNSTIR_SLOW_TESTS` ones (they ran past 25 minutes on the runner), on `master` at 03:17 UTC and on `workflow_dispatch`: a break in them shows a night late. Both jobs print each
  suite's and the slowest tests' times (`scripts/ci-times.sh`) in the log. Add a suite to the skip list only here and in
  `test.yml`, so the nightly keeps running it.
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
  It passes the shell's `ANALYTICS` (YES builds analytics in; NO, the default, is v1's) and `APTABASE_KEY`, Aptabase's
  app key, into Info.plist's `Analytics` and `AptabaseKey`, over `Config/Local.xcconfig` (gitignored), which
  `Config/Unstir.xcconfig` includes for Xcode's own builds and archives; without both analytics is off. `ANALYTICS_PLAYTEST=YES` sets Info.plist's `AnalyticsPlaytest`, which files a Release
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
  To run one test, add `-only-testing:UnstirTests/UnstirTests/testPush`. The solver's tests that take seconds, and the
  halftone's contrast test, skip unless `UNSTIR_SLOW_TESTS=1` reaches the runner, which CI never sets: put `TEST_RUNNER_UNSTIR_SLOW_TESTS=1` before
  `xcodebuild` to run them too (about a minute and a half more).
- StoreKit tests: `scripts/test-store.sh [xcodebuild args]` runs the tests with `StoreTests` on, as CI does. They
  skip under `CODE_SIGNING_ALLOWED=NO`, since storekitd refuses a test session for a host app without
  `get-task-allow`; the script signs ad hoc with `StoreKit/Test.entitlements` into `build/store`.
- Solver: `scripts/solve.sh <layout> <scramble> [seized knobs, comma-separated] [lenses=slots] [masks=slot:channel]`
  (e.g. `quad 0:+3,2:-4 0`, `tri 1:-2,2:+4,0:+3 lenses=0`, or `tri 2:+2,0:+3,1:+4 masks=0:r,1:c`; a swirl layout by its name, `quadSwirl`, its swirl never seized or a lens) prints the optimum (and what untwisting alone takes when a
  detour beats it), the park rule's fewest and most moves over every way its ties go under each parking, fair or over
  by the most, the no-lookahead count and its planning gap, then the optimal moves, one commit or turn each. It
  compiles `build/solve` with `swiftc` when a source has changed, from Twist.swift, Solver.swift and `SplitMix64` cut
  out of Levels.swift, so that struct stays top-level there. `scripts/solve.sh escapement <layout> <scramble> <clocks>
  [limit]` (e.g. `escapement hex <scramble> 1+,4-`, clocks as `problems.tsv` writes them) runs the app's own prover
  (`Solver.escapement`) instead: the fewest moves with the clocks ticking after each, under the same rule, a line,
  waits and all, and every first move that reaches it.
- Escapement's prover: `scripts/escapement.sh check <layout> <scramble> <clocks> [span] [quick]` (clocks as rods in tick
  order, each `+` or `-` for wound back, e.g. `hex <scramble> 1+,4-`) plays the pack's rule on `Array.commit`: every move
  (a turn, or `wait`) ticks each running clock one step, and a tick that pushes loses, as does the last clock stopping
  with twists still on the picture (Jack, round 9), so no line takes more moves than the clocks owe. It prints the
  optimum and its proof, which is absolute when par is what the clocks owe, the lines and keys at par over turns of up
  to `span` steps, and each move of the line with the alternatives that would lose. `build` deals problems backwards from a line,
  and `book scripts/escapement/problems.tsv` proves the draft book (`docs/escapement-problems.md`, about eight
  minutes). `ESC_RULE=lab` plays the lab's re-grab instead of the final tick, and `ESC_PUSHED=1` plays on past a pushed
  tick. It compiles `build/escapement/prove` from Twist.swift and `SplitMix64`, as `solve.sh` does.
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
- Sounds: `scripts/sounds.sh` renders the Csound sources in `sound-src/` into `Sounds/glass` and prints each file's
  loudness, peaks, onset, phone-speaker loss and size, and each bed's seam (needs Homebrew's `csound` and `ffmpeg`).
  Every source is seeded, so a rerun renders the same samples, but the AAC encoder isn't byte-deterministic, so a
  rerun may rewrite a bed's .m4a with new bytes; restore those rather than commit them. `scripts/sounds.sh listen
  <dir>` writes every effect and bed as m4a to `<dir>`, with a few effects played in turn over a bed, for listening
  off the phone.
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
- Prism's specimens: `scripts/prism-levels.sh table` measures every specimen in Pack.swift (depth, the solver's
  optimum, what is free under the masks and read white, blocked knobs, right moves per step, the shader's assumed cost,
  and the shares of the glass showing ghosts and three-way splits, the readability limits); `check <layout> <masks>
  <scramble>` measures one and `search <layout> <depth> <palette> <from> <to>` deals seeded ones over a white bottom rod,
  keeping those at par. `scripts/prism-levels/pick.py <pool dir>` picks the trays from the pools.
  `scripts/prism-plates.sh render <plate> <out.png> [side] [layout]` draws a plate on the Mac, and `check` prints each
  core's lit share and how much of it a 30° step moves, as the test measures.
- Lens's tables: `scripts/lens-table.py [docs/lens-design.md] [--pitches 4] [--solve]` reads the level rows of
  a doc (`docs/lens-tables.md` holds the built ones) and checks each against the hard lens's rules with no app code (a lens moves only its core, so
  overlap decides commutation): depth after the parse, dealt lens steps and nets, and how far each twist dealt over a
  lens drags its rim, in dot pitches; `--solve` also runs `scripts/solve.sh` on each row and breaks one whose
  optimum or the app's parse is not its depth. It exits non-zero on a break.
- First Stir's outline: `docs/first-stir-outline.md` is the pack's story, scene table and art spec, approved by Jack
  (2026-10-26) with his answers marked under its open points. `scripts/first-stir-compositions.py` draws plans of three of its scenes (each rod's disc and core,
  the part of a core another disc reaches, where each vignette sits) to `shots/first-stir-composition-*.png` (needs
  Pillow).
- Workflows: `actionlint .github/workflows/*.yml` (Homebrew's `actionlint`) before pushing a change to one.
- GPU bench: `scripts/gpu-bench.sh [sim]` launches the app with `UNSTIR_GPUBENCH=1` (`GPUBench.swift`), which runs
  Unstir.metal's own shader bodies (`benchUnstir`, over `unstirBody` and `unstirChannelsBody`, the templates the
  stitchables call) off screen at the largest phone's 1284 px and prints a plain stack entry's cost, then each Prism
  specimen's per-channel cost in entries against `Unstirred.channelCost`'s assumption, and the slowest against a 120 Hz
  frame, then quits. The simulator has no GPU clock, so there it times the wall clock round each command buffer.
  `scripts/gpu-bench.sh phone` is Jack's: it installs Release through `run-ios.sh` with the bench on, waits, and pulls
  the lines from the log.
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
  The shader's tap count and the `Tank.maxStack` (36) and `Tank.fourTaps` (30) limits are tuned against 120 Hz on an
  iPhone 13 Pro Max, before the turn was added; its cost per tap is unmeasured. A live picture's own cost comes off the
  four-tap limit as `Picture.fillEntries`, scaled from Mac GPU costs and unconfirmed on the phone. Prism's stacks
  go to a second stitchable, `unstirChannels`, only when some entry's mask isn't white (`Unstirred.masks`), so every
  other level draws through `unstir` as measured: it carries red, green and blue each through the inverses of the
  entries whose mask (a float per entry, the `Channels` raw value) holds it, and samples each channel at its own point.
  Both share the per-entry map (`unmap`); `testTheShadersChannelChainsMatchTheModel` compiles the per-channel loop
  (`chains`) and checks it against the model's cut words on hex's swirl. Its cost against the four-tap limit
  (`Unstirred.channelCost`) is a map per channel each entry holds, plus two for a tap's extra samples: assumed, not
  benched on the phone, so a 12-entry stack of mixed masks may already run two taps.
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
  one or a socket refuses touch, and a ratchet is one of Escapement's clocks (`Level.clocks`, in tick order: clockwise from twelve by
  `Layout.clockwise`, each +1, or -1 if in `woundBack`), with a
  `demo` stack for the demonstration before the first stir. Every level today turns its tank exactly where a
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
  drops. The result card of a tier's last level goes up a notch (`TierUp`): the next tier's name in its own sweep, glowing, opening its first level, or, while that tier is closed, as bright behind a lock, opening the menu on that tier's gate. `Game.history` holds rod stirs by slot and
  tank stirs as rod `Game.tank` (-1), so an entry is not always a rod index. It also holds `LevelView` (drag on a knob →
  live twist → `Game.commit` on lift; where the level's motion is the tank, a drag on the rim or a two-finger twist → live tank turn →
  `Game.turnTank`), the `Unstirred` shader modifier and the result card. `LevelView.grab`, a pure function, decides what
  a finger holds where it lands, never by its motion: the rim first, else the disc whose centre is nearest in its own
  radius, overlapped or not, never the swirl; a seized winner or a socket is `.seized`, which holds nothing, and a
  ratchet `.ratchet`, which holds nothing: a tap on the ratchet's plate (a dark disc of radius `ratchetReach`, edge lit)
  waits (`Game.wait`), a tap elsewhere on its disc sends a ring from the finger closing on the plate, and a drag shakes
  it with a thud. The rim, from
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
  Escapement's clocks live in `Game` too (`Game.Clock`, `escapement`). After every move each clock that holds an entry
  as its turn comes ticks its step through the ordinary commit, in `Level.clocks`' order (Jack's call D1, round 9), so
  one clock's tick can uncover the next's seam on the same move (the book's 17 and 18 need it), and the stack's last
  tick solves on the spot; a clock that can't tick (`canTick`) has stopped, and once all have there is nothing to wait for. A
  move is one working knob's stir or a wait, a tap on any ratchet. Every
  let-go is a move of its own and final (Jack's call E1, round 9): its tick lands with it, nothing joins it, and the
  same knob grabbed again is the next move with its own tick, so a stir's dial always counts from zero. Escapement has
  no par (Jack's calls EL1, round 11, which replaced round 9's E1/E2 loss rule, and ES2, round 12): each clock has its
  own count, what it owes on the stack (`Game.owed(_:)`, `Level.owed`), and each of its ticks spends one of it; the
  header's budget is every clock's together (`Game.budget`, `Level.budget(on:)`; `Level.budget` as dealt, which the note
  states: "Unstir in 9 ticks."), so a move with three running clocks spends three. Only a clock's own ticks change its
  rod's steps, each by one whether it merges or pushes, so the counts are read off the stack and nothing stores them.
  A clock ticks while its rod holds an entry and its count is above 0 (`canTick`); at 0 it stops. A tick that pushes
  buries a clock entry of the wrong sign, `overdue(_:)`, that no continuation pops (`testAPushedTickNeverPops`), and
  still spends one of that clock's count, but the tank plays on, every later clock in the turn still ticking
  (`pushedClock`); once no clock can tick with twists still on the picture the tank is out of ticks (`lost`, which
  `finished` counts). Without a pushed tick a clock's count reaches 0 exactly as its rod empties, so it ends no proved
  line (`testTheBudgetIsWhatTheClocksOweAlongEveryProblemsLine`, `testEachHubCountsItsOwnClockAndTheHeaderIsTheirSum`,
  which also checks the counts through a wrong move and its undo before every move of every line). No clock in the
  book owes more than 9, so a hub shows one digit (`testEveryHubCountFitsOneDigit`). A solve spends the budget to the
  last tick, so `over` is always 0 and its best stores as solved. One clock stopping while another runs loses nothing.
  A full stack refuses a move whose tick it would refuse. Undo is the pack's, the stack and the clocks as the move found
  them, and works on a tank out of ticks; reset deals the counts afresh. The header shows the budget, not moves against
  par: "ticks" and a split-flap numeral (`FlipCounter`), driven by the ticks' own keyframes, whose old digit's top half
  falls over the hinge as each clock's tick starts to turn, one flap per tick in turn; Reduce Motion swaps without the
  fall; it goes vermilion at 00 and stays up over the card. The view draws
  each clock's knob as a 12-tooth `RatchetView` read against a vermilion sub-dial fixed to the glass (a wound-back
  one mirrored), its hub a one-digit `FlipCounter` card of the clock's own count (unmirrored), flipping with the header
  as each of its ticks starts, so the header always reads as the hubs' sum; a clock at 0 greys its wheel, sub-dial,
  card and `ClockHint` as its last tick lands, the pawl and hub ring amber, with the amber stop ring; its pawl riding out with each tick, the move's ticks a beat after the lift each turning its clock's
  core a step on screen in turn, `tickTurn` apart after `tickBeat` (`Game.tick` holds each with the stack it changed; `Unstirred.tick`,
  one entry over in the four-tap budget, like the drag) and the wheel a tooth; `ClockHint` dashes the clock's disc at all
  times (Jack's call, 2026-10-25); a pushed tick flashes the ratchet red and stands as a vermilion +N; a
  tank out of ticks shows "out of ticks." (`LostStamp`) by the clock whose tick spent the last, with or without a +N
  (a −N for a wound-back clock), and with no push the look `UNSTIR_STOPLOOK` picks (`StopLook`: stamp, as built; left,
  the twists left as a count; rings, a ring on each knob still twisted), and `LostCard`'s "out of ticks on move N",
  undo and again, whose
  exit goes through `leave` as the result card's does. A clock stopping sends an amber ring out as its last tick lands. A level with a
  `demo` plays it before the problem opens, every time, unless the harness holds the tank still: a drawn fingertip
  heals the demo stack through the real rules, so the clock ticks, then taps the ratchet, and the tank dips to black
  and the problem winds in on `dealt(level)`; a tap skips it. Clock commits take the level's `lenses` like any other.
- **Pack.swift** and **Store.swift** hold the paid packs, outside the tier ladder: `Pack` (First Stir, Lens,
  Escapement, Prism) has a name, a level-id prefix (its raw value: `lens-1`), a product id, a free taste of 3 and its levels (First Stir has
  25, five chapters; Lens 25; Escapement the problem book's 30 in its order and five chapters, `Level.chapter`, which the
  card's list heads, counting solved levels: each par, never shown, what its slowest clock owes and reached by the
  prover, its one key pinned,
  `EscapementTests`; the full ±11 key search is slow; Prism six, a prototype that may take First Stir's place in v1):
  `Pack.levels` reads `Level.firstStir`, `Level.lens`, `Level.escapement` and `Level.prism`, numbered from
  1 by place under `Pack.id`; a `Level` names its `pack`. A pack's undo spends the shared bank like any other, but
  puts back the stack as the move found it, marks and tags and all, from `Game`'s snapshot of the stack as each stir
  began; the free tiers' commits the stir's negation (`testAPackUndoPutsTheStackBackWhole`). No pack best ever opens a tier. `PackTests` pins every stored
  level id, product id and storage key as literals, so never rename one. `Pack.access` says whether a level plays: the taste
  always, past it only a pack StoreKit grants, with `Best.unlocked` and the harness counted outside Release only.
  First Stir is out of v1, to be reworked (Jack's call FS17), and Prism doesn't ship while a prototype: `Pack.ships` is
  false for both, and `Pack.sold()`, the packs a build sells, leaves them out in Release only, so their code, levels,
  ids and tests stay and Debug and the harness (`UNSTIR_PACK=first-stir`, `=prism`) still reach them. In Release their every level, taste and all, is `.withheld`, which opens
  neither the level (`Store.opens`, checked by `RootView.show`) nor its card (nor `UNSTIR_CARD`), and `Pack.sold()`
  sets what StoreKit is asked for (`Pack.productIDs`), what Complete grants and needs, Complete's cover, words
  (`Pack.named`), and clip (in which Prism has no beat yet), and analytics' snapshot (`testFirstStirIsOutOfV1`).
  `Store` is StoreKit 2 with no server and nothing stored: entitlements from `Transaction.currentEntitlements` at
  launch, a `Transaction.updates` listener (Ask to Buy approvals, refunds, other devices, Family Sharing),
  `purchase` and `restore` (`AppStore.sync`). Only a verified transaction grants; Complete (`Pack.completeID`) grants
  every pack, and a revocation takes back only what that product alone granted. `Ledger` keeps each product's
  `Purchase` (unowned, owned, pending, failed, revoked). A revoked pack keeps its bests; past the taste it needs the
  card again. `StoreKit/Unstir.storekit` sells each pack (First Stir and Prism too, since `StoreTests` run outside Release, where they are sold) and Complete as family-shareable non-consumables at
  2.99 a pack and 5.99 for Complete (Jack, 2026-10-25, before Prism was a fourth); the scheme's run action and `StoreTests` use it. Prices are
  never the app's own: `Store.prices` holds each product's `displayPrice`, fetched at launch and again when a card
  opens without one, and a card with none says "buy" alone.
  `Level.lens` holds the pack's 25 levels, table A of `docs/lens-tables.md` (lenses on rods of every size; table B, big
  rods only, is the alternative on branch `lens-levels-big`), on the halftone: each dealt lens entry +1 to +3, each lens
  netting at most +3, no entry merging as it is dealt, and par the depth (`testLensLevels`, which pins the table), the
  solver's optimum (`testLensParIsTheOptimum`, slow; `scripts/lens-table.py docs/lens-tables.md --solve` checks a
  table's rules and optima in seconds before it goes in). A lens's knob carries a magenta iris (`RodView.lens`). On a level with masks every knob is tinted its mask's
  colour (`Level.tint`, `Channels.colour`, the cover's red, green and blue and their mixes), a white rod white: its
  ticks, pointer and a jewel at the cap's centre. Under Differentiate Without Colour (or `UNSTIR_LETTERS=1`) Prism
  reads without colour: each knob spells out the primaries it holds under its cap (`Channels.letters`: R, GB, RGB),
  and `ChannelSwatches` (R, G and B) sit under the caption; holding one draws that channel alone in white and hides the
  others (`Unstirred.isolate`, the `unstirChannels` shader's `isolate`), and VoiceOver toggles it. Neither shows
  otherwise, so the read stays by colour for everyone else. `scripts/colour-blind.py <out> <shots>...` lays shots out
  beside their protanopia, deuteranopia and tritanopia simulations. A lens follows the finger up and down, not round
  (Jack, 2026-10-26): `LevelView.lensTurn` counts `lensPitch` (0.15 tank units) of travel as a step, up a positive
  one, which magnifies, so the dealt entries are undone dragging down (`testALensDraggedUpZoomsIn`). The step goes
  through the rod's own `liveAngle` and detent, so its count, clicks and the iris's turn are a rod's, a step at a time,
  but its dashes run up a short vertical track beside the knob for a zoom in and down it for out (`track`, on the side
  away from the finger), not round the disc. A drawn fingertip (`UNSTIR_FINGER`) on a lens rides up and down too.
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
- **Shelf.swift** holds the shelf (Jack's pick, round 3, S2: a dock of live covers) and the cards. `Offer` is a pack or
  Complete, with its card's words and colours. `PackDock` sits at the bottom of the menu with a cover per offer on
  `Offer.shelf`: in Release a pack only once it has levels past its taste and Complete only once every pack is there
  (Jack, 2026-10-26, S1), and never a pack it doesn't sell, so today Lens alone; outside Release every cover (`Cover`, drawn in code in each pack's look until it has art) stirred and unstirred by the tank's own shader
  (`Swirled`) on a 7 s loop, each out of step, at 30 Hz, paused under a card, a dot for its state. `PackCard` grows out
  of its cover: the clip (`PackClip`), what it
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
  **Clip.swift** draws each card's clip live, never a committed video (to-do 50): a `Clip` is one or more `Reel`s,
  each a real level played by a drawn fingertip at `UNSTIR_FINGER`'s pace, every move through `Array.commit` and, on a
  clock, its tick through `Game.tick`, the rule `Game` itself ticks by, so `ClipTests` checks every stack against a real
  `Game`. A frame (`Reel.frame(at:)`) is a pure function of the clip's time, drawn by the level's own views (`Unstirred`,
  `SceneLayer` or `PictureLayer`, `RodView`, `RatchetView`, `ClockHint`, `Bezel`) with the game's heal, push, tick and
  stop rings and its solve wave timed as `LevelView`'s keyframes are; `ClipPlayer` loops it from when it appears, holds
  it at `UNSTIR_CLOCK`, and under Reduce Motion holds `Clip.still`. A reel that dips is black at both ends, so the
  seam never jumps. First Stir: level 1, the sunrise, healed top first, the time under the tank stepping back with each
  heal (F3) from 6:40 to 6:15 am and a vignette playing with each heal but the first, which leaves rod 1 an entry.
  Lens: level 3 as dealt, its lens newest, dragged down to clean and back up, let go where it began, so it loops with
  no dip on the order read (Jack, CL1). Escapement: problem 2, the mock-up's, in its three moves, its hub counting 3 down to 0. Prism: specimen 1
  healed top first. Complete (`Clip.cut(of:)`): each sold pack's first beat in turn, Prism, a prototype, having none, a
  vignette (the sunrise from just after its first heal, which plays nothing, through its second), a zoom and a tick, about 8 s (Jack, CL2);
  in Release, without First Stir, the zoom and the tick alone. Every reel stays drawn,
  the idle ones clear, so a cut never waits on a bake. The dock keeps its covers' own loops (`PackTank`).
- **Analytics.swift** holds anonymous counts for Aptabase (the app key names its region, EU or US), behind `Consent`
  (undecided, yes, no; stored as `analytics.consent`). v1 ships without them: the build's `ANALYTICS`
  (`Config/Unstir.xcconfig`, NO) sets Info.plist's `Analytics`, read as `Analytics.built`, and while it is off a plain
  launch never asks, settings has no switch (`Analytics.shown`), `start` leaves the mode off whatever the key, and
  nothing reaches `analytics` or `analytics.consent` (`testABuildWithoutAnalyticsAsksAndKeepsNothing`); the privacy
  manifest declares no collected data, so a build with `ANALYTICS = YES` must declare analytics's three types again.
  The rest of this paragraph is that build. Until yes nothing is queued or sent and no `Sender` exists, and a
  no deletes the queue. `Analytics.configure` runs in `RootView.init`, before `start` (which waits for the store), so
  the question shows at once and an answer given before `start` is stored. **Consent.swift** asks it and holds every
  word it and settings say (`ConsentWords`): on a plain launch while undecided,
  `ConsentCard` covers the menu, which waits for the answer (hidden from VoiceOver meanwhile): a title, one line and a
  link, "What does it send?", that opens and closes the full list of what is sent under it; Yes and No the same
  control, neither preselected. The gear beside the menu's title opens `SettingsSheet`, sized to what it holds: the
  analytics switch (`NeonToggle`, which calls `decide`) where the build has analytics, "send log", which hands `Log.url` to the share sheet, and
  "privacy policy", which opens `SettingsSheet.policy` (Apple's guideline 5.1.1(i)), for now the github.com page of
  `docs/privacy-policy.md`. No ID leaves the phone. `Tally` (stored as `analytics`) keeps the install's local day, the days opened, what has gone out
  once and an undo count; undecided records, a no records nothing and `decide(false)` forgets all of it but the
  install's day (`Tally.forgotten`), so day numbers stay right and a later yes starts clean (re-sending `installed`);
  bests and started flags are the game's own and stay (Jack, 2026-10-26, N). Its `opened` gives `installed` once,
  `returned` with the day number (day 1 the install's) on the first opening of any later day number not yet sent, at
  launch or on coming to the front, so a clock set ahead and back costs no real return, and on the first opening on or
  after days 2, 7 and 30 the newest `snapshot` due, every one due marked sent, so a late yes or a clock jumped ahead
  sends one (Jack, 2026-10-26, K). Days are plain `Best.day`, not `trustedNow`. A level sends `level` (id, `daily` for any daily, outcome solved, lost (Escapement out of ticks) or quit, moves, par (Escapement's budget), undos, resets)
  as it is solved, lost or left for the menu (a lost tank left is no quit); endless sends `run` (spilled or quit, tanks cleared, moves); the sandbox
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
  (`Picture.next`) takes plughole's pictures, whirlpool's and then vortex's family, and skips the twins and Lens's
  halftone. The halftone (**Halftone.swift**) is pure geometry baked a pixel at a time off the main actor: three dot
  screens at one pitch (0.03 tank units) in clean-picture coordinates, so a lens's swollen dots read against the pitch
  outside, and white linework that keeps every core asymmetric (`testEveryStepMovesContrastingPixelsOnTheHalftone`, slow).
  It takes some 20 s unoptimised, so a Debug build keeps it in Caches under the build's own timestamp. Prism's plates
  (**Engraving.swift**, `Engraving.Plate`: the fern, seed heads, a watch movement, a cathedral's west front and a
  nautilus, each a `Picture` of its name) are polylines in tank units, baked through `draw` as plughole's are, in white
  lines only, so a channel out of register shows as its colour and an aligned line is white
  (`testEveryPlateIsWhiteLinesOnBlack`). Each fills the glass and breaks every rotation a core could fall on, so a step
  moves most of the light in every core of every layout (`testEveryPlateShowsAStepInEveryCore`); the sandbox skips them.
- **Sound.swift** plays the glass set on an `AVAudioEngine` that only its own queue touches. Effects take a pool of
  twelve players, so quick ones overlap; a heal (`Game.heals`) climbs a note for each move since the level opened or was
  reset that popped one of the scramble's entries (`Game.Entry.pushed`), so cancelling the player's own push is no heal,
  and the heal that solves sounds as the solve. An undo's negation that brings back one of the scramble's entries marks
  it the scramble's again. The `seized` sound plays with `Knock.thud` whenever a finger lands on a knob that can't be
  turned. Beds loop under the menu and each tier (`Level.bed`; daily, endless, the sandbox and the packs take
  plughole's), and a new one crossfades in over the old at equal power across two decks. Only a bed that is playing
  stays decoded, and none in the background. `Sounding`, set on `RootView`, is the app's button style: a button taps as
  it acts, and undo and reset have sounds of their own; the undo's body peaks about 0.2 s after the press (Jack,
  SN1). A button that sets its own `.plain` style has none, so every
  such button that acts takes `Sounding` instead: the gear, the consent card's answers and its link, the settings
  sheet's switch and log, the pack cards' and the dock's buttons and the tier-up. The menu's tier names and rows
  stay plain: `go` plays `switch` once as a switch starts, by tap or drag, and a row taps only when it opens, never as
  a tier swipe lifts over it. Nothing sounds during a drag but the
  detent's tick, and a sound never tells the player anything the picture doesn't. The session is ambient, and while
  another app plays music the bed steps aside and the effects still sound. A harness launch or the test host is silent
  unless `UNSTIR_SOUND=1`. An undo steps the heal notes back, so the next heal plays the undone one's note again
  (Jack, SN1).
- **UnstirApp.swift** holds `RootView` and the `Harness`. The harness reads `UNSTIR_*` environment variables at launch
  (passed as `SIMCTL_CHILD_UNSTIR_*` by the scripts). They pick a screen, tier (`UNSTIR_TIER`, which the menu opens on
  even when locked), level, mode, stack, lens slots (`UNSTIR_LENSES=0,2`, parsed before the stack, which they change), channel masks (`UNSTIR_MASKS=0:r,1:c`, the same, never the swirl; `UNSTIR_SWATCH=r` holds a Prism swatch and `UNSTIR_LETTERS=1` shows Differentiate Without Colour's letters and swatches), seized knobs (`UNSTIR_SEIZED`, never a swirl, so `UNSTIR_TIER=vortex UNSTIR_LEVEL=1 UNSTIR_SEIZED=1` opens a level with both) or tank position (`UNSTIR_TANK`), and can hold a
  mid-drag turn of a rod (`UNSTIR_LIVE`) or the tank (`UNSTIR_TANKLIVE`), a finger just down (`UNSTIR_TOUCH=x,y` in tank
  units, run through `LevelView.grab`; with a held turn, where that finger went down), a turn just let go and still open
  (`UNSTIR_TURNED=rod:steps`), endless's brim (`UNSTIR_BRIM=n`, never stored), a touch on a seized knob held that
  many seconds into its shake (`UNSTIR_SHAKE`, with `UNSTIR_TOUCH`), the solve wave, autoplay or a frame-time bench
  (`UNSTIR_BENCH`). `UNSTIR_PACE=s` sets autoplay's and `UNSTIR_MOVES`' wait before each move (0.3 s unset), and
  `UNSTIR_BARE=1` draws the picture unstirred, so a story's art shows as the stack has played it. `UNSTIR_ENDING=s` with `UNSTIR_SCREEN=clean` opens First Stir's last scene solved with the night forwards held s seconds in (-1 runs it). In Debug, `UNSTIR_PACK=lens` opens that pack's level `UNSTIR_LEVEL`, or past its levels a placeholder, which keeps no
  best or started flag (`Level.keepsProgress`); Prism's is tri on the fern, rod 0 red and rod 1 cyan, dealt
  `2:+3,0:+4,1:-3`, as specimen 1 is. And
  `UNSTIR_OWNED=lens,complete` and `UNSTIR_STORE=lens:pending,complete:revoked` set the store's states for the launch
  in place of StoreKit's, never stored, with the StoreKit file's prices (none with `UNSTIR_PRICES=0`).
  `UNSTIR_CARD=lens` (or `complete`) opens that card over the menu; in Debug `UNSTIR_CARDLEVELS=n` lists n placeholder
  levels on a pack's card while it has none, and `UNSTIR_CARDSCROLL=1` opens it scrolled to its list. A pack level past
  the taste needs `UNSTIR_OWNED` too, or it opens the card. `UNSTIR_STOPLOOK=left` picks how an Escapement tank out of
  ticks as its last clock stops looks. `UNSTIR_SHELFDEMO=1` opens Lens's card from the dock and closes it, and
  `UNSTIR_TYPESIZE=accessibility5` sets Dynamic Type (a `DynamicTypeSize` case). `UNSTIR_MOVES=-1:-1,1:-8` plays a line of moves at autoplay's pace, each a knob's turn or the
  tank's (rod -1) in `parse`'s rod:steps form, a ratchet's turn a tap on it (a wait); `UNSTIR_PLAYED` commits such a
  line through the real path as the level opens, for stills; with `UNSTIR_FINGER=1` it rests `UNSTIR_REST` seconds (2 when unset), then plays at a hand's
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
  tiers through the same calls a finger makes. `UNSTIR_ICON=n` shows app-icon candidate n alone. In a build with
  analytics, `UNSTIR_ANALYTICS=log` writes each analytics event to the flight recorder instead of sending it, as if the player had said yes, and stores no consent or tally; like
  `UNSTIR_UNLOCK` it leaves the launch otherwise a plain one, and `scripts/run-ios.sh` passes it to the phone. Under
  any other harness flag analytics is off and the menu never asks, unless `UNSTIR_CONSENT=ask` (or `=sends`, which
  opens the card's list); `UNSTIR_CONSENT=yes`
  or `=no` answers for the launch, never stored; in any build, `UNSTIR_CONSENT` alone draws the card and the switch, and `UNSTIR_SETTINGS=1` opens the menu with the gear's sheet up. `UNSTIR_UNLOCK` alone
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
