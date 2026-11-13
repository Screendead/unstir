# Copyright © 2026 Jack Lusher. All rights reserved.
# Play: plughole's levels, drags and counts, endless, the sandbox, result cards, the daily and openings. Sourced in order by scripts/shots.sh.
for picture in grid; do
  for d in 1 2 3 4 5; do
    stack=${depths[$((d - 1))]}
    shot "$picture-d$d" "$picture, depth-$d scramble $stack (rod:steps, 30 degrees per step, bottom first)." \
      PICTURE=$picture STACK="$stack"
  done
done
d2=${depths[1]}
shot grid-d2-right-half "grid depth 2 ($d2), mid-drag: top rod 2 turned back +2 of its 4 steps." STACK="$d2" LIVE=2:+2
shot grid-d2-right-almost "grid depth 2 ($d2), mid-drag: top rod 2 turned back +3.6 of 4 steps." STACK="$d2" LIVE=2:+3.6
shot grid-d2-probe "grid depth 2 ($d2), mid-drag: rod 2 turned +0.4 steps. A dim hairline, its start mark and a short trace: letting go here commits nothing." \
  STACK="$d2" LIVE=2:+0.4
shot grid-d2-wrong-rod "grid depth 2 ($d2), mid-drag: rod 1 turned -2.5 steps out of order (its undo is right, but only after rod 2)." \
  STACK="$d2" LIVE=1:-2.5
shot quad-probe "Level 12 (square), mid-drag: rod 1 turned +0.3 steps. A dim hairline, its start mark and a short trace: letting go here commits nothing." \
  LEVEL=12 LIVE=1:+0.3
shot quad-commit "Level 12 (square), mid-drag: rod 1 turned +2 steps. The hairline at full tone, two dashes: letting go here commits." LEVEL=12 LIVE=1:+2
# A drag's own count: a dash per step inside the disc's hairline from where the stir began, and the signed count off
# the finger. UNSTIR_TOUCH is where the finger went down (tank units), carried round by the turn; alone, a finger just
# down and not yet moved.
shot count-tri-plus3 "Level 01 (tri), finger down at the top of rod 0 and carried +3 steps round to its right: three dashes clockwise from the start mark, +3 to the left." \
  LEVEL=1 LIVE=0:+3 TOUCH=0,-0.8
shot count-quad-minus2 "Level 12 (square), finger down below rod 1 and carried -2 steps round: two dashes anticlockwise from the start mark, -2 up and left, off the finger." \
  LEVEL=12 LIVE=1:-2 TOUCH=0.354,0.7
shot count-let-go "Level 12 (square), rod 1 just let go at -2: its stir is still open, so the hairline, its dashes and the count stay, faint." LEVEL=12 TURNED=1:-2
shot count-regrab "Level 12 (square), rod 1 let go at -2, grabbed again and turned -1 more: the dashes and count carry on to -3 from where the stir began." \
  LEVEL=12 TURNED=1:-2 LIVE=1:-1 TOUCH=0.354,0.7
shot grab-grid "Level 12 (square), a finger just down deep in rod 0, not yet moved: its knob lit, its disc a dim hairline." LEVEL=12 TOUCH=0.4,-0.4
shot grab-overlap-grid "Level 12 (square), a finger just down where rods 0 and 1 overlap, nearer rod 0's centre: rod 0's knob lit and its disc a dim hairline at once, rod 1 not." \
  LEVEL=12 TOUCH=0.5,-0.03
# Each layout at its chapter's first and last level, the first two without a replay, then every level with a sunset or city.
for n in 01 04 07 08 09 13 14 18 19 22 23 27 05 11 15 06 10 16; do
  shot "level$n" "Level $n with its full scramble and its note." LEVEL=$n
done
# Mid-solve, where an inversion is on top: the top rod should not read from the still.
shot inversion-L12 "Level 12 part-solved: 0:-2 sits on 3:+7, quieter than the twist it covers." LEVEL=12 STACK=2:-3,0:+4,3:+7,0:-2
shot inversion-L27 "Level 27 part-solved at its first inversion: 4:-7 sits on 3:+7." LEVEL=27 STACK=2:+2,3:-5,1:+3,0:+6,3:+7,1:-3,4:-7
shot daily "Today's daily." MODE=daily
shot endless "Endless, first tank of the run seeded 7: the brim empty, its ticks engraved on the bare steel of the bezel, no glint or glow at six, the brim pin at twelve; the tank's number beside the title." \
  MODE=endless
# UNSTIR_BRIM sets the notches endless opens with, for that launch only. UNSTIR_CLOCK holds the brim that many seconds after
# its last change (the harness's TURNED), or after the launch where there is none.
shot endless-brim "Endless, first tank, opened with 5 of the brim's 8 notches: the picture's own colours in the bezel up to the fifth tick on both sides, glowing onto the black; the tank where moves and par were, no undo or reset." \
  MODE=endless BRIM=5
shot endless-brim-7 "Endless opened at 7 notches, one from spilling, held 0.38 s into the brim pin's pulse, at its peak: the filled arc's bloom at its strongest, fading out on the black." \
  MODE=endless BRIM=7 CLOCK=0.38
