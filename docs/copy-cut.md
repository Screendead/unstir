# Copy cut

Every piece of text the game shows or speaks, judged against one rule (Jack, 2026-11-23): a word stays only if a player
cannot play, buy, restore, understand a lock or use the app accessibly without it, or the App Store or the law asks for
it. This file lists what goes; `docs/copy-keep.txt` lists what stays, for rewriting. Nothing in `Sources/` is changed
yet: apply these once the slope's pieces are merged.

Read from `slope/base` and `origin/slope/integrate` (which holds the menu, play, result, settings and consent builders'
work); `tools/copy/inventory.py` lists the strings and `tools/copy/build.py` holds each verdict and writes both files.
`origin/slope/d-packs` and `origin/slope/e-archive` did not exist on 2026-11-23, so the pack pages' and the archive's
words are today's (`Shelf.swift`, `Offer.swift`, `Archive.swift`) plus what `docs/slope.md` 7 and 8 specify. Placeholders
are written as the String Catalog writes them (`%lld` a number, `%@` words).

## Counts

| | Strings |
|---|---|
| Inventoried | 685 |
| Kept | 608, of them 10 trimmed, and 237 names |
| Cut | 29 |
| Calls for Jack | 32 (7 lines and the 25 strategy notes, as one call) |
| Gone with the slope already | 16 |

Not judged: First Stir's 106 strings (the pack is out of v1 and no release build sells it), the editors' build's two, and
debug and harness text. A string used in several places counts once; a plural counts once.

## Cut

| Words | Where | Why |
|---|---|---|
| PAST DAILIES | archive: eyebrow over its title (Archive.swift) | repeats the title "Archive" under it |
| Every daily as it was dealt. A best here is its own: only a daily solved on its day adds to the days running. | archive: paragraph under its title (Archive.swift) | explains the archive; the row and the practice caption already say what counts |
| done %lld/%lld at par | archive: count under its title (Archive.swift) | the menu's archive row already gives this count; the slope's archive (docs/slope.md 7) leaves it out |
| the beds under the menu and the levels | Settings: what the music switch plays (Consent.swift) | says what "music" is |
| every effect and button | Settings: what the sounds switch plays (Consent.swift) | says what "sounds" is |
| the tank's knocks and taps | Settings: what the haptics switch plays (Consent.swift) | says what "haptics" is |
| packs bought on this Apple ID | Settings: what restore brings back (Consent.swift) | says what "restore purchases" does |
| what the game keeps, and why | Settings: what the policy says (Consent.swift) | says what a privacy policy is |
| R, G and B on Prism's knobs | Settings: what the colour letters switch shows (Consent.swift) | the switch shows it when turned; Prism's page keeps its own pointer to the switch |
| ✦ by the title and in the daily's share line | Settings: where the supporter mark shows (Consent.swift) | the switch shows it when turned |
| Stir anything. Undo is free here. | The sandbox's line under the tank (Levels.swift) | flavour; the sandbox's undo button already shows no count |
| any picture, any rods · nothing counts | The sandbox's row, under its title (Menu.swift) | flavour under "Sandbox" |
| deeper every tank · eight wrong stirs and it spills | VoiceOver: endless's row. Eight is the brim's room, in words (Menu.swift, SlopeMenu.swift) | a pitch for endless on its own row; Jack already ruled "deeper every tank" is left unsaid (2026-11-11), and the brim's rule is given on the first tank. On the slope it survives only as VoiceOver's hint |
| Opens %@ %@ | VoiceOver: a level not yet solved. Its tier, its number (Menu.swift, SlopeGate.swift) | VoiceOver hint repeating the button's label |
| three packs, for less | The bundle's pitch, on its card (Offer.swift) | slogan; the bundle's facts name its packs and its saving |
| after plughole | Who Lens is for. The first tier, in lower case (Offer.swift) | audience advice; the three free levels show the buyer how hard the pack is |
| hard · composed problems | Who Escapement is for (Offer.swift) | audience advice, as Lens's |
| after plughole · reading by colour | Who Prism is for. The first tier, in lower case (Offer.swift) | audience advice, as Lens's |
| after plughole, then harder | Who the bundle is for. The first tier, in lower case (Offer.swift) | audience advice, as Lens's |
| %@ in four issues | What Lens holds. Its levels counted (Offer.swift) | the count ("25 panels") stays; "in four issues" is flavour and the level list shows its chapters |
| %@ in five chapters | What Escapement holds. Its levels counted (Offer.swift) | the count ("30 problems") stays; "in five chapters" is flavour |
| %@ in five trays | What Prism holds. Its levels counted (Offer.swift) | the count ("30 specimens") stays; "in five trays" is flavour |
| Unstir in %lld ticks. Three clocks. | Escapement's note under the tank opening its fifth chapter: the tick budget, then the chapter's rule (Pack.swift) | "Three clocks." is on the glass; the level shows "Unstir in %lld ticks." alone |
| Red passes cyan, and blocks yellow and magenta. | Prism's fourth tray's rule, under the tank (Pack.swift) | a worked case of the third tray's rule |
| clean needs no undo or reset | result: under the facts when at par but not clean (ResultCard.swift, SlopeResult.swift) | teaches what clean is; learnt from the marks |
| clean counts on the first try | result, a daily replayed: under the facts (ResultCard.swift, SlopeResult.swift) | teaches what clean is; the practice caption under the tank already says the first try counts |
| Ask to Buy: the pack opens here once it's approved · tap asked to send it again. | A pack's card: its Ask to Buy sent. Asked is the buy pill's word (Shelf.swift) | second line under "waiting for approval"; the button already reads "asked". It is already dropped when a failed ask shows its own line (approved 2026-11-02) |
| Ask to Buy: %@ opens here once %@ is approved. | A pack's card: the bundle's Ask to Buy sent. The pack, then the bundle (Shelf.swift) | second line under "Triptych I is waiting for approval" |
| watch the stir · tap to skip | The caption over a replay's opening stir (TankView.swift) | "watch the stir" tells the player to look at the screen; shows "tap to skip" alone |

