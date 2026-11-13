# App Store page

Drafted 2026-10-27; Jack's calls ST1 to ST7 applied 2026-10-29, each A, so each section holds the chosen text and the
options set aside under it. Revised 2026-11-13 against the game as built: every passage changed that day is a proposal
until Jack approves it, marked "proposed 2026-11-13", and the text he approved stands in this file's history. Every
character count below was measured with a script, not by eye. Anything legal is marked **(check)**: nothing here
settles it.

v1 ships with no analytics (AN1 = A) and is not sold in the EU or EEA at launch (EU1 = B), so this page holds only
the no-analytics texts and the privacy policy for that build. The contact address is Jack's and is written here only as
the token `{{CONTACT_ADDRESS}}`; the address itself is kept outside the repo, in `HANDOFF.private.md`, and goes into App
Store Connect and the hosted pages, never into a tracked file. The same goes for the developer's name in the policy:
`{{DEVELOPER_NAME}}`.

What it is true to: `master` on 2026-11-13, built for release with its tracked defaults (no analytics, iCloud sync
and Game Center off): four tiers of 27 levels, the daily with its frost days, endless, the daily archive and the
supporter mark that any purchase opens, and the three packs as built, Lens's 25 panels, Escapement's 30 problems and
Prism's 30 specimens, with Triptych I. First Stir is out of v1 and compiled out of Release. Built but off in v1, so left
out of the copy: iCloud sync of bests (`ICLOUD = NO`) and Game Center (`GAME_CENTER = NO`); turning either on changes
the description's last line and the privacy policy. Not built: charybdis. Out of v1: the sandbox (Jack's call
store-sandbox = A, round 16).

## Name (30 characters at most)

| Option | Text | Chars |
|---|---|---|
| **A (Jack, ST1)** | Unstir | 6 |
| B, set aside | Unstir: Unwind the Picture | 26 |
| C, set aside | Unstir - Picture Puzzle | 23 |

A: the name is the brand and the subtitle does the explaining; B and C spend the name on words the subtitle can carry.
Unchecked: whether "Unstir" is free in App Store Connect. A name is reserved only when the app record is created, and
nobody can check that before the developer account exists. A trademark search on the name is **(check)**.

## Subtitle (30 characters at most)

| Option | Text | Chars |
|---|---|---|
| **A (Jack, ST2)** | Unwind the stirred picture | 26 |
| B, set aside | Turn the stir back | 18 |
| C, set aside | A picture puzzle in reverse | 27 |

A says what you do and what you do it to. B is the shortest, but it doesn't say there is a picture. C names the genre,
which the category already shows.

## Promotional text (170 characters at most; can be changed without a review)

| Option | Text | Chars |
|---|---|---|
| **A (Jack, ST3)** | A picture, stirred by rods under the glass. Turn them back in the right order and it snaps clean. 108 levels free, a new daily every day, three packs to add. | 157 |
| B, set aside for later | Every stir left a seam. The newest one runs unbroken. Turn the rods back in order and the picture comes clean. Four tiers and a daily, free. | 140 |

A says what is free and that packs exist; B teaches the rule. Since this field changes without a review, B can follow
later, or a line about a new tier when one ships.

## Description (4000 characters at most)

Plain text. Capitals stand in for headings, since the store renders no formatting.

