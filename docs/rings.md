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
- **Taps.** A tap on the middle, or on the bead it names, opens that level at once. A tap on any other bead names
  it in the middle, with its best and par and "tap again to play" (or what opens it, "solve 08 to open"), and a
  second tap, or one on the middle, plays it. A tap anywhere else lets it go. This is the mock's; Jack's earlier
  rule was that a tap on a level opens it at once, and the difference is his to settle.
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
  four points wide. The cross lines' strip is 2 points wide and 5200 long, stretched across the floor. On a Pro Max
  with every piece baked the art is about 25 MB (the tour's log line prints it).
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
  call `apply`. There is no display link of the menu's own and no SwiftUI animation.
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
  prints them over six seconds: all zero.
- **A named bead** bakes its three lines on a tap, off the main thread, and shows them as they land.

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

All three are probes: a Debug build reads them, and a Release build only with `PROBES=YES`.

- `UNSTIR_MENU=rings` makes the rings the menu and stores it (`menu.rings`), so the phone's home screen keeps
  opening them; any other value clears it, as does a harnessed launch without the variable and the test host. It
  leaves the launch a plain one, as `UNSTIR_UNLOCK` does. `scripts/run-ios.sh` passes it on.
- `UNSTIR_RINGSTOUR=swipe|open|pick|rest` moves the menu with no finger, once a launch, three seconds after its art
  is in: `swipe` glides down through every ring and back by the scroll view's own animation; `open` taps the
  middle, so its level opens; `pick` names a bead and lets it go; `rest` waits six seconds. The flight log gets
  "tour swipe, ground drawn 0" as it starts, "tour ends, ground drawn 0" as it ends (the marks the trace readers in
  use already expect) and a line of `RingsCount`'s counts between them with the art's size.
- `UNSTIR_RINGSPOSE=ring:2`, `place:1.5` or `pick:9` holds a still for a shot, comma-separated in turn. It makes
  the launch a harnessed one.

`scripts/shots.sh rings-` shoots the cases in `scripts/shots/rings.sh`.

## Step two

Left as seams, not built: the archive's ring above plughole and endless's below maelstrom (two more entries of
`RingsModel.rings`, each with its own stage); VoiceOver (the view has no accessibility elements yet); Dynamic Type
(every text piece carries its size, so the plan can hand larger ones); Reduce Motion; the list beside play on a
wide window, where `RootView` keeps `MenuView`; the level growing out of its bead, which the mock's film shows and
this step replaces with the root's fade; First Stir's cover, when it ships.
