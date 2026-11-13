#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# What the main thread spends on a frame of a turn in hand, and of a live picture at rest (DragProbe.swift), and
# whether the play screen with a turn held draws the same pixels as another build's.
#
#   scripts/drag-probe.sh build                 builds Release for the simulator, the probes compiled in (PROBES=YES)
#   scripts/drag-probe.sh run [KEY=VALUE...]    each case's drags, as the harness's own state, a finger on a knob and
#                                               a finger on the rim, on the twist oracle's simulator, PROBE_RUNS
#                                               launches each (1), holding $ORACLE_LOCK through each; prints DragProbe's
#                                               lines and each window's median. Five drags a launch: a warm-up, then
#                                               as built, two with `LevelView` reading the turn as it used to
#                                               (UNSTIR_BROADDRAG=alt, the windows named broad) and as built again.
#                                               KEY=VALUE adds harness variables to every launch.
#   scripts/drag-probe.sh shots <set> [pattern] installs the oracle's Debug build and shoots the play screen whole,
#                                               held turns and their counts drawn, into shots/drag/<set>
#   scripts/drag-probe.sh same <a> <b>          compares two sets pixel for pixel, frame by frame, above the
#                                               home indicator, which fades on the system's own clock
#   scripts/drag-probe.sh film <set> [pattern]  films the play screen whole through drags, the opening and lines a
#                                               drawn fingertip plays, into shots/drag/<set>/film (needs ffmpeg)
#   scripts/drag-probe.sh beside <a> <b>        lays set a's films beside set b's, a on the left
#
# The simulator is the twist oracle's (scripts/twist-oracle.sh build makes it). PROBE_CASES picks the cases of `run`
# by a pattern. PROBE_APP names the Debug app `shots` and `film` install, and PROBE_RELEASE the Release app `run`
# does, for another checkout's build.
# The Mac's milliseconds are not a phone's: read the ratio between two builds, or a switch on and off.
set -euo pipefail
cd "$(dirname "$0")/.."
bundle=com.screendead.Unstir
name="twist-oracle $(basename "$PWD")"
debug=${PROBE_APP:-build/Build/Products/Debug-iphonesimulator/Unstir.app}
udid=${ORACLE_SIM:-$(xcrun simctl list devices available | grep -F "$name (" | head -1 | grep -oE '[0-9A-F-]{36}' || true)}

sim() {
  [[ -n $udid ]] || { echo "no simulator named $name: scripts/twist-oracle.sh build makes it" >&2; exit 1; }
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" -b >/dev/null
}

launch() {  # vars...
  local vars=() kv
  for kv in "$@"; do vars+=("SIMCTL_CHILD_UNSTIR_$kv"); done
  env "${vars[@]}" xcrun simctl launch --terminate-running-process "$udid" "$bundle" >/dev/null
}

# name|vars: a deep stack over a live picture, the deepest on the glass picture, a baked picture and Prism's masks.
cases() {
  cat <<'END'
m24|TIER=maelstrom LEVEL=24 TANKTURNED=1
w27|TIER=whirlpool LEVEL=27 TANKTURNED=1
p20|TIER=plughole LEVEL=20 TANKTURNED=1
prism-8|PACK=prism OWNED=prism LEVEL=8
frost|MODE=daily DAILY=20261102 TANKTURNED=1
END
}