```
A picture sits in a tank of thick fluid. Rods under the glass have stirred it, one after another, and each stir left a ring of sheared picture behind. Turn the rods back in the right order and the picture comes clean.

The rule is simple to say and slow to master: the last stir is on top. Where two rings cross, the newer one runs unbroken across the older. Find the stir that was made last, turn its rod back exactly as far as it went, and the seam heals. Then read the picture again for the next one.

Drag a knob to turn its rod. Let go where you started and nothing happens, so you can look before you commit. Every level has a par, the fewest moves that unstir it. Reset is free in every level. Undos come from a small bank that refills a little on each day you play.

FOUR TIERS, 108 LEVELS, FREE

- Plughole: 27 levels on neon pictures, from one stir on three rods to deep tanks on seven. The first three replay the scramble so you can watch it happen.
- Whirlpool: 27 deeper levels on live pictures that move as you play: glass, chainmail, coral, a web of neurons and marbled ink. More stirs, more of them hidden under louder ones.
- Vortex: 27 levels with a swirl as wide as the glass, which stirs through every other rod. Its pictures are its own: isobars, a sky of orbiting planets, woven cords.
- Maelstrom: 27 levels where knobs have seized. Turn the whole tank to bring the seams round to a knob that still works. The last free tier and the hardest: some levels need a plan, not just a good eye. Its pictures have a heartbeat.

Each tier opens when every level of the one before it is at par.

EVERY DAY

- The daily: one new tank a day, the same tank for everyone on the same date. About one day in seven is a frost day: two knobs freeze under frosted glass, so you turn the whole tank to work round them, and the solve thaws them. Share your result as three dots: solved, at par, clean.
- Endless: tank after tank, with no undo, reset or par. Every stir you waste fills the brim on the rim. Healing the scramble's own stirs lets it settle. Eight notches and it spills.

The daily and endless open once you have cleared plughole's 23rd level.

PACKS

Three packs add their own pictures, tanks and rules. The first three levels of each are free to play.

- Lens, 25 panels: some rods zoom instead of turning. Read how far a picture has grown against a halftone dot screen that never lies about scale.
- Escapement, 30 problems: composed problems with clocks in them. A clock's rod ticks a step by itself after every move you make, on a budget of ticks. Time your heals so every tick finds its seam, and tap wait to let the clocks tick while nothing turns.
- Prism, 30 specimens: every picture is drawn three times, in red, green and blue light, and each rod stirs only some of the colours. Unstir until the ghosts snap back into one white line.

Triptych I unlocks Lens, Escapement and Prism in one purchase. Packs and Triptych I can be shared with your family through Family Sharing. Any purchase also opens the archive of past dailies and adds a small supporter mark by the title and in your share line, which you can switch off.

No ads. No timers. No account. Your progress stays on your phone, and the game sends nothing.
```

