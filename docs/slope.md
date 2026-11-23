# The slope

The design spec for Unstir's redesign: everything outside the tank drawn as one world (Jack's calls of 2026-11-23:
a world, not an app; the Descent, as the Shelf). In code the world is the **slope** (`Slope…`), as `Shelf.swift` and
"the shelf" already mean the pack dock and shop. Builders build from this document word for word. Where it and the
mock-up disagree, this document wins; where it is silent, today's behaviour (`docs/architecture.md`) stands.

Sources: the approved mock-up (`design/negative-space/world/shelf/shelf.js`, rendered to
`build/negative-space/world/shelf/`), the approved list of changes on the third pitch page
(`design/negative-space/pitch3.html`), today's app (`docs/architecture.md`, `shots/index.txt`) and Jack's calls
(`docs/decisions.md`). Nothing here changes the tank: the glass, picture, knobs, rings, counts, lessons drawn on the
glass, the brim, the stamps and the solve wave are as they are.

Contents: 1 the rules every screen shares · 2 the menu · 3 travel between tiers · 4 play · 5 the result ·
6 the curtain call · 7 the archive · 8 packs · 9 settings and consent · 10 wide windows · 11 words that change ·
12 calls for Jack · 13 the build split.

All measurements are points on the reference phone's screen, 440 x 956 (the iPhone 13 Pro Max's class), unless a
rule says how they scale. `H` and `W` are the window's height and width.

## 1. The rules every screen shares

### 1.1 What may be drawn

- No boxes, cards, sheets, lists, capsule buttons, divider lines, hairlines, scrims or hard straight lines. A
  ledge's top always bows (at least 3 pt over 100 pt of run); a block of text is set on open water, never in a frame.
- Nothing stirs, swirls or rotates about a centre. Things sink, rise, drift, settle, breathe and rock (1.5). The one
  rotation left outside the glass is a refused stone's rock.
- Text never shrinks (Jack, 2026-11-11). Where words don't fit, the layout gives way in this order: a line wraps; a
  row stacks; a ledge's pitch grows; the view scrolls (the menu, a hollow, settings, consent, the archive); on the
  play screen, which never scrolls (Jack, 2026-11-13), the finished tank shrinks (`PlayLayout.finished`, unchanged).
- Colour that carries meaning today keeps it: lime "clean", amber "at par" and an armed reset, magenta over par, a
  tier's and a pack's ink on its way on, vermilion on Escapement. "Coloured level numbers become plain" (approved)
  covers the numbers only.

### 1.2 One column, one ledge function, one camera

The world is a **column**: a surface, then **stretches** one under another, then a foot. A stretch is a run of
**terraces**; a terrace is up to nine **ledges**; a ledge seats one pebble. There is one main column and one small
column per pack, for settings and for the archive; all are drawn by the same ground shader from the same data.

| Column | Stretches (terraces x seats) | Foot |
|---|---|---|
| Main | the shallows (3 x 1: today, a bare ledge, the archive), plughole, whirlpool, vortex, maelstrom (3 x 9 each) | the drop-off (endless) |
| Lens | its four issues (6, 6, 6, 7) | the hollow's floor |
| Escapement | its five chapters (6 each) | the floor |
| Prism | its five trays (6 each) | the floor |
| Settings | one stretch, a ledge per row (9.1) | none |
| Archive | a stretch per month, a terrace per week, a seat per day (7) | none |

The mock-up drew two different slopes: nine pebbles to a long ledge on the whole-column screen, one pebble to a
ledge in the dive. They are now **one geometry seen at two zooms**. Every level has its own ledge at both zooms. A
terrace is nine ledges whose lips step outward, each a little lower than the last, and under the ninth the rock cuts
back to the wall where the next terrace starts. Zoom does not magnify: it **opens depth**. From far off the nine
ledges of a terrace lie 1.3 pt apart, so the terrace reads as one long ledge with nine pebbles along its top, as the
approved overview drew it; close up they stand 110 pt apart, each its own overhung ledge with its name beside it, as
the approved dive drew it. Between the two, every pebble travels continuously from one place to the other and
nothing is swapped or crossfaded.

The ledge function, the only source of positions for the shader, the pebbles, the type and the hit targets
(`SlopeGeometry`), takes a zoom `z` from 0 (the **overview**) to 1 (the **dive**):

- `e = z*z*(3 - 2*z)`.
- Ledge pitch inside a terrace: `p(z) = 1.3 * (pitch / 1.3)^e`, where `pitch` is the dive's pitch (1.6): 110 at the
  default type size.
- Gap under a terrace: `g(z) = 28.3 * (1 - e)`. A terrace of nine is `9 * p + g` tall: 40 at the overview, 990 in
  the dive. A terrace with fewer seats keeps a full terrace's height at the overview, its gap taking up the missing
  seats' pitch, so the shallows' three ledges stand 40 pt apart there, the first 82 pt under the surface.
- Seat `i` (0 to 8) of terrace `T` (counted down the column) has its pebble at
  `x = mix(wall(T) + 2 + 11.4 * i, 109 + 9.5 * i + wobble, e)`, with `wall(T) = 40 + 8 * sin(0.9 * T + 1)` and
  `wobble = 4 * sin(2.4 * n + 1)` for the column's `n`th ledge, and its lip `mix(6, 23, e)` further out.
- A pebble's half-width is `mix(3.9, 8.4, e)` (lit), `mix(3.3, 6.8, e)` (dull), `mix(4.6, 12.5, e)` (next), its
  half-height 0.72 of that (1.4).
- Over a stretch stands its header (2.2). The room for it is `mix(0, max(pitch, header's height + 40), e)`; at the
  overview the header's words stand beside the stretch instead (2.1).
- Rock by tier, the lip's thickness, its overhang, the bluntness of its nose and the ripples down its face are the
  mock-up's `shapeD` and `rockC`/`litC` per tier (sandstone, mauve scallops, slate plates, basalt pillows); at the
  overview the nine lips merge into the terrace's top and the underside takes `shapeO`'s curve. The shallows and the
  settings column are sandstone. The water's colour by depth is the mock-up's `water(m)`, with `m` the ledge count
  from the first plughole ledge.

The **camera** is a world depth and `z`. Screen `y` of a point is its column depth at that `z` less the camera's.
Depth layers move at their own rates of the camera's travel: the far ridge 0.30, the farther ridge 0.58 (both end at
the drop-off), the slope 1, the near silhouette 1.55 (dive only, not at accessibility sizes, not in play), and three
layers of sinking motes at 0.35, 0.65 and 0.95. Only two zooms rest: 0 and 1.

### 1.3 Type

The mock-up's three voices, each a Dynamic Type role (sizes at the default setting; `Type.swift`'s roles gain the
family, keeping their text styles):

| Voice | Face | Used for |
|---|---|---|
| place | New York italic, light | the names of places and what the game says: tier names, "today", "endless", "settings", a level's note and every caption, "unstirred.", "up a notch", a pack's line |
| name | SF Pro, light | a level's name, a pack's name, the wordmark (SF Pro 250, letter-spaced 9 pt, plain ink), the tier a result goes up to |
| ui | SF Pro, regular (medium where a control is the way on, semibold for "buy") | controls, row titles, details, explanations |
| data | SF Mono, regular | numbers and counts: a level's number, "4 rods · par 4", "moves 9 · par 9", "13/27 at par", "best 9", "on"/"off", the version |

