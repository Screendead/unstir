# App Store page

Drafted 2026-10-27; Jack's calls ST1 to ST7 applied 2026-10-29, each A, so each section holds the chosen text and the
options set aside under it. Every character count below was measured with a script, not by eye. Anything legal is
marked **(check)**: nothing here settles it.

v1 ships with no analytics (AN1 = A) and is not sold in the EU or EEA at launch (EU1 = B), so this page holds only
the no-analytics texts and the privacy policy for that build. The contact address is Jack's and is written here only as
the token `{{CONTACT_ADDRESS}}`; the address itself is kept outside the repo, in `HANDOFF.private.md`, and goes into App
Store Connect and the hosted pages, never into a tracked file. The same goes for the developer's name in the policy:
`{{DEVELOPER_NAME}}`.

What it is true to: `master` with `v1-no-analytics` (four tiers of 27 levels, the daily, endless, the sandbox, StoreKit
for the packs and Complete) and the packs' levels as built: Lens's 25 and Escapement's 30. Prism, the third pack
(PK1 = A, replacing First Stir, which is out of v1), is being built; its lines below describe its design and are to be
checked against it once it ships. Not built, so left out of the copy: the daily archive, the supporter mark, iCloud
sync and charybdis.

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
- Maelstrom: 27 levels where knobs have seized. Turn the whole tank to bring the seams round to a knob that still works. Its pictures have a heartbeat.

Each tier opens when every level of the one before it is at par.

EVERY DAY

- The daily: one new tank a day, the same tank for everyone on the same date. Share your result as a line of coloured squares, one per move.
- Endless: tank after tank, with no undo, reset or par. Every stir you waste fills the brim on the rim. Healing the scramble's own stirs lets it settle. Eight notches and it spills.
- The sandbox: any picture, any rods. Nothing counts.

The daily and endless open once you have cleared plughole's 23rd level.

PACKS

Three packs add their own pictures, tanks and rules. The first three levels of each are free to play.

- Lens: some rods zoom or spiral instead of turning. Read how far a picture has grown against a halftone dot screen that never lies about scale.
- Escapement: a book of composed problems with a clock in them. One rod ticks a step by itself after every move you make. Time your heals so the clock always finds its seam.
- Prism: every picture is drawn three times, in red, green and blue light, and each rod stirs only some of the colours. Unstir until the ghosts snap back into one white line.

Complete unlocks Lens, Escapement and Prism in one purchase. Packs and Complete can be shared with your family through Family Sharing.

