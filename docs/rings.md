# The rings

The menu Jack picked on 2026-11-27, after dropping the side-on shelf: "no look just restart from the ground up.
including the design", then of three new designs "i like the rings design so far", then of two looks "A, sun in the
ring". It is built behind a launch flag; the list (`MenuView`) stays the default until Jack signs the rings off.

The mock-up is the source of truth for the look: `design/negative-space/world/rings-outrun.js` on the branch
`design/menu-rings`, look `a` (`world/rings-sun/index.html`). Geometry, colours and type here are taken from it.

## The design

- **One ring per tier.** 27 numbered beads on a circle 190 pt from its centre, 44 pt apart, the seam between 27 and
  01 at the top. One ring is in front at a time.
- **The sun is the stage.** A 300 pt banded sun sets inside the ring on a horizon 100 pt under its centre. On it,
  dark: the tier's name, "14/27 · 11 at par", the level the middle plays (the first without a best, else the first
  short of par, else 01) and a play mark. A shut tier's sun is down: a dusk disc rimmed in the tier's colour, with
  what opens it in light type. The rings a swipe away are named over and under the sun ("↑ plughole", "↓ vortex").
- **Beads.** At par: filled in the tier's colour with a yellow rim. Solved over par: a lit rim round dark glass.
  Not solved: dark glass and a faint rim. The way on: larger, white-hot, its rim split into cyan and magenta.
- **A swipe** up brings the next tier's ring forward and down the one before, by scale and fade alone: nothing
  rotates. The suns cross-fade, the stars shift a little, and the floor's lines run towards the viewer, two a ring.
- **Sound.** The menu's bed is the produced hybrid (Jack, 2026-11-28: "Hybrid, produced"): round four's
  `hybridProduced` from `sound-src/synthwave-sketches.csd`, E minor at 100 bpm, `menu.m4a` at -29 LUFS, as the old menu
  plays it too. A swipe that commits to a new ring plays the warm pair with its drum folded in (Jack, 2026-11-28:
  "Drum folded in"): falling (`swipe-down`) going deeper, rising (`swipe-up`) coming back, at -24 LUFS momentary,
  beside the tier switch's -25. It sounds once a ring, as the finger lets go towards it
  (`scrollViewWillEndDragging`'s target page) or a glide or VoiceOver's step starts (`go(to:)`), never on a scroll
  callback, and a pose for a shot is silent. Both are ordinary effects, decoded with the rest at launch.
- **Taps.** A tap on the middle, or on the bead it names, opens that level at once. A tap on any other bead names
  it in the middle, with its best and par and "tap again to play" (or what opens it, "solve 08 to open"), and a
  second tap, or one on the middle, plays it. A tap anywhere else lets it go. This is the mock's, and it is built so
  for now. Jack's earlier rule was that a tap on a level opens it at once; which holds is his call, not yet made. The
  other way is one line: `RingsView.act`'s `.bead(i)` case opens `ring.spots[i]` without naming it first.
- **The archive's ring** (today) stands above plughole once the daily shows: a bead for each past daily, no
  numerals, gold at par, and on its sun "today", "30 past dailies · 3 at par" and today's date with a play mark, which
  plays today's daily. A bead names its day, its best and par; a second tap plays it from the archive. It is shut, its
  sun down with "comes with any pack", until a purchase opens the archive (`Archive.open`), and until the store's first
  read, so an owner never meets the lock; a shut bead says "unlocked by purchasing any pack".
  Back from a daily, today's or a past one, the menu opens on this ring while it is open (`RingsMenu.opening`), as
  it does on endless's back from a run and on a tier's back from its level.
- **Endless's ring** stands below maelstrom once the daily shows: no beads, its circle one neon tube (`.orbit`), a pink
  sun. With a run saved, the middle says "tank 6 · brim 3 · best 9" over "continue", which plays the run, and "new run"
  in the play mark's place: a first tap arms it ("new run? tap again", for `ResetArm.window`, under VoiceOver until a
  second), a second drops the save and deals another, as the old menu's row does. With none saved, "new run" and the
  play mark deal one, its seed drawn as it plays, so the model stays the same between reads.
- **The daily** is an evening star on an arc over the ring, "Daily · Fri 27 Nov" and "4 days running" set along the
  arc either side. It shows once the old menu would show it (plughole 23 solved, `MenuView.lead`).
- **The packs** are three covers on an arc under the ring, each with its name and its line ("new", "2/3 free",
  "owned ✓"), over "packs · first 3 levels of each free". They show once the old menu's dock would (plughole 09
  solved or a pack owned, `PackDock.shown`), after the store's first read has settled. A cover opens the pack's
  existing card. Triptych I has no cover: a pack's card offers it.
