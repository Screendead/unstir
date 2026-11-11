# Handoff — Unstir

*Updated 2026-11-09. Audience: the next agent, or Jack. This file holds the current task: the plan, where it stands,
open thoughts, and the options set aside. Update it when a step closes or a call is made. Git holds the history. The repo is public: personal and account
details go in `HANDOFF.private.md`, which is gitignored.*

## The current task: take Unstir to market

Find out whether the game is worth releasing commercially, and if it is, how to price it and get it noticed. The store,
the share line, the privacy manifest and TestFlight prep are merged (2026-10-25); Lens, Escapement and Prism are built and on the Release shelf (PRs #52, #65, #59 and #67 to #71); First Stir is out of v1.

### Where things stand

| Item | State |
|---|---|
| Competitor scan | Done 2026-09-28, quick pass (see below) |
| Business-model recommendation | Jack ruled out paying to unlock tiers (2026-09-28). Jack wants **picture packs with their own tanks** as paid content, best with new mechanics; an archive of past dailies, a supporter mark and a tip jar are agreed (2026-09-28). Undos are never part of the paid side: free for everyone at +2 per playing day (see "Thoughts"). Packs stay outside the ladder and never open a tier. Rewarded ads for an undo top-up stay in reserve, only if TestFlight shows banks running dry. A single "Unstir+" purchase may not be needed. Options compared 2026-10-24 (below): Claude recommended one "Unstir+" purchase (the daily archive, endless past a free taste, the supporter mark) as 1.0's product, with packs from 1.1. **Jack's call (2026-10-24): packs ship at v1; there is no hurry to market** ("I think we can handle making packs for v1. I'm not in a major hurry to get it to market."). That supersedes the Unstir+ recommendation. Jack's calls on the pack catalogue (2026-10-24, below): **v1 ships First Stir, Lens and Escapement**; Claude draws First Stir's art; packs at one price beside a Complete bundle, no Unstir+, endless wholly free, no tip jar, no offer codes; Orrery's orbits become charybdis, a free tier; **The Well is cut**. The catalogue is now First Stir, Lens, Escapement, Prism and Music Box (only if it passes its ear test) |
| Monetisation code | StoreKit 2 for the packs and Complete merged 2026-10-25 (PR #21); the daily share line merged 2026-10-25 (PR #24). Prices are Jack's call (2026-10-25): 2.99 a pack, 5.99 Complete. No ads |
| Undo bank | Starts at 10 (`Best.undos` in `Sources/Levels.swift`). Jack's call (2026-09-28): everyone gets +2 for each day they play, so a long absence doesn't refill it; Claude assumes the cap stays 10. Built on `help` (2026-09-29, `Best.refill`; merged 2026-09-29, PR #9): the first opening of a level other than the sandbox on a local calendar day later than the last refill's adds 2, up to 10, and a "+2" shows over the undo count once the level's opening ends or is skipped. A fresh install records its first day without a refill; a clock moved back never refills. Jack (2026-09-29): setting the phone's date mustn't game the refill. Closed on `help` (2026-09-29, `Best.trustedNow`): within one boot the day comes from the last time it vouched for plus the uptime since (`CLOCK_MONOTONIC_RAW`, which counts sleep and can't be set), so a clock set ahead refills nothing until real time reaches the next day, give or take 5 min, and the log says `undo refill held: clock ahead Xh`. The anchor follows the wall clock no further ahead than drift explains (a second plus 100 ppm of the uptime since), so creeping the clock ahead a few minutes at a time gains about a second an opening; review found the first version let each step under 5 min carry the anchor along, a day ahead in about 290 steps (fixed 2026-09-29). Still open: a restart between date changes still borrows a refill, since a new boot has nothing to check against. A trusted network clock would close that; Claude recommends against it (a server, and a refill that waits on the network, to guard 2 undos a day). Set aside, unverified: `kern.monotonicclock`, a clock XNU's `clock.c` says nothing can set, which on a Mac runs on across restarts, is a candidate for closing the restart hole. Unchecked on iOS: whether the app may read it, and whether setting the date moves it. The launch's probe of it, and of the uptime, was dropped in PR #78, since the log can leave the phone, so the restart hole stays open; if it is picked back up, probe it on a Debug build only. Unverified: whether iOS lets the app read the boot session (`kern.bootsessionuuid`); an app in macOS's App Sandbox reads it, but `container.sb` leaves it off its sysctl allow list, and iOS's profile is unpublished. The phone's log answers it at launch (`boot session read` or `unread`). Unread, a jump of at least the phone's uptime at the last level opened passes as a possible restart, and a believed jump anchors at the uptime then; so on a phone up less than a day, as after any restart, steps of a day get through one after another until a level opens with the phone up longer than the step. A genuine forward correction of more than 5 min within a boot (a phone that ran slow, set right) is held too, so its refill day turns late by that much until the next restart; one under 5 min is believed, and the anchor takes it in a few seconds a day. A new boot whose clock reads more than 5 min before the anchor's time, as after a clock reset, is believed but leaves the anchor, so setting the clock right later in that boot still counts as a new boot (review found the first version held every refill until the next restart there; fixed 2026-09-29). Not covered: a clock behind at the first opening with no anchor stored (a fresh install, or the first on this build), then set right, makes refills late by that much until a restart. The privacy manifest is written (`Sources/PrivacyInfo.xcprivacy`, merged 2026-10-25, PR #20): UserDefaults with CA92.1 and system boot time with 35F9.1. Apple's required-reason pages (developer.apple.com, "Describing use of required reason API" and the `NSPrivacyAccessedAPIType` page, read 2026-10-25) list `systemUptime` and `mach_absolute_time()` under boot time and no `clock_gettime`-family call or sysctl, so `clock_gettime_nsec_np`, `kern.bootsessionuuid` and `kern.monotonicclock_usecs` are not on the list; 35F9.1 is declared anyway, inferred as harmless and as the nearest fit, since the uptime clock measures elapsed time and never leaves the device |
| TestFlight | Prep merged 2026-10-25 (PR #23): version 1.0 (1), the export-compliance key, an asset catalog. The icon is candidate 1, the neon grid (Jack, 2026-10-25), already the placeholder in the catalog. No archive script until Jack's developer account is in Xcode |
| CI | Tests every pull request (merged 2026-09-28). First run 4 min 37 s, close to the 5-minute line. `scripts/ci-usage.sh` reports spend. CodeQL (`codeql.yml`, replacing GitHub's default setup, which never built) scans the workflows on every PR, and Swift on merges to `master` and weekly (Jack, 2026-09-28): the Swift build takes about 17.5 min under CodeQL. Free, since the repo is public; if it ever goes private, each Swift scan costs about 190 of the 2,000 minutes. So every PR's CodeQL check reads "1 configuration not found" (master has a Swift scan, a PR doesn't): expected, and it blocks nothing. `actions/checkout` is on v7, since v4's Node 20 is deprecated. Over the line since: #21 ran 5m44s, #23 5m36s and #26 5m11s. Jack's calls (2026-10-25): watch it, then cache the build, and the line moves to 7 minutes. The cache merged 2026-10-25 (PR #29): `test.yml` keeps the StoreKit test build (`build/store`) between runs, keyed on the Xcode build and the sources, and stamps each file with a time drawn from its content, so a hit compiles nothing. It saves about 30 s, but the build is not where CI's time goes: the job ran 5m13s cold and 5m18s warm, as the simulator's boot, install and tests vary by about 90 s from run to run. A warm-up build on each merge to `master` (PR #31) was closed on Jack's call (2026-10-25, round 6): the compile runs inside the simulator's boot, so it saves nothing. Jack's call CI1 = A (2026-10-28, round 10): keep and watch, noting each run's time; if two runs in a row pass 7 minutes, build the split (the core tests on PRs, the StoreKit tests and the long pack suites nightly on `master`; a break could show a night late)). **Fired and built (2026-10-29, PR #63):** runs of 7:14, 7:37, 7:59, 8:04 and 9:12 passed 7 minutes. Measured on #63's first run: `testNoVignetteShowsTheNextMove` 129 s, `StoreTests` about 72 s, everything else under 20 s a suite. PRs now skip `StoreTests` and `FirstStirTests`; `nightly.yml` runs all tests but the `UNSTIR_SLOW_TESTS` ones on `master` (they ran past 25 minutes on the runner, so they stay local); PR run 9:12 to 5:12. Jack's call (2026-11-01): the line moves to 10 minutes, the job's timeout, after #79 ran 7:17 alongside #85's build. The Test steps now run with pipefail (`shell: bash`, PR #126, merged 2026-11-02). Before that a failing test left the job green; only a compile error turned it red. The same PR measures the app after the tests in both jobs (`scripts/app-size.sh`, APPSIZE = B) and fails past 100 MB; its push was a cold build, 6m50s, as the workflow files are in the cache key. On 2026-11-03 #140's job ran 10:00 and was cut off once at 10:25, the Test step 270 to 556 s across the day's runs: the ci-time call (recommended B, split build and test), under Round 16's build. **Probe of the slow test start (`r17-ci-probe`, measured 2026-11-09, Nightly dispatches 42674467014, 42675933640, 42677351967; one runner each, so thin):** per job, boot step / Test step's wait before "Testing started" / tests / boot+Test. PR flow (boot, `bootstatus`, then `test-store.sh test-without-building`), four runs: 101/40/165/308 s, 103/105/97/309, 107/116/97/323, 103/138/126/375. No boot wait, three: 6/218/109/334, 17/110/300/430, 7/152/353/515 (once with Spotlight off: 6/140/105/252). Spotlight off, once: 108/132/113/357. An xctestrun with Spotlight off, once: 93/61/145/301. One small suite run three times on one booted simulator (run 42674467014): about 63, 38 and 31 s before its tests (the third by xctestrun). Reading: the wait before testing starts (40 to 138 s after a full boot) is real and varies run to run; not waiting for the boot only moves it and slowed the tests in two of three runs; Spotlight and an xctestrun showed nothing in one run each; a second launch on the same simulator starts faster, so part of it is first-launch cost. None of it explains or bounds the wait, so CLAUDE.md's "not yet explained" stands. Recommendation (not decided): keep the PR flow as is. The numbers are recorded here, so the probe branch can be dropped. |
| `master` ruleset | Jack turned off "require code scanning results" and "require code quality results" to unblock PR #2. Claude's view: with Swift scanned only after merges, requiring code scanning on PRs would gate only the workflow files, so leave it off until the server code exists, then scan that on every PR and require it; leave code quality off, as its run fails on GitHub's side ("requested model is not supported") and whether it covers Swift is unchecked. Revisit it with the server code |
| Difficulty tiers | Backgrounds merged 2026-09-28 (PR #2). Jack chose the turning tank for the top tier, new levels for it, a renamed ladder and an easier switch (2026-09-28); the first slice, the turning tank and seized knobs, merged 2026-09-28 (PR #4); see "Side task" below; vortex, the swirl tier between whirlpool and maelstrom (Jack, 2026-10-24), with 27 provisional levels, merged 2026-10-25 (PR #22); Jack's calls on it (2026-10-25) are in "Vortex (provisional, 2026-10-24)"; vortex's own pictures (isobars, ephemeris, cords) merged 2026-10-25 (PR #28), and breath as the swirl's cue merged 2026-10-25 (PR #30); the swirl shears to its centre (W3, Jack 2026-10-25), on `swirl-map` |
| Performance pass | Closed at #140 (PERF = A, 2026-11-09); the twist-chain cache is set aside, R11 |
| Architecture pass | Queued after the performance pass (Jack, 2026-09-28); see below |
| Media out of git | Done 2026-09-28: history rewritten, re-signed and force-pushed; `.git` went from 311 MB to 264 KB; see below |
| README | Merged 2026-09-28 (PR #3), with the four suggested images (Jack's pick); the rename updated it to plughole, whirlpool and maelstrom (PR #7); see below |
| Copyright headers | Decided (Jack, 2026-09-28): every code file names Jack in full as the copyright holder, 2026. His name is public already (the commit email's domain). Merged 2026-09-28 (PR #3); see below |
| Sound | Jack wants a bespoke soundscape, music and effects (2026-09-28). Tools agreed (Jack, 2026-09-28): everything synthesized from scratch in Csound (Homebrew), with no samples or stock loops; MuseScore 4 only if a written tune is wanted later, with a Muse Sounds Pro licence if its audio ships; GarageBand has no scripting and Audacity adds nothing. Claude can't hear, so Jack listens at the end of every round. Two sketches (Python): "glass and water" and "neon hum". Jack played both on the phone in a prototype (branch `sound`, uncommitted) and chose **glass** (2026-09-28), asking for quieter effects against the music, neon's low synth hum brought in, music on the menu, and a sound for every button. Round 2 is built (2026-09-29): Csound sources in `sound-src/`, rendered and measured by `scripts/sounds.sh`; a detuned saw hum in D under every bed; a heal about 8 LU over its bed (the phone-speaker model says 10–12); beds for the menu and each tier, crossfading over 1.5 s between screens and stepping aside while another app plays music; tap, tier-switch, undo and reset sounds. Round 2 on today's game (2026-10-27, branch `sound-r2`, PR #56): `sound` merged with master and passing every test; the heal's note now counts moves that pop one of the scramble's entries, as endless's brim does; vortex has its own bed (open fifths and a ninth, high sparse pings, water circling three times a loop); every button added since September taps (the consent card, the settings sheet, the pack cards, the dock, the tier-up); a push that fills the brim sounds only as the spill. Jack's call (2026-10-28, SN1 = A): "In, with early undo and step-back heals. Keep the vortex bed." So the undo is the early one (its body peaks about 0.2 s after the press, against September's 0.5 s), an undo steps the heal notes back, and the vortex bed stays; the three temporary switches under the menu's list (`sound`, `undo`, `heal undo`) and the first sketch (`sound-src/sketch.py`, `scripts/sounds.sh sketch`) are gone, applied on PR #56. `scripts/sounds.sh listen <dir>` writes every sound and bed to m4a for a listen off the phone. The sounds add about 9 MB of CAF and AAC to git (rendered from `sound-src/`, so they could be rendered at build time instead, at the cost of Csound in CI). Endless has no par now, so the old question of a solve one over par is gone. The smaller list is closed by round 16 (PR #129, merged 2026-11-02): the detent's tick during a drag is dropped (SND1 = B), cancelling the player's own push flashes white everywhere, magenta and the heavy tap meaning a real heal (SND2 = A), and the share links tap through `ShareButton`, which opens the share sheet itself (SND3 = B). Its side effects went to Jack as snd1-clunk (B, the tank's drag silent too) and snd2-sandbox (the sandbox out of v1), both merged in #133. Escapement's ratchet tick is the steel pawl (soundsk2 = D, #138). A purchase landing on an open card plays the solve's chime and a success haptic since round 13's F38 (PR #81). Rule: a sound never tells the player anything the picture doesn't, so nothing sounds during a drag and a heal's pitch follows heals done, never heals left. Claude recommends building it in after the new level set and before TestFlight; not decided |
| Merged 2026-10-28 and 29 | PRs #55 (the consent link opens and closes its list), #57 (a locked next tier's up-a-notch button opens its gate), #53 (Lens, lenses on rods of every size) and #58 (drag guard) on 2026-10-28; #50 (plughole eased), #56 (sound round 2), #51 (live pack clips), #54 (First Stir's 25 scenes, FS17 C), #60 (v1 without First Stir) and #52 (Escapement's book, the tick budget and the flip counter) on 2026-10-29. Jack's calls on them are in rounds 10 and 11 under "Jack's calls on the pitch" |
| Open PRs and branches (2026-11-08) | None open. Merged 2026-11-08: #144 (the proprietary licence), #145 and #146 (the dock covers), #147 (CI's 15-minute limit), #139 (the tick sounds), #140 (the four-tap budget, `ADAPTIVE_TAPS` on) and #135 (Duo stage 5, the menu beside play); #137 closed, superseded by #140. Merged 2026-11-03: #131 to #134 (round 16's records and follow-up picks, the iCloud picks, the tank's silent drag and the sandbox out of v1), #124 (Duo stage 4), #136 (the archive reads "✕ close" beside the list; the store copy drops the sandbox) and #138 (Escapement's steel ratchet tick, soundsk2 = D). Local, unpushed: `archive/present-probe` (the in-app presentation probe, off #140), `duo-feel` (the bench at every glass size, a playtest-only DuoFeel probe and `scripts/duo-feel.sh`; its frame readout is the display link, which the probe showed sees the render server's misses), `sound-packs` (the pack layers rendered under real play, `scripts/sounds.sh layers`, renders in the tools folder) and `archive/stage5-wip`. Merged on the night of 2026-11-02: #126 (the app-size guard and pipefail), #127 (iCloud sync of bests, behind `ICLOUD = NO`), #128 (store-media fixes), #129 (round 16's play calls) and #130 (Escapement on bone paper). Local, unpushed: `sound-packs` (the ratchet ticks C, D and E for soundsk2). Outside the repo: the Eyes Shut test site, a local repo in the tools folder (`eyes-shut-site`, no remote). Merged late on 2026-11-02: #115, #119 (LG3's leftovers), #121 (store media), #123 (round 16's calls), #120 (Duo stage 2) and #122 (Duo stage 3). Merged earlier on 2026-11-02: #85, #91, #100, #104, #107 to #114, #116 (the Duo's stage 1) and #117 (round 15's calls). Earlier: merged on 2026-11-01 in round 13's merge train, in this order: #81 (`store-polish`), #86 (`taste-end`), #87 (`play-polish`), #83 (`a11y-system`) and #84 (`nav-focus`, the menu's navigation, to-do 74's F1, F2 and F19 to F22); the lanes have their own rows and notes. Merged since 2026-11-01's first list: #74 to #78, #80, #82 (N1's names) and #88. Merged since 2026-10-29's list: #60 (v1 without First Stir, FS17 C), #62 (v1 ships with no analytics, AN1 = A), #64 (the store page and privacy policy, ST1 to ST7 = A), #65 (`esc-hub-flaps`, ES2 = B: each clock's own flip count in its hub, the header their sum), #59 and #67 to #71 (Prism: the prototype, the 30 specimens, colour-blind reading, the GPU bench, the ship PR, plates 3 and 4 as medusae and radiolarians, PL1), #63 and #66 (CI split, nightly without the slow tests), #72 and #73 (below); #61 recorded rounds 10 to 12. Prism is on the Release shelf. The Escapement book still waits on Jack's play on the phone. Local branch `keep-analytics` (the other side of AN1) has no PR |
| Merged 2026-11-01 | PR #72 turned Escapement's pawl to trail the wheel's free turn (it pointed against the turn), and let playtest builds (`scripts/run-ios.sh`) open every pack level with `UNSTIR_UNLOCK=1`, since the phone cannot buy through StoreKit. PR #73 added to-dos 72 to 74: the UI design pass, the level-name audit and the pedantic polish pass |
| Round 13's store lane (2026-11-01, PR #81, `store-polish`) | Built: F13 (a) to (e), F14, F15, F16 (Lens keeps "four issues", now N1b heads its list), F29's restore and version, F34, F35, F36, F38; F13 (f), a stored "asked" date, is not, so the store still stores nothing. A review's fixes are on the branch: the pending pill reads "asked" (F13c's word) and asks again only for the product's own request; a pack waiting on Complete's Ask to Buy says Complete is waiting, its pill buys the pack alone (Claude's reading; master disabled it) and Complete's line waits; an ask again that fails keeps the request pending and says why; the launch's first read never chimes on an open card (F14's "checking purchases…" placeholder on the card is not built); a restore is announced to VoiceOver and said only on its own card; back from a pack's card opened on Complete's returns there, its button reading "‹ Complete" (Claude's call in the merge, `108901c`; Jack kept it, 2026-11-01); an owned Complete card plays on in the first pack with a level left. CI passed on the fixes (2026-11-01). Waiting on: the shots retaken when the Mac is free (those indexed predate N1's titles and Lens's chapters), then Jack's review |
| Round 13's F8, F9, F26, F27 and F28 (PR #83, `a11y-system`) | Built: VoiceOver basics (F8); Reduce Motion where it was missing (F9); the dock's covers and the card's clip held still under the settings sheet, Low Power Mode, a hot phone, 20 s idle or out of sight, carrying on from the frame they held (F26); Lens's halftone bake cached in every build, the opening waiting for its strike (F27); a black launch screen, the log cut after the first frame off the main actor, and a device line (F28). A review's fixes went in on 2026-11-01. Open checks, on a device: the light-appearance cold launch; the halftone's bake time on the oldest phone (the XS, C22), to record in CLAUDE.md's halftone paragraph in place of "unmeasured on a phone"; VoiceOver end to end, the finish taking focus as the card shows among it; the GPU bench (`scripts/gpu-bench.sh phone`). Films to take once the Mac is free: `scripts/film.sh calm-` (the Reduce Motion opening and solve) and the dock waking from idle |
| Round 14's F2 and F3 (`r14-a11y`) | Built: under Reduce Motion every live picture holds one frame (`Picture.rest`, between the twins' beats) and endless's rim cuts to where each change settles, a spill to its end (F2); plughole 01's first open hangs one line under its note, "sound, haptics, colour letters: ⚙ on the menu" (sound for both the music and sounds switches), once (F3). Merged (PR #110). Round 15: R-motion = A (the line leaves out motion, as settings has no motion switch); R-spill = B (the spill's card shows at once under Reduce Motion, on `r15-calls`) |
| Round 12 (decided, 2026-10-29) | AN1 = A (v1 ships with no analytics), EU1 = B (no EU storefronts at launch; revisit when sales cover a business address), PK1 = A (Prism replaces First Stir as the third pack, capped at depth 8), ES2 = B (each hub shows its own flip clock, plus a total counter elsewhere; a hub that reaches 0 shows plainly that it has run out; built on `esc-hub-flaps`), PL1 (Prism's plates 3 and 4 redrawn as Haeckel's medusae and radiolarians). See round 12 under "Jack's calls on the pitch" |
| Round 14's store lane (2026-11-02, branch `r14-store`) | Jack's call M6 = A (all six), this lane's four: promoted purchases (`PurchaseIntent` opens the offer's card and buys there; the four 1024 px images from `scripts/promo.sh`), the supporter mark (to-do 48), "more puzzles in the packs ›" once on maelstrom 27's card, and the known dailies below. The daily archive is lane `r14-archive`; mid-level state surviving a kill is C2, built. `Store.bought` is the one "has the player bought anything" check both lanes read |
| Dailies the solver beats (known, 2026-11-02) | On 4 of 2027's 365 dailies the solver's optimum is one under par (`par` = `scramble.count`): 2027-03-08 hex 14→13, 2027-08-29 pent 12→11, 2027-08-30 pent 13→12 (plain untwisting takes 13), 2027-12-29 pent 10→9 (measured for round 14's gap 1 against the frozen generator). Recorded as known: the generator is frozen (`testDailyVectors`) and stays unchanged (Jack's call M6). A player can finish those four under par; no test pins a daily's par to the optimum |
| Apple Developer membership | See `HANDOFF.private.md` |

2026-10-25 overnight: built for Jack. Six PRs (#19 to #24), three prototypes (`lab-firststir`, `lab-lens`, `lab-escapement`, local) and the shelf mock-ups (`shelf-mockups`, local), each recorded against its item under "To do" in "Packs: the catalogue". Also PR #23, outside the list: TestFlight prep (version 1.0 (1), the export-compliance key, an asset catalog with a placeholder icon, three icon candidates; recommended: 3, the whole-tank swirl; no archive script until Jack's developer account is in Xcode). A trial merge of #19 to #24 in number order onto `master` passes all 146 tests; the conflicts are mechanical (CLAUDE.md prose, harness lines, shot lines, the generated project file). All seven PRs (#15, #19 to #24) are merged into `master` (2026-10-25). Jack answered the review page on 2026-10-25: see round 3 under "Jack's calls on the pitch".

### Open work (finish-and-pitch, 2026-11-09)

The run's list, checked against master at #152. **Decided** (Claude does it): FreshDefaults forgets bests too; the
`shots.sh` index fix for `prism-swatch-white-*` (`scripts/shots.sh:749`); the scrolled pack card under the status bar
(confirm 5cbd45f's mask, then drop to-do 74's line); to-do 74's remaining plain fixes (F13(f)'s stored "asked" date,
F14's "checking purchases…" placeholder, the inventory walked against master); the design pass's decided calls
D1, D2 and D4 (D3's dots wait for the pass's port); ARCH's split of TankView.swift (moves only), then its typed shader
encoder; the duo-feel bench into the repo; the private-repo CI cost and the test step's slow start (ci-time = B);
the owed films and shots retaken on master and attached; handoff housekeeping. **Decided, later in ORDER**: the
String Catalog after the design pass, then the store media retaken. **Decided, waiting on a launch fact**: the Lens
and Prism shader weights (Jack's phone bench), the iCloud flip (the capability), `Share.firstDay` and `Share.url`.
**Answered 2026-11-09** (round 17, `docs/decisions.md`): DESIGN5 = A, CATORDER = D, ESCBOOK = A,
ARCHREST = A, PERF = A, TFREAD = D; their work joins the decided list. **Undecided** (on the page, with what was built):
Lens's art for v1 (draft #157, one panel per option); the pack sound layers (draft #158, filmed in play); the
Ask to Buy date kept and its 24 h wait (#154 as built); F14's checking line; the Duo-speed probe; CI and CodeQL once
the repo goes private (the measured cost is in `HANDOFF.private.md`). **Blocked**: the
owed shots for merged #81, #83, #84 are taken (`~/development/unstir-tools/r17-shots-out`) but Chrome was not
connected to attach them; a dock-waking film needs a new harness hook. Pitch page:
https://claude.ai/artifact/TcJvFtVMBXWgbh589TGYbp, design canvas https://claude.ai/artifact/W99rKP56Wv8Pz1FLvhAqtE. **Jack's to-dos**: the
Escapement book and round 13 and 16 checks on the phone, the phone GPU bench, the developer account and App Store
Connect, the ICO registration, Eyes Shut's hosting and outreach, posting the clips.

**Paused 2026-11-10 at Jack's word, after design change 1 merged (#169).** Merged in wave 2: #156, #159 to #164,
#166 to #169. Open: #165 (String Catalog first half, CI green, not yet reviewed or merged); #157 and #158 wait on
the pitch's picks. Not started: design changes 2 to 5, the catalog's chrome half, the store media retake, the
records (ESCBOOK's J3 to J8 closed, PERF's section to history, ARCH's stale split lines), and this branch's PR. Check
the nightly's StoreTests on #154 (their first run).

**Resumed 2026-11-10 (finish-and-pitch).** The list, against master at #170. **Decided**, in this order on one
chain: #165 brought up to master, reviewed and merged; design changes 2 (five text tones), 3 (one button, three
emphases), 4 (results as dots) and 5 (the menu and result card), a PR each as #169 was; the catalog's chrome half;
the store media retaken (`screens`, `preview`, `social`; `sound` switches the Mac's output, so it is Jack's to run).
Beside the chain: the records (ESCBOOK's J3, J5, J7 and J8 closed, PERF's section to history, ARCH's stale split
lines); the nightly's StoreTests on #154, dispatched on master; `r17-ci-probe`'s finding checked as recorded; the
owed shots attached if Chrome connects; the merged lanes' worktrees removed. **Undecided**, unpicked on the page and
each already built: lens-art (#157), sound-layers (#158), ask-to-buy-date, ask-to-buy-wait, f14-checking, duo-probe,
ci-private, codeql-private; new from #169: whether "unstirred." scales with the type. Nothing is built on their
recommendations. **Waiting on a launch fact**: as above; the Lens shader weight is not in the phone bench's output.

**Answered 2026-11-10** (`docs/decisions.md`; the calls page of that day, 13 calls, each written to stand alone as
CLAUDE.md's "Calls for Jack" now asks). Merged that day: #165 (the catalog's table strings), #171 (five text tones),
#172 (results as dots), #175 (the calls rule). #171 and #172 merged before Jack saw them, which he objected to: a
design PR that changes what the player sees now waits for him with before and after pictures. His picks:
DOTS-KEPT = A, TONES-KEPT = A, BUTTONS = B, STAMP = A, LENSART = B, SOUNDLAYERS = A, ATB-DATE = A, ATB-WAIT = A,
F14 = B, DUOPROBE = A, CIPRIVATE = A, CODEQL-PRIVATE = A. **Not picked**: whether an over-par row shows its "+n"
beside the dots (#174, built, CI green, held). Jack asked instead whether par isn't already perfect on every level;
the answer owed to him is that three dots mean clean (at par on the first try with no undo or reset), two mean at
par, one means solved over par, and the call goes to him again on the next page. **Next, decided**: #173's two
fixes (BUTTONS), shown to Jack before it merges; `r17-stamp` and `r17-f14` brought up to master and opened as PRs
(both change what the player sees, so each waits for him with its picture unless his pick already covers exactly
what the picture showed); #158 brought up to master and merged; Lens's 24 remaining panels in batches on #157;
design change 5 (the menu and result card) stacked on #173; then the catalog's chrome half and the store media
retake; the small-phone check of the taller result card; a checklist page of the phone feel checks owed to Jack;
the merged lanes' worktrees removed. `r17-ci-private` waits for the day the repo goes private, as does deleting
`codeql.yml`. Local branches not pushed: `r17-stamp`, `r17-f14`, `r17-ci-private`.

**Evening of 2026-11-10** (a second calls page, twelve calls, none answered yet; its link is in
`HANDOFF.private.md`). Merged on SOUNDLAYERS = A and F14 = B: #158 (each paid pack's sound layer in play) and
#179 ("checking purchases…" until the store's first read; its text takes the second tone, a little brighter than
the picture Jack saw); and #177 (one catalog escape, invisible). **Built, CI green, held for Jack**, each with real
shots on the page: #173 with BUTTONS's two fixes (a result card too tall for the room steps its own type down,
never below the default, then scrolls; the scroll-only way is on local `r17-ds3-alt`; the pack heading over the
level title gone, with the "‹ levels" button on local `r17-ds3-name-b`); #180 (`r17-ds5b`, design change 5, the
menu and result card, stacked on #173; its fourteen visible changes are in its body; proposal 5.4's lost-card
buttons and the SE's stamp-for-title not built); #178 (STAMP: "unstirred." grows to about 28 pt at xxxLarge, the
Duo tabletop's stays fixed; on an SE at the three largest sizes it crosses the title, as master's fixed word
already touches it; conflicts with #173 in TankView.swift, so whichever merges second takes the other in); #157
(all 25 Lens panels drawn and wired by level number, the picture still `.halftone`, so no stored value or print
changes; Telephoto the weakest; the pack's cover, clip and promo image now show level 3's Magnifying glass; each
panel is cached at 5.5 MB, about 137 MB for all 25, and no bake is timed on a phone); #174 as before. **The
twelve calls**: the over-par "+n" again, with what the dots mean; which pack name goes; step-down or scroll at
xxxLarge; change 5 as built, half or neither; the daily row's streak against its dots; a completion line's colour;
whether "deeper every tank" is said anywhere; tightening three cards that overflow an SE at the default size (the
tier-end card with a locked next tier, the daily's, an at-par replay with a best line); the stamp on an SE; the 25
panels and any redraws; the pack's face; the x8 softness. **Not started, waiting**: the catalog's chrome half (120
escapes left, all in files the held PRs touch: Shelf 41, TankView 18, Menu 18, ResultCard 16, Archive 15, Consent
12); the store media retake (after the design and the panels land); Lens's first-open bake in the phone bench,
then the cache cap as a call. **Raise with Jack**: three PR test jobs ran past ten minutes that evening (10:09,
11:48, 12:11), most of it the simulator's boot and the tests' start. The phone checks owed to Jack are listed on
the page as to-dos (eleven, Escapement's and Prism's playthroughs first). Later that night all five held PRs
took master in and passed CI again. Two more options were built for the page, each on a local, unpushed branch:
`r17-ds5b-streak` (the daily keeps its dots and the streak goes under its title; the taller row then pushes the
menu's "next:" line under the chips as the menu opens, to fix when it is swapped in) and `r17-stamp-below` (on a
short screen whose measured gap under the title is less than 62 pt the word centres between the title and the rim,
shrinking only if it must). #157's bench now bakes three Lens panels cold and prints their times and a panel's
bytes (`scripts/gpu-bench.sh`), so the cache call waits on a phone run of that branch. #179 has no timeout: if the
store's first read never ended, a pack's card would say "checking purchases…" with no buy button. The nightly
was dispatched on master for #179's StoreKit test.

**Answered 2026-11-11** (the evening page's twelve; rows in `docs/decisions.md`). Merged on them: #174 and #157.
The nightly dispatched above failed on #179's new `testOfflineTheFirstReadStillEnds`; a fix branch
(`fix-offline-store-test`) also gives the first read a 5 s limit. The phone bench ran on the 13 Pro Max (thermal
serious): Prism's measured over assumed cost has median 0.89 and max 1.11, the slowest specimen 6.48 of 8.33 ms;
a Lens panel bakes cold in 70 to 227 ms at 1137 px, 5.2 MB cached, 129 MB for all 25, so the cache can be capped
(a call still to put). **Next, decided**: on #173, PACKNAME's button and, in place of the type step-down, the
tank shrinking once a level is solved when the card would not fit (TEXT-NEVER-SHRINKS), on every phone; on #180,
STREAK's row and the spacing under the chips; #178 with `r17-stamp-below`; each shown to Jack before it merges.
Lens: Kaleidoscope as the face (cover, clip, promo image), Telephoto redrawn, the finer lens core. A louder
payoff on finishing a pack or the game is Jack's ask and wants options shown.

**Night of 2026-11-11.** Jack played all 90 paid levels and answered a third page (six calls, all A; rows above
LENSSOFT's in `docs/decisions.md`; link in `HANDOFF.private.md`). Merged since: #183 (the rod's tick back), #184
(the first read's 5 s limit and the offline test), #186 (a pack's loop carries into the next level), #188 (the
share line's dots), #185 (Lens's face). His playthrough notes, each with a lane building options to show him:
**Lens 8, 11, 18** (the three quad levels) are too fine to read: #190 redraws nine panels so a twist reads, held;
the lens-or-twist order stays unreadable on quad, so `lens-offquad` moves the three to other glass as the option.
**Escapement**: the wait (a tap on a clock) is undiscoverable; he would rather the clocks tick only with a rod's
turn, or the wait made unmistakable: `esc-nowait` and `esc-wait-clear` build both. Its one shared picture is
dull: plates for all 30 on `esc-plates-1` (wiring and 1 to 10), `-2`, `-3`. **Prism**: a rod stirred twice shows
the sum of its stirs in its core (nothing, or a wrong count), on 25 of 30 specimens, so no plate fix works (#189,
tools only): `prism-notches-redeal` (no rod stirred twice, par falls) against `prism-aid` (a mark on the drag's
dial, or pips on the knob). **Music**: the layer must play straight through a solve (`music-through`). Also open:
two StoreKit tests fail on an iOS 27.2 simulator (`store-ios27`); a louder payoff on finishing a pack; the six
Prism cost weights the phone bench read over their assumption (prism-25, 27 to 30, 20 and 21 marginal).

### Open work (finish-and-pitch, 2026-11-02)

Closed: moved word for word to `docs/history.md`.

### Round 16's build (2026-11-02 night)

Closed: moved word for word to `docs/history.md`.

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

### iPhone Duo (F10): the staged plan

Jack's calls (2026-11-02): **D-layout = 3** (split play plus the menu beside play), **D-tent = A** (portrait on the
closed display), **D-margin = A** (the 16 pt side margin stays). Closed-display fixes merged (#112). Each stage is a PR
that leaves `master` shippable: the wide layout only reaches windows wider than tall, so no other iPhone changes.

1. **Split play** (`duo-split`): `PlayLayout` (column for tall windows, split at the window's middle for wide ones,
   the glass capped at 1300 px), the play screen's parts laid out by it, `UNSTIR_FRAME` and the `duo-open-*` shots.
2. **Poses**: the tank keeps its identity and glides between column and split (no rebake), a drag in flight is
   cancelled cleanly, the opening, demos and keyframes survive a resize; the fold from `reservedRegions(kind:
   .division)` behind `#available(iOS 27.1, *)`; tabletop (tall and folded: chrome up, tank down).
3. **Round the tank and in the chrome pane**: brim and spill, rim lesson, knurl, lens track, clock hints and the night
   forwards measured against the tank's pane; VoiceOver order (header, title, tank, caption, controls) and Dynamic
   Type in the chrome pane.
4. **Menu, wide**: the list at a readable width, the pack card beside it rather than over it, the dock's covers sized.
5. **Menu beside play** (option 3): the menu stays up in one half while a level plays in the other; back, next and
   focus get their second meaning, and the menu's live covers and tier stir pause beside a playing tank.
6. **Device and store**: the GPU bench at each pose's pixel size, Duo App Store screenshots (1398 × 2034, 2853 × 2007,
   2007 × 2853) from the harness, Split View's sizes; hairlines and the crease on a real Duo (needs a device or tester).

Where it stands (2026-11-03): stages 2 (#120), 3 (#122) and 4 (#124, with Jack's d-calls) are merged, each after an
adversarial review and fixes. Stage 5 (menu beside play) is #135, on Jack's s5 calls (2026-11-03), reworked to
s5-chrome = B (the chrome round the tank), CI green, held on s5b-glass, s5b-words, s5b-title and s5b-back. Round 16
decided stage 5's placement (DUOMENU = B: the tank left, the menu right) and the upright cap (DUOCAP = C), refined by
duocap2 = D and duocap-step = A: the upright glass at 1471 px with iPhone stacks and a four-tap limit of 17 there (#137,
held), which #140's controller replaces, its phone test passed on 2026-11-04 (Round 16's third picks). The headroom numbers are under Round 16's
build, above; stage 6 benches a real Duo.

Stage 2's loose ends: its fix for a touch held across a pose change (`touchStart`, `holding`) is checked by reading the
code only, as no harness path drives an edge touch; a card taller than the tabletop's upright half (large Dynamic Type)
can still reach "unstirred." and the fold. The before and after card shots, by pose, and every review shot are in the
tools folder's `duo/` (stage2, stage3-review, stage4), not attached to the PRs, since Chrome was not connected.

**The critical path (Claude's reading, Jack's to overrule):** stage 5 → ARCH's TankView split →
the design pass. ARCH says "after the Duo stages", read as including stage 5, as it rebuilds the same files; ORDER
scoped the Duo as 2 to 4. The split waited for that; it merged 2026-11-09 (#156, by type, moves only), and the design
pass follows.

Jack's d-calls (2026-11-03): d2-cardpos A, d3-lenscap B, d4-one A, d4-empty A, d4-dock A, d4-table A, d4-pose B,
d4-menuback B.

### The business model and the packs catalogue (2026-09-28 to 2026-10-25)

Closed: moved word for word to `docs/history.md`.

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
    Built on PR #127 (merged 2026-11-02, ICLOUD = A): bests alone, off behind `ICLOUD = NO` until the pre-flip steps.
    Endless's best and started flags don't sync (icloud-endless, icloud-started, recommended to sync).
22. An app-size budget for the bundle (line art baked on the phone, AAC audio), with Background Assets only past it.
    Guard built on PR #126 (2026-11-02): CI's Debug-simulator host, less its test bundle and Xcode's frameworks,
    measures 27.6 MB against Release's 21.9 MB (zipped 11.4 MB); fails past 100 MB, which leaves Release near 94 MB if
    growth is resources. Background Assets still only past the cellular limit (assumed 200 MB; check).
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
    of escapement 1 and a tap skips it; escapement 1 was called "The clock" (Mainspring since N1a, round 13);
    several clocks will tick in turn clockwise from twelve. Left: the ratchet's sound (to-do 45).
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
    Built on PR #130 (merged 2026-11-02, ESC-PAPER = B). The 2 px floor is the picture's; the lines over it stay 0.5 pt
    in ink. Its open points are paper-rm, paper-vermilion, paper-accents and paper-statusbar.
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
   *Closed 2026-11-09 (ESCBOOK = A, round 17):* J3 (already D1's, clockwise from twelve), J5, J7 and J8 as built; Jack's
   play of the book on the phone (E3) still vetoes any one problem.
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
   and replayed on a real `Game`; each key pinned. Problem 1 is the book's "The tick" (so the old
   escapement-1, the mock-up, is now 2); every problem's title is N1's (round 13), Mainspring (N1a, replacing D1's "The
   clock") to Midnight. Escapement now
   has levels past its taste, so it goes on sale on the shelf and its card no longer says more arrive.
   Jack's call J6 = B (round 11): the book ends on the two-clock hex, 30, with the three-clock hex as 29; rows swapped
   and the book re-proved on `escapement-book`. Round 10's question of what a tank lost to its last clock stopping shows
   (`UNSTIR_STOPLOOK`) is superseded by EL1: the budget at 00 is always on screen, so the stamp alone says it; the
   looks stay in the harness, unpicked. Still open from the book: J3 (built as A, D1), J5, J7 (built as A), J8. Closed 2026-11-09 (ESCBOOK = A): J3, J5, J7 and J8 as built.
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
   Round 14, M6: to build, as one of the six marketing builds.
   Built 2026-11-02 on `r14-archive` (PR #108) (confirmed in M6): a row under today's daily, locked until any purchase, opening a
   calendar over the menu. Waits for Jack's look; its implementer calls are listed in the PR under "For Jack".
48. The supporter mark (menu and share line), after any purchase. ~~The tip jar~~ dropped (Jack: "No begging").
    Round 14, M6: to build, with an off switch.
    Built 2026-11-02 on `r14-store` (Jack's call M6, round 14): a still hairline four-pointed glint after the menu's
    title in the tier's sweep and ✦ after the share line's name, with a "supporter mark" switch in settings once a pack
    is owned, on until switched off. Shots `menu-supporter`, `menu-supporter-off`, `menu-no-supporter`,
    `daily-share-supporter`, `settings-supporter`.
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
    The purchase art is built on `r14-store` (2026-11-02): `scripts/promo.sh` renders each sold offer's dock cover at
    1024 x 1024 (Lens, Escapement, Prism and Complete with Release's three). The social cut is still open.
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
    Open, with the age-range check (branch `age-range`, PR #79; Claude's recommendations, not yet Jack's calls):
    **where Apple's sheet shows**: at launch, over the menu with nothing over it, as built, since it interrupts no
    play; the alternatives are after the first level is solved, the first time the menu shows after a level, and
    before the first paid pack opens. **The age gate**: 18 alone, since the answer is dropped and Apple may override
    the gates by region (Texas names under 13, 13-15, 16-17 and 18+). **The questionnaire's "Parental controls, age
    assurance" row**: the game calls the Declared Age Range API and gates nothing, and Apple's definition of age
    assurance, as round 13's legal check quotes it, includes that API, so `docs/store-page.md` answers Yes, marked
    open; either answer keeps 4+.
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
    Round 14, M1 = B2: rename Complete now to a self-limiting bundle, one per three packs; the name goes to Jack as a pitch.
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
    primaries (R, GB, RGB) and R, G and B swatches sit under the caption: holding one draws that channel alone in white
    (in its own colour since round 15, white only under Differentiate Without Colour), an exact read for every kind of colour blindness. Line styles per channel were set aside: Prism samples one layer
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
72. The UI's design pass (Jack, 2026-11-01): the game itself looks right, but the text, buttons, cards and sheets
    around it read unpolished and need a designer's eye, which Claude supplies. Every screen is shot
    (`scripts/shots.sh`), critiqued and redrawn as a design system and mock-ups for Jack's call before any SwiftUI
    changes. Claude Design (now Artifact types in Claude: Design System and Design) is the review surface: Jack
    comments inline on the mock-ups, and Claude ports the agreed design to SwiftUI.
73. A full audit of every level name, tiers and packs alike (Jack, 2026-11-01). Many read as nonsense, as in-jokes
    too technical or niche for a mass market, or as unrelated to their level. They need not all be clever or
    descriptive: a naming system per tier or pack (or one for the game) is welcome. Jack gave philosophers
    ("Aurelius", "Seneca", ...) only as an example of a system, and not a good one, so not that. Ids never change
    (progress is stored by id); only titles and chapter headings. To Jack as a pitch: the audit, the systems and
    one recommendation.
74. The pedantic polish pass (Jack, 2026-11-01): every UI action's behaviour and every edge case, so the app is as
    pleasing and intuitive as it can be, and funnels players to the paid packs without bombarding or begging them.
    Jack's examples: what happens when a player finishes the third (last free) level of a pack they haven't bought,
    and whether the level list scrolls to the right place when the player goes back from a level, finished or not,
    by button or swipe. Plain fixes go in as PRs; each choice of taste or business goes to Jack as a call.
   Round 13's plain fixes for play are on `play-polish` (PR #87): F3, F5, F10, F11, F17, F18, F23, F24, F25, F30,
   F31, F32 and F33. Two lines depart from the inventory's words: endless's first tank says "Eight and it spills."
   (the inventory had "Eight spills."), and after the merge of N1's notes F31's and F32's sentences went in only where
   they add a rule, so M1 reads "One knob has seized. Turn the tank. Turns count as moves." and Escapement chapter 1's
   rule "A clock ticks after every move. Each let-go is a move." Two calls for Jack came out of the review:
   - The daily's "again" (from F18). A retry from the daily's card would save a second solve over its one counted
     try, so the PR leaves "again" off the daily's card, which keeps the daily as it was. The other ways: a retry
     from the card that plays as practice, saving nothing, or one that counts. Recommendation: off, as built. Jack's call P1 = B (2026-11-01): practice, saving nothing; built on `daily-again`, PR #105.
   - Prism's level colour (from F17). Prism's glow is white, so on its levels the number, PRISM and "next ›" are
     about the body text's colour, marked only by a white glow. The options: keep white; the cover's red (FF2A2A);
     or neon cyan. Recommendation: keep white for now, since colour on Prism means a channel and a red or cyan
     "next" would read as one, and settle it in the design pass (to-do 72), which redraws this chrome.
    Built on `nav-focus` (PR #84): F1 (the menu and the pack card open centred on the row left, or after a solve the
    next, its hairline lit once), F2 (back from "up a notch" on the new tier), F19 (the gate lists the levels short
    of par; "level" for "tank"), F20 (a locked row says what opens it; the frontier's hairline stays lit) without its
    "tried", which waits on C3's build, F21 (a switch lands on the frontier, or a locked tier's header; the strip and
    title take the swipe; re-tapping the tier scrolls to its frontier) and F22 (the daily named in words and dealt
    afresh at midnight). The new menu shots in `scripts/shots.sh` still want a simulator run.
    Open, a plain fix for this pass: a pack card scrolled down draws its pill and "restore purchases" under the status
    bar, over the clock (`card-prism-levels`, `card-lens-tried`), since its scroll content runs under the top safe area
    unclipped; it wants a black backing or a mask there. Found in `r13-menu`'s review, outside its lane.

## Side task: the difficulty tiers (started 2026-09-28)

Closed: moved word for word to `docs/history.md`.

## Next: the performance pass (queued 2026-09-28)

Closed at #140 (PERF = A, 2026-11-09): moved word for word to `docs/history.md`. The twist-chain cache is set aside (R11).

## After that: the architecture pass (queued 2026-09-28)

Jack's aim: audit the app's architecture and design for extensibility, maintainability, and the cost of implementing
new features with Opus 5.5 or later.

**What "cost" means for an agent:** how much it must read to make a typical change, how many places a feature
touches, and whether the harness and tests let it check its own work without a person or the phone.

**Starting observations (from the difficulty-tiers work, not yet an audit):**
- `TankView.swift` held `Game`, `LevelView`, the shader modifier and the result card in about 830 lines; #156 split it by type (2026-11-09).
- A new live picture touches six places: `Picture`, a `.metal` file, `LivePictures.swift`, the level table, the tests
  and `shots.sh`.
- The shaders have no tests except the neural web's clearance scan. Their fidelity checks ran in the scratchpad.
- The harness is one flat set of `UNSTIR_*` variables in `UnstirApp.swift`.

**Where it stands (ARCHREST = A, 2026-11-09):** before v1, items 4, 5, 7's shots half and 13; the rest waits until after
v1. Merged 2026-11-09: #156 (TankView.swift split by type), #166 (a typed encoder for the tank shader's arguments),
#164 (one undo record, item 4), #167 (item 5, the shader test kit and exhaustive Picture switches), #161 (item 7's
shots half) and #168 (item 13, First Stir compiled out of Release).

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

**Before the first TestFlight build (remind Jack):**
- Check in with the ICO (LG3 = A): ask whether a home-based sole trader's register entry can show "Address: Withheld",
  then register and pay before the first emailed tester, received log or support email. If the ICO won't withhold the
  address, bring it back to Jack (the fallback was: no fee, send log out, TestFlight's public link only).
- Turn on the Declared Age Range capability in the app's entitlements once the paid team signs the build.
- Before each paid pack ships, send Apple the significant-change notice Texas requires (a new purchase is one).
- Once a year, with the ICO renewal (remind Jack): delete Unstir support mail and logs older than 12 months, and
  complaint records older than two years, as the privacy policy promises.

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

### R11 — Caching the twist chain (set aside 2026-11-09, PERF = A)

The performance pass closed at #140 (its section is in `docs/history.md`). The cache (store the committed chain's
per-tap source points in a texture on each commit, so a frame only samples the picture) is not built: it needs a Metal
path of its own and a texture's precision, and #140's controller already holds 120 Hz by stepping the four-tap budget
down. Pick it back up when testers' logs show a kept budget under 40, or a real Duo misses frames.