## Trimmed

| Today | Becomes | Where | Why |
|---|---|---|---|
| Turn a rod to look. Let go where you started and nothing happens. | Turn a rod to look. | plughole 01, under the tank (Levels.swift) | the second sentence is learnt on the first let-go; the ghost finger shows the turn |
| Turn the glass's edge. Everything inside it stirs. | Turn the glass's edge. | vortex 01, under the tank (Levels.swift) | the second sentence is what the player then sees |
| One knob has seized. Turn the tank. Turns count as moves. | One knob has seized. Turn the tank. | maelstrom 01, under the tank (Levels.swift) | the move count shows that turns count |
| levels 1–%lld free, no purchase | levels 1–%lld free | A pack's card: its free levels (Offer.swift) | "no purchase" repeats "free" |
| %@: %@. A level from each pack, played. | %@ | VoiceOver: the bundle's clip. Its name, then its pitch (PackCovers.swift) | VoiceOver needs the bundle's name; the slogan is cut and "A level from each pack, played." describes a picture |
| %@: %@. A level played. | %@: %@. | VoiceOver: a pack's clip. Its name, then its pitch (PackCovers.swift) | "A level played." describes a picture |
| ✓ owned · all %@ packs open | ✓ owned | The bundle's card, owned. Its packs, counted in words (Shelf.swift) | "all three packs open" repeats "owned" |
| ✓ owned · every level open | ✓ owned | A pack's card, owned (Shelf.swift) | "every level open" repeats "owned" |
| %@ is no longer shared with you · your progress is kept | %@ is no longer shared with you | A pack's card: a family's share ended. The pack (Shelf.swift) | reassurance |
| %@ isn't on this Apple ID any more · your progress is kept | %@ isn't on this Apple ID any more | A pack's card: refunded. The pack (Shelf.swift) | reassurance |

What follows from the cuts: a pack page's facts lose "after plughole" and the like entirely, and what a pack holds reads
"25 panels"; Escapement's fifth chapter opens with "Unstir in %lld ticks." alone; a replay's opening shows "tap to skip";
the five settings switches and three links stand without a second line, so VoiceOver gets no hint from them, and the
analytics switch keeps its line, which says what is sent.

## Calls for Jack

Each would be cut or trimmed by the rule, but its words rest on a decision of his, so it stays, and is in
`docs/copy-keep.txt`, until he agrees.

