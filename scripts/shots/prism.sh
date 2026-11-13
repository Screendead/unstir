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
# Reading the picture while a rod turns: each move's rod held at rest, short of its count, on it and past it, so the
# frame on the count can be set beside its neighbours (PrismTests measures the same holds' white share).
reads() {  # name level played rod count description
  local name=$1 level=$2 played=$3 rod=$4 count=$5 desc=$6 x
  for x in 0 -1 -0.5 +0 +0.5 +1; do
    local at=0 tag=rest
    if [[ $x != 0 ]]; then
      at=$(awk -v c="$count" -v x="$x" 'BEGIN { s = c < 0 ? -1 : 1; printf "%+.1f", c + s * x }')
      case $x in -1) tag=short10;; -0.5) tag=short5;; +0) tag=on;; +0.5) tag=past5;; +1) tag=past10;; esac
    fi
    hold=4 shot "prism-read-$name-$tag" "Prism's read: $desc, held at $at of $count." PACK=prism OWNED=prism \
      LEVEL=$level ${played:+PLAYED=$played} LIVE=$rod:$at
  done
}
reads 01-cyan 1 "" 1 +3 "Frond's cyan rod, its first move"
reads 01-red 1 1:+3 0 -4 "Frond's red rod, its second move"
reads 08-blue 8 2:+2,4:+4 0 -4 "Thistle's blue rod, its third move"
reads 14-yellow 14 2:+2 3 +4 "specimen 14's yellow rod, its second move"
reads 30-yellow 30 0:+2,1:-2,4:-2 0 -3 "the last specimen's yellow rod, its fourth move"
reads 15-magenta 15 "" 2 -5 "Sea nettle's magenta rod, stirred twice, its first move"