case "${1:-}" in
  build) PROBES=YES scripts/build-ios.sh Release sim ;;
  run)
    shift
    : "${ORACLE_LOCK:?set ORACLE_LOCK to the file every GPU timing on this Mac locks}"
    sim
    xcrun simctl install "$udid" "${PROBE_RELEASE:-build/Build/Products/Release-iphonesimulator/Unstir.app}"
    log="$(xcrun simctl get_app_container "$udid" "$bundle" data)/Library/unstir-log.txt"
    out=shots/drag/run.txt
    mkdir -p shots/drag
    : > "$out"
    while IFS='|' read -r n vars; do
      [[ $n == *${PROBE_CASES:-}* ]] || continue
      for mode in state rod rim; do
        finger=()
        [[ $mode == state ]] || finger=("TAPFINGER=$mode")
        for _ in $(seq "${PROBE_RUNS:-1}"); do
          xcrun simctl terminate "$udid" "$bundle" 2>/dev/null || true
          : > "$log"
          # shellcheck disable=SC2086
          /usr/bin/lockf -k "$ORACLE_LOCK" bash -c '
            log=$1; shift
            "$@"
            for _ in $(seq 200); do grep -q "tapdrag done" "$log" 2>/dev/null && break; sleep 0.5; done' \
            _ "$log" env $(for kv in $vars DRAGCPU=1 TAPDRAG=5 BROADDRAG=alt "${finger[@]+"${finger[@]}"}" "$@"; do printf 'SIMCTL_CHILD_UNSTIR_%s ' "$kv"; done) \
            xcrun simctl launch --terminate-running-process "$udid" "$bundle" >/dev/null
          grep -q "tapdrag done" "$log" || echo "$n $mode never finished" >&2
          grep -E "touch .* at " "$log" | sed -E "s/^[^ ]+ [^ ]+ /$n $mode: /" | sort -u | tee -a "$out" || true
          grep dragcpu "$log" | sed -E "s/^[^ ]+ [^ ]+ dragcpu/$n $mode:/" | tee -a "$out" || true
        done
      done
    done < <(cases)
    xcrun simctl terminate "$udid" "$bundle" 2>/dev/null || true
    # Each window's median over its launches and drags.
    python3 - "$out" <<'PY'
import re, sys, statistics
rows = {}
for line in open(sys.argv[1]):
    m = re.match(r"(\S+) (\S+): (.+?): frames \d+, main ([\d.]+) ms, process ([\d.]+) ms, instructions ([\d.]+) M, a frame: level ([\d.]+), tank [\d.]+, timeline ([\d.]+), picture [\d.]+, shader ([\d.]+), leaf ([\d.]+)(?:, equal [\d.]+)?; glass jumps since the last line: turns ([\d.]+), tank ([\d.]+) rad; glass built unchanged ([\d.]+) a frame", line)
    if m:
        rows.setdefault((m[1], m[2], m[3]), []).append([float(x) for x in m.groups()[3:]])
print(f"{'case':8} {'drive':6} {'window':17} {'n':>2} {'instr M':>8} {'(low to high)':>15} {'main ms':>8} {'(low to high)':>13} {'LevelView':>9} {'timeline':>8} {'shader':>6} {'leaves':>6} {'most jump, rad: turns':>22} {'tank':>6} {'glass built unchanged':>21}")
for (case, mode, window), r in rows.items():
    work, main = [x[2] for x in r], [x[0] for x in r]
    med = [statistics.median(x[i] for x in r) for i in range(7)]
    print(f"{case:8} {mode:6} {window:17} {len(r):2} {med[2]:8.2f} {min(work):7.2f}-{max(work):<7.2f} {med[0]:8.3f} {min(main):6.3f}-{max(main):<6.3f} {med[3]:9.2f} {med[4]:8.2f} {med[5]:6.2f} {med[6]:6.2f} {max(x[7] for x in r):22.3f} {max(x[8] for x in r):6.3f} {max(x[9] for x in r):21.2f}")
PY
    ;;
  shots)
    dir="shots/drag/${2:?a set name}"
    sim
    xcrun simctl install "$udid" "$debug"
    mkdir -p "$dir"
    xcrun simctl status_bar "$udid" override --time 9:41 --batteryState charged --batteryLevel 100 2>/dev/null || true
    caches="$(xcrun simctl get_app_container "$udid" "$bundle" data)/Library/Caches"
    while IFS='|' read -r n vars; do
      [[ $n == *${3:-}* ]] || continue
      touch "$dir/.launched"
      # shellcheck disable=SC2086
      launch $vars
      # A Lens panel bakes for half a minute in Debug where Caches has none (scripts/twist-oracle.sh).
      if [[ " $vars " == *" PACK=lens "* ]]; then
        for _ in $(seq 60); do
          [[ -n "$(find "$caches" -name 'halftone-*' -size +1000k -newer "$dir/.launched" 2>/dev/null)" ]] && break
          sleep 1
        done
      fi
      sleep "${settle:-6}"
      settle=3
      xcrun simctl io "$udid" screenshot "$dir/.a.png" >/dev/null 2>&1
      for tries in $(seq 20); do
        sleep 0.7
        xcrun simctl io "$udid" screenshot "$dir/.b.png" >/dev/null 2>&1
        cmp -s "$dir/.a.png" "$dir/.b.png" && break
        mv "$dir/.b.png" "$dir/.a.png"
      done
      (( tries < 20 )) || echo "$n never held still" >&2
      mv "$dir/.a.png" "$dir/$n.png"
      for f in "$dir/.b.png" "$dir/.launched"; do [[ -e $f ]] && trash "$f"; done
      echo "shot $n"
    done <<'END'
