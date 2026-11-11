# Copyright © 2026 Jack Lusher. All rights reserved.
# Prism: specimens, swatches, letters and plates. Sourced in order by scripts/shots.sh.
# Prism's specimen 1: tri on the fern engraving, rod 0 red, rod 1 cyan and rod 2 white, dealt 2:+3,0:+4,1:-3. Each
# channel is sampled through its own entries, so a ghost's colour names the channels its stir moved.
hold=5 shot prism-dealt "Prism specimen 1 as dealt: red ghosts in the top core, cyan in the left, both over the white bottom stir's shear; the knobs tinted red, cyan and white." PACK=prism
hold=5 shot prism-solved "Prism specimen 1 drawn unstirred: the engraving in pure white lines, every channel in register." PACK=prism BARE=1
hold=5 shot prism-live "Prism specimen 1 held mid-drag, the cyan rod 1 turned back +1.5 of its 3: its green and blue ghosts swing towards the red." \
  PACK=prism LIVE=1:+1.5
hold=5 shot prism-mixed "Prism on tri, magenta, yellow and cyan rods, 0:+3,1:-2,2:+2: one channel left behind where each moved, red, green and blue ghosts and their pairs." \
  PACK=prism MASKS=0:m,1:y,2:c STACK=0:+3,1:-2,2:+2
hold=5 shot prism-hex "Prism on hex, every rod a different mask (white hub), 1:+3,4:-4,2:+2,5:-3: the fern's lines in every core." \
  PACK=prism LAYOUT=hex MASKS=1:r,2:g,3:b,4:c,5:m,6:y STACK=1:+3,4:-4,2:+2,5:-3
for n in $(seq 2 30); do
  hold=5 shot "prism-specimen-$n" "Prism specimen $n as dealt (docs/prism-design.md), on its tray's plate." PACK=prism LEVEL=$n OWNED=prism
done
for layout in quad eye pent hex; do
  hold=5 shot "prism-bare-$layout" "Prism's fern under $layout's knobs, unstirred: some line in every core." PACK=prism LAYOUT=$layout STACK=0:+1 BARE=1
done
# Colour-blind reading: each swatch held on specimen 8 (red, green and blue rods), its channel alone in its own colour,
# and in white under Differentiate Without Colour (set on the simulator, as the calm shots set Reduce Motion); and the
# knobs' letters, as Differentiate Without Colour shows them, on 8 and on 14 (the inks).
for c in r g b; do
  hold=5 shot "prism-swatch-$c" "Prism specimen 8 with the $c swatch held: that channel's lines alone, in its own colour, the others hidden." \
    PACK=prism LEVEL=8 OWNED=prism SWATCH=$c
done
# The setting is flipped only when a white swatch is taken, but `shot` runs either way, as it writes the index line.
plain() { xcrun simctl spawn "$udid" defaults write com.apple.Accessibility DifferentiateWithoutColor -bool "$1"; }
white=
[[ -z "$pattern" || prism-swatch-white-r == *$pattern* || prism-swatch-white-b == *$pattern* ]] && white=1
if [[ -n "$white" ]]; then
  trap 'plain false' EXIT
  plain true
fi
for c in r b; do
  hold=5 shot "prism-swatch-white-$c" "Prism specimen 8 with the $c swatch held under Differentiate Without Colour: that channel's lines alone in white, the knobs lettered." \
    PACK=prism LEVEL=8 OWNED=prism SWATCH=$c
done
if [[ -n "$white" ]]; then
  plain false
  trap - EXIT
fi
hold=5 shot prism-letters-8 "Prism specimen 8 with its knobs' channels spelt out (Differentiate Without Colour): R, G, B and RGB." \
  PACK=prism LEVEL=8 OWNED=prism LETTERS=1
hold=5 shot prism-letters-chosen "Prism 01 with colour letters switched on in settings, Differentiate Without Colour off: the letters under the knobs and the swatches." PACK=prism LEVEL=1 LETTERSCHOICE=1
hold=5 shot prism-letters-14 "Prism specimen 14 with its knobs' channels spelt out: the inks as GB, RB and RG." PACK=prism LEVEL=14 OWNED=prism LETTERS=1
for plate in seeds medusae radiolaria nautilus; do
  hold=5 shot "prism-plate-$plate" "Prism's $plate plate under pent's knobs, unstirred." PACK=prism LAYOUT=pent STACK=0:+1 PICTURE=$plate BARE=1
done
# The count aid, two ways (UNSTIR_PRISMAID), on Jellyfish (13: the cyan rod 1 dealt +5 under -5, its core clean, the
# first move +5) and Sea nettle (15: the magenta rod 2 dealt -3 under +5, its core showing 2, the first move -5), with
# today's beside them.
aid() {  # name-suffix description KEY=VALUE...
  local name=$1 desc=$2
  shift 2
  hold=5 shot "prism-aid-today-$name" "Today: $desc" PACK=prism OWNED=prism "$@"
  hold=5 shot "prism-aid-a-$name" "Aid a, the mark on the held rod's dial: $desc" PACK=prism OWNED=prism PRISMAID=a "$@"
  hold=5 shot "prism-aid-b-$name" "Aid b, pips round every knob: $desc" PACK=prism OWNED=prism PRISMAID=b "$@"
}
aid 13 "Jellyfish as dealt, at rest." LEVEL=13
aid 13-2 "Jellyfish, the cyan rod held at +2 of its 5." LEVEL=13 LIVE=1:+2
aid 13-5 "Jellyfish, the cyan rod held at +5, the count that lifts its newest stir." LEVEL=13 LIVE=1:+5
aid 13-blocked "Jellyfish, the magenta rod held at +2 while the cyan stir over it blocks it." LEVEL=13 LIVE=0:+2
hold=5 shot prism-aid-a2-13-blocked "Aid a marking blocked rods too: Jellyfish, the magenta rod held at +2, its mark at +4 though the cyan stir over it blocks it." \
  PACK=prism OWNED=prism PRISMAID=a2 LEVEL=13 LIVE=0:+2
aid 15 "Sea nettle as dealt, at rest." LEVEL=15
aid 15-2 "Sea nettle, the magenta rod held at -2 of its 5, where its core reads whole." LEVEL=15 LIVE=2:-2
aid 15-5 "Sea nettle, the magenta rod held at -5, the count that lifts its newest stir." LEVEL=15 LIVE=2:-5
