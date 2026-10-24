# Handoff — Unstir

*Updated 2026-10-24. Audience: the next agent, or Jack. This file holds the current task: the plan, where it stands,
open thoughts, and the options set aside. Update it when a step closes or a call is made. Git holds the history. The repo is public: personal and account
details go in `HANDOFF.private.md`, which is gitignored.*

## The current task: take Unstir to market

Find out whether the game is worth releasing commercially, and if it is, how to price it and get it noticed. So far
this is analysis. No code has changed for it.

### Where things stand

| Item | State |
|---|---|
| Competitor scan | Done 2026-09-28, quick pass (see below) |
| Business-model recommendation | Jack ruled out paying to unlock tiers (2026-09-28). Jack wants **picture packs with their own tanks** as paid content, best with new mechanics; an archive of past dailies, a supporter mark and a tip jar are agreed (2026-09-28). Undos are never part of the paid side: free for everyone at +2 per playing day (see "Thoughts"). Packs stay outside the ladder and never open a tier. Rewarded ads for an undo top-up stay in reserve, only if TestFlight shows banks running dry. A single "Unstir+" purchase may not be needed. Options compared 2026-10-24 (below): Claude recommended one "Unstir+" purchase (the daily archive, endless past a free taste, the supporter mark) as 1.0's product, with packs from 1.1. **Jack's call (2026-10-24): packs ship at v1; there is no hurry to market** ("I think we can handle making packs for v1. I'm not in a major hurry to get it to market."). That supersedes the Unstir+ recommendation. Claude's pack catalogue (2026-10-24, below) recommends five packs and a capstone, with First Stir, Lens and Escapement at v1, every pack at one price beside a Complete bundle, no Unstir+ and endless wholly free; four calls are open for Jack; not decided |
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

### How Unstir makes money: options compared (Claude's recommendation, 2026-10-24; not a decision)

Analysis only; no code changed. Every claim is tagged **E** (evidence, with its source: this file, the code, or a
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
until Jack decides; the four calls it needs are under "Open for Jack: four decisions". Analysis only; no code changed.
"Checked" marks a claim checked against the code; "assumed" marks one that wasn't, platform facts included. No
revenue figures.

#### The catalogue

Five packs and a capstone for the life of the game. Each changes what the player reads (Lens: scale against a dot
screen; Prism: three colour lights; Music Box: the ear), how a move works (Escapement: a clock rod that ticks after
every move) or what the evening is (First Stir: a story told backwards). The Well comes last, nesting the free
ladder's rules. The Orrery candidate's orbits go to charybdis instead, if Jack agrees (decision 2).

Jack's call puts packs in v1, so v1 launches three, one per kind of change:
- **First Stir**, the flagship, on audience and feel alone, since its puzzles are plughole depth and test no new skill.
- **Lens**, the new read. It is built first because its map already runs in the lab, so it proves the shelf, StoreKit
  and the pack pipeline.
- **Escapement**, the new move, for problem and cube solvers.

After v1, at about one a quarter: Prism, then Music Box only if it passes its ear test, then The Well.

Each pack has 24 to 30 crafted, solver-checked levels (134 over the five, plus The Well's 13 tanks, beside the 81
free), its own id prefix, its own pictures and layer of the one piece, its first levels free and one price. None ever
opens a tier. If Music Box fails its gate, the catalogue stays at four packs and The Well, whose cups use free rules,
so its count never depended on the packs.

#### The packs

Scores are Claude's: design / engineering / market, higher better on each.

| # | Pack | Kind | Buyer | Rule | Skill | Role | Scores |
|---|---|---|---|---|---|---|---|
| 1 | First Stir | New evening | Story-first players (Florence, Gorogoa, Unpacking, A Short Hike) and plughole players | Plughole rules; each heal plays a vignette of one night, told backwards | None new | v1 flagship | 5 / 7 / 8 |
| 2 | Lens | New read | Comic and pop-art readers; core players after plughole | Some rods zoom or spiral instead of turning | Reading scale against a dot screen; three seam shapes | v1, built first: proves the pack pipeline | 8 / 7 / 7 |
| 3 | Escapement | New move | Chess-problem and logic-puzzle solvers; cube solvers; maelstrom finishers | A clock rod ticks a step after every move | Tempo: timing heals so the clock finds its seam; knowing when to wait | v1, the new move | 8 / 5 / 6 |
| 4 | Prism | New read | Photographers, designers and colour people; whirlpool players | Each rod stirs only some of red, green and blue | Reading by channel; commutation that depends on colour | First after v1 | 7 / 7 / 7 |
| 5 | Music Box | New read | Music lovers, hummers, music-box collectors, Animal Crossing and ASMR players | Pins on tracks, played by a sweeping arm; a stir garbles the tune | Melodic error-finding | Later, only if it passes its ear test | 6 / 5 / 6 |
| 6 | The Well | Capstone | Players who want one project over days; completionists | Each outer rod's core holds a smaller tank, played under free rules | Dependency planning across nested puzzles | Released last; needs no other pack | 7 / 5 / 7 |

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
  Two Clocks, Wound Back (a clock ticking −1), Grand Complication (deep pent and hex, ending on a three-clock hex
  finale), each opening on a wordless teaching problem. After each solve the composed line replays. Problems 1 to 3
  free. Level ids `escapement-1` to `escapement-30`; every problem ships proved (a line at N exists and none is
  shorter).
- **Weakest point.** The smallest, most demanding buyer and the hardest content to make: 30 composed problems, each
  proved by a pruned search that may not reach N on hex, a lost state harsher than any tier, and a paper page that
  breaks the shelf's neon.
- **R5 fix.** It revives R5's "a telegraphed second stirrer" (its queue works as an answer key, and it adds animation
  to every move), and fixes both. The clock queues nothing: always the same +1 on one rod, known before the first
  move, so it shows nothing about the scramble. Its only animation is one tooth and one 30° step of E's own core per
  move.

