# Handoff — Unstir

*Updated 2026-09-28. Audience: the next agent, or Jack. This file holds the current task: the plan, where it stands,
open thoughts, and the options set aside. Update it when a step closes or a call is made. Git holds the history. The repo is public: personal and account
details go in `HANDOFF.private.md`, which is gitignored.*

## The current task: take Unstir to market

Find out whether the game is worth releasing commercially, and if it is, how to price it and get it noticed. So far
this is analysis. No code has changed for it.

### Where things stand

| Item | State |
|---|---|
| Competitor scan | Done 2026-09-28, quick pass (see below) |
| Business-model recommendation | Proposed 2026-09-28; **Jack has not decided** |
| Monetisation code | None. No StoreKit, ads or sharing in `Sources/` |
| Undo bank | Starts at 10 and nothing refills it (`Sources/Levels.swift:210`). This is the pricing hook, and it is still open |
| TestFlight | Not started |
| CI | Tests every pull request (merged 2026-09-28). First run 4 min 37 s, close to the 5-minute line. `scripts/ci-usage.sh` reports spend. CodeQL (`codeql.yml`, replacing GitHub's default setup, which never built) scans the workflows on every PR, and Swift on merges to `master` and weekly (Jack, 2026-09-28): the Swift build takes about 17.5 min under CodeQL. Free, since the repo is public; if it ever goes private, each Swift scan costs about 190 of the 2,000 minutes |
| `master` ruleset | Jack turned off "require code scanning results" and "require code quality results" to unblock PR #2. Claude's view: with Swift scanned only after merges, requiring code scanning on PRs would gate only the workflow files, so leave it off until the server code exists, then scan that on every PR and require it; leave code quality off, as its run fails on GitHub's side ("requested model is not supported") and whether it covers Swift is unchecked. Revisit it with the server code |
| Difficulty tiers | In progress on branch `difficulty`; see "Side task" below |
| Performance pass | Queued after the difficulty tiers (Jack, 2026-09-28); see below |
| Architecture pass | Queued after the performance pass (Jack, 2026-09-28); see below |
| Media out of git | Done 2026-09-28: history rewritten, re-signed and force-pushed; `.git` went from 311 MB to 264 KB. `difficulty` is PR #2; see below |
| README | Asked for (Jack, 2026-09-28); written after the media clean-up; see below |
| Copyright headers | Decided (Jack, 2026-09-28): every code file names Jack in full as the copyright holder, 2026. His name is public already (the commit email's domain); see below |
| Apple Developer membership | See `HANDOFF.private.md` |

### The plan

1. **TestFlight with 20–50 strangers.** Watch whether they get the goal without help, where they get stuck, and
   whether they come back for the daily. Day-2 return is the number to watch.
2. **A share line for the daily result**, Wordle style (e.g. `Unstir #142 · 7 moves (par 6)`). The daily generator
   already exists; the sharing does not.
3. **3–5 short clips** of a picture snapping back, recorded with `scripts/film.sh`, posted to TikTok, Reels and Shorts.
   See whether anyone cares before spending money.
4. **Choose the model from what testers do**, then set up the App Store page, preview video and a featuring request.

### Recommended model (not decided)

Free, with one purchase that unlocks the rest (full campaign, Nightmare and Nightmare+, endless). The daily stays free
for good because it is the marketing. Undos refill daily and are never sold.

## Side task: the difficulty tiers (started 2026-09-28)

Jack's asks: Nightmare+'s animated backgrounds become Nightmare's; Nightmare should have several live backgrounds, as
the campaign has several pictures (any colours); Nightmare+ needs something genuinely novel and a real step up; the way
from Nightmare to Nightmare+ is easy to miss.

| Item | State |
|---|---|
| Nightmare on the live background | Done and reviewed; committed on `difficulty`, not pushed. The baked cracked glass is deleted |
| More live backgrounds | Set, palettes, twins and level table decided (below); all ten ported with the heartbeat in the twins' lines, tests passing; Jack approved the films and the cost. Staged for review. `fillEntries` stay Mac-measured: no phone benches until the performance pass (Jack) |
| Nightmare+ design | Recommended below; **Jack has not decided** |
| The way in | Recommended below; **Jack has not decided** |

**Recommended Nightmare+ (not decided): the seized rod and the turning tank.** N+k is Nightmare k's scramble with one
or two seized knobs (never the hub). The whole tank turns one rod over (the layout's symmetry: 120°, 90°, 180°, 72°,
60°), carrying seams under working knobs; a knob untwists whatever seam sits under it, exactly (a rigid turn maps a
twist on one rod onto the rod it lands on). A tank stir is one move and adds no stack entry. The new skill is routing:
turn a seam to a working knob, and keep the ring you will need free. A model of the levels says planning matters on
about 10 of the 27 (quad, pent and hex); on tri and eye it is routine. Par is built on a stated rule so a clean never
depends on stack order the glass hides. About 3–4 days; the go/no-go is whether a finished ring reads on hex glass
and how dragging the rim feels on the phone. Claude's view: make N+ only the levels where planning matters, and let
the last heal finish the level instead of a final turn home (in the model, dropping the return keeps all 27 fair and
planning matters on 11).

**Backgrounds (Jack's calls, 2026-09-28).** All five ship in Nightmare: the cracked glass, chainmail (interlocked
rings, where a broken circle reads as a seam at once), a brain-coral labyrinth, a neural web and marbling rings.
Palettes: chainmail ember and blood, coral hot pink, neurons indigo, the glass unchanged, marbling green (its
designer's pick, toned down in the port).
Nightmare+ gets different backgrounds, more dire than Nightmare's, and Claude has creative licence there. Claude's
direction: each Nightmare picture gets a dire twin (the same place later that night, gone wrong: a malignant palette,
decay in the structure, and a 1 s heartbeat that also tells the tiers apart at a glance). N+k shows the twin of Nk's
picture. Jack reshaped the heartbeat: the twins' drawn lines themselves swell and brighten, and the beat radiates
through them by Perlin-type noise instead of landing everywhere at once. It lives in the picture (Jack's call). Being
stirred with the picture, the beat's direction inside a turned core shows how far the core turned; that costs little,
since probing already finds the amount for free and the order stays hidden. A screen-space version was built first and
rejected. As built, a line swells to about 1.9× its width and 2.1× its brightness at the lub; glows brighten but
never widen, so each design's clearances hold; the front crosses the tank in about 0.4 s and all is at rest by 0.9 s.
Jack approved the films. A twin reuses its sibling's data and must read
at least as well: the step up comes from Nightmare+'s rules, never from a murkier picture. Round 2 fixed the Nightmare
versions and made the twins. Every one reads a heal at phone size and holds up at 28 stirs (Mac renders). Neurons'
lattice imprint is gone. Coral's heal now reads, at the price of stripes that run straight for a stripe or two, so it
stays on shallow levels. Jack judged the chainmail and neurons twins too close to recolours; a third round made them
barbed rust with a few links still burning, and a dead dun web with inflamed scarlet nodes. GPU cost against the glass, Mac only: chainmail about 1.04×, coral 1.03×, neurons 1.18×, marbling
0.76×. With the heartbeat each twin costs 1.16–1.24× its sibling, over the 1.1× the designs aimed for, about one
stack entry more (`fillEntries` 4–6); Jack accepted that, and the performance pass is where to win it back.

Level table (Jack agreed, 2026-09-28); N+k shows the twin of Nk's picture:

| Picture | Levels | Why |
|---|---|---|
| Glass | 1, 9, 14, 19, 23, 26, 27 | Opens each layout; the deepest levels |
| Chainmail | 3, 10, 13, 18, 21, 24 | |
| Coral | 2, 5, 8, 16 | 6 stirs or fewer |
| Neurons | 4, 7, 11, 17, 20 | 14 stirs or fewer; the dearest |
| Marbling | 6, 12, 15, 22, 25 | The cheapest, so it takes deep levels |

Still open: the glass's faint square-grid imprint (measured on renders, not seen in play); the glass twin's crazing,
which finds its second-nearest border in a 3×3 search and so gets about one or two pixels a frame wrong beside a
hairline (a 5×5 search fixes it at a cost; Claude's view: leave it); and a GPU-side bench on the
phone. Instruments in Xcode 26.6 lists the phone (iOS 27) as offline, and a trace over USB left the app on a black
screen until it was quit.
The harness bench (`UNSTIR_BENCH`) sees only main-thread stalls; on this branch it held 120 Hz on Nightmare glass at
26 entries and the drag.

**Runner-up: Bookkeeping.** In N+ the fluid doesn't follow the finger: the knob shows a step count, the stir plays on
release, every release is a move, and a line lists the sizes of the remaining entries. About a day, but it is nearer
"Nightmare without the safety net" than a new skill.

**Recommended way in (not decided):** one "campaign · nightmare" strip above the list replaces the header toggles,
and each Nightmare row gets its own "+" cell. N+k opens when Nightmare k is at par with no hints; the result card that
opens one says so and offers it. N+ levels are labelled "+01". Today the "+" reads as part of the word "nightmare+",
turning nightmare off leaves the "+" on out of sight, and once both tiers share a picture nothing on screen tells them
apart.

## Next: the performance pass (queued 2026-09-28)

Jack's aim: the app looks and feels exactly as it does, and runs as fast as it can be made to, even if that takes very
clever work under the hood.

**The bar.** Output stays the same: the shots, films and the live pictures' designs match today's to within float
noise. Every level's heaviest frame (its deepest stack, the drag, a live picture and Nightmare+'s heartbeat) holds
120 Hz on the reference phone (iPhone 13 Pro Max) with four taps. Less heat and battery for the same frames.

**Measure first.** Jack has ruled out phone benches before this pass: they are slow, and heat skews them. One series
of twelve runs with 45 s rests between them reached "serious" by the fourth. None of the tools sees the phone's GPU yet:
- Instruments in Xcode 26.6 lists the phone (iOS 27) as offline. An Xcode that supports iOS 27 is the first fix, and
  it is Jack's to install.
- The harness bench (`UNSTIR_BENCH`) times main-thread intervals only, now with the thermal state. Back-to-back runs
  seem to heat the phone: in one session, even the cheapest picture dropped about a fifth of its frames after nine
  minutes of runs, and a picture that dropped frames early on held 120 Hz after a cool-down. Cool down between runs.
- A GPU clock in the app would settle it without Instruments: an offscreen harness that runs the same Metal source in
  its own command buffers and reads their GPU start and end times.
- The background sheet tool (a Mac renderer and benchmark) lives only in a session scratchpad, which the OS can
  clear. It is worth moving into the repo as a dev tool.

**Candidate ideas (Claude's, untested; each must earn a measured gain on the phone):**
- **Cache the twist chain.** The stack changes only on a commit, yet every frame on a live picture runs each pixel's
  four taps through every entry just to find the same sample points. Store the committed chain's per-tap source
  points in a texture when the stack changes, and each frame only sample the picture there. During a drag, the map is
  exactly the identity outside the live disc, so only that disc's pixels need the full chain. That turns a deep
  frame's cost from per-entry to near constant, and could retire `fourTaps` and `fillEntries`. It needs a Metal path
  of its own (SwiftUI's `layerEffect` keeps no textures between frames) and enough precision in the stored points.
- **Derive taps from one.** Where the map is locally rigid (every core, and outside every disc), the four taps are the
  centre tap moved by the map's Jacobian. Carry the Jacobian through the chain for one tap, and run all four only
  where the stretch says a filament needs them.
- **Per-frame CPU work off the main thread**: the live pictures' data and the heartbeat's delay grid.

**Claude's view.** Cleverness costs maintainability, and the architecture pass comes straight after. Keep each trick in
one place with its reason stated, and drop any that doesn't pay on the phone.

## After that: the architecture pass (queued 2026-09-28)

Jack's aim: audit the app's architecture and design for extensibility, maintainability, and the cost of implementing
new features with Opus 5.5 or later.

**What "cost" means for an agent:** how much it must read to make a typical change, how many places a feature
touches, and whether the harness and tests let it check its own work without a person or the phone.

**Starting observations (from the difficulty-tiers work, not yet an audit):**
- `TankView.swift` holds `Game`, `LevelView`, the shader modifier and the result card in about 830 lines.
- A new live picture touches six places: `Picture`, a `.metal` file, `LivePictures.swift`, the level table, the tests
  and `shots.sh`.
- The shaders have no tests except the neural web's clearance scan. Their fidelity checks ran in the scratchpad.
- The harness is one flat set of `UNSTIR_*` variables in `UnstirApp.swift`.

**Output:** a ranked list of changes, each with its payoff and cost, for Jack to pick from. Score it against the
features that are coming: the Nightmare+ mechanic, the way in, the StoreKit unlock and the daily share line.

## The Apple Developer account

Account status is in `HANDOFF.private.md`. A membership runs 12 months from the day it's bought, so buy it when
TestFlight is ready, not earlier; that gives the first year the most selling time.

**Needs the paid account:**
- TestFlight, for testers beyond your own devices (plan step 1)
- App Store Connect: the app record, reserving the name, the store page, submitting
- Selling anything: in-app purchases, and sandbox testing of them against App Store Connect
- The Small Business Program's 15% rate (you apply once you're a member)
- Game Center and push notifications, if either is ever wanted
- Profiles that last a year; a free team's expire every 7 days

**Works without it:**
- Everything in the simulator: development, tests, `shots.sh`, `film.sh`
- CI, which builds unsigned (`CODE_SIGNING_ALLOWED=NO`)
- Running on your own phone, and on a friend's plugged into your Mac, with a free team (re-signed every 7 days)
- Building the unlock with StoreKit 2 and testing it locally with a StoreKit configuration file in Xcode
- The daily share line, the clips, and the screenshots and preview video for the store page
- Checking whether the name "Unstir" is taken. A web search on 2026-09-28 found no app by that name, but only App
  Store Connect can confirm it

## The repo is public (Jack's call, 2026-09-28)

Jack's reasoning: hardly anyone will clone, build and sideload it to avoid paying a small price, and anyone with Claude
could rebuild the game in hours anyway. The bet is on being first to market with the most polish.

Claude's view: public is fine, and GitHub Actions is free for public repos, which is a real saving for an iOS
project. The risk isn't players. It's clone studios that re-skin working code and ship it with ads. Two things help:

- **Don't add an open-source licence.** With no licence, the default is all rights reserved: people can view and fork
  it on GitHub but can't ship it. That's what gives you grounds for an Apple content dispute against a copy that uses
  your code or art. Adding MIT or similar gives that away.
- **Keep secrets out.** Signing keys, App Store Connect API keys and any future server keys belong in GitHub Secrets,
  not in the repo.

The "rebuilt in hours" argument cuts both ways: if the game can be copied that fast, being first only lasts a few
weeks. That's a reason to ship soon, not to rely on being first.

## Media out of git (Jack's call, 2026-09-28)

`.git` was 311 MB, of which code and docs were 0.3 MB; the rest was shots and films. PNGs and MP4s neither delta nor
compress, so every re-render added its full size for good, and every clone and CI checkout downloaded all of it.

- `shots/` stays in the working directory, ignored by git, except `shots/index.txt`. The scripts still write there.
- `git filter-repo` removes the media from every commit, including the three comparison folders from the first
  commit (`v1`, `before`, `v2-before-tune`); nobody remembers what they compared. Then force-push `master` (Jack
  approved this in advance) and delete the merged `process-and-ci`.
- Order: untrack the media in a commit before the rewrite, so the rewrite's reset leaves the files on disk. Keep a
  throwaway bundle in the scratchpad until the push is checked.
- GitHub keeps PR #1's own ref to the old commits, so their media stays on that PR page; clones and CI don't fetch it.
- Kept in git: a few README images at 440 px wide as WebP, 40–50 KB each. Claude's suggested set: `grid-d2-right-half`
  (the mechanic, mid-drag), `level05` (sunset), `level27` (deep hex) and `nightmare24-chainmail`. **Jack has not
  picked.** There is no README yet.
- Pictures for a PR get attached to its description or comments, not committed. GitHub has no API for those
  attachments, so it takes the browser: Chrome's file upload into the comment box works (PR #2), with Jack signed in
  to GitHub there. Videos must stay under 10 MB; crop films to the tank and re-encode.

**For the next rewrite.** `filter-repo` strips commit signatures, and the `master` ruleset requires signed commits and
blocks force-pushes with no bypass. So re-sign every rewritten commit (`git commit-tree -S` per commit, keeping authors
and dates), have Jack pause the ruleset, and expect Jack to run the force-push himself: auto mode refuses it.

**Order (done).** Jack reviews the heartbeat; commit the difficulty work without its media; untrack the media; rewrite and
force-push `master`; push `difficulty` and open its PR. After that merges, one `housekeeping` branch carries the
copyright headers and the README, so the new files get headers too.

**README.** What Unstir is, the picked images, how to build, run and test (from CLAUDE.md), and that the code is all
rights reserved with no licence (see "The repo is public").

**Copyright headers.** One line at the top of every `.swift`, `.metal` and `.sh` file (after a script's shebang):
`Copyright © 2026` and Jack's name, `All rights reserved.` CLAUDE.md gains the rule, so new files get it, and its
personal-details rule makes an exception for this line. The header records ownership; copyright exists without it.

## Competitor scan

Done 2026-09-28: a handful of US-only web searches, not the App Store's own search. **Before claiming "unique" in a
pitch**, search the App Store directly for twist, swirl, unwind and untwist, in more than one language.

Found (from the store pages and the SWIRL site):

- **SWIRL** (take5games.com/swirl). Two swirls warp a picture and you drag two dots freely to undo them. There are no
  fixed steps, no stack and no order to unwind. Seen on the web only; not confirmed on iOS.
- **Spin the Wheel: Magic Puzzles** (Tapotap, Sept 2025, 4.6★ from 21 ratings). The photo is cut into rigid concentric
  rings that turn independently, so order doesn't matter.
- **Swipe the Picture: Puzzle** (EvokePlanet). Rigid rotating rings reveal a picture. Too few ratings to show.
- **Untie the Rings**, **Rotate Rings** and Hungarian Rings clones. Overlapping rotations where order matters, but they
  move coloured pieces, not a warped image.

Inferred: nobody combines a smooth warp with a rigid core and sheared ring, twists that must be undone in order, and
discrete 30° steps against a par.

## Thoughts

- **A mechanic can't be protected.** Copyright doesn't cover mechanics (Threes → 2048). Expect a free, ad-funded copy
  if Unstir takes off. The defence is polish that's hard to copy and getting there first.
- **Discovery matters more than price.** The daily plus sharing, and clips that are satisfying to watch, are the two
  built-in advantages.
- **Apple featuring** tends to go to well-made games with no predatory monetisation, which fits the recommended model.
- **No revenue forecast.** There are no reliable numbers for this niche, and a made-up forecast is worse than none.
  Most indie puzzle games earn little; the few that do well usually got a viral moment or Apple featuring.
- **The biggest unknown is whether strangers find it fun.** Step 1 answers that cheaply.

## Set aside, with reasons

These are recommendations against, not Jack's calls, unless the entry says so. Keep every entry: if one is picked
back up, note the date and why.

### R1 — Premium only ($2–5 up front)

Clean, and suits the crafted look. But few people download paid apps, and a new name with nothing to try first makes
that worse. Revisit if Apple features the game, or if testers say they would pay up front.

### R2 — Sell undo packs

The undo bank makes this the obvious in-app purchase. It was set aside because a puzzle built on careful, clean solves
would feel like it was selling the answers, and reviews punish that. Daily refills keep the bank without the sale.

### R3 — Rewarded ads or banner ads

The highest possible revenue, but it breaks the clean-solve feel, looks like the clones this game has to stand apart
from, and works against Apple featuring. Revisit only if the unlock plus the daily both clearly fail.

### R4 — Picking the model before TestFlight

Pricing depends on how often players return and how far they get. Choosing now would be a guess.

### R5 — Nightmare+ ideas set aside (2026-09-28)

Each was judged on what skill it tests that Nightmare doesn't.

- **Turning the tank in 30° steps.** Rigid cores land on other cores, and every probe in every position becomes free.
  The symmetry-step version gets the same effect without that.
- **Fewer knobs than rods, carried by tap.** The seized-rod idea plus admin; a tap to lift fights the drag gesture.
- **No live preview on some rods.** Leaks: a wrong commit turned straight back joins its stir and costs nothing.
- **Geared rods.** Easier, not harder: one probe heals both seams. Two entries per stir breaks the stack budget.
- **Lights out, with a film of the scramble.** Tests memory, not reading, and keeps the tier dark.
- **No free looks** (a budget on probes). Nightmare with a limit, and a sub-detent wiggle still peeks for free.
- **Commits go under the stack.** Its outline gives the answer away; without it, it is murk.
- **Record a stirring pattern and crank it.** A clean needs a read many entries deep before the first move, and it
  needs 27 new levels.
- **Diffusion scars on wrong probes.** Right and wrong probes don't separate at Nightmare depths, so the penalty lands
  at random, and it breaks exact inverses.
- **Make the tank match a target stir.** A second live picture breaks the shader budget; three sub-modes to teach.
- **A telegraphed second stirrer.** Its queue works as an answer key, and it adds animation to every move.
- **Two tanks sharing stirs.** Two tanks on one phone screen are too small to read, and it is the largest refactor.
- **Every touch counts.** Tests no new skill, and leaks the same way as no free looks.

### R6 — Nightmare backgrounds set aside (2026-09-28)

- **Truchet grains.** Its grain borders are the glass's own cell network at a larger scale, and it turns to haze at
  depth.
- **Sonar stations.** The beam arms read as needles and move far faster than anything else; dark wedges fake seams.
- **Contour map.** Some seeds draw a valley across the whole tank (a direction), and contours look like shear rings.
- **Crystal shards.** Reads as pick-up sticks, the busiest clean tank, and haze in the shear rings.
