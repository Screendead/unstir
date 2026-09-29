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
| Business-model recommendation | Jack ruled out paying to unlock tiers (2026-09-28). Jack wants **picture packs with their own tanks** as paid content, best with new mechanics; an archive of past dailies, a supporter mark and a tip jar are agreed (2026-09-28). Undos are never part of the paid side: free for everyone at +2 per playing day (see "Thoughts"). Packs stay outside the ladder and never open a tier. Rewarded ads for an undo top-up stay in reserve, only if TestFlight shows banks running dry. A single "Unstir+" purchase may not be needed |
| Monetisation code | None. No StoreKit, ads or sharing in `Sources/` |
| Undo bank | Starts at 10 (`Best.undos` in `Sources/Levels.swift`). Jack's call (2026-09-28): everyone gets +2 for each day they play, so a long absence doesn't refill it; Claude assumes the cap stays 10. Built on `help` (2026-09-29, `Best.refill`): the first opening of a level other than the sandbox on a local calendar day later than the last refill's adds 2, up to 10, and a "+2" shows over the undo count once the level's opening ends or is skipped. A fresh install records its first day without a refill; a clock moved back never refills. Jack (2026-09-29): setting the phone's date mustn't game the refill. Closed on `help` (2026-09-29, `Best.trustedNow`): within one boot the day comes from the last time it vouched for plus the uptime since (`CLOCK_MONOTONIC_RAW`, which counts sleep and can't be set), so a clock set ahead refills nothing until real time reaches the next day, give or take 5 min, and the log says `undo refill held: clock ahead Xh`. The anchor follows the wall clock no further ahead than drift explains (a second plus 100 ppm of the uptime since), so creeping the clock ahead a few minutes at a time gains about a second an opening; review found the first version let each step under 5 min carry the anchor along, a day ahead in about 290 steps (fixed 2026-09-29). Still open: a restart between date changes still borrows a refill, since a new boot has nothing to check against. A trusted network clock would close that; Claude recommends against it (a server, and a refill that waits on the network, to guard 2 undos a day). Unverified whether it is the only way: `kern.monotonicclock` is a candidate, a clock XNU's `clock.c` says nothing can set, and on a Mac it runs on across restarts. Unchecked on iOS: whether the app may read it, and whether setting the date moves it. The launch logs it next to the uptime (`monotonic clock Ns` or `unread`), so launches either side of a restart and of a date change answer both; if it holds, reckoning from it would close the restart hole. Unverified: whether iOS lets the app read the boot session (`kern.bootsessionuuid`); an app in macOS's App Sandbox reads it, but `container.sb` leaves it off its sysctl allow list, and iOS's profile is unpublished. The phone's log answers it at launch (`boot session read` or `unread`). Unread, a jump of at least the phone's uptime at the last level opened passes as a possible restart, and a believed jump anchors at the uptime then; so on a phone up less than a day, as after any restart, steps of a day get through one after another until a level opens with the phone up longer than the step. A genuine forward correction of more than 5 min within a boot (a phone that ran slow, set right) is held too, so its refill day turns late by that much until the next restart; one under 5 min is believed, and the anchor takes it in a few seconds a day. A new boot whose clock reads more than 5 min before the anchor's time, as after a clock reset, is believed but leaves the anchor, so setting the clock right later in that boot still counts as a new boot (review found the first version held every refill until the next restart there; fixed 2026-09-29). Not covered: a clock behind at the first opening with no anchor stored (a fresh install, or the first on this build), then set right, makes refills late by that much until a restart. The privacy manifest TestFlight will need (UserDefaults already requires one) should give reason 35F9.1 for the uptime clock: Apple's boot-time list names `systemUptime` and `mach_absolute_time()`, not `clock_gettime`; if the `kern.monotonicclock` read stays, check whether it needs a reason too |
| TestFlight | Not started |
| CI | Tests every pull request (merged 2026-09-28). First run 4 min 37 s, close to the 5-minute line. `scripts/ci-usage.sh` reports spend. CodeQL (`codeql.yml`, replacing GitHub's default setup, which never built) scans the workflows on every PR, and Swift on merges to `master` and weekly (Jack, 2026-09-28): the Swift build takes about 17.5 min under CodeQL. Free, since the repo is public; if it ever goes private, each Swift scan costs about 190 of the 2,000 minutes. So every PR's CodeQL check reads "1 configuration not found" (master has a Swift scan, a PR doesn't): expected, and it blocks nothing. `actions/checkout` is on v7, since v4's Node 20 is deprecated. |
| `master` ruleset | Jack turned off "require code scanning results" and "require code quality results" to unblock PR #2. Claude's view: with Swift scanned only after merges, requiring code scanning on PRs would gate only the workflow files, so leave it off until the server code exists, then scan that on every PR and require it; leave code quality off, as its run fails on GitHub's side ("requested model is not supported") and whether it covers Swift is unchecked. Revisit it with the server code |
| Difficulty tiers | Backgrounds merged 2026-09-28 (PR #2). Jack chose the turning tank for the top tier, new levels for it, a renamed ladder and an easier switch (2026-09-28); the first slice, the turning tank and seized knobs, merged 2026-09-28 (PR #4); see "Side task" below |
| Performance pass | Queued after the difficulty tiers (Jack, 2026-09-28); see below |
| Architecture pass | Queued after the performance pass (Jack, 2026-09-28); see below |
| Media out of git | Done 2026-09-28: history rewritten, re-signed and force-pushed; `.git` went from 311 MB to 264 KB; see below |
| README | Merged 2026-09-28 (PR #3), with the four suggested images (Jack's pick); still says Nightmare and Nightmare+, so it changes with the rename; see below |
| Copyright headers | Decided (Jack, 2026-09-28): every code file names Jack in full as the copyright holder, 2026. His name is public already (the commit email's domain). Merged 2026-09-28 (PR #3); see below |
| Sound | Jack wants a bespoke soundscape, music and effects (2026-09-28). Tools agreed (Jack, 2026-09-28): everything synthesized from scratch in Csound (Homebrew), with no samples or stock loops; MuseScore 4 only if a written tune is wanted later, with a Muse Sounds Pro licence if its audio ships; GarageBand has no scripting and Audacity adds nothing. Claude can't hear, so Jack listens at the end of every round. Two sketches (Python): "glass and water" and "neon hum". Jack played both on the phone in a prototype (branch `sound`, uncommitted) and chose **glass** (2026-09-28), asking for quieter effects against the music, neon's low synth hum brought in, music on the menu, and a sound for every button. Round 2 is built (2026-09-29): Csound sources in `sound-src/`, rendered and measured by `scripts/sounds.sh`; a detuned saw hum in D under every bed; a heal about 8 LU over its bed (the phone-speaker model says 10–12); beds for the menu and each tier, crossfading over 1.5 s between screens and stepping aside while another app plays music; tap, tier-switch, undo and reset sounds. It is committed locally on `sound` with a temporary "glass · sketch · off" switch for comparing on the phone, and waits for Jack's listen before a PR. Open for Jack: whether undo feels late (its body peaks about half a second after the press); whether undoing a heal should step the heal notes back (Claude's recommendation; today it doesn't); in endless, a solve that is also one over par plays the solve (Claude's pick). Rule: a sound never tells the player anything the picture doesn't, so nothing sounds during a drag and a heal's pitch follows heals done, never heals left. Claude recommends building it in after the new level set and before TestFlight; not decided |
| Apple Developer membership | See `HANDOFF.private.md` |

### The plan

1. **TestFlight with 20–50 strangers.** Watch whether they get the goal without help, where they get stuck, and
   whether they come back for the daily. Day-2 return is the number to watch.
2. **A share line for the daily result**, Wordle style (e.g. `Unstir #142 · 7 moves (par 6)`). The daily generator
   already exists; the sharing does not.
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
| The way in | Jack chose the strip (2026-09-28) from three working mock-ups (strip, dial, window), for its ticked line of the levels left to open the next tier; he loved the window's live tank but it took too much of the screen. Built on `tiers` with the rename and the gate; the swipe was driven by simulated touches, never a finger. The swap freezes 50–107 ms on the simulator: left for the performance pass |
| Rename | Nightmare is now **whirlpool** and Nightmare+ **maelstrom** in code, harness (`UNSTIR_TIER`), scripts, tests and docs, on `tiers`. Stored level ids stay `N<k>` and `N+<k>`, so progress carries over (Claude first planned new ids, which would have reset it; the review caught that). The new maelstrom set gets fresh ids, so old N+ bests don't land on new levels |
| Solver and the maelstrom set | Solver built and verified on branch `solver` (2026-09-29). An independent brute force found a push that holds a disc still and beats plain untwisting by a move, so the optimum now adds a bounded search for such detours: par is the solver's bounded optimum, not a proof. The park rule has two readings (fewest dead knobs over rings with a seam, or every dead knob over a ring without one) and two tie-breaks; Jack's pick is open, and the proposed set is fair under all four. A first proposed table passed every check but its early planning gap came from a tie-break (a lucky guess of direction scores par), its first ten levels all turn counterclockwise, and its seized pairs were always neighbours; a second version is being made against those |
| The phone | Free again after the first playtest (Jack, 2026-09-28). It has the sound prototype and the temporary seized table. Next install: the touch fixes with round 2's sound, prepared overnight 2026-09-29 without installing (Jack asked for no phone use while he slept) |

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
  wrong rod costs a notch in endless; heals absorb the odd one. The capacity (4 in the film) waits for TestFlight.
  **The look** (Jack): the measuring jug on the real rim, filled with the picture's own colours (the only look whose
  single frame read as a level to a viewer who didn't know it), with the tide's outward-spreading colour and vibrancy,
  which Jack loves, grafted on. The tide itself failed on the real rim: even at 1.5x thickness a viewer read the band
  as a thick bezel, and another took it for the picture shrinking. Jack approved the graft's film (2026-09-28: "very
  nice"): each notch arrives as the picture's colour spreading across the rim behind a glint, and a glow off the
  filled arc grows as the room runs out. Still open, from two cold reads: the spill swells the whole rim instead of
  pouring over the lip at twelve, the rim goes pastel just after it, and "spilled." is easy to miss.
- Switching between tiers must be easier to find than today's header toggles, and on-brand. Jack's idea: stir
  between modes. He chose the strip (see the table).
- Order of work: the go/no-go slice (`turning-tank`), the switcher as mock-ups for Jack to pick, the rename, then the
  level set, whose table (layout, depth, seized knobs, par, planning gap, picture) goes to Jack before it is written
  into `Levels.swift`.

**The first playtest (2026-09-28, a playtester on Jack's phone, loving it).**
- Touching where two discs overlap, you can't tell which rod will move. Today the nearest centre wins and the only
  cue (a dashed ring and the start notch) sits under the finger. Claude's recommendation: light the grabbed rod the
  moment a finger lands (disc outline, knob glow, a light haptic); in an overlap, let the first few points of motion
  pick the rod whose turn explains them (near the lens tips the two turns' directions differ by about 95° on quad);
  near the line between the centres they coincide, so fall back to the nearest centre.
- "I can't remember how far I've turned it." Claude's recommendation: while dragging, an arc from the start notch
  lights one segment per 30° step, with a signed count placed away from the finger; it stays faint while the move is
  still open, so a re-grab of the same rod carries on the count. It reports only the player's own turns, so it is
  not a hint. It was within one drag, and Jack likes the fix (2026-09-28). Both fixes are built on `touch` (2026-09-29): in an
  overlap the first 8 pt of motion pick the rod, and a late pick jumps the rod at most 10° so it can't commit a step on
  its own. Near a lens tip on tri, eye and hex a third disc joins in, and motion more than about 15° off a tangent goes
  to the rod the finger is deepest in; how that feels needs the phone.
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
