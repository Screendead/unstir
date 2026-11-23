# Design pass: room to breathe

Mock-ups for the chrome design pass (Jack's direction, 2026-11-23): the chrome round the tank is too busy; it should
be airy, spacious and gently animated, in the tank's theme. Nothing here changes the app. The glass is never redrawn:
every tank, cover and clip is a crop of a real screenshot (`before.sh`).

## Directions

Each is a small design system, shown on the same six screens: the menu, plughole 01 in play, plughole 27's result,
Prism 01 in play, Prism's pack card and settings. They differ in how they make room and in how they move, not in
palette.

- **A. Subtract.** Today's look kept whole: SF Mono, the neon sweeps, the hue walk of level numbers. Room comes from
  removal and spacing only: one line a row, detail only where the player is about to act, no capsules or rules, wider
  gutters. Motion as today. The cheap anchor.
- **B. Still water.** One thing in focus at a time; the rest recedes. Titles in SF Pro (proportional), numbers and
  counts in SF Mono. The row the player is about to play is large and carries its detail; others are one quiet line.
  Colour leaves the text and pools as soft light behind the focus, in the tier's sweep. Everything arrives by
  settling: a slow rise with a damped stop, like sediment. The result's three dots fill one by one like drops.
- **C. Mist.** All chrome in white SF Mono, no per-element colour, no capsules, no rules: grouping by space alone.
  The tier's sweep becomes a large, blurred light that drifts slowly behind the screen's top and blooms once when a
  tank is solved. Prism's mist is red, green and blue lobes meeting in white.

The two calls this pass owns are drawn in each: the result marks (decided as dots, one to three filled: solved, at
par, clean) and Prism's level colour (white today, since colour on Prism means a channel).

## Files

- `before.sh` shoots the before screens on a simulator into `build/negative-space/before/`.
- `crop.py` cuts the glass, covers and status bar out of those shots into `build/negative-space/glass/`.
- `mock.html`, `mock.css`, `mock.js` draw any screen in any direction: `mock.html?d=b&s=menu` (`rm=1` for Reduce
  Motion, `ax=1` for accessibility type).
- `render.mjs` drives one headless Chrome over the DevTools protocol: stills at 3x, Reduce Motion stills and films
  with every animation stepped by time, into `build/negative-space/`.