shot endless-notch "Endless opened at 4 notches, then rod 1 turned +1, a push: notch 5 arriving, held 0.2 s in, its colour spreading out across the bezel behind a glint." \
  MODE=endless BRIM=4 TURNED=1:1 CLOCK=0.2
shot endless-notch-surge "The same, 0.5 s in: the new arc filled, its light running on past the rim onto the black." \
  MODE=endless BRIM=4 TURNED=1:1 CLOCK=0.5
shot endless-heal "Endless opened at 5 notches, then rod 0 turned +3, which heals the tank's top stir: the level settling to the fourth tick, held 0.35 s in, a wet film where it stood." \
  MODE=endless BRIM=5 TURNED=0:3 CLOCK=0.35
shot endless-cleared "Endless, first tank opened at 5 notches and cleared by the harness after two wasted stirs (2 notches) and five heals: the card shows the brim at 2." \
  SCREEN=result MODE=endless BRIM=5
shot endless-spill-crest "Endless opened at 7 notches, then rod 1 turned +1, a push: the brim spills. Held 0.7 s in: the fronts have met at the brim pin, and a crest swells over the lip at twelve, the pin on top of it." \
  MODE=endless BRIM=7 TURNED=1:1 CLOCK=0.7
shot endless-spill-pour "The same, 1.1 s in: the crest has broken and the liquid pours down the outside of the rim either way, a wave behind a bead at each head; the picture starts to stir together." \
  MODE=endless BRIM=7 TURNED=1:1 CLOCK=1.1
shot endless-spill-drip "The same, 2 s in: the runs have slowed just past three and nine o'clock and a drop falls from each head onto the black." \
  MODE=endless BRIM=7 TURNED=1:1 CLOCK=2
shot endless-spilled "The same, 6 s in: the picture stirred together, its finest lines mixed rather than glittering, the caps still on it, the rim still brimful in its own colours, spilled. over the tank, and the card with tanks cleared and the best." \
  MODE=endless BRIM=7 TURNED=1:1 CLOCK=6
shot undo-refill "Level 12 opened on a new day with 6 undos banked: the bank refills to 8, and a +2 shows over the count, held 1 s after the opening (none here: a still launch)." \
  LEVEL=12 UNDOS=6 TODAY=2026-10-01 CLOCK=1
shot reset-armed "Level 12 with two moves played, reset tapped once: it reads reset? tap again." \
  LEVEL=12 PLAYED=0:+1,1:+1 RESETARMED=1
# UNSTIR_RESUME saves the level's try with that line for the launch: UNSTIR_MOVES's form, plus u an undo and r a reset.
shot level-resumed "Level 12 reopened mid-try, its saved line replayed (rod 2 healed, a wasted stir on rod 0 undone, rod 1 healed): four entries left, moves 2 / par 6, the undo already spent from the bank, and no opening." \
  LEVEL=12 UNDOS=9 RESUME=2:+5,0:+2,u,1:+3
shot menu-endless-continue "The menu with an endless run saved on tank 6, brim 3, best 9 tanks: the endless row reads continue · tank 6 · brim 3 · best 9, with new run on its title's line in place of the best." \
  BESTS=plughole:$par27,endless:9 MODE=endless SCREEN=menu RESUME= RESUMETANK=5 BRIM=3
shot sandbox "The sandbox as it opens: picture: grid and rods: 3 in the header, and the caption Stir anything. Undo is free here." \
  MODE=sandbox CLOCK=3
full=$(for i in $(seq 0 35); do printf '%d:+1,' $((i % 2)); done)
hold=2 shot sandbox-full "The sandbox with a full stack of 36, then rod 2 turned a step: the knob shakes, and the caption says the tank is full: undo or reset." \
  MODE=sandbox STACK=${full%,} MOVES=2:1
shot sandbox-chainmail "The sandbox on chainmail and pent: the header's controls in full where they fit." \
  MODE=sandbox PICTURE=chainmail LAYOUT=pent STACK= CLOCK=3
hold=9 shot knob-lesson "Level 01 left untouched 4 s (no opening: a still launch): the ghost finger halfway out knob 0's disc, held mid-rock." \
  LEVEL=1 CLOCK=0
shot result "Level 05 result card after a harness solve through the real commit path: two wasted stirs taken back, then the inverse word (+2 over par)." \
  SCREEN=result LEVEL=5
shot level-at-par "Level 11 after three heals, a partial and a push, the stack not empty: moves 5 / par 5 in amber." \
  LEVEL=11 PLAYED=2:-6,1:+4,3:+5,0:+1,1:+2
shot level-over-par "The same a push later: moves 6 / par 5 in magenta." LEVEL=11 PLAYED=2:-6,1:+4,3:+5,0:+1,1:+2,3:+2
shot result-veil "Level 11 solved in 9, four over par: the picture under the card veiled at 0.2, its most." \
  LEVEL=11 PLAYED=0:+1,2:-6,0:-1,3:+1,1:+4,3:+4,0:+1,2:+4,0:-5
