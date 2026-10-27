# App Store page: drafts for Jack

Draft, 2026-10-27. Nothing here is decided. Where a choice is Jack's, it gives the options and one recommendation.
Every character count below was measured with a script, not by eye. Anything legal is marked **(check)**: it needs
Jack's or a lawyer's check, and nothing here settles it.

What it is true to: `master` at 2f74de9 (four tiers of 27 levels, the daily, endless, the sandbox, StoreKit for three
packs and Complete) and the `analytics` branch at e816c97 (the consent card and Aptabase). Not built, so left out of
the copy: the packs' levels (`Level.firstStir`, `Level.lens` and `Level.escapement` are empty), the daily archive, the
supporter mark, iCloud sync, sound (on `sound`, unmerged) and charybdis. The packs' lines describe the designs in
HANDOFF.md; check them against the packs once they are built.

## Name (30 characters at most)

| Option | Text | Chars |
|---|---|---|
| **A (recommended)** | Unstir | 6 |
| B | Unstir: Unwind the Picture | 26 |
| C | Unstir - Picture Puzzle | 23 |

A: the name is the brand and the subtitle does the explaining; B and C spend the name on words the subtitle can carry.
Unchecked: whether "Unstir" is free in App Store Connect. A name is reserved only when the app record is created, and
nobody can check that before the developer account exists. A trademark search on the name is **(check)**.

## Subtitle (30 characters at most)

| Option | Text | Chars |
|---|---|---|
| **A (recommended)** | Unwind the stirred picture | 26 |
| B | Turn the stir back | 18 |
| C | A picture puzzle in reverse | 27 |

A says what you do and what you do it to. B is the shortest, but it doesn't say there is a picture. C names the genre,
which the category already shows.

## Promotional text (170 characters at most; can be changed without a review)

| Option | Text | Chars |
|---|---|---|
| **A (recommended)** | A picture, stirred by rods under the glass. Turn them back in the right order and it snaps clean. 108 levels free, a new daily every day, three packs to add. | 157 |
| B | Every stir left a seam. The newest one runs unbroken. Turn the rods back in order and the picture comes clean. Four tiers and a daily, free. | 140 |

A says what is free and that packs exist; B teaches the rule. Since this field changes without a review, B can follow
later, or a line about a new tier when one ships.

## Description (4000 characters at most)

2,855 characters with the analytics paragraph, 2,756 without; plain text. Capitals stand in for headings, since the store renders no formatting. The
last paragraph is two variants: use the one that matches the build that ships.

```
A picture sits in a tank of thick fluid. Rods under the glass have stirred it, one after another, and each stir left a ring of sheared picture behind. Turn the rods back in the right order and the picture comes clean.

The rule is simple to say and slow to master: the last stir is on top. Where two rings cross, the newer one runs unbroken across the older. Find the stir that was made last, turn its rod back exactly as far as it went, and the seam heals. Then read the picture again for the next one.

Drag a knob to turn its rod. Let go where you started and nothing happens, so you can look before you commit. Every level has a par, the fewest moves that unstir it. Reset is free in every level. Undos come from a small bank that refills a little on each day you play.

FOUR TIERS, 108 LEVELS, FREE

- Plughole: 27 levels on neon pictures, from one stir on three rods to deep tanks on seven. The first three replay the scramble so you can watch it happen.
- Whirlpool: 27 deeper levels on live pictures that move as you play: glass, chainmail, coral, a web of neurons and marbled ink. More stirs, more of them hidden under louder ones.
- Vortex: 27 levels with a swirl as wide as the glass, which stirs through every other rod. Its pictures are its own: isobars, a sky of orbiting planets, woven cords.
- Maelstrom: 27 levels where knobs have seized. Turn the whole tank to bring the seams round to a knob that still works. Its pictures have a heartbeat.

Each tier opens when every level of the one before it is at par.

EVERY DAY

- The daily: one new tank a day, the same tank for everyone on the same date. Share your result as a line of coloured squares, one per move.
- Endless: tank after tank, with no undo, reset or par. Every stir you waste fills the brim on the rim. Healing the scramble's own stirs lets it settle. Eight notches and it spills.
- The sandbox: any picture, any rods. Nothing counts.

The daily and endless open once you have cleared plughole's 23rd level.

PACKS

Three packs add their own pictures, tanks and rules. The first three levels of each are free to play.

- First Stir: a wordless story of one stormy night in a seaside town, told backwards. Each heal rewinds part of the night, until the last tank is a child stirring a cup of tea.
- Lens: some rods zoom or spiral instead of turning. Read how far a picture has grown against a halftone dot screen that never lies about scale.
- Escapement: a book of composed problems with a clock in them. One rod ticks a step by itself after every move you make. Time your heals so the clock always finds its seam.

Complete unlocks First Stir, Lens and Escapement in one purchase.

[with analytics] No ads. No timers. No account. Your progress stays on your phone. If you say yes when the game asks, it sends counts of how you play, never who you are; you can change your answer in settings.

[without analytics] No ads. No timers. No account. Your progress stays on your phone, and the game sends nothing.
```

