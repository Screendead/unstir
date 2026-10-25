# Handoff — Unstir

*Updated 2026-10-25. Audience: the next agent, or Jack. This file holds the current task: the plan, where it stands,
open thoughts, and the options set aside. Update it when a step closes or a call is made. Git holds the history. The repo is public: personal and account
details go in `HANDOFF.private.md`, which is gitignored.*

## The current task: take Unstir to market

Find out whether the game is worth releasing commercially, and if it is, how to price it and get it noticed. So far
this is analysis. No code has changed for it.

### Where things stand

| Item | State |
|---|---|
| Competitor scan | Done 2026-09-28, quick pass (see below) |
| Business-model recommendation | Jack ruled out paying to unlock tiers (2026-09-28). Jack wants **picture packs with their own tanks** as paid content, best with new mechanics; an archive of past dailies, a supporter mark and a tip jar are agreed (2026-09-28). Undos are never part of the paid side: free for everyone at +2 per playing day (see "Thoughts"). Packs stay outside the ladder and never open a tier. Rewarded ads for an undo top-up stay in reserve, only if TestFlight shows banks running dry. A single "Unstir+" purchase may not be needed |
| Monetisation code | None. No StoreKit, ads or sharing in `Sources/` |
| Undo bank | Starts at 10 (`Best.undos` in `Sources/Levels.swift`). Jack's call (2026-09-28): everyone gets +2 for each day they play, so a long absence doesn't refill it; Claude assumes the cap stays 10. Built on `help` (2026-09-29, `Best.refill`; merged 2026-09-29, PR #9): the first opening of a level other than the sandbox on a local calendar day later than the last refill's adds 2, up to 10, and a "+2" shows over the undo count once the level's opening ends or is skipped. A fresh install records its first day without a refill; a clock moved back never refills. Jack (2026-09-29): setting the phone's date mustn't game the refill. Closed on `help` (2026-09-29, `Best.trustedNow`): within one boot the day comes from the last time it vouched for plus the uptime since (`CLOCK_MONOTONIC_RAW`, which counts sleep and can't be set), so a clock set ahead refills nothing until real time reaches the next day, give or take 5 min, and the log says `undo refill held: clock ahead Xh`. The anchor follows the wall clock no further ahead than drift explains (a second plus 100 ppm of the uptime since), so creeping the clock ahead a few minutes at a time gains about a second an opening; review found the first version let each step under 5 min carry the anchor along, a day ahead in about 290 steps (fixed 2026-09-29). Still open: a restart between date changes still borrows a refill, since a new boot has nothing to check against. A trusted network clock would close that; Claude recommends against it (a server, and a refill that waits on the network, to guard 2 undos a day). Unverified whether it is the only way: `kern.monotonicclock` is a candidate, a clock XNU's `clock.c` says nothing can set, and on a Mac it runs on across restarts. Unchecked on iOS: whether the app may read it, and whether setting the date moves it. The launch logs it next to the uptime (`monotonic clock Ns` or `unread`), so launches either side of a restart and of a date change answer both; if it holds, reckoning from it would close the restart hole. Unverified: whether iOS lets the app read the boot session (`kern.bootsessionuuid`); an app in macOS's App Sandbox reads it, but `container.sb` leaves it off its sysctl allow list, and iOS's profile is unpublished. The phone's log answers it at launch (`boot session read` or `unread`). Unread, a jump of at least the phone's uptime at the last level opened passes as a possible restart, and a believed jump anchors at the uptime then; so on a phone up less than a day, as after any restart, steps of a day get through one after another until a level opens with the phone up longer than the step. A genuine forward correction of more than 5 min within a boot (a phone that ran slow, set right) is held too, so its refill day turns late by that much until the next restart; one under 5 min is believed, and the anchor takes it in a few seconds a day. A new boot whose clock reads more than 5 min before the anchor's time, as after a clock reset, is believed but leaves the anchor, so setting the clock right later in that boot still counts as a new boot (review found the first version held every refill until the next restart there; fixed 2026-09-29). Not covered: a clock behind at the first opening with no anchor stored (a fresh install, or the first on this build), then set right, makes refills late by that much until a restart. The privacy manifest is written (`Sources/PrivacyInfo.xcprivacy`, branch `privacy-manifest`): UserDefaults with CA92.1 and system boot time with 35F9.1. Apple's required-reason pages (developer.apple.com, "Describing use of required reason API" and the `NSPrivacyAccessedAPIType` page, read 2026-10-25) list `systemUptime` and `mach_absolute_time()` under boot time and no `clock_gettime`-family call or sysctl, so `clock_gettime_nsec_np`, `kern.bootsessionuuid` and `kern.monotonicclock_usecs` are not on the list; 35F9.1 is declared anyway, inferred as harmless and as the nearest fit, since the uptime clock measures elapsed time and never leaves the device |
| TestFlight | Not started |
| CI | Tests every pull request (merged 2026-09-28). First run 4 min 37 s, close to the 5-minute line. `scripts/ci-usage.sh` reports spend. CodeQL (`codeql.yml`, replacing GitHub's default setup, which never built) scans the workflows on every PR, and Swift on merges to `master` and weekly (Jack, 2026-09-28): the Swift build takes about 17.5 min under CodeQL. Free, since the repo is public; if it ever goes private, each Swift scan costs about 190 of the 2,000 minutes. So every PR's CodeQL check reads "1 configuration not found" (master has a Swift scan, a PR doesn't): expected, and it blocks nothing. `actions/checkout` is on v7, since v4's Node 20 is deprecated. |
| `master` ruleset | Jack turned off "require code scanning results" and "require code quality results" to unblock PR #2. Claude's view: with Swift scanned only after merges, requiring code scanning on PRs would gate only the workflow files, so leave it off until the server code exists, then scan that on every PR and require it; leave code quality off, as its run fails on GitHub's side ("requested model is not supported") and whether it covers Swift is unchecked. Revisit it with the server code |
| Difficulty tiers | Backgrounds merged 2026-09-28 (PR #2). Jack chose the turning tank for the top tier, new levels for it, a renamed ladder and an easier switch (2026-09-28); the first slice, the turning tank and seized knobs, merged 2026-09-28 (PR #4); see "Side task" below; vortex, the swirl tier between whirlpool and maelstrom (Jack, 2026-10-24), is built with 27 provisional levels on the local branch `vortex`; see "Vortex (provisional, 2026-10-24)" |
| Performance pass | Queued after the difficulty tiers (Jack, 2026-09-28); see below |
| Architecture pass | Queued after the performance pass (Jack, 2026-09-28); see below |
| Media out of git | Done 2026-09-28: history rewritten, re-signed and force-pushed; `.git` went from 311 MB to 264 KB; see below |
| README | Merged 2026-09-28 (PR #3), with the four suggested images (Jack's pick); the rename updated it to plughole, whirlpool and maelstrom (PR #7); see below |
| Copyright headers | Decided (Jack, 2026-09-28): every code file names Jack in full as the copyright holder, 2026. His name is public already (the commit email's domain). Merged 2026-09-28 (PR #3); see below |
| Sound | Jack wants a bespoke soundscape, music and effects (2026-09-28). Tools agreed (Jack, 2026-09-28): everything synthesized from scratch in Csound (Homebrew), with no samples or stock loops; MuseScore 4 only if a written tune is wanted later, with a Muse Sounds Pro licence if its audio ships; GarageBand has no scripting and Audacity adds nothing. Claude can't hear, so Jack listens at the end of every round. Two sketches (Python): "glass and water" and "neon hum". Jack played both on the phone in a prototype (branch `sound`, uncommitted) and chose **glass** (2026-09-28), asking for quieter effects against the music, neon's low synth hum brought in, music on the menu, and a sound for every button. Round 2 is built (2026-09-29): Csound sources in `sound-src/`, rendered and measured by `scripts/sounds.sh`; a detuned saw hum in D under every bed; a heal about 8 LU over its bed (the phone-speaker model says 10–12); beds for the menu and each tier, crossfading over 1.5 s between screens and stepping aside while another app plays music; tap, tier-switch, undo and reset sounds. It is committed locally on `sound` with a temporary "glass · sketch · off" switch for comparing on the phone, and waits for Jack's listen before a PR. Open for Jack: whether undo feels late (its body peaks about half a second after the press); whether undoing a heal should step the heal notes back (Claude's recommendation; today it doesn't); in endless, a solve that is also one over par plays the solve (Claude's pick). Rule: a sound never tells the player anything the picture doesn't, so nothing sounds during a drag and a heal's pitch follows heals done, never heals left. Claude recommends building it in after the new level set and before TestFlight; not decided |
| Apple Developer membership | See `HANDOFF.private.md` |

### The plan

1. **TestFlight with 20–50 strangers.** Watch whether they get the goal without help, where they get stuck, and
   whether they come back for the daily. Day-2 return is the number to watch.
2. **A share line for the daily result**, Wordle style (e.g. `Unstir #142 · 7 moves (par 6)`). The daily generator
   already exists. Built on `daily-share` (2026-10-25, `Sources/Share.swift`): a share button on the daily's card, a
   square per move in its flash's colour, practice named as such, no URL yet (`Share.url`). Open for Jack: the first day,
   daily #1 (`Share.firstDay`, today as a placeholder; options in the PR).
3. **3–5 short clips** of a picture snapping back, recorded with `scripts/film.sh`, posted to TikTok, Reels and Shorts.
   See whether anyone cares before spending money.
4. **Choose the model from what testers do**, then set up the App Store page, preview video and a featuring request.

### Recommended model (Jack ruled it out, 2026-09-28: he won't put tiers behind a purchase)

Free, with one purchase that unlocks the rest (full campaign, Nightmare and Nightmare+, endless). The daily stays free
for good because it is the marketing. Undos refill daily and are never sold.

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
| Vortex (the swirl) | Jack's calls 2026-10-24: the whole-tank swirl is the tier vortex, between whirlpool and maelstrom, and the rim must show what it does before a move. Built on the local branch `vortex` (not pushed, no PR): the swirl layouts, the rim grab, the tier and its gate, the swirl's lesson, the solver's `interacts` pruning, three rim-cue variants for Jack to pick from, and 27 provisional levels. See "Vortex (provisional, 2026-10-24)" below |
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

**Vortex (provisional, 2026-10-24).** Built on the local branch `vortex` (cut from `master` at dbc776a; not pushed, no
PR): the swirl as a mechanic, the tier, the solver's handling of it, three ways for the rim to show what it does, and
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

**What is built.**
- **The swirl** (`Layout.swirls`: `triSwirl`, `quadSwirl`, `eyeSwirl`, `pentSwirl`, `hexSwirl`): the base layout's rods
  plus one last rod of radius exactly 1 at the centre, so the glass's edge never moves. It merges like any rod, commutes
  with nothing but hex's hub (same centre), turns with the tank onto itself, and is never seized. Left out of
  `Layout.allCases`, so the frozen generator, the dailies and the sandbox never see it.
- **The grab.** Swirl only: from 0.93 of the radius out over the bezel to 25 pt beyond. Seized knobs only: unchanged.
  Both: the glass's own edge band (0.86 to 1.0) holds the swirl, the bezel and beyond turn the tank.
- **The tier.** Whirlpool all at par opens vortex; vortex all at par opens maelstrom. Ids `V1`–`V27`. Its own menu
  colours (violet to teal). Rows on a swirl layout read "4 rods + swirl".
- **The lesson.** A thin cyan arc at the bottom on the swirl's ticks inside the glass, with a ghost finger there, until
  the first swirl stir commits (`Best.swirled`), beside the tank's amber one outside the bezel where knobs are seized:
  each points at its own ring (a cold review found both had pointed at the bezel). It hides while the swirl is held. A
  cold first touch where the rim does both (`film.sh rim-knob-both-cold`) lands on the ticks and holds the swirl.
- **The solver.** It prunes by which rods' maps interact (`interacts`), so the hub and the swirl commute: hex's provisional
  level went from 2027 stacks in 2.2 s to 8 in 81 ms. `solve.sh` takes the swirl layouts and refuses a seized swirl.
  Every player's play on swirl levels, seized knobs included, empties a real `Game`. A randomised check (5398 swirl
  scrambles of 2–3 entries, half with a knob seized) found nothing shorter than the optimum.
- **What the rim does, before a move** (Jack's call above), three variants on `UNSTIR_RIM`, each for swirl only, glass
  turn only and both, shot as `rim-<variant>-*` (27 shots):
  - `knob` (default, Claude's lead): the swirl gets a knob's dial just inside the glass's edge (cyan hairline ring, 11
    ticks and a longer 1 pt pointer at twelve, turning with it), its ticks leaning as a shear leans them, and further
    the way a held turn goes, so they read as a swirl and not a dial; where knobs are seized the bezel becomes knurled
    steel, its ridges faintly amber at rest (the tank's colour), that turns with the glass, on every seized level. A
    dark groove (the picture's outer 5 pt) parts the ticks from the knurl, so "both" no longer reads as one dive-watch
    bezel. **For Jack, a trade-off against the hairline rule:** each tick and the swirl lesson's arc sit on a 3–3.5 pt
    dark stroke, and the groove darkens the picture's last 5 pt, so the ticks read on busy pictures (marbling, coral).
  - `bands`: the swirl's grab outlined in cyan (its wash and slanted hatch dropped: they hid the picture's outer ring),
    an amber bezel for the tank, matching the lessons' colours.
  - `glyphs`: two 28 pt icons above twelve (a spiral; a ring with a red slash and a two-headed arc). It says both
    controls exist, not which band does which.
  **Awaiting Jack's pick.** Claude recommends `knob`: it uses the game's own language (a knob is what you turn) and
  keeps the picture clean.
- **The swirl's own marks, under every cue** (Claude's calls, 2026-10-25): a push flashes red as a 0.5 pt hairline on
  the `knob` cue's ring, 5 pt inside the glass's edge, where a knob's flashes on its own dial (`rim-knob-swirl-push`
  film); over a red picture it is faint, the price of the hairline rule. A held swirl's dashes run inside the cue's
  ticks and pointer, and its count sits inside them on the far side from the finger, as a knob's sits off its disc
  (`rim-knob-swirl-held`, `-held-low`, `-turned`). The result card's "next" is vortex's own blue (`Tier.glow`, the
  middle of the menu's violet → blue → teal walk; `vortex-result`).

**How the set was made.** `scripts/vortex-levels/pools.sh` deals seeded scrambles on each swirl layout with the frozen
generator (`Layout.scramble`, unchanged; the dailies never pass it a swirl layout), keeping only those whose optimum
equals their entry count and which plain untwisting reaches, one band per depth and hidden-stir budget;
`scripts/vortex-levels/pick.py` then takes, slot by slot, the lowest seed that meets the slot. Every row was then
checked with `scripts/solve.sh`: optimum = entries, no detour, planning gap 0 (`testVortexParIsTheOptimum`, slow, pins
it; `testVortexTable` pins the rest). Maelstrom's rules, translated:
- **Planning gap.** It doesn't apply: with no knob seized the tank never turns, so no lookahead is optimal and the gap is
  0 on every level. Vortex is a reading tier, like whirlpool, and climbs in depth, hidden stirs (`Layout.inversions`),
  swirls per level, hidden swirls and how many rods ride on the newest swirl.
- **First turns never more than two the same way** becomes the newest swirl's undo: never the same direction three
  levels running. And within a level, from four stirs on, no more than two thirds go one way, so undos can't be
  guessed by direction (the generator dealt one tri level all counterclockwise).
- **Fair under every park reading** holds trivially: no seized knobs, so both parkings untwist.
- **Neighbours never share a picture.** Whirlpool's live pictures (not the twins, which are maelstrom's), with
  whirlpool's limits: glass opens each layout and takes the finale, coral only to 6 stirs, neurons to 14, marbling
  deep. Each tank is four taps as dealt.
- **The swirl taught early on small tanks.** Quad first (V1 kept as it was, so its note and the rim shots stand), then
  tri and eye, then pent and hex, each layout opening easier than the last one's showpiece. A swirl of 240° (8 steps)
  is rare: none before V6, then at most a third of a level's swirls. No two levels open on the same three stirs.

Levels (**par** = entries = the solver's optimum; **hidden** counts the stirs no louder than what they covered, swirls among them in brackets; **swirls** lists their sizes in steps, newest first; **over the newest** is how many rods ride on the newest swirl; **its undo** is the direction that takes it off; **seed** is the band and seed that dealt it):

| Level | Layout | Par | Hidden (swirls) | Swirls, newest first | Over the newest | Its undo | Picture | Title | Why | Seed | Scramble |
|---|---|---|---|---|---|---|---|---|---|---|---|
| V1 | quad | 2 | 0 (0) | +4 | 0 | ccw | glass | The rim is a rod too. | The lesson: the swirl alone on top (the placeholder's V1, kept, so the rim shots stand) | fixed #- | `0:+3,4:+4` |
| V2 | quad | 3 | 0 (0) | -7 | 1 | cw | coral | Something stirred after the rim. | A rod stirred after the swirl: the rim isn't always first off | quadSwirl-3-0 #13 | `0:+4,4:-7,3:-8` |
| V3 | quad | 4 | 0 (0) | +4 | 3 | ccw | chainmail | The rim went first. | The swirl at the bottom: three rods ride on it, and it comes off last | quadSwirl-4-0 #17 | `4:+4,3:-5,2:-8,0:+2` |
| V4 | quad | 5 | 0 (0) | +7 +3 | 0 | ccw | coral | Twice round the rim. | Two swirls, the newest on top | quadSwirl-5-0 #48 | `3:-2,4:+3,1:-5,0:+6,4:+7` |
| V5 | quad | 6 | 1 (1) | -4 -7 | 1 | cw | neurons | Quiet at the edge. | The first hidden stir, and it is a swirl | quadSwirl-6-0 #25 | `0:-4,4:-7,1:+8,3:+3,4:-4,0:+5` |
| V6 | quad | 8 | 2 (1) | -2 -7 -4 | 0 | cw | marbling | Taylor turned the outer cylinder too. | Quad's showpiece: three swirls, two stirs hidden | quadSwirl-8-0 #148 | `4:-4,3:+6,4:-7,3:+8,1:+4,2:-8,0:-3,4:-2` |
| V7 | tri | 5 | 1 (0) | +6 -5 | 0 | ccw | glass | Three rods, and the rim makes four. | Tri opens easier: every disc reaches the rim | triSwirl-5-0 #1 | `1:+4,3:-5,0:-8,1:-4,3:+6` |
| V8 | tri | 6 | 2 (1) | -5 -5 | 0 | cw | coral | Every disc reaches the rim. | Two swirls of one size, one of them hidden | triSwirl-6-0 #145 | `2:-4,3:-5,2:-6,0:+8,2:+8,3:-5` |
| V9 | tri | 8 | 2 (2) | -6 -6 +2 | 0 | cw | chainmail | The rim carries every seam with it. | Tri's showpiece: three swirls, two hidden | triSwirl-8-0 #51 | `3:+2,2:+3,1:-6,0:+7,2:-8,3:-6,1:-8,3:-6` |
| V10 | eye | 7 | 2 (0) | +7 +4 | 2 | ccw | glass | Big rods, small rods, one rim. | Eye opens easier, its swirl two deep | eyeSwirl-7-1 #35 | `0:-2,4:+4,2:+6,0:-4,4:+7,0:-8,2:-6` |
| V11 | eye | 8 | 2 (2) | -3 +6 +4 | 0 | cw | neurons | Free vortex, forced vortex. | Three swirls, two hidden, on mixed sizes | eyeSwirl-8-1 #7 | `0:-2,4:+4,2:+7,4:+6,0:+7,3:-8,2:-2,4:-3` |
| V12 | eye | 10 | 3 (2) | +5 +7 -4 | 1 | ccw | marbling | Read the edge before the middle. | Ten stirs, three hidden | eyeSwirl-10-1 #127 | `3:-4,4:-4,1:+7,3:-8,2:-3,4:+7,0:+8,3:+4,4:+5,0:+6` |
| V13 | eye | 12 | 4 (2) | -5 -6 +8 +4 | 1 | cw | chainmail | Small on big, inside the biggest. | Eye's showpiece: four swirls | eyeSwirl-12-1 #430 | `4:+4,1:+6,3:-7,4:+8,0:+5,2:-8,3:-2,1:-8,4:-6,1:-8,4:-5,2:+6` |
| V14 | pent | 8 | 2 (1) | +4 +4 | 3 | ccw | glass | Five rods and a rim. Still no middle. | Pent opens easier, its swirl three deep | pentSwirl-8-2 #10 | `2:-3,5:+4,4:-5,3:-7,5:+4,4:-5,3:+4,4:-6` |
| V15 | pent | 10 | 3 (1) | +8 -5 -3 | 2 | ccw | neurons | Angular momentum, handed back. | Three swirls, the newest under two rods | pentSwirl-10-2 #96 | `3:+4,2:-7,1:+2,5:-3,4:+5,5:-5,4:+7,5:+8,3:-8,1:-2` |
| V16 | pent | 12 | 3 (1) | -8 -6 -2 | 3 | cw | chainmail | Under the rim, over the rim. | Three swirls, the newest under three rods | pentSwirl-12-2 #327 | `4:+2,0:-2,5:-2,4:+3,3:+5,0:-3,5:-6,0:+7,5:-8,4:-2,1:-2,3:+5` |
| V17 | pent | 13 | 4 (1) | +8 -4 +4 -3 | 2 | ccw | marbling | Kelvin would like his circulation back. | Four swirls | pentSwirl-13-3 #2 | `2:+3,5:-3,3:-2,0:-2,5:+4,1:-7,0:+3,5:-4,3:+6,2:-7,5:+8,3:-5,2:+7` |
| V18 | pent | 14 | 4 (2) | -4 -5 +8 -6 | 0 | cw | neurons | Quiet at the edge, loud in the middle. | Four swirls, two hidden | pentSwirl-14-2 #716 | `2:+4,5:-6,3:+8,2:-8,0:-4,4:-5,5:+8,4:-4,5:-5,4:+8,2:-4,1:+7,2:-8,5:-4` |
| V19 | pent | 16 | 5 (1) | -8 +6 -4 -4 | 4 | cw | chainmail | Ekman layers, politely ignored. | Four rods over the newest swirl | pentSwirl-16-4 #175 | `5:-4,3:-3,4:-3,2:+2,1:-2,5:-4,1:+6,2:-7,5:+6,4:+7,1:-2,5:-8,4:+8,2:+3,1:+4,2:+6` |
| V20 | pent | 18 | 6 (4) | +7 -8 +7 -3 +2 | 0 | ccw | marbling | Rankine vortex, by hand. | Pent's showpiece: five swirls, four hidden | pentSwirl-18-4 #382 | `4:+2,0:-2,2:+2,4:+4,5:+2,2:-5,0:+2,5:-3,1:-6,5:+7,3:-8,1:-2,5:-8,4:-8,2:+4,1:-6,2:+8,5:+7` |
| V21 | hex | 12 | 3 (2) | -4 +4 +4 | 3 | cw | glass | The hub and the rim keep out of each other's way. | Hex opens easier; the hub and the swirl come off in either order | hexSwirl-12-3 #136 | `7:+4,1:-7,7:+4,3:+5,5:+2,0:+2,6:+4,4:-2,7:-4,0:-6,3:-8,6:-3` |
| V22 | hex | 14 | 4 (2) | -8 -2 -5 | 2 | cw | chainmail | Seven rods and a rim. Same rule. | Hex, three swirls | hexSwirl-14-3 #67 | `3:-3,2:+6,4:+2,7:-5,1:-8,7:-2,3:-5,1:-4,4:+7,0:+8,6:+7,7:-8,3:-2,1:-3` |
| V23 | hex | 16 | 4 (1) | +4 -6 -7 -7 | 1 | ccw | marbling | Bathtub vortex, either hemisphere. | Four swirls | hexSwirl-16-4 #54 | `1:+4,0:-5,7:-7,5:-8,2:-4,4:+3,3:+3,0:+6,7:-7,5:+8,4:-5,7:-6,3:+8,5:+2,7:+4,6:-5` |
| V24 | hex | 18 | 5 (3) | -4 +3 +2 -6 | 1 | cw | chainmail | Forced core, free edge. | Four swirls, three hidden | hexSwirl-18-3 #23 | `2:-4,6:+2,7:-6,5:+2,7:+2,2:+5,7:+3,6:-6,3:-3,4:+5,1:+7,3:-8,5:+2,6:-8,2:+8,4:-2,7:-4,2:+6` |
| V25 | hex | 20 | 6 (2) | +6 -5 -6 -8 -4 | 0 | ccw | glass | Spin-down takes longer. | Five swirls | hexSwirl-20-4 #54 | `1:+4,6:-2,7:-4,3:-7,7:-8,5:+3,6:+5,0:+8,7:-6,5:+3,3:+3,7:-5,5:-8,2:+3,1:+5,2:+8,3:-7,1:+4,2:-8,7:+6` |
| V26 | hex | 22 | 7 (3) | -8 +7 -6 -3 +7 | 3 | cw | marbling | Stir the stirrer. | Five swirls, three hidden | hexSwirl-22-6 #311 | `6:-4,3:-4,5:+5,0:+6,7:+7,5:+8,3:-2,6:-4,7:-3,1:-3,7:-6,6:+8,3:+2,7:+7,6:-8,4:+4,2:+3,3:+6,7:-8,0:-8,2:-3,5:-3` |
| V27 | hex | 24 | 8 (2) | +8 -4 -8 -3 -2 -6 | 1 | ccw | glass | The vortex, unstirred. | The finale: 24 stirs, six swirls | hexSwirl-24-5 #375 | `4:+3,1:-2,7:-6,1:-3,7:-2,0:-4,2:+6,1:+4,6:+5,1:+7,0:-8,6:+4,7:-3,0:+6,5:-7,3:+3,7:-8,0:+6,1:+3,7:-4,1:-7,3:-3,7:+8,5:-8` |

**Swirl and seized knobs together: a separate proposal, not in the set.** Vortex has no seized knob: seizing is
maelstrom's lesson, and it comes after. Both together already work (the grab, both lessons, every cue variant's "both"
shots, and the solver's plays empty a real `Game` with a knob seized on every vortex level). Two options:
- **A. Maelstrom's last few levels add the swirl** (say M25–M27 on `hexSwirl`, the hub and a ring knob or two seized):
  the tier that teaches the tank's turn ends by combining it with vortex's control, which the player already knows.
  The swirl is a slot the tank turns onto itself, so it never parks and never seizes; whether it makes planning harder
  (it carries every seam round with it) or only longer needs the solver's gap measured on candidates.
- **B. Leave both for charybdis**, the tier past maelstrom, as its new skill.
Claude recommends **B for now**: maelstrom's set has just been rebuilt and playtested (PR #17), and A would reopen it
before vortex has had one playtest. Revisit A if charybdis needs a different mechanic.

**What the tier needs before it's final.**
- **Jack's playtest** of the 27 levels on the phone; the titles are drafts.
- **Its picture family.** Whirlpool's live pictures for now, on Claude's call: the step up comes from the rule, as for
  maelstrom's twins. The swirl's shear at the edge reads strongly on glass, chainmail and marbling in the shots;
  coral and neurons with the swirl were not checked beyond `shots/vortex*.png`. A family of its own (as maelstrom's
  twins), or plughole's grid, whose "up" would show the swirl's turn of the core, are the alternatives.
- **Its sound bed** (the `sound` branch has a bed per tier; vortex has none).
- **The rim variant** (above).
- **Tri and eye**: whether they read with a swirl is Jack's call from `shots/swirl-tri.png`, `shots/swirl-eye.png` and
  V7–V13. Each block drops out whole (V7–V9, V10–V13) and the slots move to pent and hex.
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

### R2 — Sell undo packs

The undo bank makes this the obvious in-app purchase. It was set aside because a puzzle built on careful, clean solves
would feel like it was selling the answers, and reviews punish that. Daily refills keep the bank without the sale.

### R3 — Rewarded ads or banner ads

The highest possible revenue, but it breaks the clean-solve feel, looks like the clones this game has to stand apart
from, and works against Apple featuring. Revisit only if the unlock plus the daily both clearly fail.

Picked back up 2026-09-28: Jack ruled out the unlock. Undos are never sold: everyone gets +2 a playing day, capped
at 10. The paid side is picture packs with their own tanks, an archive of past dailies, a supporter mark and a tip
jar. Rewarded ads that grant undos stay in reserve.

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