shot result-clean "Level 06 (city) result card after a harness solve with nothing wasted on its first try: two marks and at par, as only the daily shows clean." SCREEN=clean LEVEL=6
shot result-replay "Level 06 (city) replayed at par with nothing wasted, started before (UNSTIR_TRIED) so no first try, no best saved yet: two marks and at par, the same as a first try." \
  SCREEN=clean LEVEL=6 TRIED=L6
shot result-again-best "Level 05 result card over par against a stored best of +6: the line new best, was +6, and again beside next." \
  SCREEN=result LEVEL=5 BESTS=plughole:00006
shot result-fullest "Plughole 27 replayed at +2 (two wasted stirs taken back, then the inverse word) against a stored best of +6, every other plughole level at par: the margin, the new best's line, again, and up a notch to WHIRLPOOL, the fullest card a tier level shows." \
  SCREEN=result LEVEL=27 BESTS=plughole:000000000000000000000000006 CLOCK=0
shot result-pack-complete "Lens 25 solved, Lens 01 to 24 solved before: Lens complete · 25 panels under the facts, and under it a quiet try Escapement (First Stir and Lens owned, so the first unowned pack on a Debug shelf is Escapement, as on Release's)." \
  PACK=lens LEVEL=25 SCREEN=clean OWNED=first-stir,lens BESTS=lens:000000000000000000000000- CLOCK=0
shot result-every-tier "Maelstrom 27 solved, every other free level at par: every tier unstirred under the facts, and a quiet try Lens (First Stir owned, as Release doesn't sell it)." \
  SCREEN=clean TIER=maelstrom LEVEL=27 OWNED=first-stir BESTS=plughole:000000000000000000000000000,whirlpool:000000000000000000000000000,vortex:000000000000000000000000000,maelstrom:00000000000000000000000000- CLOCK=0
shot result-ladder-end "Maelstrom 27 solved, the rest of the ladder short: no completion, and once, a quiet more puzzles in the packs, opening Lens's card (First Stir owned, as Release doesn't sell it)." \
  SCREEN=clean TIER=maelstrom LEVEL=27 OWNED=first-stir CLOCK=0
shot tier-up "Vortex 27 result card, maelstrom open: the card's one button, its whole width, up a notch to MAELSTROM in maelstrom's sweep, glowing." \
  SCREEN=clean TIER=vortex LEVEL=27 UNLOCK=1 CLOCK=0
shot tier-up-locked "The same with maelstrom still closed, no other vortex level solved (as levels open in order, plain play never reaches this): as bright, with a lock, saying how many vortex levels are unsolved; it opens the menu on maelstrom's gate." \
  SCREEN=clean TIER=vortex LEVEL=27 CLOCK=0
shot tier-up-midway "Plughole 05 solved at par, the last plughole level without a best: its card goes up a notch to WHIRLPOOL, though 05 is not the tier's last." \
  SCREEN=clean LEVEL=5 BESTS=plughole:0000-0000000000000000000000 CLOCK=0
shot tier-up-gate-landing "Where that button lands: the menu on maelstrom's gate, vortex 01 to 24 solved (04, 11 and 22 over par): 24 ticks lit, short: 25–27." \
  TIER=maelstrom BESTS=plughole:$par27,whirlpool:$par27,vortex:000100000010000000000200---
shot daily-result "Today's daily, result card after a harness solve: two wasted stirs taken back, then the inverse word; again and share, sharing the card's width, and next daily in 7 h under them (UNSTIR_NOW=17:00)." \
  SCREEN=result MODE=daily NOW=17:00
shot daily-clean "Today's daily solved at par on its first try with nothing wasted: three marks, clean, share and next daily in 7 h." \
  SCREEN=clean MODE=daily NOW=17:00
shot daily-practice "Today's daily solved at par as practice, as again on its card plays it (Jack's call P1 = B; UNSTIR_TRIED stands in for the first try): clean counts on the first try, no best line, again, share and next daily in 7 h." \
  SCREEN=clean MODE=daily NOW=17:00 TRIED=daily-$(date +%Y%m%d)
hold=8 shot daily-share-sheet "The same, with the system share sheet open on its share line (UNSTIR_SHARESHEET: the sheet its share button opens, opened without a tap)." \
  SCREEN=result MODE=daily SHARESHEET=1
hold=8 shot daily-share-supporter "The share sheet over the daily's card with a pack owned: the share line's name carries the supporter mark, Unstir 2026-11-02 ✦." \
  SCREEN=result MODE=daily SHARESHEET=1 OWNED=lens
for w in 0.4 0.8 1.2; do
  shot "wave-$w" "Level 13 solved through the real commit path, solve wave held at radius $w from the last-turned rod." LEVEL=13 WAVE=$w
done
hold=2 shot open-L03 "Level 03 about a second into its opening replay (clean picture first, then each twist plays forward)." LEVEL=3 OPEN=1
# From launch: the texture lands and ignites, 1 s of clean picture, then 1.4 s of wind-in.
i=0
for h in 0.9 1.6 2.0 3.2; do
  i=$((i + 1))
  hold=$h shot "open-L12-$i" "Level 12 opening, ${h}s after launch: clean picture, then every twist growing together." LEVEL=12 OPEN=1
done