- **Settings** is seven motes at the foot, opening the existing sheet. The wordmark is chrome, at the top.
- **The scene.** A sky from deep purple through magenta to orange with stars, cyan wireframe mountains either side
  of the sun, and a magenta grid floor running to the horizon. The grid's straight lines, the sun's bands, the
  horizon and the mountains are Jack's references, which override the redesign's "no hard straight lines" here.

## The speed rule, as built

Jack rejected two menus for hitching. The rule: all art is drawn once, off the main thread, into bitmaps; motion is
only Core Animation transform and opacity on the layers that hold them; nothing is drawn per frame and nothing runs
at rest.

- **Bake once.** `RingsArt` (RingsArt.swift) draws every picture on a thread of the pool into a `CGImage` and
  keeps it by its `RingsPiece`, a key made of everything that decides its pixels. The cache is static, so the menu
  the root builds again on each return from a level fills from it in one commit, with no bake. A launch's first
  bake lands as one commit too, and the scene fades in once over the sky's top colour.
- **Sprites, not sheets.** A ring is 27 bead layers, 27 numeral layers and 27 short threads between beads, all
  sharing a few bitmaps: four beads a tier colour, one numeral per number and ink, one thread a colour. No ring is
  one bitmap. Soft or large art is baked under the screen's scale: the suns and the floor at 2x, the sky as a strip
  four points wide. The cross lines' strip is 2 points wide and 5200 long, stretched across the floor, baked at 1.5x
  (7,800 pixels tall). At 3x (15,600) the simulator drew a hard-edged pale band over the far floor on some launches;
  at 1.5x thirteen captures of the same pose, from 1.6 s to 5 s after launch, showed none, and one shot of a run that
  had just installed the app showed a fainter one. The cause is not settled (a texture past 8192 pixels cut into
  tiles, or mipmaps not yet made), and the phone is the judge; 1.5x also softens the nearest lines a little on a 3x
  screen, where they are mostly glow. On a Pro Max with every piece baked the art is about 23 MB with
  the four tiers' rings and 31 MB with the archive's and endless's too (the tour's log line prints it).
- **Layers.** `RingsView` (RingsView.swift) is a `UIView` whose layers are `RingsLayer`s, which never animate a
  change by themselves. Back to front: the ground behind the suns (sky, stars), one sun a ring, the ground in front
  (mountains, floor, the cross lines, the horizon's haze), one container a ring (its beads group and its words
  group), then the wordmark, the daily, the covers and settings. The beads' and words' groups have group opacity
  off, so a fading ring's sprites fade by their own alpha and nothing is composited off screen first. No layer has
  a shadow, a mask or `shouldRasterize`: every glow is in its bitmap.
- **One pose.** `RingsPose(depth:)` gives a ring's scale and its beads', words' and sun's opacities from its depth
  from the ring in front. `apply(place)` sets them for every ring and slides the ground, and is the only thing that
  moves the menu. It is the mock's rule: a deeper ring is 0.78 the size per step and unseen at rest, a passed one
  1.5 times and gone by 0.8 of a step.
- **The swipe is a native scroll view.** A hidden paging `UIScrollView` 240 pt tall (the finger's travel for one
  ring) holds no content; its pan recognizer is moved onto the menu. A drag, the paging glide after it and a touch
  that catches it mid-glide are all UIKit's, at the display's rate, and `scrollViewDidScroll` does nothing but
  call `apply`. There is no display link of the menu's own and no SwiftUI animation. Its scroll edge effects are
  hidden (iOS 26 on): it stands under the status bar, where UIKit otherwise blurs the backdrop into a soft edge
  ("Pocket") and renders it again on every frame it scrolls, 16 offscreen passes a frame on a 13 Pro Max simulator,
  and it holds nothing to edge. Without it the stars run sharp to the top of the screen, as in the mock, and a glide
  costs 2 passes a frame, both the system's (64-pixel backdrop copies by the status bar). The menu's own layers
  cost none.
- **The floor.** The grid's lines along the floor do not move when the floor runs, so they are baked flat with it.
  The lines across it are one strip of the flat floor, laid back at a right angle under its window's fixed
  perspective (`sublayerTransform`'s `m34`, the vanishing point the window's top middle) and slid along itself by
  the compositor. The strip repeats every 200 pt, so the slide wraps: it never travels more than half a repeat, its
  foot stays at the screen's foot, and the wrap falls where the nearest line is leaving the screen, never at rest.
  The lines thin and fade with distance by perspective and trilinear filtering.