Choices and checks in it:
- **Triptych.** The bundle, Triptych I in the app and the store (Jack's call, round 15: a numeral from day one). It grants Lens, Escapement and Prism
  and no later pack ever joins it, so the page names the three and promises nothing about later ones **(check)**.
- **Family Sharing.** On for all four products (Jack, ST6): `StoreKit/Unstir.storekit` already marks each
  family-shareable, and the store code handles family grants. Turn it on for each in App Store Connect too; once on it
  can't be turned off (check).
- **Prices.** Left out: they vary by storefront and the store shows them beside each purchase.
- **Pack sizes.** In, each in its pack's own noun as its card counts it (`Pack.counted`): Lens 25 panels, Escapement 30
  problems, Prism 30 specimens (proposed 2026-11-13).
- **Frost days and maelstrom's plans** (proposed 2026-11-13). Both shipped on 2026-11-12. The maelstrom line says
  "some levels" without naming rows, as which rows need a plan is still Jack's to see. Frost days are in the code from
  2026-10-01 to 2029-12-31, 164 of those 1,188 days, one in 7.2.
- **Archive and supporter mark** (proposed 2026-11-13). Both open with any purchase (`Archive.opens`, `Store.bought`);
  the archive holds every past daily back to 30 days before daily #1. The mark has an off switch in settings.
- **Vortex's swirl.** Worded to fit both the map in CLAUDE.md and a7d5b9f ("turn the swirl inside out"); check it
  against the swirl as it ships.

## Keywords (100 characters at most, comma-separated, no spaces)

Apple already indexes the name and subtitle, so neither option repeats "unwind", "stirred" or "picture"; "puzzle" is
left out as the category's own word (assumed to be indexed through the category; check).

| Option | Text | Chars |
|---|---|---|
| **A (Jack, ST7)** | `twist,unscramble,swirl,rotate,rods,untangle,undo,logic,brain,daily,neon,calm,minimal,order,mind,spin` | 100 |
| B, set aside | `twist,swirl,unscramble,rotate,untwist,rods,knob,logic,brain,daily,neon,relaxing,minimal,order,mind` | 98 |

A leans on what players search for when they look for this kind of game (unscramble, untangle, logic); B swaps in
"relaxing" and "knob". No competitor names in either, which Apple's guidelines forbid.

## Category

| Option | Primary | Secondary |
|---|---|---|
| **A (Jack, ST7)** | Games › Puzzle | Games › Casual |
| B, set aside | Games › Puzzle | Games › Strategy |
| C, set aside | Games › Puzzle | none |

A puts it beside calm puzzle games, where Lens's buyer looks. B suits maelstrom and Escapement's solver, a
smaller audience. Secondary category is optional, so C costs only reach.

## Age rating

As drafted, with the two corrections from a check against Apple's own reference (App Store Connect help, "Age ratings
values and definitions"), accepted with ST7. Apple's July 2025 scheme is 4+, 9+, 13+, 16+ and 18+; each item is
answered None, Infrequent or Frequent, or No and Yes. The questions sit under App Information and may show only once a
version exists.

| Area | Answer | Why |
|---|---|---|
| Violence (cartoon, realistic, prolonged, graphic) | None | Abstract pictures |
| Sexual content, nudity | None | |
| Profanity, crude humour | None | |
| Horror, fear themes | None | Abstract pictures, no scenes |
| Alcohol, tobacco, drugs | None | |
| Mature or suggestive themes | None | |
| Medical or treatment information | None | |
| Gambling, simulated gambling | None | No loot boxes; every purchase names what it unlocks |
| Contests ("competitions for rankings, rewards, or personal goals") | Infrequent | Par, bests and the daily fit. Still 4+, but A6 in Brazil, not AL |
| Unrestricted web access | No | The app's one web page is the privacy policy, shown in Apple's in-app Safari sheet (`SFSafariViewController`), which shows the page's address but has no field to type one **(check)** (proposed 2026-11-13; the reason said "opens Safari") |
| User-generated content, messaging, chat | No | The share line is a text the player sends through the system share sheet; nothing is received |
| Advertising | No | |
| In-app purchases | Yes | Three packs and a bundle of them |
| Parental controls, age assurance | Yes (open) | The game calls Apple's Declared Age Range API and gates nothing; either answer keeps 4+ |
| In-app controls, capabilities, medical or wellness topics, violent themes (added 2025) | None or No | |

Expected result: 4+.

## Screenshots

Each is a `scripts/shots.sh <name>` case, rendered on a Pro Max simulator at 1320 × 2868, one of the sizes App
Store Connect accepts for "iPhone with Dynamic Island (large display)", which also covers the required Face ID (large)
set (its "Screenshot specifications" page, read 2026-11-02: PNG or JPEG, no alpha, up to ten). Jack judges each from
the shots. HANDOFF's rule: lead with the free game, then the packs, each pack shot labelled as a paid add-on (guideline
2.3.2, assumed).