| Words | Where | His decision | Proposed |
|---|---|---|---|
| anything goes | menu: heading over the sandbox row (Menu.swift, SlopeMenu.swift) | The heading over the sandbox row. Jack put the sandbox at the end of the list "under 'anything goes'" on 2026-11-01. | cut: a heading over one row named "Sandbox" |
| Unstir in %lld ticks. Sometimes the first move is to wait. | Escapement's note under the tank opening its second chapter: the tick budget, then the chapter's rule (Pack.swift) | Escapement chapter 2's line under the tank. Jack settled this wording on 2026-11-12, when the wait button came back. | trim to "Unstir in %lld ticks.": the second sentence is a hint |
| made by screendead · thank you for playing | The credit after the last free level. screendead is the maker's name, never translated (Payoff.swift) | The game's one credit, after the last free level. Jack set its words on 2026-11-11. | trim to "made by screendead": the thanks is the kind of line this pass removes |
| Made by screendead. Thank you for playing. | VoiceOver: the credit after the last free level. screendead is the maker's name, never translated (Payoff.swift) | VoiceOver's sentence for the credit. | trim to "Made by screendead." |
| wait: the clock ticks, nothing turns | Escapement's demonstration, as the wait control is pressed: a wait ticks the clock and turns no rod (TankView.swift) | The caption shown as Escapement's wait button is demonstrated. Jack's call of 2026-11-12 brought the wait button back on condition that the game makes clear a clock can tick with no knob turned. | cut: problem 2's note ("Tap wait: the clock ticks, nothing turns.") and the demonstration itself make it clear; VoiceOver keeps its hint |
| sound, haptics, colour letters: in settings, at the surface | Plughole 01's pointer to the settings, on the slope (SlopePlay.swift) | Plughole 01 shows one quiet line under its note, once ever, pointing at settings. Jack asked for it on 2026-11-02 and ruled the same day that it stays as built; the slope rewords it because the gear is gone, and the slope's own open call 7 offers dropping it. | cut, with its VoiceOver sentence: "settings" is now written on the opening screen |
| Sound, haptics and colour letters are in settings, at the surface of the menu. | VoiceOver: plughole 01's pointer to the settings, on the slope (SlopePlay.swift) | VoiceOver's sentence for the same line. | cut with it |
| The 25 notes listed below | under the tank, one per level (Levels.swift) | The strategy lines under the free tiers' tanks. When Jack renamed every level on 2026-11-01 (plain nouns, one world per tier), the hints the old titles carried were moved into these notes, and on 2026-11-02 he passed the notes as built (no note for plughole 02). | cut all 25: each is a tip a player finds by playing. The three notes that introduce a control (plughole 01, vortex 01, maelstrom 01) stay, trimmed as above, with the frost day's line and endless's first-tank rule |

The strategy notes in that call:

| Level | Note |
|---|---|
| plughole 03 | The last rod you saw turn is on top. |
| plughole 04 | Where two rings cross, the later one runs unbroken. |
| plughole 05 | Where two discs overlap, the order they come off matters. |
| plughole 06 | One rod was stirred twice. Its newer stir comes off first. |
| plughole 08 | Turn a rod to look. A fresh hard ring means not that one. |
| plughole 09 | Rings that never meet come off in any order. |
| plughole 11 | Any whole ring can come off. |
| plughole 12 | A small stir is not an old one. |
| plughole 14 | The small rods count as much as the big ones. |
| plughole 15 | The small stir is on top. |
| plughole 16 | Turned, stirred past, turned back: all it leaves is a tail. |
| plughole 20 | Read where the rings cross, not their colours. |
| plughole 21 | One ring is whole. Find it. |
| plughole 24 | The hub's disc crosses every other. |
| whirlpool 01 | Same rules, twice the stirs, no replays. |
| whirlpool 04 | The newest ring is never broken. |
| whirlpool 11 | There is always a whole ring. |
| vortex 02 | A rod was stirred after the rim. |
| vortex 03 | The rim was stirred first. |
| vortex 12 | Read the edge before the middle. |
| maelstrom 02 | The tank turns the other way too. |
| maelstrom 03 | Turn the tank so the seized knob is out of the way. |
| maelstrom 08 | Plan two turns of the tank ahead. |
| maelstrom 10 | The nearer turn is not the shorter way. |
| maelstrom 18 | The right stop is past the obvious one. |

## Gone with the slope already

Today's words that `docs/slope.md` (11 and 12) replaces or drops. No decision here; only the slope's wording is in
`docs/copy-keep.txt`.