##### 4. Prism (recommended first after v1)

The picture is one engraving drawn three times in red, green and blue light, and each rod stirs only some of the
colours: unstir until every coloured ghost snaps back into one white line.

- **Role.** The first release after v1, the colour half of the Optical Bench candidate. Its depth is capped until the
  performance pass's cached chain lands.
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
- **Look.** Botanical and architectural engravings (a fern, seed heads, a cathedral elevation, a clock movement) in
  fine lines. Misregistered, each splits into red, green and blue ghosts, with cyan, magenta and yellow where two
  coincide; aligned, it is a white line drawing. For colour-blind players each channel draws its own line style (solid
  red, dashed green, dotted blue) when iOS's Differentiate Without Colour setting is on. Off, every channel is solid,
  since mixed styles would keep aligned lines from going pure white. Both are checked by a colour-blind simulation
  before any level is made, and holding a channel's swatch shows that channel alone. A spectral bezel. Procedural,
  baked.
- **Sound.** The lead is the piece's motif in three detuned voices, one per channel, over cold FM glass-bell pads.
  They resolve to unison only on the solve, never during play, so the sound is no closeness meter. A heal is a struck
  glass rod, pitched by heals done. Nothing sounds during a drag.
- **Structure.** 30 specimens in five trays of 6: Two Colours (red and cyan rods only), Three Colours (all seven
  masks), Colour Order (a buried seam freed because the stir above it is another colour), Overprint (deep pent and
  hex), Spectrum (the finale tray). Specimens 1 to 3 free. Level ids `prism-1` to `prism-30`; depth held near 12 to 14
  entries until the cached chain lands.
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

##### 6. The Well (capstone)

One puzzle, days deep: every rod's core holds a smaller tank, and you dive into them to free the tank above.

- **Role.** Released last. A pack anyone can buy at the one price, and part of Complete. Its cups use the free
  ladder's rules, so it needs no other pack and its count never depends on which packs exist.
- **Buyer.** Players who want one long project kept over days (the 1000-piece jigsaw crowd, Gorogoa and Droste fans),
  who can buy it without owning any other pack, and completionists, who get it in Complete.
