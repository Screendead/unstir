# Handoff history

Closed sections moved word for word out of `HANDOFF.md`, which every session reads at its start. Each section keeps its own
headings; `HANDOFF.md` says where each was. Jack's calls in them are indexed in `docs/decisions.md`.

### Open work (finish-and-pitch, 2026-11-02)

The run's list. **Decided** (Claude does it): #115; LG3's leftovers (Store.swift's two whole-`error` logs, privacy-policy.md's "only thing it talks to" without the age-range check, the undo-bank row's monotonic-clock text, from local `legal-lg3`'s three commits); the Duo's stages 2 to 4; the shots and films owed (#81's indexed shots, `film.sh calm-`, the dock waking, nav-focus's menu shots); the store screenshots and 25 s preview (ST4, ST5); plan step 3's clips; the architecture pass's ranked list; pack sound sketches (to-do 45, ends at Jack's ear). **Unblocked by round 16**: the String Catalog migration (F4 = C, about five days; CAT1 to CAT8 = A), in ORDER's place after the design pass. **Undecided** (to Jack's pitch): the UI design pass (to-do 72); round 16's follow-ups (below). Round 16 answered the rest. **Jack's to-dos**: device checks, the developer account and App Store Connect, Eyes Shut's outreach (Triptych's trademark check is done: clear). **Round 16 answered every call** (the table under round 15's): the work it decides follows ORDER. Follow-ups from the run: the
preview's "01: Calm" segment snaps to its end when the rim turns (Jack's note, STOREMEDIA; in the strike and cut
pipeline); `shots.sh` with a pattern rewrote `shots/index.txt` and dropped the two `prism-swatch-white-*` lines though
the script still defines them (cause found 2026-11-03: the `if` at `scripts/shots.sh:749` skips those two `shot`
calls when the pattern matches neither, so their index lines are never written on a patterned run; the fix, writing
those lines outside the `if`, is in no PR, and the lines are put back by hand meanwhile); `FreshDefaults` forgets
started flags and saved tries but not bests, so a second test run on the same simulator install fails
`testResetZeroesMovesButCostsClean`, `testALookIsFree` and `ShareTests.testMarksFollowThePlay` on the first run's
bests (found on stage 5, 2026-11-03; a reinstall clears it; the fix is in no PR); before the repo goes private at launch
(Jack's note on HISTORY), cost the PR and nightly runs against the Actions allowance, macOS minutes at 10x. Outputs
kept in the tools folder: the architecture pass's ranked list (`architecture/ranked.md`), the pack sound sketches
(local branch `sound-packs`), the owed shots and films (`owed-shots/`) and the store media (`store-media/`).

### Round 16's build (2026-11-02 night)

Merged: #126 (APPSIZE = B, the CI size guard, and pipefail in both Test steps), #127 (ICLOUD = A, bests through iCloud
key-value storage, off behind `ICLOUD = NO`), #128 (store media: the Calm segment's jump fixed, screenshot 4 on vortex
14 Monsoon, the preview cut to 25 s, the endless segment ending 1 s into the spilled card), #129 (SND1 = B, SND2 = A,
SND3 = B, C1A = B, C1B = A) and #130 (ESC-PAPER = B, Escapement on bone paper). #124 (Duo stage 4) followed on 2026-11-03.

DUOCAP = C: the stack limits were tuned on the 13 Pro Max's glass, about 1137 px, not 1300 px as the round 16 pitch
said, so it went back to Jack as duocap2. He picked **D** (2026-11-03): the upright glass at 1471 px, stacks as deep as
on an iPhone, only the four-tap limit shrinking there (to 17), built in #137; and duocap-step = **A**: 30 up to 1300
px, then the measured curve, so every iPhone and every pose drawn today stays as it is. #137 is held: #140 carries its
commits and replaces the fixed 17 with a controller (Duo headroom, below). The "1300 px, the size
the limits were tuned at" text in `Sources/PlayLayout.swift` (`maxPixels`) and CLAUDE.md is wrong: it should say
1137 px measured, with 1300 a round-up. Correct it in the DUOCAP build (#137, carried by #140), not before. Today's 1300 cap already sits
about 3% over the measured budget for a fill-6 picture pushed to 36 stirs, though no iPhone gets there.

Built outside the repo: the Eyes Shut test site (EYES1 = A), a local repo in the tools folder (`eyes-shut-site`);
Jack creates the GitHub repo and Pages from its README, swaps the Pages URL into the tester brief and posts, and runs
its Safari check on a real phone first. Three metal ratchet ticks for SOUNDSK on local branch `sound-packs`: C a
watch's escapement, D a steel pawl on a steel wheel, E a counter's click spring. Jack picked D (soundsk2 = D,
2026-11-03), merged in #138 with the defaults he kept (soundsk-defaults = A: -30 LUFS, four takes in turn, the
demonstration's ticks sound, each tick on its core's turn).