| Today | On the slope |
|---|---|
| past | dropped (slope call 9: the daily, archive and endless are marked by where they are) |
| day | dropped, as "past" |
| Tier | dropped: the tier chips become the tiers' names on the water |
| BUNDLE | "bundle" |
| BUNDLE · PAID ADD-ON | "bundle · paid add-on" |
| PACK | "pack" |
| PACK · PAID ADD-ON | "pack · paid add-on" |
| for | dropped: the facts stand without their keys |
| free | dropped, as "for" |
| holds | dropped, as "for" |
| %@ on the packs you don't have | "save %@" (the key "save" and the price) |
| PACKS · PAID ADD-ONS | "packs · paid add-ons · first 3 levels of each free", under plughole's name |
| PACKS | "packs", under plughole's name |
| first 3 levels of each free | joined into the line above |
| sound, haptics, colour letters: [gear] on the menu | "sound, haptics, colour letters: in settings, at the surface" (see the calls) |
| Sound, haptics and colour letters are in settings, the gear on the menu. | "Sound, haptics and colour letters are in settings, at the surface of the menu." (see the calls) |
| "‹ levels", "‹ menu", "‹ archive", "‹ Triptych I" | "↑ levels", "↑ menu", "↑ archive", "↑ Triptych I" |
| "UP A NOTCH", "WHIRLPOOL ›" | "up a notch", "whirlpool ›" |

## Kept, with wording Jack decided

These stay, and are in `docs/copy-keep.txt`, but their words were themselves his call: a rewrite of one changes that call.

| Words | The call |
|---|---|
| unlocked by purchasing any pack | the locked archive's words when tapped, Jack's own (2026-11-02) |
| %lld past dailies · comes with any pack | the locked archive row's line stays (2026-11-02) |
| Help improve Unstir? | consent card's question (2026-10-26) |
| Let the game tell us how you play. Never who you are. | consent card's one line (2026-10-26) |
| What does it send? › | consent card's link (2026-10-26) |
| Hide the list ‹ | consent card's link, open (2026-10-28) |
| That tick can't come back. Reset. | the pushed tick's words with no undo left (2026-11-01) |
| That tick can't come back. Undo, or again. | the pushed tick's words, and "again" against "reset" (2026-11-01) |
| playing | "playing" under the row being played (2026-11-03) |
| frost day | "frost day" on the daily's row (2026-11-12) |
| %@ is yours | "Lens is yours" after an Ask to Buy approval (2026-11-01) |
| letters for colour-blind play, in settings | one line on Prism's page for the colour letters (2026-11-01) |
| close | "✕ close" beside the menu (2026-11-03) |
| The first %@ are free. %@ | the skip-ahead line over buying (2026-11-02) |
| Unstir in %lld ticks. A clock ticks after every move. Each let-go is a move. | Escapement: a turn-back is not free, so the rule is stated (2026-10-24) |
| Unstir in %lld ticks. Tap wait: the clock ticks, nothing turns. | the wait button's explanation (2026-11-12) |
| unstirred. | "unstirred." heads the result (2026-11-04) |
| more puzzles in the packs › | "more puzzles in the packs ›" stays as built (2026-11-02) |
| more in %@ › | "more in Lens ›" on a pack's last free level (2026-11-01) |
| checking purchases… | "checking purchases…" (2026-11-10) |
| next | VoiceOver's "next" stays (2026-11-11) |
| reset? tap again | "reset? tap again" for 2 s (2026-11-01) |
| Solve a daily clean: at par on the first try, with no undo or reset. | No Wake's Game Center text (2026-11-13) |
| every achievement's title | a stored value: a live achievement's title never changes |

## Seen on the way

- The sandbox's picture and rods controls show code names where no English was written: "glassTwin", "chainmailTwin",
  "coralTwin", "neuronsTwin", "marblingTwin", "engineTurned", "triSwirl", "quadSwirl", "eyeSwirl", "pentSwirl", "hexSwirl".
  They are kept as labels and listed for rewriting.
- v1 ships with analytics off, so the consent card and the analytics switch are not in v1's build; they are kept for the
  build that has them.
- "deeper every tank · eight wrong stirs and it spills" is still the endless row's line on today's menu, after the
  call that left "deeper every tank" unsaid.