No ads. No timers. No account. Your progress stays on your phone, and the game sends nothing.
```

Choices and checks in it:
- **Complete.** It names the three packs and promises nothing about later ones (HANDOFF: the store page never promises
  later packs to Complete owners; to-do 55, App Review's rules on Complete, is still open) **(check)**.
- **Family Sharing.** On for all four products (Jack, ST6): `StoreKit/Unstir.storekit` already marks each
  family-shareable, and the store code handles family grants. Turn it on for each in App Store Connect too; once on it
  can't be turned off (check).
- **Prices.** Left out: they vary by storefront and the store shows them beside each purchase.
- **Pack sizes.** Left out until Prism is built (Lens 25 levels, Escapement 30 problems, Prism planned at 30 specimens).
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
| Unrestricted web access | No | The app has no web view: the privacy policy row opens Safari |
| User-generated content, messaging, chat | No | The share line is a text the player sends through the system share sheet; nothing is received |
| Advertising | No | |
| In-app purchases | Yes | Three packs and Complete |
| Parental controls, age assurance | No | No age question in v1 |
| In-app controls, capabilities, medical or wellness topics, violent themes (added 2025) | None or No | |

Expected result: 4+.

## Screenshots

Each is a `scripts/shots.sh <name>` case, rendered on a Pro Max simulator at 1320 × 2868, which is assumed to be the
6.9-inch size App Store Connect asks for (check). No render was looked at for this draft: Jack judges each from the
shots. HANDOFF's rule: lead with the free game, then the packs, each pack shot labelled as a paid add-on (guideline
2.3.2, assumed).

| Option | Set |
|---|---|
| **A (Jack, ST4)** | Seven free-game shots, then one shot per pack (ten, Apple's limit) |
| B, set aside | Nine free-game shots, then one "packs" shot of the shelf |
| C, set aside | Free game only; the packs shown only in their promoted-purchase art |

A shows each pack's look, which is what sells it, and the free game still leads.

The set, in order, with a caption each (captions are composited onto the shot, which no script does yet):

| # | Case | Caption | Chars |
|---|---|---|---|
| 1 | `whirlpool25-marbling` | Rods under the glass stirred this picture. | 42 |
| 2 | `count-quad-minus2` | Turn a knob back. The newest seam goes first. | 45 |
| 3 | `wave-0.8` | Get the order right and it snaps clean. | 39 |
| 4 | `vortex-family-ephemeris-13` | Vortex: one swirl as wide as the glass. | 39 |
| 5 | `seized-m23-half` | Maelstrom: knobs seize. Turn the whole tank. | 44 |
| 6 | `daily-result` | A new daily every day, the same for everyone. | 45 |
| 7 | `endless-brim` | Endless: waste a stir and the brim rises. | 41 |
| 8 | to make: a Prism specimen, ghosts half-merged | Paid pack · Prism: three colours, one line | 42 |
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
| **A (Jack, ST5)** | One preview, about 25 s, free game only: the packs live in screenshots 8 to 10 |
| B, set aside | Three previews: the free game, the tiers, the packs |
| C, set aside | One preview with the packs at its end, each labelled as a paid add-on |

A: the first seconds autoplay muted in search results, and one strong loop of a picture snapping back is the pitch
(plan step 3's clips test the same moment). B triples the cutting work for slots most visitors never open. C is the
fallback if the packs need video to sell.

The cut, in order:

| Seconds | Source | What it shows | Caption (muted playback) |
|---|---|---|---|
| 0–4 | `open-L12` | The clean picture, then every stir growing over it | A picture, stirred |
| 4–12 | **new**: a finger-driven unstir of one level to its solve wave (`UNSTIR_MOVES` with `UNSTIR_FINGER=1`, on a whirlpool level) | A hand turning the rods back in order, the seams healing, the wave | Turn the rods back in order |
| 12–16 | `rim-swirl` | Vortex's swirl held from the rim | Vortex: the swirl |
| 16–21 | `rim-seized` | Maelstrom's tank turned past a seized knob | Maelstrom: the tank turns |
| 21–25 | `endless-brim-run` (its spill) | The brim filling and spilling | Endless, and a daily |

The 4–12 s film doesn't exist and is the one new case the plan needs; it also serves plan step 3's social clips.

## Other fields App Store Connect asks for

- **Privacy policy URL** (required): GitHub Pages serving `docs/` of this public repo (Jack, ST7), free and versioned
  with the code. Until Pages is set up, the app's settings row links the plain github.com page of
  `docs/privacy-policy.md`; switch that constant to the Pages address once it serves. Set aside: a domain of its own,
  which HANDOFF puts off until sharing.
- **Support URL** (required): a support page on the same Pages site, giving `{{CONTACT_ADDRESS}}`.
- **Contact address** for privacy and support: `{{CONTACT_ADDRESS}}` everywhere in the repo. Jack has picked it; it is
  recorded in `HANDOFF.private.md` only, and filled in App Store Connect and in the published pages at publishing.
- **Marketing URL** (optional). None until a domain exists.
- **Copyright.** The year and holder of the source files' copyright headers.
- **In-app purchases.** Display names: "Lens", "Escapement", "Prism", "Complete". Descriptions (Apple's limit is
  assumed to be 45 characters; check):

  | Product | Description | Chars |
  |---|---|---|
  | Lens | Rods that zoom and spiral | 25 |
  | Escapement | Composed problems with a clock | 30 |
  | Prism | Three colours, one white line | 29 |
  | Complete | Lens, Escapement and Prism | 26 |

  Each also needs a review screenshot and, if promoted, its own art (to-do 50 and 51).
- **Review notes.** App Review can't open the later tiers without playing every level at par, and the developer unlock
  is off in Release. Recommend a short note saying how tiers open, which levels show each mechanic in the free taste,
  and that the packs' first three levels play without a purchase. A Release build with the unlock on would be a
  different build from the one reviewed, so it is not an option.

## App Privacy label

The label must match the build that ships: v1 without analytics (branch `v1-no-analytics`). Derived from the code.

**Data Not Collected.** With analytics off the app opens no network connection of its own. StoreKit's
purchases go between the phone and Apple, and Apple's handling isn't the app's to declare (Apple's guidance, as
understood; check). The daily's share line and the send-log button go through the system share sheet, which the
player directs.

### The send-log button

`ShareLink(item: Log.url)` hands `Library/unstir-log.txt` to the share sheet; the app sends nothing itself. The log
holds the last 3,000 lines of play: each touch's landing and path in tank units, commits, undos and resets with the
stack, levels opened and left, tank turns, purchase and restore failures, and a launch line with the uptime and
whether the boot session and monotonic clock could be read (not their values).

| Option | Label |
|---|---|
| **A (Jack, ST7)** | Don't declare it: optional, infrequent, started by the player each time, through a system sheet that shows where it goes |
| B, set aside | Declare Diagnostics › Other Diagnostic Data, linked (an email carries the sender's address) |

A rests on Apple's "optional disclosure" criteria, unchecked against the current App Privacy page **(check)**; B is
the fallback if App Review reads them otherwise. Either way the privacy policy says what the log holds.

## Still open

1. Before submitting: the checks marked **(check)** above, against App Store Connect's live pages.
2. Screenshots 8 to 10 and the 4–12 s film are still to make, and captions need a compositing step that doesn't exist.
3. The Prism lines describe its design; check them against the pack as it ships.
4. In App Store Connect's availability, exclude the EU/EEA storefronts (EU1 = B); the EU is out at launch.
