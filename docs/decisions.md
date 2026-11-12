# Decisions

Jack's decisions, one row each. Other files cite a call by its id; this file says in short what each decided. Add a row when Jack
makes a call. "HANDOFF" in the Where column includes the closed sections now in `docs/history.md`.

Each row is a one-line summary for finding a call, not the call itself: where a row and the file it names differ,
the file wins. Read the full text there before acting on a call.

## Round 1

The pitch page's first answers, 2026-10-24 (HANDOFF numbers only the later rounds).

| Call | Date | Decided | Where |
|---|---|---|---|
| Packs at v1 | 2026-10-24 | Packs ship at v1 and there is no hurry to market; this replaced Claude's single "Unstir+" purchase for 1.0. | HANDOFF |
| 1. v1's packs | 2026-10-24 | v1 ships First Stir, Lens and Escapement (option A); First Stir later left v1 (FS17) and Prism became the third pack (PK1). | HANDOFF |
| 3. First Stir's art | 2026-10-24 | Claude draws all 25 scenes (option B); Jack will not hire an illustrator. | HANDOFF |
| 4. What v1 sells | 2026-10-24 | Packs plus a Complete bundle (option A); Unstir+ is dropped and endless stays free. | HANDOFF |
| Tip jar | 2026-10-24 | Dropped ("No begging"), though agreed on 2026-09-28; the supporter mark is the thank-you. | HANDOFF |
| Offer codes | 2026-10-24 | Dropped. | HANDOFF |
| Family Sharing | 2026-10-24 | On for the packs and the bundle. | HANDOFF |
| Undo in packs | 2026-10-24 | Undo works in packs, and in the free tiers an undo must not close the stir it uncovers; merged in PR #19. | HANDOFF |
| Escapement turn-backs | 2026-10-24 | A turn-back is not free: the skill is knowing how the escapement works, so the pack must show the clock before stir 1. Confirmed in round 2. | HANDOFF |
| Analytics | 2026-10-24 | Analytics are acceptable if done respectfully, with no dark-pattern menus; the terms were set in round 2. | HANDOFF |

## Round 2

2026-10-24, same page, after Jack saw Orrery's mock-up.

| Call | Date | Decided | Where |
|---|---|---|---|
| 2. Orrery | 2026-10-24 | A free rung: charybdis gets the orbits, and Orrery leaves the pack catalogue. | HANDOFF |
| Escapement's tick | 2026-10-24 | A tick is final once a move is made; a look that lets go where it started is no move and no tick; level one shows the clock first. | HANDOFF, architecture |
| Eyes Shut | 2026-10-24 | Prototype it after v1, free, and drop it if a blind tester cannot play it. | HANDOFF |
| The Well | 2026-10-24 | Cut: not compelling enough even for free; moved to the benched candidates (R9). | HANDOFF |
| Undoing a heal in a pack | 2026-10-24 | Yes: the story beat plays forward again and its note steps back. | HANDOFF |
| First Stir's heal ring | 2026-10-24 | Magenta only for a heal that plays a beat; cancelling your own stir flashes white. | HANDOFF |
| Analytics | 2026-10-24 | Anonymous counts only, no tracking prompt, no advertising partners, one settings switch; check whether EU law wants a consent prompt. | HANDOFF |
| Firestore | 2026-10-24 | No server: purchases through StoreKit, progress through iCloud key-value storage, and a test pins every stored level id and product id. | HANDOFF |
| Vortex and charybdis reserved | 2026-10-24 | Vortex and charybdis are free; their mechanics are reserved from the packs now, each with its own phone go/no-go. | HANDOFF (sources differ: see disagreements) |

## Round 3

2026-10-25, the review page of the overnight builds.

| Call | Date | Decided | Where |
|---|---|---|---|
| V1. Vortex's rim cue | 2026-10-25 | The knob (option A), over bands and glyphs. | HANDOFF |
| V2. Swirl ticks | 2026-10-25 | No option chosen, but Jack rejected the tick dial as the swirl's cue, which reopened the cue (breath, in round 4). | HANDOFF |
| V4. Swirl with seized knobs | 2026-10-25 | Charybdis (option B): dragging the tank's edge always swirls the tank; Claude's reading as one gesture was confirmed in round 4 (R1). | HANDOFF |
| V5. Vortex's levels | 2026-10-25 | Accepted as provisional. | HANDOFF |
| V6. Vortex's pictures | 2026-10-25 | A family of its own (option C); round 4 (P1) chose all three. | HANDOFF |
| F1. First Stir | 2026-10-25 | Go. | HANDOFF |
| F2. First Stir's time cue | 2026-10-25 | Make time visible (option C): the night winds back, plus the caption. | HANDOFF |
| L1. Lens | 2026-10-25 | Try the hard lens with a phone test next (option A), against the reviewers' advice to shelve it. | HANDOFF, architecture |
| E1. Escapement | 2026-10-25 | Go, with changes. | HANDOFF |
| E2. Warning before a losing lift | 2026-10-25 | The standing hint (option C): the clock's disc always has a dashed vermilion edge (`ClockHint`). | HANDOFF, architecture |
| E3. What a sealed loss shows | 2026-10-25 | Freeze on the +1 (option B). | HANDOFF |
| S1. Prices | 2026-10-25 | 2.99 a pack and 5.99 for Complete. | HANDOFF, architecture |
| S2. The pack shelf | 2026-10-25 | A dock of live covers along the bottom of the menu (option C). | HANDOFF, architecture |
| I1. The app icon | 2026-10-25 | Candidate 1, the neon grid. | HANDOFF |
| D1. Daily #1 | 2026-10-25 | Daily #1 is launch day; until it is set, the share line shows the date. | HANDOFF |
| B1. CI time | 2026-10-25 | Watch it. | HANDOFF |

## Round 4

2026-10-25, its own page after round 3.

| Call | Date | Decided | Where |
|---|---|---|---|
| R1. Charybdis's rim | 2026-10-25 | Claude's reading confirmed (option A): one gesture that turns the glass and swirls it together. | HANDOFF |
| C1. The swirl's cue | 2026-10-25 | Breath (option B): the picture sloshes once, 12°, 1.5 s after the tank rests, then every 12 s idle; merged in PR #30. | HANDOFF, architecture |
| P1. Vortex's pictures | 2026-10-25 | All three families: isobars, ephemeris and cords. | HANDOFF |
| V3. Which layouts get a swirl | 2026-10-25 | All five, the 27 levels as built. | HANDOFF |
| B2. CI over 5 minutes | 2026-10-25 | Cache the build (option A) and move the line to 7 minutes; the cache merged in PR #29. | HANDOFF |

## Round 5

| Call | Date | Decided | Where |
|---|---|---|---|
| W3. The whole-tank swirl's map | 2026-10-25 | Option D: the swirl shears to its centre (plateau 0) while knobs keep 0.6, over today's map and softer maps (sources differ on the date). | HANDOFF, architecture |

## Round 6

2026-10-25, five calls before TestFlight.

| Call | Date | Decided | Where |
|---|---|---|---|
| PR #31, warm-up build | 2026-10-25 | Close it: the compile runs inside the simulator's boot, so a warm cache saves nothing; the PR #29 cache stays. | HANDOFF |
| Daily archive back-fill | 2026-10-25 | Back-fill 30 days before launch day. | HANDOFF |
| EU consent for anonymous counts | 2026-10-25 | Ask once: a plain Yes or No at first launch, the same switch in settings, nothing sent until Yes. | HANDOFF |
| How to read testers' play | 2026-10-25 | An analytics library behind the consent switch, plus a send-log button in settings (option D). | HANDOFF |
| First Stir's opening | 2026-10-25 | The wrecked harbour, as built: the player starts in the storm and earns the calm. | HANDOFF |

## Round 7