m24-rest|TIER=maelstrom LEVEL=24 TANKTURNED=1 CLOCK=3
m24-rod|TIER=maelstrom LEVEL=24 TANKTURNED=1 CLOCK=3 LIVE=2:+1.40
m24-rod-back|TIER=maelstrom LEVEL=24 TANKTURNED=1 CLOCK=3 LIVE=0:-2.30
m24-rod-idle|TIER=maelstrom LEVEL=24 TANKTURNED=1 CLOCK=3 LIVE=2:+0.10
m24-rod-touch|TIER=maelstrom LEVEL=24 TANKTURNED=1 CLOCK=3 LIVE=2:+1.40 TOUCH=0.3,-0.1
m24-rim|TIER=maelstrom LEVEL=24 TANKTURNED=1 CLOCK=3 TANKLIVE=17.0
m24-rim-far|TIER=maelstrom LEVEL=24 TANKTURNED=1 CLOCK=3 TANKLIVE=95.0
m24-rim-touch|TIER=maelstrom LEVEL=24 TANKTURNED=1 CLOCK=3 TANKLIVE=95.0 TOUCH=0.7,-0.7
m24-moved|TIER=maelstrom LEVEL=24 TANKTURNED=1 CLOCK=3 MOVES=2:2,-1:1 PACE=0.3
w27-rod|TIER=whirlpool LEVEL=27 TANKTURNED=1 CLOCK=3 LIVE=1:-0.80
p20-rod|TIER=plughole LEVEL=20 CLOCK=3 LIVE=0:+0.50
v27-rod|TIER=vortex LEVEL=27 TANKTURNED=1 CLOCK=3 LIVE=0:+1.20
v27-swirl|TIER=vortex LEVEL=27 TANKTURNED=1 SWIRLED=1 CLOCK=3 LIVE=6:+0.70
lens-held|PACK=lens LEVEL=1 CLOCK=3 LIVE=0:+2.00
lens-out|PACK=lens LEVEL=1 CLOCK=3 LIVE=0:-1.50 TOUCH=0.3,0.2
esc-held|PACK=escapement LEVEL=2 CLOCK=3 LIVE=2:+1.30
prism-held|PACK=prism OWNED=prism LEVEL=8 CLOCK=3 LIVE=1:+1.50
frost-rim|MODE=daily DAILY=20261102 TANKTURNED=1 CLOCK=3 TANKLIVE=40.0
frost-rod|MODE=daily DAILY=20261102 TANKTURNED=1 CLOCK=3 LIVE=2:+1.40
END
    xcrun simctl terminate "$udid" "$bundle" 2>/dev/null || true
    ;;
  film)
    dir="shots/drag/${2:?a set name}/film"
    sim
    xcrun simctl install "$udid" "$debug"
    mkdir -p "$dir"
    caches="$(xcrun simctl get_app_container "$udid" "$bundle" data)/Library/Caches"
    while IFS='|' read -r n secs vars; do
      [[ $n == *${3:-}* ]] || continue
      # A launch first where the take would otherwise open on a panel still baking: an install can leave Caches
      # without this build's.
      if [[ " $vars " == *" PACK=lens "* ]]; then
        touch "$dir/.launched"
        # shellcheck disable=SC2086
        launch $vars
        for _ in $(seq 60); do
          [[ -n "$(find "$caches" -name 'halftone-*' -size +1000k -newer "$dir/.launched" 2>/dev/null)" ]] && break
          sleep 1
        done
        trash "$dir/.launched"
      fi
      xcrun simctl terminate "$udid" "$bundle" 2>/dev/null || true
      xcrun simctl io "$udid" recordVideo --codec=h264 --force "$dir/$n-raw.mp4" >/dev/null 2>&1 &
      rec=$!
      sleep 1.5
      # shellcheck disable=SC2086
      launch $vars
      sleep "$secs"
      kill -INT "$rec"
      wait "$rec" || true
      # The whole play screen at half size. recordVideo's doubled frames: scripts/film.sh.
      ffmpeg -loglevel error -y -fflags +igndts -i "$dir/$n-raw.mp4" -vf "fps=60,scale=660:-2" -an -crf 18 "$dir/$n.mp4" < /dev/null
      trash "$dir/$n-raw.mp4"
      echo "film $n"
    done <<'END'