Choices and checks in it:
- **Complete.** It names the three packs and promises nothing about later ones (HANDOFF: the store page never promises
  later packs to Complete owners; to-do 55, App Review's rules on Complete, is still open) **(check)**.
- **Family Sharing.** Left out. `StoreKit/Unstir.storekit` marks every product family-shareable, but HANDOFF lists
  Family Sharing among the defaults needing Jack's explicit yes, as it can't be turned off once on (assumed; check). If
  he says yes, add "Packs and Complete can be shared with your family through Family Sharing." after the Complete line.
- **Prices.** Left out: they vary by storefront and the store shows them beside each purchase.
- **Pack sizes.** Left out until built (planned: First Stir 25 scenes, Lens 25 panels, Escapement 30 problems).
- **Vortex's swirl.** Worded to fit both the map in CLAUDE.md and a7d5b9f ("turn the swirl inside out"); check it
  against the swirl as it ships.

## Keywords (100 characters at most, comma-separated, no spaces)

Apple already indexes the name and subtitle, so neither option repeats "unwind", "stirred" or "picture"; "puzzle" is
left out as the category's own word (assumed to be indexed through the category; check).

| Option | Text | Chars |
|---|---|---|
| **A (recommended)** | `twist,unscramble,swirl,rotate,rods,untangle,undo,logic,brain,daily,neon,calm,minimal,order,mind,spin` | 100 |
| B | `twist,swirl,unscramble,rotate,untwist,rods,knob,logic,brain,daily,neon,relaxing,minimal,order,mind` | 98 |

A leans on what players search for when they look for this kind of game (unscramble, untangle, logic); B swaps in
"relaxing" and "knob". No competitor names in either, which Apple's guidelines forbid.

## Category

| Option | Primary | Secondary |
|---|---|---|
| **A (recommended)** | Games › Puzzle | Games › Casual |
| B | Games › Puzzle | Games › Strategy |
| C | Games › Puzzle | none |

A puts it beside calm puzzle games, where First Stir's buyer looks. B suits maelstrom and Escapement's solver, a
smaller audience. Secondary category is optional, so C costs only reach.

## Age rating

Apple revised the questionnaire in 2025, so the wording below is by content area, not Apple's own: match each to the
live questionnaire in App Store Connect **(check)**.

| Area | Answer | Why |
|---|---|---|
| Violence (cartoon, realistic, prolonged, graphic) | None | Abstract pictures; First Stir's storm and flood show no harm to anyone (keep it so as the scenes are drawn) |
| Sexual content, nudity | None | |
| Profanity, crude humour | None | |
| Horror, fear themes | None | First Stir's storm is a mild weather scene; recheck once drawn |
| Alcohol, tobacco, drugs | None | |
| Mature or suggestive themes | None | |
| Medical or treatment information | None | |
| Gambling, simulated gambling, contests | None | No loot boxes; every purchase names what it unlocks |
| Unrestricted web access | No | The app has no web view; analytics posts to one fixed address |
| User-generated content, messaging, chat | No | The share line is a text the player sends through the system share sheet; nothing is received |
| Advertising | No | |
| In-app purchases | Yes | Three packs and Complete |
| Parental controls, age assurance | No | |

Expected result: the lowest rating (4+ under the old scheme). **(check)**: a game rated for young children that asks a
yes or no about analytics at first launch; whether a child's yes is valid consent under GDPR article 8 (the age varies
by country, 13 to 16) needs a lawyer. See the privacy policy draft.

## Screenshots

Each is a `scripts/shots.sh <name>` case, rendered on a Pro Max simulator at 1320 × 2868, which is assumed to be the
6.9-inch size App Store Connect asks for (check). No render was looked at for this draft: Jack judges each from the
shots. HANDOFF's rule: lead with the free game, then the packs, each pack shot labelled as a paid add-on (guideline
2.3.2, assumed).

