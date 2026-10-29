# Handoff — Unstir

*Updated 2026-10-29. Audience: the next agent, or Jack. This file holds the current task: the plan, where it stands,
open thoughts, and the options set aside. Update it when a step closes or a call is made. Git holds the history. The repo is public: personal and account
details go in `HANDOFF.private.md`, which is gitignored.*

## The current task: take Unstir to market

Find out whether the game is worth releasing commercially, and if it is, how to price it and get it noticed. The store,
the share line, the privacy manifest and TestFlight prep are merged (2026-10-25); the packs' content is not built.

### Where things stand

| Item | State |
|---|---|
| Competitor scan | Done 2026-09-28, quick pass (see below) |
| Business-model recommendation | Jack ruled out paying to unlock tiers (2026-09-28). Jack wants **picture packs with their own tanks** as paid content, best with new mechanics; an archive of past dailies, a supporter mark and a tip jar are agreed (2026-09-28). Undos are never part of the paid side: free for everyone at +2 per playing day (see "Thoughts"). Packs stay outside the ladder and never open a tier. Rewarded ads for an undo top-up stay in reserve, only if TestFlight shows banks running dry. A single "Unstir+" purchase may not be needed. Options compared 2026-10-24 (below): Claude recommended one "Unstir+" purchase (the daily archive, endless past a free taste, the supporter mark) as 1.0's product, with packs from 1.1. **Jack's call (2026-10-24): packs ship at v1; there is no hurry to market** ("I think we can handle making packs for v1. I'm not in a major hurry to get it to market."). That supersedes the Unstir+ recommendation. Jack's calls on the pack catalogue (2026-10-24, below): **v1 ships First Stir, Lens and Escapement**; Claude draws First Stir's art; packs at one price beside a Complete bundle, no Unstir+, endless wholly free, no tip jar, no offer codes; Orrery's orbits become charybdis, a free tier; **The Well is cut**. The catalogue is now First Stir, Lens, Escapement, Prism and Music Box (only if it passes its ear test) |
| Monetisation code | StoreKit 2 for the packs and Complete merged 2026-10-25 (PR #21); the daily share line merged 2026-10-25 (PR #24). Prices are Jack's call (2026-10-25): 2.99 a pack, 5.99 Complete. No ads |
| Undo bank | Starts at 10 (`Best.undos` in `Sources/Levels.swift`). Jack's call (2026-09-28): everyone gets +2 for each day they play, so a long absence doesn't refill it; Claude assumes the cap stays 10. Built on `help` (2026-09-29, `Best.refill`; merged 2026-09-29, PR #9): the first opening of a level other than the sandbox on a local calendar day later than the last refill's adds 2, up to 10, and a "+2" shows over the undo count once the level's opening ends or is skipped. A fresh install records its first day without a refill; a clock moved back never refills. Jack (2026-09-29): setting the phone's date mustn't game the refill. Closed on `help` (2026-09-29, `Best.trustedNow`): within one boot the day comes from the last time it vouched for plus the uptime since (`CLOCK_MONOTONIC_RAW`, which counts sleep and can't be set), so a clock set ahead refills nothing until real time reaches the next day, give or take 5 min, and the log says `undo refill held: clock ahead Xh`. The anchor follows the wall clock no further ahead than drift explains (a second plus 100 ppm of the uptime since), so creeping the clock ahead a few minutes at a time gains about a second an opening; review found the first version let each step under 5 min carry the anchor along, a day ahead in about 290 steps (fixed 2026-09-29). Still open: a restart between date changes still borrows a refill, since a new boot has nothing to check against. A trusted network clock would close that; Claude recommends against it (a server, and a refill that waits on the network, to guard 2 undos a day). Unverified whether it is the only way: `kern.monotonicclock` is a candidate, a clock XNU's `clock.c` says nothing can set, and on a Mac it runs on across restarts. Unchecked on iOS: whether the app may read it, and whether setting the date moves it. The launch logs it next to the uptime (`monotonic clock Ns` or `unread`), so launches either side of a restart and of a date change answer both; if it holds, reckoning from it would close the restart hole. Unverified: whether iOS lets the app read the boot session (`kern.bootsessionuuid`); an app in macOS's App Sandbox reads it, but `container.sb` leaves it off its sysctl allow list, and iOS's profile is unpublished. The phone's log answers it at launch (`boot session read` or `unread`). Unread, a jump of at least the phone's uptime at the last level opened passes as a possible restart, and a believed jump anchors at the uptime then; so on a phone up less than a day, as after any restart, steps of a day get through one after another until a level opens with the phone up longer than the step. A genuine forward correction of more than 5 min within a boot (a phone that ran slow, set right) is held too, so its refill day turns late by that much until the next restart; one under 5 min is believed, and the anchor takes it in a few seconds a day. A new boot whose clock reads more than 5 min before the anchor's time, as after a clock reset, is believed but leaves the anchor, so setting the clock right later in that boot still counts as a new boot (review found the first version held every refill until the next restart there; fixed 2026-09-29). Not covered: a clock behind at the first opening with no anchor stored (a fresh install, or the first on this build), then set right, makes refills late by that much until a restart. The privacy manifest is written (`Sources/PrivacyInfo.xcprivacy`, merged 2026-10-25, PR #20): UserDefaults with CA92.1 and system boot time with 35F9.1. Apple's required-reason pages (developer.apple.com, "Describing use of required reason API" and the `NSPrivacyAccessedAPIType` page, read 2026-10-25) list `systemUptime` and `mach_absolute_time()` under boot time and no `clock_gettime`-family call or sysctl, so `clock_gettime_nsec_np`, `kern.bootsessionuuid` and `kern.monotonicclock_usecs` are not on the list; 35F9.1 is declared anyway, inferred as harmless and as the nearest fit, since the uptime clock measures elapsed time and never leaves the device |
| TestFlight | Prep merged 2026-10-25 (PR #23): version 1.0 (1), the export-compliance key, an asset catalog. The icon is candidate 1, the neon grid (Jack, 2026-10-25), already the placeholder in the catalog. No archive script until Jack's developer account is in Xcode |
| CI | Tests every pull request (merged 2026-09-28). First run 4 min 37 s, close to the 5-minute line. `scripts/ci-usage.sh` reports spend. CodeQL (`codeql.yml`, replacing GitHub's default setup, which never built) scans the workflows on every PR, and Swift on merges to `master` and weekly (Jack, 2026-09-28): the Swift build takes about 17.5 min under CodeQL. Free, since the repo is public; if it ever goes private, each Swift scan costs about 190 of the 2,000 minutes. So every PR's CodeQL check reads "1 configuration not found" (master has a Swift scan, a PR doesn't): expected, and it blocks nothing. `actions/checkout` is on v7, since v4's Node 20 is deprecated. Over the line since: #21 ran 5m44s, #23 5m36s and #26 5m11s. Jack's calls (2026-10-25): watch it, then cache the build, and the line moves to 7 minutes. The cache merged 2026-10-25 (PR #29): `test.yml` keeps the StoreKit test build (`build/store`) between runs, keyed on the Xcode build and the sources, and stamps each file with a time drawn from its content, so a hit compiles nothing. It saves about 30 s, but the build is not where CI's time goes: the job ran 5m13s cold and 5m18s warm, as the simulator's boot, install and tests vary by about 90 s from run to run. A warm-up build on each merge to `master` (PR #31) was closed on Jack's call (2026-10-25, round 6): the compile runs inside the simulator's boot, so it saves nothing. Jack's call CI1 = A (2026-10-28, round 10): keep and watch, noting each run's time; if two runs in a row pass 7 minutes, build the split (the core tests on PRs, the StoreKit tests and the long pack suites nightly on `master`; a break could show a night late)). **Fired and built (2026-10-29, PR #63):** runs of 7:14, 7:37, 7:59, 8:04 and 9:12 passed 7 minutes. Measured on #63's first run: `testNoVignetteShowsTheNextMove` 129 s, `StoreTests` about 72 s, everything else under 20 s a suite. PRs now skip `StoreTests` and `FirstStirTests`; `nightly.yml` runs all tests but the `UNSTIR_SLOW_TESTS` ones on `master` (they ran past 25 minutes on the runner, so they stay local); PR run 9:12 to 5:12 |
| `master` ruleset | Jack turned off "require code scanning results" and "require code quality results" to unblock PR #2. Claude's view: with Swift scanned only after merges, requiring code scanning on PRs would gate only the workflow files, so leave it off until the server code exists, then scan that on every PR and require it; leave code quality off, as its run fails on GitHub's side ("requested model is not supported") and whether it covers Swift is unchecked. Revisit it with the server code |
| Difficulty tiers | Backgrounds merged 2026-09-28 (PR #2). Jack chose the turning tank for the top tier, new levels for it, a renamed ladder and an easier switch (2026-09-28); the first slice, the turning tank and seized knobs, merged 2026-09-28 (PR #4); see "Side task" below; vortex, the swirl tier between whirlpool and maelstrom (Jack, 2026-10-24), with 27 provisional levels, merged 2026-10-25 (PR #22); Jack's calls on it (2026-10-25) are in "Vortex (provisional, 2026-10-24)"; vortex's own pictures (isobars, ephemeris, cords) merged 2026-10-25 (PR #28), and breath as the swirl's cue merged 2026-10-25 (PR #30); the swirl shears to its centre (W3, Jack 2026-10-25), on `swirl-map` |
| Performance pass | Queued after the difficulty tiers (Jack, 2026-09-28); see below |
| Architecture pass | Queued after the performance pass (Jack, 2026-09-28); see below |
| Media out of git | Done 2026-09-28: history rewritten, re-signed and force-pushed; `.git` went from 311 MB to 264 KB; see below |
| README | Merged 2026-09-28 (PR #3), with the four suggested images (Jack's pick); the rename updated it to plughole, whirlpool and maelstrom (PR #7); see below |
| Copyright headers | Decided (Jack, 2026-09-28): every code file names Jack in full as the copyright holder, 2026. His name is public already (the commit email's domain). Merged 2026-09-28 (PR #3); see below |
| Sound | Jack wants a bespoke soundscape, music and effects (2026-09-28). Tools agreed (Jack, 2026-09-28): everything synthesized from scratch in Csound (Homebrew), with no samples or stock loops; MuseScore 4 only if a written tune is wanted later, with a Muse Sounds Pro licence if its audio ships; GarageBand has no scripting and Audacity adds nothing. Claude can't hear, so Jack listens at the end of every round. Two sketches (Python): "glass and water" and "neon hum". Jack played both on the phone in a prototype (branch `sound`, uncommitted) and chose **glass** (2026-09-28), asking for quieter effects against the music, neon's low synth hum brought in, music on the menu, and a sound for every button. Round 2 is built (2026-09-29): Csound sources in `sound-src/`, rendered and measured by `scripts/sounds.sh`; a detuned saw hum in D under every bed; a heal about 8 LU over its bed (the phone-speaker model says 10–12); beds for the menu and each tier, crossfading over 1.5 s between screens and stepping aside while another app plays music; tap, tier-switch, undo and reset sounds. Round 2 on today's game (2026-10-27, branch `sound-r2`, PR #56): `sound` merged with master and passing every test; the heal's note now counts moves that pop one of the scramble's entries, as endless's brim does; vortex has its own bed (open fifths and a ninth, high sparse pings, water circling three times a loop); every button added since September taps (the consent card, the settings sheet, the pack cards, the dock, the tier-up); a push that fills the brim sounds only as the spill. Jack's call (2026-10-28, SN1 = A): "In, with early undo and step-back heals. Keep the vortex bed." So the undo is the early one (its body peaks about 0.2 s after the press, against September's 0.5 s), an undo steps the heal notes back, and the vortex bed stays; the three temporary switches under the menu's list (`sound`, `undo`, `heal undo`) and the first sketch (`sound-src/sketch.py`, `scripts/sounds.sh sketch`) are gone, applied on PR #56. `scripts/sounds.sh listen <dir>` writes every sound and bed to m4a for a listen off the phone. The sounds add about 9 MB of CAF and AAC to git (rendered from `sound-src/`, so they could be rendered at build time instead, at the cost of Csound in CI). Endless has no par now, so the old question of a solve one over par is gone. Also for Jack, smaller: the detent's tick sounds during a drag (it echoes the haptic and the dashes; the rule as written says nothing sounds then), so keep it or drop it; in the free tiers cancelling the player's own push still shows the magenta ring and heavy tap but no longer plays a heal, so the ring could follow endless's rule too; a purchase landing plays nothing (the buy buttons tap). The share links tap through a simultaneous gesture, unheard and untapped on a device. Rule: a sound never tells the player anything the picture doesn't, so nothing sounds during a drag and a heal's pitch follows heals done, never heals left. Claude recommends building it in after the new level set and before TestFlight; not decided |
| Merged 2026-10-28 and 29 | PRs #55 (the consent link opens and closes its list), #57 (a locked next tier's up-a-notch button opens its gate), #53 (Lens, lenses on rods of every size) and #58 (drag guard) on 2026-10-28; #50 (plughole eased), #56 (sound round 2), #51 (live pack clips), #54 (First Stir's 25 scenes, FS17 C), #60 (v1 without First Stir) and #52 (Escapement's book, the tick budget and the flip counter) on 2026-10-29. Jack's calls on them are in rounds 10 and 11 under "Jack's calls on the pitch" |
| Open PRs and branches (2026-10-29) | `esc-hub-flaps` (ES2 = B: each clock's own flip count in its hub, the header their sum; Claude merges it once CI passes); the book still waits on Jack's play on the phone. Prism: #59 (the prototype), #67 (the 30 specimens, five plates), #68 (colour-blind reading), #69 (the GPU bench) and the ship PR merged 2026-10-29; Prism is on the Release shelf. PR #60 `v1-without-firststir` (v1 without First Stir, FS17 C). Local, no PR: `v1-no-analytics` and `keep-analytics` (the two sides of AN1), `store-page` (ST1 to ST7 = A, two drafts of the privacy policy) |
| Round 12 (decided, 2026-10-29) | AN1 = A (v1 ships with no analytics), EU1 = B (no EU storefronts at launch; revisit when sales cover a business address), PK1 = A (Prism replaces First Stir as the third pack, capped at depth 8), ES2 = B (each hub shows its own flip clock, plus a total counter elsewhere; a hub that reaches 0 shows plainly that it has run out; built on `esc-hub-flaps`). See round 12 under "Jack's calls on the pitch" |
| Apple Developer membership | See `HANDOFF.private.md` |

2026-10-25 overnight: built for Jack. Six PRs (#19 to #24), three prototypes (`lab-firststir`, `lab-lens`, `lab-escapement`, local) and the shelf mock-ups (`shelf-mockups`, local), each recorded against its item under "To do" in "Packs: the catalogue". Also PR #23, outside the list: TestFlight prep (version 1.0 (1), the export-compliance key, an asset catalog with a placeholder icon, three icon candidates; recommended: 3, the whole-tank swirl; no archive script until Jack's developer account is in Xcode). A trial merge of #19 to #24 in number order onto `master` passes all 146 tests; the conflicts are mechanical (CLAUDE.md prose, harness lines, shot lines, the generated project file). All seven PRs (#15, #19 to #24) are merged into `master` (2026-10-25). Jack answered the review page on 2026-10-25: see round 3 under "Jack's calls on the pitch".

### The plan

1. **TestFlight with 20–50 strangers.** Watch whether they get the goal without help, where they get stuck, and
   whether they come back for the daily. Day-2 return is the number to watch.
2. **A share line for the daily result**, Wordle style (e.g. `Unstir #142 · 7 moves (par 6)`). The daily generator
   already exists. Built on `daily-share` (2026-10-25, `Sources/Share.swift`): a share button on the daily's card, a
   square per move in its flash's colour, practice named as such, no URL yet (`Share.url`). Merged 2026-10-25 (PR #24).
   Jack's call (2026-10-25): daily #1 is launch day. Until `Share.firstDay` is set, the line shows the date instead of
   a number.
3. **3–5 short clips** of a picture snapping back, recorded with `scripts/film.sh`, posted to TikTok, Reels and Shorts.
   See whether anyone cares before spending money.
4. **Choose the model from what testers do**, then set up the App Store page, preview video and a featuring request.

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
| LG3. The rest of the legal work, required either way | **No answer.** Jack objected to the UK data-protection registration fee. To come back to him |

Round 12 (decided, 2026-10-29). Jack's words are kept in `HANDOFF.private.md`.

| Call | Decision |
|---|---|
| AN1. Analytics in v1 | **A:** none. v1 ships through `v1-no-analytics` (App Store Connect's numbers only); `keep-analytics` holds the other side, for an update. Every analytics item in the to-dos and in the launch checklist below is moot for v1 |
| EU1. Selling in the EU at launch | **B:** no EU or EEA storefronts at launch. Revisit if sales cover the cost of a business address for the trader details the Digital Services Act asks of an EU seller (no vendor names or prices in tracked files) |
| PK1. Prism as First Stir's replacement | **A:** Prism, capped at depth 8, since depth 9 reads too busy. Built and on the Release shelf (PRs #59, #67, #68, #69 and the ship PR, 2026-10-29); Jack's play of the specimens and the phone bench remain |
| ES2. Escapement's budget display | **B:** the flip-clock numbers also show in each hub, and a total counter elsewhere; the numbers must never contradict each other, and a hub at 0 must show clearly that it has run out. Jack's words: "just don't let the numbers contradict each other? they should render as flip-clock numbers in the hubs too. and when the hubs reach 0, it should show clearly that they've run out (e.g. greying out the hub/escapement, or what you already built to show it, or something else)", and "i want the flip clocks for each hub in that hub, plus a counter for the total elsewhere." Built on `esc-hub-flaps` (2026-10-29), the rule Claude settled under the note: each clock's count is what it owed as dealt, each of its ticks takes one off it, a pushed tick too; the header is the hubs' sum after every tick; a clock at 0 stops ticking and greys (wheel, sub-dial, card, dashed disc) as its last tick lands, with the amber stop ring; out of ticks once no clock can tick with twists left. On a clean line each count reaches 0 as its rod empties, so the book stands. Each hub is a one-digit split-flap card (no clock owes more than 9) |

**Launch checklist** (App Store Connect and the rest; to be extended)

- In App Store Connect's availability, exclude the EU and EEA storefronts (EU1 = B).
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
- **Game Center and a web domain.** Neither at v1; a domain comes with sharing and Music Box's Composer links.
- **Languages at v1.** English only, with every string in a String Catalog from the first pack (captions, the shelf
  and pack cards, Escapement's stipulations, purchase text), so a language is a translation job. Store metadata in
  English on every storefront.
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

#### To do

1. Record in HANDOFF.md (the main session, not this worktree): the roster, the ladder reservation, this to-do, the
   open calls with their recommendations, and the 17 benched entries under Set aside with their reasons; mark option
   C's "no packs at 1.0" superseded by Jack's call of 2026-10-24.
2. ~~Jack's calls on decisions 1 to 4.~~ Answered (Jack's calls on the pitch); the defaults he hasn't objected to stand.
3. Settle pack names, level-id prefixes and product ids together, before anything is created in App Store Connect.
   Settled 2026-10-25 by Jack's yes to the defaults. Pinned by tests on PR #21: product ids
   `com.screendead.Unstir.pack.firststir|lens|escapement` and `com.screendead.Unstir.complete`; level ids `first-
   stir-N`, `lens-N`, `escapement-N`. Merged 2026-10-25 (PR #21).
4. First Stir go/no-go first, since its art is the long pole: one harbour scene with three vignettes drawn in code,
   filmed and cold-read. Each heal must read as time stepping back, not the stir changing.
   Built 2026-10-25; Jack has called it (round 3, F1 and F2, below): lab branch `lab-firststir` (local), a harbour scene on tri with three code-
   drawn vignettes. Claude's verdict: go with changes; the art carries it. The cold read fixed a heal order whose
   vignette was smeared by a neighbour's shear ring, which gives a new rule: a vignette plays only after the rods
   whose discs overlap it are healed. Then open: whether heals read as time stepping back or as repair (answered by F2 below),
   and whether the opening shows the wrecked harbour.
   Jack's calls (2026-10-25): go (F1); make time visible, the night winding back (`UNSTIR_FSTIME` on `lab-firststir`),
   plus the caption (F2). Jack's call (2026-10-25, round 6): the opening shows the wrecked harbour, as built.
   Ported 2026-10-26 to `firststir-pack` as First Stir's level 1 (to-do 40), the night winding back by default.
5. First Stir's story outline (25 scenes and their vignettes) for Jack's approval, then Claude draws all 25 scenes
   (Jack's call 3, no illustrator) to an art spec: single-weight neon line, the chapter palettes, up readable in every
   lit core, each figure change inside its own rod's core.
   Written 2026-10-25 on `firststir-outline`: `docs/first-stir-outline.md` holds the story (one night
   told backwards, dawn to the teacup), the five chapters with their palettes and time windows, 25 scenes of three
   vignettes each (layout, rods, held back and played, heal order), the art spec, and eight open points with Claude's
   recommendations (approve the story; three vignettes a scene; the night tiled across the pack; the time alone as the
   caption; a plain heal steps the time back; the lab's light rule; the lab harbour as scenes 16 and 1; the end film
   from the baked states). `scripts/first-stir-compositions.py` draws composition plans for scenes 1, 12 and 14. Left:
   Jack's answers, then the art and scrambles (43).
   Jack's calls (2026-10-26, round 9), recorded in the outline under each open point (PR #41):
   - *FS = A:* the story approved as written; the art for all 25 pictures starts next.
   - *F1 = A:* three changes (vignettes) per picture, 75 in the pack, 150 drawings (point 2).
   - *F2 = A:* one night across the pack, each picture about half an hour, the sky carrying on from one to the next
     (point 3).
   - *F3 = A:* a clock, a time under the tank like "4:10 am" that steps back every time the player undoes a twist
     (point 4). The outline had the time under the title; Jack's question put it under the tank, so it goes there.
   - *F4 = A:* each change inside its own core, checked by a test over every picture; level 1's boat stern and lamp
     shards, which break it, are redrawn in the art pass (point 6).
   - *F5 = A:* the lab harbour twice, as picture 16 (midnight) and its dawn view as picture 1 (point 7).
   Still open: point 5 (whether a heal with no vignette also steps the sky and rain back, beyond F3's clock) and point
   8 (the night forwards film). Left: the art and scrambles (43).
6. Lens go/no-go: port the lab zoom onto a halftone test picture, film ±1 to ±3 steps on the phone and set the rate
   (1.2, or 1.25 to 1.33 if one step doesn't read); film a zoom seam over and under a twist seam and cold-read which
   is newest; compare shrunk cores against a supersampled reference for glitter, since zoom isn't area-preserving.
   Built 2026-10-25; Jack has called it (round 3, L1, below): no-go as designed. The soft zoom leaves no seam, so the newest stir can't
   be read, and shrinking reads as moire. A hard-edged lens (magnify only, x1.3, capped at +3, a rim inside the
   core) is on `lab-lens`: the order reads partly (a whole rim means the lens is newest), and the magnified area
   drops to 36% of the disc. Jack's call (2026-10-25, L1): the hard lens, with a phone test next. The reviewers had
   recommended shelving it; trying it is Jack's choice.
   Phone test planned 2026-10-25 (`docs/lens-design.md` section 3, branch `lens-design`): count, order on tri, quad
   and pent, the two lab levels, the rim band at +3 and +5, with a go/no-go. Not yet run: it needs Jack and the phone.
   The rim break is computed weak on quad and pent (1.7 and 1.1 dot pitches for a 1-step twist, against 6.2 on tri),
   which the test checks.
   First phone session (2026-10-26, played, not the stills): Jack played hard lens 2 (quad) and found the lens rods
   too small to make out their rims, so the order was very hard to read. His calls from it, built on `lab-lens`
   (65c049b): a lens follows the finger up and down instead of turning, up zooming in ("way better"), and x2 a step,
   good after x1.6. He suggested lenses only on big rods, or bigger steps, as two ways out; which one is open (eye's
   two big rods as lenses, radius 0.58, are `eyeZoom`, lab entry `lens-hard-3`, where he judged x2). Not yet checked at x2: glitter in the rim band at +2 and +3, and whether the order
   reads on eye's lenses. The count and order stills were not run. These change the draft's table (tri and quad
   rows), its x1.3 and its "clockwise in", and the lens-pack PR's port.
   Jack's call (2026-10-26, round 9, L1 = A): the phone test before any of Lens's art is drawn; the story and levels
   wait for its result. The session above is its first part. `docs/lens-design.md` now opens with what the session
   decided and which parts of the draft it supersedes (PR #42); the table itself is not redone.
   The hard lens is built for real on `lens-pack` (PR #45, merged 2026-10-27), with `lens-1` to `lens-3` (the draft's
   taste, tri) to play, each card's "next" going on to the next. The phone session's two calls are ported there
   (round 9, 2026-10-26): the drag up and down (0.15 tank units a step, up a positive step, which magnifies, so the
   dealt lenses still magnify and are undone dragging down) and x2 a step. Lenses on big rods only is still open, so
   the three levels keep tri and rod 0. At x2 the deal's cap of +3 is x8 at the centre, and just inside the rim a
   step squashes by 2^-2, so +3 there is 1/64 of the screen's pitch, against 0.21 at x1.3: the glitter check at +2 and
   +3 matters more. The shelf shows no Lens cover in Release until the pack has levels past its taste (S1), so it is
   still a Debug install (`scripts/run-ios.sh Debug`), then
   `xcrun devicectl device process launch --device "$UNSTIR_DEVICE" --terminate-existing --environment-variables
   '{"UNSTIR_PACK":"lens","UNSTIR_LEVEL":"1","UNSTIR_OPEN":"1","UNSTIR_UNLOCK":"1"}' com.screendead.Unstir`
   (`UNSTIR_UNLOCK` keeps the phone's developer unlock, which any other harness variable clears; the flag's name is
   unchecked against this Xcode's `devicectl`). The first launch bakes the halftone, unoptimised, for 20 s or more;
   later ones read it from Caches. The phone test itself has not been run.
   Built 2026-10-27 (round 10, for Jack's call on lens sizes; not merged, nothing decided): a lens's drag now counts on
   a short vertical track beside its knob, up for in, and a drawn fingertip rides up and down on a lens
   (`lens-levels-all`). The glitter check at x2 (simulator stills at the screen's own pixels, not the phone): at +3 the
   band just inside the rim is a stripe of dots finer than a pixel, a point or two wide, that shimmers as the lens or a
   neighbour moves; at +2 the dots there still read as slivers. The order read at x2: a 1-step twist visibly breaks a
   lens's rim on tri, eye (both sizes) and hex (ring and hub); on quad even 3 steps barely do, as the draft's
   consequence 3 predicted from its discs grazing. Three complete 25-level tables, each solver-checked with par the
   optimum, which is the depth on every row (`docs/lens-tables.md`): A, lenses on every rod size, the draft table
   unchanged (`lens-levels-all`, the PR); B, lenses only on big rods, so only tri and eye (`lens-levels-big`); and A
   capped at +2 a lens for the glitter (`lens-levels-cap2`). Recommended: A, with quad's three rows (8, 11, 18) moved to
   hex or eye if quad's order fails on the phone, and the cap left at +3 until the phone shows whether the band's
   shimmer bothers a player. With 25 levels the Lens cover shows in Release (S1).
   Jack's calls (2026-10-28, round 10): LN1 = A, lenses on rods of every size, merged 2026-10-28 (PR #53); LN2 = A, the
   cap stays +3 (`lens-levels-cap2` is the fallback if the band's shimmer bothers him on the phone).
7. Escapement go/no-go: the mock-up's problem in the lab, played on the phone, for whether a tick landing on lift and
   lifting out on a re-grab reads, whether sealing on the next commit feels fair, and whether "lost." does.
   Built 2026-10-25; Jack has called it (round 3, E1, below): `lab-escapement` (local). Claude's verdict: go with changes. Then open:
   warn before a losing lift (recommended: live preview), and what a sealed loss shows (recommended: freeze on
   +1). Harness switches `UNSTIR_ESCWARN` and `UNSTIR_ESCSEAL`. The loss card now reads "lost on move N".
   Jack's calls (2026-10-25): go with changes (E1); the standing hint, the clock's disc always with a dashed vermilion
   edge (E2); freeze on the +1 when a loss is sealed (E3). `lab-escapement` now defaults to `hint` and `freeze`
   (local, not pushed).
   Still to reconcile: the lab lifts a tick out on a re-grab, which round 2's final tick rules out, and Jack's round 9
   call E1 (below, to-do 39) settles it: every let-go is final. The lab still lifts a tick out.
8. Split `seized` into a level motion (none, tank, crank) and a knob kind (working, seized, socket, ratchet, cup). The
   rim grab, the rim lesson, the bezel's hit area and the spin gesture key on motion; touch keys on kind, with new
   `Grab` cases for a ratchet tap and a cup dive; par's comment and the solver's turn moves key on motion; maelstrom's
   tests unchanged.
   Built 2026-10-25 on `packs-ground` (not merged): `Level.motion` (none, tank, crank) and `Level.kind(of:)` (working,
   seized, socket, ratchet, from `seized`, `sockets` and `ratchets`); maelstrom and `UNSTIR_SEIZED` set `.tank`, and a
   test pins that every level turns its tank exactly where a knob is seized. `Grab.ratchet` holds nothing and calls
   `Game.wait`, a stub. Cup is left out: The Well is cut (R9) and nothing else needs a dive. Left: the ratchet's tick
   (to-do 34, Escapement), the socket and the crank (charybdis: no level has either, and a crank would turn the tank
   until its planets are built), and a harness switch for ratchets and sockets.
9. A `Pack` type outside `Tier` (name, id prefix, levels, free-taste count, product id, card), a `pack` field on
   `Level` as the lab branch's `lab` field is, bests by id, and a test that no pack best opens a tier.
   Merged 2026-10-25 (PR #21, `store`).
10. A merge hook on `Stacked`, so an entry merging into another hands over its payload (First Stir's tag sets union;
    `Game.Entry`'s pushed mark stays the landing entry's), with tests that endless's brim behaves exactly as today.
    Built 2026-10-25 on `packs-ground` (not merged): `Stacked.absorb`, called on every merge before a pop;
    `Game.Entry.tags` unions. Left for to-do 40: the level's tags per scramble entry, which `Game` starts empty.
11. Pack undo (the free tiers' rule, that an undo leaves the uncovered stir open, merged 2026-10-25, PR #19): a
    snapshot per move, restored by undo from the shared bank, with tests per pack (First Stir's tags,
    Escapement's tick, Lens's zoom entries).
   Built 2026-10-25 on `packs-ground` (not merged): `Game` keeps the stack as each stir began, and a pack level's undo
   restores it from the shared bank; the free tiers' undo rule is merged (PR #19) and unchanged. Tested on a stack
   where the two differ. Left: the per-pack tests once each pack's state exists (First Stir's tags, Escapement's tick,
   which must ride in the snapshot, Lens's zoom entries).
   First Stir's tags: tested on `firststir-pack` (`testAHealPlaysItsVignette`, an undo of a heal brings its entry and
   tag back whole).
   Escapement's: built on `escapement-pack` and merged 2026-10-27 (PR #46): the snapshot holds the clock with the
   stack, and `testUndoTakesTheMoveAndItsTick` undoes a loss, tick and all.
12. StoreKit 2: a non-consumable per pack plus Complete; purchase, restore, the `Transaction.updates` listener,
    revocation and refunds, pending Ask to Buy; entitlements read at launch; a StoreKit configuration file and
    StoreKit test-session tests, all before the paid account exists.
   Merged 2026-10-25 (PR #21): purchase, restore, refund and Ask to Buy, Family Sharing, with StoreKit tests in CI
   via `scripts/test-store.sh`. Prices: Jack's call (2026-10-25, S1), 2.99 a pack and 5.99 Complete, in
   `StoreKit/Unstir.storekit`.
13. Entitlement guard: only StoreKit grants a pack; `Best.unlocked` never opens a paid pack in Release;
    `UNSTIR_OWNED` exists only in DEBUG or under the harness; a test for each.
   Merged 2026-10-25 (PR #21).
14. A revoked pack keeps its progress, and its levels past the taste show the card again.
   Merged 2026-10-25 (PR #21).
15. The pack shelf, apart from the tier strip and ungated: three working mock-ups for Jack to pick from, as with the
    tier switcher, then the chosen one built.
   Built 2026-10-25; Jack has called it (round 3, S2, below): three working mock-ups on local branch `shelf-mockups`, switched by
   `UNSTIR_SHELF=a|b|c`: a row under the strip, a place past maelstrom, or a dock of covers. Recommended: B.
   Jack's call (2026-10-25, S2): C, the dock of live covers along the bottom of the menu. Built 2026-10-25 on
   `packs-shelf` (`PackDock`, Shelf.swift), ported from the mock-up, with Complete as the fourth cover. Left: each
   pack's real cover art once its pictures exist (the covers are the mock-up's code-drawn placeholders); the dock's
   cost on the phone (four live shader tanks at 30 Hz on the menu) is unmeasured.
   Jack's calls (2026-10-26, round 9), built on `packs-shelf` (PR #40):
   - *S1 = C, not until its levels ship:* in Release a pack's cover shows only once `Pack.levels` holds more than its
     taste, and Complete's only once all three packs' do (Claude's reading of "its levels are in the game"); with none,
     the dock is gone. Debug shows every cover. Backstop kept from B: any card whose levels aren't all in
     (`Pack.planned`) says "More levels arrive in an update." (`testAPackGoesOnTheShelfOnceItsLevelsAreIn`).
   - *D1 = A, the defaults as built:* the buy button above the list of levels; leaving a free level opened from a card
     goes back to the card; Complete the fourth cover, labelled "Bundle"; the covers move while the menu is up, their
     battery cost still to measure on the phone.
   - Jack (2026-10-26, on the phone): a failed purchase's "didn't go through" stayed after back, even on another pack's
     card. Fixed on `packs-shelf`: every change of card forgets it, one that lands after its card changed is dropped,
     and Complete's failure, bought from a pack's card, shows under Complete's line there, not as the pack's state.
     Unchecked on the phone.
16. The pack card: a looping 7-second clip, what the pack assumes, the free taste, price, buy and restore; levels past
    the taste show it; Music Box's says "needs sound".
   Built 2026-10-25 on `packs-shelf` (`PackCard`): the price is StoreKit's `displayPrice` (`Store.prices`), the levels
   list shows once a pack has levels (shot with Debug placeholders, `UNSTIR_CARDLEVELS`), and `Store.card(for:)` sends
   any level past the taste of an unowned pack to its card (`RootView.show`). The clips themselves are drawn live by the game (to-do 50, `Clip.swift`); Music Box's "needs sound"
   waits on Music Box; the card's words ("holds 25 panels in four issues" and so on) follow the design tables and
   change with them.
17. Accessibility on the new screens: Dynamic Type and VoiceOver for the shelf, card and purchase flow; Reduce Motion
    for the vignettes' crossfades, the zooms, the clock's steps and the dive.
   Shelf and card done 2026-10-25 on `packs-shelf`: Dynamic Type through text styles (the card scrolls and stacks at
   accessibility sizes, the dock caps at xxxLarge with the large content viewer), VoiceOver labels, values and an
   announcement on a purchase state's change, Reduce Motion stills the covers, clip and pending dot and fades the card.
   Shots `shelf-menu-ax` and `card-lens-ax`. Not checked with VoiceOver running on the phone. The vignettes, zooms,
   clock and dive wait on their packs.
18. Harness: `UNSTIR_PACK`, `UNSTIR_OWNED` (one launch, never stored), First Stir's played vignettes, Escapement's
    provisional tick and lost state, with a shot and a film line per pack.
   Merged 2026-10-25 (PR #21) for the store side: `UNSTIR_PACK`, `UNSTIR_OWNED`, `UNSTIR_STORE`. The per-pack
   shots and films wait on the packs.
   First Stir's built on `firststir-pack` (2026-10-26): its played vignettes follow `UNSTIR_STACK` and
   `UNSTIR_TURNED`, `UNSTIR_BARE` draws the art unstirred and `UNSTIR_PACE` slows autoplay and `UNSTIR_MOVES` for films.
   Escapement's: built on `escapement-pack` and merged 2026-10-27 (PR #46): `UNSTIR_PLAYED` (a line committed as the
   level opens) and a ratchet's move in `UNSTIR_MOVES` as a tap; shots `escapement-1`, `-ticked`, `-lost` (a pushed
   tick), `-stopped` (the clock stopped with twists left) and `-won`, and films of the demonstration, a win and a loss.
19. A shot per purchase state: unowned, owned, pending Ask to Buy, failed, revoked.
   Merged 2026-10-25 (PR #21, `UNSTIR_STORE`).
20. A String Catalog for every new string (captions, the shelf and cards, purchase text, Escapement's stipulations),
    English at v1.
21. iCloud key-value sync of bests, pack progress, never the undo bank or its clock anchor.
22. An app-size budget for the bundle (line art baked on the phone, AAC audio), with Background Assets only past it.
23. A phone bench of every new shader cost against `fourTaps` (zoom and spiral entries, the vignette crossfade,
    Prism's channels) through an in-app GPU timer, since Instruments can't see the phone yet; each kind's weight set
    from it.
24. The performance pass's bar on each pack's heaviest frame: 120 Hz on the iPhone 13 Pro Max.
25. The slow pack-table proofs (solver optima, Escapement's prover) behind
    `UNSTIR_SLOW_TESTS`, so CI stays under the 5-minute line.
26. Tests for every pack table (par equals the solver's or prover's optimum, planning gaps where they apply), unique
    ids, and each pack's own rules.
27. Lens: a rod kind on the level (twist by default), read by the map, `same`, the shader and the solver;
    `testDailyVectors` and `testEndlessVectors` pass unchanged.
   Built 2026-10-25 on `lens-pack` (merged 2026-10-27), off `packs-ground`: `Level.lenses` (slots), a `lenses` set on every
   call that maps points, empty by default, so the free game is untouched. Left: a spiral kind, only if Jack wants one
   (below).
28. Lens: the zoom map from the lab and the spiral flow (its ring angle a closed-form integral checked against
    numerical integration), each in Twist.swift and Unstir.metal together, with tests that steps merge by summing, an
    entry and its inverse cancel, the map is the identity outside the disc and the Metal copy holds precision far past
    ±3 steps; shots that pin each kind's sign.
   Built 2026-10-25 on `lens-pack` (merged 2026-10-27): the hard lens only (Jack's L1), x2 a step (x1.3 until the
   phone session, 2026-10-26) at sharpness 2, as
   constants (`Tank.lensRate`, `Tank.lensEdge`), with those tests (`LensTests`, the Metal copy to 12 steps either way)
   and the `lens-plus`/`lens-minus` shots pinning the sign. The soft zoom and the spiral are not ported.
29. Lens: the solver and solve.sh learn rod kinds; pars from the solver.
   Built 2026-10-25 on `lens-pack` (merged 2026-10-27): `Solver(layout, lenses:)`, `solve.sh ... lenses=0`. The three test
   levels' pars (1, 2, 3) are the solver's optimum. Left: pars for the rest of the table once Jack approves it.
30. Lens: the halftone pipeline (dot screens in clean coordinates, baked panels, fill 0) and a test in the spirit of
    `testVisibleSmudgeIsNotSolved` that every step of every rod moves contrasting pixels.
   Built 2026-10-25 on `lens-pack` (merged 2026-10-27) as far as the lab's halftone test panel (`Picture.halftone`, baked off
   the main actor, cached in Debug, where it takes some 20 s) and the contrast test, on every layout. Left: the 25
   panels' art (to-do 32) and a bake that fits the phone's time and memory with 25 of them.
31. Lens: iris and nautilus knobs, the drag's count reading zoom steps, and haptic detents.
   Built 2026-10-25 on `lens-pack` (merged 2026-10-27): the iris (`RodView.lens`). The drag runs up and down, a step
   per 0.15 tank units, up zooming in (Jack, 2026-10-26); the count, dashes and half-step clicks are a rod's unchanged,
   the dashes running round the disc and the iris turning with the steps (`lens-live` shot). No nautilus: no spiral. Left: the phone's feel,
   in the phone test.
32. Lens: 25 panels of art (an original wordless heist in pop-art objects) and the issue pages.
   Story drafted 2026-10-25 (`docs/lens-design.md` section 1, branch `lens-design`): "The Switch", a reverse heist,
   each panel's beat and the clue its lens core holds. Waits on Jack (open point 2); no art drawn.
33. Lens: the level table (25), solver-checked, to Jack before it goes into code.
   Drafted 2026-10-25 (`docs/lens-design.md` section 2, branch `lens-design`): layouts, lens rods and scrambles as
   design intent, checked against the hard lens's rules by `scripts/lens-table.py`; no spiral (open point 1), no pent
   (open point 3). Every par TBD until rod kinds land (27 to 29); par is at most the depth.
   Built 2026-10-27 as three complete tables, par the solver's optimum on every row (`docs/lens-tables.md`; item 6
   above): A on `lens-levels-all`, B (big rods only) on `lens-levels-big`, A capped at +2 on `lens-levels-cap2`. Which
   one is Jack's call.
34. Escapement: the ratchet knob kind and its tap, and the tick rule (lands on lift, lifts out on a re-grab of the
    open stir, sealed by the next commit of another knob or a ratchet tap, solves on the spot, the clock stopping once
    E is empty), with a test for each case.
    Built on `escapement-pack` and merged 2026-10-27 (PR #46), ported from `lab-escapement` onto the groundwork:
    `Game.Clock`, `wait(on:)`, the tap (near the ratchet's centre; anything else on its disc shakes), the
    demonstration before the first stir (`Level.demo`, played on escapement 1), with a test for each case in
    `EscapementTests`. The rule is Jack's round 9 call E1 (to-do 39): every let-go is a move of its own and final,
    its tick landing with it, and a re-grab of the same knob is the next move, so the lab's lift-out, its seal and
    Claude's two readings about sealing are gone. Jack's round 9 D1 = A keeps the rest as built: a move a full stack
    would refuse the tick of is refused (no problem comes near 36 entries); the demonstration plays on every opening
    of escapement 1 and a tap skips it; escapement 1 is called "The clock"; several clocks will tick in turn
    clockwise from twelve. Left: the ratchet's sound (to-do 45).
    Several clocks and wound-back clocks built on `escapement-book` (2026-10-27, round 10): each running clock ticks
    in turn, clockwise from twelve, a wound-back one -1 with a mirrored ratchet; a pushed tick stops the turn and
    loses; one clock stopping while another runs loses nothing; a tap on any ratchet waits.
35. Escapement: the lost rule and its test (a pushed tick leaves a positive E entry that no continuation pops,
    property-tested on small cases) and the "lost." card with undo and again.
    Superseded 2026-10-29 by Jack's round 11 call EL1 (the tick budget, under to-do 39): a pushed tick now plays on
    until the budget is spent, then "out of ticks."; the history below is round 9's rule.
    Built on `escapement-pack` and merged 2026-10-27 (PR #46): a tick that pushes loses on the move that made it
    (E1), and so does a tick that stops the clock with twists still on the picture (E2 = B, round 9); "lost." by
    the clock, `LostCard` with "lost on move N", undo (from the bank) and again, its exit through `leave` so
    analytics sees it; a lost tank sends the level event with outcome `lost`, and leaving it after is no quit.
    `testAPushedTickNeverPops` plays 40 random small tri and quad stacks to a pushed tick, then every continuation of
    one move (two under `UNSTIR_SLOW_TESTS`, minutes). Checked on the 30 book problems too (2026-10-25,
    `ESC_PUSHED=1 scripts/escapement.sh`): playing on past a pushed tick, no line of whole heals and waits reaches
    par.
    Superseded by Jack's round 11 call EL1 (to-do 39): the instant loss gives way to a tick budget.
36. Escapement: the pruned prover (`exhaustive` with a forced tick after every move and a line dropped where a tick
    pushes), a meet-in-the-middle fallback for hex, and an escapement mode in solve.sh.
    Two provers now. The book's, `scripts/escapement.sh` on `Array.commit` (from `escapement-design`, PR #43), has a
    lower bound (each move ticks each clock once) that proves every book problem's par outright, so no
    meet-in-the-middle was needed; uniqueness is a search over turns of up to ±6 steps, which finishes on hex. The
    app's, `Solver.escapement` (PR #46, one clock), is breadth first over stacks, a move a wait or one commit of
    ±1 to ±11 or an entry's inverse, the same slot allowed twice running (E1), a line dropped where its tick pushes
    or stops the clock with twists left (E2); `scripts/solve.sh escapement <layout> <scramble> <clock> [limit]`.
    `testEveryProblemsParIsTheProversOptimum` replays each shipped problem's line on a real `Game` at par. The app's
    prover takes several clocks since `escapement-book` (2026-10-27): depth first from the clocks' bound with failed
    states remembered, `solve.sh escapement <layout> <scramble> 1+,4-`. On all 30 it finds the book's par and, over
    every turn of ±1 to ±11 steps, exactly the book's key (about 70 s optimised; the test of it is slow-only).
37. Escapement: the paper ground: dark-ink variants of the solve wave and the turn's hairlines, ink lines at least
    2 px wide, and shots that pin them.
38. Escapement: ratchet art (a 12-tooth wheel and pawl), the vermilion sub-dial and the stipulation set in a serif.
    Built on `escapement-pack` and merged 2026-10-27 (PR #46) as far as the ratchet (the lab's wheel and pawl), a
    vermilion sub-dial round the wheel fixed to the glass, its index read against it, and the standing hint (Jack's
    call, 2026-10-25). Left: the
    stipulation in a serif, and the paper ground's look of all three (to-do 37).
39. Escapement: 30 composed problems, each proved, to Jack before code.
   Drafted on `escapement-design` (2026-10-25): `docs/escapement-problems.md`, the rules as the player meets them, 30
   problems in the pitch's five chapters (layout, scramble, clocks, "Unstir in N.", line, key idea, grade), each with
   par proved absolute and one key; table in `scripts/escapement/problems.tsv`. Seven teachers composed by hand, 23
   dealt by the prover and chosen by hand. Found: under the rule a wait is never a choice (it is right exactly when
   nothing can come off), so the puzzle is triage under the dial; three clocks on hex cross every knob. Waiting on
   Jack: J1 to J9 in that file (recommended: final tick, loss shown on the lift, clockwise tick order, over par
   allowed, keep the rule, end on 29, keep Wound Back, accept detour duals in 9 and 11, accept dealt problems after
   he plays them).
   Jack's calls (2026-10-26, round 9), recorded in the book under J1, J2, J4 and J9 (PR #43):
   - *E1 = A:* every let-go is final: the clock clicks on the lift, a losing click shows "lost." at once, and no
     re-grab takes it back (J1 and J2 A). The book was proved under it.
   - *E2 = B:* if the last clock stops with twists still on the picture, the problem fails, shown as lost like a bad
     click (J4 B). The prover now plays it, and the book was proved again: every par, key, line and count of lines
     at par stands, so no problem changed or broke; 15 problems measure one bit less, since a last-move tap now loses
     at once, and the grades are as drafted. By bits 28 (4.6) now outranks 29 (4.0), which bears on J6.
   - *E3 = A:* searched problems are fine once Jack has played them on the phone and vetoed any that feel random;
     replacements come from the same search (J9 A). He also judges the order of the last two then (J6).
   Still open: J3 and J5 to J8. Left: Jack's play of the book on the phone.
   Jack's calls (2026-10-28, round 10): J6 = B, the book ends on the two-clock hex and the three-clock hex is 29; ES1 =
   B, a count of twists left, which he found unclear and asked to be workshopped; EB1 = B, change some (a wait's tap
   target on problem 7, and on problem 16 how many ticks are left and that a clock has stopped; problem 27 "naaasty!
   But I love it!"). Round 11 (2026-10-29): ET1 = B (a plate on the hub, a miss points to it); EB2 = B as a flip
   counter that starts flipping when the escapement starts moving; EL1's note replaces the E1/E2 loss rule: no par,
   a tick budget that every escapement's tick decrements (several clocks moving in sequence take several off for one
   move), always shown, and a wrong move leaves the puzzle unsolvable without an undo instead of losing at once;
   EL2 follows it. Built on PR #52 (`escapement-book`, merged 2026-10-29): the budget, the flip counter, the plate and J6.
   Round 12, ES2 = B: each clock's own split-flap count in its hub, the header their sum, a clock at 0
   stopped and greyed (built on `esc-hub-flaps`; the rule under "Jack's calls on the pitch", round 12).
   E1 and E2 are built in the app and merged 2026-10-27 (PR #46, to-dos 34 to 36), with the D1 defaults that touch
   Escapement kept as built (D1 = A, round 9).
   All 30 built on `escapement-book` (2026-10-27, round 10), waiting on Jack's play of the book on the phone (E3): the
   book's order and five chapters, headed in the card's list; each par what its clocks owe, reached by the app's prover
   and replayed on a real `Game`; each key pinned. Problem 1 is the book's "The tick" under D1's title "The clock" (so
   the old escapement-1, the mock-up, is now 2, "The wait"); the 22 untitled problems are "Problem N". Escapement now
   has levels past its taste, so it goes on sale on the shelf and its card no longer says more arrive.
   Jack's call J6 = B (round 11): the book ends on the two-clock hex, 30, with the three-clock hex as 29; rows swapped
   and the book re-proved on `escapement-book`. Round 10's question of what a tank lost to its last clock stopping shows
   (`UNSTIR_STOPLOOK`) is superseded by EL1: the budget at 00 is always on screen, so the stamp alone says it; the
   looks stay in the harness, unpicked. Still open from the book: J3 (built as A, D1), J5, J7 (built as A), J8.
   Jack's round 11 calls, built on `escapement-book` (2026-10-29):
   - ET1 = B: `esc-tap-target` merged: the ratchet sits on a lit plate a tap waits on, and a tap off the plate draws a
     ring closing on it instead of a refusal.
   - EB2 = B: `esc-budget-count` (on `esc-owed`, `Game.owed`) merged, with Jack's note: "to keep with the clock theme,
     can you make the numbers count down like a flip clock? have start flipping when the escapement starts moving".
     Built as one split-flap numeral in the header, flipping once per clock's tick as that tick starts to turn; the
     per-clock hub counts went, since after a pushed tick they would disagree with the one budget EL1 asks for. ES2
     (round 12) brought them back as flip cards that can't disagree: each clock's own count, the header their sum.
   - EL1 (and EL2, "See answer to call 3"), replacing round 9's E1/E2 loss rule: "better idea: "par" is not a thing
     for escapement. instead, you get a tick budget, and each individual escapement decreases it. a puzzle becomes
     impossible to solve without an undo if you make a wrong move, rather than you losing instantly. the remaining
     ticks are always shown clearly. if a tank has more than one escapement, each one decrements the budget when it
     moves, so when they all move in sequence the budget goes down by for example 3 even though only one move was made
     by the player. make sense?" Built: the budget is what the clocks owe in all as dealt; each tick spends one; a
     pushed tick plays on (every later clock in the turn still ticks); spent with twists left is "out of ticks." with
     `LostCard`'s undo and again. Without a push the budget equals what the clocks still owe after every move and hits
     0 exactly as the last clock stops: checked on all 30 problems' proved lines, so the book stands unchanged. Par is
     gone from every Escapement screen, the card and the book's stipulations ("Unstir in N ticks.").
   - Not merged, per Jack: `esc-lost-line`, `esc-lost-flash`, `esc-tap-anywhere`, `esc-tap-lesson`,
     `esc-budget-stopwork` (local branches, kept).
40. First Stir: vignettes as tag sets on the scramble's entries, played when their tags leave the stack (a pop, a
    merged pop, a fine-pass win), unplayed by undo and reset, crossfading 0.4 s under the stack.
    Built 2026-10-26 on `firststir-pack`, merged 2026-10-27 (PR #44): `Level.story` and `Story.vignettes`, each of
    the scramble's entries tagged with its rod where that core has a vignette, `Game.played` a function of the stack,
    the heal ring magenta only for a commit that plays a vignette, and `StoryLayer`, which cross-fades each core 0.4 s
    and winds the night back a stage per vignette (F2) under the live rain and moon. Level 1 is the lab's harbour, as
    a real level of the pack (`first-stir-1`), opening wrecked (round 6), its caption the note "Each heal turns the
    night back." Shots `firststir-01*` and films `firststir-01-solve` and `firststir-01-ring`. Left: tags are the
    entry's rod, so the outline's "Last" order (a vignette held by one chosen entry) needs a per-entry tag on the level
    when a scene asks for it. Outside Release the shelf's First Stir card lists level 1; in Release the pack has no
    cover until its levels past the taste are in (S1).
    Jack's calls (2026-10-26, round 9) that touch it: *F2 = A* (one night across the pack, about half an hour a
    picture) and *F5 = A* (the harbour as pictures 16 and 1) mean level 1's whole night, storm back to evening, is a
    stand-in: the art pass cuts each harbour picture to its own half hour. *F3 = A* (a clock under the tank stepping
    back on every heal) replaces the caption "Each heal turns the night back."; built with chapter 1 (to-do 43). *D1 = A:* the cottage's
    glow stays narrowed to its core (to-do 41).
41. First Stir: a per-scene test that no vignette's light reaches the core of a rod with an entry removable right
    after its heal (`Layout.removable`), over every heal order.
    Built 2026-10-26 on `firststir-pack`: `testNoVignetteShowsTheNextMove` renders each vignette's two states and
    takes where they differ as its light. It also checks that light stays inside its own core (the lab's cottage glow
    spilled past it and was clipped: tightened to the lantern's) and the lab's smear rule, that the entries left move
    none of it by half a pixel. The harbour passes the light rule and breaks the smear rule twice, pinned in the test
    as Jack's call: the lantern's falling shards (5 px at most at 3x) and the boat's stern, both in the cottage's shear
    ring when they play. Tri's cores all lie in each other's discs, so no heal order avoids it; only the art can.
    Jack's call (2026-10-26, round 9, F4 = A): every change stays inside its own core, checked by the test over every
    picture, and the boat's stern and the lantern's shards are redrawn in the art pass; the two smears stay pinned in
    the test until then. Merged 2026-10-27 (PR #44). Redrawn 2026-10-27 on `firststir-ch4` (scene 16 on the engine):
    the shards fall inside the lantern's core clear of the other discs, the boat lies right of the cottage's disc, and
    the test pins no fault.
42. First Stir: vignettes baked on demand within a memory budget measured on the phone.
    Built 2026-10-26 on `firststir-pack`: the layers bake as the level appears, five in all whatever the number of
    stages (two skies, the bolt's box, the scene held back and played), against the lab's two per stage; about 51 MB
    at 3x on the Pro Max, under `Harbour.budget` (64 MB), past which they bake at a lower scale
    (`testTheLayersBakeWithinTheBudget`). Merged 2026-10-27 (PR #44). Left: measure the budget on the phone; it is a
    guess until then.
43. First Stir: 25 scenes of art and their scrambles; Jack reviews the table.
    **Jack's call FS17 = C (2026-10-29): First Stir leaves v1, to be reworked significantly later.** His note: "I say C
    only because I think the constraints of the artwork have resulted in the story becoming difficult to read from the
    illustrations alone. I think we should leave First Stir out of v1 of the app, and rework it significantly later.
    Something else needs to take its place as the third paid level pack with at least one new mechanic." The work below
    stays on `firststir-content` (PR #54, merged 2026-10-29) for that rework; the third pack is Prism (PK1 = A, round 12).
    Jack's calls (2026-10-28, round 10), made before FS17: FS10 = A (approve the art), FS12, FS13 and FS14 = A (the
    night's clock and sky, and the departures from the outline, all as built), FS15 = A (judge small figures on the
    phone first), FS16 = A (fold Pen into Brush), and a note on FS11 (the ending film, see to-do 44). They stand for the
    rework.
    Built 2026-10-29 on `v1-without-firststir` (PR #60, merged 2026-10-29): `Pack.ships`/`Pack.sold()` keep First
    Stir off a Release build (no shelf cover, no card, its levels `.withheld`, Complete naming, granting, drawing and
    clipping Lens and Escapement only, the analytics snapshot without it) while Debug and the harness keep all of it.
    The StoreKit test file keeps First Stir's product, since `StoreTests` run outside Release, where it is still sold.
    Release-build shots `round12/fs/release-*.png` in the tools folder: the dock shows Lens alone (Escapement has one
    level, so it waits for levels past its taste, and Complete waits for both).
    All five chapters joined on `firststir-content` (2026-10-27), levels `first-stir-1` to `-25` in the outline's
    order, with master's Lens and Escapement; First Stir was on the Release shelf until FS17, nothing left to arrive, the taste
    of 3 then the card (`testFirstStirPlaysInOrderFromTheShelf`). The Flood's and the Storm's `HighStreet` clashed; the
    Storm's is `StreetInRain`. Sheets `round10/firststir/ch1-sheet.png` to `ch5-sheet.png` in the tools folder.
    The scene table is outlined in `docs/first-stir-outline.md` (to-do 5), approved by Jack (2026-10-26, round 9).
    Chapter 1, Dawn After (scenes 1 to 5), built 2026-10-27 on `firststir-ch1`, merged into `firststir-content` (off `master`, not yet a PR), to
    the outline (FS=A) and round 9's answers (F1 to F5, all A): `FirstStirDawn.swift` draws the five scenes, three
    vignettes each, in dawn pewter, 6:40 back to 4:45 am; `StoryScene.swift` plays them on the pack's one night, the
    time stepping back with each of the scramble's entries gone and shown as a clock under the tank ("6:40 am"). Levels
    `first-stir-1` to `-5`: sunrise (tri `2:+5,1:-4,0:+3,1:+2`), the gallery (quad `3:+4,0:-3,1:+5,2:-2`), the rock pool
    (tri `1:+4,2:-3,0:+5,1:-2,2:+3`), righting the boat (eye `0:+3,1:-4,2:+5,3:-2,1:+2`), tea on the quay (quad
    `2:+4,3:-3,1:+5,0:-2,3:+2,2:-5`); each par the solver's optimum. Every change keeps 0.02 inside its core and clear of
    its knob, and no vignette plays smeared over any heal order (tested). Level 1 was the lab's storm harbour, the
    outline's scene 16: per F5 it is now the same view at sunrise, redrawn, and the storm harbour waits, with no level,
    for chapter 4. Shots `firststir-0N`, `-held`, `-played`, `firststir-01-healed-1` and `-2`; `scripts/first-stir-lab.sh`
    is the drawing loop. The review's fixes (2026-10-27): each core cuts in through a mask without antialiasing, since
    an antialiased edge left a faint ring at every played core (`testTheCutInCoresLeaveNoSeam`; a vignette's faint glow
    tail can still step a few levels where it crosses its core's edge); the sun and smoke keep clear of every disc by
    their glow and line as well (`Dawn.bodyGlow`), so the sun is smaller (0.022) and further right, and the smoke starts
    a little higher off the neighbour's chimney pot; tea's crate stands on the ground with the flask in the pouring
    hand, its searchlight beam is a flat fill and the held coil is ink; righting's lantern and bucket stand either side
    of rod 3's knob; the rock pool's weed is ink, leaving the float the one teal thing; the gallery's candle window
    sits in a house's wall. The sunrise's cottage plays after the boat because its doorway lies in the boat's disc (as
    the outline says), its door moved a little left so the change keeps 0.02 inside the core.
    **Open, Jack's calls on three departures from the outline** (Claude's recommendations, not decided):
    - D1, the sunrise's chimney smoke. A: smoke from the neighbour's chimney as the time layer, outside every disc,
      thinning as the night winds back (built). B: the outline's, smoke from the cottage's own chimney in the
      cottage's vignette, which needs the cottage redrawn so its chimney lies in the core. C: no smoke. Recommend A:
      the smoke tells the time on every heal, not once, and B crowds the cottage's core.
    - D2, the rock pool's dog. A: sitting a little up the rocks from the child, clear of her change (built). B: the
      outline's, by the child's boots, where its change did not stay clear, so B needs the dog, the child or the
      pool reworked until it does. Recommend A: the same story, and each change reads on its own.
    - D3, righting the boat's heal order. A: the boat clear of the haulers' disc, so the two heal in either order
      (built). B: the outline's, the bow reaching the haulers' disc so the boat heals after them, which means
      redrawing the beach so the boat sits nearer rod 0 and rechecking it plays unsmeared. Recommend A for now:
      it plays clean under every order; B is the better story if Jack wants the order to carry it.
    Chapter 2, The Rescue (scenes 6 to 10), drawn 2026-10-27 on `firststir-ch2` in `FirstStirRescue.swift` and brought
    onto chapter 1's engine on `firststir-content` (2026-10-27, pushed, no PR yet) as `Story.rescue` cases, levels
    `first-stir-6` to `-10` (ids now stamped by place): home light (pent `1:+3,0:-4,2:+5,4:-3,3:+4,0:+2`), off the
    breakwater (eye `0:+4,3:-3,1:+5,2:-4,1:-2,3:+3`), the lantern chain (quad `3:+4,0:-3,1:+5,2:-2,3:-5,0:+2,1:-3`), the
    stair (tri `0:+4,1:-3,2:+5,1:+4,2:-3,1:-5,2:+2`) and the lighthouse door (pent `3:-4,1:+3,0:+5,4:-2,2:+4,1:-5,3:+2`),
    each par the solver's optimum (`SolverTests.testFirstStirParIsTheOptimum`). On the engine its time steps per
    scramble entry with the clock caption, 4:45 back to 2:30 am; its rain is drawn over the composite (`drawOver`), a
    function of the time; its sky and sea open on Dawn After's 4:45 tones and turn to rescue amber's lit low cloud by
    4:15, so the horizon brightens as scene 6 winds back. Its pen is `Brush` beside chapter 1's `Pen`. Chapter 2's `.compositingGroup()` fix to `StoryLayer`'s cut-in was not carried; the storm harbour moved onto the engine with chapter 4, so `StoryLayer` is gone. At the test's
    512 px five vignettes reached a few thousandths past the art spec (scene 6's window pane by the knob, scene 8's
    lifeboat and bearers, scene 10's door wave and lamp flashes) and were pulled in. Its review's fixes stand (flat
    fills for glows and beams, scene 7's steps, scene 8's beats, scene 9's lamp and lantern, scene 6's searchlight).
    **Open for Jack, chapter 2** (Claude's recommendations, not decided):
    - Ink: the outline names no line ink for rescue amber; built with the rain's B7CEFF at full strength. The other
      choice is chapter 3's 8F9CFF, carrying over into the flood. Recommend B7CEFF: it ties the lines to the rain.
    - Scale on pent: figures are at the spec's 0.12 minimum and the lifeboat about 0.12 long between knob and margin.
      If they read small on the phone: a smaller knob clearance on small rods, or closer-up drawing. Recommend judging
      on the phone first.
    - Two pens: `Pen` (chapter 1) and `Brush` (chapter 2) do the same job. Recommend folding `Pen` into `Brush` (the
      more general: figure units, clips, one glow per vignette) before chapter 3, so later chapters draw with one.
    Chapter 3, The Flood (scenes 11 to 15), drawn 2026-10-27 on `firststir-ch3` (off `firststir-content`) in
    `FirstStirFlood.swift` with chapter 2's `Brush` and `Cast`, levels `first-stir-11` to `-15`: the breakwater path
    (eye `1:+4,0:-3,3:+5,2:-4,0:-2,3:+3,2:+2`, the path's entry under both of the quay end's: the wave over the father
    reaches rod 0's disc), high street under water (pent `0:+3,2:-4,3:+5,1:-3,0:-5,4:+2,2:+4,3:-2`), the upstairs
    window (quad `1:-4,3:+3,0:+5,2:-3,1:+2,0:-4,3:-5,2:+4`), the kitchen, flooded (eye
    `0:+4,3:-3,1:+5,2:-4,1:-2,3:+3,2:+2,1:+4`, the table's one entry at the bottom, so it plays last, as the outline's
    "A after rod 1" asks) and over the quay (pent `4:-3,1:+4,3:+5,0:-2,4:+3,2:-4,1:-5,3:+2,0:+3`); each par the solver's
    optimum, and every change 0.02 inside its core, clear of its knob, and unsmeared over every heal order (tested at
    512 px). 2:30 back to 12:30 am in flood teal, ink 8F9CFF (the outline's), opening on the Rescue's 2:30 sky, sea and
    rain (tested) and thickening the same rain field from 320 drops to 400 towards the storm; the sky stays in the
    flood's palette, taking a little of its ink (chapter 4 turns from it to storm indigo, as this one turns from the
    Rescue's). The father's rope is drawn only in scene 11's vignettes, out to him and the coil on his shoulder at 2:30
    as scene 10 leaves him, and absent at 2:05 while he ties it; a wave over the path stands where it would cross
    between the cores. Each scene's floodwater line is fixed outside its cores (the spec lets only sky, rain and lightning move
    there); the vignettes that lower the water draw their own line inside the core: the lamp's foot, the cottage
    door's step between its porch posts, the kitchen table standing clear with ripples at its legs. The float keeps
    3FE0B0. `scripts/first-stir-lab.sh` now draws chapters 1 to 3. Shots `firststir-11` to `-15`, `-held`, `-played`;
    sheet in the tools folder (`round10/firststir/ch3-sheet.png`).
    **Open for Jack, chapter 3** (Claude's recommendations, not decided):
    - The water inside a core. Where a vignette lowers the water (scenes 12, the street lamp; 13, the door; 14, the
      table), the played core shows a lower
      line than the scene around it, since the scene's own line may not move. A: as built. B: put each lowering in the
      time layer instead, the water a function of the time like the rain (a spec change: the water would cross discs).
      Recommend A: it keeps the spec's rule that only sky, rain and lightning cross discs, and every other beat already
      shows an earlier moment against a later scene.
    - Scene 14's heal order. The outline asks the table after the stair; built as the table's one entry at the bottom,
      so it heals after everything (the tabletop also reaches the float's disc). Recommend keeping it: the cup back on
      the table is the chapter's last beat before the storm.
    Left: Jack's review of the art at phone size (the figures are small on the quad and pent scenes), the films, and
    chapters 4 and 5.
    Chapter 4, The Storm (scenes 16 to 20), drawn 2026-10-27 on `firststir-ch4` (off `firststir-content`, pushed, no PR)
    in `FirstStirTheStorm.swift` as `Story.storm` cases, in storm indigo with sodium, 12:30 am back to 9:30 pm (its
    times negative past midnight), levels `first-stir-16` to `-20` once chapter 3 joined the table on
    `firststir-content`. The harbour (tri
    `2:+5,1:-4,0:+3,2:-2,1:+5,0:-4,1:+2,0:+3`, the cottage's entry at the bottom as the lab had it), lightning (quad
    `3:+4,0:-3,1:+5,2:-2,3:+3,0:+4,1:-4,2:+5,3:-2`), the bell buoy (pent `0:+4,2:-3,1:+5,3:+2,4:-4,0:-2,2:+5,3:-3,1:+2`),
    high street, rain (eye `0:+4,2:-3,1:+5,3:+2,0:-3,1:+4,2:+5,0:+2,3:-4,1:-2`) and washing (pent
    `3:+4,0:-3,1:+5,4:-2,2:+4,0:+3,1:-4,3:-5,2:+2,0:-2`), the outline's stirs, each par the solver's optimum. The lab's
    harbour is scene 16 on the engine, drawn from the sunrise's plan, its two faults redrawn (F4); `StoryLayer`,
    `Story.harbour` and the lab's own drawing are gone, and `Harbour` keeps only the shared line, fades and budget. Its
    sky is the lab's storm at 12:30 warming late to the lab's dusk at 9:30; its rain thins as the night winds back; far
    lightning crosses the sky in scenes 16 and 18 until about 10:50; scene 17 is indoors, rain only in its windows.
    Joined on `firststir-content` (2026-10-27): the two branches disagreed on the seams (the Flood's 12:30 sky is its
    own deep blue, and the Storm's 9:30 sky was Dusk Before's 7:40 coral, where Dusk opens on night blue), so the Storm
    bridges both, as each chapter before it turns from the last: it opens on the Flood's 12:30 sky and sea, turns to the
    lab's storm across scene 16, and ends on Dusk Before's 9:30 sky and sea, its rain gone by then
    (`testTheStormsSkyMeetsItsNeighbours`). Scene 19's sign is a cut-out cobbler's boot (no board, so nothing in it reads as a letter) high
    on a gable, where the small rod's core is clear of the big rods' discs (the outline fixes no place for it); its
    cuff chain and the top of its toe chain are the same in both states, the toe chain snapped below. Review fixes
    (2026-10-27): the tinted room fills are black; scene 17's low window is wider so the child and the dog both kneel
    under it, heads against its sky, and the held child is larger, her hat beside her father's brim; scene 19's bicycle
    stands on the pavement, its front wheel against the lamp post (moved to x 0.64); scene 20's corner line stops at the
    back wall's top, the shirts hang by their shoulders, sheared downwind, pegged at the corners, the neighbour's window
    is larger and she leans out to her waist, and a lit window with a sill under it gives rod 1's core its up.
    `testNoVignetteShowsTheNextMove` now also checks the baked layers for strays at the phone's own pixels, where
    scene 20 once showed two single-pixel strays at 512 px that went away on a 0.01 nudge.
    **Open for Jack, chapter 4** (Claude's recommendation, not decided):
    - S1, scene 17's windows. The outline gives the upstairs room one window over the bay, with the candle on its sill
      and the child on its window seat, but quad puts the three vignette rods in three corners (view top right, light
      top left, child bottom left). A: three windows, the bay window for the view, a small high one whose sill holds the
      candle, a low one over the window seat (built). B: one wide window, which means re-planning which rods hold which
      beat (the light and the child would move off the outline's rods 3 and 2). Recommend A: the outline's rods and
      beats stand, and an attic room with three windows reads as one room.
    Left: Jack's review of the art at phone size (the figures are small on the quad and pent scenes; on the Storm's pent
    and quad scenes the adults are near the spec's 0.12 minimum), the films, and chapters 3 and 5.
    Chapter 5, Dusk Before (scenes 21 to 25), drawn 2026-10-27 on `firststir-ch5` (from `firststir-content`, pushed, no
    PR) in `FirstStirDuskBefore.swift` on the scene engine as `Story.dusk` cases: lighting the lamp (quad
    `3:+4,0:-3,1:+5,2:-2,3:-5,0:+2,1:-3,2:+4`), the path to the light (eye `0:+3,2:-4,1:+5,3:-2,0:-4,1:+3,2:+2,3:+4`),
    doubling the lines (pent `4:+3,1:-4,3:+5,2:-3,0:+4,1:+2,4:-5`), the float (quad `0:+4,3:-3,2:+5,1:-2,0:-3,3:+2`) and
    first stir (tri `2:+4,0:-3,1:+5,0:+2,1:-3`, the cup's entry at the bottom so the stir always heals last), each par
    the solver's optimum and every vignette drawn clear of the other discs (the outline's "Clear" orders). The clock
    runs 9:30 back to 7:40 pm. Its levels are `first-stir-21` to `-25`. The Storm's scene 20 ends on `Dusk.skyTones(1290)` and
    `Dusk.seaTone(1290)` (`testTheStormsSkyMeetsItsNeighbours`). Sheet: `scripts/first-stir-sheet.py 21 25`. **Open for Jack, chapter 5** (Claude's recommendations, not decided):
    - Scene 24's gift held back: the outline has the child holding the float up to the light while the same picture
      shows it hanging in the window, two floats as the level opens. Built: the child's hands up to the window, empty,
      so the opening and the end each show one float, the child standing under the window with both arms up to it.
      The other choice is the outline's, as written.
    Review fixes (2026-10-27, same branch): the quay runs under scene 23's hut and the boat is moored to two buoys; its
    barometer is larger, the needle short of the glyphs; scene 24's figures are scaled to the kitchen (bodies drawn
    outside the vignette, only arms and float inside the core) and its door is glazed, a horizon in rod 0's core;
    scene 21's grandmother is 0.125 tall; scene 25 has a cloud, not a gull, a leaf hour hand, and the child's hand
    joined to a sleeve from the table's near edge (static, so it may leave the core). The cloud bank now sinks as a
    live body at the glass's left edge (x -0.985 to -0.83), the one stretch of horizon clear of every disc, so it is
    no longer a departure; the sky uses the palette's three tones alone.
44. First Stir: the "night forwards" end film.
    Built 2026-10-27 on `firststir-content` (Jack's D1 default, round 9): after level 25's solve, all 25 scenes play
    forwards in the glass, 4.6 s each with a 0.6 s crossfade, the time under it running on from 7:40 pm to 6:40 am,
    about two minutes, ending held on scene 1 as the pack opened, then the card; a tap skips it. Every solve of 25
    plays it (as Escapement's demo plays every time). Reduce Motion cuts instead of fading. No motif yet: the sound
    branch is unmerged. Shots `firststir-ending-*`, film `firststir-ending`. Left: the memory and frame pacing of the
    bake (main actor, two scenes at once, at most 2x) measured on the phone.
    Jack's note (2026-10-28, round 10, FS11): at points a scene changes very briefly and switches back, which reads as
    gameplay rather than the final scene; those changes should be longer, clearer in what they say, or not happen. Moot
    for v1 with First Stir out (FS17 C); it belongs to the rework.
45. Sound: round 2 is in (SN1 = A, 2026-10-28: early undo, step-back heals, the vortex bed; PR #56); sketch each v1 pack's
    layers for his ear (First Stir's felt-piano motif and weather pads, Lens's canon, Escapement's muted kit, tooth
    drops and looping phrase); render the finals in Csound.
46. Free taste: the first three levels of each pack teach its rule without words; cold-read each on a new player.
   Escapement's three drafted on `escapement-design` (2026-10-25): 1 the tick, 2 the wait (the mock-up), 3 the dashed
   edge, after the lab's demonstration. The cold read waits on the pack's build.
   Lens's taste drafted 2026-10-25 (`docs/lens-design.md`, levels 1 to 3, all tri): the knob and the dot ruler, a
   broken rim, a whole rim. Not built or cold-read.
47. The daily archive: a calendar screen, bests under `daily-yyyymmdd` ids, back-filled to Jack's date, opened by any
    purchase.
   Jack's call (2026-10-25, round 6): back-filled to 30 days before launch day (`Share.firstDay`).
48. The supporter mark (menu and share line), after any purchase. ~~The tip jar~~ dropped (Jack: "No begging").
49. The daily share line (plan step 2), separate from sharing, before TestFlight.
   Merged 2026-10-25 (PR #24). Jack's call (2026-10-25, D1): daily #1 is launch day; until `Share.firstDay` is set,
   the line shows the date instead of a number.
50. Jack (2026-10-26, on the phone): the placeholder loops "don't show off what it does". Each card's clip must show the pack's own mechanic: Lens's lenses zooming, Escapement's clock ticking, First Stir's picture changing as it unstirs. They wait on each pack's content merging, so the card can stir with the real code (no committed media).
    Clips and images: each pack's 7-second clip and promoted in-app purchase art, filmed with film.sh, plus a sound-on
    cut for social video.
    Built 2026-10-27 on `pack-clips` (`Clip.swift`): every card's clip is drawn live by the game on the real levels and
    rules, about 7 s, seamless, Reduce Motion holding a still; the bundled-video path is gone. First Stir: level 1 healed,
    each vignette playing as its time under the tank steps back (12:30 am to 11:40 pm, scene 16's window, a stand-in
    until the level carries F3's clock). Lens: level 3 as dealt, the lens dragged down and back up, ending on the order
    read. Escapement: problem 1 in three, each tick landing. Complete: an 8 s cut, a vignette, a zoom and a tick. The dock keeps its covers.
    Merged 2026-10-29 (PR #51). Jack's calls (2026-10-28, round 10): CL1 A, Lens plays the zoom and the read; CL2 B, Complete plays each one's first beat in
    turn (a vignette, a zoom, a tick, about 8 s). The other takes are gone (set aside: Lens's level 2 solved, and
    Complete's three whole, about 21 s, too long for a card). Films `clip-*`, `shelf-dock`. Follow-up: on
    `firststir-content` level 1 becomes Sunrise on `SceneLayer` with its own clock, so the First Stir reel must then
    draw with the level's own layer and read its `late`/`early`; `ClipTests` will flag it. Complete keeps three
    tanks drawn, two clear: its cost on the phone is unmeasured. Still open: the purchase art and the social cut.
51. Buy the developer account when TestFlight is ready (see "The Apple Developer account"); then the paid apps
    agreement, tax and banking, and the in-app purchases with review screenshots and promoted purchases.
52. The privacy manifest, new work (no `PrivacyInfo.xcprivacy` exists): UserDefaults with reason CA92.1, the uptime
    clock with 35F9.1, and whether reading `kern.monotonicclock` needs a reason (the open question in "Where things
    stand"); then the privacy label.
   Merged 2026-10-25 (PR #20).
   With analytics (branch `analytics`) the manifest also declares product interaction, coarse location and purchase
   history (the `purchased` event and the snapshot's packs owned), each unlinked, not tracking, for analytics; the
   App Store privacy label must say the same.
53. The age-rating questionnaire. Jack's call LG2 = A (2026-10-29, round 11): if analytics ships, an age bracket comes before
    the consent card, the threshold read from one setting; round 12's AN1 recommends no analytics in v1, which would make it moot.
54. The store page: screenshots and a preview leading with the free game, then the packs, each pack labelled as a paid
    add-on, captioned for muted playback.
   Jack's calls (2026-10-28, round 10), drafted on local branch `store-page` (not pushed, no PR): ST1 = A, the name
   Unstir; ST2 = A, the subtitle "Unwind the stirred picture"; ST3 = A, the promotional text that says what is free and
   that packs exist; ST4 = A, seven free-game screenshots then one per pack; ST5 = A, one 25 s preview of the free game
   only; ST6 = A, Family Sharing on for the packs and Complete; ST7 = A, the draft's keywords, category, policy and
   support page, and the send-log button left undeclared on the privacy label (contact address: kept privately). The
   analytics side's policy draft was dropped after AN1 = A. ST8: Jack will not ask a lawyer and told Claude to find
   the answers itself; the legal summary is kept outside the repo. Open: the pack screenshots and the 25 s film are
   still to make, and AN1 and EU1 (round 12) are decided, so the no-analytics policy is the one that stays.
55. Check App Review's rules on Complete before naming or pricing it.
56. ~~Offer codes for press and reviewers.~~ Dropped (Jack: "No.").
57. TestFlight with 20 to 50 strangers and sandbox purchases. What it measures (shelf and card taps, free-taste
    completion and sandbox purchases per pack, beside day-2 return) waits on Jack's call on how to read testers' play.
   Jack's calls (2026-10-25, round 6): an analytics library plus a send-log button, behind one consent question at
   first launch. Jack's call (2026-10-25, round 7): **Aptabase** on its EU region (Claude's recommendation, over
   TelemetryDeck, PostHog Cloud EU and Mixpanel; Firebase, Amplitude, Countly, Matomo and a self-hosted PostHog ruled
   out). It sends no player ID, so the app derives return itself: it sends `installed` once and `returned` with the day
   number once on the first launch of each later day, and once-per-install events for each pack's card view, finished
   taste and purchase; `level` events carry the level, the outcome, moves, undos and resets. Every figure is a count over
   the players who said Yes. Free up to 20,000 events a month, US$10 for 200,000, and it pauses at the cap rather than
   billing over. Apple's App Analytics is a free cross-check. The research is on the local `archive/scratch` branch.
   Per-player history, Jack's call (2026-10-25): no install ID, since a persistent ID makes the data personal under
   GDPR and Aptabase's policy refuses deletion requests. Instead the phone builds each player's history from what it
   already stores and sends one summary on days 2, 7 and 30, with no ID tying it to the player's other rows (e.g.
   `snapshot`, day 7, days played 1,2,5, furthest V9, lens card seen, taste finished, not bought, 14 undos); grouping
   rows by their contents answers questions such as whether players who finished a taste came back. Plus the send-log
   button for full touch histories from testers who send one. Aptabase's server (`EventBody.cs`) takes property keys
   of up to 40 characters and event names of up to 60, and cuts string values at 180; it drops, still answering 200,
   events over a day old and any whose session began over 7 days ago.
   The analytics core is built on `analytics` (`Analytics.swift`, its own sender with a queue on disk rather than the
   pre-1.0 SDK, which holds events only in memory).
   Jack's calls (2026-10-26, round 8), built on `analytics` (PR #38):
   - *Q = A:* the question is a card over the menu at first launch, and the menu waits for an answer; Yes and No are
     the same control, same type, colour and size, neither preselected (mock-up style A, `consent-mockups`).
   - *S = A:* a gear beside the menu's title opens a dark sheet with the analytics switch and "send log", which hands
     the flight recorder to the share sheet.
   - *N = C:* under No nothing is recorded for analytics and the tally is cleared but for the install's day, so day
     numbers stay right; a later Yes starts clean. Bests and started flags stay. Undecided keeps recording.
   - *K = B:* `returned` goes for any day number not yet sent, and when several snapshots are due at once only the
     newest goes.
   Jack's call (2026-10-26, round 9), built on `analytics` (PR #38):
   - *C1 = C, one line and a link:* the card reads "Help improve Unstir?", then "Let the game tell us how you play.
     Never who you are.", then a cyan link "What does it send? ›" that opens round 9's option A, the full list of what
     is sent, under the line (Claude recommended B, the shorter text). Yes and No stay equal. Shots `consent-ask` and
     `consent-sends` (`UNSTIR_CONSENT=sends`).
   Settled (Jack, 2026-10-28, round 10, AN2 = A): under N, clearing the tally clears what was sent once too, so a player
   who says Yes, No, then Yes sends `installed` (and any snapshot due) again and counts as a second install; he
   accepts that. AN1 = A: the consent card's link opens and closes its list (merged 2026-10-28, PR #55). Round 11:
   LG1 = C conditionally (no EU release if the EU hurdles can't be cleared), LG2 = A (an age bracket), LG3 unanswered.
   Round 12, AN1 = A: v1 ships no analytics (`v1-no-analytics`); `keep-analytics` holds the other side.
   TestFlight prep merged 2026-10-25 (PR #23); the icon is candidate 1, the neon grid (Jack, 2026-10-25, I1).
58. Apple's featuring nomination, then launch.
59. ~~Prism: per-channel `same`, `commutes` and `looksSolved` on each channel's restricted word, with tests that
    overlapping entries with disjoint masks commute.~~ Done: PR #59, merged 2026-10-29.
60. Prism: the shader's per-channel chains (built, #59), their cost (assumed 2 plus a map per channel held) benched on
    the phone. Depth is capped at 8 (PK1), so every specimen costs at most 18 entries against the 30 the plain shader
    holds four taps at. The GPU bench is built (`prism-bench`, `scripts/gpu-bench.sh`): on the simulator (the Mac's GPU,
    wall clock) every specimen's measured cost is 0.6 to 0.9 of the assumed, the slowest (24) 0.7 ms a frame at 1284 px.
    **For Jack:** run `scripts/gpu-bench.sh phone` once with the phone cool; it prints the same lines from the phone's
    own GPU clock. Until then the cost stays an assumption.
61. ~~Prism: a colour-blind simulation, the line styles under Differentiate Without Colour, and the swatch that shows
    one channel.~~ Done 2026-10-29 (`prism-colourblind`). The simulation (`scripts/colour-blind.py`) showed the default
    read fails for protanopes and deuteranopes: red, green and yellow ghosts all turn one olive, and cyan nearly white,
    so tray 1's cyan ghosts vanish into the aligned lines. Under Differentiate Without Colour each knob spells out its
    primaries (R, GB, RGB) and R, G and B swatches sit under the caption: holding one draws that channel alone in white,
    an exact read for every kind of colour blindness. Line styles per channel were set aside: Prism samples one layer
    per channel, so a styled picture must differ in its R, G and B planes, and the inks then read as the union of two
    styles (red's solid line hides whatever it is paired with), so magenta, yellow and red stay alike; the swatch has
    no such gap. Off Differentiate Without Colour neither shows, so the pack reads by colour as designed.
62. ~~Prism: the engravings, tinted knobs and 30 specimens, solver-checked.~~ Done 2026-10-29: five plates, 30
    specimens in five trays at depth 8 or less, par the solver's optimum on every one (`docs/prism-design.md`).
63. Music Box: the render-thread scheduler for sample-accurate plucks (a render callback reading a lock-free snapshot
    of pin positions each buffer; assumed `AVAudioSourceNode`).
64. Music Box: the ear-test protocol (cold readers, sound on against sound off, the time to find each seam), run
    before any art; the pack is cut if it fails.
65. Music Box: pins, the comb arm, snapping, the hum control and the tines in Csound; 24 tunes, to Jack's ear in
    sketch rounds.
66. Music Box: the Composer: tune links, a web domain, report and block tools for titles and links, and the
    age-rating effect of user content.
67. ~~The Well: cups baked to textures, nested `Game`s, the round-glass test, the cup knob kind and the dive.~~ Cut (R9).
68. ~~The Well: every tank's game saved between launches.~~ Cut (R9).
69. ~~The Well: the deadlock checker and its table to Jack.~~ Cut (R9).
70. Albums: a route (a distributor and its account) for releasing each pack's music, the account kept in
    `HANDOFF.private.md`.
71. Vortex and charybdis, free: the lab's swirl played on the phone (does a swirl seam read through the cores?), then
    vortex's own design round; charybdis's orbit solver (a reach table per crank tick), its shared-slot rule and its
    own design round.
   Vortex merged 2026-10-25 (PR #22). Jack's calls (2026-10-25): the rim cue is knob (V1), but not its ticks (V2:
   "I actually don't like the ticks at all as a method of showing the tank will swirl."), so the swirl's cue is
   breath (C1), merged 2026-10-25 (PR #30); the swirl meets seized knobs in charybdis, where dragging the tank's edge
   always swirls it (V4, the charybdis rule under round 3); the table stands as provisional (V5); vortex has a
   picture family of its own (V6), all three of isobars, ephemeris and cords (P1), merged 2026-10-25 (PR #28); a
   swirl on all five layouts (V3, round 4). Charybdis's orbit solver is not started.

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
- Kept in git: four README images in `docs/images/`, 440 px wide as WebP, 40–55 KB each: `grid-d2-right-half`
  (the mechanic, mid-drag), `level05` (sunset), `level27` (deep hex) and `nightmare24-chainmail`, Claude's suggestion,
  which Jack kept.
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
- **Should a paid tier include undos?** Jack doubts it (2026-09-28): a player who pays for a premium version
  probably doesn't want more "cheats", and payers are likely the better players. Claude's view: in free-to-play
  generally, the most engaged players do buy help at the hardest content (inferred, no figures); but in Unstir an undo
  only saves replaying, since resets are free, so it is weak value, and selling help clashes with the earned ladder.
  Fans pay for more of what they love: new tanks, pictures and mechanics. So undos stay free (+2 per playing day),
  and the paid side is packs, the archive and support.

## Set aside, with reasons

These are recommendations against, not Jack's calls, unless the entry says so. Keep every entry: if one is picked
back up, note the date and why.

### R1 — Premium only ($2–5 up front)

Clean, and suits the crafted look. But few people download paid apps, and a new name with nothing to try first makes
that worse. Revisit if Apple features the game, or if testers say they would pay up front.

Revisited 2026-10-24 in the options comparison: still set aside. It is the one option that keeps Jack's tier rule
completely.

### R2 — Sell undo packs

The undo bank makes this the obvious in-app purchase. It was set aside because a puzzle built on careful, clean solves
would feel like it was selling the answers, and reviews punish that. Daily refills keep the bank without the sale.

### R3 — Rewarded ads or banner ads

The highest possible revenue, but it breaks the clean-solve feel, looks like the clones this game has to stand apart
from, and works against Apple featuring. Revisit only if the unlock plus the daily both clearly fail.

Picked back up 2026-09-28: Jack ruled out the unlock. Undos are never sold: everyone gets +2 a playing day, capped
at 10. The paid side is picture packs with their own tanks, an archive of past dailies, a supporter mark and a tip
jar. Rewarded ads that grant undos stay in reserve.

Revisited 2026-10-24 in the options comparison: still in reserve, for the trigger Jack set (banks running dry).

### R4 — Picking the model before TestFlight

Pricing depends on how often players return and how far they get. Choosing now would be a guess.

Revisited 2026-10-24: TestFlight can't measure who would pay (its purchases are free sandbox ones), so the comparison
recommends a shape now, Unstir+, and says which tester numbers would change its contents.

Revisited again 2026-10-24: Jack's call puts packs in v1, so Unstir+ is superseded. The recommended shape is now packs
at one price with a Complete bundle (decision 4 under "Packs: the catalogue"; not decided).

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

### R7 — Picking an overlapped rod by the finger's first motion (set aside 2026-09-29)

Built on `touch` on 2026-09-29: in an overlap the finger held nothing until it had moved 8 pt, then the rod whose
tangent best fitted that motion, falling back to the nearest centre within a 15° tie, and a late pick caught up at
most 10°. Jack, on the phone: "much more unpredictable... chooses wrong more often than not". The first ~1.3 mm of a
touch is mostly the finger rolling as it presses, not the turn it means, and a simulation showed noisy first motion
hands 20–40% of overlap touches to another rod. Replaced the same day by the nearest rod where the finger lands.
Claude's view: revisit only if the log's landing points show that rule picking wrong often.

### R8 — Fine graduation ticks for a drag's count (dropped 2026-09-29, Jack's call)

A hairline mark per step on the disc's hairline, the step just reached brightest. Jack, on the phone: "too faint and
thin". He liked the dashes they replaced, only not so prominent, so the dashes came back lighter (2 pt at 0.85, no glow
or band).

### R9 — Pack candidates benched (2026-10-24)

- **The Well** (cut by Jack, 2026-10-24, after the film): "I don't actually think The Well is compelling. Not good enough for free, let alone paid." It was a hex tank whose six rods each held a cup, a smaller tank played under free-tier rules and dived into, about 13
  tanks over days; the largest build in the catalogue (nested `Game`s, cups baked to textures, a deadlock checker) for a
  pack Jack finds uncompelling. Its nested-tank dive stays here in case a later pack wants it.
- **Orrery as a pack** (Jack, 2026-10-24): its orbits go to charybdis as a free tier instead.

The two entries above are Jack's calls. The rest were benched in drawing up the pack catalogue ("Packs: the
catalogue"): Claude's recommendations against, not Jack's calls.

- **Orrery.** Its independent orbits are maelstrom generalised (maelstrom is orbits with every working knob at one
  rate), so they are reserved for charybdis, the free rung beyond maelstrom, with its crank and shared-slot rule
  (recommended; decision 2).
- **Coriolis.** One-way knobs make a wrong lift cost moves to carry away, against Jack's call that a wrong stir turned
  straight back stays free (Jack, for now, 2026-09-28). And they are maelstrom made harder, the line charybdis takes
  with orbits. No longer offered to charybdis.
- **Marbled.** Building towards a target needs the oldest, least readable stir first with nothing healing to confirm
  it (R5's crank flaw), and its "trace" fix turns it back into plain unstirring. Its making-and-sharing appeal goes to
  free sharing.
- **Duet.** A chord leaves the read unchanged (amounts still come from solo probes), small dependency graphs let greedy
  pairing reach par, two thumbs cover the picture being read, and its fix, a two-player mode, is a different product.
- **Relief.** Charging blind players for the only version of the game they can play is wrong, and its sighted half
  (the crater illusion) is a thin twist on reading up. Recommended as a free "Eyes Shut" mode once a blind tester
  confirms a prototype.
- **Abyss.** Rationing light subtracts from the read. Unlimited pings sweep the tank and bring back R5's memory flaw,
  rationed ones make a budget puzzle no buyer asked for, and store stills are black.
- **Drift.** A flow field turns every core into an arrow, so amounts are trivial while seam order can't be read; a
  still line layer underneath makes it a skin. It fails every still frame and shuts out Reduce Motion players. Its
  winter hook suits a free seasonal daily.
- **Riptide.** A clock on authored charts is peril rising within a tank, which Jack ruled out for the music (peril
  rises only from tier to tier, 2026-09-29) and which the feel he set for it ("no pressure", 2026-09-29) rules out for
  play. A memorised chart stops being a read, and rhythm buyers expect far more than three tracks.
- **Postcards.** It is the growth engine, and charging the sender taxes the loop that recruits players. Recommended as
  a free feature after v1, receiving always free, with the solver's per-core readability check.
- **Cascade.** Three systems stacked (pours, gifts, a brim per pool) read as bookkeeping, a gift no clip can show,
  Escapement's small buyer again, and the largest refactor of any candidate (a `Game` per pool).
- **The Cabinet.** The sealed tank removes every picture and commit signal, so it is a combination lock entered
  through rods, and its cipher craft is unrelated to stirring.
- **The Loom.** Once the period is found every level is "record, crank". Its Zachtronics buyer needs solution
  histograms (Game Center or a server) and is the logic buyer Escapement serves.
- **Gallery.** Public-domain paintings on plughole's rules are new pictures on old rules, which compete with endless,
  and painted swirls as camouflage frustrate more than they test. Its broad, featurable role goes to First Stir.
- **Rose Window.** Forgiveness offers no real decision (a forgivable bottom entry is invisible, and a visible one
  mid-stack must be zeroed to free what lies under it), a win with a rod still turned reads as a bug, and the petal
  compound is R5's geared rods.
- **Frozen rod (lab f9ff424).** An iced core keeps showing the tank as dealt, so it hides its own rod's progress and
  leaves the ring to read alone. It subtracts from the read (Abyss's flaw), adds no decision, costs a second shader
  pass masked to the core, and is no read aid, since what it keeps is the scramble. Not a pack and not a rung (vortex
  has the swirl).
- **Rush (lab ed17a0a).** Five minutes against a clock is pressure, against the feel Jack set for the game's music
  (2026-09-29: "no pressure, no crescendo, no rising danger"), read here as a rule for play too and the reason Riptide
  is benched. Tanks dealt from endless's generator are endless's job. Speed and competitive players are left out on
  purpose by that reading.
- **A commutator pack** (considered for the twisty-puzzle buyer). In Unstir every entry comes off by its own inverse,
  so a commutator is only a detour (a push that later merges, the Problems candidate's cut Key chapter), rare and
  found only by a bounded search (par is the solver's bounded optimum, not a proof). Cube solvers are named
  Escapement's second buyer instead.

### R10 — Options Jack passed over on the review page (2026-10-25)

Jack's calls, round 3 under "Jack's calls on the pitch".

- **Maelstrom's last levels adding the swirl** (vortex's option A for the swirl with seized knobs): Jack chose
  charybdis.
- **Two bands for swirl and turn** (the glass's edge swirls, the bezel turns the tank, as built for vortex's "both"):
  superseded by Claude's reading of his note on the charybdis rule (one gesture that always swirls), pending his
  confirmation; not an option he passed over. Its code is charybdis's starting point.
- **The tick dial as the swirl's cue**, seated on dark strokes or as pure hairlines: "I actually don't like the ticks
  at all as a method of showing the tank will swirl."
- **Bands and glyphs as the rim cue**: Jack picked knob.
- **Shelving Lens for Prism, or keeping the soft zoom** (the reviewers recommended shelving): Jack chose to try the
  hard lens.
- **Escapement's live preview** (recommended) and no warning: Jack chose the standing hint.
- **Escapement's seal ticking on to +2, or blaming the knob**: Jack chose freeze on the +1.
- **The shelf as a row under the strip, or a place past maelstrom** (B was recommended): Jack chose the dock of live
  covers.
- **Icon candidates 2 and 3** (3, the whole-tank swirl, was recommended): Jack chose 1, the neon grid.