- **Rule.** The top tank is hex, level motion none. Each outer rod's rigid core holds a cup: a whole smaller tank
  drawn inside it, scrambled, and played under one free tier's rules (plughole, whirlpool, and vortex, maelstrom or
  charybdis once they exist), never a pack's. An outer rod is a new knob kind, cup: until its cup is solved it refuses
  turning with the seized thud, yet it is not `seized`, which would turn on the rim grab, the tank turn and the rim
  lesson. A tap on its core dives into the cup (a new `Grab` case) only while the cup's glass is round: no outer entry
  on the hub or on the rod's two neighbours, whose discs reach within 0.12 of its centre, well inside its 0.264 core
  (checked from the layout table). Diving is free and counts no move. Inside, the cup is its own `Game` under its own
  tier's rules (its own stack, moves, undo and, for a maelstrom cup, a turning tank). Climbing out bakes it back into
  the core, where its clean picture rides rigidly; a solved cup sets for good and frees its rod. The outer stack orders
  the dives, and a checker proves every well has a dive order with no deadlock. Par is the sum of every tank's par.
  Every tank's state persists between launches.
- **Skill.** Dependency planning across nested puzzles, like keys and doors, using every rule the free ladder taught.
- **Look.** Looking down a well that is also a raked stone garden: grey gravel raked in straight lines (never rings,
  which hide turns) round the mouth, each cup in its own tier's look. The dive is a continuous zoom into the core as
  the cup's knobs fade in; climbing out pulls back until the solved cup is a small upright picture and moss creeps
  over its stone. A bent cup's glass is the clearest seam cue in the game.