Store media (#128): the 25 s preview and the 14 s endless take are in the tools folder's `store-media/r16-fixes`; the
other four takes are still the old ones, so the final set waits on ORDER's retake. The proof frames aren't attached to
the PR (needs Chrome). The pitch page's vortex montage order was fixed locally, in no PR.

iCloud, before `ICLOUD = YES` ships: (1) turn on the iCloud capability (key-value storage) on the App ID, which
regenerates the provisioning profiles; (2) run a two-device test on one Apple ID, as nothing has yet talked to a real
store; (3) update `docs/privacy-policy.md` ("on your phone only, and never sends them anywhere"; "Deleting the app
deletes all of it") and `docs/store-page.md` (iCloud listed as not built); (4) only then set `ICLOUD = YES`. Commit
8d8cbf7 in #127 doesn't compile alone (a test written twice; db46f0b removes it).

Escapement on paper (#130) also took the dock's cover, the bundle's wedge and cut, the card's clip and the
promoted-purchase image to paper, as each draws the level's own picture. Known on paper: the result card's lime and
amber or magenta hints are drawn in ink; the clock-stop ring is the plate's vermilion, not amber; the lines over the
picture stay 0.5 pt, in ink (the 2 px floor is the picture's); sheared areas go pale, so the stirred plate reads pale
at dock-cover size, the risk the pitch named. The before and after shots aren't attached to the PR (needs Chrome).

Round 16's follow-up calls: Jack picked them on the round 16 page (2026-11-03). Built and merged the same day, each
after an adversarial review and fixes: #124 (Duo stage 4 with d3-lenscap, d4-menuback and d4-pose = B), #132 (the
iCloud picks: endless's best and the tried flags sync; the editors' build and the unlock never sync) and #133 (the
tank's drag silent, its sound removed; the sandbox withheld from Release, as First Stir is, kept in Debug and the
harness).

Jack's picks on the round 16 page (2026-11-03), the follow-ups and the calls their builds raised:

| Call | Jack's pick |
|---|---|
| lenscap2. What d3-lenscap's cap counts | **A:** the whole open stir, as built: lifted at the cap, the same lens zooms no further until another rod or the tank turns, or an undo. No Lens level reaches the cap |
| archive-close. The archive beside the list | **A:** it reads "✕ close" as the card does. Merged in #136 |
| store-sandbox. `docs/store-page.md` still sold the sandbox | **A:** drop its bullet and its mention (guideline 2.3). Merged in #136 |
| duocap2. The open Duo upright's glass | **D:** 1471 px, stacks as deep as on an iPhone, only the four-tap limit shrinking (to 17). Built in #137, held for #140 |
| duocap-step. Where the four-tap limit starts to shrink | **A:** 30 up to 1300 px, then the measured curve; every iPhone and every pose drawn today unchanged |
| soundsk2. Escapement's ratchet tick | **D:** the steel pawl on a steel wheel. Merged in #138 |
| soundsk-defaults. The tick's defaults | **A:** keep all four: -30 LUFS, four takes in turn, demonstration ticks sound, the tick on its core's turn |
| soundsk-layers. When the pack layers go in | **B:** one more listen first: each layer rendered under a real level's play. Rendered on local `sound-packs` (`scripts/sounds.sh layers`), renders in the tools folder; lay-esc follows from it |
| soundsk-pushtick. A tick that pushes | **B:** it plays the push sound at the tick's own time, with its flash. Built in #139 |
| soundsk-haptic. The tick's haptic | **B:** one tap per tick, with its sound. Built in #139 |
| s5-chrome. The level's header and controls beside the menu | **B:** round the tank, as the pitch's picture had it (not the recommendation, A). Jack: "Right of 'as built' looks cramped." Reworked on #135 |
| s5-title. The title and gear beside play | **A:** hidden while a level plays (reopened as s5b-title, since B removed its reason) |
| s5-card. A pack card or the archive while a level plays | **A:** over the right half, the level playing on |
| s5-paper. Escapement's paper beside the menu | **A:** bone wherever the level draws, the menu a black block |
| s5-swipe. The back swipe beside the menu | **A:** nothing slides; past the threshold the level leaves through the dip |
| s5-tabletop. The tabletop menu's dock and cards | **A:** the dock at the foot of the flat half, cards there |
| s5-playing. The row being played | **A:** the hairline plus "playing" under its title, its result kept |
| s5-clip. A card's clip beside a playing tank | **A:** it plays, until stage 6 benches a real Duo |
| appsize2. The guard's form and limit | **A:** keep the CI step at 100 MB, as merged |
| icloud-defaults. The four rules built | **A:** accept all four |
| icloud-editors. The editors' build and the unlock | **A:** no sync in the editors' build or under the unlock; their progress stays on that phone |
| icloud-endless. Endless's best | **A:** sync it too |
| icloud-started. Started flags | **A:** sync them: once tried anywhere, a level is tried everywhere |
| snd1-clunk. The rim drag's tank clunk | **B:** silence it too; every drag is silent, only the haptic marks the tank's steps |
| snd2-sandbox. The sandbox | No pick. Jack's note: the sandbox needs work and isn't in v1 (a player who unlocks packs should have their mechanics there too, which needs thought). Defer it and remove it from the build, as First Stir is withheld |
| store-endless-tail. The endless segment's end | **A:** as built, 1 s into the spilled card |
| paper-defaults. The paper build's five defaults | **A:** accept all five |
| paper-rm. A solve on paper under Reduce Motion | **A:** nothing on the picture; the card and the chime carry it |
| paper-vermilion. Two vermilions | **A:** keep both, as built |
| paper-accents. Magenta heal ring and cyan pointers on bone | **A:** keep both: the magenta heal ring is SND2's game-wide signal, and ink wouldn't show on the steel caps |
| paper-statusbar. The dark status bar during a back swipe | **A:** leave it: its dark glyphs can't be read over the black menu until the swipe commits or springs back |
| d2-cardpos. The card in the split and tabletop | **A:** caption and card centred together, as merged |
| d3-lenscap. A long lens drag on the Duo | **B:** cap the drag at what the pane can show |
| d4-one. A card and the archive beside the list | **A:** one at a time, as built |
| d4-empty. The right half with nothing open | **A:** empty, as built |
| d4-dock. The dock beside an open card | **A:** keep turning, as built |
| d4-table. The tabletop menu | **A:** leave it for stage 5 |
| d4-pose. A card open through a fold or unfold | **B:** keep the card's scroll position |
| d4-menuback. The card's back beside the menu | **B:** "✕ close" in the wide pose |
| order. The three big UI jobs | **A:** confirmed again, as ORDER stands (below) |

Round 16's third picks (Jack, 2026-11-04, on the round 16 page): the calls from the night of 2026-11-03's builds,
plus taps-keep, raised by #140's phone test that morning.

| Call | Jack's pick |
|---|---|
| s5b-glass. One glass size beside the menu, or one per list (#135) | **A:** a size per list, as built (424 pt for most, 419 maelstrom, 415 Escapement, 394 Prism with colour letters, 348 endless) |
| s5b-words. Where "unstirred." goes beside the menu (#135) | **A:** heading the card, over the menu half, as built |
| s5b-title. The title and gear while a level plays (#135) | **B:** shown, the trailing half the menu exactly as with no level open (the list gives up about 72 pt) |
| s5b-back. A pack card opened from a result card (#135) | **B:** "✕ close" while a result card is under it |
| tk-push. A pushed tick's sound (#139) | **B:** the ratchet and the push at the same instant. Jack: "It still stands out." |
| tk-multi. A move whose stir and ticks both push (#139) | **C:** only the move's first push sounds; later pushed ticks play the ratchet with the error haptic |
| tk-finish. The last move's ticks and the solve chime (#139) | **B:** the chime moves to the last tick. Jack: "The solve wave should also wait until the last tick, keeping the chime in step with it." |
| taps-floor. The lowest four-tap budget #140 may drop to | **A:** 12 on every device |
| taps-ceil. The highest it may climb | **A:** 42: maxStack 36 plus the heaviest live picture's 6 |
| taps-keep. Keep #140 once the 13 never needs it | **C:** a fixed 40 on phone-sized glass as the start, and #140 on for heat and the Duo |
| wp27-table. Whirlpool 27, 32 against the old limit of 30 | **B:** leave it as dealt (under the limit of 40 it draws four taps) |
| ci-time. The test job at its 10-minute limit | **B:** split it into build-for-testing (on the cache) and test-without-building. Jack: "Also investigate whether any of the time is being spent on tests or other tasks that don't actually meaningfully ensure quality." |
| lay-esc. Escapement B's layer in real play | **A:** leave it level |

#140's phone test (2026-11-04, the 13 Pro Max, Release, 1136 px glass, whirlpool 27 on the glass picture): every stack
the game deals, work 40, held 120 Hz at four taps, about 120 frames a second reaching the screen as an in-app probe
(local branch `archive/present-probe`, `UNSTIR_PRESENTPROBE`) read them. An overload, rods 0 and 1 masked and pinned at
four taps (work 97), fell to 36 to 67 frames a second, and the display link counted every miss, all read gpu: the link
sees the render server's misses. A main-thread stall's late frames read gpu nearly as often as cpu (7 of 15), so
`Taps.cuts` is `TapCuts.unattributed`. Instruments' Animation Hitches holds this phone's panel at 60 Hz while it
records, so its traces can't judge 120 Hz. The bench's whole-frame 8.815 ms for this load reads about 6% high.

Round 16's fourth picks (Jack, 2026-11-08, on the round 16 page): the calls raised while building the third picks.
All took the recommendation. Merged the same night: #147 (CI), #139, #140 and #135; #137 closed.

| Call | Jack's pick |
|---|---|
| r16c-pointer. Plughole 01's settings line beside the menu (#135) | **C:** not shown there, still stored as shown (built) |
| r16c-prismglass. Prism's glass resizing from the in-app letters switch (#135) | **A:** keep it |
| r16c-solvetick. A special tick's sound and haptic (#139) | **A:** the ratchet sound kept, the special haptic in place of the tap, as built |
| r16c-duoprior. The Duo upright's starting four-tap limit (#140) | **B:** rescaled from the phones' 40 and the entry in flight: 23 at 1471 px, 30 at 1300.5 (built) |
| r16c-ci-build. Chase the slow build step | **A:** investigate (findings below) |
| r16c-ci-limit. The PR job's time limit | **B:** 15 minutes (#147). The rule to raise a build over 10 minutes with Jack stands |
| r16c-ci-nightly. Split the nightly too | **B:** leave it as it is |
| r16c-ci-firststir. First Stir's two stray tests on PRs | **A:** skipped on PRs, kept nightly (#147) |

Also on 2026-11-08: Jack's call (in chat) that every dock cover draws its knobs, so a cover shows how its pack plays
(#146; Escapement's showed only its plate, never its clock), after #145 kept the plate ink on bone at a cover's size.
Open: whether the promoted-purchase images draw the knobs too (recommendation: yes; they would need re-uploading).
#140's last run took 10m22s and #135's 9m47s, both after merging master, under the new 15-minute limit.

The CI build investigation (r16c-ci-build, 2026-11-08), ranked by time on the critical path. Jack's calls: make 2 and 3,
let the phase lines through, measure the boot both ways, research 4 without `env -i`. Built in #150 (below the list).
1. The simulator's boot overlaps the build. Every build alongside it took 130 to 378 s; one that ran after the boot
   took about 75 s (inferred from 14 runs). Booting after the build may save 60 to 150 s of build against a boot no
   longer hidden: net uncertain.
2. Checkout gives every folder a new time and the stamping sets only files', so the asset catalog, Sounds' copy, the
   Info.plist and signing rerun on every cache hit (measured locally): 25 to 94 s on the runner. Fix: stamp tracked
   folders too. Low risk.
3. The Boot step's `simctl list` lookup runs serially, 5 to 70 s (measured). Fix: move it into the background boot.
4. Each run's environment (`GITHUB_RUN_ID` and the like) forces a new build description (measured locally). Fix: run
   xcodebuild under a trimmed `env -i`. Medium risk.
5. Metal recompiles every run: the toolchain's mount path has a random suffix the build records. No cheap fix.
6. Unexplained Swift work on exact cache hits, perhaps the asset symbols (fix 2 may cure it).
The step's grep hides xcodebuild's own phases, so about 90 s of planning has no breakdown: letting the phase lines
through the grep, at no risk, comes first.
#150 (2026-11-08): fixes 2 and 3 made, every phase and task line through the build step's grep (flushed per line, as
grep held them back in blocks). On an exact cache hit the build step now takes 12 to 33 s (CompileMetalFile about 6 s).
The boot, measured on exact hits: beside the build, jobs of 376 and 508 s (run 42527325401 attempts 2 and 3; in the
second a build description took 164 s against 3 to 5 s otherwise); after it, 310, 395 and 383 s (42529264269 attempts
2 to 4), and 302 and 383 s with the test step's second wait dropped (42531815833 attempts 2 and 3). Within the runner's
noise, but beside the build the boot can hide at most the build's 20 s and can stall it for minutes, so the boot now
runs after the build. Inferred, one sample each, not measured: a push that changes `Sources/` recompiles, and there the
boot beside the build could hide more; the earlier probe's 75 s build after the boot against 130 to 378 s beside it
leans the same way. Open for Jack: an A/B on source-changing pushes. Finding 4: no standard fix (swift-build hashes the
whole environment into the signature; its denylist of session variables has no CI ones and, tested on Xcode 27.2, doesn't reach
xcodebuild; `-UseSanitizedBuildSystemEnvironment=YES` still changes the signature), and a new
description costs 3 to 5 s on the runner uncontended, so nothing was applied. The test step is now the long pole: 150
to 380 s, the tests themselves 45 to 95 s, the rest `test-without-building` starting on the fresh simulator, unexplained.

Duo headroom (measured 2026-11-03 on the 13 Pro Max, `duo-feel`): one four-tap entry costs 0.2714 ms at 1137 px,
0.3426 ms at 1284 and 0.4466 ms at 1471, so 29.4 entries fit a 120 Hz frame at 1137 px and 16.9 at 1471. The Duo's GPU
against the 13's A15, from published figures (researched, not measured): 1.65 at worst, 2.4 likely, 2.9 at best. At
the likely ratio, the feel build holds 120 Hz on every level as dealt with four taps; pushed to 36 entries maelstrom
27 runs 1.7% of frames late and vortex 27 5.3% (114 fps); at the worst ratio, 77 to 93 fps at 36. Also measured: a
transform between the `Unstirred` layer effect and its clip makes the shader run over its whole `maxSampleOffset`
region, about 7 times the cost; keep the circle clip directly on the effect.

Jack's to-dos from round 16: host the Eyes Shut site (the repo, Pages and the URL swap); iCloud's pre-flip steps above
(the App ID's capability, then the two-device test); #129's phone checks, the share buttons tapping and "report a
problem" opening the share sheet over settings on a phone without a Mail account.


### Recommended model (Jack ruled it out, 2026-09-28: he won't put tiers behind a purchase)

Free, with one purchase that unlocks the rest (full campaign, Nightmare and Nightmare+, endless). The daily stays free
for good because it is the marketing. Undos refill daily and are never sold.

### How Unstir makes money: options compared (Claude's recommendation, 2026-10-24; not a decision)

The analysis itself changed no code; the StoreKit layer, the share line and TestFlight prep it recommended are now merged on `master`. Every claim is tagged **E** (evidence, with its source: this file, the code, or a
page found on 2026-10-24) or **G** (a guess, including platform facts Claude didn't check this session). There are no
revenue figures here, by design (see "Thoughts").

**Superseded in part (2026-10-24).** Jack's call puts packs in v1. The recommendation of C below rested on there being
no pack at 1.0, so it no longer stands; the comparison is kept as it was written. See "Recommendation" below and
"Packs: the catalogue".

**What 1.0 has to sell, as things stand.** Three tiers of 27 levels each, 81 in all, every one free (E: `Level.plughole`,
`Level.whirlpool` maps it one to one, `Level.maelstrom` maps whirlpool; Jack's tier call). Endless and the daily, free
(E). Undos, free at +2 per playing day (E: Jack's call). No pack exists, and none is designed (E). Selling anything needs
the paid developer account (E: "The Apple Developer account").

#### The options

**A. The agreed mix: picture packs, a daily archive, a supporter mark and a tip jar**
- *Build.* StoreKit 2 with several products: a non-consumable per pack, one for the archive, consumable tips, the mark
  on purchase, and restore (G). The archive is cheap to make. `Level.daily(_:)` takes any date and the generator is
  frozen, so every past daily, back to any date, can be rebuilt exactly (E: `Levels.swift`, `testDailyVectors`). It
  needs a calendar screen and bests per `daily-yyyymmdd` id (E for the id; G for the rest).
- *Content.* Packs are the most expensive content in the plan: "their own tanks, best with new mechanics" (E: Jack's
  call). One live picture touches six places (E: "After that: the architecture pass"). One new mechanic, maelstrom's,
  took a solver and three proposed level tables (E: "Side task"). The archive needs no new content, but every daily
  is the same kind of tank: one of four generated layouts, 10–14 stirs (E: `Level.daily`).
- *How it earns.* At 1.0: the archive, the tip jar and the mark. Packs earn only once they exist (E).
- *Risks.* Jack's tier call gives away the part that sells best, more levels (G). What is left to buy at 1.0 is more
  dailies of a mode that is free every day, and goodwill (E for what is on sale; G that this sells little). Packs then
  ship to whatever players are still around after launch (G). Four kinds of purchase split a small audience (G).
- *Featuring.* Good: nothing is locked or timed (G; "Thoughts" says the same, unsourced).

**B. Paid up front, R1**
- *Build.* The least of any option: no StoreKit, no purchase screens (G).
- *Content.* None new (E).
- *How it earns.* Once, per download (E).
- *Risks.* Few people download paid apps, and a new name with nothing to try is worse (G; R1's own reasoning). A daily
  share line that ends at a price tag loses most of its pull as marketing (G). A free copy, which "Thoughts" expects
  if the game takes off, undercuts it directly (G).
- *Featuring.* Good: premium games with no in-app purchases fit Apple's editorial taste (G).
- *Note.* R1 is the one option that keeps Jack's rule completely: nothing inside the game is locked, because everyone
  has paid (E: the rule is about tiers behind a purchase).

**C. One "Unstir+" purchase that locks no tier**
- *What it holds* (Claude's definition; this file has never defined it): the daily archive, endless past a free taste,
  and the supporter mark, in one non-consumable. Every tier and the daily stay free (G: a proposal).
- *Build.* One product, one purchase card, restore, the archive screen, and a gate in endless (G). Fewer StoreKit
  paths than A, and testable locally without the paid account (E: "Works without it").
- *Content.* None new: the archive and endless exist already (E).
- *How it earns.* One purchase per fan at 1.0, then packs later as separate products (G).
- *Risks.* Endless is the free game's only mode with no end; gating it may cut how often players come back (G;
  TestFlight measures it). Without endless, Unstir+ is the same thin offer as A's (G). Endless is a mode, not a tier, so
  this stays inside Jack's rule, but it is near enough to the unlock he ruled out to be his call (E for the rule's
  wording; the rest is judgement).
- *Featuring.* Good: one fair purchase on a free game, nothing sold that helps a solve (G).

**D. Rewarded ads for an undo top-up, R3**
- *Build.* A third-party ad SDK, a consent prompt where the law requires one, likely Apple's tracking prompt, a
  privacy-label change and the app's first network code (G: platform knowledge, unchecked). The privacy manifest
  TestFlight needs grows (E: it is already flagged in "Where things stand").
- *Content.* None (E).
- *How it earns.* Only when a bank runs dry (E: the reward is undos). The +2 refill each playing day caps that, and
  endless has no undo at all (E).
- *Risks.* It sells undos, which Jack made free, and it looks like the clones the game must stand apart from (E:
  R3's reasoning and Jack's undo call). It brings in data collection for the first time (G).
- *Featuring.* Poor (G).

| | Build | New content | Earns at 1.0 | Main risk | Featuring |
|---|---|---|---|---|---|
| A. Agreed mix | Medium; packs large | Packs: large | Archive, tips, mark | Little to buy at 1.0 | Good (G) |
| B. Paid up front | Least | None | Every download | Few downloads | Good (G) |
| C. Unstir+ | Small | None | One purchase per fan | Gating endless may cost returns | Good (G) |
| D. Rewarded ads | Medium, plus privacy | None | Only from empty banks | Brand, privacy | Poor (G) |

#### The agreed mix against Jack's aim of making money

Jack wants money from the game (E: the task). With every tier free and no pack in existence, the mix at 1.0 is a tip
jar with a cheap archive attached (E for what exists; G that this sells little). Its earning part, packs, is the
most expensive content to make, it is designed only as an idea, and it lands after launch, when the players who
would buy it may have gone (G). So the mix, as agreed, defers the money to a content pipeline that doesn't exist yet.

**Pushback.**
1. *The tier rule isn't wrong, but it has a cost that must be paid somewhere.* It gives away the one thing the earlier
   model sold. Keep the rule if Jack wants it; then 1.0 needs something else worth buying, and endless is the only
   thing that already exists and isn't a tier.
2. *Don't plan revenue on packs.* Packs with their own tanks and mechanics are a tier's worth of design each. Treat
   them as 1.1 content, sold only if launch shows players finishing the free ladder.
3. *Four kinds of purchase is too many for 1.0.* Fold the archive and the mark into one product. A separate tip jar
   only competes with that product for the same goodwill.
4. *R4 doesn't block a decision on shape.* One StoreKit product can be built and tested locally whichever way the
   contents go. TestFlight can't measure who would pay anyway (below).

#### Recommendation: C, Unstir+, as 1.0's one product (superseded 2026-10-24)

**Superseded by Jack's call (2026-10-24): packs ship at v1; there is no hurry to market.** This recommendation's
premise was that no pack exists at 1.0 ("What 1.0 has to sell": no pack exists, and none is designed). That premise is
gone: packs are now designed (the catalogue below) and Jack puts them in v1. So these parts fall away: point 3, "No
packs at 1.0"; point 1's Unstir+ anchored on endless past a free taste, which gated endless only because 1.0 had
nothing else to sell; pushback point 2, "Don't plan revenue on packs"; and "Open for Jack" items 1, 2 and 8. What v1
sells beside the packs is decision 4 under "Packs: the catalogue". Kept as written, for the reasoning:

Free download. Every tier, the daily and the daily share line stay free. Undos stay free. 1.0 sells:

1. **Unstir+**, one non-consumable: the full daily archive (back-filled to a date Jack picks, so it isn't empty on
   launch day), endless past a free taste (e.g. the first few tanks of each run, or a free run each day; Jack picks),
   and the supporter mark (e.g. on the menu and in the daily share line). Priced in R1's band; Jack picks the price.
2. **A tip jar of two or three consumable tips**, shown only after Unstir+ is owned, so it never competes with it (G
   that it earns anything; it is cheap to build).
3. **No packs at 1.0.** The first pack is a 1.1 product, sold separately, built only if launch numbers show players
   finishing the ladder.

Rewarded ads stay in reserve, as agreed, for the case Jack set: TestFlight shows banks running dry. Paid up front
(R1) comes back if Apple features the game or testers say they would pay up front.

#### What TestFlight must measure to confirm it

TestFlight purchases run in Apple's sandbox and cost the tester nothing (E: an Apple DTS answer on the developer
forums, and Adapty's docs, found 2026-10-24). So TestFlight shows interest, never willingness to pay. Real conversion
is known only after launch. Today the app sends nothing anywhere: the flight recorder (`Log.write`) stays on the phone
(E). Strangers' play can't be read unless an opt-in log upload, an analytics library or a survey is added (E that
none exists; the choice is Jack's). With 20–50 testers every number points a direction and proves nothing (G).

- **Day-2 and day-7 return**, as the plan already asks. Low return sinks every model equally.
- **How far testers get**: plughole finished, whirlpool opened, maelstrom opened. If most never finish plughole, the
  free tiers cost little, and packs are a long way off.
- **Endless**: the share of testers who play it, runs per tester, and whether endless players return more. This decides
  whether endless anchors Unstir+. If few play it, or its players return no more than others, Unstir+ needs another
  anchor.
- **The daily**: the share who play it on three or more days. That is the archive's market.
- **Undo banks at zero**: how often, and for whom. This is R3's trigger.
- **The Unstir+ card**: taps on it, and free sandbox purchases. Interest only.
- **An exit question**: would you pay for Unstir+ at its price, and what would you want in it? Stated intent usually
  runs above real buying (G).

With Unstir+ superseded (2026-10-24), its card and the question of endless as its anchor fall away. What TestFlight
measures for packs is item 57 of the catalogue's to-do.

#### Open for Jack

1. Accept C, Unstir+, as 1.0's model, or keep A as agreed, knowing it earns little until a pack ships?
2. Put endless past a free taste inside Unstir+? If yes: a few tanks per run, or a free run a day?
3. Unstir+'s price, within R1's band.
4. Back-fill the archive before launch, and from what date?
5. The tip jar: only after Unstir+, or not at 1.0?
6. Where the supporter mark shows: the menu, the share line, both?
7. How to read testers' play: an opt-in log upload, an analytics library, or a survey only?
8. The first pack: which picture or mechanic, and is it worth starting before launch numbers?

Items 1, 2 and 8 are overtaken by Jack's call of 2026-10-24 (packs at v1). The live calls are now the four decisions
under "Packs: the catalogue" below; items 3 to 7 carry into its defaults.

### Packs: the catalogue (Claude's recommendation, 2026-10-24; not decided)

**Jack's call (2026-10-24): packs ship at v1, and there is no hurry to market.** In his words: "I think we can handle
making packs for v1. I'm not in a major hurry to get it to market." This section is Claude's answer to it: a
catalogue of packs, the three for v1, what v1 sells beside them, and the work. Everything in it is a recommendation
until Jack decides; Jack's answers to its four calls are under "Jack's calls on the pitch". The analysis changed no code; the StoreKit layer, the share line and TestFlight prep are now merged on `master`.
"Checked" marks a claim checked against the code; "assumed" marks one that wasn't, platform facts included. No
revenue figures.

#### Jack's calls on the pitch (2026-10-24)

Jack answered on the pitch page. These are his calls. Everything else in this section stays a recommendation.

| Call | Jack's answer |
|---|---|
| 1. v1's packs | **First Stir, Lens and Escapement** (option A). "I LOVE the look of Lens. Escapement is a great idea, if implemented properly." Superseded for First Stir by FS17 (2026-10-29): First Stir leaves v1; see to-do 43. The third pack is **Prism** (Jack's call PK1 = A, round 12) |
| 2. Orrery: free rung or pack | **Not made.** "You didn't show me Orrery, so I can't make a call." A mock-up of Orrery, and Orrery beside maelstrom, goes to him next |
| 3. First Stir's art | **Claude draws all 25 scenes** (option B): "I am not hiring an illustrator". So First Stir's long pole is Claude's line art, judged by Jack scene by scene, and the go/no-go film decides whether code-drawn figures carry it |
| 4. What v1 sells | **Packs and a Complete bundle** (option A); Unstir+ dropped, endless stays free. "not just one I think will sell, but one I would be proud and unashamed to put my brand behind" |

On the recommended defaults: Jack said yes to every one he didn't object to. His objections and notes:

- **Tip jar: dropped.** "People get things for what they pay. No begging."
- **Offer codes: dropped.** "No."
- **Family Sharing: yes**, on his reading, which is right: everyone in an Apple family group gets a purchase one of them made.
- **Undo in packs: yes, with a rule that covers the free tiers too.** Undo must not close the stir it uncovers. After a stir
  on rod A, then one on rod B, undoing B leaves A's stir open, so a further turn of A joins it and counts no new move,
  as if B had never been made. Today `Game.undo` sets `open = false` (TankView.swift:253), so it breaks this rule now:
  restore whether the uncovered stir was open when the undone move began. Merged 2026-10-25 (PR #19).
- **Escapement turn-backs: not free.** "The skill is in knowing how the escapement works, so it's important the player is
  visually informed about this before stir #1." Read as: the tick is final once a move is committed (a look that lets go
  where it started is still no move and no tick), and the pack shows the clock working before the first stir. To
  confirm with Jack alongside call 2.
- **Reading testers' play: analytics are fine**, "as long as it's done respectfully and tastefully. None of those long
  dark-pattern menus". Recommendation to replace the default: anonymous counts only, no tracking and so no tracking prompt,
  no advertising partners, one plain switch in settings, and the privacy label to match. Unchecked: whether EU law needs
  a consent prompt even for anonymous analytics.
- **A web domain:** Jack has one, and can set up a subdomain for Unstir when needed (details in `HANDOFF.private.md`).
- **Names and ids:** names don't matter to Jack, "as long as we never screw up existing players' data or (especially)
  purchases". He asked whether a Firebase Firestore database fits. Claude's recommendation: no. Purchases live with Apple:
  StoreKit 2 rebuilds what a player owns on any device from `Transaction.currentEntitlements`, so no server can lose a
  purchase. Progress syncs through iCloud key-value storage, which needs no account or server (its 1 MB limit is ample
  for bests, guessed). A server would add an account system, a privacy-label entry, running costs and a way to fail. The
  guard that matters is in code: never rename a stored level id or product id, and a test that pins both.
- **Asked to have explained** (answers go to Jack with the Orrery film): the free "Eyes Shut" mode for blind players, The
  Well's price line, undoing a heal in a pack, and First Stir's heal ring.

Round 2 (2026-10-24, on the same page, after Jack saw Orrery's mock-up and Orrery beside maelstrom):

| Call | Jack's answer |
|---|---|
| 2. Orrery | **A free rung: charybdis gets orbits.** Orrery leaves the pack catalogue; vortex keeps the lab's whole-tank swirl as the recommendation |
| Escapement's tick | **Final once a move is made**; a look that lets go where it started is no move and no tick; the pack's first level shows the clock working before the first stir |
| Eyes Shut | **Prototype it after v1**, free, dropped if a blind tester can't play it. Jack: "I really doubt this will work. Good luck." |
| The Well | **Cut.** "I don't actually think The Well is compelling. Not good enough for free, let alone paid." Moved to R9 |
| Undoing a heal in a pack | **Yes:** the story beat plays forward again and its note steps back |
| First Stir's heal ring | **Yes:** magenta only for a heal that plays a beat; cancelling your own stir flashes white |
| Analytics | **Yes:** anonymous counts, no tracking (so no tracking prompt), no advertising partners, one switch in settings; check whether EU law needs a consent prompt for anonymous counts |
| Firestore | **No server:** purchases through StoreKit, progress through iCloud key-value storage; a test pins every stored level id and product id |

Round 3 (2026-10-25, on the review page of the overnight builds, after all seven PRs were merged):

| Call | Jack's answer |
|---|---|
| V1. Vortex's rim cue | **Knob** (option A), over bands and glyphs |
| V2. Dark seats under the swirl's ticks | **No option chosen.** Jack: "I actually don't like the ticks at all as a method of showing the tank will swirl." That rules out the tick dial as the swirl's cue, so what shows the swirl was open again. Round 4 (C1) chose breath; merged 2026-10-25 (PR #30) |
| V3. Which layouts get a swirl | **All five** (round 4, below) |
| V4. The swirl with seized knobs | **Charybdis** (option B). Jack: "The tank edge being dragged should always swirl the tank. It'd make the locked rods harder because turning the tank has a side effect. I feel strongly about this." |
| V5. Vortex's levels | **Accept as provisional** |
| V6. Vortex's pictures | **A family of its own** (option C). Round 4 (P1) chose all three families; merged 2026-10-25 (PR #28) |
| F1. First Stir | **Go** |
| F2. First Stir's time cue | **Make time visible** (option C): the night winding back (`UNSTIR_FSTIME` on `lab-firststir`), plus the caption |
| L1. Lens | **The hard lens, phone test next** (option A). The reviewers had recommended shelving it; trying it is Jack's choice |
| E1. Escapement | **Go, with changes** |
| E2. Warning before a losing lift | **The standing hint** (option C): the clock's disc always has a dashed vermilion edge |
| E3. What a sealed loss shows | **Freeze on the +1** (option B) |
| S1. Prices | **2.99 a pack, 5.99 Complete** |
| S2. The pack shelf | **The dock of live covers along the bottom of the menu** (option C, `UNSTIR_SHELF=c` on `shelf-mockups`) |
| I1. The app icon | **Candidate 1, the neon grid**, already the placeholder in the asset catalog |
| D1. Daily #1 | **Launch day.** Until it is set, the share line shows the date instead of a number |
| B1. CI time | **Watch it.** Since then #21 ran 5m44s and #23 5m36s, both over the 5-minute line |

Round 4 (2026-10-25, on its own page after round 3's answers):

| Call | Jack's answer |
|---|---|
| R1. Charybdis's rim | **Claude's reading confirmed** (option A): one gesture that turns the glass and swirls it together |
| C1. The swirl cue that replaces the ticks | **Breath** (option B): 1.5 s after the tank comes to rest the picture sloshes once, 12°, through the swirl, then again every 12 s idle. Merged 2026-10-25 (PR #30); as built the slosh peaks near 8°, which Jack kept (2026-10-25, K2: A). Jack's call (2026-10-25): it breathes only until the player's first swirl stir (under "What the tier needs" in "Vortex (provisional, 2026-10-24)") |
| P1. Vortex's own pictures | **All three families**, isobars, ephemeris and cords. Jack: "A is my favourite solved, but I love the animation of B both solved and unsolved too. I want both! Can we have both? Textiles are the least compelling - but not *bad*, so I kind of want all three." Ephemeris's orbits may overlap charybdis's planned orbits. Merged 2026-10-25 (PR #28) |
| V3. Which layouts get a swirl | **All five**, the 27 levels as built |
| B2. CI over 5 minutes | **Cache the build** (option A), **and move the line to 7 minutes**. The cache merged 2026-10-25 (PR #29) |

Round 5 (2026-10-25, after a film of the swirl's map at plateaus 0.6, 0.3 and 0.0, and the swirl alone at 0.0):

| Call | Jack's answer |
|---|---|
| W3. The whole-tank swirl's map | **D**: the swirl shears to the centre (plateau 0), knobs keep 0.6, chosen over keeping today's map (Claude's recommendation) and over softer maps for every disc (0.3, 0.0), which blurred every seam. Built on `swirl-map` (`Tank.swirlPlateau`) |

Round 6 (2026-10-25, five calls before TestFlight, one at a time on their own page):

| Call | Jack's answer | Code it needs |
|---|---|---|
| PR #31, the warm-up build after each merge | **Close** (Claude's recommendation). The test job compiles while the simulator boots (about 110 s), so a warm cache can't shorten it: 247 s cold, 262 s warm. Closed 2026-10-25 | None. The PR #29 cache stays |
| The daily archive's back-fill | **30 days before launch day** (Claude's recommendation): one calendar page on day one. Days before daily #1 show their date, not a number | The archive (to-do 47) starts at `Share.firstDay` minus 30 days |
| EU consent for anonymous counts | **Ask once** (Claude's recommendation): one plain Yes or No at first launch, the same switch in settings, nothing sent until Yes. Consent satisfies ePrivacy article 5(3) under any reading; whether anonymous counts need it at all is unconfirmed, and no lawyer was asked | A first-launch question and a settings switch, stored; the analytics layer sends nothing while it is off |
| How to read testers' play | **An analytics library now, plus a send-log button** (option D, Claude's revised recommendation after Jack asked what a log upload alone adds if a library comes anyway). Counts measure day-2 return across every tester who says yes and test the library before launch; a log shows a stuck tester's every touch. Which library: researched and pitched next | The library behind the consent switch, with events for return, progress, stuck points, shelf and card taps, free-taste completion and sandbox purchases; a "Send log" button in settings that shares `Library/unstir-log.txt` through the share sheet (no server); the privacy manifest and label updated for the library |
| First Stir's opening | **The wrecked harbour, as built** (Claude's recommendation): the player starts in the storm and earns the calm; opening on the calm evening would give away the end | None now: `lab-firststir` already deals the held-back picture. The pack's build keeps it |
Round 10 (2026-10-28, on the review page of PRs #50 to #58, Escapement's book, First Stir's scenes and the store page):

| Call | Jack's answer |
|---|---|
| PH1. Plughole 19-27 eased (PR #50) | **No option chosen on the page.** Jack: "Why are we doing this at all? Were they too hard? What's the rationale?" The rationale was that pent and hex were the steep part of plughole. Merged 2026-10-29 as option A (pent and hex both eased); see "Plughole gets easier" |
| SN1. Sound round 2 (PR #56) | **A:** in, with the early undo and step-back heals; keep the vortex bed. Merged 2026-10-29 |
| TU1. A locked next tier's up-a-notch button | **C, the gate:** the tap shows what is left to do, as the menu's gate page does. Merged 2026-10-28 (PR #57) |
| LN1. Lens's rod sizes | **A:** lenses on rods of every size. Merged 2026-10-28 (PR #53); `lens-levels-big` stays as the alternative |
| LN2. Cap on a dealt lens | **A:** keep +3. `lens-levels-cap2` stays as the fallback if the band's shimmer bothers him on the phone |
| J6. The book's last problems | **B:** end on 29, the two-clock hex; the three-clock hex becomes 29. Applied on PR #52 |
| ES1. What the tank shows when the last clock stops with twists left | **B, a count of twists left,** with a note: "3 left" doesn't read at once as three twists left, which can't be undone at par with the ticking escapement in play; workshop it. Reworked in round 11 (EL1), and then replaced by the tick budget |
| EB1. Play Escapement's 30 problems on the phone | **B, change some.** Notes: on problem 7 a wait needs a tap on the escapement's centre, and a tap on the circle instead reads as an impossible move (it shakes and refuses), so players may think it can't be moved by tapping; he asked for a better way to show the centre is the target (round 11, ET1). On problem 16 it is not clear at a glance that an escapement moves only so many times, that it then stops, and that it has stopped; that should be clear upfront so players can plan (round 11, EB2). "Problem 27 is naaasty! But I love it!" |
| CL1. Lens's card clip | **A:** the zoom and the read |
| CL2. Complete's clip | **B:** a cut of the three, a vignette, a zoom and a tick, about 8 s. PR #51 merged 2026-10-29 |
| FS10. First Stir's 25 scenes | **A:** approve the art. Superseded in effect by FS17 (round 11): First Stir leaves v1 |
| FS11. The ending film | **No option chosen.** Jack: "There are points where the scene changes very briefly then switches back to what it was before - reads as something for gameplay, rather than the final rendered scene. They should either be longer changes, clearer in what they're communicating, or they shouldn't change like that at all." Moot for v1 with First Stir out |
| FS12. The night's clock and sky | **A:** all as built |
| FS13. Chapters 1 and 2's departures from the outline | **A:** all as built |
| FS14. Chapters 3 to 5's departures from the outline | **A:** all as built |
| FS15. Figures on small rods | **A:** judge them on the phone first; change nothing yet |
| FS16. Fold Pen into Brush | **A:** one drawing kit |
| ST1. The store name | **A:** Unstir |
| ST2. The subtitle | **A:** "Unwind the stirred picture" |
| ST3. The promotional text | **A:** the one that says what is free and that packs exist |
| ST4. Screenshots | **A:** seven free-game shots, then one per pack |
| ST5. Preview video | **A:** one 25 s preview, free game only |
| ST6. Family Sharing | **A:** yes, on for the packs and Complete, and the description says so |
| ST7. Store defaults (keywords, category, policy and support page, the send-log disclosure) | **A:** all fine. The contact address for privacy and support: kept privately |
| ST8. Questions for a lawyer | **No option chosen.** Jack will not ask a lawyer: Claude finds the answers itself and keeps looking until sure. He is UK-based, so UK law matters most, but the app should release worldwide if possible. The findings are in a legal summary kept outside the repo and became round 11's LG1 to LG3 |
| AN1. The consent link | **A:** a toggle, "Hide the list" when open. Merged 2026-10-28 (PR #55) |
| AN2. Yes, No, Yes counting a second install | **A:** accept the double count |
| CI1. CI near the 7-minute line | **A:** keep and watch |
| DO1. For Jack to do | **B, partly:** he updates Xcode (a macOS upgrade and a restart, so Claude stops and waits); the failed-purchase message issue is fixed; he has played Lens and Escapement and not First Stir |

Round 11 (2026-10-29, on the review page after round 10's notes):

| Call | Jack's answer |
|---|---|
| ET1. Learning that a wait is a tap on the clock's centre | **B:** a plate on the hub, and a miss points to it. Built on PR #52 |
| EB2. Showing how many ticks a clock has left and that it has stopped | **B,** the countdown numeral in the hub, with a note: "to keep with the clock theme, can you make the numbers count down like a flip clock? have start flipping when the escapement starts moving". Built on PR #52 as a flip counter |
| EL1. Why a tank is lost when the last clock stops with twists left | **No option chosen; a note that replaces round 9's E1/E2 loss rule:** "better idea: "par" is not a thing for escapement. instead, you get a tick budget, and each individual escapement decreases it. a puzzle becomes impossible to solve without an undo if you make a wrong move, rather than you losing instantly. the remaining ticks are always shown clearly. if a tank has more than one escapement, each one decrements the budget when it moves, so when they all move in sequence the budget goes down by for example 3 even though only one move was made by the player. make sense?" Built on PR #52 (tick budget, one flip counter) |
| EL2. A reason for a tank lost to a pushing tick | **"See answer to call 3"** (EL1): the budget replaces the instant loss |
| FS17. First Stir | **C:** the clearer ending (the fade fix, the longer night and a caption per vignette, merged in #54). With it, Jack's note: First Stir leaves v1 and is reworked later, because the art's constraints made the story hard to read from the illustrations alone; something else with at least one new mechanic takes its place as the third paid pack. #54 merged 2026-10-29; PR #60 is v1 without it |
| LG1. The EU and analytics | **C, conditionally:** "C if those hurdles can't be overcome", meaning no EU release if the EU representative and trader-page hurdles can't be cleared. He asked how solo developers handle the EU representative; the answer fed round 12's EU1 |
| LG2. Children and the consent card | **A:** an age bracket before the card, the threshold read from one setting |
| LG3. The rest of the legal work, required either way | **A (Jack, 2026-11-01): keep send log; register with the ICO and pay its fee with the address withheld, before TestFlight but not yet.** Jack will check with the ICO and pay before the first TestFlight invite (reminder under "The Apple Developer account"). Nothing is due until the first emailed tester, received log or support email. With A, Claude also: takes boot time out of the flight log; makes send log say what it holds; fixes the privacy policy (drop portability, say StoreKit reaches Apple, the objection and legal-duty wording) (those three on branch `legal-lg3`, awaiting review; the policy's retention figures, 12 months for support email and logs and two years for complaint records, are confirmed by Jack (2026-11-01), and the mailbox's provider and country are placeholders, since no paid business mailbox means no processor contract to claim); adds Apple's age-range check before launch (branch `age-range`, awaiting review) (California AB 1856 joins TX, UT, LA, AL); notes Texas's significant-change notice before a new paid pack, and Self Assessment once App Store income passes the trading allowance. The geographic address: EC1 = A (below the round 13 table) |

Round 12 (decided, 2026-10-29). Jack's words are kept in `HANDOFF.private.md`.

| Call | Decision |
|---|---|
| AN1. Analytics in v1 | **A:** none. v1 ships through `v1-no-analytics` (App Store Connect's numbers only); `keep-analytics` holds the other side, for an update. Every analytics item in the to-dos and in the launch checklist below is moot for v1 |
| EU1. Selling in the EU at launch | **B:** no EU or EEA storefronts at launch. Revisit if sales cover the cost of a business address for the trader details the Digital Services Act asks of an EU seller (no vendor names or prices in tracked files) | (Round 14, F12 = A: the EU stays closed.)
| PK1. Prism as First Stir's replacement | **A:** Prism, capped at depth 8, since depth 9 reads too busy. Built and on the Release shelf (PRs #59, #67, #68, #69 and the ship PR, 2026-10-29); Jack's play of the specimens and the phone bench remain |
| ES2. Escapement's budget display | **B:** the flip-clock numbers also show in each hub, and a total counter elsewhere; the numbers must never contradict each other, and a hub at 0 must show clearly that it has run out. Jack's words: "just don't let the numbers contradict each other? they should render as flip-clock numbers in the hubs too. and when the hubs reach 0, it should show clearly that they've run out (e.g. greying out the hub/escapement, or what you already built to show it, or something else)", and "i want the flip clocks for each hub in that hub, plus a counter for the total elsewhere." Built on `esc-hub-flaps` (2026-10-29), the rule Claude settled under the note: each clock's count is what it owed as dealt, each of its ticks takes one off it, a pushed tick too; the header is the hubs' sum after every tick; a clock at 0 stops ticking and greys (wheel, sub-dial, card, dashed disc) as its last tick lands, with the amber stop ring; out of ticks once no clock can tick with twists left. On a clean line each count reaches 0 as its rod empties, so the book stands. Each hub is a one-digit split-flap card (no clock owes more than 9) |
| PL1. Prism's plates 3 and 4 | **Redrawn.** Jack found the watch movement (tray 3, Colour Order) and the cathedral's west front (tray 4, Overprint) messy, and chose from six redraws, three a plate: Haeckel's medusae for tray 3 and Haeckel's radiolarians for tray 4 (2026-10-29). Shipped as he saw them, without the later polish passes, on `prism-plates-v2`; the plates, their `Picture` cases and the trays' headings take the new names |

Round 13 (decided, 2026-11-01): every recommendation on the names-and-polish page, except C19. The page and its sources
(the audit, the proposals, the UX inventory) are outside the repo, in round 13's notes.

| Call | Decision |
|---|---|
| N1. Level names | **One world per tier and pack, plain nouns, gentle to wild:** plughole the bath (Drop to Drain), whirlpool a river (Spring to Estuary), vortex the winds (Calm to Tornado), maelstrom the open sea (Swell to Abyss), Lens things you look through (Keyhole to Kaleidoscope), Escapement a clock taken apart (Mainspring to Midnight), Prism the specimens on each plate (Frond to Nautilus). Ids never change. The hints the old titles carried move into the levels' notes. First Stir's titles stay. Built on `level-names` (PR #82). Open: L2 (Drip, was "Further than it looks.") has no note, though the recommendation said L1 to L4 lose nothing; whether it wants one is a creative call |
| N1a. Escapement 01 | **Mainspring**, replacing D1's "The clock" |
| N1b. Lens's chapters | **Four:** Close-up (1-6), Cut-in (7-12), Double-take (13-18), Big Picture (19-25), so the card's "four issues" is true |
| N1c. Case | **Sentence case** ("Last drop") |
| C1. The end of the free taste | **B:** level 03's result card says "more in Lens ›" in the pack's colour; the card opens on its buy block under "You've played the free three. 22 more in Lens."; no price on the result card. Built on `taste-end` (PR #86). Open, side effects for Jack: the note shows only while it is true (every free level has a best, the pack never owned), so a player gated after fewer, or a refunded owner, sees no line; whether they want one is a words call. And the landing scrolls the card's only exit, "‹ back", off the top; Claude recommends pinning it over the card's top at every scroll position, rather than waiting for C19's edge swipe |
| C2. Leaving an unfinished level, or the app dying | **A, resume:** the moves are saved on every commit and replayed on reopening; endless resumes mid-tank; no dialog. Built on `r13-resume`, PR #101 (implementer calls in the PR: out of ticks clears the save, since replaced by C19's side effect, A; endless's "new run" arms for 2 s like reset, under VoiceOver until focus leaves, then starts another run; the row keeps the best at the end of its detail). Open check: a saved line grows with every reset and "again", and 300 calls on a maelstrom level replay in 0.12 s on the simulator's Debug build; unmeasured on a phone |
| C3. When a level counts as tried | **A:** the first committed move; a look is free; "tried" shows on the row. The rule built on `r13-play`, PR #93; the row's mark (menu and pack card) on `r13-menu`, PR #90 |
| C4. A new player's first screen | **B:** a fresh install opens straight into plughole 01; the menu leads with 01, daily and endless hidden until they open. Built on `r13-menu`, PR #90 |
| C5. The pack dock | **C:** it appears once plughole 09 is solved. Built on `r13-menu`, PR #90 |
| C6. Pulls toward the dock | **C:** a one-time "new" mark on a cover when its pack fits the player's progress or an update adds levels, and "2/3 free" under a started pack. Built on `r13-shop`, PR #95 (implementer calls in the PR: Escapement fits once maelstrom is open; "3/3 free" stays; First Stir never marks) |
| C7. Complete once a pack is owned | **C:** shown only while it costs less than the unowned packs, with the saving said. Built on `r13-shop`, PR #95 (the cards' line and fact wait for the prices; the dock's cover waits too unless no pack is owned, so a launch keeps it; back from a pack's card opened from Complete's goes to the menu once Complete saves nothing) |
| C8. Finishing a pack or the last free tier | **C:** one completion line, plus one quiet "try <pack> ›" while a pack is unowned. Built on `r13-result`, PR #92 |
| C9. Results | **B:** three marks (solved, at par, clean), drawn in the design pass (to-do 72) |
| C10. The timer | **A:** off the result card and out of the best's ranking. Built on `r13-result`, PR #92 |
| C11. Par warning and the over-par veil | **A:** the count amber at par and magenta past it; the veil at 0.05 a move, capped at 0.2. Built on `r13-play`, PR #93 |
| C12. Reset | **A:** "reset? tap again" for 2 s. Built on `r13-play`, PR #93 |
| C13. A drag the system cuts off | **A:** commit everywhere, as V26; after a phone check of which handler runs first. Built on `r13-cutoff`, PR #100 | (Round 14: PR100-V26 = A. Round 15, PR100-phone = A: the phone check passed and #100 is merged.)
| C14. Escapement's pushed tick | **A:** the caption says at once "That tick can't come back. Undo, or again."; the tank plays on (EL1 kept). Built on `r13-play`, PR #93. Open, for Jack: the words name "again", the lost card's button, where the play screen's control reads "reset"; Claude recommends keeping both. Also open, for Jack: with the undo bank at 0 the words still point at undo, which then only says when undos refill; Jack's call (2026-11-01): A, "That tick can't come back. Reset." while the bank is empty |
| C15. Teaching Lens's taste | **A:** a ghost finger rides the lens's track on Lens 01 until the first lens commit. Built on `r13-lesson`, PR #91 (stacks on #85); shows at once, with no 4 s wait (implementer call); the finger starts on the knob's left edge and rides the drag's real two steps beside the rail, so copying it solves on any phone (implementer call on the spec's 2.5 track pitches and finger on the rail, recommendation, for Jack's look at the PR) |
| C16. Prism's letters | **B:** a "colour letters" switch in settings, defaulting to Differentiate Without Colour, and one line on Prism's card. Built on `r13-settings`, PR #94 |
| C17. Settings | **A:** music, sounds and haptics switches; "report a problem" mails the log to the support address (kept out of the repo); the policy on Jack's own domain. Built on `r13-settings`, PR #94 |
| C18. The daily | **A:** the gate stays at plughole 23 for v1; a quiet run count on the row and "next daily in 7 h" on the card. The row's run count built on `r13-menu`, PR #90; the card's part on `r13-result`, PR #92. Implementer call: past the midnight that ends the card's daily it reads "next daily is out" (the other choice: drop the line) |
| C19. Swiping back (round 14: see PR100-V26, the two-finger twist) | **Jack: an edge swipe back, as everywhere else in iOS** ("it's little things like this that Apple looks for"). Claude's recommendation (none in play) is set aside. The swipe starts only from the screen's left edge and wins over a rim turn that lands there; with C2's resume an accidental swipe loses nothing. Built on `r13-swipe`, PR #102 (stacked on `r13-resume`; implementer call in the PR: interactive, the level sliding off over the menu, with threshold-then-dip the fallback if drawing the menu under the level costs a frame on the oldest phone, unmeasured while the XS is down: it won't turn on, and Jack may fix it before TestFlight day; the dock's covers hold still under the slide to lower the risk). Open, side effect for Jack, waits on him: Escapement's out-of-ticks card is where the premise fails. C2's resume clears a lost tank's save (its implementer call), so a graze from the edge on the lost card drops the tank and the card's undo, which before C19 took a tap on the back button. Options: keep a lost tank's save until "again" or a solve clears it, reopening on the lost card (the swipe loses nothing, as the premise says; a change to the resume's replay, which closes a line that ends lost); or keep C2 as built and accept it. Claude recommended the first. **Jack's call (2026-11-01): A, built on `lost-resume`, PR #103** |
| C20. A rating request | **B:** once, after the solve that opens whirlpool; never after a loss, a spill or a purchase. Built on `r13-result`, PR #92. Open, waits on Jack: a TestFlight or playtest install that opens whirlpool spends the one trigger where Apple shows no sheet, so the App Store build over it never asks; keeping the ask needs a broader trigger, which changes the call. Recommendation: keep it as decided |
| C21. After a purchase | **A:** the card stays with "play 04 ›" lit; an Ask to Buy approval says "Lens is yours" once on the menu. Built on `r13-shop`, PR #95: the dock's header says it unless its own card is up, and waits while a card or the settings cover the dock |
| C22. Mac and Vision Pro | **A:** opt out for v1 in App Store Connect. Jack will bench the GPU on his old iPhone XS if it still runs | (Round 14, F7 = C: Mac and Vision Pro off at launch, QA at month 1, the Mac on with its own nomination; revisits this call.)


Round 13's later calls (Jack, 2026-11-01, on the open-calls page; every one as recommended but P1):

| Call | Decision |
|---|---|
| D1. The menu's line under the title | **A:** dropped; "Every stir in this tank has an exact inverse." lives on the App Store page |
| D2. The sandbox's row | **A:** at the end of the list, under "anything goes" |
| D3. The result marks' shape (C9) | **A:** dots, one to three filled |
| D4. The second "‹ levels" on the solved and out-of-ticks cards | **A:** removed; the top "‹ levels" and the edge swipe go back |
| AR1. The age-range sheet (PR #79) | **A:** on the menu, never over a level or its opening; merged 2026-11-01 |
| EC1. A geographic address | **A:** publish nothing more: the seller's name, a working support email and the GitHub page, Apple's standard EULA; the address given to anyone who asks, and put on the support page the day an enforcer writes. A knowing gap on one limb, not compliance |
| P1. "again" on the daily's card (from F18) | **B:** a retry from the card that plays the daily as practice and saves nothing (best, started flag, analytics' first-try count and the card's best line untouched). Built on `daily-again`, PR #105: "again" after the daily's solve turns the try into practice, the later visit's path (`Game.firstTry` false). Implementer call: a clean daily offers no again, as on every level. Round 14, P1-clean = A: Jack approved that |
| P2. Prism's level colour (from F17) | **A:** white for now; the design pass settles it |
| S1. "Undo, or again." against "reset" (C14) | **A:** both words kept |
| S2. A vertical touch in C19's edge band | **A:** a rim turn, as iOS's own edge pan |

The iPhone XS doesn't power on (2026-11-01): its bench and bake-time checks wait until Jack has fixed it, before TestFlight day.

Round 14's calls (Jack, 2026-11-02, on his decisions page; the game and the build. The money and marketing calls are
in `HANDOFF.private.md`). P is the day the paid account opens and L is launch, as the marketing plan counts them.
Jack's own words are quoted; the rest is the option he picked.

| Call | Decision |
|---|---|
| F1. The launch timeline | **B:** launch at P+91, nominate for featuring at P+4 to P+7, open the pre-order at P+49 |
| F2. Reduce Motion and the live pictures | **B:** live pictures hold a still frame and endless's pour cuts to its end under Reduce Motion |
| F3. Pointing at settings | **B:** one quiet line on plughole 01's first open, pointing at settings, once |
| F4. Languages | **C:** a String Catalog at launch; languages as their own update, nominated at L+6 to L+8 weeks. Replaces marketing decision 15; "English only" below stays for launch |
| F5. Game Center | **B:** sign-in plus achievements, no leaderboards, if the sign-in overlay test on an iOS 26.2+ phone passes. Replaces marketing decision 8 and "no Game Center at v1". The achievements list goes to Jack as a pitch. *(Round 15: G-list, G-hidden, G-playtest, G-banner and G-link = A, PR #113 as built, merged.)* |
| F6. iPad | **A:** iPhone only at launch; native iPad as the first big update |
| F7. Mac and Vision Pro | **C:** both off at launch, QA at month 1, then the Mac on with its own nomination. Revisits C22 |
| F8. Play without sight | **Undecided.** Jack wants to see how it could work, even in theory, before committing; he knows no blind testers. *(Round 15: E-next = A, blind testers next.)* |
| F9. Apple Arcade | **A:** one Arcade pitch on P, a reply by P+28; the pre-order waits for it |
| F10. iPhone Duo | **A:** Claude scopes it. Jack: it must be polished and well done on Duo, Apple will be paying attention; he has no Duo. *(Scoped; the closed display's fixes merged, PR #112. Round 15: D-layout = 3, D-tent = A, D-margin = A; stage 1, split play, in PR #116.)* |
| F11. What editors play | **B+C:** an editors' TestFlight build with a visible "open every tier" switch, never in the App Store build, plus a 60 s film of the later tiers |
| F12. EU storefronts | **A:** they stay closed. Jack: "screw the EU". The UK is unaffected |
| M1. Complete's name | **B2:** rename Complete now to a self-limiting bundle, one per three packs. The name goes to Jack as a pitch. *(Round 15: B-name = A, Triptych; B-numeral = B, "Triptych I" from day one; PR #114, merged.)* |
| M2. The share line's link | **A:** a tracked App Store link on its own last line of the share line, in the build that goes to review |
| M6. Smaller marketing builds | **All six:** promoted purchases with four images; the daily archive (to-do 47); the supporter mark with an off switch (to-do 48); mid-level state surviving a kill, done as C2; a "more puzzles in the packs ›" line once on the last free tier's result card; a HANDOFF note on the four 2027 dailies the solver beats by one (not yet written) |
| M7. The daily's gate | **A:** keep the gate after plughole 23, with honest copy that the daily opens after the ladder |
| PR100-V26. A two-finger twist over a held rod | **A:** it commits the rod's turn, then turns the tank |
| PR85. L1's ghost finger | **A:** approved |
| PR104. The two pack-card wordings | **A:** approved |
| P1-clean. "again" after a clean first-try daily | **A:** none |
| CAP. The clean capture | **A:** it keeps the bezel and the solve wave |

Round 15's calls (Jack, 2026-11-02, on his morning page): the open PRs, the Duo, Eyes Shut and round 14's small calls.
Jack's own words are quoted; the rest is the option he picked. Built on `r15-calls` unless a PR is named.

| Call | Decision |
|---|---|
| PR100-phone. A drag the system cuts off, on the phone | **A:** works as described. #100 is merged |
| B-name. The bundle's name (M1) | **A:** Triptych. Its trademark check in the UK IPO and USPTO registers is Jack's to do |
| B-numeral. A numeral after it | **B:** "Triptych I" from day one. Built on PR #114, merged |
| G-list. The 16 achievements, 255 points (F5) | **A:** all 16 as built on PR #113 (merged), the four that could read as pressure kept. Game Center stays off (`GAME_CENTER`) until Jack's sign-in overlay test passes |
| G-hidden. How many are hidden | **A:** 5, as built |
| G-playtest. Reporting from Jack's phone's builds | **A:** playtest builds report to Game Center's sandbox; only screenshot and test launches never report |
| G-banner. Game Center's completion banner | **A:** shown, over the result card |
| G-link. GameKit with the switch off | **A:** linked, never called |
| D-layout. How the open Duo lays out (F10) | **3:** split play (the tank in one half, header, caption, controls and cards in the other) plus the menu beside play. Estimated at 2–3 weeks plus 1–2; stage 1, split play in wide windows, is in PR #116 |
| D-tent. Landscape on the closed display | **A:** portrait on the outer display |
| D-margin. The closed Duo's tank size | **A:** leave the 16 pt margin as it is |
| E-next. Eyes Shut, what next (F8) | **A:** Jack played plughole 03, 05 and 11 eyes shut, each at par: "an interesting mechanic", unsure whether it is enjoyable, which only blind players can say. Next is 3–5 blind testers; build only if two of them solve quad levels unaided |
| R-motion. Plughole 01's settings line | **A:** as built, no "motion" |
| R-spill. Endless's spill card under Reduce Motion | **B:** it shows at once (`Brim.card(still:)`), not after 2 s over the still, spilled glass |
| R-mark. The supporter mark | **A:** as built |
| R-packsline. "more puzzles in the packs ›" | **A:** as built |
| R-promo. A promoted bundle that costs more than the packs left | **A:** as built: it opens its card and buys |
| R-reel. The editors' 60 s reel | **B:** Lens goes in, filmed from a warm start (the halftone already in Caches). Built: Lens 03 between maelstrom 01 and Escapement 02; every segment rests 0.2 s after its opening (was 1 s) and ends with its solve's wave, so the six join to 62.8 s (was five, 59 s) |
| R-arch-where. Where the archive lives | **A:** a row under today's daily, the calendar over the menu |
| R-arch-lock. Tapping the locked archive | **A**, in Jack's words: it shakes and says "unlocked by purchasing any pack" for 2 s (was "any pack on the shelf opens it"), never opening the shop. The row's own quiet line, "30 past dailies · comes with any pack", stays |
| R-arch-best. Archive days and bests | **A:** as built |
| P3. Prism's isolated channel (new, from Jack) | Holding a swatch draws its channel alone in its own colour, red, green or blue, not white: "Makes it more clear." Not Jack's call, a refinement in the build, his to overrule: under the system's Differentiate Without Colour it stays white (the system flag, not the colour letters' choice), as pure red and blue can read dark on black to a colour-blind player. Measured on specimen 8's shots: the knob colours' lines sit at about a quarter of white's luminance (red 0.26, blue 0.23, green 0.65, white 0.89), near 5:1 against black; protanopia turns red olive at 0.21. Kept at the knobs' colours, not lightened |
Round 16's calls (Jack, 2026-11-02, on the finish-and-pitch page). Jack's own words are quoted; the rest is the option he picked.

| Call | Decision |
|---|---|
| ORDER. The three big UI jobs | **A:** the Duo's stages 2 to 4, then the architecture pass's three (ARCH), then the UI design pass (to-do 72), then the String Catalog, then the store media taken again on the finished chrome |
| ARCH. The architecture pass | **A:** all three of its top list (split TankView.swift; CLAUDE.md and HANDOFF.md cut to a short map plus area docs; a typed shader-argument encoder), after the Duo's stages and before the design pass |
| DOCKFADE. The dock on launch | **A:** keep #115's one fade-in (merged) |
| DUO2. Stage 2's two choices (#120) | **A:** both as built: tabletop's "unstirred." at the foot of the upright half, the glass 398 pt; a turn in flight as the phone folds lands as the steps it shows |
| DUOMENU. Stage 5, a level opened beside the menu | **B:** the tank left at stage 1's glass, the menu on the right with the header and controls. Unblocks stage 5 |
| DUOCAP. The open Duo upright | **C:** a higher cap than 1300 px, with shallower stacks allowed at that size (not the recommendation, A). The limits were tuned at about 1137 px, so it went back as duocap2: **D** (1471 px, iPhone stacks, the four-tap limit 17 there) and duocap-step **A** (2026-11-03). Built in #137, held for #140 |
| VORTEXSHOT. Store screenshot 4 | Vortex 14, "Monsoon" (isobars). The page's left, middle and right labels were wrong |
| STOREMEDIA. Store media (#121) | **B:** the preview cut to 25 s (not the recommendation, A). Jack: "The preview jumps on 01: Calm when the rim is turned. It just snaps straight to the end of the animation." A bug to fix. Both built, merged in #128 |
| SOUNDSK. Pack sound layers | Lens B, Escapement B, Prism A. The ratchet's tick: neither sketch; it "should sound like an actual small piece of metal ticking against another small piece of metal". A new sketch goes to Jack's ear. Three ticks (C, D, E) on local `sound-packs`, pitched as soundsk2. Jack picked D, the steel pawl (soundsk2, 2026-11-03), merged in #138; soundsk-layers = B, a listen under real play first (rendered on local `sound-packs`) |
| CAT1 to CAT8. The String Catalog plan's eight calls | **A** on all eight: pack names never translate; tier names translate; Prism's R, G, B kept for v1, reopened with the first language; the report mail always English; the share line follows the device, "Unstir #n" and the grid fixed; development language `en`, with a note that the source is British; the editors' build words do-not-translate; translated consent against an English-only policy deferred to the first non-English release with analytics. Unblocks the migration |
| EYES1. Eyes Shut's prototype host | **A:** GitHub Pages, a new small public repo. The site is built, local in the tools folder; Jack creates the repo and Pages |
| EYES2. The blind testers' thank-you | **B:** the smaller voucher each (not the recommendation, A); the amount is in HANDOFF.private.md |
| C1A. A player gated before three free levels | **B:** a line for the skip-ahead case only, "The first three are free. 22 more in Lens." above buying. Built, merged in #129 |
| C1B. The card's back when it lands on buying | **A:** "‹ back" pinned over the card's top at every scroll position. Built, merged in #129 |
| C20. TestFlight installs and the rating request | **A:** as decided |
| N1. A note for plughole 02, Drip | **A:** no note, as built (not the recommendation, D) |
| SND1. The detent tick during a drag | **B:** dropped; the haptic and dashes carry the steps (not the recommendation, A). Built, merged in #129 |
| SND2. Cancelling your own push in the free tiers | **A:** endless's rule everywhere: it flashes white; magenta and the heavy tap mean a real heal. Built, merged in #129 |
| SND3. The share links on a device | **B:** they tap: a button that taps and opens the share sheet itself. Built, merged in #129 |
| AGE1. The age gate asked for | **A:** 18 alone, as built |
| AGE2. The questionnaire's age-assurance row | **A:** Yes |
| J5. Escapement's forced waits | **A:** keep the rule |
| J8. Problems 9 and 11's many lines at par | **A:** accept them |
| ESC-PAPER. Escapement's paper ground | **B:** build the bone-paper page for v1 (not the recommendation, C). Built, merged in #130 |
| ICLOUD. iCloud key-value sync of bests | **A:** build for v1 (not the recommendation, B). Built, merged in #127, off behind `ICLOUD = NO` until the pre-flip steps (Round 16's build) |
| APPSIZE. An app-size budget (to-do 22) | **B:** a CI size guard: a test fails past a set size (not the recommendation, A). Built on PR #126 (merged): `scripts/app-size.sh` as a step after Test in test.yml and nightly.yml, failing past 100 MB (the pitch's example figure); a workflow step, not an XCTest, for Jack to confirm (appsize2) |
| A5. Defending the name on Apple Ads | **B:** armed: a campaign ready, spent only once a rival bids on the name |
| A6. A UK pre-order push | **A:** no |
| M10. Organic reach | **A:** new accounts in the studio's name, from zero; personal accounts stay out |
| M14. An address for a paid Android port | **C:** neither for now; a paid port is closed until Jack revisits |
| HISTORY. Rewriting history for an old device identifier | **A:** leave it. Jack: the repo goes private at launch. Then GitHub Actions draws on the allowance, macOS minutes at 10x: cost the PR and nightly runs before then |
| TRIPTYCH. The bundle's name in the registers (Jack's to-do) | Clear. UK IPO: two class 41 marks (Triptych, Tryptich), both business training and education, nothing in class 9. USPTO, live marks in classes 9, 28 and 41: the four spelled like it are cinema cameras and film production, travel guides, a fishing-trip app and medical-records software; none covers games. "Triptych I" can go into App Store Connect |

**Launch checklist** (App Store Connect and the rest; to be extended)

- In App Store Connect's availability, exclude the EU and EEA storefronts (EU1 = B).
- Opt out of the Mac and Vision Pro App Stores for v1 (C22 = A).
- Publish the privacy policy on Jack's own domain, then give App Store Connect its URL, and set `POLICY_URL` and
  `SUPPORT_ADDRESS` (both in HANDOFF.private.md) in `Config/Local.xcconfig` or the shell for the archive build, so
  settings opens that page and "report a problem" mails the log (C17 = A).
- App size: guarded in CI at 100 MB (PR #126); Release 21.9 MB on 2026-11-02.
- iCloud sync, if it ships on: the App ID's iCloud capability (key-value storage), a two-device test on one Apple ID,
  the privacy policy's and store page's lines, then `ICLOUD = YES` (Round 16's build).
- Analytics items (the consent question, the age bracket, the privacy label's analytics rows, Aptabase's region and key)
  are moot for v1 (AN1 = A).

**The charybdis rule (Jack's call, 2026-10-25, from V4).** Jack's words, and only these: "The tank edge being dragged
should always swirl the tank. It'd make the locked rods harder because turning the tank has a side effect. I feel
strongly about this." That is the call.

**Claude's reading, confirmed by Jack (round 4, R1):** on a level with seized knobs, turning the glass to carry them round
swirls it too; the swirl is the turn's side effect, and that side effect is what makes the locked rods harder; it is
one gesture, not two bands. What it would mean for what is built, on that reading:
- Vortex's "both" levels (a seized knob on a swirl layout, `UNSTIR_SEIZED` on a vortex level), the two-band grab
  (the glass's edge band 0.86 to 1.0 holds the swirl, the bezel and beyond turn the tank), both lessons side by side
  and every rim cue's "both" shots were built on vortex as a proposal. They would become charybdis's starting point, and
  the two bands give way there to one gesture that turns and swirls together. Vortex itself has no seized knob, so
  nothing in its set changes.
- Charybdis also takes the orbits (round 2). How the swirl-with-turn and the orbits sit together is not designed.

**Vortex gets the whole-tank swirl (Jack, 2026-10-24):** "it should be in the free game". The lab's prototype is
`b6ed01c` on `lab` (a quad layout with a fifth rod the size of the tank, turned from the rim, committed like any rod
stir), never merged. To make it a tier:

1. A go/no-go on the phone first: Jack plays the lab's two swirl levels, then a swirl on pent and hex, for whether the
   swirl's seam reads (its rigid core is 0.6 of the tank, so its shear lies in the outer ring, under every other rod;
   since W3, 2026-10-25, it has no core).
2. Jack's calls (2026-10-24): the rim's meaning must be visible before a move: whether it swirls the tank, turns the
   glass with its seized knobs, or both, which one level may have. There are no players yet, so nothing is
   grandfathered. The solver needs the swirl. A tank-sized stir's cost is fine; measuring it is optional.
3. `Tier.vortex` between whirlpool and maelstrom. Raw values are strings, so nothing is remapped; `Tier.isOpen`'s gate
   moves.
4. Swirl layouts kept out of `Layout.allCases`, as the lab does, so the frozen daily generator and endless are
   untouched (`testDailyVectors`, `testEndlessVectors`).
5. Grab, rim lesson and drag count for the swirl from the lab, on every layout; the solver and `solve.sh` taught that the
   swirl commutes with nothing; the shader's cost of a tank-sized disc measured against `fourTaps` on the phone.
6. Vortex's pictures (its own family, or plughole's with up withheld; Jack's pick from mock-ups), its sound bed, and 27
   levels, solver-checked, to Jack as a table before code.
7. Tests, shots and films; the tier strip takes a fourth name.

So the catalogue is five packs: First Stir, Lens and Escapement at v1, then Prism, then Music Box if it passes its ear
test. **Since FS17 (2026-10-29): First Stir is out of v1, to be reworked; v1's third pack, which Jack wants to bring at
least one new mechanic, is Prism (PK1 = A, round 12), on the Release shelf since 2026-10-29.**

#### The catalogue

Five packs for the life of the game. Each changes what the player reads (Lens: scale against a dot
screen; Prism: three colour lights; Music Box: the ear), how a move works (Escapement: a clock rod that ticks after
every move) or what the evening is (First Stir: a story told backwards). The Well is cut (R9), and the Orrery
candidate's orbits go to charybdis, free (Jack's call, round 2).

Jack's call puts packs in v1, so v1 launches three, one per kind of change:
- **First Stir**, the flagship, on audience and feel alone, since its puzzles are plughole depth and test no new skill.
- **Lens**, the new read. It is built first because its map already runs in the lab, so it proves the shelf, StoreKit
  and the pack pipeline.
- **Escapement**, the new move, for problem and cube solvers.

After v1, at about one a quarter: Prism, then Music Box only if it passes its ear test.

Each pack has 24 to 30 crafted, solver-checked levels (134 over the five, beside the 81
free), its own id prefix, its own pictures and layer of the one piece, its first levels free and one price. None ever
opens a tier. If Music Box fails its gate, the catalogue stays at four packs.

#### The packs

Scores are Claude's: design / engineering / market, higher better on each.

| # | Pack | Kind | Buyer | Rule | Skill | Role | Scores |
|---|---|---|---|---|---|---|---|
| 1 | First Stir | New evening | Story-first players (Florence, Gorogoa, Unpacking, A Short Hike) and plughole players | Plughole rules; each heal plays a vignette of one night, told backwards | None new | v1 flagship | 5 / 7 / 8 |
| 2 | Lens | New read | Comic and pop-art readers; core players after plughole | Some rods zoom or spiral instead of turning | Reading scale against a dot screen; three seam shapes | v1, built first: proves the pack pipeline | 8 / 7 / 7 |
| 3 | Escapement | New move | Chess-problem and logic-puzzle solvers; cube solvers; maelstrom finishers | A clock rod ticks a step after every move | Tempo: timing heals so the clock finds its seam; knowing when to wait | v1, the new move | 8 / 5 / 6 |
| 4 | Prism | New read | Photographers, designers and colour people; whirlpool players | Each rod stirs only some of red, green and blue | Reading by channel; commutation that depends on colour | First after v1 | 7 / 7 / 7 |
| 5 | Music Box | New read | Music lovers, hummers, music-box collectors, Animal Crossing and ASMR players | Pins on tracks, played by a sweeping arm; a stir garbles the tune | Melodic error-finding | Later, only if it passes its ear test | 6 / 5 / 6 |

**Every pack's sound** sits inside the one-piece structure. That structure is Jack's idea (2026-09-29; "Sound
direction" in HANDOFF.md on the `soundscape` branch), and as a whole a recommendation until he hears sketches: one
piece in D at one tempo, the menu its stripped core, each tank adding its own bass, kit and lead on a bar line. Jack's
calls within it (2026-09-29): peril rises only from tier to tier, never within a tank, and the piece runs a long
cycle. Each entry below gives only the pack's own layer.

##### 1. First Stir (recommended v1 flagship)

A wordless story told backwards: each heal rewinds one part of a stormy night in a seaside town, scene by scene,
until the last tank is a child stirring a cup of tea.

- **Role.** The gentlest pack, for the broad buyer. It leads the shelf, carries the featuring story and closes the
  trailer. On the store page it is the first pack shown after the free game, labelled as a paid add-on. Sold as an
  evening, not a challenge.
- **Buyer.** Story-first players of Florence, Gorogoa, Unpacking and A Short Hike, who buy an evening rather than
  difficulty, and plughole players who want more of the gentle game. Not the puzzle buyer, and its card says so
  ("anyone; an evening, not a challenge").
- **Rule.** Plughole rules on tri, quad, eye and pent: 4 to 10 stirs, no seized knobs, level motion none, par the
  scramble's count. Each of the scramble's entries (after `parse`) owns one vignette: a change to the clean picture
  drawn inside its own rod's rigid core (rigid cores never overlap: `Tank.plateau`'s comment), plus light it may add
  anywhere (light adds, so vignettes compose in any order). Entries carry a set of vignette tags. When a turn or a fall
  merges one entry into another, the survivor takes the union of both sets. Today `Array.commit` keeps only the
  landing entry's payload, so the merge gains that hook; `Game.Entry`'s pushed mark stays the landing entry's, as
  endless needs. A vignette shows as played exactly when its tag is no longer on the stack, so the picture is a
  function of the stack alone: a pop plays every tag it carries (several at once after a merge); a win the fine pass
  calls on a stack that only looks solved (`Game.settle` empties `entries`) plays every tag left; undo and reset bring
  tags back with their entries; and every solve plays every vignette whatever the order of heals. A vignette
  crossfades over 0.4 s under the stack. Design rule, checked by a test on every scene and every heal order: no
  vignette's light reaches the core of a rod with an entry removable right after its heal (`Layout.removable`), so
  light never shows the next move. Heal ring as in endless (Jack, 2026-09-29): magenta and the heavy tap only for a
  commit that plays a vignette; cancelling your own push flashes white. Undo is the pack snapshot from the shared bank.
- **Skill.** None new, and the pack says so: plughole's read (the newest seam is unbroken) on a picture that changes
  as you heal, so each heal asks for a re-read but no new decision.
- **Look.** Hand-composed neon line illustration of one seaside town, baked like plughole's pictures: storm indigo
  with sodium lamps, flood teal, rescue amber torchlight, dusk rose, and the last scene's kitchen gold. Every vignette
  keeps up readable in each core it touches (upright figures, horizons, lit windows), and every figure change sits
  inside its own rod's core.
- **Sound.** The lead is a felt piano playing the piece's own motif backwards across the pack, one note per vignette
  played (a pop that plays two plays two), running on across scene ends so no note marks a tank's last heal. The
  pack's last solve plays the motif forwards, whole, for the first time. Its pads are storm and rain layers that follow
  the story's weather scene by scene (the storm peaks in chapter 4, a kettle and a clock in chapter 5), set when a tank
  opens and never changing within it. Nothing sounds during a drag.
- **Structure.** 25 scenes in five chapters of 5, in reverse story order (Dawn After, The Rescue, The Flood, The
  Storm, Dusk Before), about two hours. The last tank is the teacup on tri, the night's first stir, and a "night
  forwards" film unlocks at the end. Scenes 1 to 3 free. Level ids `first-stir-1` to `first-stir-25`.
- **Weakest point.** Its puzzles are plughole depth and it tests no new skill: by its own design rule no vignette's
  light reaches a core that can heal next, so the changing picture changes no decision. It is plughole with a story,
  sold on feel. Its roughly 150 figurative vignettes need an illustrator the game has never had (every picture today
  is code, checked: `Pictures.swift`).
- **R5 fix.** None needed.

##### 2. Lens (recommended for v1: the new read)

Some rods zoom instead of turning, so you read how big a core has grown against a halftone dot screen that never lies
about scale.

Superseded in part by Jack's call L1 (round 3: the hard lens, magnify only, x1.3, a rim inside the core) and by the
drafts in `docs/lens-design.md` (branch `lens-design`), which drop the spiral and pent; the entry below is the
original pitch.

- **Role.** Built first, because its map already runs in Swift and Metal on the lab branch, so it proves the pack
  pipeline (the `Pack` type, StoreKit, the shelf and card) for the others.
- **Buyer.** The comic and pop-art reader (halftone, Ben-Day dots, risograph prints), who is also the core Unstir
  player wanting a read their eye hasn't learned. Its card says "after plughole".
- **Rule.** Each level fixes each rod's kind: twist (today's), zoom or spiral, shown by its knob (iris blades, a
  nautilus). Every kind is dragged like any rod, with no pinch. A zoom step is the lab's radial flow (d56b02e:
  `Tank.zoom` and `zoomFlow` in Twist.swift, a copy in Unstir.metal): the core scales by 1.2 a step and the flow slows
  to nothing at the disc's edge; clockwise magnifies. A spiral step is the flow, for one step, of the twist's field and
  the zoom's field added (both turn about the rod's centre, so the sum is one autonomous field): in the core exactly
  30° and ×1.2 together, in the ring the sum's flow (derived, not built). Each kind's steps form a one-parameter group,
  so a turn merges into its rod's newest entry by summing and pops at 0 through the ordinary `Array.commit`, and `same`
  and `commutes` sample each entry by its rod's kind. A zoom or spiral never wraps: +k needs exactly −k. Only the deal
  is capped (scramble entries at most ±3 steps, ×1.73). Play is uncapped, since any number of steps is a bijection (the
  lab commit's message), so no turn is ever refused for its size and probing learns nothing from a refusal. The
  stack's 36-entry limit stays, as everywhere. Level motion none. Dailies and endless are untouched
  (`testDailyVectors` and `testEndlessVectors` pass unchanged). Undo is the pack snapshot from the shared bank.
- **Skill.** Reading proportion against the dot screen's pitch, a ruler that never lies, and telling three seam
  shapes apart: a zoom seam is a band of radially squashed dots, a twist seam tangential shear, a spiral seam a log
  spiral. Where they overlap, the newest is still the unbroken one.
- **Look.** Neon halftone on black: flat colours printed as glowing dot screens (fluoro cyan #00e5ff at 15°, magenta
  #ff2bd6 at 75°, yellow #ffe600 at 0°, one pitch of 0.03 tank units), white ink outlines and a registration-mark
  bezel. Dots are generated in clean-picture coordinates, so the pitch is the ruler: a magnified core shows swollen
  dots, a shrunk one fine dots, and each core carries asymmetric linework so a 90° turn can't hide in the square
  screen. Original panels of a wordless heist told through pop-art objects and close-ups (a safe dial, an eye, a
  diamond, a getaway car), clearly not Lichtenstein pastiche. Baked, fill 0.
- **Sound.** The lead is the piece's motif in mensuration canon, the motif against itself at two speeds: scale made
  audible. On a zoom commit only, a short glass whoosh, rising to magnify and falling to shrink. The iris's detents
  are haptic ticks like the rod's, since nothing sounds during a drag.
- **Structure.** 25 panels: four issues of 6 (Close-up: zoom rods alone on tri and quad; Cut-in: zoom among twists on
  quad, eye and pent; Spiral: spiral rods; Splash: deep mixed hex tanks) and a splash-page finale. Each solved issue
  lays its panels out as a comic page. Panels 1 to 3 free. Level ids `lens-1` to `lens-25`, pars from the solver once
  it learns rod kinds.
- **Weakest point.** Scale may read slower than angle. If one 1.2× step can't be told from none at phone size, the
  rate must rise to 1.25 to 1.33. Mixed stacks may murk past about 10 entries. Zoom and spiral aren't area-preserving,
  so a shrunk core may glitter under the four-tap average. None of it has been filmed on the phone.
- **R5 fix.** None needed.

##### 3. Escapement (recommended for v1: the new move)

A book of composed problems with a clock in them: one rod ticks a step by itself after every move you make, and you
must time your heals so the clock always finds its seam.

- **Role.** The critics' and puzzle press's pack, for problem solvers and cube solvers.
- **Buyer.** Chess-problem solvers and hand-made logic puzzle players (Stephen's Sausage Roll, The Witness,
  Snakebird), who pay for one insight per puzzle and no filler. Second, twisty-puzzle and Rubik's cube solvers, the
  audience nearest Unstir's own mechanic, who already plan move sequences around their side effects and race for
  fewest moves. And players who finished maelstrom. Its card says "hard: composed problems".
- **Rule.** A clock rod E has a ratchet for a knob, a new knob kind. It can't be turned, and a tap on it is a new
  `Grab` case (`.seized` holds nothing). E's scramble entries are negative, and after every move E ticks +1 through
  the ordinary `Array.commit`, merging into E's newest entry when everything above it commutes and popping at 0. A move
  is the net of one working knob's open stir, or a wait (a tap on the ratchet).
  - *Superseded again (Jack's round 11 call EL1, built on PR #52):* par is not a thing for Escapement. A tank has a tick
    budget, and each escapement's tick takes one off it, so several clocks cost several ticks for one move; the
    budget is always shown. A wrong move leaves the puzzle impossible without an undo, instead of losing at once.
  - *Superseded (Jack's round 9 call E1, built in PR #46):* every let-go is a move of its own and final, its tick
    landing with it and a losing tick showing "lost." at once; nothing lifts out or seals. The timing below is the
    lab's, kept for the record.
  - *Timing, with no timer anywhere.* The tick lands the moment a stir is let go, provisionally. While that stir is
    open, re-grabbing its knob lifts the tick back out (the pawl rises, E's core steps back) for the drag; letting go
    lands it again on the new net, or drops the move and its tick together if the net is zero. So a wrong stir turned
    straight back costs nothing, as Jack's call on turn-backs requires (Jack, for now, 2026-09-28). The next commit of
    another working knob seals the open move (no new tick for the seal; that commit then lands its own), as `Game`'s
    open stir closes only on another slot's commit. So a look at another knob, or a drag not let go, seals nothing. A
    ratchet tap seals the open move and then waits, one more tick. A tick that empties the stack solves on the spot,
    so the last move needs no seal. The clock stops, with a chime, once E holds no entry.
  - *Lost.* A tick that pushes (E's newest entry buried under an overlapping one) leaves a positive E entry. Only +1
    ticks ever reach E, and the overlapping entry beneath can't come off past it, so that entry never pops and the
    stack can never empty. While provisional it shows as a vermilion +1 on E's core and a red flash on the ratchet.
    Once sealed, "lost." stamps the page over a card with undo (if the bank has one) and again (a reset, free as
    everywhere).
  - *Variants.* Two Clocks: both tick after each move, the clock nearer twelve first, and tapping either ratchet
    waits. Wound Back: a clock ticking −1 over positive entries, the rule mirrored.
  - Undo is the pack snapshot: the move and its tick together, from the shared bank. Level motion none: no chapter
    turns the tank, since a turned tank would tick whatever seam sits under the ratchet. Each problem states "Unstir in
    N", and par is the prover's optimum.
- **Skill.** Tempo: planning a whole move order so a forced side effect lands as a heal, and knowing when to wait.
  Nothing in the free game moves unless you move it.
- **Look.** The only light-ground pack: a problem book in bone paper (#f3ead8) and black ink (#1a1a1a) with one
  vermilion (#d8402a) accent per plate, engraved engine-turning (straight rays from off-centre points and barleycorn
  chevrons, which read up in every core; never concentric rings). E's core holds a vermilion sub-dial with a 12 index;
  its knob is a ratchet wheel whose pawl drops a tooth on each tick. The stipulation is set in a serif under the tank.
  A light ground needs no change to the map, since the shader's white term is zero unless the solve wave is on
  (checked: Unstir.metal), but the solve wave and the turn's hairlines get dark-ink variants, and ink lines stay at
  least 2 px wide, because the four-tap average in squared light fades dark lines on a light ground. Procedural, baked.
- **Sound.** The layers are the piece's muted kit and a dry, close lead. Each tick is a pencil-like tooth drop as it
  lands, never a running tick-tock, which would read as a timer. Each move steps a phrase of the piece's motif one
  note, looping without resolving, and only the solve lands it on the tonic, D, never move N on an unsolved page.
  Nothing sounds during a drag.
- **Structure.** 30 problems in five chapters of 6: The Clock (one clock, no slack), The Waiting Move (slack to burn),
  Two Clocks, Wound Back (a clock ticking −1), Grand Complication (deep pent and hex, three clocks on hex one page
  before a two-clock hex finale, J6 = B), each opening on a wordless teaching problem. After each solve the composed
  line replays. Problems 1 to 3 free. Level ids `escapement-1` to `escapement-30`; every problem ships proved (a line
  at N exists and none is shorter).
- **Weakest point.** The smallest, most demanding buyer and the hardest content to make: 30 composed problems, each
  proved by a pruned search that may not reach N on hex, a lost state harsher than any tier, and a paper page that
  breaks the shelf's neon.
- **R5 fix.** It revives R5's "a telegraphed second stirrer" (its queue works as an answer key, and it adds animation
  to every move), and fixes both. The clock queues nothing: always the same +1 on one rod, known before the first
  move, so it shows nothing about the scramble. Its only animation is one tooth and one 30° step of E's own core per
  move.

##### 4. Prism (v1's third pack, Jack's call PK1 = A, round 12)

The picture is one engraving drawn three times in red, green and blue light, and each rod stirs only some of the
colours: unstir until every coloured ghost snaps back into one white line.

- **Role.** v1's third pack, in First Stir's place (PK1), the colour half of the Optical Bench candidate. Every
  specimen is at depth 8 or less (PK1). **State (2026-10-29):** ships in Release (`Pack.ships`, Complete, the
  dock, its card and clip, Complete's cut). Left before it ships for real: Jack's play of the 30 specimens on the
  phone; the phone GPU bench (to-do 60); Prism's product in App Store Connect beside the others; its own sound, if
  Jack wants one (it takes plughole's bed and the shared effects, as Lens and Escapement do; the design's detuned
  three-voice lead would go to Jack as sketches first); the cover is the fern printed off register, drawn in code.
- **Buyer.** Photographers, designers and colour people (chromatic aberration, misregistered riso and anaglyph
  prints), and whirlpool players who liked a picture that makes them work for its up.
- **Rule.** Each rod carries a channel mask (red, green, blue, cyan, magenta, yellow or white), shown by its knob's
  tint. A stir moves only its channels, so channel c is sampled through the word of entries whose mask holds c. Two
  entries commute when their discs are disjoint, when their masks share no channel, or when their maps commute on
  every shared channel, judged by `same` on each channel's restricted word (today `same` samples one map for the whole
  word, checked: Twist.swift); `landing` and `commit` are otherwise unchanged. Each scramble's bottom entry is white,
  so no channel is ever clean on its own. The win is every channel looking solved (`looksSolved` per channel). Level
  motion none. The Optical Bench's strain-lit half is cut: its fringes read a step's size directly, a closeness
  meter. Undo is the pack snapshot from the shared bank.
- **Skill.** Reading by channel: which channels a seam broke, from the colour of its ghosts, and working out what is
  free to heal when commutation depends on colour. No free tier splits a picture into parts that stir independently.
- **Look.** Natural-history engravings (a fern, seed heads, medusae and radiolarians after Haeckel, a nautilus) in
  fine lines. Misregistered, each splits into red, green and blue ghosts, with cyan, magenta and yellow where two
  coincide; aligned, it is a white line drawing. For colour-blind players each channel draws its own line style (solid
  red, dashed green, dotted blue) when iOS's Differentiate Without Colour setting is on. Off, every channel is solid,
  since mixed styles would keep aligned lines from going pure white. Both are checked by a colour-blind simulation
  before any level is made, and holding a channel's swatch shows that channel alone. A spectral bezel. Procedural,
  baked.
- **Sound.** The lead is the piece's motif in three detuned voices, one per channel, over cold FM glass-bell pads.
  They resolve to unison only on the solve, never during play, so the sound is no closeness meter. A heal is a struck
  glass rod, pitched by heals done. Nothing sounds during a drag.
- **Structure.** 30 specimens in five trays of 6, every one at depth 8 or less (PK1), built 2026-10-29
  (`docs/prism-design.md`): Two Colours on the fern (red and cyan), Three Colours on seed heads (the primaries),
  Colour Order on medusae after Haeckel (the inks, each pair sharing a channel), Overprint on radiolarians after
  Haeckel (primaries and inks), Spectrum on a nautilus (any mask). Later trays are harder by colour order, not depth, and every
  specimen keeps to readability limits on how much of the glass ghosts and splits three ways. Specimens 1 to 3 free.
  Level ids `prism-1` to `prism-30`.
- **Weakest point.** Fine lines may mush past about 8 entries, the colour-blind read rests on line styles nobody has
  tested, and each channel's own inverse chain costs up to 3× an entry (assumed) until the performance pass's cached
  chain lands.
- **R5 fix.** None needed.

##### 5. Music Box (later, only if it passes its ear test)

The tank is a music box disc whose pins a comb arm plays as it sweeps: a stir garbles the tune, and every heal brings
a phrase back in.

- **Role.** The sound-led pack, built after the audio engine and only if it passes its ear test.
- **Buyer.** Music lovers and hummers, music-box collectors, Animal Crossing and ASMR players; the Composer's shared
  tunes reach people who never search for puzzles. Its card and store page say "needs sound", since deaf and
  hard-of-hearing players can't play it.
- **Rule.** The picture is pins on tracks round the tank's centre: radius is pitch (ten irregularly spaced tracks on
  the piece's scale on D), angle is time (12 beats a sweep, so the 30° step is a beat, with onsets on eighths). A
  hairline comb arm fixed to the screen sweeps clockwise from twelve once every 12 beats and plucks each pin it passes
  at the pin's current position. Its clean point is carried forward through the stack and any live twist (the lab's
  `Layout.forward` does this for its lights), its pitch snapped to the nearest track and its time to the nearest
  eighth: a displaced pin plays a whole wrong note, never a quarter tone, and now and then the right one. A turn of
  hex's hub shifts its core's pins by whole beats; off-centre rods move pins to new pitches and beats. A hum control
  replays the clean sweep. Rods, stack, par, level motion (none) and the geometric win are unchanged; undo is the pack
  snapshot. Two exceptions to the game's sound rule (a sound never tells the player anything the picture doesn't),
  inside this pack only, are recommended and not yet decided: sound carries the read, and the arm keeps playing during
  a drag.
- **Skill.** Melodic error-finding: hearing which beat and register of a known phrase is wrong, and mapping beat to
  angle and pitch to radius to find the rod.
- **Look.** A black lacquer disc (#0b0b0f) with silver star pins (#d8dde6) and a mother-of-pearl label carrying the
  tune's title; no staff rings, which would draw seams. Each pin glints for 80 ms as it is struck, so the eye can
  follow the ear; the arm is a 0.5 pt silver hairline. Pins are drawn at their forward-mapped points, so they move but
  never smear. A baked disc; pins and glints a small overlay.
- **Sound.** The box is the pack's lead: steel tines rendered once per pitch in Csound (plucked steel, a soft damper
  buzz, a wooden case's resonance) and a winding-key crank at the start. The piece keeps running beneath, stripped to
  its core (the D hum and halo pads, no kit), and its tempo sets the sweep, a whole number of its bars that starts on a
  bar line, so the box never drifts off the beat. Tunes: public-domain melodies (Amazing Grace, Auld Lang Syne) in
  their real rhythms, and phrases of the piece's own motif; the finale arranges the main motif.
- **Structure.** 24 tunes on four cylinders of 6 (tri, quad, pent, hex), the last two with stem lanes (bass, melody
  and counter-melody tracks, so the ear tells which register broke). Each solve winds a phrase onto the pack's song.
  Then the Composer: place pins, stir them and send a link a friend opens to unstir the tune (playing a received tune
  is free; titles and links carry report and block tools). Tunes 1 to 3 free. Level ids `music-box-1` to
  `music-box-24`.
- **Weakest point.** Claude can't hear, and the read is the ear: it ships only if sound on finds seams clearly faster
  than sound off in a cold read. Phones play muted, deaf and hard-of-hearing players are shut out, and the Composer
  brings user content, moderation and an age-rating question.
- **R5 fix.** None needed.

##### 6. The Well

Cut (Jack, 2026-10-24). See R9.

#### The ladder: what packs may not take

Rule: no pack takes a mechanic a free rung needs, so the rungs are chosen first. Jack plans both as free tiers
(2026-09-28).

- **Vortex**, between whirlpool and maelstrom: the lab's whole-tank swirl (b6ed01c: quad plus a rod of radius 1 at the
  centre, turned by dragging the rim). It is a stir like any other whose disc covers every rod, so it orders every
  seam and teaches the rim before maelstrom turns the glass with it. It breaks the "cores clear at 0.6" rule (its core
  overlaps every rod's), so its go/no-go is whether a swirl seam reads through the cores on the phone.
- **Charybdis**, beyond maelstrom: independent orbits, the Orrery candidate's mechanic (Jack's call, round 2). Maelstrom is orbits with every
  working knob at one rate (a step of the glass is every knob moving one slot round it, hex's hub a sun at rate 0), so
  orbits are the line maelstrom starts. They reuse its solver (positions become crank ticks, a reach table per tick,
  the lcm of the planets' periods), its rim and its lesson. Planets ride the crank, never a tap, which answers R5's
  "fewer knobs than rods, carried by tap" (admin, a tap fighting the drag): moving them is the puzzle, not admin. Two
  planets on one slot make it live once (the finger holds that slot's rod), are drawn side by side 0.04 apart along
  the slot circle, and strike their bells together as they land. During the crank's drag only haptics play, since
  nothing sounds during a drag.
- **Packs keep what no rung needs:** zoom and spiral (Lens), the clock (Escapement), channels (Prism), the ear (Music
  Box).
- **Coriolis is benched**, not offered to charybdis, since its one-way knobs break Jack's free slip.

Jack settled it (round 2): charybdis takes the orbits and Orrery is not a pack. Nothing else on the bench or in the lab
survives as a rung: linked rods are R5's admin, and the frozen core and lights-off subtract from the read.

#### Open for Jack: four decisions

All four are answered: see "Jack's calls on the pitch" above. The prices are set (Jack, 2026-10-25: 2.99 a pack, 5.99
Complete). The three left open since are answered too: the product names by Jack's yes to the defaults (to-do 3), the
archive's back-fill and the consent question in round 6.

#### Recommended defaults (not decided; 2026-10-24)

These are Claude's recommendations, not Jack's calls. None is built until Jack has said yes to it, alone or as a
list. Three are hard to undo once live and need an explicit yes each, marked **(hard to undo)**: Family Sharing, the
names and product ids, and Complete's promise to older owners.

- **Price.** One price for every pack, inside R1's band ($2–5), never set by difficulty or size; Jack picks the
  number. Jack's call (2026-10-25): 2.99 a pack, 5.99 Complete.
- **Complete's price path.** **(hard to undo)** About one pack less than the packs it holds. Each new pack joins it and raises it by one
  pack's price. Owners of an older Complete are granted later packs by the app, which the store page never promises
  (check App Review first).
- **Free taste.** The first three levels of every pack free, as its wordless teach-in.
- **Tier gating.** None: every pack opens from the first launch, its card says what it assumes ("anyone", "after
  maelstrom"), and no pack best ever touches `Tier.isOpen` (tested).
- **Undo in packs.** The shared bank (+2 a playing day, capped at 10, never sold), one undo per move, restoring a
  snapshot of the state before that move (the stack's entries with their marks and tags, the clock's tick). The free
  tiers keep today's undo, except that an undo leaves the stir it uncovers open (Jack's call; merged 2026-10-25, PR
  #19).
- **Undoing a heal in a pack.** Its vignette unplays and its note steps back, as Claude already recommends for every
  heal's note.
- **Turn-backs in Escapement.** Not free (Jack, round 2): the tick is final once a move is committed; a look that lets
  go where it started is no move and no tick. The pack's first level shows the clock working before the first stir.
- **Escapement's tick budget** (Jack's round 11 call EL1, which replaced round 9's E1/E2 loss rule, where a pushed
  tick or the last clock stopping with twists left lost at once): no par; a budget of ticks that every clock's tick
  spends, a wrong move playing on until the budget is spent, then "out of ticks." with undo (if the bank has one) and
  again (a free reset).
- **First Stir's heal ring.** Endless's rule (Jack, 2026-09-29): magenta and the heavy tap only for a commit that plays
  a vignette; cancelling your own push flashes white.
- **Music Box's two exceptions to the sound rule.** Allow, inside Music Box only, sound carrying the read and the arm
  playing during a drag. A recommendation for Jack to take after its ear test, not his call yet.
- **Music Box's gate.** Cut it if, in a cold read, sound on doesn't find seams clearly faster than sound off. The
  catalogue then stays at four packs.
- **Music Box's pitch.** Snap each pin to the nearest track and eighth, so errors are whole wrong notes; no quarter
  tones.
- **Each pack's sound.** Layers (bass, kit, lead) of the one piece in D entering on a bar line, inside the one-piece
  structure. Each pack's peril is set for the pack and never rises within a tank. Sketches go to Jack before anything
  is polished.
- **Store page.** Lead with the free game (a picture snapping back), then the packs, every screenshot or preview moment
  of a pack labelled as a paid add-on (guideline 2.3.2, assumed).
- **Family Sharing.** **(hard to undo)** On for every pack and Complete, knowing that once on for a product it can't be turned off
  (assumed Apple platform fact; check).
- **The daily archive.** Back-filled to a date Jack picks, opened by any purchase, with bests under `daily-yyyymmdd`
  ids. Jack's call (2026-10-25, round 6): 30 days before launch day.
- **The supporter mark.** On the menu and in the daily share line, after any purchase (no tips, so it is the thank-you).
- **The tip jar.** Dropped (Jack: "No begging.").
- **Vortex and charybdis.** Free updates after v1, their mechanics reserved now (Jack's call, round 2), each with its own
  go/no-go on the phone.
- **Rim meanings across tiers.** Vortex's rim swirls, maelstrom's turns the glass, charybdis's cranks the planets.
  Vortex's go/no-go checks that a player moving up isn't misled.
- **Speed and competitive players.** Left out on purpose, reading the feel Jack set for the music (2026-09-29: "no
  pressure, no crescendo, no rising danger") as a rule for play: no rush, no timers, no leaderboards.
- **Sharing (stir-a-friend links, photo postcards).** A free feature after v1, receiving always free. The daily share
  line (plan step 2) is separate and stays before TestFlight.
- **Relief's audience.** No paid chapter; a free "Eyes Shut" mode after v1, prototyped with a blind tester before any
  art.
- **Game Center and a web domain.** Neither at v1; a domain comes with sharing and Music Box's Composer links. *Round 14, F5 = B replaces the Game Center half: sign-in plus achievements, no leaderboards, if the overlay test passes.*
- **Languages at v1.** English only, with every string in a String Catalog from the first pack (captions, the shelf
  and pack cards, Escapement's stipulations, purchase text), so a language is a translation job. Store metadata in
  English on every storefront. *(Round 14, F4 = C: this stands for launch; languages come as their own update.)*
- **Progress backup.** Bests and pack progress sync through iCloud key-value storage from v1.
  The undo bank and its clock anchor never sync.
- **How to read testers' play.** Jack said yes to analytics done respectfully (round 2): anonymous counts only, no
  tracking prompt, no advertising partners, one switch in settings. Jack's calls (2026-10-25, round 6): a library for
  TestFlight and launch, plus a send-log button, asked once at first launch and off until Yes.
- **Albums.** Each pack's music released as an album once Jack approves its sketches, through a distributor chosen
  then, its account details kept in `HANDOFF.private.md`.
- **App size.** Packs ship in the bundle, art as line paths baked on the phone and audio as AAC. Background Assets
  only if the app would pass the cellular download limit (assumed about 200 MB; check).
- **Names and ids.** **(hard to undo)** The roster's names. Each pack's id is its level prefix (`first-stir-N`, `lens-N`,
  `escapement-N`, `prism-N`, `music-box-N`, clear of `L`, `N`, `N+`, `M`, `daily-`, `endless`, `sandbox`
  and `lab-`). Product ids `<bundle id>.pack.firststir` and so on, plus `<bundle id>.complete` (letters, digits,
  periods and underscores; assumed).
- **Offer codes.** Dropped (Jack: "No.").
- **A revoked pack.** Progress kept; levels past the free taste show the pack card again.


## Side task: the difficulty tiers (started 2026-09-28)

Jack's asks: Nightmare+'s animated backgrounds become Nightmare's; Nightmare should have several live backgrounds, as
the campaign has several pictures (any colours); Nightmare+ needs something genuinely novel and a real step up; the way
from Nightmare to Nightmare+ is easy to miss.

| Item | State |
|---|---|
| Nightmare on the live background | Merged 2026-09-28 (PR #2). The baked cracked glass is deleted |
| More live backgrounds | Set, palettes, twins and level table decided (below); all ten ported with the heartbeat in the twins' lines, tests passing; Jack approved the films and the cost. Merged 2026-09-28 (PR #2). `fillEntries` stay Mac-measured: no phone benches until the performance pass (Jack) |
| Maelstrom (was Nightmare+) design | The seized rod and the turning tank (Jack, 2026-09-28). First slice merged 2026-09-28 (PR #4). Go/no-go shots pass: seams land concentric after a turn, and a finished outer ring reads on hex glass (the hub doesn't, but it never moves or seizes). On the phone (Jack, 2026-09-28): the rim is easy to grab, two fingers always turn the tank, he plans where to park the dead knob, and he likes the glass easing home after the solve. The tank clicks felt featherweight: each tank step now plays a Core Haptics clunk (a hard knock and a 90 ms low rumble), and Jack finds it great. The first step after launch or a return from background may hitch a frame while the engine restarts. Pars must come from a solver of the ending-on-the-last-heal rule: the temporary table used the old model's pars, which counted a final turn home, so Jack finished a move under par |
| The way in | Jack chose the strip (2026-09-28) from three working mock-ups (strip, dial, window), for its ticked line of the levels left to open the next tier; he loved the window's live tank but it took too much of the screen. Built on `tiers` with the rename and the gate, merged 2026-09-29 (PR #7); the swipe was driven by simulated touches, never a finger. The swap freezes 50–107 ms on the simulator: left for the performance pass |
| Rename | Nightmare is now **whirlpool** and Nightmare+ **maelstrom** in code, harness (`UNSTIR_TIER`), scripts, tests and docs, merged 2026-09-29 (PR #7). Stored level ids stay `N<k>` for whirlpool, so progress carries over (Claude first planned new ids, which would have reset it; the review caught that). Maelstrom's own set took fresh ids `M<k>` (on `maelstrom-set`, 2026-10-24), so old N+ bests don't land on new levels |
| Solver and the maelstrom set | Solver built and verified (2026-09-29), merged 2026-09-29 (PR #10, then PR #13 into `master`). An independent brute force found a push that holds a disc still and beats plain untwisting by a move, so the optimum now adds a bounded search for such detours: par is the solver's bounded optimum, not a proof. The park rule has two readings (fewest dead knobs over rings with a seam, or every dead knob over a ring without one) and no tie-break (Jack, 2026-10-24); the set is fair under both readings however its ties go. A first proposed table passed every check but its early planning gap came from a tie-break (a lucky guess of direction scores par), its first ten levels all turn counterclockwise, and its seized pairs were always neighbours. A second reworked it, and a third, all new levels, was proposed below (2026-10-24), with Jack's calls on it. Merged 2026-10-24 (PR #14): the 27 levels under ids M1–M27 with M1's note, the solver's `parkTies` (the park rule with no tie-break, its fewest and most moves over every way its ties go) and solve.sh printing it, and tests that every level's par is the optimum and the park rule's worst over its ties under both parkings. Jack's playtest (2026-10-24): the seized knobs moved once, parked over finished work, and never mattered again. Most levels needed only one or two turns, and the hex levels' park lines ran 7–17 moves after their last turn. Merged 2026-10-24 (PR #17): M7, M8 and all of hex (M15–M27) replaced from the pool by levels that need three or more turns in hex (two in M15–M18), the park line never more than a third of par plus one without a turn (`testMaelstromKeepsTheTankTurning`), every pick fair and checked with solve.sh; the finale is new too (gap 7, three turns), which Jack accepted. The frontier: a short run costs nothing in pent, and in hex keeps a planning gap of up to 7 at three turns; four or more turns cap it at 5. The pent order is now v5 M7, v4 M9, v4 M10, v5 M8, then M11–M14 |
| Endless's new rules | Built on `endless` (2026-09-29): no undo, reset or par, the brim counting red flashes, Claude's ramp, and the vivid jug on the rim, ported from the approved film. Reviewed, and the review's fixes made, the pour over the lip among them. Jack watched the app's film on 2026-09-29 and approved it ("looks great"); merged 2026-09-29 (PR #11). See "Endless changes rules" below |
| Vortex (the swirl) | Jack's calls 2026-10-24: the whole-tank swirl is the tier vortex, between whirlpool and maelstrom, and the rim must show what it does before a move. Built on `vortex` and merged 2026-10-25 (PR #22): the swirl layouts, the rim grab, the tier and its gate, the swirl's lesson, the solver's `interacts` pruning, three rim-cue variants (since removed), and 27 provisional levels. Jack's calls of 2026-10-25 (knob cue but no ticks, then breath as the swirl's cue; the swirl with seized knobs goes to charybdis; the table provisional; a picture family of its own, all three families; a swirl on all five layouts) are in "Vortex (provisional, 2026-10-24)" below. Vortex's pictures merged 2026-10-25 (PR #28); breath merged 2026-10-25 (PR #30), which removed the ticks, the bands and glyphs cues and `UNSTIR_RIM` |
| The phone | Installed 2026-10-24: a Release build of `maelstrom-turns` (since merged, PR #17; the set that keeps the tank turning); before it, `maelstrom-set` (since merged, PR #14) for Jack to test the new maelstrom set (M1–M27). Before that, installed 2026-09-29: a local build of `touch` at 42406cc with `help`'s three commits (hints removed, the daily +2 refill, the clock guard), the glass sound set, and two proposals not to be committed (maelstrom v2 as M1–M27, and plughole 19–27's easier scrambles). The next install carries the dashes |

**Jack's calls (2026-09-28).**
- Nightmare+ becomes the seized rod and the turning tank, below. Bookkeeping stays the fallback if the go/no-go fails
  (a finished ring doesn't read on hex glass, or the rim drag feels wrong on the phone).
- The level ends on the last heal, with no turn home, so no notch or home index. This was Claude's recommendation;
  Jack said to build the recommended rule, and Claude has taken it as included.
- Only tanks that need and work with the new skill go in the tier, and they are a new set built around it; the old
  N+ scrambles (Nightmare's, reused) are scrapped. Tri and eye can't carry the skill, so the set is quad, pent and hex.
- The tiers are renamed **plughole** (the campaign), **whirlpool** (Nightmare) and **maelstrom** (Nightmare+). The
  ladder leaves room for two more: **vortex** between whirlpool and maelstrom, and **charybdis** beyond maelstrom.
- Each tier opens when every level of the tier below is done at par.
- **Hints go** (Jack): undos are the help, and a player who can't reach par with them hasn't earned the next tier. Par
  stays reachable by persistence alone, since a reset is free. Removing them also spares maelstrom a hint of its own.
  Removed on `help` (2026-09-29): no hint control is left, and a best saved while hints existed still loads and counts
  at par (`testABestSavedWithHintsStillCounts`).
- **Plughole gets easier** (Jack agreed to Claude's proposal): keep levels 1–13 as they are; take the pent and hex
  levels down to about 7 and 9 stirs, with fewer quiet stirs hidden under loud ones. Measure every level first with
  the maelstrom solver (stirs, hidden stirs, choices per step) and show Jack the table. Jack's own results, the only
  play data so far, are in `HANDOFF.private.md`.
  **Merged (PR #50), Jack's call PH1 = A (2026-10-29): pent and hex both eased.** Measured with
  `scripts/plughole-levels.sh`; "choices per step" is defined there as the rods that could rightly come off next,
  averaged over the untwist. 19–22 (pent) go from 6, 7, 8, 9 stirs to 5, 6, 6, 7 and 23–27 (hex) from 7, 8, 10, 12, 14
  to 6, 7, 8, 9, 9; hidden stirs from 16 to 6 over the nine. Each is dealt by the frozen generator from a seed (in the
  comment over the table), par is the solver's optimum, titles kept, the first hex level leaves the hub out. Claude
  recommends easing both layouts; easing hex only is the alternative. Side effect for a later call: whirlpool was built
  at twice plughole's stirs, and its 19–27 are untouched, so they now run 2.4–3.1 times the eased levels.
- **A wrong stir turned straight back stays free** (Jack, for now): a slip of 30° is too easy, and charging it would
  upset players chasing every clean. So par and the gates measure persistence as much as reading: a player can try
  each rod, turn back each red flash and never go over par (the free test; simulated on endless tanks).
- **Endless changes rules** (Jack): no undo, no hints, no par; just unstir each tank, however many moves and however
  long it takes. It ramps a little faster and goes much deeper. Jack likes a capacity limit, the tank's brim, if it
  is truly intuitive, always visible and on-theme; he rejected draining the picture's colour (it hurt the read and
  looked sharper, not blended). The gauge must never touch the picture before the spill. **The brim counts red
  flashes** (Jack, after the side-by-side film): each red flash adds a notch that stays when the stir is turned back;
  each heal of one of the tank's own stirs settles one (cancelling your own wrong stir is not a heal); the level
  carries across tanks; the run ends when it spills. Counting the stirs in the tank was the alternative: anyone who
  turns back every red flash never rises. The one free probe left is a drag not let go, which only a reader of the
  picture can use: the live ring says whether letting go will count, never whether it's right. A 30° slip on the
  wrong rod costs a notch in endless; heals absorb the odd one. The capacity (8 in the approved film) waits for
  TestFlight.
  **The look** (Jack): the measuring jug on the real rim, filled with the picture's own colours (the only look whose
  single frame read as a level to a viewer who didn't know it), with the tide's outward-spreading colour and vibrancy,
  which Jack loves, grafted on. The tide itself failed on the real rim: even at 1.5x thickness a viewer read the band
  as a thick bezel, and another took it for the picture shrinking. Jack approved the graft's film (2026-09-28: "very
  nice"): each notch arrives as the picture's colour spreading across the rim behind a glint, and a glow off the
  filled arc grows as the room runs out. Still open, from two cold reads: the spill swells the whole rim instead of
  pouring over the lip at twelve, the rim goes pastel just after it, and "spilled." is easy to miss.
  **The rules, as built on `endless` (2026-09-29).** No undo control (`Game.undo` refuses), no reset (it would bring
  back entries the brim has already settled on) and no par (`Game.over` is 0 in endless); moves and time are unlimited.
  The capacity is `Run.room`, 8, the approved film's ticks: the eighth notch spills. A notch is added by every commit
  that pushes, the same event as the red ring, the red header flash and the warning tap, and it stays whatever becomes
  of that entry: turned straight back, cancelled later, merged into, or merged down onto one of the scramble's entries
  when a heal below it lets it fall (`testAPushThatMergesDownKeepsItsNotch`). A notch is settled by every one of the
  scramble's own entries that pops: the one a commit cancels (the magenta ring and heavy tap), and one that a push the
  heal lets fall cancels in the same commit, so a right turn made too early ends where it would had it merged and been
  healed later (`testAPushThatFallsOntoTheScrambleHealsIt`). The stack now marks the player's pushes (`Game.Entry`), and
  an entry a turn merges into stays whose it was, so a scramble entry turned part way, or that a push fell onto, still
  settles one when healed. Nothing settles for cancelling the player's own push, for a white merge (even into the
  scramble's entry, or two of the scramble's that a heal lets merge: they are healed as one), or for a heal with the
  brim empty (no credit is banked). The tank's last heal settles one like any other, and the next tank opens with what
  is left (`Game.nextTank`); where the fine pass calls a win on a stack that isn't empty, the move that got there
  settles one if any of the scramble's entries is left and the move healed none. The card on a cleared tank shows moves
  and time, and "tank N · brim k / 8", with next; at the spill, "spilled." over the tank, moves and time, and "tanks
  cleared K · best B", with new run. `Best.tanks` keeps its meaning (most tanks cleared in one run). `UNSTIR_BRIM=n`
  opens endless at n notches for one launch.
  **Claude's calls in building it:** the ramp, as Claude proposed: tank n has 5 + 5n/4 stirs, n/2 of them hidden. The
  cap is 28 stirs, from tank 19 (the 20th): the stack holds at most the scramble plus the brim's notches, so at 28 the
  push that spills (7 notches held, at most 35 entries) always fits under `Tank.maxStack` (36); 30 would let a full
  stack refuse pushes, and its dashed ring would then mark which turns merge. 28 also keeps the dealt tank at four taps
  (`Tank.fourTaps`, 30, less the grid's fill of 0); with more than two pushes held on a 28-deep tank the shader drops to
  two taps. Hidden stirs rise to 14, half of the 28, from tank 28. As first built they rose to 27, all but the bottom
  one, and the generator then made nearly every stir 60° (the review, over 300 seeds: 2-step stirs a fifth to tank 19,
  half at 40, 95% from 54), a word of equal twists nothing else in the game deals. Capped at half, 2-step stirs hold at
  about 30% from tank 28 (help's ramp had 29% at its tank 36). It hides at least what it is asked, and more where no rod
  can go louder: 27 of 183 tanks checked (0 to 60, three seeds) hid 1 or 2 more. So the ramp stops at tank 28: the
  stack's limit caps the stirs, and hiding more past half only flattens their sizes. How it might keep ramping past
  there (a generator of endless's own that hides without flattening sizes, or maelstrom's seized knobs on deep tanks)
  is for Jack. The generator itself is untouched and marked frozen, so every daily is as it was (`testDailyVectors`
  unchanged); endless is re-pinned (`testEndlessVectors`). Endless takes no undo refill, as the sandbox takes none: it
  never touches the bank or the refill's clock anchor, and has no undo control to show the "+2" on, so the day's refill
  waits for the next level that counts.
  **Cancelling your own push flashes white in endless** (Jack, 2026-09-29, on Claude's recommendation): it settles
  nothing, so it shows as a merge, and the magenta heal ring and heavy tap mark only a commit that pops one of the
  scramble's entries, the brim's own event. Elsewhere every cancel keeps the ring. **Open.** When `sound` lands, its heal
  (cancels less a stir turned straight back) counts a later cancel of the player's own push as a heal; it should take
  the brim's event instead, and its endless over-par case is gone.
  **The jug as built (2026-09-29).** Ported from the approved film into Brim.swift and Brim.metal (see CLAUDE.md). A
  review against the film found drift, since fixed: the bloom ran about 30% strong (now within about 10% of the
  film's bloom-to-band ratios at every level measured), its glow ended in a hard circle 64 units out (now drawn to 110
  and faded), a push landing while the notch before still surged cut that light off in a frame (the last two notches
  now keep their own clocks), the empty jug had a white glint at six (the surface now stands clear of the edge), and
  the murk glittered where the stir squeezes lines finer than a pixel (now averaged along each pixel's footprint, as
  the mockup's was; against a supersampled reference it keeps the fine lines and loses the speckle). The caps stay
  over the murk, as in the film. The murk's cost on the phone is unmeasured: up to 48 taps a pixel, for the spill's
  few seconds. The tank's number moved from under the move count to the title ("Endless, tank 1"), where it can't read
  as the gauge's count, and the tank now sits where every other level's does.
  **The three open points.** The spill no longer swells the whole rim: a crest swells over the lip at twelve and
  breaks, and the liquid pours down the outside either way in a wave behind a glossy bead, dressed as the mockup's
  sheet in the rim's own colours, slowing past three and nine o'clock, where two drops fall from each head; the brim
  pin stays on top. A first try (a mound at twelve) burned to white, hid the pin and held still instead of running.
  The rim keeps its full colours after the spill (a spill changes no stack, so it never goes pastel), and "spilled."
  sits over a dark pool with a red glow. Jack approved the app's film (`scripts/film.sh endless-brim-run`) on 2026-09-29; no cold reader has seen the new pour.
  **A cold read of the app's film** (a viewer who didn't know the game) raised points that question the approved look
  or Jack's rules, so they wait for Jack rather than being changed: near full reads as charged or complete, not as
  danger (the glow grows as room runs out, as approved, and no colour warns); the lit rim at the start reads as the
  picture's neon, not an amount (the film opens at 5 notches; a real run opens empty); what fills it is hard to infer,
  since moves both lowered and raised it and only the red ring on the disc and the red header flash tie a rise to its
  move; the ring and pin read as a dial, and the card's time is never shown in play; the drag's count lingering after
  a turn (from `touch`) can read as points added. One claim was wrong: the level lands on a tick at every notch (the
  ticks are 22.5° apart, not 30°). Claude's recommendation: let TestFlight test the first three before changing the
  look; tying each rise to the disc that caused it (a notch of colour leaving that disc for the rim, say) would not
  change the jug.
- Switching between tiers must be easier to find than today's header toggles, and on-brand. Jack's idea: stir
  between modes. He chose the strip (see the table).
- Order of work: the go/no-go slice (`turning-tank`), the switcher as mock-ups for Jack to pick, the rename, then the
  level set, whose table (layout, depth, seized knobs, par, planning gap, picture) goes to Jack before it is written
  into `Levels.swift`.

**The first playtest (2026-09-28, a playtester on Jack's phone, loving it).**
- Touching where two discs overlap, you can't tell which rod will move. Then the nearest centre won, and the only cue (a
  dashed ring and the start notch) sat under the finger. Claude recommended lighting the held rod the moment a finger
  lands, and in an overlap letting the first few points of motion pick the rod whose turn explains them. Both were built
  on `touch` on 2026-09-29. On the phone Jack found the motion pick "much more unpredictable... chooses wrong more often
  than not". The first ~1.3 mm of a touch is mostly the finger rolling as it presses, and a simulation showed noisy
  first motion hands 20–40% of overlap touches to another rod. It was set aside the same day (R7). Built now: the finger
  holds the rod whose centre is nearest, in its own disc's radius, where it lands, and that rod lights at once with a
  light tap, so the rod that lights is the rod that turns. Going back to the landing rule was Claude's call, for Jack to
  confirm on the phone. The log now records where each touch lands and the path each drag takes, so the next complaint
  about a pick can be checked against the finger.
- "I can't remember how far I've turned it." Claude's recommendation: while dragging, an arc from the start notch lights
  one segment per 30° step, with a signed count placed away from the finger; it stays faint while the move is still
  open, so a re-grab of the same rod carries on the count. It reports only the player's own turns, so it is not a hint.
  It was within one drag, and Jack likes the fix (2026-09-28). Built on `touch` (2026-09-29).
- The lines a turn draws were too heavy for pictures made of fine lines. On `touch` (2026-09-29) every line a turn draws
  over the picture became one 0.5 pt hairline, with no glow or dark band. The held knob lights inside its own footprint
  (its ticks and a ring on its dark band), and one hairline rings its disc, dimmer until letting go would commit. The
  count became fine graduation ticks on that hairline. Jack dropped the ticks the same day (R8): "too faint and thin".
  He liked the dashes and only wanted them less prominent. So the count is dashes again, 2 pt at 0.85 opacity, with no
  glow or dark band, over a hairline trace from the start to where the turn stands. The disc's hairline and its start
  mark stay: Jack asked for one thin line round the circle of influence. Open for Jack: a knob-only variant (no line
  round the disc) against this, though his ask for the line may settle it; and whether the hint's ring and the opening
  replay's ring, still heavy, should thin too.
- Some tank turns committed a step with no clunk. The phone's log confirmed the cause: all 107 silent tank turns were
  let go between 0.52 and 0.99 of a step. Letting go rounds to the nearest step, but the clunk fired only at whole
  steps. Fixed on `touch` (2026-09-29): a turn clicks each time what letting go would commit changes, at the half step
  either way, so every step a turn commits has had its clunk. The rod's tick moved to the half step too, so click, count
  and commit always agree. That was Claude's call, for Jack to confirm.
- Whirlpool 22 (pent, marbling) looked solved at moves 19 / par 18 with one 30° step left on the bottom-right rod. The
  win check was right: that step moves its worst point about 0.14 tank radii (about 80 phone pixels), but round ring
  motifs still look like rings after a turn. Pictures built from locally round motifs hide rotation; check this
  when the live pictures are reviewed.
- Maelstrom's first level (the placeholder with a seized knob on the phone): five minutes without finding that the
  tank turns. Jack: it needs to be clearer, even just an arrow, since turning the tank back is free. Claude's
  recommendation, queued: on any level with seized knobs, until the player has turned the tank once (a stored flag),
  an amber arrow sweeps along the rim with a ghost drag; touching a seized knob plays its thunk, shakes the knob and
  pulses the rim arrow, since that touch is the moment of confusion; maelstrom 1 gets a one-line note ("One knob has
  seized. Turn the tank."). It teaches the control, not the move, so it isn't a hint. Built on `touch` (2026-09-29),
  except the note: no committed maelstrom level has a seized knob yet, so the note, and a rewording of whirlpool 1's
  "This is the last note.", come with the new set. The arrow sits on black just outside the bezel at twelve, apart from
  the hint's. A two-finger twist whose first finger lands on a seized knob still thuds and shakes it: SwiftUI gives no
  touch count, so only the phone can say whether that grates.
- "Why are some locked and some aren't?" The phone's temporary table seizes knobs on only 17 of the 27 placeholder
  levels. Jack: every maelstrom level has seized knobs. The new set already does (one or two on each).
- From the phone's log (every tier open with the developer unlock): in 107 minutes the playtester solved all 81
  levels and one endless tank, with no hints, 20 of them over par, and no crash. The undo bank was already empty from
  earlier testing and never refills, so the whole evening was played with resets (87 of them). The
  hardest were whirlpool 22 (23 resets, about 9 minutes; one step from solved, the playtester left the app and reset on return),
  maelstrom 22 (17 resets, 54 tank turns), whirlpool 21 and maelstrom 21 (6 over par). Maelstrom 1 took 3 min 35 s,
  12 touches of the seized knob and 8 resets before the first tank turn. Maelstrom was the placeholder (whirlpool's
  scrambles with seized knobs), so a third of the levels repeated puzzles just solved. The log can't show
  losing count in a drag: quick re-grabs of one rod are too common to mean anything.

**Maelstrom set (proposed 2026-10-24; installed in `Levels.swift` on the branch `maelstrom-set`, not merged).** 27 new levels: quad M1–M6, pent M7–M14,
hex M15–M27, one or two seized knobs each, never the hub. None repeats a whirlpool or plughole scramble, or a level of
the two earlier tables, in any rotation or mirror image. Every row was checked with `scripts/solve.sh`: par is the
optimum and plain untwisting reaches it (no detour), and the park rule reaches par under all four readings and on
every tie branch, whichever way a tie goes. **Gap cw** is solve.sh's planning gap (no lookahead, ties clockwise);
**luckiest** is the same player with every tie going its way, so a gap there can't be won by guessing a direction.
**Wrong turn** is what that player loses when the first turn goes the worse way. **Plan** is the park rule's tank
turns, in steps (+ clockwise). M1 carries the note "One knob has seized. Turn the tank."

| Level | Layout | Seized | Depth | Par | Gap (cw / luckiest) | Wrong turn | Plan | Picture | Title | Scramble |
|---|---|---|---|---|---|---|---|---|---|---|
| M1 | quad | 1 | 3 | 4 | 0 / 0 | 1 | +1 | coral | Something has set. | `3:-4,2:+7,1:-8` |
| M2 | quad | 2 | 4 | 5 | 2 / 0 | 2 | -1 | neurons | The tank turns the other way too. | `0:-3,2:+4,1:+5,2:+8` |
| M3 | quad | 1 | 5 | 6 | 1 / 1 | 1 | +2 | coral | Park the dead knob where the work is done. | `1:+2,2:-5,1:-5,0:-6,1:+8` |
| M4 | quad | 0,3 | 5 | 6 | 1 / 1 | 1 | +2 | chainmail | Two knobs, one reason to turn. | `3:+2,0:+4,3:-5,0:+6,1:-8` |
| M5 | quad | 0,1 | 6 | 8 | 1 / 1 | 2 | -1, +2 | coral | A step back, then half round. | `1:+3,2:+3,1:-5,2:-7,3:-8,0:+2` |
| M6 | quad | 1,2 | 10 | 14 | 1 / 1 | 3 | -1, -1, -1, +2 | glass | Round in circles, on purpose. | `3:-2,0:+2,1:-5,2:+8,0:-2,3:+7,1:+2,0:-8,2:-2,1:-6` |
| M7 | pent | 1,4 | 9 | 10 | 1 / 1 | 2 | +2 | chainmail | Five rods. No half turns. | `1:+2,0:+4,1:+4,0:-7,1:+8,0:-6,1:+7,0:+8,1:+5` |
| M8 | pent | 2,3 | 6 | 7 | 2 / 2 | 2 | -2 | coral | The near turn is a trap. | `2:-2,1:+5,2:-7,1:+8,2:+5,3:-7` |
| M9 | pent | 0,4 | 8 | 10 | 2 / 2 | 3 | -1, +2 | marbling | Look two turns ahead. | `0:+4,2:-3,3:-3,1:-5,2:-7,3:-8,0:-4,4:+4` |
| M10 | pent | 0,1 | 10 | 12 | 2 / 2 | 4 | +1, +2 | neurons | Couette flow, interrupted. | `4:-2,0:-2,1:-4,0:-3,4:+4,2:+2,3:-6,2:+7,1:+8,3:-2` |
| M11 | pent | 3,4 | 14 | 17 | 2 / 2 | 4 | +1, +1, +2 | chainmail | Turn, turn, unstir. | `2:-2,3:+5,2:-7,1:+8,0:-2,4:+5,3:-6,4:-7,0:+8,1:+3,0:+6,4:-8,1:+3,2:+4` |
| M12 | pent | 2,3 | 14 | 17 | 2 / 2 | 4 | -1, -1, -2 | glass | Never park on wet paint. | `4:+2,3:+5,4:+8,0:+7,1:-8,2:+5,3:-6,2:+7,1:+8,0:-4,2:-4,1:-6,2:+8,1:-6` |
| M13 | pent | 3,4 | 20 | 24 | 2 / 2 | 4 | +1, -1, +1, +2 | marbling | Forward, back, forward, round. | `3:+2,4:+3,2:-2,3:+5,2:+6,1:-2,0:+4,4:+7,2:-2,1:+5,0:+8,1:-3,2:+5,4:-4,0:-4,4:+7,1:-7,0:-8,4:-3,2:-4` |
| M14 | pent | 0,1 | 18 | 22 | 2 / 2 | 5 | -1, -1, -1, +2 | glass | Two seized, five rods, no hurry. | `4:-3,0:-5,4:-2,3:+3,2:+6,1:-8,0:-5,1:-6,4:-3,2:-7,0:+6,3:+8,1:-8,0:-7,4:-3,0:+4,4:-3,3:+2` |
| M15 | hex | 1,5 | 10 | 11 | 2 / 2 | 2 | +3 | chainmail | The hub holds still. The rest go round. | `6:+4,5:-5,6:+7,1:-2,6:+3,5:-5,6:+6,5:+8,6:+6,1:+7` |
| M16 | hex | 2,3 | 10 | 11 | 3 / 3 | 3 | -2 | neurons | Seven rods, two sulking. | `3:-3,2:+5,3:-7,2:-8,6:-4,1:+5,0:+8,3:+4,5:+3,4:+5` |
| M17 | hex | 3,4 | 15 | 17 | 3 / 3 | 4 | +1, +3 | marbling | Lend it a step first. | `3:-2,0:+5,3:-8,2:-3,1:+4,3:+2,4:+3,0:-7,4:+8,3:+5,5:-2,6:+5,1:-7,0:+8,4:+8` |
| M18 | hex | 2,3 | 12 | 13 | 4 / 4 | 4 | -2 | neurons | Two stops past the obvious one. | `1:+3,0:+6,2:-8,1:-7,0:-8,3:-4,0:-7,1:+8,6:-4,0:+7,3:+8,4:+4` |
| M19 | hex | 3,4 | 15 | 17 | 4 / 4 | 5 | -1, +3 | chainmail | Spin-up takes a while. | `3:-2,4:-3,5:+4,0:-6,6:-2,0:+2,4:+3,3:-6,1:+2,6:+4,1:-6,2:+2,3:-2,6:-3,5:+3` |
| M20 | hex | 4,5 | 14 | 15 | 5 / 5 | 5 | +2 | glass | Commit to the turn. | `4:+2,0:+5,5:+6,6:-7,0:+8,1:+7,6:+8,4:-4,0:+2,1:+5,0:-6,5:+7,0:-8,4:+7` |
| M21 | hex | 1,2 | 18 | 20 | 5 / 5 | 6 | -1, -2 | marbling | The second turn is the one that counts. | `6:+2,1:+3,2:-6,3:+8,0:-4,1:-5,6:+7,0:+8,3:+7,0:+8,3:+4,5:-2,4:-5,0:-6,1:-8,6:+6,4:+2,3:+5` |
| M22 | hex | 1,6 | 24 | 27 | 5 / 5 | 6 | +1, +1, -2 | chainmail | Step, step, and back across. | `5:+4,4:+6,0:-8,4:-8,3:-6,2:-8,0:-2,4:-4,2:-3,0:+7,5:-8,1:+4,2:+2,1:+3,6:+8,1:-6,6:+8,0:+8,3:-5,4:-6,0:-7,1:-8,5:+4,4:-7` |
| M23 | hex | 1,2 | 18 | 20 | 6 / 6 | 7 | -1, +3 | glass | Rigid-body rotation, mostly. | `1:-2,2:+3,3:-4,0:-6,4:-8,0:-6,2:+7,0:-8,4:-6,0:-7,2:-8,5:-2,4:-4,5:-6,6:-7,1:+6,0:-7,6:-8` |
| M24 | hex | 4,5 | 24 | 27 | 6 / 6 | 7 | +1, -1, +3 | marbling | Taylor-Couette, by hand. | `3:-2,4:+4,6:-3,0:+6,5:-7,6:+6,0:+8,3:-4,4:+7,3:-8,4:+4,6:+4,0:+6,6:-7,0:+8,3:-8,4:+7,1:+4,2:+6,3:+8,0:-2,5:-4,6:-7,5:-8` |
| M25 | hex | 1,2 | 22 | 24 | 6 / 6 | 9 | -1, -2 | chainmail | No second chances. | `2:+4,1:+5,6:-3,2:+4,0:+6,2:+7,0:+8,3:-7,0:-6,1:-2,0:+4,1:-7,6:+7,3:+4,0:+8,3:+4,4:+6,5:-7,6:+7,1:+8,5:-2,4:+5` |
| M26 | hex | 4,5 | 24 | 26 | 7 / 7 | 8 | +1, -2 | marbling | The long way is the short way. | `1:+2,2:+2,3:-3,0:+3,4:-5,1:+4,0:+4,2:+4,1:+5,0:+5,4:-7,1:+4,0:+8,2:-6,4:+4,0:-2,4:+3,6:-4,1:+5,2:+7,1:-8,6:+7,5:+8,6:-4` |
| M27 | hex | 3,4 | 24 | 27 | 7 / 7 | 8 | -1, -2, -1 | glass | The maelstrom, unstirred. | `3:+4,0:+5,4:-7,5:+3,0:-4,6:+3,4:-3,0:+4,3:+7,0:+8,4:-6,0:+8,3:+2,0:+4,5:-7,6:-3,2:-3,0:-4,4:-6,6:+2,1:-3,2:-6,3:+5,0:+5` |

Jack's calls (2026-10-24), from a deck of films of each candidate played at par beside a player who doesn't plan:
- **The finale stays M27**, the three-turn level, over a two-turn one at gap 8.
- **M2 stays**: it punishes only a clockwise habit, the one M1 builds.
- **Lean into difficulty**: maelstrom is the last tier of free levels, where players should spend the most thought and
  feel the most achievement. Quad was cut from 8 levels to 6 (the first table's M6 and M7, a three- and a four-turn
  plan at gap 1, are gone), and hex gained two levels before the finale: M25 (gap 6, a wrong first turn costs 9, one
  route) and M26 (gap 7, one route).
- **The park rule has no tie-break.** Jack: a clockwise tie-break is unintuitive, since nothing says it should be so.
  The rule as a player would state it: take off the newest twist a working knob reaches; when none does, turn the
  tank the shortest way to where no dead knob sits over unfinished work; if two turns are equally short, either
  works. Every level here reaches par on every tie branch under both parkings, so this holds for the whole set, and
  it is the test for any later set (`Solver.park` still takes a `Tie` to name one play; fairness means `Solver.parkTies`'s worst is par under both parkings, which `testMaelstromIsFairAtPar` checks).

What the set can't have (from searches of up to 20,000 seeds a band, both random and plan-first, and an argument from
the park rule that the searches agree with):
- **The gap is flat on quad and pent.** Under a fair park rule a luckiest player who doesn't plan loses at most 1 on
  quad and 2 on pent, so those stretches climb only in plan length and wrong-turn cost. A gap above 2 needs a hex
  neighbour pair.
- **Spacing is mostly neighbours** (22 of 27). Two-apart pairs reach gap 1 on pent and 2 on hex, and opposite pairs on
  quad and hex always have gap 0.
- **The finale has 8 equal plans.** No level at gap 7 or more needs three turns and also has one route.
- **Par dips** at M14, M23 and M25, and each layout opens easier than the last one's showpiece.
- **Not measured:** whether a free stir turned straight back gives the plan away, and how the levels play. The titles
  are drafts.

The earlier tables, the search tool, the three designs the set was judged from and the films are on the local branch
`archive/scratch`, never pushed.

**Vortex (provisional, 2026-10-24).** Built on `vortex` (cut from `master` at dbc776a), merged 2026-10-25 (PR #22): the
swirl as a mechanic, the tier, the solver's handling of it, three ways for the rim to show what it does, and
27 provisional levels. Ported by reading the prototype (b6ed01c on `lab`), not cherry-picked.

Jack's calls (2026-10-24):
- The whole-tank swirl goes in the free game as the tier **vortex**, between whirlpool and maelstrom.
- "It should be visually apparent to the user before making a move whether the rim swirls or moves locked rods (or
  both - which we could definitely include)."
- "There are no users yet. There's nobody to grandfather in." No migration or grandfathering of any kind: vortex sits
  in the gate between whirlpool and maelstrom from the start.
- "Solver needs updating, yes."
- "Tank-sized stir is fine, but feel free to measure." Not measured: the simulator's GPU says nothing about the phone,
  so it waits for the performance pass.
- "Can you do the work on a local simulator? If so, do." All of it was, on a simulator of its own.

Jack's calls (2026-10-25, round 3 under "Jack's calls on the pitch"):
- **The rim cue: knob** (V1), over bands and glyphs.
- **The ticks: out** (V2, no option chosen): "I actually don't like the ticks at all as a method of showing the tank
  will swirl." The tick dial is ruled out as the swirl's cue, so a new cue was open. Round 4 (C1) chose breath;
  merged 2026-10-25 (PR #30).
- **Which layouts get a swirl** (V3): unanswered in round 3; round 4 answered all five.
- **The swirl with seized knobs: charybdis** (V4, option B): "The tank edge being dragged should always swirl the
  tank. It'd make the locked rods harder because turning the tank has a side effect. I feel strongly about this."
  See "The charybdis rule" under round 3, where one gesture, not two bands, is Claude's reading, which Jack confirmed
  in round 4 (R1).
- **The 27 levels: accepted as provisional** (V5).
- **Pictures: a family of its own** (V6, option C). Round 4 (P1): all three families, isobars, ephemeris and cords;
  merged 2026-10-25 (PR #28).
- **W3. The whole-tank swirl's map**: D, the swirl shears to the centre (plateau 0), knobs keep 0.6 (Jack,
  2026-10-25), chosen over keeping today's map (recommended) and over softer maps for every disc (0.3, 0.0), which
  blurred every seam. Built on `swirl-map`: `Tank.swirlPlateau`, picked by the disc's radius in `Tank.twist` and the
  shader.

**What is built.**
- **The swirl** (`Layout.swirls`: `triSwirl`, `quadSwirl`, `eyeSwirl`, `pentSwirl`, `hexSwirl`): the base layout's
  rods plus one last rod of radius exactly 1 at the centre, so the glass's edge never moves. It has no rigid core
  (`Tank.swirlPlateau`, 0, W3): its turn fades from the full angle at the centre to 0 at the edge. It merges like any
  rod, commutes with nothing but hex's hub (same centre), turns with the tank onto itself, and is never seized. Left
  out of `Layout.allCases`, so the frozen generator, the dailies and the sandbox never see it.
- **The grab.** Swirl only: from 0.93 of the radius out over the bezel to 25 pt beyond. Seized knobs only: unchanged.
  Both: the glass's own edge band (0.86 to 1.0) holds the swirl, the bezel and beyond turn the tank.
- **The tier.** Whirlpool all at par opens vortex; vortex all at par opens maelstrom. Ids `V1`–`V27`. Its own menu
  colours (violet to teal). Rows on a swirl layout read "4 rods + swirl".
- **The lesson.** A thin cyan arc at the bottom just inside the glass's edge, with a ghost finger there, until
  the first swirl stir commits (`Best.swirled`), beside the tank's amber one outside the bezel where knobs are seized:
  each points at its own ring (a cold review found both had pointed at the bezel). It hides while the swirl is held. A
  cold first touch where the rim does both (`film.sh rim-both-cold`) lands on the glass's edge and holds the swirl.
- **The solver.** It prunes by which rods' maps interact (`interacts`), so the hub and the swirl commute: hex's provisional
  level went from 2027 stacks in 2.2 s to 8 in 81 ms. `solve.sh` takes the swirl layouts and refuses a seized swirl.
  Every player's play on swirl levels, seized knobs included, empties a real `Game`. A randomised check (5398 swirl
  scrambles of 2–3 entries, half with a knob seized) found nothing shorter than the optimum.
- **What the rim does, before a move** (Jack's call above). Built first as three variants on `UNSTIR_RIM` (`knob`,
  `bands`, `glyphs`). Jack picked `knob` (V1) but ruled out its ticks (V2), then chose breath (C1, round 4). Merged
  2026-10-25 (PR #30), what ships:
  - **Breath**, the swirl's cue. 1.5 s after the tank becomes the player's, the swirl sloshes the picture once through
    its own map and settles: a 12° sine damped by e^-t over 3.2 s, so it peaks near 8° and ends at 0. It sloshes
    again every 12 s while the tank rests; after any lift the next slosh waits 10 s. It runs only until the player's
    first stir of the swirl commits (`Best.swirled`, which retires the swirl's lesson too), then never on any level
    (Jack's call, 2026-10-25; on `breath-once`, in review). A finger on the rim or a knob,
    two fingers or a drawn fingertip ends the rest, and the slosh fades out over 0.25 s from where it stood, under
    the live turn, so the picture never jumps (measured frame to frame in the `breath-grab` and `breath-grab-knob`
    films). The opening, a win and a reset end it the same way, and under Reduce Motion there is none. It is one
    extra entry on top of the shader's stack, drawn only while its angle is off 0, and it never touches `Game`. The
    picture's timeline runs only while a breath moves: on a static picture the simulator recorded no frames between
    sloshes. Shots `breath-01`, `-14`, `-21` and `-both`; films `breath-rest`, `breath-grab`, `breath-grab-knob`, all
    launched as a player who has never swirled, so the swirl's lesson shows beside the breath.
  - **The knurl** (`Knurl`, was `RimCues`), kept from `knob`: where knobs are seized the bezel is knurled steel, its
    ridges faintly amber at rest (the tank's colour), turning with the glass, on every seized level. It still says
    "turns the glass".
  - **Removed:** the swirl's ticks, pointer, ring and groove, so the trade-off against the hairline rule went with
    them; the `bands` and `glyphs` cues and `UNSTIR_RIM`; `UNSTIR_SEATS` and its shots. The `rim-knob-*` shots and
    films are now `rim-*`. The swirl lesson's arc keeps its dark stroke (open, below).
- **The swirl's own marks** (Claude's calls, 2026-10-25): a push flashes red as a 0.5 pt hairline 5 pt inside the
  glass's edge, where a knob's flashes on its own dial (`rim-swirl-push` film); over a red picture it is faint, the
  price of the hairline rule. A held swirl's dashes follow the knob rule since PR #30, 14 pt inside its disc (before,
  they kept clear of the ticks), and its count sits inside them on the far side from the finger, as a knob's sits off
  its disc (`rim-swirl-held`, `-held-low`, `-turned`). The result card's "next" is vortex's own blue (`Tier.glow`, the
  middle of the menu's violet → blue → teal walk; `vortex-result`).

**How the set was made.** `scripts/vortex-levels/pools.sh` deals seeded scrambles on each swirl layout with the frozen
generator (`Layout.scramble`, unchanged; the dailies never pass it a swirl layout), keeping only those whose optimum
equals their entry count and which plain untwisting reaches, one band per depth and hidden-stir budget;
`scripts/vortex-levels/pick.py` then takes, slot by slot, the lowest seed that meets the slot. Every row was then
checked with `scripts/solve.sh`: optimum = entries, no detour, planning gap 0 (`testVortexParIsTheOptimum`, slow, pins
it; `testVortexTable` pins the rest). Re-run under the swirl's own map (W3, 2026-10-25), the pipeline picked the same
27 seeds and scrambles, and every row still checks (optimum = untwisting = entries, the same hidden stirs, swirls, rods
over the newest and undo), and the swirl still commutes only with hex's hub (`testTheSwirlInteractsWithEveryRodButTheHub`).
Inferred, not checked: the generator and the solver judge stacks only by which entries cancel and commute, which the
profile leaves alone. Maelstrom's rules, translated:
- **Planning gap.** It doesn't apply: with no knob seized the tank never turns, so no lookahead is optimal and the gap is
  0 on every level. Vortex is a reading tier, like whirlpool, and climbs in depth, hidden stirs (`Layout.inversions`),
  swirls per level, hidden swirls and how many rods ride on the newest swirl.
- **First turns never more than two the same way** becomes the newest swirl's undo: never the same direction three
  levels running. And within a level, from four stirs on, no more than two thirds go one way, so undos can't be
  guessed by direction (the generator dealt one tri level all counterclockwise).
- **Fair under every park reading** holds trivially: no seized knobs, so both parkings untwist.
- **Neighbours never share a picture.** Vortex's own family since PR #28 (until then whirlpool's live pictures), nine
  levels each: V1–V3 one of each, isobars open each layout (V1, V7, V10, V14, V21) and take the finale, the ephemeris
  only to 14 stirs since it dims to a filigree at depth, cords the rest, mostly mid-depth. Each tank is four taps as
  dealt with its picture's `fillEntries`: every level fits with any of the three (deepest: 24 stirs + 6 = 30).
- **The swirl taught early on small tanks.** Quad first (V1 kept as it was, so its note and the rim shots stand), then
  tri and eye, then pent and hex, each layout opening easier than the last one's showpiece. A swirl of 240° (8 steps)
  is rare: none before V6, then at most a third of a level's swirls. No two levels open on the same three stirs.

Levels (**par** = entries = the solver's optimum; **hidden** counts the stirs no louder than what they covered, swirls among them in brackets; **swirls** lists their sizes in steps, newest first; **over the newest** is how many rods ride on the newest swirl; **its undo** is the direction that takes it off; **seed** is the band and seed that dealt it):

| Level | Layout | Par | Hidden (swirls) | Swirls, newest first | Over the newest | Its undo | Picture | Title | Why | Seed | Scramble |
|---|---|---|---|---|---|---|---|---|---|---|---|
| V1 | quad | 2 | 0 (0) | +4 | 0 | ccw | isobars | The rim is a rod too. | The lesson: the swirl alone on top (the placeholder's V1, kept, so the rim shots stand) | fixed #- | `0:+3,4:+4` |
| V2 | quad | 3 | 0 (0) | -7 | 1 | cw | ephemeris | Something stirred after the rim. | A rod stirred after the swirl: the rim isn't always first off | quadSwirl-3-0 #13 | `0:+4,4:-7,3:-8` |
| V3 | quad | 4 | 0 (0) | +4 | 3 | ccw | cords | The rim went first. | The swirl at the bottom: three rods ride on it, and it comes off last | quadSwirl-4-0 #17 | `4:+4,3:-5,2:-8,0:+2` |
| V4 | quad | 5 | 0 (0) | +7 +3 | 0 | ccw | ephemeris | Twice round the rim. | Two swirls, the newest on top | quadSwirl-5-0 #48 | `3:-2,4:+3,1:-5,0:+6,4:+7` |
| V5 | quad | 6 | 1 (1) | -4 -7 | 1 | cw | cords | Quiet at the edge. | The first hidden stir, and it is a swirl | quadSwirl-6-0 #25 | `0:-4,4:-7,1:+8,3:+3,4:-4,0:+5` |
| V6 | quad | 8 | 2 (1) | -2 -7 -4 | 0 | cw | ephemeris | Taylor turned the outer cylinder too. | Quad's showpiece: three swirls, two stirs hidden | quadSwirl-8-0 #148 | `4:-4,3:+6,4:-7,3:+8,1:+4,2:-8,0:-3,4:-2` |
| V7 | tri | 5 | 1 (0) | +6 -5 | 0 | ccw | isobars | Three rods, and the rim makes four. | Tri opens easier: every disc reaches the rim | triSwirl-5-0 #1 | `1:+4,3:-5,0:-8,1:-4,3:+6` |
| V8 | tri | 6 | 2 (1) | -5 -5 | 0 | cw | ephemeris | Every disc reaches the rim. | Two swirls of one size, one of them hidden | triSwirl-6-0 #145 | `2:-4,3:-5,2:-6,0:+8,2:+8,3:-5` |
| V9 | tri | 8 | 2 (2) | -6 -6 +2 | 0 | cw | cords | The rim carries every seam with it. | Tri's showpiece: three swirls, two hidden | triSwirl-8-0 #51 | `3:+2,2:+3,1:-6,0:+7,2:-8,3:-6,1:-8,3:-6` |
| V10 | eye | 7 | 2 (0) | +7 +4 | 2 | ccw | isobars | Big rods, small rods, one rim. | Eye opens easier, its swirl two deep | eyeSwirl-7-1 #35 | `0:-2,4:+4,2:+6,0:-4,4:+7,0:-8,2:-6` |
| V11 | eye | 8 | 2 (2) | -3 +6 +4 | 0 | cw | ephemeris | Free vortex, forced vortex. | Three swirls, two hidden, on mixed sizes | eyeSwirl-8-1 #7 | `0:-2,4:+4,2:+7,4:+6,0:+7,3:-8,2:-2,4:-3` |
| V12 | eye | 10 | 3 (2) | +5 +7 -4 | 1 | ccw | cords | Read the edge before the middle. | Ten stirs, three hidden | eyeSwirl-10-1 #127 | `3:-4,4:-4,1:+7,3:-8,2:-3,4:+7,0:+8,3:+4,4:+5,0:+6` |
| V13 | eye | 12 | 4 (2) | -5 -6 +8 +4 | 1 | cw | ephemeris | Small on big, inside the biggest. | Eye's showpiece: four swirls | eyeSwirl-12-1 #430 | `4:+4,1:+6,3:-7,4:+8,0:+5,2:-8,3:-2,1:-8,4:-6,1:-8,4:-5,2:+6` |
| V14 | pent | 8 | 2 (1) | +4 +4 | 3 | ccw | isobars | Five rods and a rim. Still no middle. | Pent opens easier, its swirl three deep | pentSwirl-8-2 #10 | `2:-3,5:+4,4:-5,3:-7,5:+4,4:-5,3:+4,4:-6` |
| V15 | pent | 10 | 3 (1) | +8 -5 -3 | 2 | ccw | ephemeris | Angular momentum, handed back. | Three swirls, the newest under two rods | pentSwirl-10-2 #96 | `3:+4,2:-7,1:+2,5:-3,4:+5,5:-5,4:+7,5:+8,3:-8,1:-2` |
| V16 | pent | 12 | 3 (1) | -8 -6 -2 | 3 | cw | cords | Under the rim, over the rim. | Three swirls, the newest under three rods | pentSwirl-12-2 #327 | `4:+2,0:-2,5:-2,4:+3,3:+5,0:-3,5:-6,0:+7,5:-8,4:-2,1:-2,3:+5` |
| V17 | pent | 13 | 4 (1) | +8 -4 +4 -3 | 2 | ccw | ephemeris | Kelvin would like his circulation back. | Four swirls | pentSwirl-13-3 #2 | `2:+3,5:-3,3:-2,0:-2,5:+4,1:-7,0:+3,5:-4,3:+6,2:-7,5:+8,3:-5,2:+7` |
| V18 | pent | 14 | 4 (2) | -4 -5 +8 -6 | 0 | cw | cords | Quiet at the edge, loud in the middle. | Four swirls, two hidden | pentSwirl-14-2 #716 | `2:+4,5:-6,3:+8,2:-8,0:-4,4:-5,5:+8,4:-4,5:-5,4:+8,2:-4,1:+7,2:-8,5:-4` |
| V19 | pent | 16 | 5 (1) | -8 +6 -4 -4 | 4 | cw | isobars | Ekman layers, politely ignored. | Four rods over the newest swirl | pentSwirl-16-4 #175 | `5:-4,3:-3,4:-3,2:+2,1:-2,5:-4,1:+6,2:-7,5:+6,4:+7,1:-2,5:-8,4:+8,2:+3,1:+4,2:+6` |
| V20 | pent | 18 | 6 (4) | +7 -8 +7 -3 +2 | 0 | ccw | cords | Rankine vortex, by hand. | Pent's showpiece: five swirls, four hidden | pentSwirl-18-4 #382 | `4:+2,0:-2,2:+2,4:+4,5:+2,2:-5,0:+2,5:-3,1:-6,5:+7,3:-8,1:-2,5:-8,4:-8,2:+4,1:-6,2:+8,5:+7` |
| V21 | hex | 12 | 3 (2) | -4 +4 +4 | 3 | cw | isobars | The hub and the rim keep out of each other's way. | Hex opens easier; the hub and the swirl come off in either order | hexSwirl-12-3 #136 | `7:+4,1:-7,7:+4,3:+5,5:+2,0:+2,6:+4,4:-2,7:-4,0:-6,3:-8,6:-3` |
| V22 | hex | 14 | 4 (2) | -8 -2 -5 | 2 | cw | ephemeris | Seven rods and a rim. Same rule. | Hex, three swirls | hexSwirl-14-3 #67 | `3:-3,2:+6,4:+2,7:-5,1:-8,7:-2,3:-5,1:-4,4:+7,0:+8,6:+7,7:-8,3:-2,1:-3` |
| V23 | hex | 16 | 4 (1) | +4 -6 -7 -7 | 1 | ccw | isobars | Bathtub vortex, either hemisphere. | Four swirls | hexSwirl-16-4 #54 | `1:+4,0:-5,7:-7,5:-8,2:-4,4:+3,3:+3,0:+6,7:-7,5:+8,4:-5,7:-6,3:+8,5:+2,7:+4,6:-5` |
| V24 | hex | 18 | 5 (3) | -4 +3 +2 -6 | 1 | cw | cords | Forced core, free edge. | Four swirls, three hidden | hexSwirl-18-3 #23 | `2:-4,6:+2,7:-6,5:+2,7:+2,2:+5,7:+3,6:-6,3:-3,4:+5,1:+7,3:-8,5:+2,6:-8,2:+8,4:-2,7:-4,2:+6` |
| V25 | hex | 20 | 6 (2) | +6 -5 -6 -8 -4 | 0 | ccw | isobars | Spin-down takes longer. | Five swirls | hexSwirl-20-4 #54 | `1:+4,6:-2,7:-4,3:-7,7:-8,5:+3,6:+5,0:+8,7:-6,5:+3,3:+3,7:-5,5:-8,2:+3,1:+5,2:+8,3:-7,1:+4,2:-8,7:+6` |
| V26 | hex | 22 | 7 (3) | -8 +7 -6 -3 +7 | 3 | cw | cords | Stir the stirrer. | Five swirls, three hidden | hexSwirl-22-6 #311 | `6:-4,3:-4,5:+5,0:+6,7:+7,5:+8,3:-2,6:-4,7:-3,1:-3,7:-6,6:+8,3:+2,7:+7,6:-8,4:+4,2:+3,3:+6,7:-8,0:-8,2:-3,5:-3` |
| V27 | hex | 24 | 8 (2) | +8 -4 -8 -3 -2 -6 | 1 | ccw | isobars | The vortex, unstirred. | The finale: 24 stirs, six swirls | hexSwirl-24-5 #375 | `4:+3,1:-2,7:-6,1:-3,7:-2,0:-4,2:+6,1:+4,6:+5,1:+7,0:-8,6:+4,7:-3,0:+6,5:-7,3:+3,7:-8,0:+6,1:+3,7:-4,1:-7,3:-3,7:+8,5:-8` |

**Swirl and seized knobs together: a separate proposal, not in the set.** Vortex has no seized knob: seizing is
maelstrom's lesson, and it comes after. Both together already work (the grab, both lessons, the `rim-both*` and `breath-both`
shots, and the solver's plays empty a real `Game` with a knob seized on every vortex level). Two options:
- **A. Maelstrom's last few levels add the swirl** (say M25–M27 on `hexSwirl`, the hub and a ring knob or two seized):
  the tier that teaches the tank's turn ends by combining it with vortex's control, which the player already knows.
  The swirl is a slot the tank turns onto itself, so it never parks and never seizes; whether it makes planning harder
  (it carries every seam round with it) or only longer needs the solver's gap measured on candidates.
- **B. Leave both for charybdis**, the tier past maelstrom, as its new skill.
Claude recommended **B for now**: maelstrom's set has just been rebuilt and playtested (PR #17), and A would reopen it
before vortex has had one playtest. **Jack's call (2026-10-25): B, charybdis**, with a rule: dragging the tank's edge
always swirls the tank. Claude's reading, which Jack confirmed in round 4 (R1), is that the "both" grab's two bands give way to one
gesture there (see "The charybdis rule" under round 3). A is set aside (R10).

**What the tier needs before it's final.**
- **Jack's playtest** of the 27 levels on the phone; the titles are drafts.
- **Its picture family.** Built and merged 2026-10-25 (PR #28): isobars, ephemeris and cords (Jack, V6 and P1), in
  the table above. Jack's calls on it (2026-10-25):
  - **Which levels get which picture**: Jack kept Claude's interleaved split (2026-10-25, K3: A). Isobars V1, V7, V10, V14, V19,
    V21, V23, V25, V27 (2–24 stirs); ephemeris V2, V4, V6, V8, V11, V13, V15, V17, V22 (3–14 stirs); cords V3, V5,
    V9, V12, V16, V18, V20, V24, V26 (4–22 stirs). The rule: nine each, no two neighbours alike, V1–V3 one of each,
    isobars open each layout and take the finale (Jack's favourite solved, and the cheapest to draw, 2 entries), the
    ephemeris only to 14 stirs (it dims to a filigree at depth; `testVortexTable` enforces it), cords the rest (they
    go grey-brown at depth). A small search picked the table that keeps the ephemeris, then cords, as shallow as
    those rules allow. Shots `vortex-family-*`, laid out by `scripts/vortex-family-sheet.py`.
  - **The sandbox's picture cycle takes vortex's family** (Jack's call, 2026-10-25): `Picture.next` runs plughole's
    three, whirlpool's five, then isobars, ephemeris and cords, and skips only the twins. On `breath-once`, in review.
  Not a call: the ephemeris's orbits may overlap the orbit pictures planned for charybdis.
- **Its sound bed** (built 2026-10-27 on `sound-r2`; Jack kept it, SN1 = A, 2026-10-28).
- **The rim's swirl cue** (above): breath (C1), built and merged 2026-10-25 (PR #30). Jack's calls on what the PR left
  open (2026-10-25):
  - **Breath stops once the swirl is used.** Jack: "I don't think it does need to move after the first move is made -
    if the player has already seen the tank slosh and made their move swirling the whole tank, they understand the
    mechanic." It runs only until the player's first committed stir of the swirl, the moment and the stored flag
    (`Best.swirled`) that retire the swirl's lesson, and no level breathes after it (`Game.breathes`,
    `testBreathStopsOnceTheSwirlIsUsed`). On `breath-once`, in review.
  - **The wait after a move stays 10 s** (Jack's call, 2026-10-25). The first slosh of a level comes 1.5 s after the
    tank is the player's; after any lift the next waits 10 s, then one every 12 s, so a move is never answered by a
    slosh.
  - **The slosh peaks near 8°, not 12°**, which Jack kept (2026-10-25, K2: A). Jack's answer to C1 said 12°; the
    pitch's film used the same curve (12° damped by e^-t), so the 8° peak (8.3°, checked) is what he saw. An amplitude
    of about 17.3° would give a true 12° peak.
  - **The four defaults stay as built** (Jack, 2026-10-25, K4: A):
    - **Reduce Motion means no breath at all**, as the menu drops its stir under Reduce Motion. Until the first swirl,
      the swirl's lesson arc still names the control.
    - **The swirl's lesson arc keeps its dark stroke** (V2 was never answered before).
    - **The swirl's count dashes follow the knob rule**, 14 pt inside the disc, where before they kept clear of the
      ticks.
    - **An undo doesn't restart the rest**: the breath carries on over the changed stack.
- ~~**Tri and eye** (V3)~~: answered in round 4, a swirl on all five layouts, the 27 levels as built.
- **Known gap**: a sandbox launched on a swirl layout through `UNSTIR_LAYOUT` crashes on the layout button (harness
  only).
- **Not measured**: the tank-sized stir's GPU cost on the phone (performance pass), narrow phones (everything was shot on
  a Pro Max), and whether the free probe (a stir turned straight back) gives a swirl level away.

**Recommended Nightmare+ (chosen 2026-09-28): the seized rod and the turning tank.** N+k is Nightmare k's scramble with one
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

**Measured (2026-11-03, the 13 Pro Max, local `duo-feel`).** A four-tap entry costs 0.2714 ms at 1137 px, 0.3426 at
1284 and 0.4466 at 1471: 29.4 entries a 120 Hz frame at 1137 px, 16.9 at 1471. A transform between the `Unstirred`
layer effect and its clip runs the shader over its whole `maxSampleOffset` region, about 7 times the cost: keep the
circle clip directly on the effect. #140 (off, `ADAPTIVE_TAPS = NO`) steps the four-tap budget down and up to hold 120
Hz, the look only, never the stack's depth; whirlpool 27 sits over today's limit (wp27-table). Details under Round
16's build.

**Claude's view.** Cleverness costs maintainability, and the architecture pass comes straight after. Keep each trick in
one place with its reason stated, and drop any that doesn't pay on the phone.
