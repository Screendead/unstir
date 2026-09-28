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
| CI | Workflow written on branch `process-and-ci`; waiting for Jack's review. `scripts/ci-usage.sh` reports spend |
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