| Call | Date | Decided | Where |
|---|---|---|---|
| Analytics library | 2026-10-25 | Aptabase on its EU region, over TelemetryDeck, PostHog Cloud EU and Mixpanel. | HANDOFF |

## Round 8

2026-10-26, built on `analytics` (PR #38).

| Call | Date | Decided | Where |
|---|---|---|---|
| Q = A | 2026-10-26 | The consent question is a card over the menu at first launch, the menu waits, and Yes and No are the same control with neither preselected. | HANDOFF, architecture |
| S = A | 2026-10-26 | A gear beside the menu's title opens a sheet with the analytics switch and "send log", which hands the flight recorder to the share sheet. | HANDOFF, architecture |
| N = C | 2026-10-26 | Under No nothing is recorded and the tally is cleared except the install's day; a later Yes starts clean; bests and started flags stay. | HANDOFF, architecture |
| K = B | 2026-10-26 | `returned` goes for any day number not yet sent, and when several snapshots are due only the newest goes. | HANDOFF, architecture |

## Round 9

2026-10-26.

| Call | Date | Decided | Where |
|---|---|---|---|
| FS = A | 2026-10-26 | First Stir's outline (`docs/first-stir-outline.md`) approved as written; the art for all 25 pictures starts. | HANDOFF, CLAUDE.md |
| F1 = A | 2026-10-26 | Three changes (vignettes) per picture, 75 in the pack. | HANDOFF |
| F2 = A | 2026-10-26 | One night across the pack, about half an hour a picture, the sky carrying on from one to the next. | HANDOFF, architecture |
| F3 = A | 2026-10-26 | A clock under the tank, like "4:10 am", steps back as the player undoes a twist. | HANDOFF, architecture |
| F4 = A | 2026-10-26 | Each change stays inside its own core, checked by a test over every picture; level 1's boat stern and lamp shards are redrawn. | HANDOFF |
| F5 = A | 2026-10-26 | The lab harbour is used twice, as picture 16 (midnight) and its dawn view as picture 1. | HANDOFF |
| E1 = A | 2026-10-26 | Every let-go is final in Escapement: the clock clicks on the lift and no re-grab takes it back (book J1 and J2 = A). | HANDOFF, architecture |
| E2 = B | 2026-10-26 | If the last clock stops with twists left, the problem fails like a bad click (J4 = B); replaced in play by EL1 in round 11 (sources differ). | HANDOFF, CLAUDE.md, architecture |
| E3 = A | 2026-10-26 | Searched problems are fine once Jack has played them on the phone and vetoed any that feel random (J9 = A). | HANDOFF |
| L1 = A | 2026-10-26 | Run the phone test of the hard lens before any of Lens's art is drawn. | HANDOFF |
| Lens drag direction | 2026-10-26 | After the first phone session, a lens follows the finger up and down, not round; up zooms in. | HANDOFF, architecture |
| Lens step size | 2026-10-26 | A lens zooms by x2 a step, judged good after x1.6. | HANDOFF, architecture |
| S1 = C | 2026-10-26 | In Release a pack's cover shows only once its levels past the taste ship, and Complete's only once all its packs' do. | HANDOFF, architecture |
| D1 = A | 2026-10-26 | The defaults as built: buy button above the list, a free level goes back to its card, Complete is the fourth cover, and First Stir ends with the night forwards. | HANDOFF, architecture |
| C1 = C | 2026-10-26 | The consent card reads "Help improve Unstir?" and one line, with a link "What does it send? ›" that opens the full list. | HANDOFF, architecture |

## Round 10

2026-10-28, the review page of PRs #50 to #58.

| Call | Date | Decided | Where |
|---|---|---|---|
| PH1. Plughole 19-27 eased | 2026-10-29 | Pent and hex both eased (option A, PR #50), after Jack asked what the rationale was. | HANDOFF |
| SN1 = A | 2026-10-28 | Sound round 2 goes in with the early undo and step-back heals; keep the vortex bed. | HANDOFF, architecture |
| TU1. Locked up-a-notch button | 2026-10-28 | Option C, the gate: the tap shows what is left to do, as the menu's gate page does (PR #57). | HANDOFF |
| LN1 = A | 2026-10-28 | Lenses on rods of every size (PR #53); `lens-levels-big` stays as the alternative. | HANDOFF |
| LN2 = A | 2026-10-28 | Keep the cap of +3 on a dealt lens; `lens-levels-cap2` is the fallback if the band's shimmer bothers him. | HANDOFF |
| J6 = B | 2026-10-28 | The book ends on problem 30, the two-clock hex; the three-clock hex becomes 29. | HANDOFF |
| ES1 = B | 2026-10-28 | Show a count of twists left, to be workshopped; reworked in round 11 (EL1) and then replaced by the tick budget. | HANDOFF |
| EB1 = B | 2026-10-28 | Change some of the book on the phone's evidence: a clearer wait target on problem 7 and clearer tick counts on problem 16. | HANDOFF |
| CL1 = A | 2026-10-28 | Lens's card clip plays the zoom and the read. | HANDOFF, architecture |
| CL2 = B | 2026-10-28 | Complete's clip is a cut of the three packs' first beats, about 8 s. | HANDOFF, architecture |
| FS10 = A | 2026-10-28 | Approve First Stir's 25 scenes; superseded in effect by FS17. | HANDOFF |
| FS12 = A | 2026-10-28 | The night's clock and sky, all as built. | HANDOFF |
| FS13 = A | 2026-10-28 | Chapters 1 and 2's departures from the outline, all as built. | HANDOFF |
| FS14 = A | 2026-10-28 | Chapters 3 to 5's departures from the outline, all as built. | HANDOFF |
| FS15 = A | 2026-10-28 | Judge figures on small rods on the phone first and change nothing yet. | HANDOFF |
| FS16 = A | 2026-10-28 | Fold Pen into Brush: one drawing kit. | HANDOFF |
| ST1 = A | 2026-10-28 | Store name: Unstir. | HANDOFF, CLAUDE.md |
| ST2 = A | 2026-10-28 | Subtitle: "Unwind the stirred picture". | HANDOFF |
| ST3 = A | 2026-10-28 | Promotional text: the one that says what is free and that packs exist. | HANDOFF |
| ST4 = A | 2026-10-28 | Screenshots: seven free-game shots, then one per pack. | HANDOFF, CLAUDE.md |
| ST5 = A | 2026-10-28 | One 25 s preview video, free game only. | HANDOFF, CLAUDE.md |
| ST6 = A | 2026-10-28 | Family Sharing on for the packs and Complete, and the description says so. | HANDOFF |
| ST7 = A | 2026-10-28 | Store defaults (keywords, category, policy and support page, send-log disclosure) all fine. | HANDOFF |
| ST8. Lawyer questions | 2026-10-28 | No lawyer: Claude finds the answers itself; UK law matters most, but release worldwide if possible. | HANDOFF |
| AN1 = A | 2026-10-28 | The consent card's link is a toggle, "Hide the list" when open (PR #55). | HANDOFF |
| AN2 = A | 2026-10-28 | Accept that Yes, No, Yes counts as a second install. | HANDOFF, architecture |
| CI1 = A | 2026-10-28 | Keep CI and watch it; if two runs in a row pass 7 minutes, build the PR/nightly split. | HANDOFF |
| DO1 = B | 2026-10-28 | Partly: Jack updates Xcode and Claude waits; the failed-purchase message issue is fixed. | HANDOFF |

## Round 11

2026-10-29.

| Call | Date | Decided | Where |
|---|---|---|---|
| ET1 = B | 2026-10-29 | A lit plate on Escapement's hub marks the wait target, and a miss points to it. | HANDOFF |
| EB2 = B | 2026-10-29 | A countdown numeral that counts down like a flip clock and starts flipping when the escapement moves. | HANDOFF |
| EL1. Tick budget | 2026-10-29 | Escapement has no par: a tick budget each clock's tick spends, a wrong move leaves the puzzle unsolvable without undo, and the remaining ticks are always shown. | HANDOFF, architecture |
| EL2. Reason for a lost tank | 2026-10-29 | "See answer to call 3": the budget replaces the instant loss. | HANDOFF |
| FS17 = C | 2026-10-29 | First Stir leaves v1 and is reworked later; something with at least one new mechanic takes its place as the third paid pack. | HANDOFF, architecture |
| LG1 = C | 2026-10-29 | Conditionally: no EU release if the EU representative and trader-page hurdles cannot be cleared. | HANDOFF |
| LG2 = A | 2026-10-29 | An age bracket before the consent card, its threshold read from one setting. | HANDOFF |
| LG3 = A | 2026-11-01 | Keep send log; register with the ICO and pay with the address withheld, before the first TestFlight invite but not yet. | HANDOFF |

## Round 12

2026-10-29.

| Call | Date | Decided | Where |
|---|---|---|---|
| AN1 = A | 2026-10-29 | v1 ships with no analytics (`v1-no-analytics`); `keep-analytics` holds the other side. | HANDOFF, CLAUDE.md |
| EU1 = B | 2026-10-29 | No EU or EEA storefronts at launch; revisit if sales cover a business address. | HANDOFF |
| PK1 = A | 2026-10-29 | Prism replaces First Stir as the third pack, capped at depth 8 because deeper reads too busy. | HANDOFF, architecture |
| ES2 = B | 2026-10-29 | Each hub shows its own flip-clock count plus a total counter elsewhere; the numbers never contradict and a hub at 0 shows it has run out. | HANDOFF, architecture |
| PL1. Prism's plates 3 and 4 | 2026-10-29 | Redrawn as Haeckel's medusae and radiolarians, chosen from six redraws. | HANDOFF |

## Round 13

2026-11-01, the names-and-polish page; every recommendation but C19.

| Call | Date | Decided | Where |
|---|---|---|---|
| N1. Level names | 2026-11-01 | One world per tier and pack, plain nouns, gentle to wild (plughole the bath, whirlpool a river, vortex the winds, maelstrom the open sea, and so on); ids never change. | HANDOFF |
| N1a. Escapement 01 | 2026-11-01 | Named Mainspring, replacing "The clock". | HANDOFF |
| N1b. Lens's chapters | 2026-11-01 | Four: Close-up (1-6), Cut-in (7-12), Double-take (13-18), Big Picture (19-25). | HANDOFF |
| N1c. Case | 2026-11-01 | Sentence case. | HANDOFF |
| C1 = B | 2026-11-01 | Level 03's result card says "more in Lens ›" in the pack's colour and the card opens on its buy block; no price on the result card. | HANDOFF, architecture |
| C2 = A | 2026-11-01 | An unfinished level resumes: moves are saved on every commit and replayed on reopening; endless resumes mid-tank; no dialog. | HANDOFF, architecture |
| C3 = A | 2026-11-01 | A level counts as tried on its first committed move; a look is free; the row shows "tried". | HANDOFF, architecture |
| C4 = B | 2026-11-01 | A fresh install opens straight into plughole 01; the menu leads with 01, with daily and endless hidden until they open. | HANDOFF, architecture |
| C5 = C | 2026-11-01 | The pack dock appears once plughole 09 is solved. | HANDOFF, architecture |
| C6 = C | 2026-11-01 | A one-time "new" mark on a cover when its pack fits the player's progress or an update adds levels, and "2/3 free" under a started pack. | HANDOFF, architecture |
| C7 = C | 2026-11-01 | Complete shows only while it costs less than the unowned packs, with the saving said. | HANDOFF, architecture |
| C8 = C | 2026-11-01 | One completion line, plus one quiet "try <pack> ›" while a pack is unowned. | HANDOFF, architecture |
| C9 = B | 2026-11-01 | Three result marks (solved, at par, clean), drawn in the design pass; shape set in D3. | HANDOFF |
| C10 = A | 2026-11-01 | The timer is off the result card and out of the best's ranking; ties keep the older best. | HANDOFF, architecture |
| C11 = A | 2026-11-01 | The count is amber at par and magenta past it; the over-par veil is 0.05 a move, capped at 0.2. | HANDOFF, architecture |
| C12 = A | 2026-11-01 | Reset takes a second tap: "reset? tap again" for 2 s. | HANDOFF, architecture |
| C13 = A | 2026-11-01 | A drag the system cuts off commits everywhere, as V26, after a phone check of which handler runs first. | HANDOFF, architecture |
| C14 = A | 2026-11-01 | A pushed tick says at once "That tick can't come back. Undo, or again." and the tank plays on; with the undo bank empty it says "... Reset.". | HANDOFF, architecture |
| C15 = A | 2026-11-01 | A ghost finger rides the lens's track on Lens 01 until the first lens commit. | HANDOFF |
| C16 = B | 2026-11-01 | A "colour letters" switch in settings, defaulting to Differentiate Without Colour, and one line on Prism's card. | HANDOFF, architecture |
| C17 = A | 2026-11-01 | Settings has music, sounds and haptics switches; "report a problem" mails the log; the policy lives on Jack's own domain. | HANDOFF, architecture |
| C18 = A | 2026-11-01 | The daily's gate stays at plughole 23 for v1, with a quiet run count on the row and "next daily in 7 h" on the card. | HANDOFF, architecture |
| C19. Swiping back | 2026-11-01 | An edge swipe back, as elsewhere in iOS; a lost tank keeps its save until "again" or a solve clears it, built on `lost-resume`. | HANDOFF, architecture |
| C20 = B | 2026-11-01 | One rating request, after the solve that opens whirlpool; never after a loss, a spill or a purchase. | HANDOFF, architecture |
| C21 = A | 2026-11-01 | After a purchase the card stays with "play 04 ›" lit; an Ask to Buy approval says "Lens is yours" once on the menu. | HANDOFF, architecture |
| C22 = A | 2026-11-01 | Opt out of Mac and Vision Pro for v1 in App Store Connect; revisited by F7. | HANDOFF |
| D1 = A | 2026-11-01 | The menu's line under the title is dropped; "Every stir in this tank has an exact inverse." goes on the App Store page. | HANDOFF |
| D2 = A | 2026-11-01 | The sandbox's row sits at the end of the list, under "anything goes". | HANDOFF |
| D3 = A | 2026-11-01 | The result marks are dots, one to three filled. | HANDOFF |
| D4 = A | 2026-11-01 | The second "‹ levels" on the solved and out-of-ticks cards is removed. | HANDOFF |
| AR1 = A | 2026-11-01 | The age-range sheet shows on the menu, never over a level or its opening. | HANDOFF |
| EC1 = A | 2026-11-01 | Publish no geographic address beyond the seller's name, a working support email and the GitHub page; give the address to anyone who asks. | HANDOFF |
| P1 = B | 2026-11-01 | "again" on the daily's card plays the daily as practice and saves nothing. | HANDOFF, architecture |
| P2 = A | 2026-11-01 | Prism's level colour is white for now; the design pass settles it. | HANDOFF |
| S1 = A | 2026-11-01 | Both words kept: "Undo, or again." on the play screen against "reset". | HANDOFF |
| S2 = A | 2026-11-01 | A vertical touch in the edge-swipe band is a rim turn, as iOS's own edge pan. | HANDOFF, architecture |

## Round 14

2026-11-02, the game and build calls (money and marketing calls are in `HANDOFF.private.md`).

| Call | Date | Decided | Where |
|---|---|---|---|
| F1. Launch timeline | 2026-11-02 | Option B: launch at P+91, nominate for featuring at P+4 to P+7, open the pre-order at P+49. | HANDOFF |
| F2 = B | 2026-11-02 | Under Reduce Motion live pictures hold a still frame and endless's pour cuts to its end. | HANDOFF, architecture |
| F3 = B | 2026-11-02 | One quiet line on plughole 01's first open, pointing at settings, once. | HANDOFF, architecture |
| F4 = C | 2026-11-02 | A String Catalog at launch; languages as their own update, nominated at L+6 to L+8 weeks. | HANDOFF |
| F5 = B | 2026-11-02 | Game Center sign-in plus achievements, no leaderboards, if the sign-in overlay test on an iOS 26.2 phone passes. | HANDOFF, architecture |
| F6 = A | 2026-11-02 | iPhone only at launch; native iPad as the first big update. | HANDOFF |
| F7 = C | 2026-11-02 | Mac and Vision Pro off at launch, QA at month 1, then the Mac on with its own nomination; revisits C22. | HANDOFF |
| F9 = A | 2026-11-02 | One Apple Arcade pitch on P with a reply by P+28; the pre-order waits for it. | HANDOFF |
| F10 = A | 2026-11-02 | Claude scopes the iPhone Duo; it must be polished, as Apple will be paying attention. | HANDOFF |
| F11 = B+C | 2026-11-02 | An editors' TestFlight build with a visible "open every tier" switch, never in the App Store build, plus a 60 s film of the later tiers. | HANDOFF, CLAUDE.md |
| F12 = A | 2026-11-02 | EU storefronts stay closed; the UK is unaffected. | HANDOFF |
| M1 = B2 | 2026-11-02 | Rename Complete now to a self-limiting bundle, one per three packs; no later pack joins it. | HANDOFF, architecture |
| M2 = A | 2026-11-02 | A tracked App Store link on its own last line of the share line, in the build that goes to review. | HANDOFF |
| M6 = A | 2026-11-02 | All six smaller marketing builds: promoted purchases, the daily archive, the supporter mark, mid-level resume, a "more puzzles in the packs ›" line, and the frozen generator left as is. | HANDOFF, architecture |
| M7 = A | 2026-11-02 | Keep the daily's gate after plughole 23, with honest copy that the daily opens after the ladder. | HANDOFF |
| PR100-V26 = A | 2026-11-02 | A two-finger twist over a held rod commits the rod's turn, then turns the tank. | HANDOFF, architecture |
| PR85 = A | 2026-11-02 | L1's ghost finger approved. | HANDOFF |
| PR104 = A | 2026-11-02 | The two pack-card wordings approved. | HANDOFF |
| P1-clean = A | 2026-11-02 | A clean first-try daily offers no "again". | HANDOFF |
| CAP = A | 2026-11-02 | The clean capture keeps the bezel and the solve wave. | HANDOFF |

## Round 15

2026-11-02, the morning page.

| Call | Date | Decided | Where |
|---|---|---|---|
| PR100-phone = A | 2026-11-02 | The cut-off drag works as described on the phone; #100 merged. | HANDOFF |
| B-name = A | 2026-11-02 | The bundle is named Triptych. | HANDOFF, architecture |
| B-numeral = B | 2026-11-02 | "Triptych I" from day one, so a second bundle is Triptych II. | HANDOFF, architecture |
| G-list = A | 2026-11-02 | All 16 achievements (255 points) as built, the four that could read as pressure kept; Game Center stays off until the sign-in test passes. | HANDOFF, architecture |
| G-hidden = A | 2026-11-02 | Five achievements hidden, as built. | HANDOFF |
| G-playtest = A | 2026-11-02 | Playtest builds report to Game Center's sandbox; only screenshot and test launches never report. | HANDOFF |
| G-banner = A | 2026-11-02 | Game Center's completion banner shows, over the result card. | HANDOFF |
| G-link = A | 2026-11-02 | GameKit is linked but never called while the switch is off. | HANDOFF |
| D-layout = 3 | 2026-11-02 | The open Duo gets split play (tank in one half, chrome and cards in the other) plus the menu beside play. | HANDOFF, architecture |
| D-tent = A | 2026-11-02 | Portrait on the closed display. | HANDOFF |
| D-margin = A | 2026-11-02 | Leave the closed Duo's 16 pt margin as it is. | HANDOFF |
| E-next = A | 2026-11-02 | Eyes Shut next goes to 3 to 5 blind testers; build only if two of them solve quad levels unaided. | HANDOFF |
| R-motion = A | 2026-11-02 | Plughole 01's settings line stays as built, with no "motion". | HANDOFF |
| R-spill = B | 2026-11-02 | Endless's spill card shows at once under Reduce Motion, not after 2 s. | HANDOFF, architecture |
| R-mark = A | 2026-11-02 | The supporter mark stays as built. | HANDOFF |
| R-packsline = A | 2026-11-02 | "more puzzles in the packs ›" stays as built. | HANDOFF |
| R-promo = A | 2026-11-02 | A promoted bundle that costs more than the packs left opens its card and buys, as built. | HANDOFF |
| R-reel = B | 2026-11-02 | Lens goes into the editors' reel, filmed from a warm start. | HANDOFF, CLAUDE.md |
| R-arch-where = A | 2026-11-02 | The archive is a row under today's daily, its calendar over the menu. | HANDOFF |
| R-arch-lock = A | 2026-11-02 | Tapping the locked archive shakes and says "unlocked by purchasing any pack" for 2 s, never opening the shop. | HANDOFF, architecture |
| R-arch-best = A | 2026-11-02 | Archive days and bests stay as built. | HANDOFF |

## Round 16

Main calls 2026-11-02 (finish-and-pitch page); follow-up picks 2026-11-03; third picks 2026-11-04; fourth picks 2026-11-08, all of which took the recommendation.

| Call | Date | Decided | Where |
|---|---|---|---|
| ORDER = A | 2026-11-02 | Order of work: the Duo's stages 2 to 4, the architecture pass's three, the UI design pass, the String Catalog, then store media retaken; confirmed again on 2026-11-03. | HANDOFF |
| ARCH = A | 2026-11-02 | All three top architecture items: split TankView.swift, cut CLAUDE.md and HANDOFF.md to a short map plus area docs, and a typed shader-argument encoder. | HANDOFF |
| DOCKFADE = A | 2026-11-02 | Keep #115's one fade-in of the dock on launch. | HANDOFF |
| DUO2 = A | 2026-11-02 | Both stage 2 choices as built: tabletop "unstirred." at the upright half's foot with a 398 pt glass; a turn in flight at a fold lands as shown. | HANDOFF |
| DUOMENU = B | 2026-11-02 | Stage 5: the tank on the left at stage 1's glass, the menu on the right. | HANDOFF, architecture |
| DUOCAP = C | 2026-11-02 | A higher cap than 1300 px with shallower stacks allowed at that size; refined as duocap2 and duocap-step. | HANDOFF |
| VORTEXSHOT | 2026-11-02 | Store screenshot 4 is vortex 14, "Monsoon" (isobars). | HANDOFF |
| STOREMEDIA = B | 2026-11-02 | The free-game preview is cut to 25 s; the Calm segment's snap to its end is a bug to fix. | HANDOFF, CLAUDE.md |
| SOUNDSK | 2026-11-02 | Pack sound layers: Lens B, Escapement B, Prism A; the ratchet tick must sound like small metal ticking on metal, so new sketches went to his ear. | HANDOFF |
| CAT1 to CAT8 = A | 2026-11-02 | All eight String Catalog calls as recommended (pack names never translate, tier names translate, Prism's R, G, B kept, development language `en`, and so on). | HANDOFF |
| EYES1 = A | 2026-11-02 | Host Eyes Shut's prototype on GitHub Pages from a new small public repo, which Jack creates. | HANDOFF |
| EYES2 = B | 2026-11-02 | The blind testers' thank-you is the smaller voucher each. | HANDOFF |
| C1A = B | 2026-11-02 | A line for the skip-ahead case only: "The first three are free. 22 more in Lens." above buying. | HANDOFF, architecture |
| C1B = A | 2026-11-02 | The card's "‹ back" is pinned over its top at every scroll position. | HANDOFF, architecture |
| C20 = A | 2026-11-02 | TestFlight installs and the rating request: as decided. | HANDOFF |
| N1 = A | 2026-11-02 | No note for plughole 02, Drip, as built. | HANDOFF |
| SND1 = B | 2026-11-02 | The detent tick during a drag is dropped; the haptic and dashes carry the steps. | HANDOFF, architecture |
| SND2 = A | 2026-11-02 | Endless's rule everywhere: cancelling your own push flashes white; magenta and the heavy tap mean a real heal. | HANDOFF, architecture |
| SND3 = B | 2026-11-02 | Share links tap, through a button that opens the share sheet itself. | HANDOFF, architecture |
| AGE1 = A | 2026-11-02 | The age gate asked for is 18 alone, as built. | HANDOFF |
| AGE2 = A | 2026-11-02 | The questionnaire's age-assurance row answers Yes. | HANDOFF |
| J5 = A | 2026-11-02 | Keep Escapement's forced-wait rule. | HANDOFF |
| J8 = A | 2026-11-02 | Accept problems 9 and 11's many lines at par. | HANDOFF |
| ESC-PAPER = B | 2026-11-02 | Build the bone-paper page for Escapement in v1. | HANDOFF, architecture |
| ICLOUD = A | 2026-11-02 | Build iCloud key-value sync of bests for v1, off behind `ICLOUD = NO` until the pre-flip steps. | HANDOFF, architecture, CLAUDE.md |
| APPSIZE = B | 2026-11-02 | A CI size guard that fails past 100 MB, as a workflow step. | HANDOFF, CLAUDE.md |
| A5 = B | 2026-11-02 | Defending the name on Apple Ads: a campaign ready, spent only once a rival bids on the name. | HANDOFF |
| A6 = A | 2026-11-02 | No UK pre-order push. | HANDOFF |
| M10 = A | 2026-11-02 | Organic reach through new accounts in the studio's name, from zero; personal accounts stay out. | HANDOFF |
| M14 = C | 2026-11-02 | No address for a paid Android port for now; a paid port is closed until Jack revisits. | HANDOFF |
| HISTORY = A | 2026-11-02 | Leave history alone for the old device identifier; the repo goes private at launch, so cost PR and nightly runs against the Actions allowance first. | HANDOFF |
| lenscap2 = A | 2026-11-03 | d3-lenscap's cap counts the whole open stir, as built; no Lens level reaches it. | HANDOFF, architecture |
| archive-close = A | 2026-11-03 | The archive beside the list reads "✕ close" as the card does; merged in #136. | HANDOFF, architecture |
| store-sandbox = A | 2026-11-03 | Drop the sandbox bullet and mention from `docs/store-page.md` (guideline 2.3); merged in #136. | HANDOFF |
| duocap2 = D | 2026-11-03 | The open Duo upright's glass is 1471 px, stacks as deep as on an iPhone, only the four-tap limit shrinking (to 17 then; rescaled by r16c-duoprior). | HANDOFF, architecture |
| duocap-step = A | 2026-11-03 | The four-tap limit stays 30 up to 1300 px, then follows the measured curve; every iPhone and pose drawn today is unchanged. | HANDOFF |
| soundsk2 = D | 2026-11-03 | Escapement's ratchet tick is the steel pawl on a steel wheel; merged in #138. | HANDOFF, architecture |
| soundsk-defaults = A | 2026-11-03 | Keep all four tick defaults: -30 LUFS, four takes in turn, demonstration ticks sound, each tick on its core's turn. | HANDOFF |
| soundsk-layers = B | 2026-11-03 | One more listen first, with each pack layer rendered under a real level's play. | HANDOFF |
| soundsk-pushtick = B | 2026-11-03 | A tick that pushes plays the push sound at the tick's own time, with its flash (#139). | HANDOFF |
| soundsk-haptic = B | 2026-11-03 | One haptic tap per tick, with its sound (#139). | HANDOFF, architecture |
| s5-chrome = B | 2026-11-03 | Beside the menu the header and controls go round the tank, as the pitch's picture had it, not as built ("Right of 'as built' looks cramped"). | HANDOFF, architecture |
| s5-title = A | 2026-11-03 | The title and gear are hidden while a level plays; reopened as s5b-title. | HANDOFF |
| s5-card = A | 2026-11-03 | A pack card or the archive while a level plays goes over the right half, the level playing on. | HANDOFF |
| s5-paper = A | 2026-11-03 | Escapement's paper beside the menu is bone wherever the level draws, the menu a black block. | HANDOFF |
| s5-swipe = A | 2026-11-03 | The back swipe beside the menu slides nothing; past the threshold the level leaves through the dip. | HANDOFF |
| s5-tabletop = A | 2026-11-03 | The tabletop menu's dock sits at the foot of the flat half, with cards there. | HANDOFF |
| s5-playing = A | 2026-11-03 | The row being played shows a hairline plus "playing" under its title, its result kept. | HANDOFF |
| s5-clip = A | 2026-11-03 | A card's clip plays beside a playing tank until stage 6 benches a real Duo. | HANDOFF |
| appsize2 = A | 2026-11-03 | Keep the app-size CI step at 100 MB, as merged. | HANDOFF |
| icloud-defaults = A | 2026-11-03 | Accept all four iCloud rules as built. | HANDOFF |
| icloud-editors = A | 2026-11-03 | No sync in the editors' build or under the unlock; their progress stays on that phone. | HANDOFF, architecture |
| icloud-endless = A | 2026-11-03 | Sync endless's best too. | HANDOFF, architecture |
| icloud-started = A | 2026-11-03 | Sync started flags: once tried anywhere, a level is tried everywhere. | HANDOFF, architecture |
| snd1-clunk = B | 2026-11-03 | Silence the rim drag's tank clunk too: every drag is silent and only the haptic marks the tank's steps. | HANDOFF, architecture |
| snd2-sandbox | 2026-11-03 | The sandbox needs work and is not in v1 (a pack's mechanics should join it once owned): defer it and withhold it from Release, as First Stir is. | HANDOFF, architecture |
| store-endless-tail = A | 2026-11-03 | The endless preview segment ends 1 s into the spilled card, as built. | HANDOFF |
| paper-defaults = A | 2026-11-03 | Accept the paper build's five defaults. | HANDOFF |
| paper-rm = A | 2026-11-03 | A solve on paper under Reduce Motion draws nothing on the picture; the card and chime carry it. | HANDOFF |
| paper-vermilion = A | 2026-11-03 | Keep both vermilions, as built. | HANDOFF |
| paper-accents = A | 2026-11-03 | Keep the magenta heal ring and cyan pointers on bone. | HANDOFF |
| paper-statusbar = A | 2026-11-03 | Leave the dark status bar during a back swipe. | HANDOFF |
| d2-cardpos = A | 2026-11-03 | Caption and card centred together in the split and tabletop, as merged. | HANDOFF |
| d3-lenscap = B | 2026-11-03 | Cap a long lens drag on the Duo at what the pane can show. | HANDOFF, architecture |
| d4-one = A | 2026-11-03 | A card and the archive beside the list open one at a time, as built. | HANDOFF |
| d4-empty = A | 2026-11-03 | The right half with nothing open stays empty. | HANDOFF |
| d4-dock = A | 2026-11-03 | The dock keeps turning beside an open card. | HANDOFF |
| d4-table = A | 2026-11-03 | Leave the tabletop menu for stage 5. | HANDOFF |
| d4-pose = B | 2026-11-03 | A card open through a fold or unfold keeps its scroll position. | HANDOFF, architecture |
| d4-menuback = B | 2026-11-03 | The card's back beside the menu reads "✕ close" in the wide pose. | HANDOFF, architecture |
| s5b-glass = A | 2026-11-04 | One glass size per list beside the menu, as built (424 pt for most, 419 maelstrom, 415 Escapement, 394 Prism with letters, 348 endless). | HANDOFF, architecture |
| s5b-words = A | 2026-11-04 | "unstirred." heads the card over the menu half, as built. | HANDOFF |
| s5b-title = B | 2026-11-04 | The title and gear show while a level plays, the trailing half the menu exactly as with no level open. | HANDOFF, architecture |
| s5b-back = B | 2026-11-04 | A pack card opened from a result card reads "✕ close" while the result card is under it. | HANDOFF, architecture |
| tk-push = B | 2026-11-04 | A pushed tick sounds the ratchet and the push at the same instant ("It still stands out"). | HANDOFF, architecture |
| tk-multi = C | 2026-11-04 | When a move's stir and ticks both push, only the first push sounds; later pushed ticks play the ratchet with the error haptic. | HANDOFF, architecture |
| tk-finish = B | 2026-11-04 | The chime and the solve wave move to the last move's last tick. | HANDOFF, architecture |
| taps-floor = A | 2026-11-04 | The adaptive four-tap budget may drop no lower than 12 on every device (also named TAPS-FLOOR). | HANDOFF, architecture |
| taps-ceil = A | 2026-11-04 | It may climb no higher than 42, maxStack 36 plus the heaviest live picture's 6 (also named TAPS-CEIL). | HANDOFF, architecture |
| taps-keep = C | 2026-11-04 | Phone-sized glass starts at a fixed 40 and #140's adaptive law stays on for heat and the Duo; `ADAPTIVE_TAPS` defaults to YES. | HANDOFF, architecture, CLAUDE.md |
| wp27-table = B | 2026-11-04 | Leave whirlpool 27 as dealt (32 against the old limit of 30; under 40 it draws four taps). | HANDOFF, architecture |
| ci-time = B | 2026-11-04 | Split the test job into build-for-testing on the cache and test-without-building, and investigate time spent on tests that do not ensure quality. | HANDOFF |
| lay-esc = A | 2026-11-04 | Leave Escapement B's layer level in real play. | HANDOFF |
| r16c-pointer = C | 2026-11-08 | Plughole 01's settings line is not shown beside the menu but is still stored as shown. | HANDOFF, architecture |
| r16c-prismglass = A | 2026-11-08 | Prism's glass keeps resizing from the in-app letters switch. | HANDOFF |
| r16c-solvetick = A | 2026-11-08 | A special tick keeps the ratchet sound with the special haptic in place of the tap, as built. | HANDOFF |
| r16c-duoprior = B | 2026-11-08 | The Duo upright's starting four-tap limit is rescaled from the phones' 40 and the entry in flight: 23 at 1471 px, 30 at 1300.5. | HANDOFF, architecture |
| r16c-ci-build = A | 2026-11-08 | Investigate the slow CI build step. | HANDOFF |
| CI investigation | 2026-11-08 | Make fixes 2 and 3, let the phase lines through the grep, measure the boot both ways, and research fix 4 without `env -i`; built in #150. | HANDOFF |
| r16c-ci-limit = B | 2026-11-08 | The PR job's time limit is 15 minutes (#147); the rule to raise a build over 10 minutes with Jack stands. | HANDOFF, CLAUDE.md |
| r16c-ci-nightly = B | 2026-11-08 | Leave the nightly unsplit. | HANDOFF |
| r16c-ci-firststir = A | 2026-11-08 | First Stir's two stray tests are skipped on PRs and kept nightly (#147). | HANDOFF, CLAUDE.md |
| Dock covers draw knobs | 2026-11-08 | In chat: every dock cover draws its knobs so a cover shows how its pack plays (#146); the promoted-purchase images are recorded differently (sources differ). | HANDOFF, architecture |

## Round 17

Calls 2026-11-09 (finish-and-pitch page); each took the recommendation.

| Call | Date | Decided | Where |
|---|---|---|---|
| DESIGN5 = A | 2026-11-09 | The UI design pass builds all five changes: one Dynamic Type scale (body 17), five text tones, one button in three emphases, results as dots, the menu and result card rebuilt round the next move; after the TankView split. | HANDOFF |
| CATORDER = D | 2026-11-09 | Split the String Catalog: the table strings (Levels.swift, Pack.swift, the catalog file and lint) now; the five chrome files after the design pass. | HANDOFF |
| ESCBOOK = A | 2026-11-09 | Close J3 (already D1's, clockwise from twelve), J5, J7 and J8 as built; Jack's phone play of the book (E3) still vetoes any one problem. | HANDOFF |
| ARCHREST = A | 2026-11-09 | Before v1, architecture items 4 (one undo record), 5 (shader test kit, no default arms in Picture), 7's shots half (shots.sh split by area) and 13 (First Stir compiled out of Release); the rest after v1. | HANDOFF |
| PERF = A | 2026-11-09 | Close the performance pass at #140; the twist-chain cache is set aside until testers' logs show a kept budget under 40 or a real Duo misses frames. | HANDOFF |
| TFREAD = D | 2026-11-09 | Read TestFlight play from App Store Connect's per-tester sessions polled daily, testers' sent logs and a short survey; check the poll separates days on Jack's install first, with analytics in TestFlight builds as the fallback. | HANDOFF |
| DOTS-KEPT = A | 2026-11-10 | Results as dots (#172) stays as merged: the card shows this solve's marks and the best in words, Escapement rows and the archive keep words, the marks scale with the type and land after the card's reveal, the daily row shows marks and its run, pack-card rows show clean. The small-phone check of the taller card is still owed. | HANDOFF |
| TONES-KEPT = A | 2026-11-10 | The five text tones (#171) stay as merged, with the tones chosen where the proposal was silent. | HANDOFF |
| BUTTONS = B | 2026-11-10 | One button in three emphases (#173) merges after fixes, shown to Jack again first: at xxxLarge nothing falls off the bottom of the result card (it does on master too), and a paid pack's play screen stops reading the pack's name twice (the back button "‹ Escapement" over the heading "ESCAPEMENT"). The rest is approved. | HANDOFF |
| STAMP = A | 2026-11-10 | "unstirred." scales with the player's text size (`r17-stamp`); the Duo tabletop's fixed 28 pt for it is checked with it. | HANDOFF |
| LENSART = B | 2026-11-10 | Lens gets 25 standalone panels, each drawing its level's name, with what is seen through it under the lens; drawn and shown in batches (draft #157 holds the first). | HANDOFF |
| SOUNDLAYERS = A | 2026-11-10 | The three pack sound layers ship as built (#158), before TestFlight. Jack heard the films as choppy; he has heard the layers already and will listen on the phone. | HANDOFF |
| ATB-DATE = A | 2026-11-10 | The stored Ask to Buy date (#154) stays. | HANDOFF |
| ATB-WAIT = A | 2026-11-10 | A pending Ask to Buy shows as waiting for 24 hours after a relaunch, as built. | HANDOFF |
| F14 = B | 2026-11-10 | A pack card opened before the store's first check reads "checking purchases…" until the check ends (`r17-f14`). | HANDOFF |
| DUOPROBE = A | 2026-11-10 | The Duo-speed probe stays out of the main branch entirely. | HANDOFF |
| CIPRIVATE = A | 2026-11-10 | When the repo goes private, CI runs on a self-hosted runner on Jack's Mac, queued behind his builds, the nightly weekly (`r17-ci-private`, not yet run). | HANDOFF |
| CODEQL-PRIVATE = A | 2026-11-10 | `codeql.yml` is deleted when the repo goes private. | HANDOFF |
| OVERPAR = A | 2026-11-11 | A row solved over par shows its "+n" beside its dots again (#174). | HANDOFF |
| PACKNAME = B | 2026-11-11 | In a paid pack the back button reads "‹ levels" and the pack's heading stays. | HANDOFF |
| TEXT-NEVER-SHRINKS | 2026-11-11 | Jack: "The text never shrinks. If the user wants big text, they get big text. To fit it, the tank itself must shrink once a level is completed, if the whole content wouldn't fit on-screen all at once." On small phones too: "the tank scales; text and UI does not." | HANDOFF |
| MENUCARD = A | 2026-11-11 | Design change 5 goes in as built (#180), but the text under the tier chips ("next:", the streak) is poorly spaced and must be fixed; Jack asks whether it needs to be there. | HANDOFF |
| STREAK = B | 2026-11-11 | The daily's row keeps its dots; the streak goes under its title. | HANDOFF |
| COMPLETION = A | 2026-11-11 | A completion line keeps its colour and glow. Jack: "The payoff should actually be significantly more rewarding and exciting", and wonders about credits. | HANDOFF |
| ENDLESSLINE = A | 2026-11-11 | "deeper every tank" is left unsaid. | HANDOFF |
| STAMP-SMALL = B | 2026-11-11 | On a short screen "unstirred." sits below the title; "If necessary, the tank scales." | HANDOFF |
| LENSPANELS = B | 2026-11-11 | The 25 panels ship (#157 merged), Telephoto is redrawn, and Jack plays them on the phone to confirm. | HANDOFF |
| LENSCOVER = B | 2026-11-11 | Lens's face is Kaleidoscope: "Kaleidoscope wins." | HANDOFF |
| LENSSOFT = B | 2026-11-11 | A lens's core is drawn finer so x8 is crisp. Jack: "It's a paid pack. Laziness for expediency is unacceptable. I respect my future players." | HANDOFF |
| SND1 taken back | 2026-11-11 | Jack: "i kinda miss the sound that went with the rod-turning haptics...can you quickly put that back in?" A rod's drag ticks at each step again, under its haptic; SND1 = B (2026-11-02) no longer holds. The tank's clunk stays silent (snd1-clunk = B). | architecture |
| SHAREDOTS | 2026-11-11 | The daily's share line shows the three result dots after its name, in place of a square per move (Jack: "the coloured squares? idk what they're for"; then "dots"). The link stays on its own last line once it exists (M2 = A). | Share.swift |
| GLASSSHRINKS = A | 2026-11-11 | The stack merges as built: a card that does not fit shrinks the tank from its top (never below 55%, then it scrolls), "‹ levels" on a paid pack's way out, the rebuilt menu and card, "unstirred." growing and sitting under the title on short screens (#173, #180, #178). | HANDOFF |
| NEXTLINE = A | 2026-11-11 | The menu's "next:" line under the tier chips goes; the list's marker bar shows the next level. | HANDOFF |
| LENSFACE = A | 2026-11-11 | Lens's cover, clip, promo image and the bundle's wedge show Kaleidoscope seven moves into its line (#185). | HANDOFF |
| TELEPHOTO = A | 2026-11-11 | The redrawn Telephoto stands (#185). | HANDOFF |
| CRISP = A | 2026-11-11 | The finer lens core merges and goes on the phone to check (#187). Jack: "How exciting. This looks lovely." | HANDOFF |
| ESCPICTURES = A | 2026-11-11 | Escapement gets a plate per problem, drawn as its name. | HANDOFF |
| MUSIC-THROUGH | 2026-11-11 | Jack, on the packs' layers: "i don't want the packs' foreground to fade when the level is solved then come back in the same spot on the next level; i want it to keep playing all the way through". | HANDOFF |
| PAYOFF = C | 2026-11-11 | Finishing a tier, a paid pack or the free game plays the curtain call, with a credit line after the game. Jack: "I just don't like how A re-stirs to reward you for unstirring. Curtain call looks cleanest to me." The credit's words are not decided. | HANDOFF, architecture |

## Round 18

Calls 2026-11-11 (the page of built options after Jack's playthrough of the paid packs).

| Call | Date | Decided | Where |
|---|---|---|---|
| ESCWAIT = untouchable clocks | 2026-11-11 | Escapement's clocks can never be touched; the twenty levels that needed a wait are dealt again (#194). Chosen against Claude's recommendation, a labelled wait button (#191, closed). | HANDOFF |
| UNDOASIDE = keep | 2026-11-11 | While reset is armed and the row cannot hold both labels on a line each, undo steps aside (#200). | HANDOFF |
| ESCPLATES = take all | 2026-11-11 | Escapement takes all thirty per-level pictures (#196); the Pause picture is to be redrawn after. The redraw is on hold: with the wait gone, level 7's name is back with Jack. | HANDOFF |
| LENSQUAD = move | 2026-11-11 | Lens's Spectacles, Bifocals and Night vision are redrawn and moved to the three-rod glass (#195, which carried #190). | HANDOFF |
| PRISMAID = leave | 2026-11-11 | No aid for reading a count from the knobs. Jack: "The issue with reading was not reading the knobs. It was with reading the picture itself while turning the rod. I think you investigated the wrong problem here." | HANDOFF |
| ESCNOTES = keep | 2026-11-11 | Escapement's per-move notes start again each level, as built. | HANDOFF |
| VOICENEXT = keep | 2026-11-11 | VoiceOver's "next, not played" stays, as built. | HANDOFF |

## Round 19

Calls 2026-11-11, night (the second follow-up page, six calls, all answered).

| Call | Date | Decided | Where |
|---|---|---|---|
| Chapter 2's name | 2026-11-11 | Escapement's second chapter is "Tempo", and level 7's line stays "Unstir in 3 ticks. No move is spare.", both as they stood. | HANDOFF |
| Level 7's name | 2026-11-11 | Escapement's level 7 is named "Counterweight" and keeps its picture of two weights; its id doesn't change. The pause-mark picture is set aside. | HANDOFF |
| Snooze and Standstill | 2026-11-11 | Escapement's levels 8 and 12 keep their names. | HANDOFF |
| Prism's held rod | 2026-11-11 | While a Prism rod is held, the colours it moves are drawn alone in their own colour, and white fades in near the count. Jack: "This is a fantastic solution to the problem. Well done." It goes on his phone before it merges. | HANDOFF |
| The curtain call as built | 2026-11-11 | Change it first and show it again before merging. Jack: "I want the text within the glass. You spaced the text below the glass far too close to it anyway, so it looks shoddy - but yeah I'm left wondering why you chose to build it differently to what I decided? It looks good in the glass. I agree with your decision to shrink the glass and put the curtain call below on small screens." | HANDOFF |
| The credit | 2026-11-11 | The game's one credit reads "made by screendead · thank you for playing". | HANDOFF |

## Round 20

Said in the session, 2026-11-12, after Claude measured two no-wait rules (clocks that slip, and clocks that tick only
when the turned knob crosses them): neither brought back choice, as at most moves only one twist can come off at all.

| Call | Date | Decided | Where |
|---|---|---|---|
| Escapement's wait, reversed | 2026-11-12 | The waiting move comes back as the labelled wait button (#191, merged into #207), and the game makes clear that a clock can tick with no knob turned. This reverses ESCWAIT (round 18), and the twenty problems dealt again go back to their earlier deals. Jack: "Okay, then I reverse my decision, and choose the tick button to wait and make it clear that the ratchets can move without a rod being manually turned." | HANDOFF |

## Dated, no round

| Call | Date | Decided | Where |
|---|---|---|---|
| Tiers behind a purchase | 2026-09-28 | Jack ruled out paying to unlock tiers; every tier stays free. | HANDOFF |
| Paid content | 2026-09-28 | Paid content is picture packs with their own tanks, best with new mechanics, plus a daily archive and supporter mark; packs never open a tier. | HANDOFF |
| Undo bank | 2026-09-28 | Undos are never sold: everyone gets +2 for each day they play, so a long absence does not refill it. | HANDOFF, architecture |
| Top tier | 2026-09-28 | The top tier becomes the seized rod and the turning tank, with bookkeeping as the fallback if the go/no-go fails. | HANDOFF |
| Last heal ends a level | 2026-09-28 | A level ends on the last heal, with no turn home, so par counts no final turn. | HANDOFF |
| Maelstrom's set | 2026-09-28 | Only tanks that need the new skill go in, as a new set; the old N+ scrambles are scrapped; the set is quad, pent and hex. | HANDOFF |
| Tier names | 2026-09-28 | Plughole, whirlpool and maelstrom, leaving room for vortex between whirlpool and maelstrom and charybdis beyond. | HANDOFF, architecture |
| Tier gate | 2026-09-28 | Each tier opens when every level of the tier below is done at par. | HANDOFF, architecture |
| Hints | 2026-09-28 | Hints go: undos are the help, and par stays reachable by persistence alone. | HANDOFF |
| Plughole gets easier | 2026-09-28 | Agreed to Claude's proposal to ease the steep pent and hex levels; made concrete as PH1 on 2026-10-29. | HANDOFF |
| Wrong stir turned back | 2026-09-28 | A wrong stir turned straight back stays free, "for now". | HANDOFF |
| Endless's rules | 2026-09-28 | Endless has no undo, hints or par, ramps faster and goes deeper, and keeps a tank-capacity limit, the brim. | HANDOFF, architecture |
| Brim counts red flashes | 2026-09-28 | Each red flash adds a notch that stays when the stir is turned back; each heal of the tank's own stirs settles one; the run ends at the spill. | HANDOFF, architecture |
| Brim's look | 2026-09-28 | The measuring jug on the real rim in the picture's own colours with the tide's outward-spreading colour grafted on; approved ("very nice"), and the app's film again on 2026-09-29. | HANDOFF, architecture |
| Backgrounds | 2026-09-28 | All five live pictures ship in whirlpool, with the level table agreed; the heartbeat lives in the twins' drawn lines; the twins' extra cost is accepted. | HANDOFF |
| The way in | 2026-09-28 | The tier switcher is the strip, chosen from three working mock-ups. | HANDOFF |
| Public repo | 2026-09-28 | The repo stays public: few will build and sideload it to avoid a small price, and the bet is on being first with the most polish. | HANDOFF, CLAUDE.md |
| Media out of git | 2026-09-28 | Remove media from history with `git filter-repo` (force-push approved in advance), keep `shots/` ignored, and attach pictures to PRs rather than committing them. | HANDOFF, CLAUDE.md |
| README images | 2026-09-28 | The README uses the four suggested images. | HANDOFF |
| Copyright headers | 2026-09-28 | Every code file names Jack in full as copyright holder, 2026. | HANDOFF, CLAUDE.md |
| Sound direction | 2026-09-28 | Everything synthesised in Csound, no samples or stock loops; of two sketches "glass" was chosen, with quieter effects, neon's hum, menu music and a sound for every button. | HANDOFF |
| CodeQL | 2026-09-28 | CodeQL scans the workflows on every PR and Swift on merges to `master` and weekly. | HANDOFF, CLAUDE.md |
| Work queue | 2026-09-28 | The performance pass is queued after the difficulty tiers, and the architecture pass after the performance pass. | HANDOFF |
| Commit and open the PR | 2026-09-28 | When a feature or round of ideation is finished, commit it and open the PR without asking first. | CLAUDE.md |
| Maelstrom's seized knobs | 2026-09-28 | Every maelstrom level has seized knobs. | HANDOFF |
| Refill and the phone's date | 2026-09-29 | Setting the phone's date must not game the undo refill. | HANDOFF, architecture |
| Heal ring, endless and First Stir | 2026-09-29 | Cancelling your own push flashes white; the magenta ring and heavy tap mark only a commit that pops a scramble entry (First Stir: plays a vignette); SND2 extended it. | HANDOFF, architecture |
| Fine graduation ticks | 2026-09-29 | Dropped ("too faint and thin"); the count is dashes again, 2 pt at 0.85 opacity, with one thin line round the disc. | HANDOFF, architecture |
| One-piece sound | 2026-09-29 | Jack's idea of one piece in D that each tank adds layers to; peril rises only between tiers, never within a tank, and the piece runs a long cycle. | HANDOFF |
| Maelstrom's calls | 2026-10-24 | The finale stays M27 (three turns), M2 stays, lean into difficulty, and the park rule has no tie-break. | HANDOFF, architecture |
| Vortex's calls | 2026-10-24 | The whole-tank swirl joins the free game as tier vortex; the rim's meaning must show before a move; no grandfathering; the solver learns the swirl. | HANDOFF |
| Pack names and product ids | 2026-10-25 | Names, level-id prefixes and product ids settled by Jack's yes to the recommended defaults (pinned by tests). | HANDOFF |
| Merging | 2026-10-25 | Claude may merge a PR without asking once CI passes and its checks and quality review pass; a PR resting on an undecided call still waits. | CLAUDE.md |
| Per-player analytics history | 2026-10-25 | No install ID, since a persistent ID makes the data personal; the phone sends one summary on days 2, 7 and 30 with nothing tying it to other rows. | HANDOFF, architecture |
| K2 = A | 2026-10-25 | The breath's slosh peaks near 8°, as built, not a true 12°. | HANDOFF, architecture |
| K3 = A | 2026-10-25 | Vortex's pictures use Claude's interleaved split: nine levels each, no two neighbours alike, isobars opening each layout and taking the finale. | HANDOFF, architecture |
| K4 = A | 2026-10-25 | The four breath defaults as built: none under Reduce Motion, the lesson arc keeps its dark stroke, dashes follow the knob rule, an undo does not restart the rest. | HANDOFF |
| Breath stops once the swirl is used | 2026-10-25 | The breath runs only until the player's first swirl stir commits, then never on any level. | HANDOFF, architecture |
| Breath's wait after a move | 2026-10-25 | The wait after a move stays 10 s. | HANDOFF, architecture |
| Sandbox picture cycle | 2026-10-25 | The sandbox's picture cycle takes vortex's family, skipping only the twins. | HANDOFF, architecture |
| Swirl's profile | 2026-10-26 | The swirl's profile is turned inside out: the glass's edge goes round whole and the swirl lets go towards its still centre (sources differ on the date versus W3). | architecture |
| V26 call | 2026-10-27 | A drag the system cuts off, a second finger or a change of pose lets go as the lift would; extended by C13. | architecture |
| Phone builds are playtests | 2026-10-27 | Every build `run-ios.sh` installs is a playtest, so Jack's own play never lands in real players' numbers. | CLAUDE.md |
| UI design pass | 2026-11-01 | Redraw the text, buttons, cards and sheets as a design system and mock-ups for Jack's call before any SwiftUI changes. | HANDOFF |
| Name audit | 2026-11-01 | Audit every level name, tiers and packs alike, with a naming system per tier or pack; resolved by N1. | HANDOFF |
| Pedantic polish pass | 2026-11-01 | Pass over every UI action and edge case so the app pleases and funnels to the packs without begging. | HANDOFF |
| CI line | 2026-11-01 | The CI line moves to 10 minutes (after #79 ran 7:17); a build over 10 minutes goes to Jack to rethink the approach. | HANDOFF, CLAUDE.md |
| Back button from a bundle's card | 2026-11-01 | Kept Claude's merge call: back from a pack's card opened on the bundle's returns there, reading "‹ Complete" (now "‹ Triptych"). | HANDOFF, architecture |

## Undated, no round

| Call | Date | Decided | Where |
|---|---|---|---|
| Branches and PRs | — | Standing permission to create branches and open PRs without asking. | CLAUDE.md |
| Pushback | — | Jack asked for hard pushback whenever one of his ideas looks wrong; once he has heard it and still decides, carry out his decision. | CLAUDE.md |
| Phone benches | — | No phone benches before the performance pass: they are slow and heat skews them. | HANDOFF |
| Escapement lab branches | — | `esc-lost-line`, `esc-lost-flash`, `esc-tap-anywhere`, `esc-tap-lesson` and `esc-budget-stopwork` are not merged and stay local. | HANDOFF |
