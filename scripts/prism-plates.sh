#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/prism-plates.sh render <plate> <out.png> [side px] [layout]
#        scripts/prism-plates.sh check [plate...]
#        scripts/prism-plates.sh deal <plate> <layout> <masks> <scramble, or - for none> <out.png> [side px]
# Draws one of Prism's engravings (Engraving.swift) white on black on the Mac, with a layout's cores if given, or checks
# every plate against every layout: the share of each core lit, and the share of that light a 30° step moves. `deal`
# sketches a plate as the glass shows it under a stack and its masks, each channel through its own word.
set -euo pipefail
cd "$(dirname "$0")/.."
# PLATE_ONLY=<Name> (an Engraving<Name>.swift) builds that plate alone, every other one an empty stub, into its own
# folder, so one plate can be drawn while another is mid-edit.
out=build/prism-plates${PLATE_ONLY:+-$PLATE_ONLY}
mkdir -p "$out"
plates=(Sources/Engraving?*.swift)
if [[ -n "${PLATE_ONLY:-}" ]]; then
  plates=("Sources/Engraving$PLATE_ONLY.swift")
  for f in Sources/Engraving?*.swift; do
    n=$(basename "$f" .swift); n=${n#Engraving}
    [[ "$n" == "$PLATE_ONLY" ]] && continue
    printf 'enum %s { static let lines: [Engraving.Line] = [] }\n' "$n" > "$out/stub-$n.swift"
    plates+=("$out/stub-$n.swift")
  done
fi
if [[ ! -x "$out/plates" ]] || [[ -n "$(find Sources/Twist.swift Sources/Engraving*.swift scripts/prism-plates/main.swift -newer "$out/plates")" ]]; then
  awk '/^struct SplitMix64/,/^}/' Sources/Levels.swift > "$out/SplitMix64.swift"
  swiftc -O -o "$out/plates" Sources/Twist.swift Sources/Engraving.swift "${plates[@]}" "$out/SplitMix64.swift" scripts/prism-plates/main.swift
fi
"$out/plates" "$@"