- **Sound.** Depth is the music's form, after Meander's slow layering (Jack's reference, 2026-09-29): each solved cup
  adds its tier's layer to the piece for good, each level down thins the mix towards bass and a water drip, and
  climbing restores it. A dive is a pressure swell and one glassy ping, on the bar line.
- **Structure.** One well: a hex top tank, six cups and six sub-cups, about 13 tanks played over days, with a small
  depth tree beside the tank. Then a harder second well, The Cistern (pent, three deep). A finished well can be left
  playing as a picture and sound. The top tank and its first cup are free. Level ids `well-1` onward.
- **Weakest point.** A cup is a fifth of the tank across, too small to read before diving, so the outer view must work
  as a map. A loose dependency graph goes rote. And it is the largest build in the catalogue: nested games, cups baked
  to textures, about 13 stacks saved between launches, and a deadlock checker.
- **R5 fix.** It revives R5's "two tanks sharing stirs" (too small to read, and the largest refactor), and answers the
  first. No stir passes between tanks, since the outer stack only carries a cup rigidly or bends its glass, and no cup
  is read at cup size, since the dive plays it full screen, so the outer view is only a map of round or bent, solved
  or not. The refactor stays, as its weakest point says.

#### The ladder: what packs may not take

Rule: no pack takes a mechanic a free rung needs, so the rungs are chosen first. Jack plans both as free tiers
(2026-09-28).

- **Vortex**, between whirlpool and maelstrom: the lab's whole-tank swirl (b6ed01c: quad plus a rod of radius 1 at the
  centre, turned by dragging the rim). It is a stir like any other whose disc covers every rod, so it orders every
  seam and teaches the rim before maelstrom turns the glass with it. It breaks the "cores clear at 0.6" rule (its core
  overlaps every rod's), so its go/no-go is whether a swirl seam reads through the cores on the phone.
- **Charybdis**, beyond maelstrom: independent orbits, the Orrery candidate's mechanic. Maelstrom is orbits with every
  working knob at one rate (a step of the glass is every knob moving one slot round it, hex's hub a sun at rate 0), so
  orbits are the line maelstrom starts. They reuse its solver (positions become crank ticks, a reach table per tick,
  the lcm of the planets' periods), its rim and its lesson. Planets ride the crank, never a tap, which answers R5's
  "fewer knobs than rods, carried by tap" (admin, a tap fighting the drag): moving them is the puzzle, not admin. Two
  planets on one slot make it live once (the finger holds that slot's rod), are drawn side by side 0.04 apart along
  the slot circle, and strike their bells together as they land. During the crank's drag only haptics play, since
  nothing sounds during a drag.
- **Packs keep what no rung needs:** zoom and spiral (Lens), the clock (Escapement), channels (Prism), the ear (Music
  Box) and nesting (The Well).
- **Coriolis is benched**, not offered to charybdis, since its one-way knobs break Jack's free slip.

The conflict is Jack's call (decision 2). The only other strong rung is Escapement's clock, so keeping Orrery as a pack
means charybdis takes the clock and Escapement leaves the shelf. Nothing else on the bench or in the lab survives as a
rung: linked rods are R5's admin, and the frozen core and lights-off subtract from the read.

#### Open for Jack: four decisions

**1. The catalogue and v1's three packs.** Five packs and a capstone (First Stir, Lens, Escapement, Prism, Music Box if
it passes its ear test, then The Well), with First Stir, Lens and Escapement at v1 and First Stir as the flagship.
First Stir is the weakest design in the set: its puzzles are plughole depth and it tests no new skill (by its own rule
its changing picture changes no decision), so it leads on audience and feel alone. Accept that trio?
- A: First Stir (the flagship, sold as an evening, not a challenge), Lens and Escapement at v1; then Prism, Music Box
  if it passes its ear test, and The Well.
- B: puzzle-first: Lens, Escapement and Prism at v1, so every v1 pack teaches a new skill and none needs an
  illustrator; First Stir later, or never.
- C: the synth's trio, First Stir, Lens and Orrery, only if decision 2 keeps Orrery as a pack.

*Recommendation (Claude's): A.* A flagship's job is to reach players who will never buy a harder pack, and First Stir
is the one pack anyone can finish, the purest form of Jack's own ask ("picture packs with their own tanks",
2026-09-28) and the strongest featuring story and trailer close. Sold honestly, at the same price as the rest, its
plughole depth disappoints nobody it is sold to, while Lens and Escapement carry v1's new skills. Jack's call ("I think
we can handle making packs for v1. I'm not in a major hurry to get it to market.", 2026-10-24) retires the synth's
speed reasons for its trio (no new platform surface, nothing waiting on the performance pass, which is queued next
anyway). So the trio is re-picked on merit: one pack per kind of change, the two best designs (Lens and Escapement, 8
each) and the broadest buyer. Prism (7) is a second new read and comes first after v1; Music Box waits on its ear test.
If First Stir's go/no-go film fails, or decision 3 finds no art route, Prism takes its slot and Lens leads the shelf.

**2. Orbits and the swirl for the free rungs.** No pack may take a mechanic a free rung needs. Should charybdis, the
planned free rung beyond maelstrom, take the Orrery candidate's independent orbits, and vortex the lab's whole-tank
swirl, so that Orrery leaves the pack catalogue?
- A: charybdis gets orbits and vortex the swirl; Orrery leaves the shelf, Escapement takes v1's new-move slot, and
  Coriolis is benched for good.
- B: Orrery stays a v1 pack; charybdis takes Escapement's clock instead, and Escapement leaves the shelf.
- C: keep Orrery and Escapement as packs and leave charybdis without a designed mechanic for now, which breaks the
  rule.

*Recommendation (Claude's): A.* Maelstrom is orbits with every working knob at one rate (a step of the glass is every
knob moving one slot round it, hex's hub a sun at rate 0), so orbits are the line maelstrom starts and the natural rung
beyond it. The synth benched Coriolis as "maelstrom made harder, the charybdis rung", and Orrery is the same case done
well. As a pack its real buyer was the maelstrom finisher; as charybdis every finisher gets it free, built on
maelstrom's solver, rim and lesson. The clock is a different axis (tempo, not routing), so selling it starves no rung.
Nothing else is a strong rung: linked rods are R5's admin, the frozen core and lights-off subtract from the read, and
Coriolis breaks the free slip.

**3. First Stir's art.** About 150 figurative neon line vignettes: commission an illustrator, or have Claude draw them
in code?
- A: Claude draws the go/no-go harbour scene in code first; if its film passes, commission a neon line illustrator from
  an art spec Jack approves.
- B: Claude draws all 25 scenes as procedural line art, Jack judging each.
- C: neither: Prism takes First Stir's v1 slot and Lens leads the shelf.

*Recommendation (Claude's): A.* Every picture today is drawn in code (checked: `Pictures.swift`), and a lighthouse,
houses and a boat are within its reach, so the go/no-go costs nothing but time. Figures, faces and a child stirring
tea are where code-drawn line reads stiff, and the art is the pack's whole value and its long pole. Spending money is
Jack's call alone, and with no hurry the commission's lead time costs nothing if it starts the day the film passes.

**4. What v1 sells beside the packs.** Claude's options comparison (2026-10-24) recommended Unstir+ (the daily
archive, endless past a free taste, the supporter mark) as 1.0's one product, with no packs; Jack's call now puts
packs in v1.
- A: packs at one price each, and a Complete bundle of the packs released so far for less than their sum; drop
  Unstir+, so endless stays wholly free; the daily archive and the supporter mark come with any purchase; a tip jar
  shows only after one.
- B: keep Unstir+ beside the packs, with endless past a free taste inside it.
- C: packs only at v1; the archive, the mark and tips later.

*Recommendation (Claude's): A.* Option C of the comparison gated endless only because 1.0 had nothing else to sell.
With packs on the shelf, gating the free game's one endless mode buys little and risks the returns TestFlight is meant
to measure, and the archive and mark become thank-yous rather than a second product to weigh. A Complete of shipped
packs promises nothing App Review might question (assumed; checked before it is named), and at v1 it must cost less
than the three packs or it saves nobody anything. Product ids can't be reused once created (assumed, Apple platform
fact), so this set and its names are fixed before App Store Connect.

#### Defaults (Claude's recommendations; they stand unless Jack changes them)

- **Price.** One price for every pack, inside R1's band ($2–5), never set by difficulty or size; Jack picks the
  number.
- **Complete's price path.** About one pack less than the packs it holds. Each new pack joins it and raises it by one
  pack's price. Owners of an older Complete are granted later packs by the app, which the store page never promises
  (check App Review first).
- **Free taste.** The first three levels of every pack free, as its wordless teach-in; for The Well, its top tank and
  first cup.
- **Tier gating.** None: every pack opens from the first launch, its card says what it assumes ("anyone", "after
  maelstrom"), and no pack best ever touches `Tier.isOpen` (tested).
- **Undo in packs.** The shared bank (+2 a playing day, capped at 10, never sold), one undo per move, restoring a
  snapshot of the state before that move (the stack's entries with their marks and tags, the clock's tick). The free
  tiers keep today's undo.
- **Undoing a heal in a pack.** Its vignette unplays and its note steps back, as Claude already recommends for every
  heal's note.
- **Turn-backs in Escapement.** Free: the tick lands provisionally on lift and comes off with a stir turned straight
  back. No extra star for never doing it.
- **Escapement's lost rule.** A pack-only exception: a tick that pushes loses the problem once its move is sealed;
  "lost." with undo (if the bank has one) and again (a free reset).
- **First Stir's heal ring.** Endless's rule (Jack, 2026-09-29): magenta and the heavy tap only for a commit that plays
  a vignette; cancelling your own push flashes white.
- **Music Box's two exceptions to the sound rule.** Allow, inside Music Box only, sound carrying the read and the arm
  playing during a drag. A recommendation for Jack to take after its ear test, not his call yet.
- **Music Box's gate.** Cut it if, in a cold read, sound on doesn't find seams clearly faster than sound off. The
  catalogue then stays at four packs and The Well.
- **Music Box's pitch.** Snap each pin to the nearest track and eighth, so errors are whole wrong notes; no quarter
  tones.
- **Each pack's sound.** Layers (bass, kit, lead) of the one piece in D entering on a bar line, inside the one-piece
  structure. Each pack's peril is set for the pack and never rises within a tank. Sketches go to Jack before anything
  is polished.
- **Store page.** Lead with the free game (a picture snapping back), then the packs, every screenshot or preview moment
  of a pack labelled as a paid add-on (guideline 2.3.2, assumed).
- **Family Sharing.** On for every pack and Complete, knowing that once on for a product it can't be turned off
  (assumed Apple platform fact; check).
- **The daily archive.** Back-filled to a date Jack picks, opened by any purchase, with bests under `daily-yyyymmdd`
  ids.
- **The supporter mark.** On the menu and in the daily share line, after any purchase.
- **The tip jar.** Two or three consumable tips, shown only after a purchase.
- **Vortex and charybdis.** Free updates after v1, their mechanics reserved now (decision 2), each with its own
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
- **Progress backup.** Bests, pack progress and The Well's saved tanks sync through iCloud key-value storage from v1.
  The undo bank and its clock anchor never sync.
- **How to read testers' play** (Jack's open call, item 7 of "Open for Jack" above). An opt-in upload of the flight
  recorder log and an exit survey; no analytics library.
- **Albums.** Each pack's music released as an album once Jack approves its sketches, through a distributor chosen
  then, its account details kept in `HANDOFF.private.md`.
- **App size.** Packs ship in the bundle, art as line paths baked on the phone and audio as AAC. Background Assets
  only if the app would pass the cellular download limit (assumed about 200 MB; check).
- **The Well's price.** A pack at the one price, for anyone, and part of Complete.
- **Names and ids.** The roster's names. Each pack's id is its level prefix (`first-stir-N`, `lens-N`,
  `escapement-N`, `prism-N`, `music-box-N`, `well-N`, clear of `L`, `N`, `N+`, `M`, `daily-`, `endless`, `sandbox`
  and `lab-`). Product ids `<bundle id>.pack.firststir` and so on, plus `<bundle id>.complete` (letters, digits,
  periods and underscores; assumed).
- **Offer codes.** For press and reviewers, First Stir's and Escapement's first.
- **A revoked pack.** Progress kept; levels past the free taste show the pack card again.

#### To do

1. Record in HANDOFF.md (the main session, not this worktree): the roster, the ladder reservation, this to-do, the
   open calls with their recommendations, and the 17 benched entries under Set aside with their reasons; mark option
   C's "no packs at 1.0" superseded by Jack's call of 2026-10-24.
2. Jack's calls on decisions 1 to 4, then any defaults he wants changed.
3. Settle pack names, level-id prefixes and product ids together, before anything is created in App Store Connect.
4. First Stir go/no-go first, since its art is the long pole: one harbour scene with three vignettes drawn in code,
   filmed and cold-read. Each heal must read as time stepping back, not the stir changing.
5. First Stir's story outline (25 scenes and their vignettes) for Jack's approval, then, on decision 3, the
   illustrator's commission from an art spec: single-weight neon line, the chapter palettes, up readable in every lit
   core, each figure change inside its own rod's core.
6. Lens go/no-go: port the lab zoom onto a halftone test picture, film ±1 to ±3 steps on the phone and set the rate
   (1.2, or 1.25 to 1.33 if one step doesn't read); film a zoom seam over and under a twist seam and cold-read which
   is newest; compare shrunk cores against a supersampled reference for glitter, since zoom isn't area-preserving.
7. Escapement go/no-go: the mock-up's problem in the lab, played on the phone, for whether a tick landing on lift and
   lifting out on a re-grab reads, whether sealing on the next commit feels fair, and whether "lost." does.
8. Split `seized` into a level motion (none, tank, crank) and a knob kind (working, seized, socket, ratchet, cup). The
   rim grab, the rim lesson, the bezel's hit area and the spin gesture key on motion; touch keys on kind, with new
   `Grab` cases for a ratchet tap and a cup dive; par's comment and the solver's turn moves key on motion; maelstrom's
   tests unchanged.
9. A `Pack` type outside `Tier` (name, id prefix, levels, free-taste count, product id, card), a `pack` field on
   `Level` as the lab branch's `lab` field is, bests by id, and a test that no pack best opens a tier.
10. A merge hook on `Stacked`, so an entry merging into another hands over its payload (First Stir's tag sets union;
    `Game.Entry`'s pushed mark stays the landing entry's), with tests that endless's brim behaves exactly as today.
11. Pack undo: a snapshot per move, restored by undo from the shared bank, with tests per pack (First Stir's tags,
    Escapement's tick, Lens's zoom entries).
12. StoreKit 2: a non-consumable per pack plus Complete; purchase, restore, the `Transaction.updates` listener,
    revocation and refunds, pending Ask to Buy; entitlements read at launch; a StoreKit configuration file and
    StoreKit test-session tests, all before the paid account exists.
13. Entitlement guard: only StoreKit grants a pack; `Best.unlocked` never opens a paid pack in Release;
    `UNSTIR_OWNED` exists only in DEBUG or under the harness; a test for each.
14. A revoked pack keeps its progress, and its levels past the taste show the card again.
15. The pack shelf, apart from the tier strip and ungated: three working mock-ups for Jack to pick from, as with the
    tier switcher, then the chosen one built.
16. The pack card: a looping 7-second clip, what the pack assumes, the free taste, price, buy and restore; levels past
    the taste show it; Music Box's says "needs sound".
17. Accessibility on the new screens: Dynamic Type and VoiceOver for the shelf, card and purchase flow; Reduce Motion
    for the vignettes' crossfades, the zooms, the clock's steps and the dive.
18. Harness: `UNSTIR_PACK`, `UNSTIR_OWNED` (one launch, never stored), First Stir's played vignettes, Escapement's
    provisional tick and lost state, with a shot and a film line per pack.
19. A shot per purchase state: unowned, owned, pending Ask to Buy, failed, revoked.
20. A String Catalog for every new string (captions, the shelf and cards, purchase text, Escapement's stipulations),
    English at v1.
21. iCloud key-value sync of bests, pack progress and The Well's tanks, never the undo bank or its clock anchor.
22. An app-size budget for the bundle (line art baked on the phone, AAC audio), with Background Assets only past it.
23. A phone bench of every new shader cost against `fourTaps` (zoom and spiral entries, the vignette crossfade,
    Prism's channels) through an in-app GPU timer, since Instruments can't see the phone yet; each kind's weight set
    from it.
24. The performance pass's bar on each pack's heaviest frame: 120 Hz on the iPhone 13 Pro Max.
25. The slow pack-table proofs (solver optima, Escapement's prover, The Well's deadlock checker) behind
    `UNSTIR_SLOW_TESTS`, so CI stays under the 5-minute line.
26. Tests for every pack table (par equals the solver's or prover's optimum, planning gaps where they apply), unique
    ids, and each pack's own rules.
27. Lens: a rod kind on the level (twist by default), read by the map, `same`, the shader and the solver;
    `testDailyVectors` and `testEndlessVectors` pass unchanged.
28. Lens: the zoom map from the lab and the spiral flow (its ring angle a closed-form integral checked against
    numerical integration), each in Twist.swift and Unstir.metal together, with tests that steps merge by summing, an
    entry and its inverse cancel, the map is the identity outside the disc and the Metal copy holds precision far past
    ±3 steps; shots that pin each kind's sign.
29. Lens: the solver and solve.sh learn rod kinds; pars from the solver.
30. Lens: the halftone pipeline (dot screens in clean coordinates, baked panels, fill 0) and a test in the spirit of
    `testVisibleSmudgeIsNotSolved` that every step of every rod moves contrasting pixels.
31. Lens: iris and nautilus knobs, the drag's count reading zoom steps, and haptic detents.
32. Lens: 25 panels of art (an original wordless heist in pop-art objects) and the issue pages.
33. Lens: the level table (25), solver-checked, to Jack before it goes into code.
34. Escapement: the ratchet knob kind and its tap, and the tick rule (lands on lift, lifts out on a re-grab of the
    open stir, sealed by the next commit of another knob or a ratchet tap, solves on the spot, the clock stopping once
    E is empty), with a test for each case.
35. Escapement: the lost rule and its test (a pushed tick leaves a positive E entry that no continuation pops,
    property-tested on small cases) and the "lost." card with undo and again.
36. Escapement: the pruned prover (`exhaustive` with a forced tick after every move and a line dropped where a tick
    pushes), a meet-in-the-middle fallback for hex, and an escapement mode in solve.sh.
37. Escapement: the paper ground: dark-ink variants of the solve wave and the turn's hairlines, ink lines at least
    2 px wide, and shots that pin them.
38. Escapement: ratchet art (a 12-tooth wheel and pawl), the vermilion sub-dial and the stipulation set in a serif.
39. Escapement: 30 composed problems, each proved, to Jack before code.
40. First Stir: vignettes as tag sets on the scramble's entries, played when their tags leave the stack (a pop, a
    merged pop, a fine-pass win), unplayed by undo and reset, crossfading 0.4 s under the stack.
41. First Stir: a per-scene test that no vignette's light reaches the core of a rod with an entry removable right
    after its heal (`Layout.removable`), over every heal order.
42. First Stir: vignettes baked on demand within a memory budget measured on the phone.
43. First Stir: 25 scenes of art and their scrambles; Jack reviews the table.
44. First Stir: the "night forwards" end film.
45. Sound: merge the sound branch after Jack's listen; sketch each v1 pack's layers for his ear (First Stir's
    felt-piano motif and weather pads, Lens's canon, Escapement's muted kit, tooth drops and looping phrase); render
    the finals in Csound.
46. Free taste: the first three levels of each pack teach its rule without words; cold-read each on a new player.
47. The daily archive: a calendar screen, bests under `daily-yyyymmdd` ids, back-filled to Jack's date, opened by any
    purchase.
48. The supporter mark (menu and share line) and a tip jar of two or three consumable tips, shown after a purchase.
49. The daily share line (plan step 2), separate from sharing, before TestFlight.
50. Clips and images: each pack's 7-second clip and promoted in-app purchase art, filmed with film.sh, plus a sound-on
    cut for social video.
51. Buy the developer account when TestFlight is ready (see "The Apple Developer account"); then the paid apps
    agreement, tax and banking, and the in-app purchases with review screenshots and promoted purchases.
52. The privacy manifest, new work (no `PrivacyInfo.xcprivacy` exists): UserDefaults with reason CA92.1, the uptime
    clock with 35F9.1, and whether reading `kern.monotonicclock` needs a reason (the open question in "Where things
    stand"); then the privacy label.
53. The age-rating questionnaire.
54. The store page: screenshots and a preview leading with the free game, then the packs, each pack labelled as a paid
    add-on, captioned for muted playback.
55. Check App Review's rules on Complete before naming or pricing it.
56. Offer codes for press and reviewers.
57. TestFlight with 20 to 50 strangers and sandbox purchases. What it measures (shelf and card taps, free-taste
    completion and sandbox purchases per pack, beside day-2 return) waits on Jack's call on how to read testers' play.
58. Apple's featuring nomination, then launch.
59. Prism: per-channel `same`, `commutes` and `looksSolved` on each channel's restricted word, with tests that
    overlapping entries with disjoint masks commute.
60. Prism: the shader's per-channel chains, their cost (up to 3× an entry, assumed) benched on the phone, and depth
    held near 12 to 14 entries until the cached chain lands.
61. Prism: a colour-blind simulation of every specimen (protanopia, deuteranopia, tritanopia), with and without the
    per-channel line styles that Differentiate Without Colour turns on, and the swatch that shows one channel.
62. Prism: the engravings, tinted knobs and 30 specimens, solver-checked, to Jack before code.
63. Music Box: the render-thread scheduler for sample-accurate plucks (a render callback reading a lock-free snapshot
    of pin positions each buffer; assumed `AVAudioSourceNode`).
64. Music Box: the ear-test protocol (cold readers, sound on against sound off, the time to find each seam), run
    before any art; the pack is cut if it fails.
65. Music Box: pins, the comb arm, snapping, the hum control and the tines in Csound; 24 tunes, to Jack's ear in
    sketch rounds.
66. Music Box: the Composer: tune links, a web domain, report and block tools for titles and links, and the
    age-rating effect of user content.
67. The Well: cups baked to textures when not played, nested `Game`s, the round-glass test, the cup knob kind and the
    dive.
68. The Well: every tank's game saved between launches.
69. The Well: the deadlock checker (every well has a dive order) and its table to Jack.
70. Albums: a route (a distributor and its account) for releasing each pack's music, the account kept in
    `HANDOFF.private.md`.
71. Vortex and charybdis, free: the lab's swirl played on the phone (does a swirl seam read through the cores?), then
    vortex's own design round; charybdis's orbit solver (a reach table per crank tick), its shared-slot rule and its
    own design round.

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
| Endless's new rules | Built on `endless` (2026-09-29): no undo, reset or par, the brim counting red flashes, Claude's ramp, and the vivid jug on the rim, ported from the approved film. Reviewed, and the review's fixes made, the pour over the lip among them. Jack watched the app's film on 2026-09-29 and approved it ("looks great"); PR #11 is waiting for his merge. See "Endless changes rules" below |
| The phone | Installed 2026-09-29: a local build of `touch` at 42406cc with `help`'s three commits (hints removed, the daily +2 refill, the clock guard), the glass sound set, and two proposals not to be committed (maelstrom v2 as M1–M27, and plughole 19–27's easier scrambles). The next install carries the dashes |

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

Benched in drawing up the pack catalogue ("Packs: the catalogue"). Claude's recommendations against, not Jack's calls;
Orrery's move to charybdis waits on decision 2 there.

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