- **120 Hz.** The scroll view runs at the display's rate. The only animations the menu adds itself are short
  opacity fades (the scene's first, a picked bead's words and halo), each with `preferredFrameRateRange` 80 to 120.
  `CADisableMinimumFrameDurationOnPhone` is already in Info.plist.
- **At rest nothing runs.** No timer, no display link, no animation. `RingsCount` counts what the main thread does
  for the menu (layouts, SwiftUI updates, model reads, builds, bakes, scroll callbacks), and the tour's `rest`
  prints them over six seconds: all zero on the simulator (2026-11-27). Its `swipe`, down through every ring and back,
  costs scroll callbacks alone (112 at the simulator's 60 Hz over four rings, 184 over six), with no layout, build or
  bake. On the 13 Pro Max (2026-11-27) the screen drew at 60 Hz, slowing to 48, through three of the swipe's rests
  and for about a second after launch: each time the trace's commits were GameOverlayUI's alone (Game Center's
  overlay, which shows its welcome banner after sign-in), none the app's.
- **A named bead** bakes its three lines on a tap, off the main thread, and shows them as they land.
- **The model's read** runs on the main thread at launch and on each return from a level. The archive's ring deals
  thirty past dailies, which took 0.3 s in a Debug build on the simulator, so `RingsModel` keeps each daily as dealt
  (the generator is frozen) and a later read takes about 3 ms. The launch's first read still deals them, as the old
  menu does in its own init: about 0.3 s before the menu's first frame in Debug, not yet measured in Release or on
  the phone. A Debug or probe build logs each read's time ("rings model read").

## The files

- **RingsModel.swift** `RingsModel`: what the menu shows, read once on the main actor and compared, so the layers
  are laid out again only when it changes. A bead opens only if its tier is open and the level before it has a
  best, the list's own rule: `RootView.show` does not check it.
- **RingsArt.swift** the look, all of it: `RingsPiece` names each picture, `RingsLook` holds the constants the
  engine needs (colours, the ground's layers, the floor's eye and repeat), `RingsPaint` draws. A new look is new
  drawing code here. The ground is a list of `RingsGround` layers, each with how far it slides a ring, whether it
  stands in front of the suns, and for a floor its eye, repeat and stretch, so a look can add a layer without
  touching the engine. The covers are the promoted-purchase images cut to discs, in the asset catalog as
  `RingsCover-<pack>`; a pack without one draws a plain disc.
- **RingsView.swift** the engine: `RingsPlan` (where everything stands, from the screen's size and insets: a
  screen smaller than the mock's 440 by 956 draws the ring, sun and orbits in and leaves words and beads their
  size), `RingsPose`, `RingsView`.
- **RingsMenu.swift** `RingsFlag` and `RingsMenu`, the SwiftUI host: the view under a pack's card, the settings
  sheet and the consent question, each the old menu's own.
- **RingsTour.swift** the tour and the poses.

## Flags

All four are probes: a Debug build reads them, and a Release build only with `PROBES=YES`.

- `UNSTIR_MENU=rings` makes the rings the menu and stores it (`menu.rings`), so the phone's home screen keeps
  opening them; any other value clears it, as does a harnessed launch without the variable and the test host. It
  leaves the launch a plain one, as `UNSTIR_UNLOCK` does. `scripts/run-ios.sh` passes it on.
- `UNSTIR_RINGSTOUR=swipe|open|pick|speak|renew|rest` moves the menu with no finger, once a launch, three seconds after its art
  is in: `swipe` glides down through every ring and back by the scroll view's own animation; `open` taps the
  middle, so its level opens; `pick` names a bead and lets it go; `rest` waits six seconds. The flight log gets
  "tour swipe, ground drawn 0" as it starts, "tour ends, ground drawn 0" as it ends (the marks the trace readers in
  use already expect) and a line of `RingsCount`'s counts between them with the art's size. `swipe` also logs
  "tour glide 2→3 (vortex)" as each glide starts and "tour arrive 3 (vortex)" as UIKit reports it ended. The flight
  log's clock is the phone's, which can sit a second or more off the trace's: line the marks up by the first glide's
  frames.
- `UNSTIR_RINGSPOSE=ring:2`, `place:1.5` or `pick:9` holds a still for a shot, comma-separated in turn. It makes
  the launch a harnessed one. Rings count from the top: with the daily showing, 0 is the archive's, 1 to 4 the
  tiers and 5 endless's.
- `UNSTIR_CADEBUG=CA_COLOR_OFFSCREEN,CA_PRINT_OFFSCREENS` (any of Core Animation's `CA_COLOR_*` and `CA_PRINT_*`
  debug names) turns those options on in the render server as the tour or pose starts, as the Simulator's Debug
  menu would: offscreen layers tinted yellow in a shot, and each frame's offscreen passes printed in the
  simulator's log (`xcrun simctl spawn <sim> log show --last 20s | grep CADebug`). They hold for every app on that
  simulator until it shuts down, so use a simulator of your own.

`scripts/shots.sh rings-` shoots the cases in `scripts/shots/rings.sh`; `SHOTS_ENV="MUSIC=0 SOUNDS=0"` keeps the
one plain launch, `rings-fresh`, silent too.

A tour on the simulator, silent (`MUSIC=0` and `SOUNDS=0` make the launch a harnessed one, which is muted):

```
SIMCTL_CHILD_UNSTIR_MUSIC=0 SIMCTL_CHILD_UNSTIR_SOUNDS=0 SIMCTL_CHILD_UNSTIR_MENU=rings \
  SIMCTL_CHILD_UNSTIR_RINGSTOUR=swipe xcrun simctl launch --terminate-running-process <sim> com.screendead.Unstir
```

then `scripts/pull-log.sh --sim` and read the lines from "tour swipe" to the counts. On the phone,
`UNSTIR_MENU=rings UNSTIR_RINGSTOUR=swipe scripts/run-ios.sh Release` with `PROBES=YES`.

## Checked

On the simulator (iPhone 17 Pro Max, 2026-11-27), by real taps and swipes: the way's bead and the middle open the
level at once; another bead names it and a second tap plays it; the daily's star opens today's daily; a cover opens
its pack's card, whose "menu" comes back to the rings; the motes open settings; a finger's swipe brings the next
ring forward; back from a level lands on the rings. The archive's middle plays today's daily, a past day's bead
names it and a second tap plays it, and back from either lands on the archive's ring; endless's "continue" plays the
saved run on its tank and "new run" arms (logged "rings new run armed"); its second tap inside the two seconds was
not reached by the simulator's tool, whose taps land seconds apart, and rests on `ResetArm`, as the old row does. The shots match the mock but for what the mock's data differs in:
its Lens reads "owned ✓" and its Prism "2/3 free" where the app's covers say "new" until each card has opened once,
as the old dock's do (`Marks.line`).

## Accessibility

- **VoiceOver.** `RingsView` is a container of elements made only when VoiceOver asks (`speak`): the daily, the
  middle, each bead of the ring in front, endless's "New run", the covers and settings. The middle is adjustable: a
  swipe up or down brings the next ring or the one before at once and moves focus to its middle, which reads the
  ring's count and the level it plays. A bead opens at once under VoiceOver; naming it first is for the eye. The drawn
  lines' " · " is read as a pause. `UNSTIR_RINGSTOUR=speak` logs every element's label and value, steps once and logs
  them again.
- **Reduce Motion.** The rings only cross-fade: a ring keeps its size, the ground stands still (`apply`), and the
  setting is followed live.

- **Dynamic Type.** Up to xxxLarge the mock's sizes hold. At accessibility sizes the plan takes the mock's own layout
  for them (`launch-ax.png`): the ring 34 pt higher, the sun whole over a horizon 150 pt under its middle, without
  bands, the mountains low, the rings a swipe away unnamed and no play mark; the daily's words flat under its star;
  one line under each cover, its name and its news; the packs' line wrapped. Every word is the size the system gives
  its role at that setting (`RingsPlan.pt`: `UIFontMetrics` for title1, headline, footnote, subheadline, callout or
  caption1 from the mock's size), never smaller, and the middle's words are measured (`RingsPaint.measure`, line
  layout without drawing) and stacked centred on the sun, the count in its short form ("14/27 · 11 par"). At
  accessibility3, the mock's, it matches `launch-ax.png` (`rings-ax3`). Past it the menu's text stops growing
  (Jack, 2026-11-28: "Stop the menu's text growing past the third size"): `RingsPlan` takes accessibility4 and 5 as
  accessibility3, so `rings-ax5` draws as `rings-ax3`. Drawn at their own sizes they did not fit (the level's name
  ran past the sun, the covers' labels into the packs' line). An exception to "text never shrinks" for the rings
  alone: the settings sheet, the cards over the menu and the play screen still follow the setting.

## Step two, what is left

The list beside play on a wide window, where `RootView` keeps `MenuView`; the level
growing out of its bead, which the mock's film shows and this step replaces with the root's fade; First Stir's cover,
when it ships.