| Option | Set |
|---|---|
| **A (Jack, ST4)** | Seven free-game shots, then one shot per pack (ten, Apple's limit) |
| B, set aside | Nine free-game shots, then one "packs" shot of the shelf |
| C, set aside | Free game only; the packs shown only in their promoted-purchase art |

A shows each pack's look, which is what sells it, and the free game still leads.

The set, in order, with a caption each. `scripts/store-media.sh screens` shoots it (the `store-` cases) and composites
the captions in a draft look:

| # | Case | Caption | Chars |
|---|---|---|---|
| 1 | `store-01-marbling` | Rods under the glass stirred this picture. | 42 |
| 2 | `store-02-count` | Turn a knob back. The newest seam goes first. | 45 |
| 3 | `store-03-wave` | Get the order right and it snaps clean. | 39 |
| 4 | `store-04-vortex` | Vortex: one swirl as wide as the glass. | 39 |
| 5 | `store-05-maelstrom` | Maelstrom: knobs seize. Turn the whole tank. | 44 |
| 6 | `store-06-daily` | A new daily every day, the same for everyone. | 45 |
| 7 | `store-07-endless` | Endless: waste a stir and the brim rises. | 41 |
| 8 | `store-08-prism` | Paid pack · Prism: three colours, one line | 42 |
| 9 | `store-09-lens` | Paid pack · Lens: rods that zoom | 32 |
| 10 | `store-10-escapement` | Paid pack · Escapement: a clock in every problem | 48 |

Notes:
- 9 is proposed 2026-11-13: it said "rods that zoom and spiral", and no rod spirals.
- 2 shows the drag's dashes and count on plughole's grid; `whirlpool-count-marbling` is the same moment on a live
  picture if the grid reads too plain beside 1.
- 3 is plughole level 13 solved; a solve wave on a live picture would need a new case (`UNSTIR_TIER=whirlpool` with the
  same harness solve).
- 4 is vortex 14, Monsoon, on the isobars (Jack's call VORTEXSHOT, round 16). Of the three vortex pictures shot, the
  ephemeris (vortex 13, the first pick) read darkest at thumbnail size and cords (vortex 16) was the recommendation.
- 6 and 7 are harnessed states a player reaches (a solved daily, a brim at 5 of 8), so they show nothing a player can't
  see. The menu shots with `UNSTIR_UNLOCK` (`menu-unlocked`, `menu-maelstrom`) would show every tier open, which no new
  player sees; `menu-vortex-open` is the honest menu if B wants one.
- 8 to 10 are each pack's taste, so none needs owning: Prism 01 with the red stir healed and the cyan held halfway
  back, Lens 03 held mid-zoom, Escapement 02 with its first tick landed. The harness can't hold a tick mid-turn, so 10
  shows the tick landed, not mid-tick.

## Preview video

Each source is a `scripts/film.sh <name>` case. Only films run with `UNSTIR_FINGER=1` show a fingertip; `autoplay-L09`,
`tour` and `open-L12` show the picture moving with no hand. `scripts/store-media.sh preview` films and cuts it to
Apple's limits as read on 2026-11-02 (in the script's header): 886 × 1920, 30 fps, H.264, with a silent stereo track,
since the page doesn't say whether a preview needs one.

| Option | Plan |
|---|---|
| **A (Jack, ST5)** | One preview, about 25 s, free game only: the packs live in screenshots 8 to 10 |
| B, set aside | Three previews: the free game, the tiers, the packs |
| C, set aside | One preview with the packs at its end, each labelled as a paid add-on |

A: the first seconds autoplay muted in search results, and one strong loop of a picture snapping back is the pitch
(plan step 3's clips test the same moment). B triples the cutting work for slots most visitors never open. C is the
fallback if the packs need video to sell.

The cut, in order, at 25 s (Jack's call STOREMEDIA = B, round 16; `STORE_PREVIEW` sets another length, up to
the segments' whole 27.6 s, the four round whirlpool 03 giving up the same share each):

| Seconds | Source | What it shows | Caption (muted playback) |
|---|---|---|---|
| 0–3.35 | `store-open-L12` (`open-L12`, taken long enough to wind in whole) | The clean picture, then every stir growing over it | A picture, stirred |
| 3.35–13.95 | `store-whirlpool-03`: whirlpool 03 unstirred at par by a drawn fingertip to its solve | A hand turning the rods back in order, the seams healing, the wave | Turn the rods back in order |
| 13.95–17.8 | `rim-swirl` | Vortex's swirl held from the rim | Vortex: the swirl |
| 17.8–21.65 | `rim-seized` | Maelstrom's tank turned past a seized knob | Maelstrom: the tank turns |
| 21.65–25 | `endless-brim-run` (its spill) | The brim filling and spilling, ending on its card | Endless, and a daily |

`store-whirlpool-03` also serves plan step 3's social clips, beside three drawn clean (`clean-plughole-05`,
`clean-whirlpool-01`, `editors-vortex-02`).

## Other fields App Store Connect asks for

- **Privacy policy URL** (required): the policy's page on Jack's own domain (Jack's call C17 = A, round 13, which
  replaced ST7's GitHub Pages), written here only as `{{POLICY_URL}}`. The build reads it from `POLICY_URL`, set in the
  shell or `Config/Local.xcconfig` for the archive; a build without it opens the plain github.com page of
  `docs/privacy-policy.md`, the draft, and `scripts/archive-ios.sh` does not refuse one (proposed 2026-11-13).
- **Support URL** (required): a support page on the same domain, `{{SUPPORT_URL}}`, giving `{{CONTACT_ADDRESS}}`
  (proposed 2026-11-13).
- **Contact address** for privacy and support: `{{CONTACT_ADDRESS}}` everywhere in the repo. Jack has picked it; it is
  recorded in `HANDOFF.private.md` only, and filled in App Store Connect and in the published pages at publishing.
- **Marketing URL** (optional). The policy is to live on Jack's own domain (C17 = A); once that domain serves, whether
  its home page is the marketing URL is his call (proposed 2026-11-13).
- **Copyright.** The year and holder of the source files' copyright headers.
- **In-app purchases.** Four products. An id never changes once it is registered with Apple; the bundle's was renamed
  from its first name, Complete, to `triptych1` by Jack on 2026-11-13, before any was. Display names (30 characters at most, assumed; check)
  and descriptions (45 at most, assumed; check), proposed 2026-11-13:

  | Product id | Reference name | Display name | Description | Chars |
  |---|---|---|---|---|
  | `com.screendead.Unstir.pack.lens` | Lens | Lens | 25 panels where some rods zoom | 30 |
  | `com.screendead.Unstir.pack.escapement` | Escapement | Escapement | 30 problems with clocks in them | 31 |
  | `com.screendead.Unstir.pack.prism` | Prism | Prism | 30 specimens in three colours | 29 |
  | `com.screendead.Unstir.triptych1` | Triptych I | Triptych I | Lens, Escapement and Prism | 26 |

  The reference name is App Store Connect's own, never shown to players. `StoreKit/Unstir.storekit`, the local test
  file, holds the same names and descriptions. First Stir's product, in that file, is not created in App Store
  Connect for v1.

  Each also needs a review screenshot and, if promoted, its own art (to-do 50 and 51).
- **Review notes** (App Review Information, Notes; 4000 characters at most, assumed; check). App Review can't open the
  later tiers without playing every level at par, and the developer unlock is off in a Release build (the editors'
  build has a labelled switch, but it is its own TestFlight group, never the one reviewed). Proposed 2026-11-13:

  ```
  No account or sign-in is needed, and the app has no server of its own: purchases go through StoreKit alone.

  How the game opens: the four free tiers (Plughole, Whirlpool, Vortex, Maelstrom) open in turn, each once every level of the one before is solved at par. The release build has no unlock. Plughole's first levels teach the rule; the screenshots and preview show the later tiers.

  The daily and Endless open once Plughole level 23 is solved. About one daily in seven is a frost day, with two knobs frozen under frosted glass: this is intended.

  Paid packs: the row of pack covers at the bottom of the menu appears once Plughole level 9 is solved. Lens, Escapement and Prism each play their first three levels free; buying a pack, or Triptych I for all three, opens the rest. Any purchase also opens the archive of past dailies (a row under today's daily) and a supporter mark (a small star by the title and in the daily's share line, with an off switch in settings). "restore purchases" is in settings (the gear by the title) and on each pack's card.

  Age range: where the system says a law applies, the app asks Apple's Declared Age Range API once a launch. Every level suits all ages, so the answer changes nothing and is not kept.

  Settings, "report a problem", opens a mail to our support address with the app's log attached; nothing is sent unless the player sends it.
  ```

## App Privacy label

The label must match the build that ships: v1 without analytics (`ANALYTICS = NO`, `master`'s default; proposed
2026-11-13, it named the branch `v1-no-analytics`). Derived from the code.

**Data Not Collected.** With analytics off the app opens no network connection of its own. StoreKit's
purchases go between the phone and Apple, and Apple's handling isn't the app's to declare (Apple's guidance, as
understood; check). The daily's share line goes through the system share sheet, which the player directs, and the
send-log button opens a mail the player reads and sends, or the share sheet where Mail has no account (proposed
2026-11-13; it said both went through the share sheet).

### The send-log button

Settings' "report a problem" (proposed 2026-11-13; the button was `ShareLink(item: Log.url)` when ST7 was decided)
opens a mail to the support address in Apple's Mail, `Library/unstir-log.txt` attached and the device line in the body;
where Mail has no account, the share sheet with the address, the subject, the line and the log; the app sends nothing
itself. The log keeps its newest part, cut back to 512 KB once it passes 1 MB: each touch's landing and path in tank
units, commits, undos and resets with the stack, levels opened and left, tank turns, whether a pack is owned as its
levels open, cards shown, purchase and restore failures, the settings switched, a launch line saying whether the boot
session could be read (not its value), the device line once the first screen is up (app version and build, iOS, model,
locale, text size, Reduce Motion, VoiceOver, Low Power Mode, the game's settings and each screen's four-tap budget), and
the phone's thermal state and whether it is charging, at launch and on each thermal change, each line with the phone's
time. It holds no uptime, since a line's time less the uptime would give the boot's instant, and no name, account or
device identifier.

| Option | Label |
|---|---|
| **A (Jack, ST7)** | Don't declare it: optional, infrequent, started by the player each time, through a system sheet that shows where it goes |
| B, set aside | Declare Diagnostics › Other Diagnostic Data, linked (an email carries the sender's address) |

A rests on Apple's "optional disclosure" criteria, unchecked against the current App Privacy page **(check)**; B is
the fallback if App Review reads them otherwise. Either way the privacy policy says what the log holds.

## Still open

1. Before submitting: the checks marked **(check)** above, against App Store Connect's live pages.
2. The captions' look (band, type, size) is a draft for the UI design pass to set; `scripts/store-media.sh` makes the
   set, the preview and the social clips again in one run.
3. ~~The Prism lines describe its design; check them against the pack as it ships.~~ Prism ships; its lines were
   checked against it on 2026-11-13.
4. In App Store Connect's availability, exclude the EU/EEA storefronts (EU1 = B); the EU is out at launch.
5. "Every stir in this tank has an exact inverse." left the menu for this page (Jack's call D1 = A, round 13). Which
   field carries it, the description's rule paragraph or a later promotional text, is not yet decided, so the chosen
   texts above are as Jack approved them.
6. The send-log button's label answer (ST7 = A, don't declare it) was decided for a share-sheet button. The button now
   opens a mail already addressed to the developer, its log attached and the device line in the body, so the call goes
   back to Jack with the mechanism as built (proposed 2026-11-13).
7. iCloud sync and Game Center are built but off (`ICLOUD = NO`, `GAME_CENTER = NO` by default). If either ships on, the description's last line, the privacy label and the privacy policy
   change before the build goes to review.
8. `Share.url` and `Share.firstDay` are still empty, so the share line names the date and carries no link (Jack's calls
   D1 and M2 = A want daily #1 set to launch day and an App Store link on the line in the build that goes to review).
9. `scripts/archive-ios.sh` refuses an archive without `SUPPORT_ADDRESS` but not one without `POLICY_URL`, whose settings
   row would then open this repo's draft policy, a page that goes dark if the repo goes private (CIPRIVATE = A).
10. Follow-up outside the docs: `Config/Unstir.xcconfig`'s comment on `ICLOUD` says these docs call iCloud sync
    unbuilt.