drag-rod|14|TIER=maelstrom LEVEL=24 TANKTURNED=1 TAPDRAG=2 TAPFINGER=rod
drag-rim|14|TIER=maelstrom LEVEL=24 TANKTURNED=1 TAPDRAG=2 TAPFINGER=rim
drag-state|14|TIER=maelstrom LEVEL=24 TANKTURNED=1 TAPDRAG=2
open|8|TIER=maelstrom LEVEL=24 TANKTURNED=1 OPEN=1
replay|9|TIER=plughole LEVEL=3 OPEN=1
play|22|TIER=maelstrom LEVEL=24 TANKTURNED=1 MOVES=2:2,-1:1,5:-3,u,-1:-1 FINGER=1 REST=1
lens|16|PACK=lens LEVEL=1 MOVES=0:3,0:-5,0:2 FINGER=1 REST=1
esc|16|PACK=escapement LEVEL=2 MOVES=2:4,w,1:-3 FINGER=1 REST=1
prism|16|PACK=prism OWNED=prism LEVEL=8 MOVES=1:2,0:-3,u FINGER=1 REST=1
vortex|16|TIER=vortex LEVEL=27 TANKTURNED=1 SWIRLED=1 MOVES=6:1,0:-2,u FINGER=1 REST=1
END
    xcrun simctl terminate "$udid" "$bundle" 2>/dev/null || true
    ;;
  beside)
    a="shots/drag/${2:?a set name}/film" b="shots/drag/${3:?another set name}/film"
    for f in "$a"/*.mp4; do
      n=$(basename "$f")
      [[ $n == *-beside-* || ! -e "$b/$n" ]] && continue
      ffmpeg -loglevel error -y -i "$f" -i "$b/$n" -filter_complex "[0:v][1:v]hstack=shortest=1" -an -crf 18 "$b/${n%.mp4}-beside-$2.mp4" < /dev/null
      echo "beside $n"
    done
    ;;
  same)
    python3 - "shots/drag/${2:?a set name}" "shots/drag/${3:?another set name}" <<'PY'
import sys, glob, os
import numpy as np
from PIL import Image
a, b = sys.argv[1:]
miss = 0
for f in sorted(glob.glob(a + "/*.png")):
    n = os.path.basename(f)
    if not os.path.exists(b + "/" + n):
        print("absent", n); miss = 1; continue
    x, y = (np.asarray(Image.open(d + "/" + n).convert("RGB")).astype(int) for d in (a, b))
    foot = x.shape[0] - 70
    d = np.abs(x[:foot] - y[:foot]).max(axis=2) if x.shape == y.shape else None
    if d is not None and not d.any():
        print("same  ", n)
    else:
        miss = 1
        print("DIFFER", n, "sizes" if d is None else f"{int((d > 0).sum())} px, most {int(d.max())} levels, rows {np.nonzero(d.any(axis=1))[0][[0, -1]]}")
sys.exit(miss)
PY
    ;;
  *) sed -n '3,24p' "$0"; exit 2 ;;
esac
