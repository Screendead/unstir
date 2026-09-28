# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Unstir is an iPhone puzzle game (SwiftUI + Metal, iOS 17, Swift 6, portrait only). Rods under a tank of picture twist
it; the player unwinds the scramble by turning rods back in the right order.

## Git, pull requests and CI

- **Branch and PR for every change.** Never commit to `master`. Jack has given standing permission to create branches
  and open PRs without asking.
- **Commit only after Jack reviews.** When a feature or a round of ideation is finished, stage it and ask Jack to review
  the staged diff. Commit once he's reviewed it, not before, and not partway through the work.
- **Atomic commits.** Changes that belong together go in one commit. Separate changes go in separate commits, even when
  that means splitting one file's diff line by line (`git add -p` is interactive, so build the partial patch and use
  `git apply --cached`).
- **Merging.** Jack holds merge authority. Once he has seen the diff, a spoken OK from him is enough approval for Claude
  to merge the PR.
- **Push only when a build is needed.** `.github/workflows/test.yml` runs only on `pull_request` events: when a PR
  is opened, reopened or pushed to. It skips pushes that change only `*.md` files, and it stops any run at 10 minutes.
  Pushing to a branch with no open PR builds nothing. Never add a `push:` trigger: it builds every push to every
  branch, PR or not. Keep commits local until the next build is worth paying for. If a build takes more than
  5 minutes, raise it with Jack: the approach to builds needs rethinking.
- **Watch CI spend.** Before each push that builds, run `scripts/ci-usage.sh`, which prints this month's GitHub Actions
  allowance left. Tell Jack when 50% is left, and warn him urgently at 25%. Public repos, this one included, don't
  use the allowance. macOS minutes in private repos count 10×.

## Keep the repo free of personal details

The repo is public. Nothing personal or confidential goes into a tracked file, a commit message or a PR: no device
UDIDs, account or membership status, money, usage history, email addresses, local paths or anything else about Jack
beyond his first name. Such notes go in `HANDOFF.private.md`, which is gitignored and exists only on this Mac.
Machine-specific values come from environment variables. Before asking for a review, check the staged diff for
personal details.

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
- Device log: `scripts/pull-log.sh [--sim] [dest]` copies `Library/unstir-log.txt`, the flight recorder written by `Log.write`.

## Architecture

- **Twist.swift** holds the core model and has no UI. A scramble is a stack of `Twist(rod, steps)` entries (30° per step),
  applied bottom first. `Tank.twist`/`Tank.profile` is the point map: a rigid disc core out to `plateau` (0.6), then a
  smoothstep shear ring. `Array<Twist>.commit` is the one rule for every move. A turn merges into the rod's newest entry
  when everything above that entry commutes with the turn, and pushes a new entry otherwise. Commutation is decided
  geometrically (non-overlapping discs), or by sampling the maps on `Tank.samples` when the discs overlap. An entry that
  merges to 0 steps pops. `Layout.looksSolved` checks the stack against the identity to half a pixel.
- **Unstir.metal** is the GPU copy of the same map. It applies the stack's inverses to sample the picture. The tests
  only reach the Swift copy (`Tank.profile`/`Tank.twist`), so change the two together. The shader's tap count and the
  `Tank.maxStack` (36) and four-tap limits in `Unstirred` are tuned against 120 Hz on an iPhone 13 Pro Max.
- **Levels.swift** has the 27 hand-written campaign levels (scramble strings like `"2:+3,0:-5"` fed through `parse`, so
  they merge exactly as play would), nightmare / Nightmare+ variants (ids prefixed `N` / `N+`), daily and endless
  (`SplitMix64`-seeded generator). The generator is ported draw for draw from an earlier prototype, and
  `testDailyAndEndlessVectors` pins its output. Progress (`Best`, started flags, undo bank) is kept in `UserDefaults`.
- **TankView.swift** holds `Game`, the per-level state: stirs, moves against par, undo, hints, clean-solve rules and the
  endless spill. It also holds `LevelView` (drag gesture → live twist → `Game.commit` on lift), the `Unstirred` shader
  modifier and the result card. Wins run the coarse `looksSolved` pass on the main actor and the fine pass off it.
- **Pictures.swift** bakes the neon pictures once per size. Nightmare+ is drawn live by its own shader instead.
  Campaign pictures are designed so that "up" is readable inside every rigid core.
- **UnstirApp.swift** holds `RootView` and the `Harness`. The harness reads `UNSTIR_*` environment variables at launch
  (passed as `SIMCTL_CHILD_UNSTIR_*` by the scripts). They pick a screen, level, mode or stack, and can hold a
  mid-drag turn, a hint, the solve wave, autoplay or a frame-time bench (`UNSTIR_BENCH`). This is how screenshots and
  films are taken without touch; see `scripts/shots.sh` for examples. To show a visual change, add a `shot` line there.

Many tests are regressions from real play (e.g. `testNightmare11UnstirsToEmpty`, `testVisibleSmudgeIsNotSolved`).
Others check the level tables against the design tables (par, inversion counts).
