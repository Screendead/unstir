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
  to merge the PR.
- **Push only when a build is needed.** `.github/workflows/test.yml` runs only on `pull_request` events: when a PR
  is opened, reopened or pushed to. It skips pushes that change only `*.md` files, and it stops any run at 10 minutes.
  Pushing to a branch with no open PR builds nothing. `.github/workflows/codeql.yml` scans the workflows on every PR to
  `master`, `*.md`-only ones too, in case the `master` ruleset requires code scanning. It scans Swift, which takes
  about 18 minutes, only on pushes to `master` (only merges make them) and weekly. Never add a `push:` trigger for any
  other branch: it builds every push, PR or not. Keep
  commits local until the next build is worth paying for. If a build takes more than
  5 minutes, raise it with Jack: the approach to builds needs rethinking.
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

- Build: `scripts/build-ios.sh [Debug|Release] [device|sim]` (defaults to Debug, device; prints only errors, warnings and the result)
- Install and launch on the reference phone: `scripts/run-ios.sh [Debug|Release]` (needs `UNSTIR_DEVICE`, the phone's UDID, set in the shell)
- Tests (XCTest, on a simulator):
  ```
  xcodegen generate --quiet && xcodebuild test -project Unstir.xcodeproj -scheme Unstir \
    -destination 'platform=iOS Simulator,name=Unstir iPhone 17 Pro Max' -derivedDataPath build CODE_SIGNING_ALLOWED=NO
  ```
  To run one test, add `-only-testing:UnstirTests/UnstirTests/testPush`.
- Screenshots: `scripts/shots.sh [pattern]` builds for a Pro Max simulator, launches each harness case and writes
  `shots/<name>.png`, with a description of each in `shots/index.txt`.
- Films: `scripts/film.sh [pattern]` records animations to `shots/film/*.mp4` with a frame strip each (needs ffmpeg).
  Git ignores `shots/` apart from `index.txt`: show pictures and films in a PR by attaching them to a comment through
  Chrome (GitHub has no API for attachments; videos under 10 MB), never by committing them.
- Workflows: `actionlint .github/workflows/*.yml` (Homebrew's `actionlint`) before pushing a change to one.
- Device log: `scripts/pull-log.sh [--sim] [dest]` copies `Library/unstir-log.txt`, the flight recorder written by `Log.write`.

## Architecture

- **Twist.swift** holds the core model and has no UI. A scramble is a stack of `Twist(rod, steps)` entries (30° per
  step), applied bottom first. `Tank.twist`/`Tank.profile` is the point map: a rigid disc core out to `plateau` (0.6),
  then a smoothstep shear ring. `Array<Twist>.commit` is the one rule for every rod stir. A turn merges into the rod's
  newest entry when everything above that entry commutes with the turn, and pushes a new entry otherwise. Commutation is
  decided geometrically (non-overlapping discs), or by sampling the maps on `Tank.samples` when the discs overlap. An
  entry that merges to 0 steps pops. `Layout.looksSolved` checks the stack against the identity to half a pixel. The
  stack names the glass's own rods (slots), so a turn of the tank never touches it: `Layout.order`/`tankStep` are the
  layout's rotational symmetry (hex's hub held still), which sets each rod's twist exactly on a rod of the same size,
  and `slot(of:at:)`/`knob(over:at:)` map a physical knob to the slot under it at a tank position.
- **Unstir.metal** is the GPU copy of the same map. It turns the sample point back by the glass's `turn`, then applies
  the stack's inverses to sample the picture. The tests only reach the Swift copy (`Tank.profile`/`Tank.twist`), so
  change the two together. The turn has no Swift copy: only the `seized-*` shots pin its sign against `Layout.behind`.
  The shader's tap count and the `Tank.maxStack` (36) and four-tap limits in `Unstirred` are tuned against 120 Hz on an
  iPhone 13 Pro Max, before the turn was added; its cost per tap is unmeasured. A live picture's own cost comes off the
  four-tap limit as `Picture.fillEntries`, scaled from Mac GPU costs and unconfirmed on the phone.
- **Glass.metal**, **Chainmail.metal**, **Coral.metal**, **Neurons.metal** and **Marbling.metal** draw Nightmare's live
  pictures, one family per file: a stitchable named after each `Picture` case (`glass`, `glassPlus`, ...), the
  Nightmare+ twin being the same body with `plus` set. Each file stands alone. Nightmare+'s heartbeat lives in the twins'
  own lines: each file's `heartbeat` reads the delay grid `Picture.delays` appended to the twin's data, and the lines
  swell and brighten as the beat passes, so it is stirred with the picture. A swollen line must keep inside its design's
  limits (neurons' regions, chainmail's early-out). `testNeuronsStayInTheirRegions` compiles Neurons.metal itself and
  checks its search against a brute force, the twin at the beat's peak; nothing else tests the shaders.
- **Levels.swift** has the 27 hand-written campaign levels (scramble strings like `"2:+3,0:-5"` fed through `parse`, so
  they merge exactly as play would), nightmare / Nightmare+ variants (ids prefixed `N` / `N+`; Nightmare's pictures
  follow a table, and N+k shows the twin of Nk's), daily and endless (`SplitMix64`-seeded generator). The generator is
  ported draw for draw from an earlier prototype, and `testDailyAndEndlessVectors` pins its output. Progress (`Best`,
  started flags, undo bank) is kept in `UserDefaults`. A `Level` may have `seized` knobs, which ignore touch; the tank
  turns only on such a level. `par` is `fixedPar`, else `scramble.count`.
- **TankView.swift** holds `Game`, the per-level state: stirs, moves against par, undo, hints, clean-solve rules and the
  endless spill. `Game.commit` takes a physical knob and commits to the slot under it. `Game.turnTank` is a move that
  pushes no entry: turns in a row join, and one netting a whole turn drops. `Game.history` holds rod stirs by slot and
  tank stirs as rod `Game.tank` (-1), so an entry is not always a rod index. It also holds `LevelView` (drag on a knob →
  live twist → `Game.commit` on lift; where knobs are seized, a drag on the rim or a two-finger twist → live tank turn →
  `Game.turnTank`), the `Unstirred` shader modifier and the result card. Wins run the coarse `looksSolved` pass on the
  main actor and the fine pass off it.
- **Pictures.swift** bakes the campaign's neon pictures once per size. Campaign pictures are designed so that "up" is
  readable inside every rigid core. Nightmare's five (glass, chainmail, coral, neurons, marbling) and their Nightmare+
  twins withhold it and are drawn live instead: `PictureLayer` hands each shader the clock mod the picture's `period`
  (a minute for a twin, its heartbeat's loop) and the floats from **LivePictures.swift**, seeded by level. The glass's
  cells take the raw clock; the neural web is static per seed, built once off the main actor.
- **UnstirApp.swift** holds `RootView` and the `Harness`. The harness reads `UNSTIR_*` environment variables at launch
  (passed as `SIMCTL_CHILD_UNSTIR_*` by the scripts). They pick a screen, level, mode, stack, seized knobs
  (`UNSTIR_SEIZED`) or tank position (`UNSTIR_TANK`), and can hold a mid-drag turn of a rod (`UNSTIR_LIVE`) or the tank
  (`UNSTIR_TANKLIVE`), a hint, the solve wave, autoplay or a frame-time bench (`UNSTIR_BENCH`). This is how screenshots
  and films are taken without touch; see `scripts/shots.sh` for examples. To show a visual change, add a `shot` line
  there.

Many tests are regressions from real play (e.g. `testNightmare11UnstirsToEmpty`, `testVisibleSmudgeIsNotSolved`).
Others check the level tables against the design tables (par, inversion counts, Nightmare's pictures).