| Option | Set |
|---|---|
| **A (recommended)** | Seven free-game shots, then one shot per pack (ten, Apple's limit) |
| B | Nine free-game shots, then one "packs" shot of the shelf |
| C | Free game only; the packs shown only in their promoted-purchase art |

A shows each pack's look, which is what sells it; B needs the shelf built; C keeps the page shortest but sells the
packs only to players who scroll to the purchases.

Option A, in order, with a caption each (captions are composited onto the shot, which no script does yet):

| # | Case | Caption | Chars |
|---|---|---|---|
| 1 | `whirlpool25-marbling` | Rods under the glass stirred this picture. | 42 |
| 2 | `count-quad-minus2` | Turn a knob back. The newest seam goes first. | 45 |
| 3 | `wave-0.8` | Get the order right and it snaps clean. | 39 |
| 4 | `vortex-family-ephemeris-13` | Vortex: one swirl as wide as the glass. | 39 |
| 5 | `seized-m23-half` | Maelstrom: knobs seize. Turn the whole tank. | 44 |
| 6 | `daily-result` | A new daily every day, the same for everyone. | 45 |
| 7 | `endless-brim` | Endless: waste a stir and the brim rises. | 41 |
| 8 | to make: a First Stir scene, mid-heal | Paid pack · First Stir: a night told backwards | 46 |
| 9 | to make: a Lens panel with a zoom seam | Paid pack · Lens: rods that zoom and spiral | 43 |
| 10 | to make: an Escapement plate, clock mid-tick | Paid pack · Escapement: a clock in every problem | 48 |

Notes:
- 2 shows the drag's dashes and count on plughole's grid; `whirlpool-count-marbling` is the same moment on a live
  picture if the grid reads too plain beside 1.
- 3 is plughole level 13 solved; a solve wave on a live picture would need a new case (`UNSTIR_TIER=whirlpool` with the
  same harness solve).
- 4 could be `vortex-family-isobars-14` or `vortex-family-cords-16` instead; the planets are the most legible at
  thumbnail size (guessed).
- 6 and 7 are harnessed states a player reaches (a solved daily, a brim at 5 of 8), so they show nothing a player can't
  see. The menu shots with `UNSTIR_UNLOCK` (`menu-unlocked`, `menu-maelstrom`) would show every tier open, which no new
  player sees; `menu-vortex-open` is the honest menu if B wants one.
- 8 to 10 wait on the packs' art and a harness case each (`UNSTIR_PACK=` with a level).

## Preview video

Each source is a `scripts/film.sh <name>` case. Only films run with `UNSTIR_FINGER=1` show a fingertip; `autoplay-L09`,
`tour` and `open-L12` show the picture moving with no hand. Master has no sound, so a preview is silent unless the
`sound` branch is merged first. Apple's current preview limits (length, resolution per device, frame rate) are not
restated here from memory: check them before cutting **(check)**.

| Option | Plan |
|---|---|
| **A (recommended)** | One preview, about 25 s, free game only: the packs live in screenshots 8 to 10 |
| B | Three previews: the free game, the tiers, the packs |
| C | One preview with the packs at its end, each labelled as a paid add-on |

A: the first seconds autoplay muted in search results, and one strong loop of a picture snapping back is the pitch
(plan step 3's clips test the same moment). B triples the cutting work for slots most visitors never open. C is the
fallback if the packs need video to sell.

Option A's cut, in order:

| Seconds | Source | What it shows | Caption (muted playback) |
|---|---|---|---|
| 0–4 | `open-L12` | The clean picture, then every stir growing over it | A picture, stirred |
| 4–12 | **new**: a finger-driven unstir of one level to its solve wave (`UNSTIR_MOVES` with `UNSTIR_FINGER=1`, on a whirlpool level) | A hand turning the rods back in order, the seams healing, the wave | Turn the rods back in order |
| 12–16 | `rim-swirl` | Vortex's swirl held from the rim | Vortex: the swirl |
| 16–21 | `rim-seized` | Maelstrom's tank turned past a seized knob | Maelstrom: the tank turns |
| 21–25 | `endless-brim-run` (its spill) | The brim filling and spilling | Endless, and a daily |

The 4–12 s film doesn't exist and is the one new case the plan needs; it also serves plan step 3's social clips.

## Other fields App Store Connect asks for

- **Privacy policy URL** (required). Options: **A (recommended)** GitHub Pages serving `docs/` of this public repo,
  free and versioned with the code; B the plain github.com link to `docs/privacy-policy.md`, which works but reads as a
  code page; C a domain of its own, which HANDOFF puts off until sharing. A or B shows the GitHub account name in the
  address, which the public repo shows already.
- **Support URL** (required). The same Pages site with a support page, or the repo's issues page. Either needs a
  contact address that is Jack's to choose; it goes into App Store Connect, never into this repo.
- **Marketing URL** (optional). None until a domain exists.
- **Copyright.** The year and holder of the source files' copyright headers.
- **In-app purchases.** Display names: "First Stir", "Lens", "Escapement", "Complete". Descriptions (Apple's limit is
  assumed to be 45 characters; check):

  | Product | Description | Chars |
  |---|---|---|
  | First Stir | A stormy night, told backwards | 30 |
  | Lens | Rods that zoom and spiral | 25 |
  | Escapement | Composed problems with a clock | 30 |
  | Complete | First Stir, Lens and Escapement | 31 |

  Each also needs a review screenshot and, if promoted, its own art (to-do 50 and 51).
- **Review notes.** App Review can't open the later tiers without playing every level at par, and the developer unlock
  is off in Release. Recommend a short note saying how tiers open, which levels show each mechanic in the free taste,
  and that the packs' first three levels play without a purchase. A Release build with the unlock on would be a
  different build from the one reviewed, so it is not an option.

## App Privacy label

The label must match the build that ships. All of what follows is derived from the code, cited by file.

### Without analytics (`master` as it is)

**Data Not Collected.** The app opens no network connection of its own (no `URLSession` on `master`). StoreKit's
purchases go between the phone and Apple, and Apple's handling isn't the app's to declare (Apple's guidance, as
understood; check). The daily's share line and the send-log button go through the system share sheet, which the
player directs.

### With analytics (the `analytics` branch, if merged)

Matches the branch's `Sources/PrivacyInfo.xcprivacy`:

| Data type | Collected | Linked to the player | Used to track | Purpose |
|---|---|---|---|---|
| Usage Data › Product Interaction | Yes | No | No | Analytics |
| Purchases › Purchase History | Yes | No | No | Analytics |
| Location › Coarse Location | Yes | No | No | Analytics |

Everything else: not collected. No tracking, so no App Tracking Transparency prompt.

Why each, from `Sources/Analytics.swift` on `analytics`:
- **Product Interaction**: `installed` and `returned` (a day number); `level` (the level's id, a daily as "daily",
  outcome solved or quit, moves, par, undos, resets); `run` (endless: outcome spilled or quit, tanks cleared, moves);
  `card` and `taste` (a pack's name, once per install); `snapshot` on days 2, 7 and 30 (the day numbers played, undos
  used, undos banked, endless's best, the furthest level reached in each tier, levels started, dailies solved on the
  first try, and for each pack whether its card was seen, its taste finished and it is owned). The sandbox sends
  nothing.
- **Purchase History**: `purchased` (a pack's name or "complete", once per install, for a verified purchase made on
  that phone), and each pack's owned flag in `snapshot`. No price, transaction or Apple ID.
- **Coarse Location**: the code sends no location. Aptabase reads the country from the address each request comes
  from, which is why the consent card says "roughly which country you're in". What Aptabase does with the address
  after that is its policy, not this code: unchecked **(check)**.
- **Not linked**: no player, install or device ID is sent. Each event carries a random session number, renewed after
  an hour with no event (and a fresh one for each snapshot), so events of one sitting can be grouped together, but not
  with the next sitting. Also sent with every batch: whether the build is Debug, "iOS", the app's version and build
  number, `unstir@1`, and a `User-Agent` of "Unstir". No locale, device model or OS version. Whether "not linked" holds
  in Apple's sense for a `snapshot` row, a per-player summary, is a judgement call **(check)**.

### The send-log button

`ShareLink(item: Log.url)` hands `Library/unstir-log.txt` to the share sheet; the app sends nothing itself. The log
holds the last 3,000 lines of play: each touch's landing and path in tank units, commits, undos and resets with the
stack, levels opened and left, tank turns, purchase and restore failures, and a launch line with the uptime and
whether the boot session and monotonic clock could be read (not their values).

| Option | Label |
|---|---|
| **A (recommended)** | Don't declare it: optional, infrequent, started by the player each time, through a system sheet that shows where it goes |
| B | Declare Diagnostics › Other Diagnostic Data, linked (an email carries the sender's address) |

A rests on Apple's "optional disclosure" criteria as Claude understands them, unchecked against the current App
Privacy page **(check)**. B is the safe reading if those criteria don't fit. Either way the privacy policy says what
the log holds.

## Open choices for Jack

1. Name: "Unstir" alone (recommended), or with a tagline.
2. Subtitle: "Unwind the stirred picture" (recommended).
3. Promotional text: A (recommended), what is free and that packs exist.
4. Keywords: A (recommended).
5. Category: Puzzle with Casual (recommended).
6. Screenshots: seven free shots then one per pack (recommended); captions need a compositing step that doesn't exist.
7. Preview: one 25-second free-game preview (recommended), with one new finger-driven film to make.
8. Family Sharing: still needs an explicit yes before the description mentions it (hard to undo).
9. Privacy policy hosting: GitHub Pages from `docs/` (recommended), and a contact address for privacy and support.
10. The send-log button on the label: undeclared under optional disclosure (recommended), or Diagnostics.
11. For a lawyer: GDPR article 8 and a 4+ game's consent question; whether `snapshot` rows are personal data; whether
    Aptabase offers a processing agreement and how long it keeps request addresses.
12. Carried from to-do 57, not a page choice: a Yes, then No, then Yes sends `installed` again and counts as a second
    install.