Sizes: display 34, title 28, body 17, label 15, detail 13. Nothing that means something is under 13. The menu, a
hollow, the archive, settings and consent follow every Dynamic Type size; the play screen stops at xxxLarge
(`PlayLayout.typeCap`, unchanged: the mock-up's `play-ax` still was drawn past the cap and is not the design).

### 1.4 Tone on water and the stone

Text is one ink (#EDEFF7) at four strengths, set by the foundation as `ink`, `ink2`, `ink3` and `ink4`: `ink` for
names and the way on; `ink2` for details that carry meaning (a count, a fact, a note at rest); `ink3` for keys,
progress and explanations; `ink4` only for what is closed or off, beside a dull pebble. Each is defined by contrast,
not by an opacity: `ink` to `ink3` read at least 4.5:1, and `ink4` at least 3:1, against the lightest ground they can
lie over (the shallows in sun). Text over lit sand gets the water's shade behind it: no word is set on a lit ledge
top. On Escapement's paper (8.6) every word is the paper's ink (`Page`, unchanged).

The **stone** is the one control (it replaces `UnstirButton`'s three emphases). It is a smooth pebble with its
label beside it; the label's side is the open-water side.

| State | Looks | Used for |
|---|---|---|
| lit | pale warm stone, a soft glow, a highlight | a solved level; a switch that is on; a control that can act |
| next | larger, brighter, its glow breathing 0.86 to 1 over 3 s | the one way on: the frontier, "next ›", "buy", "play 04 ›", an open "up a notch" |
| dull | grey-blue, no glow or highlight, drawn at 0.9 | a closed level or tier, a switch that is off, undo with nothing to undo |
| armed | lit, its glow amber (`Page.stop`), its label amber | reset after its first tap; "new run? tap again" |
| pending | lit, its glow breathing over 1.2 s, its label at `ink2` | "buying…", "restoring…", "checking purchases…" |
| pressed | sinks 2 pt and scales to 0.97 over 0.2 s | any stone while touched |
| refused | rocks 6° either way twice in 0.3 s, sounds `seized` | a closed level, the locked archive |
| pale | cool white stone and glow | Prism's own controls |
| engraved | an ink outline hatched on its shaded side, no glow | every stone on Escapement's paper |

One stone per screen is `next`, by today's order (an open "up a notch", then next, then share; "again" never
leads). Where a `next` stone belongs to a tier or a pack, its glow is that tier's or pack's colour (`Tier.glow`,
`Offer.glow`) and its label that ink (`Tier.ink`, `Offer.ink`). A stone's target is its pebble and its words
together, never under 44 pt either way; on the slope it is the whole ledge's row, from the screen's leading edge to
the end of its words. A quiet control is words alone with a 44 pt target (the ways back, small print, links). Every
stone and quiet control sounds as today's buttons do.

### 1.5 Motion, and Reduce Motion

| Move | What it is | Under Reduce Motion |
|---|---|---|
| sink, rise | the camera travels down or up, ease-out; a change of zoom takes 1.1 s, a move inside one zoom 0.9 s | a cut under a 0.24 s fade |
| open | a pebble grows into its tank, or a cover rises out of its hollow, with `settle` over 1.3 s | the same cut and fade |
| settle | an arrival that overshoots a touch and comes to rest: `1 - exp(-6x) * cos(5x)` | arrives in place |
| drift | motes sink and the surface line sways, on the ground's clock | none: the clock holds at 0 |
| breathe | a glow's strength swells and falls | steady at full |
| rock | a refused stone | none; the message alone |
| light settling | nine bright motes sink past a solved tank and come to rest over 3.4 s; the terrace under it glints | none |

A line of words arrives by fading in over 0.6 s while rising 12 to 26 pt to its place with `settle`; under Reduce
Motion it fades in where it stands. Nothing moves faster than a finger could follow, and nothing loops except drift
and breathe.

### 1.6 Sizes of screen and type

- The dive's `pitch` is the taller of 110 and a ledge row's own height at the type size plus 60 (196 at
  accessibility3, as the mock-up's `menu-ax`).
- From accessibility1 up the slope keeps to the leading edge: the first lip stands at 62, the seats step 1.5 pt, the
  near silhouette is not drawn, and a row's words start at 96 and wrap inside the screen. A row then stacks: number
  and name on the first line, the marks on their own line under the name, the facts under them.
- On a narrower phone the dive's lips move in by half the width lost (first lip at 100 on a 375 pt screen).
- The overview's heights are shares of `H` (2.1). Where a stretch's words are taller than its share, that stretch
  takes the height of its words plus 24, its terraces spread to fill it, and the overview scrolls; this happens only
  at the larger type sizes and on the shortest phone.

### 1.7 The battery

The ground is one full-screen pass. It redraws only when something it shows has changed: the camera moved, or its
clock ticked. The clock (drift) runs at 30 Hz and stops: while a level is on screen (the ground under play is a
still), under Reduce Motion, while `Power` saves (Low Power Mode, or a thermal state of serious or worse), once no
finger has landed for 20 s (`Power.idle`), and while anything covers the slope. Scrolling draws at the display's
rate. Pebbles, type and glass are drawn over it, not in it.

### 1.8 VoiceOver

Every screen reads top to bottom: the way back, the screen's name, then each ledge in the column's order, then the
foot. A ledge is one element: its label is what is written beside it, its value its result or state, its hint what a
tap does when that isn't to open it. Pebbles, marks, glows and the ground are hidden from it. A place the sighted
player reaches by scrolling is reached by VoiceOver's own scroll (three-finger swipe moves the camera a screen).
Announcements made today are made at the same moments. The words in `Spoken.swift` stand.

## 2. The menu

The menu is the main column. It rests at two zooms: the **overview**, the whole column on one screen, and the
**dive**, the slope at full size, which scrolls from the surface to the drop-off.

### 2.1 The overview

Top to bottom, as the mock-up's `menu-today`:

- **The air** (0 to 0.188 `H`): dusk, warm along the water. "UNSTIR" (name voice, display) at leading 32, baseline
  128. After it, once a pack is owned and until the settings' switch is off, the **supporter mark**: the four-pointed
  glint, 14 pt, still, in plughole's lit colour, which VoiceOver reads with the title as "Unstir, supporter".
- **The bank**: the shelf's dry top breaks the surface at the leading edge. On it lies the **settings stone** (lit),
  "settings" (ui, detail) beside it. Tapping either opens settings (9.1).
- **The surface** at 0.188 `H`: a bright line that sways.
- **The shallows** (0.188 to 0.40 `H`): "today" (place, title) beside the first ledge, the daily under it; the
  archive two ledges down (2.4, 2.5). Neither is drawn until the daily opens.
- **Four tiers**, 0.125 `H` each from 0.40 `H`: three terraces of nine pebbles, in the tier's rock. Beside each, from
  x = 180: the tier's name (place, title); under it its progress, "13/27 at par" (data, detail, `ink3`), or while it
  is closed its reason, "opens with every whirlpool level solved" (ui, detail, `ink3`), the name then at `ink4`.
  Solved pebbles are lit, the frontier's is `next`, the rest dull.
- **The way on**: the tier the player is in (`Tier.stored()`) carries one more line under its progress, the frontier's
  number and name and a chevron, "14 Lather ›" (number in data, name in name voice, body, `ink`). Tapping it opens that
  level from here (2.9). No other tier shows one.
- **The packs' line**: once the hollows show (8.1), plughole's block ends with the caption (2.2's words; ui, detail,
  `ink3`), and the hollows themselves are drawn in the rock beside plughole's terraces if Jack takes call 1's
  alternative. Tapping the caption dives to the first hollow marked new, else the first unowned, else the first.
- **The drop-off** (from 0.90 `H`): the rock ends (2.6). "endless" (place, title) centred in open water, its line
  under it. Not written until endless opens.

Tappable: the settings stone; the daily; the archive; each tier's whole band, the full width of its stretch (dives
to its landing, 2.7; a closed tier's to its gate); the way on; the packs' line; endless. Nothing else.

At the accessibility sizes the words keep their size, start at x = 96, wrap, and each stretch grows to hold its
words (1.6); the overview then scrolls, opening at its top.

VoiceOver, in order: "Unstir" (or "Unstir, supporter"), heading; "settings", button; the daily; the archive; each
tier as one button, "plughole, 13 of 27 at par" or "vortex, locked, opens with every whirlpool level solved, 20 of
27" (today's words); the way on, "next, 14, Lather"; the packs' line; endless.

### 2.2 The dive

The slope at `z = 1`, as the mock-up's `menu`. It scrolls with the system's own momentum and bounce (what lies past
either end belongs to the easter eggs' owner; this document reserves it). At the top leading corner, where the play
screen's way back stands, a quiet control reads **"↑ surface"** whenever the surface is out of sight; it, a pinch
in, and the edge swipe (2.11) rise to the overview.

**A stretch's header** stands over its first ledge, at the words' x: the tier's name (place, title, `ink`), under it
its progress (data, detail, `ink3`), and under plughole's, once the hollows show, the packs' caption (ui, detail,
`ink3`): "packs · paid add-ons · first 3 levels of each free" with no pack owned, "packs · first 3 levels of each
free" once one is, "packs" once every one is (today's three states, the dock's own words). A closed tier's header is
its gate (2.3).

**A ledge's row**: its pebble on the ledge; from 18 pt past the lip its number (data, label, `ink3`), its name (ui,
body, `ink`), its result marks after the name on its baseline (`ResultMarks` as today: three discs, none filled
tried, one solved over par, two at par, three clean; hidden where the level has never been started); under them
"4 rods · par 4" (data, detail, `ink3`; "5 rods + swirl · par 12" on a swirl layout). The facts stay on every ledge
(approved).

| State | Pebble | Words |
|---|---|---|
| solved | lit | name `ink`, marks filled by its best |
| tried, no best | dull, undimmed | name `ink`, three hollow marks |
| the frontier (`Tier.frontier`) | `next` | number at body, name in the name voice at 1.15 x title, facts at label and `ink2`; VoiceOver says "next" |
| open, not the frontier (the unlock, or a level before the frontier with no best) | dull, undimmed | name `ink` |
| closed | dull at 0.9 | number, name and facts at `ink4`; no marks, no lock |
| being played beside the menu (wide windows) | as its state | "playing" under its name, in the facts' place (Jack's call, unchanged) |

A tap anywhere on an open row opens its level (2.9). A tap on a **closed row** opens nothing: its pebble rocks, the
`seized` sound plays, and for 2 s its facts line is replaced, in `ink`, by what opens it: "solve 14 to open", or on a
closed tier "solve every plughole level to open". VoiceOver reads that as the row's value.

VoiceOver reads a row as today: "14, Lather, 4 rods, par 4", value "at par" / "solved, 2 over par" / "clean" /
"tried", and "locked" with what opens it.

### 2.3 A closed tier's gate

A closed tier can be dived into and scrolled through; its ledges are closed rows in its own rock and water. Its
header is the gate, the first thing a tap on its band lands on:

- the tier's name (place, title, `ink4`);
- "opens with every whirlpool level solved" (ui, detail, `ink2`);
- **the tally**: the 27 levels of the tier above as small pebbles (half-width 3.9) on one long sill of the closed
  tier's rock, three groups of nine, lit for each level with a best and dull for the rest, in level order. This is
  today's row of ticks;
- under it the levels still without a best, as runs: "short: 21–27" (ui, label; "short:" at `ink3`, each run in the
  ink of the tier above). Each run is a quiet control that opens its first level, which is always open. Runs wrap,
  never shrink.

VoiceOver: one element, "vortex, locked, opens with every whirlpool level solved, 20 of 27", then each run as a
button, "whirlpool 21 to 27, opens 21".

### 2.4 The daily

On the first ledge of the shallows, at both zooms. Shown only once the daily is open (plughole 23 solved, or the
unlock), as today.

- The header "today" (place, title).
- Its pebble: `next` until today's is solved, then lit.
- "Daily · Mon 23 Nov" (ui, body; the day in the locale's words), its marks after it as any row's (three hollow once
  tried).
- Under it, in data at detail and `ink2`: "4 days running" from a run of two; on a frost day "frost day", or "frost
  day · 4 days running"; nothing on a plain day with no run. The line wraps at large sizes.
- Until the daily or endless has first been opened (`Best.modesSeen`), "new" (data, detail, `ink`) follows the title.

A tap opens today's daily. The menu deals it afresh on coming to the front and at midnight, as today. VoiceOver:
"Daily, Monday 23 November", value its result and "4 days running", "frost day" first where it is one, and today's
hint describing what a daily is.

### 2.5 The archive

On the third ledge of the shallows (the second is bare), at both zooms, once the daily is open.

- Closed (nothing bought): a dull pebble; "Archive" (ui, body, `ink4`); "30 past dailies · comes with any pack" (ui,
  detail, `ink3`). A tap rocks the pebble, sounds `seized`, and replaces the second line for 2 s with "unlocked by
  purchasing any pack" in `ink`; it never opens a hollow (Jack's call, unchanged).
- Open: a lit pebble; "Archive" in `ink`; "30 past dailies · 12 at par". A tap opens the calendar (7).
- Until the store has read its purchases the row is drawn closed with only "30 past dailies", as today.

### 2.6 Endless, the drop-off

Under maelstrom's last terrace the slope ends. The last ledge's underside curves back to the leading edge and the
rock leaves the screen within one pitch; both far ridges taper out over the same depth; nothing stands below. The
water goes from maelstrom's red-black to near black over two pitches, the sinking motes thin to none, and a few
large slow motes drift sideways instead of down: a current, the first thing in the column that isn't falling. No
ledge and no pebble: nothing here rests on anything.

At the overview this is the screen's last 0.10 `H`; in the dive it is the last screen of the scroll, which stops
with the word at 0.5 `H`.

Shown once endless is open (as the daily):

- "endless" (place, title, `ink`), centred.
- With a best and no run saved: "best 9" (data, detail, `ink3`) under it. Under that, hanging in the dark, one small
  light per tank of the best run (up to 24, 14 pt apart, fading with depth): how far down the player has been.
  Decoration only; hidden from VoiceOver.
- With a run saved: "continue · tank 6 · brim 3 · best 9" (data, detail, `ink2`) under the word, and under that the
  quiet control "new run" (ui, body). A tap on the word or the line continues the run. A tap on "new run" arms it:
  it reads "new run? tap again" in amber for 2 s (under VoiceOver until focus leaves, announcing "Tap again for a
  new run"); a second tap drops the run and starts another.
- "new" after the word until a mode has first been opened.

A tap on the word with no run saved starts a run: the camera sinks off the last ledge into the dark, then the tank
opens (2.9). VoiceOver: "Endless", value "best 9" or the continue line, with today's hint.

### 2.7 Where the menu rests

- **A cold launch** rests on the overview (call 2 offers the alternative). A fresh install's first launch still
  opens plughole 01 itself (Jack's call, unchanged), over the slope.
- **Back from a tier's or a pack's level**: the dive, unanimated under the level's leaving, on `RootView.focus` as
  today: the row just left, or after a solve the one after it (`Level.focus(solved:)`). Back from the daily, an
  archive day's calendar or endless: the overview.
- **A dive into a tier** (a tap on its band, the tier's name spoken, "up a notch" then back) lands on
  `Tier.landing`: the first level without a best, else the first short of par, else its first ledge; a closed tier
  on its gate.
- **Landing on a ledge** puts it at 0.49 `H`. If that would cut its stretch's header by the top control, the camera
  rests instead with the header whole, 24 pt under that control (the rule today's `inSight` keeps: what leads the
  list is whole or well away). The frontier's glow, not a hairline, marks the row.
- The menu opens in the tier of the level last opened (`Tier.store`, unchanged), which decides which tier carries
  the way on.

### 2.8 Before things open

- Before plughole 01 is solved: no daily, archive, endless or hollows. The shallows' ledges and the drop-off are
  drawn bare and wordless and take no tap. Plughole reads "0/27 at par" with the way on "01 Drop ›"; the other
  tiers their reasons.
- The daily, archive and endless appear when the daily opens, each mode marked "new" (2.4, 2.6).
- The hollows and the packs' caption appear by the dock's rule today (`PackDock.shown`: plughole 09 solved, a pack
  owned or asked for, or the unlock), and are laid out unseen until the store's first read and price fetch settle,
  then fade in once (as the dock does).
- Debug's sandbox keeps a plain row, "anything goes", on a loose ledge under the drop-off's brink; it is out of v1
  and gets no design.

### 2.9 Opening a level

From a ledge in the dive: its pebble grows into the tank (`open`), travelling to the tank's place; the slope draws
aside 280 pt to the leading edge; one terrace rises under the tank (4.1); the play chrome fades in over the last
0.8 s. From the overview (the way on, the daily, endless): the camera first sinks to that ledge at `z = 1` (1.1 s),
then the same. The level's own opening (its wind-in or replay) starts as the tank reaches full size, as today it
starts as the level appears. A tap during the travel skips to its end.

### 2.10 Messages on the menu

- "Lens is yours" ("Triptych I is yours"): after an Ask to Buy approval that didn't land on its open hollow, the
  line stands for 5 s in the pack's ink, at the overview under the wordmark and in the dive under "↑ surface",
  waiting while anything covers the slope; VoiceOver hears it once (today's rule).
- The age-range request and Game Center's banners are the system's and unchanged.

### 2.11 The back swipe

The edge swipe works wherever a way back is written, and does what that control does:

- In the dive: rises to the overview. Interactive: the zoom follows the finger from 1 toward 0.6; let go past 0.4
  of the width, or flicked, it completes; else it springs back.
- In a level: today's `BackSwipe` rule decides whose touch it is (unchanged). The leaving is the reverse of the
  opening: the tank shrinks toward its ledge following the finger and the slope draws back in. Past the threshold
  the level leaves as "↑ levels" does; else it springs back. A lost Escapement tank keeps its save (unchanged).
- In a hollow, a pack's dive, the archive and settings: as that screen's way back.
- Under Reduce Motion nothing follows the finger; past the threshold on lifting, the screen changes under a fade.

## 3. Travel between tiers

Today a tap on a tier's chip, or a sideways drag, stirs the list away with the tank's shader. That goes: the strip
of chips, the sideways drag, `Stirred` and its hidden warm-up stir are removed, and nothing replaces the sideways
gesture.

- **From the overview**: tap a tier's band. The camera sinks into it (1.1 s): depth opens, the tier's terraces draw
  apart into ledges, the other tiers pass out of frame, and the names fade in beside their pebbles as the pitch
  passes 44 pt. It lands by 2.7.
- **In the dive**: the tiers are one continuous slope; scrolling crosses from one into the next past its header.
  "↑ surface" then a tap on another tier is the long jump: two taps and about two seconds, against one tap today.
- **From a result**: "up a notch" opens the next tier's first level as today, and the menu is then in that tier.
- The tier switch's sound plays once as a dive lands in a tier other than the one last shown, and not while
  scrolling.
- The water and rock change with depth as the camera crosses a boundary; nothing else marks it.
- Reduce Motion: the overview cuts to the dive at its landing under a 0.24 s fade.
- VoiceOver: each tier is a button on the overview; in the dive each tier's name is a heading, so the rotor's
  headings move tier to tier.

## 4. Play

### 4.1 The ground under a level

The slope has drawn aside. What is left is the water at that level's depth (a tier level's own; a daily's the
shallows'; endless's the drop-off's dark), the far ridges, and **one terrace** rising from the screen's foot, in the
level's rock, its bowed top 50 to 60 pt above the foot. The ground is a still while the level plays (1.7).

Per pack: Prism plays in clear water and white light (the ground at 0.9 grey, as the mock-up's `prism`); Lens in the
shallows' water with its terrace lit in Lens's glow; Escapement on paper (8.6). A pack level keeps its pack's glow as
its accent (`Level.colour`).

### 4.2 The header

- **The way back**, top leading, a quiet control (ui, body, `ink2`): "↑ levels" for a tier's level and a pack's
  (Jack's call: a pack's reads "levels", not the pack's name), "↑ archive" for an archive day, "↑ menu" for the
  daily and endless. Beside the menu in a wide window the words that read "✕ close" today still do.
- **The count**, top trailing (data, label): "moves 0 / par 1" in `ink2`, amber once the moves reach par with the
  stack not empty, magenta over par (unchanged). Endless shows its tank there; Escapement its budget's flip counter
  (the game's own drawing, unchanged); the sandbox its two controls.
- From accessibility1 up to the cap, the count goes under the way back, leading.

### 4.3 The title

Centred over the tank: the level's number (data, body, `ink2`), then its name (name voice, display). A pack's level
has its pack's name small over it (data, detail, `ink3`; the one place the play screen names the pack). Prism's
number is white with a faint white glow, never a colour, since colour on Prism means a channel. Endless's title
reads its name and tank as today.

### 4.4 The note and every other caption

Under the tank, centred, in the place voice at body: the level's note, at `ink` for its first 4 s of play and then
`ink2`. Everything that takes the note's place today takes it here, same words, same timing, in the same voice at
`ink`:

- "tap to skip", "watch the stir · tap to skip" over an opening;
- the lessons' and the ghost finger's notes (the note to turn the tank, the swirl's, the lens's), which go when the
  lesson is learnt, as today;
- "the tank is full: undo or reset", 3 s;
- "undos refill +2 each day you play", 3 s;
- "Practice: only the first try counts." and "Practice: this day's best was set on its day.";
- Escapement's "That tick can't come back. Undo, or again." (or "... Reset."), which stays until an undo, and its
  demonstration's "wait: the clock ticks, nothing turns";
- First Stir's time under the tank.

Plughole 01's first open hangs one more line under the note, once ever, at `ink3` in the ui voice: "sound, haptics,
colour letters: in settings, at the surface" (11: the gear it named is gone). The ghost fingers, arcs and rings are
drawn on the glass and are untouched.

### 4.5 The controls

Stones resting on the terrace, their labels over the water just above it (ui, body):

- **undo**, leading: "undo · 10", the bank's count after the dot ("undo" alone in the sandbox). Lit when there is
  something to undo; dull with its label at `ink4` when there is not, and it then refuses. With the bank empty it is
  dull but live, and a tap only shows the refill line (4.4). A refill shows "+2" (the first ever, "+2 undos") in
  data at label, rising 14 pt over the count and standing 3 s once the opening ends; VoiceOver announces it
  (unchanged).
- **reset**, trailing, its label on the stone's leading side. With moves played, a first tap arms it: the stone
  turns amber and the label reads "reset? tap again" for 2 s (under VoiceOver until focus leaves it); a second tap
  resets; any move, undo or finish disarms it. Where the terrace can't hold undo beside the armed label on a line
  each (`PlayLayout.rowHolds`), undo steps aside while it is armed, so no label wraps and neither the terrace nor
  the tank moves. With nothing played a tap replays the opening.
- **wait** (Escapement), between them, an engraved stone, "wait"; where the row can't hold three it has a terrace of
  its own above (the one case with two terraces in play), as today's second row.
- **Prism's swatches**, when colour letters are on: three pale stones between the note and the terrace, each glowing
  in its channel and lettered R, G, B; held, not tapped, and filled while held (unchanged behaviour).
- Endless has no stones; its terrace is bare.

The controls are dimmed and dead through an opening or a settle exactly as today. The play screen's parts keep their
order and their measured heights, so `PlayLayout`'s arithmetic stands with the terrace in the controls' row.

VoiceOver order: way back, count, title, tank, caption, controls (unchanged), with today's labels and hints.

## 5. The result

The level stays where it is; the result arrives round the tank (as the mock-up's `result`). There is no card: "the
card" below means these lines and stones, which `PlayLayout.finished` measures as it measures the card today, so the
finished tank shrinks by exactly what they lack and nothing scrolls or shrinks.

### 5.1 What arrives, in order

1. The count leaves the header; the title becomes one quiet line, number (data, label, `ink3`) and name (ui, body).
2. **"unstirred."** (place, display, the stamp's role and rules) rises over the tank. Endless's spill keeps
   "spilled." and Escapement's loss its stamp, the game's own.
3. Light settling (1.5).
4. Under the tank, centred, top down, today's lines in today's order and colours:
   - the marks, 16 pt discs landing one after another (`ResultMarks.land`), a filled disc glowing faintly;
   - the verdict (ui medium, body): "clean" in lime, "at par" in amber, "solved" in `ink`;
   - the facts (data, label, `ink2`): "moves 9 · par 7 · +2", the margin in magenta; Escapement's "moves 7" alone;
     endless's "tank 3 · brim 2 / 8", or after a spill "tanks cleared 7 · best 9" ("new best" in lime);
   - what clean takes, only where the solve is neither clean nor over par (ui, detail, `ink3`): "clean needs no undo
     or reset"; on the daily past its first try "clean counts on the first try";
   - the best line (data, label, `ink2`): "new best · was +6" or "best · par";
   - a completion (ui medium, body, in its colour with its glow, as Jack kept it): "Lens complete · 25 panels",
     "every tier unstirred";
   - one quiet pointer under it (ui, detail): "try Escapement ›", or on maelstrom 27 "more puzzles in the packs ›".
5. On the terrace, the stones (5.2).
6. On the daily, under the terrace's stones: "next daily in 7 h" (data, detail, `ink3`).

Timing is today's: the lines 1.4 s after the solve, or after the curtain call. Under Reduce Motion everything is in
place at once and no light settles.

### 5.2 The stones

Three seats on the terrace: leading, middle, trailing.

| Stone | Seat | State |
|---|---|---|
| "again ↺" | leading | lit; shown by today's rule (`Game.offersAgain`); never `next` |
| "share" (the daily) | middle, or trailing where nothing else is there | `next` in amber when it leads, else lit |
| "next ›" | trailing | `next` in the tier's or pack's colour; "more in Lens ›" on a pack's last free level; endless's "next ›" (VoiceOver: "Next tank") and, spilled, "new run ›" |
| up a notch | trailing, and "next ›" then moves to the middle | two lines, "up a notch" (place, label, `ink2`) over the tier's name and a chevron, "whirlpool ›" (name voice, title), `next` in that tier's colour |

- **Up a notch, closed** (only after an unlock was on and is off): a dull stone, the tier's name at `ink4` with no
  chevron, and under it "3 vortex levels unsolved" (ui, detail, `ink2`). A tap opens the menu's dive on that tier's
  gate. No lock is drawn.
- **Midway**: the solve that opens the next tier wherever it stands shows up a notch too, as today.
- Where three seats can't each hold their words on one line (the larger sizes, the narrowest phone), up a notch
  takes a second terrace of its own above the first, and the tank gives way for it.

### 5.3 Every variant

| Variant (its shot today) | What shows |
|---|---|
| clean (`result-clean`) | three marks, "clean", facts; "next ›" alone |
| at par with an undo (`result-undone`) | two marks, "at par", facts, "clean needs no undo or reset"; "again ↺", "next ›" |
| over par (`result`) | one mark, "solved", facts with the magenta margin; "again ↺", "next ›" |
| new best (`result-again-best`) | as its verdict, plus "new best · was +6" |
| the fullest (`result-fullest`) | two marks, "at par", facts, what clean takes, the best line; "again ↺", up a notch |
| up a notch, open / closed / midway (`tier-up`, `-locked`, `-midway`) | 5.2 |
| pack complete (`result-pack-complete`) | the completion and "try Escapement ›" |
| every tier (`result-every-tier`) | "every tier unstirred" and "try Lens ›" |
| the ladder's end (`result-ladder-end`) | once, "more puzzles in the packs ›" |
| a pack's last free level (`card-lens-taste-end`) | "more in Lens ›" in Lens's ink; owned, "next ›" in it |
| the daily (`daily-result`, `daily-clean`) | its verdict; "again ↺" unless clean; "share"; "next daily in 7 h" |
| practice (`daily-practice`) | "clean counts on the first try", no best line; "again ↺", "share", the next daily's time |
| an archive day | as a level: no share, no next daily |
| endless, a tank cleared / spilled | its facts line; "next ›" / "new run ›" |
| lost (`escapement-2-out`) | on paper: "out of ticks on move 3" (ui medium, body, ink); "undo" leading and "again ↺" trailing, engraved, again's outline in the plate's vermilion; under them, when undo is tapped with an empty bank, "undos refill +2 each day you play" |

Neither the result nor the lost screen has a second way back (Jack's call): the header's stays.

VoiceOver: the result is one summary element with today's words (`Spoken.result`, the completion's sentence), then
each stone; focus lands on the summary.

## 6. The curtain call

Unchanged in what it says, when and for how long (`Payoff`): the solve that finishes a tier, a paid pack or the free
game plays it between its wave and its result. The chrome leaves first: the header, title and note fade, the stones
fade and the terrace sinks out of the foot over 0.6 s. The veil dims the glass, the tank turns once about its centre
and ends upright (the tank's own motion, not the world's), and over it stand the name in display in its own sweep
and its stamp, "unstirred." or "25 panels unstirred"; the game's names each tier in turn, then "every tier
unstirred" and "made by screendead · thank you for playing". The words stay inside the glass where they fit and
under it where they don't, by today's rule. Then the terrace rises again and the result arrives as in 5.

The ground holds still throughout. On paper nothing glows, as today. Reduce Motion and VoiceOver are today's. This
is the one place a gradient is kept outside the wordmark, since it lies on the glass.

## 7. The archive

Opened from the archive's ledge. The camera sinks to the shallows and the archive's own column takes the screen: the
shallows' water and sandstone.

- The way back, "↑ menu"; beside it in a wide window, "✕ close". The title "Archive" (name voice, display).
- A stretch per month, headed by the month's name (place, title). A terrace per week of the player's calendar, seven
  seats across it, 52 pt apart, the terraces 72 pt apart. A day's seat: its number (data, label) over its pebble,
  and under the pebble its result in today's words (data, detail, `ink2`): "clean", "par", "+2", "tried"; nothing
  for a day not played.
- Pebbles: lit for a day with a best, dull and undimmed for one tried or not played. Today's own seat is bare with
  "today" under its number (the daily stays on the menu). A day just returned from is `next` once.
- A tap on a day opens that day's tank (2.9); its way back reads "↑ archive" and returns here.
- It scrolls when the months outrun the screen, opening with the latest week in sight.
- At the accessibility sizes it is a dive: a ledge per day, newest first, "Mon 16 Nov" (ui, body) and its result
  word after it.

VoiceOver: each day one button, "Monday 16 November", value "clean" / "at par" / "2 over par" / "tried" / "not
played".

## 8. Packs

### 8.1 The hollows

Each offer on the shelf (`Offer.shelf`: in Release Lens, Escapement, Prism, and Triptych I while it saves) is a
**hollow**: a round opening in the rock, dark inside, with the offer's cover (58 pt across) lit within, its light
spilling on the rock and catching the opening's lower lip in the pack's glow. They lie in plughole's stretch, in the
wall on the leading side of the ledges, centred at x = 56: Lens between ledges 6 and 7, Escapement between 11 and
12, Prism between 16 and 17, Triptych I between 21 and 22 (Debug's First Stir between 2 and 3).

Under a hollow, centred: its name (ui, detail, `ink`), with today's glyph after it for its state (a check owned, an
hourglass waiting on Ask to Buy). Under that, today's line by today's rules: "new" in the pack's ink (`Marks`), else
"2/3 free" (data, detail, `ink3`); never under the bundle.

The cover is the level its clip opens on, drawn as the game draws it, knobs and all, and **held still** at its
stirred frame (call 3: today's covers stir and unstir on a loop).

A tap on a hollow or its words opens it (8.2). The hollows show by 2.8's rule and change as the dock does today (the
bundle's leaves once it saves nothing).

**At the accessibility sizes** the slope stands at the leading edge and there is no rock beside the ledges, so a
hollow takes a row of its own in the column at the same depth: the gap between the ledges above and below opens by
the hollow's row, the rock bulges out to hold the opening (58 pt, centred at x = 48), and its name, glyph and line
stand beside it at the words' x, full size, wrapping. Nothing about packs is dropped at any size.

VoiceOver reads a hollow where it lies in the column, between its neighbouring ledges: "Lens, pack, $2.99", or
"owned", "waiting for approval", with "new" or "2 of 3 free levels solved" (today's words).

### 8.2 Inside a hollow

The cover rises out of the hollow to the top centre and grows into the pack's **clip** (290 pt across, no taller
than 0.36 `H`; it plays the pack's real play as today, and holds `Clip.still` under Reduce Motion); the slope gives
way to the hollow's inside: still dark water between two jambs of pale stone, a floor near the foot, and the cover's
light falling in three soft beams (the mock-up's `pack`). Each pack's inside takes its own light: Lens's magenta,
Prism's white split red, green and blue, the bundle's warm, Escapement's is paper (8.6).

Top down, centred, each line arriving in turn (1.5):

1. The way back, top leading: "↑ menu"; "↑ Triptych I" when opened from the bundle's while the bundle is on offer;
   "✕ close" where today's reads so.
2. The clip.
3. The eyebrow (data, detail, `ink3`): "pack · paid add-on", the bundle's "bundle · paid add-on"; an owner's, "pack" or "bundle".
4. The name (name voice, 1.3 x display) in the pack's ink (Prism's white).
5. Its line (place, body): "some rods zoom instead of turning" / "clocks tick after every move, on a budget of
   ticks" / "each rod stirs only some colours" / "three packs, for less".
6. The facts, three lines (ui, label, `ink2`), without the keys "for", "free" and "holds" (approved): who it is for
   ("after plughole · reading by colour"); the taste ("levels 1–3 free, no purchase"); what it holds ("30 specimens
   in five trays"; the bundle's "Lens, Escapement and Prism · 85 levels", as `Pack.named` writes it, "each pack's first 3 levels", and its
   saving as "save $2.98"). "More levels arrive in an update." follows while any are not in.
7. A pack's own small print (ui, detail, `ink3`): Prism's "letters for colour-blind play, in settings".
8. The arrival line, only when a level past the taste opened this hollow (place, body, `ink`): "You've played the
   free three. 27 more in Prism." or "The first three are free. 27 more in Prism."
9. **The status and the stones**, on a ledge that juts from the leading jamb (8.3).
10. Triptych's line, a quiet control (ui, detail, `ink2`), by today's rule: "or all three in Triptych I · $5.99 ·
    save $2.98 ›", broken only before "· save".
11. **The floor's tally** (8.4) and its count (data, detail, `ink3`): "0/30 at par"; an owner's "done 4/25 at par".
12. "restore purchases" (a quiet control; ui, detail, `ink2`), only while something sold is unowned; its outcome
    under it.

At the default size all of this stands on one screen of the reference phone. Where it doesn't (smaller phones,
larger type, the arrival line, a failure's line) the inside scrolls, the way back staying pinned at the top (Jack's
call), and buy stays on the first screen of the shortest phone. A hollow opened by a level past the taste opens
scrolled to the arrival line.

The bundle's inside names each of its packs as a quiet control that opens that pack's hollow, as today.

### 8.3 Buying, restoring and waiting

One ledge, two seats: the pack's stone leading with its label beside it, "try 3 free ›" trailing as a quiet control
(it opens the taste's first level without a best; "replay 01–03 ›" once all have one). Every word below is today's.

| State | The stone and its label | Under it |
|---|---|---|
| before the store's first read | pending; "checking purchases…" in the status's place, no price, no Triptych line | |
| unowned, price known | `next` in the pack's colour (Prism's pale); "buy $2.99" (ui semibold, body) | |
| price loading | lit; "buy" | "price loading" |
| price fetch failed | lit, live; "buy" | "App Store unreachable" |
| buying | pending; "buying…" | |
| waiting on Ask to Buy | lit and live; "asked" (a tap sends the request again) | a pending dot as a small breathing amber light, then "waiting for approval" in amber; under it "Ask to Buy: the pack opens here once it's approved · tap asked to send it again.", or the failure's words after asking again offline |
| failed | `next`; "try again" | "the purchase didn't go through" in magenta, and under it the failure's own words ("No connection. Try again when you're online.", "couldn't reach the App Store", "purchase failed") |
| purchases off on the phone | no stone | "In-app purchases are turned off on this iPhone."; "try 3 free ›" kept |
| not sold in the storefront | no stone | "Not sold in your country's App Store." |
| revoked or no longer shared | `next`; "buy again" (refunded) or "buy" (no longer shared) | "Lens isn't on this Apple ID any more · your progress is kept" / "Lens is no longer shared with you · your progress is kept", at `ink3` |
| owned | `next` in the pack's colour; "play 04 ›" until a level past the taste is solved, then "continue 06 ›", none once every level is at par; the bundle's "play Lens 04 ›" | "✓ owned · every level open" ("✓ owned · all three packs open") in lime; no "paid add-on" in the eyebrow, no taste |
| the bundle waiting or failed, seen on a pack's hollow | the pack's own stone stays "buy" | "Triptych I is waiting for approval" and "Ask to Buy: Lens opens here once Triptych I is approved."; Triptych's line dimmed, or its own failure under that line, never as the pack's |
| restoring | the restore control reads "restoring…" | |
| restored | | "restored Lens" |
| nothing restored | | "nothing to restore on this Apple ID" |

A status line under the stone is ui, detail, `ink2`.

**A purchase landing** on an open hollow (bought, approved or restored): the solve's chime and a success haptic; the
owned line settles in; the stone becomes "play 04 ›"; the floor's dull pebbles light one after another, 60 ms apart,
in place of today's locks dissolving. Under Reduce Motion the state changes at once. The launch's first read is no
landing.

VoiceOver: today's labels ("Buy Lens", "Buying… Lens", "Try Again Lens", "Ask again for Lens", "Buy Again Lens"),
each with its price; the slope behind is hidden; a change of state is announced.

### 8.4 Picking a level: the pack's own slope

The floor's tally is the mock-up's row of small pebbles, grouped by chapter (six to a tray for Prism): lit for a
level with a best, pale or `next`-bright for an open one without, dull for one closed past the taste. It is a count,
too small to pick from: the whole floor, tally and count together, is **one control**. Its label under the count
reads "levels ↓" (ui, detail, `ink2`).

A tap on it, or a scroll past the foot of the inside, **sinks through the floor into the pack's own column**: the
same slope and the same dive as a tier's, in the pack's pale rock and still water, lit in the pack's colour. This is
where a player picks a level, and it holds everything today's list holds:

- a stretch per chapter, headed by the chapter's name (place, title; Prism's "two colours") and its progress
  ("0/6 at par"; data, detail, `ink3`);
- a ledge per level: number, name, marks (Escapement's result in words, "solved", "+2", "tried", as it has no par),
  and under them its facts where it has them;
- the levels past the taste closed for a player who doesn't own the pack: dull, `ink4`. A tap on one rises back to
  the inside at the buy stone, which pulses once (its glow to 1.6 x and back over 0.6 s); VoiceOver's focus goes to
  the stone;
- the way back, top leading: "↑ Prism" (the pack's name), which rises to the inside;
- it lands like a tier (2.7): on `PackCard.pickUp`'s level for an owner, on the first free level without a best
  otherwise.

A pack's level opens from its ledge as any level does (2.9). Its way back, "↑ levels", returns to this dive on the
focus row (the row left, or after a solve the next), as `PackCard.focus` does today. A purchase landing while the
pack's dive is open lights its closed pebbles the same way.

So a specific pack level is three taps from the menu's dive: the hollow, "levels ↓", the ledge. An owner continuing
is two: the hollow, "play 04 ›".

VoiceOver: the floor is "Levels, 30, 0 at par", a button; the pack's dive reads as a tier's, a closed row saying
"locked, needs the pack".

### 8.5 The bundle

Triptych I's hollow shows its three wedges, still. Its inside is 8.2 with no floor and no tally: in their place the
three packs' names as quiet controls with each one's progress. Owned: "✓ owned · all three packs open", the stone
"play Lens 04 ›" playing on in the first of its packs with a level left, no restore.

### 8.6 Escapement's paper

Escapement's inside, its dive and its levels are **paper**, as its levels and cards are today (`Page`): the ground is
bone, the rock and ledges are drawn in ink as an engraving (an outline that thickens on the shaded side, hatching
under each lip, no fills, no glows, no motes), the water is the bare page, every word is the page's ink, every stone
is `engraved`, and the accent, the plate's vermilion, stays on outlines and marks and never colours a word.
`Page.tone` raises `ink3` to `ink2` there, as it does `text3` today.

Entering, the page spreads from the cover outward over 0.6 s as a soft-edged wash (a growing circle, no turning);
leaving, it draws back to the hollow. Reduce Motion: a fade. The status bar turns dark over the page, as today.
Beside the menu in a wide window the page stops at the pane's edge (Jack's call, unchanged).

## 9. Settings and consent

### 9.1 Settings

Opened from the stone on the bank, which is in sight at the overview and at the top of the dive. The camera rises
until the surface stands at 0.188 `H`; the wordmark and the menu's words fade; the water under the surface becomes
the settings' own column, sandstone in the shallows' light, and each switch's stone drops in from 26 pt above its
ledge and settles, 140 ms apart (the mock-up's `settings`). In the air: "settings" (place, display).

A ledge per row, 74 pt apart (more where a row's words need it), top down. A switch's row: its stone, its name (ui,
body), after it "on" or "off" (data, detail), and under them its explanation (ui, detail, `ink3`), kept on every row
(approved). On: a lit stone, the name at `ink`. Off: a dull stone, the name at `ink2`. A tap anywhere on the row
flips it: the stone lifts 6 pt and settles as it changes (at once under Reduce Motion), with today's sound.

| Row | Its words | Shown |
|---|---|---|
| music | "the beds under the menu and the levels" | always |
| sounds | "every effect and button" | always |
| haptics | "the tank's knocks and taps" | always |
| colour letters | "R, G and B on Prism's knobs" | always |
| supporter mark | "✦ by the title and in the daily's share line" | once a pack is owned |
| analytics | "on · how you play, never who you are" / "off · nothing is sent" (in place of on/off and the explanation) | in a build with analytics |
| open every tier | "every level and pack too, without buying" | the editors' build only, labelled as today |
| restore purchases | "packs bought on this Apple ID"; then its outcome: "restoring…", "restored Lens", "nothing to restore on this Apple ID" | always; no stone |
| report a problem ↗ | "with the log: touches, moves, purchases and errors" | where a support address is set; no stone |
| privacy policy ↗ | "what the game keeps, and why" | where a policy URL is set; no stone |
| the version | "Unstir 1.0 (1)" (data, detail, `ink3`; "editors" after it in that build) | always; not a control |

The three rows without a stone are quiet controls on their own ledges; "↗" (in `ink`, not amber) says the row leaves
the game. Under the last ledge, centred, the way back: **"↓ back into the water"** (a quiet control; ui, detail,
`ink2`). It, the edge swipe and a tap on the air return to where settings was opened from.

It scrolls where the rows outrun the screen (the shortest phone, the larger sizes), the title scrolling away with
them and the way back following the last row. Settings takes the menu's type size, as today's sheet does.

VoiceOver: "settings", heading; each switch as a switch with its explanation as its hint; the three links as
buttons; the version as text; "Back".

### 9.2 Consent

Shown as today: at the first menu of a build with analytics, before anything else can be touched (not in v1's
default build, which has none). No card and no scrim: the overview is up, its words, pebbles and hollows hidden, and
the ground is drawn at 0.35 of its light, the dusk deepened. Centred in the open water from 0.34 `H`:

- "Help improve Unstir?" (name voice, title);
- "Let the game tell us how you play. Never who you are." (ui, body, `ink2`), wrapping;
- "What does it send? ›", a quiet control (ui, label), which opens the full list under it (today's text; ui,
  detail, `ink2`) and then reads "Hide the list ‹";
- on one bowed sill, side by side and alike in every way, two lit stones of one size, each with its word under it:
  **"Yes"** and **"No"** (ui medium, body). Neither is `next`, neither glows more, neither is first by any cue but
  reading order (Jack's call: the same control, neither preselected).

Nothing else takes a touch until one is tapped; then the ground returns to its light over 0.6 s and the menu's words
arrive. With the list open at large sizes the block scrolls, the stones last. VoiceOver: a modal; the question, the
line, the link ("hidden" / shown), "Yes", "No".

## 10. Wide windows

The panes are today's (`PlayLayout`, `MenuLayout`; Jack's calls on the open Duo, the tabletop and the menu beside
play all stand). What is drawn in them changes:

- **The menu alone, opened like a book**: the slope in the leading half at a phone's width; the trailing half is the
  same water, the far ridges running on across it, empty until something opens there.
- **A hollow's inside, the archive and settings** open over the trailing half, the slope staying live beside them,
  one at a time; their way back reads "✕ close". A pack's dive, from there, takes the trailing half too.
- **A level beside the menu**: the tank, its header, title, note and terrace in the leading half; the slope in the
  trailing half exactly as with no level open, the row being played saying "playing". The result's lines hang in
  the trailing half over the slope, which dims to 0.35 of its light under them, headed by "unstirred." (today's
  placement); its stones stay on the tank's terrace.
- **The tabletop**: the slope in the upright half; what opened at the foot of the flat half today opens there.
- The ground is drawn once per pane, and the fold between panes stays dark.

## 11. Words that change

Everything not listed keeps its words exactly.

| Today | On the slope | Why |
|---|---|---|
| "‹ levels", "‹ menu", "‹ archive", "‹ Triptych I" | "↑ levels", "↑ menu", "↑ archive", "↑ Triptych I" | approved |
| the tier chips | the tiers' names on the water | approved |
| "Endless" | "endless" | a place, written as the tiers are (the approved overview) |
| the header "today" over the modes | "today" over the daily alone | the archive and endless have their own places |
| "PACKS · PAID ADD-ONS" and "first 3 levels of each free" | one line under plughole's name: "packs · paid add-ons · first 3 levels of each free" (2.2's three states) | approved: the caption moves there |
| none | "↑ surface" | new: the way from the dive to the overview |
| none | "14 Lather ›" on the overview | new: the way on (call 2) |
| none | "levels ↓" | new: the way from a hollow's inside to its levels |
| none | "↑ Prism" (a pack's name) | new: the way back from a pack's levels |
| none | "↓ back into the water" | new: settings' way back (the mock-up's) |
| "PACK", "BUNDLE", "PACK · PAID ADD-ON", "BUNDLE · PAID ADD-ON" | "pack", "bundle", "pack · paid add-on", "bundle · paid add-on" | lower case, as the approved hollow |
| "0/6 at par" beside each chapter only | also "0/30 at par" on a hollow's floor | approved |
| "sound, haptics, colour letters: ⚙ on the menu"; VoiceOver's "... in settings, the gear on the menu." | "sound, haptics, colour letters: in settings, at the surface"; "... in settings, at the surface of the menu." | the gear is gone (approved) |
| "UP A NOTCH", "WHIRLPOOL ›" | "up a notch", "whirlpool ›" | no capsule, no capitals (the approved result) |

## 12. Calls for Jack

Each stands alone. These are the places where the slope drops or changes something a player sees that the approved
list didn't name, or touches an earlier call of his. Everything else in this document follows the approved list or
keeps today's behaviour.

**1. Packs on the opening screen.**
Today the five pack covers sit along the bottom of the menu on every tier, from the moment plughole 09 is solved.
On the slope, as approved, the packs are lit hollows in plughole's rock and the opening screen (the whole column)
shows none of them: a player sees a pack only by diving into plughole and passing it, or from a result's pointer
("more in Lens ›", "try Escapement ›", "more puzzles in the packs ›"). A player working through whirlpool, vortex or
maelstrom never passes one. This is the approved design, and it is the biggest sales risk in it.
Alternative: draw the same hollows, small and lit, in plughole's rock on the opening screen too, with the caption
"packs · paid add-ons · first 3 levels of each free" under plughole's name there; a tap on either dives to them.
They are the same hollows seen from further off, so it costs about half a day and adds one line of small text and
four small lights to the opening screen.
Recommended: the alternative. If he does nothing, the approved version is built and the hollows can be added later
without redrawing anything.

**2. Where a launch lands, and the way on.**
Today a launch opens the level list already centred on the next unsolved level: one tap plays it. The approved
opening screen is the whole column, where levels are pebbles too small to tap, so playing on would take two taps
and a dive (tap the tier, then the level).
Proposed: launch on the whole column, and write the next level under its tier's name there, "14 Lather ›"; one tap
on it dives and opens the level in a single move. That line is new, and he removed a similar "next: 07 · Sprinkle ›"
line from today's menu on 2026-11-11 because the list's own marker did the job; on the whole column there is no list
to do it.
Alternative: launch straight into the dive on the next level, as today, with the whole column one tap away
("↑ surface"). Then no new line is needed, but the opening screen is the list, the whole-column picture is rarely
seen, and the daily is a tap further for a player on a deep tier.
Recommended: the proposal. Coming back from a level lands in the dive on the next level either way.

**3. Pack covers hold still.**
Today each cover on the menu plays its pack on a loop, stirring and unstirring every seven seconds, so a cover
shows how its pack plays (his calls of 2026-10-25 and 2026-11-08). On the slope each hollow's cover would be the
same picture and knobs held still at its stirred frame, as covers are today under Reduce Motion; the live play stays
in the clip at the top of the pack's page, one tap in.
Why: he ruled that nothing in the interface may stir, and a hollow in the rock reads as the world rather than as a
tank; and up to four live covers redrawn 30 times a second on the menu are the largest battery cost the menu has.
Alternative: keep them live, as glass seen through the rock. It costs the battery what it costs today.
Recommended: still. If he does nothing they are built still.

**4. The daily, the archive and endless have one place each.**
Today the daily, the archive and endless stand at the top of every tier's list, so a player in maelstrom has them
on screen. On the slope the daily and archive are at the surface and endless at the foot of the column: all three
are on the opening screen, and none is beside the levels in the dive. From deep in a tier they are two taps away
("↑ surface", then the daily) where they are one today. This was listed for another version of the Descent, not for
the Shelf.
Recommended: accept it; it is what makes the column a place. It matters less if call 2's proposal is taken, since
every launch then opens with all three in sight.

**5. Switching tier takes two taps.**
Today a tier is one tap on its chip, or a sideways swipe, from any tier. On the slope it is "↑ surface" and then a
tap on the tier (about two seconds), or a long scroll; the sideways swipe does nothing. The approved list says the
tabs become bands of water to tap or dive into, but not that the swipe goes or that the tap count rises.
Alternative: keep a sideways swipe in the dive that carries the camera to the next or previous tier's landing in
one sink. It is cheap to build but it is a hidden gesture with nothing on screen to suggest it.
Recommended: accept two taps, no swipe. Players change tier rarely; "up a notch" on a result still goes straight on.

**6. A pack's level list comes back as its own slope.**
The approved list says the shop page loses its level list and the levels become pebbles. Built exactly so, nobody,
owner or not, could choose a pack level: an owner could only press "continue". Proposed: the pebbles on the page's
floor are one control, "levels ↓", that sinks into the pack's own small slope, a ledge per level with its number,
name and result under its chapter's name, built from the same parts as a tier. It brings back what the list held;
it adds one tap for an owner replaying a particular level (three taps from the menu, against two today).
Recommended: build it. Without it a paid pack's levels can't be picked, which no owner should meet.

**7. Small losses to confirm together.**
- The lock symbol goes everywhere, not only on level rows: on closed tiers, the locked archive, a pack's closed
  levels and a closed "up a notch". Each is a dull pebble with dimmer words, and each still says what opens it when
  tapped.
- The amber "↗" on settings' two links becomes plain; the amber "day", "past" and "∞" tags that stand where a
  level's number would on today's menu go, the daily, archive and endless being marked by where they are.
- The supporter mark shows only on the opening screen, beside the wordmark, since the dive has no title. It keeps
  its place in the daily's share line.
- "PACK", "BUNDLE", "UP A NOTCH" and the tier's name on it lose their capitals.
- On the result the three buttons become stones on the ledge under the tank, so "again" and the way on stand at
  opposite corners rather than stacked full-width.
Recommended: accept all five; each follows from a change he approved.

Kept as today though the mock-up drew otherwise, so nothing to decide: the play screen's text still stops growing
at the largest ordinary size (the mock-up's large-text play still went past it and shrank the glass in play);
"again ↺" keeps its glyph; the result's lines keep today's order; "paid add-ons" stays in the packs' caption.

## 13. The build split

The foundation, being built now by its own owner, is assumed to be: the ground shader, the slope geometry, tone on
water and the stone control. File and type names below are this document's; where the foundation has chosen others,
its names stand and only the mapping changes.

**The foundation's files** (its owner only): `Slope.metal`, `SlopeGround.swift` (the Metal view, the clock and its
pauses, 1.7), `SlopeGeometry.swift` (columns, stretches, the ledge function and the camera, 1.2; pure, so every
piece asks it where things are), `Stone.swift` (1.4), `Tone.swift`, `Type.swift` (1.3), `Buttons.swift`. Every piece
needs from it, beyond the main column: a column built from any list of stretches (packs, settings, the archive), the
paper look (8.6), the hollow's inside, the ground's light as a uniform (consent, the wide result), and one terrace
alone (play).

**The slope lands beside the old screens, not over them.** A build setting and a harness flag (`UNSTIR_SLOPE`)
choose the world; until the last piece is in, the default is today's app and `master` stays shippable. Each piece
adds new files and leaves the old view's file alone, so no piece edits another's file, and each screen is shown to
Jack from the flag before it merges. The last change flips the default and deletes the old views.

**First, two extractions** (one owner each, before the pieces start; no change in behaviour, the existing tests
passing untouched):

- **Menu logic out of `Menu.swift`** into a new `MenuModel.swift`, with nothing of SwiftUI's views in it:
  `Tier.step`, `frontier`, `short`, `landing` and `Level.focus(solved:)` (already extensions, moved as they are);
  `MenuView.lead` and `dailyLines` as free functions on a `Menu` namespace; what a closed row says
  ("solve 14 to open", the tier's form) and the gate's lit count, today computed inside `TierList` and `LevelRow`;
  the 2 s refusal and the endless row's arming as a small state type beside `ResetArm`'s; `CameFrom`. `SupporterMark`
  and `Sparkle` move to `SupporterMark.swift`. `Menu.swift` is left holding only today's views, which the slope
  never edits.
- **The play screen's chrome out of `TankView.swift`** into a new `PlayChrome.swift`: `LevelView`'s `header`,
  `titleRow`, `caption` and `controls` become views that take values and closures, `LevelView` keeping the state,
  and the result's and lost card's place becomes a slot `LevelView` fills. `MenuLayout` moves from
  `PlayLayout.swift` to `MenuLayout.swift`. `Shelf.swift` is cut in three with no other change: `Offer.swift`
  (`Offer`, the `Store`, `Failure`, `Pricing` and `Purchase` extensions, `Marks`: the words and rules), `PackCovers.swift`
  (`PackTank`, `Wedge`, `LoopingTank`, `PackClip`), leaving `PackCard` and `PackDock` in `Shelf.swift`.

**Then six pieces in parallel**, one owner each:

| Piece | Builds (sections) | Its new files | Old files it alone may edit | Reads only |
|---|---|---|---|---|
| A. The menu | the overview, the dive, a ledge's row, the gate, the daily's and endless's places, landing and focus, travel between tiers, messages (2, 3) | `SlopeMenu.swift`, `SlopeLedge.swift`, `SlopeGate.swift` | none | `MenuModel.swift`, `SupporterMark.swift`, `ResultMarks.swift` |
| B. Play | the ground under a level, header, title, captions, the terrace and its stones, the terrace's seats for C (4) | `SlopePlay.swift` | `PlayChrome.swift`, `PlayLayout.swift`, `TankView.swift`, `PlayLayoutTests.swift` | `Lessons.swift`, `Page.swift` |
| C. The result | the result's lines and stones, every variant, the lost screen, the curtain call's chrome (5, 6) | `SlopeResult.swift` | `ResultCard.swift`, `ResultMarks.swift`, `Payoff.swift`, `PayoffViews.swift`, `ResultMarksTests.swift`, `PayoffTests.swift` | `PlayChrome.swift` |
| D. Packs | the hollow on the slope, its inside, every store state, the pack's own slope, the bundle, the paper inside (8) | `SlopeHollow.swift`, `SlopePack.swift` | `PackCovers.swift`, `Clip.swift`, `ClipTests.swift` | `Offer.swift`, `Pack.swift`, `Store.swift`, `SlopeLedge.swift` once A has it |
| E. The archive | the archive's ledge and its calendar (2.5, 7) | `SlopeArchive.swift` | `Archive.swift`, `ArchiveTests.swift` | |
| F. Settings and consent | 9 | `SlopeSettings.swift`, `SlopeConsent.swift` | `Consent.swift` | |

How they meet without sharing a file:

- A places what D and E draw. D hands A one view, the hollow (`SlopeHollow`), and E one, the archive's ledge
  content; A asks `SlopeGeometry` for where each goes. Until they land, A draws a plain dull pebble in their place.
- B owns the terrace. Its seats (leading, middle, trailing, and a second terrace) are a small type in
  `PlayChrome.swift` that C fills; C never edits B's files. B hands in before C needs more than the stub the
  extraction left.
- D's pack slope uses A's ledge row. If A's isn't in yet, D builds against the extraction's row data and swaps the
  view when it is; the row's inputs (number, name, marks or a word, facts, state) are fixed by 2.2.

**One integrator**, working alongside from the start, alone edits everything shared: `UnstirApp.swift` (`RootView`:
which world, opening a level from a ledge, 2.9, the back swipe's handover, 2.11; the `Harness`'s flags),
`MenuLayout.swift` and the wide windows (10, last), `Spoken.swift`, `Localizable.xcstrings`, `scripts/shots.sh`,
`shots/index.txt`, `docs/architecture.md`, `HANDOFF.md`, `UnstirTests.swift` and `ToneTests.swift`. A piece writes
its strings in its own code with `String(localized:)`, lists its shot cases and its architecture entry in its pull
request's text, and the integrator enters them, so those files have one writer. The integrator makes the final
change: the default flips, `Menu.swift`, `Shelf.swift`'s card and dock, `ResultCard`'s old views, `SettingsSheet`,
`ConsentCard`, `ArchiveView`, `Stirred` and the chips go, and the tests that pinned only their layout go with them.

Order: the foundation and the two extractions; then A to F at once, with the integrator; then the wide windows; then
the flip. The App Store screenshots and preview film are retaken after it.
