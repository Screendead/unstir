# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Unstir is an iPhone puzzle game (SwiftUI + Metal, iOS 17, Swift 6, portrait only). Rods under a tank of picture twist
it; the player unwinds the scramble by turning rods back in the right order.

## State and the current task

This file holds the rules and commands every session needs, and pointers to the rest; it loads whole into every
session and subagent, so it stays under 30,000 characters (`scripts/doc-size.sh`, checked on every PR). How the code
works goes in `docs/architecture.md`, an index of Jack's calls in `docs/decisions.md` (the full text it points to wins), and closed sections of the handoff in
`docs/history.md`. `HANDOFF.md` holds the current task: the plan, where it stands, open thoughts,
and the options set aside with their reasons. Read it and `HANDOFF.private.md` at the start of a session. Update it when a step closes or Jack
makes a call, and keep its "Set aside" entries (note when one is picked back up). If the two files disagree about
state, `HANDOFF.md` wins. Record a recommendation as a recommendation until Jack decides it; when he decides, add the
call's row to `docs/decisions.md`. A section of `HANDOFF.md` that has closed moves to `docs/history.md` word for word,
leaving its heading and a pointer.

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
  its vignette render takes two minutes), and First Stir's two tests in other suites, `testFirstStirParIsTheOptimum` and
  `testFirstStirPlaysInOrderFromTheShelf` (Jack's call r16c-ci-firststir = A, round 16), which `.github/workflows/nightly.yml` runs with every other test, bar the
  `UNSTIR_SLOW_TESTS` ones (they ran past 25 minutes on the runner), on `master` at 03:17 UTC and on `workflow_dispatch`: a break in them shows a night late. Both jobs print each
  suite's and the slowest tests' times (`scripts/ci-times.sh`) in the log. Add a suite to the skip list only here and in
  `test.yml`, so the nightly keeps running it. Both Test steps pipe the tests through `grep`, so they set `shell: bash`
  for pipefail: under the default shell the step's status is grep's, which passes once any test has run.
- **Push only when a build is needed.** `.github/workflows/test.yml` runs only on `pull_request` events: when a PR
  is opened, reopened or pushed to. It skips pushes that change only `*.md` files, and it stops any run at 15 minutes (Jack's call r16c-ci-limit = B, round 16).
  Pushing to a branch with no open PR builds nothing. `test.yml` caches the StoreKit test build (`build/store`) between
  runs, keyed on the Xcode build and a hash of `project.yml`, `Sources/`, `UnstirTests/`, `StoreKit/`, `Config/`, the workflow and
  `scripts/test-store.sh`, so a file that sets the build's flags goes in that list. Checkout gives every file and folder a new
  inode and the current time, so the job stamps each tracked file with a time drawn from its blob's hash and each
  tracked folder from its tree's, and tells the build system to ignore inode changes; the restored build then stays
  incremental, asset catalog and all. The job builds for testing (`scripts/test-store.sh build-for-testing`, for a
  generic simulator, so it reads no device list, passing every phase and task line, flushed so GitHub stamps each, and
  the timing summary), then boots the simulator and runs `test-without-building`. Booting beside the build, as the job
  did until 2026-11-08, can stall it: one build description took 164 s against 3 to 5 s without the boot, for at most
  the 20 s of a cache hit's build hidden. Each run's environment (`GITHUB_RUN_ID` and the like) still makes a new build
  description, as the build system hashes the whole environment into its signature and no setting or flag leaves it
  out (`-UseSanitizedBuildSystemEnvironment=YES` doesn't), but alone that costs 3 to 5 s. On 2026-11-08, on an exact
  cache hit, the build step took 12 to 33 s (Metal recompiles every run, about 6 s), the boot 72 to 113 s and the test
  step 150 to 380 s, of which the tests are 45 to 95 s: the rest is `test-without-building` starting on the freshly
  booted simulator, not yet explained, and the next place to look. A push that changes `Sources/` adds the recompile.
  Every step's time moves with the runner's speed. After the tests it, and the nightly, measure the app they built (`scripts/app-size.sh`, Jack's
  call APPSIZE = B) less the test bundle and Xcode's testing frameworks the test host carries, and fail past 100 MB.
  That build is Debug for the simulator, one architecture: its debug dylib (16.6 MB on 2026-11-02) outweighs the
  Release binary (11.2 MB), and the resources are the same bytes in both, so it reads about 6 MB over a Release bundle
  (27.6 against 21.9). Grown by resources, the guard trips with Release near 94 MB, under the cellular download prompt
  (assumed 200 MB).
  `.github/workflows/codeql.yml` scans the workflows on every PR to
  `master`, `*.md`-only ones too, in case the `master` ruleset requires code scanning. It scans Swift, which takes
  about 18 minutes, only on pushes to `master` (only merges make them) and weekly. Never add a `push:` trigger for any
  other branch: it builds every push, PR or not. Keep
  commits local until the next build is worth paying for. If a build takes more than
  10 minutes (Jack, 2026-11-01), raise it with Jack: the approach to builds needs rethinking.
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
after a script's shebang, and so does every `.py`, `.csd` and `.udo` file, every workflow, `project.yml` and
`Config/Unstir.xcconfig`. The code is all rights reserved under
`LICENSE.md`, the proprietary licence: never add an open-source licence.

## Pushing back

Claude is the implementer under Jack's supervision and also the project's advisor. Jack has asked for pushback,
hard if needed, whenever an idea of his looks wrong. Say so plainly, give the reasons, and propose something better.
Once Jack has heard the argument and still decides, carry out his decision.

## Calls for Jack

A call goes to Jack as a pitch he can pick from, with the options built and shown. Each wave of calls gets a new
Artifact page: never add calls to a page he has already been sent; carry an unanswered call over written out in
full, and leave answered ones off. Write every call so it stands alone, for a busy, technical reader who has read
none of the repo's notes: no call ids, pick codes, round numbers or branch names, and no pointing at `HANDOFF.md`,
`docs/decisions.md` or a design doc, which are Claude's working files. What he needs from them goes in the call:
what exists today, what would change on screen, why it is asked now, each option's cost, and what waits on it.

## Commands

`project.yml` is the source of truth for the Xcode project; the scripts run `xcodegen generate` before building, so
edit `project.yml`, not `Unstir.xcodeproj`. Build products go to `build/` (gitignored).

- Build: `scripts/build-ios.sh [Debug|Release] [device|sim]` (defaults to Debug, device; prints only errors, warnings and the result).
  It passes the shell's `ANALYTICS` (YES builds analytics in; NO, the default, is v1's) and `APTABASE_KEY`, Aptabase's
  app key, into Info.plist's `Analytics` and `AptabaseKey`, over `Config/Local.xcconfig` (gitignored), which
  `Config/Unstir.xcconfig` includes for Xcode's own builds and archives; without both analytics is off. The same way,
  `SUPPORT_ADDRESS` and `POLICY_URL` (Jack's, never in a tracked file; `testNoTrackedConfigHoldsAPrivateValue`) set
  Info.plist's `SupportAddress` and `PolicyURL`; in an xcconfig a URL is written `https:/$()/...`, as `//` starts a
  comment. `ANALYTICS_PLAYTEST=YES` sets Info.plist's `AnalyticsPlaytest`, which files a Release
  build's events as Debug. `ICLOUD=YES` syncs progress through iCloud (`Sync.swift`), signing with its entitlement, so a
  device build needs the App ID's iCloud capability; a simulator build without signing builds either way.
  `ADAPTIVE_TAPS` (YES, the default; Jack's call taps-keep = C) lets a plain launch learn and keep each glass's four-tap budget (`Taps`); NO draws the static limit. `EDITORS=YES` (or `EDITORS = YES` in `Config/Local.xcconfig` for an Xcode archive) makes the
  editors' build, for App Store editors on its own TestFlight group (Jack's call F11): it sets the `EDITORS` compilation
  condition (`Build.editors`), and settings shows a labelled switch, "open every tier", that sets `Best.unlocked`, every
  tier, level and pack open, and the version line ends "editors". Any other Release build compiles the switch out
  (guideline 2.5.19 bars a hidden one; `testADefaultBuildHasNoEditorsSwitch`).
- Install and launch on the reference phone: `scripts/run-ios.sh [Debug|Release]` (needs `UNSTIR_DEVICE`, the phone's
  UDID, set in the shell). Every build it installs is a playtest, so Jack's own play never lands in real players'
  numbers (Jack, 2026-10-27). `UNSTIR_UNLOCK=1 scripts/run-ios.sh Release` also opens every tier and level, packs' too, on the phone
  until a run with `UNSTIR_UNLOCK=0`. It passes `UNSTIR_TAPS` (`Taps`) on as it does `UNSTIR_ANALYTICS`.
- Tests (XCTest, on a simulator):
  ```
  xcodegen generate --quiet && xcodebuild test -project Unstir.xcodeproj -scheme Unstir \
    -destination 'platform=iOS Simulator,name=Unstir iPhone 17 Pro Max' -derivedDataPath build CODE_SIGNING_ALLOWED=NO
  ```
  To run one test, add `-only-testing:UnstirTests/UnstirTests/testPush`. The test host shares its defaults with the
  harness's launches on that simulator, so the bundle's principal class (`FreshDefaults`) forgets every started flag
  before each test and after the run. The solver's tests that take seconds, and the
  halftone's contrast test, skip unless `UNSTIR_SLOW_TESTS=1` reaches the runner, which CI never sets: put `TEST_RUNNER_UNSTIR_SLOW_TESTS=1` before
  `xcodebuild` to run them too (about a minute and a half more).
- StoreKit tests: `scripts/test-store.sh [test|build-for-testing|test-without-building] [xcodebuild args]` runs the tests with `StoreTests` on, as CI does. They
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
  with twists left (Jack, round 9), so no line takes more moves than the clocks owe. It prints the
  optimum and its proof, absolute when par is what the clocks owe, the lines and keys at par over turns of up
  to `span` steps, and each move of the line with the alternatives that would lose. `build` deals problems backwards from a line,
  and `ESC_WAIT=0 ... book scripts/escapement/problems-nowait.tsv` proves the book
  (`docs/escapement-problems.md`; it stalls on 11). `ESC_RULE=lab` plays the lab's re-grab instead of the final tick, `ESC_PUSHED=1` plays on past a pushed
  tick, and `ESC_WAIT=0` plays without the wait, the app's rule. It builds `build/escapement/prove` as `solve.sh` does.
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
- Films: `scripts/film.sh [pattern]` records animations to `shots/film/*.mp4` with a frame strip each (needs ffmpeg);
  a pattern ending in `$` films only the case of that name, as `rim-swirl` alone would also film `rim-swirl-push`.
  Both take the first simulator named "Pro Max", or the one whose id `UNSTIR_SIM` gives. A film over 9.5 MB is shrunk
  to 660 px wide for a PR comment unless `FILM_FULL=1`; `FILM_SOUND=1` plays the take's sound and records it from
  BlackHole into the film, with the Mac's output already switched there (`store-media.sh sound`), placed on the
  video's clock by when each recorder started. recordVideo writes a frame only when the screen changes, so a take
  ending on a still screen ends early: each take's comment tag says how long it really ran (`take 19.520 s`). It also
  gives two frames the same time now and then, after which ffmpeg times the rest of the take by its dts, which step
  back about a second there (0.99 s in two takes), and `fps=` drops that much: every command that decodes a take
  reads it with `-fflags +igndts` (`movie=`'s `format_opts`), which a `-c copy` must not take. `scripts/strike.sh
  <film>` prints the seconds into a take just before its picture strikes, past the home screen and the launch's black.
- Editors' reel: `scripts/editors-film.sh [--join]` films `scripts/film.sh editors-` (whirlpool 03 and vortex 02 drawn
  clean, maelstrom 01, Lens 03, Escapement 02 and Prism 01, each solved at par by a drawn fingertip; Lens from a warm
  start, a launch first baking its halftone into Caches, R-reel, round 15) and joins them, each from just before its
  picture strikes for the seconds its list keeps, into `shots/film/editors-reel.mp4`, about a minute,
  for the App Store nomination's supplemental links (Jack's call F11); `--join` only rejoins.
  Git ignores `shots/` apart from `index.txt`: show pictures and films in a PR by attaching them to a comment through
  Chrome (GitHub has no API for attachments; videos under 10 MB), never by committing them.
- Store media: `scripts/store-media.sh [screens|preview|social|sound|all] [--cut]` makes the App Store's set (Jack's calls
  ST4 and ST5 = A, `docs/store-page.md`) into `$STORE_OUT` (`shots/store` unless set): the ten `shots.sh store-`
  screenshots, at 1320 x 2868 without alpha and again captioned (`scripts/store-captions.py`, Pillow and the Mac's SF
  Mono, as this ffmpeg has no drawtext; its look is a draft), the 25 s free-game preview (Jack's call STOREMEDIA = B,
  round 16; `STORE_PREVIEW` sets 15.6 to 27.6) at 886 x 1920 and 30 fps with a silent stereo track, its five segments
  (`store-open-L12`, `store-whirlpool-03`, `rim-swirl`, `rim-seized`, `endless-brim-run`) cut from their strikes and
  captioned, whirlpool 03 keeping its whole solve and the other four each giving up the same share of the 27.6 s that
  all five hold, from the end their line names, and plan step 3's social clips, 1080 x 1920 and silent,
  three drawn clean and one with the hand. `sound` films those clips again with the game's sound, switching the
  Mac's output to BlackHole for the takes and back (needs Homebrew's `blackhole-2ch` and `switchaudio-osx`), into
  `<name>-sound.mp4`, aimed at -16 LUFS (one-pass loudnorm lands them near -15). It films with `FILM_FULL=1`; `--cut` reuses what is taken. Apple's limits
  it meets are in its header, with where they were read.
- Sounds: `scripts/sounds.sh` renders the Csound sources in `sound-src/` into `Sounds/glass` and prints each file's
  loudness, peaks, onset, phone-speaker loss and size, and each bed's seam (needs Homebrew's `csound` and `ffmpeg`).
  Every source is seeded, so a rerun renders the same samples, but the AAC encoder isn't byte-deterministic, so a
  rerun may rewrite a bed's .m4a with new bytes; restore those rather than commit them. `scripts/sounds.sh listen
  <dir>` writes every effect and bed as m4a to `<dir>`, with a few effects played in turn over a bed, for listening
  off the phone, then renders the packs' sketches (`sound-src/sketches.csd`: two takes each of Lens's, Escapement's
  and Prism's layers on one motif at 75 bpm, and five of the ratchet's tick, the last three also in Escapement B's
  layer, for Jack's ear) alone and over plughole's bed, as `sketch-*.m4a`. The main render also renders the kept
  layers the app plays from it (`layer-*`, `Sound.Layer`).
  `scripts/sounds.sh layers <dir>` plays each kept layer (Lens B, Escapement B, Prism A) under a real level's line in
  `sound-src/layers-in-play.tsv`, three to four minutes of moves, undos and the solve with the sounds the game plays for
  each (`testTheLayerLinesSoundAsTheGamePlaysThem` checks them on a real `Game`): an 8-bar loop of the layer over the
  menu's bed crossfading to plughole's, its resolution on the beat after the solve, Escapement B's reed a note a move
  on the next eighth, and the game's effects at their own levels (`scripts/layers.py` times and mixes them), as
  `<pack>.mp3` and `<pack>-bed-only.mp3` with `layers-in-play.txt` listing each line and its loudness: each render's,
  the layer's alone over the line and, for Escapement, its sketch's with and without the sketch's ticks and its drums
  alone (`escBDry`, `escBDrums`), as the game's own tick replaces the sketch's in play. `scripts/layers-film.sh`
  films those three levels in the app with sound (`film.sh layer-`, BlackHole switched in and back).
- App icon: `scripts/shots.sh icon-` shoots each candidate (`UNSTIR_ICON=n`, `IconView` in Icon.swift), then
  `scripts/icon.sh [n]` crops them to `shots/icon-n-1024.png` without alpha, lays them out at 1024, 180 and 60 px on a
  dark and a light home screen in `shots/icon-candidates.png` and, with n, makes candidate n the app icon (needs Pillow).
- Promoted-purchase images: `scripts/promo.sh` shoots each sold offer's (`shots.sh promo-`, `UNSTIR_PROMO`,
  `PromoArt` in Icon.swift: its dock cover stirred inside the bezel) and crops each to `shots/promo-<offer>-1024.png`, as App Store Connect asks: 1024 x 1024, RGB without alpha,
  square corners, 72 dpi (needs Pillow).
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
  keeping those at par; `read` prints whether each move's count shows in its rod's core (a rod stirred twice shows
  the sum). `scripts/prism-levels/pick.py <pool dir>` picks the trays from the pools.
  `scripts/prism-plates.sh render <plate> <out.png> [side] [layout]` draws a plate on the Mac, and `check` prints each
  core's lit share and how much of it a 30° step moves, as the test measures. `deal <plate> <layout> <masks>
  <scramble> <out.png>` draws a deal.
- Lens's tables: `scripts/lens-table.py [docs/lens-design.md] [--pitches 4] [--solve]` reads the level rows of
  a doc (`docs/lens-tables.md` holds the built ones) and checks each against the hard lens's rules with no app code (a lens moves only its core, so
  overlap decides commutation): depth after the parse, dealt lens steps and nets, and how far each twist dealt over a
  lens drags its rim, in dot pitches; `--solve` also runs `scripts/solve.sh` on each row and breaks one whose
  optimum or the app's parse is not its depth. It exits non-zero on a break.
- Lens's panels: `scripts/lens-panels.sh render <panel> <out.png> [side] [layout lenses stack]` bakes a halftone panel
  as the app does, stirred if given; `time [side]` times each bake, a pixel at a time
  and as vectors; `check <panel> <layout> [lenses]` runs the contrast test's measure on one layout.
  `scripts/lens-art-sheet.py proof <dir> <level>...` bakes each drawn level's panel clean and through its lenses,
  `check` measures each on its own level, `read` ranks levels by the shapes a twist turns, and `sheet <out.png> <level>...` lays the Mac's bake over the
  game's shots (`shots.sh lens-NN`); its table names each level's panel (needs Pillow).
- First Stir's outline: `docs/first-stir-outline.md` is the pack's story, scene table and art spec, approved by Jack
  (2026-10-26) with his answers marked under its open points. `scripts/first-stir-compositions.py` draws plans of three of its scenes (each rod's disc and core,
  the part of a core another disc reaches, where each vignette sits) to `shots/first-stir-composition-*.png` (needs
  Pillow).
- Strings: `scripts/loc-lint.sh` lists player text that escapes the String Catalog against its baseline
  (`CatalogTests` runs it too; `--write` rewrites the baseline); `scripts/catalog.py plural` writes a plural key's
  English forms into `Sources/Localizable.xcstrings`, which no command-line build does, and `fixed` marks keys
  do-not-translate (`docs/architecture.md`).
- Workflows: `actionlint .github/workflows/*.yml` (Homebrew's `actionlint`) before pushing a change to one.
- GPU bench: `scripts/gpu-bench.sh [sim|phone]` launches the app with `UNSTIR_GPUBENCH=1` (`GPUBench.swift`), which
  times Unstir.metal's shader bodies (`benchUnstir`) off screen: a stack entry with four taps and two at 1137, 1284 and
  1471 px, the glass's fill and whirlpool 27's frame, each Prism specimen against `Unstirred.channelCost`, then bakes
  Lens's cheapest, dearest and first panels cold at the device's glass, and quits. `phone` (Jack's) installs Release
  through `run-ios.sh` and pulls the lines from the log; the simulator's times are the Mac's wall clock.
- The four-tap budget on the phone: `scripts/taps-check.sh [--sim udid] [runs...]` plays whirlpool 27 on the phone
  `UNSTIR_DEVICE` names (the build `scripts/run-ios.sh Release` installed), its stack cut or repeated (`UNSTIR_DEEP`),
  a knob dragged through the real let-go (`UNSTIR_TAPDRAG`), and prints each run's `taps` lines: `gpu`, `calm` and
  `stall` (`watch:n`, `UNSTIR_TAPSTALL`) showed on the 13 Pro Max that a late frame's main-thread CPU time can't tell
  the GPU's misses from the main thread's, hence `TapCuts.unattributed`; `adapt`, `prior`, `edge` and `edgestall` run
  the law. `--sim` is a dry run of the plumbing: the simulator's
  frames say nothing of a phone's GPU. `scripts/duo-feel.sh [--sim udid] [drags] [budgets...]` does the same for the
  deepest levels, each dealt and at 36, at each budget pinned (42 and the Duo upright's 23 unset), on the device's own
  glass; its header says what the display link can't see. Both launch through `scripts/harness.sh`.
- TestFlight play: `tools/tf-poll.py [--report|--dry-run|--force|--app-id <bundle id>]` polls App Store Connect's
  sessions per tester into a CSV outside the repo, the raw responses beside it, and prints day-2 return (Jack's call
  TFREAD = D); a date keeps its first poll unless `--force`. Setup, the two-day check and the survey draft are in
  `docs/testflight.md`. `python3 tools/tf-poll-test.py` checks it without a key.
- Device log: `scripts/pull-log.sh [--sim] [dest]` copies `Library/unstir-log.txt`, the flight recorder written by `Log.write`.
  Each touch logs what it holds and where it landed, and each drag one line when it ends: its path in tank units from
  the landing to the lift, with ms since the drag was taken up (usually the landing), thinned by `Trail` (a twist logs
  its rotation), so a pick or turn can be checked against the finger. Past 1 MB (`Log.cap`) it is cut to its newest
  512 KB from a whole line once the first screen is up (`Log.trim`): read and cut off the main actor, then replaced
  atomically on it with the lines written meanwhile, so a launch before the first frame only opens it. Once the first screen is up
  it logs a `device:` line (app version and build, iOS, model, locale, type size, Reduce Motion, VoiceOver, Low Power,
  the settings' switches, `Settings.summary`, and each glass's four-tap budget kept, `Taps.summary`), never the phone's name; each switch tapped logs a `settings:` line.
  `UILaunchScreen`'s colour (`LaunchBackground`, black) keeps a cold launch black in light appearance too.

## Architecture

`docs/architecture.md` holds how each part of the code works: the model, the shaders, the game state, the views, the packs and store, sync, analytics and the harness, with the reasons and Jack's calls behind them. Read the entry for a file before changing that file, and update the entry with the code.

These rules from it hold everywhere, read or not:

- **Never rename a stored value.** Progress, purchases and achievements are keyed by them: a tier's raw value, a
  level's id (its tier's or pack's prefix and number), a pack's level ids, product ids and storage keys (`PackTests`
  pins them), an achievement's id, title, points and hidden flag (a live one can't be deleted or repointed;
  `AchievementTests`), and Sync's store keys.
- **The level generator is frozen.** Every past daily is its output (`testDailyVectors`, `testEndlessVectors`): never
  change a draw.
- **`Level.print` is spelt out, never through a description** (`testThePrintNeverChanges`): a change drops every
  resume save.
- **Unstir.metal and its Swift copy (`Tank.profile`, `Tank.twist`, `Tank.lens`) change together.**
- **No later pack joins the bundle** (`Pack.bundled`, `testNoLaterPackJoinsTheBundle`): a later bundle is its own
  product.
- **"Jack's call" marks a decision.** Never change what one decided without asking him.
