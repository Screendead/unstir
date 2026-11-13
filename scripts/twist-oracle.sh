#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# The twist oracle: what a faster way to draw twists is held against. Cases are in scripts/twist-oracle/cases.sh, the
# pass rule in scripts/twist-oracle.py (needs numpy and Pillow; films need ffmpeg).
#
#   scripts/twist-oracle.sh build              builds Debug for the simulator; every command below installs that build
#                                              on the oracle's own simulator and refuses if Sources/ has changed since
#   scripts/twist-oracle.sh ref [pattern]      shoots the reference frames into $ORACLE_REF: refused unless Sources/ is
#                                              committed and the same as $ORACLE_BASE's (origin/master's), the shader
#                                              as it ships
#   scripts/twist-oracle.sh shoot <set> [pattern]   shoots the same cases into shots/oracle/<set>
#   scripts/twist-oracle.sh diff <set> [pattern]    holds a set against the references by the pass rule; fails on a miss
#   scripts/twist-oracle.sh control [pattern]       the rule's measures on references blurred, shifted and dithered
#   scripts/twist-oracle.sh film <set> [pattern]    films the moving cases, cropped to the glass, into
#                                              shots/oracle/<set>/film (`film ref`: into $ORACLE_REF/film), each
#                                              beside the reference's take where there is one
#   scripts/twist-oracle.sh time [pattern]     times each case's frame off screen (OracleBench.swift), every method
#                                              in turn, ORACLE_RUNS launches (3), holding $ORACLE_LOCK through each
#                                              (shots/oracle/time: each run's lines, and the last's frames)
#   scripts/twist-oracle.sh benchdiff <method> holds a timed method's frames against today's by the same rule
#   scripts/twist-oracle.sh cases [pattern]    prints the timed cases as the bench takes them (scripts/gpu-bench.sh twists)
#   scripts/twist-oracle.sh clean              deletes the oracle's simulator
#
# ORACLE_SIM names the simulator; unset, one named for this checkout is made on the first call (a Pro Max) and found
# again after. ORACLE_REF is where the references live (shots/oracle/ref): a folder outside the checkout shares one
# set between checkouts. ORACLE_LOCK is the file every GPU timing on this Mac locks, so no two run at once; `time`
# refuses without it. ORACLE_EXTRA="TAPS=5" adds harness variables to every case of a shoot, for a set drawn worse on
# purpose (two taps), and to `time`'s launch. ORACLE_BASE is the commit whose Sources/ the references are shot from, origin/master unless set
# (a branch that adds a harness hold its cases need names itself, before it changes any drawing). The app's sound
# stays off: a harness launch is silent.
set -euo pipefail
cd "$(dirname "$0")/.."
bundle=com.screendead.Unstir
ref=${ORACLE_REF:-shots/oracle/ref}
name="twist-oracle $(basename "$PWD")"

sim() {
  udid=${ORACLE_SIM:-$(xcrun simctl list devices available | grep -F "$name (" | head -1 | grep -oE '[0-9A-F-]{36}' || true)}
  if [[ -z "$udid" ]]; then
    # The references' own device and runtime (scripts/twist-oracle/sim), so every checkout's frames are alike.
    read -r type runtime < scripts/twist-oracle/sim
    if ! xcrun simctl list runtimes available | grep -qF "$runtime"; then
      echo "no $runtime here: the newest iOS instead, whose frames may not match the references'" >&2
      runtime=$(xcrun simctl list runtimes available | grep '^iOS' | tail -1 | grep -oE 'com\.apple\S+$')
    fi
    udid=$(xcrun simctl create "$name" "$type" "$runtime")
  fi
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" -b >/dev/null
}

# Installs what `build` built, and refuses where Sources/ has changed since: a set shot from a stale app reads as
# whatever was installed last.
fresh() {
  local app=build/Build/Products/Debug-iphonesimulator/Unstir.app stale
  [[ -e build/.oracle-built && -d $app ]] || { echo "nothing built: scripts/twist-oracle.sh build first" >&2; exit 1; }
  stale=$(find Sources -newer build/.oracle-built -type f | head -3)
  [[ -z $stale ]] || { echo "Sources/ changed since the last build ($(echo $stale)): scripts/twist-oracle.sh build first" >&2; exit 1; }
  xcrun simctl install "$udid" "$app"
}

# Every case, as "kind|name|sweep|better|calm|seconds|vars".
list() {
  still() { local n=$1; shift; printf 'still|%s||%s|%s||%s\n' "$n" "${better:-}" "${calm:-}" "$*"; }
  sweep() {
    local n=$1 key=$2 v; shift 2
    local values=$1; shift
    for v in $values; do printf 'still|%s|%s||||%s\n' "$n@${v#*:}" "$n" "$* $key=$v"; done
  }
  film() { local n=$1 s=$2; shift 2; printf 'film|%s||||%s|%s\n' "$n" "$s" "$*"; }
  source scripts/twist-oracle/cases.sh
}

launch() {  # vars...
  local vars=() kv
  for kv in "$@" ${ORACLE_EXTRA:-}; do vars+=("SIMCTL_CHILD_UNSTIR_$kv"); done
  env "${vars[@]}" xcrun simctl launch --terminate-running-process "$udid" "$bundle" >/dev/null
}

# A Lens panel's bake, half a minute in Debug where Caches has none, marks its file as it lands or is read: waits
# for the launch just made to have its panel.
baked() {  # vars caches marker
  [[ " $1 " == *" PACK=lens "* || " $1 " == *" CARD=lens "* ]] || return 0
  for _ in $(seq 240); do
    [[ -n "$(find "$2" -name 'halftone-*' -size +1000k -newer "$3" 2>/dev/null)" ]] && break
    sleep 1
  done
}

calm() { xcrun simctl spawn "$udid" defaults write com.apple.Accessibility ReduceMotionEnabled -bool "$1"; }

shoot() {  # dir pattern
  local dir=$1 pattern=$2 kind n sweep better isCalm secs vars settle=6 caches launched tries a b
  sim
  fresh
  mkdir -p "$dir"
  xcrun simctl status_bar "$udid" override --time 9:41 --batteryState charged --batteryLevel 100 2>/dev/null || true
  caches="$(xcrun simctl get_app_container "$udid" "$bundle" data)/Library/Caches"
  launched="$dir/.launched" a="$dir/.a.png" b="$dir/.b.png"
  trap 'calm false' EXIT
  list | awk -F'|' '$1 == "still" { print $2 "\t" $3 "\t" $4 }' > "$dir/cases.tsv"
  while IFS='|' read -r kind n sweep better isCalm secs vars; do
    [[ $kind == still && $n == *$pattern* ]] || continue
    [[ -n $isCalm ]] && calm true
    touch "$launched"
    # shellcheck disable=SC2086
    launch $vars
    baked "$vars" "$caches" "$launched"
    sleep "$settle"
    settle=3
    # Held clocks draw one frame for good: the frame is taken once two shots 0.7 s apart are the same bytes.
    xcrun simctl io "$udid" screenshot "$a" >/dev/null 2>&1
    for tries in $(seq 20); do
      sleep 0.7
      xcrun simctl io "$udid" screenshot "$b" >/dev/null 2>&1
      cmp -s "$a" "$b" && break
      mv "$b" "$a"
    done
    (( tries < 20 )) || echo "$n never held still: a clock is running" >&2
    mv "$a" "$dir/$n.png"
    [[ -n $isCalm ]] && calm false
    echo "shot $n"
  done < <(list)
  xcrun simctl terminate "$udid" "$bundle" 2>/dev/null || true
  for f in "$a" "$b" "$launched"; do [[ -e $f ]] && trash "$f"; done
  return 0
}

films() {  # set pattern
  local dir="shots/oracle/$1/film" pattern=$2 kind n sweep better isCalm secs vars rec raw
  [[ $1 == ref ]] && dir="$ref/film"
  sim
  fresh
  mkdir -p "$dir"
  while IFS='|' read -r kind n sweep better isCalm secs vars; do
    [[ $kind == film && $n == *$pattern* ]] || continue
    # A launch first where the take would otherwise open on a panel still baking.
    if [[ " $vars " == *" PACK=lens "* || " $vars " == *" CARD=lens "* ]]; then
      touch "$dir/.launched"
      # shellcheck disable=SC2086
      launch $vars
      baked "$vars" "$(xcrun simctl get_app_container "$udid" "$bundle" data)/Library/Caches" "$dir/.launched"
      trash "$dir/.launched"
    fi
    xcrun simctl terminate "$udid" "$bundle" 2>/dev/null || true
    raw="$dir/$n-raw.mp4"
    xcrun simctl io "$udid" recordVideo --codec=h264 --force "$raw" >/dev/null 2>&1 &
    rec=$!
    sleep 1.5
    # shellcheck disable=SC2086
    launch $vars
    sleep "$secs"
    kill -INT "$rec"
    wait "$rec" || true
    # The glass and its bezel on the Pro Max's 1320 x 2868 screen. recordVideo gives two frames one time now and
    # then, after which the decoder times the take by its dts: read it with those ignored (scripts/film.sh).
    ffmpeg -loglevel error -y -fflags +igndts -i "$raw" -vf "fps=60,crop=1232:1232:44:812" -an -crf 16 "$dir/$n.mp4" < /dev/null
    trash "$raw"
    # Beside the reference's take, which never lines up to the frame: for the eye, not for a diff.
    if [[ $1 != ref && -e $ref/film/$n.mp4 ]]; then
      ffmpeg -loglevel error -y -i "$ref/film/$n.mp4" -i "$dir/$n.mp4" -filter_complex "[0:v][1:v]hstack" -an -crf 16 \
        "$dir/$n-beside-ref.mp4" < /dev/null
    fi
    echo "film $n"
  done < <(list)
  xcrun simctl terminate "$udid" "$bundle" 2>/dev/null || true
}

# The bench's cases, as UNSTIR_ORACLECASES takes them. A sweep is timed at its first value.
timed() {  # pattern
  local pattern=$1 cases="" kind n sweep better isCalm secs vars seen=""
  while IFS='|' read -r kind n sweep better isCalm secs vars; do
    # The glass alone: a frame with the chrome round it, the menu's or a card's times nothing more, and the bench
    # draws no wave.
    [[ $kind == still && $n == *$pattern* && -z $isCalm && " $vars " == *" CLEAN=1 "* && " $vars " != *" WAVE="* ]] || continue
    [[ -n $sweep && " $seen " == *" $sweep "* ]] && continue
    seen="$seen $sweep"
    cases="$cases${sweep:-$n}|$(for kv in $vars; do printf 'UNSTIR_%s ' "$kv"; done);"
  done < <(list)
  printf '%s' "$cases"
}

timing() {  # pattern
  local cases run out data f
  : "${ORACLE_LOCK:?set ORACLE_LOCK to the file every GPU timing on this Mac locks}"
  sim
  fresh
  cases=$(timed "$1")
  data=$(xcrun simctl get_app_container "$udid" "$bundle" data)
  out=shots/oracle/time
  mkdir -p "$out"
  # A shorter run's summary would otherwise read a longer one's leftover files too.
  for f in "$out"/run-*.txt; do [[ -e $f ]] && trash "$f"; done
  # ORACLE_EXTRA reaches the bench's launch as it does a shot's (UNSTIR_MAPLENS=1 for Lens's map, a probe the bench
  # reads from its own launch).
  local extra=()
  for f in ${ORACLE_EXTRA:-}; do extra+=("SIMCTL_CHILD_UNSTIR_$f"); done
  for run in $(seq "${ORACLE_RUNS:-3}"); do
    : > "$out/run-$run.txt"
    # The bench's lines reach the file as it quits. The lock is held from its launch until then.
    /usr/bin/lockf -k "$ORACLE_LOCK" env ${extra[@]+"${extra[@]}"} SIMCTL_CHILD_UNSTIR_GPUBENCH=oracle SIMCTL_CHILD_UNSTIR_ORACLECASES="$cases" \
      ${ORACLE_SIDE:+SIMCTL_CHILD_UNSTIR_ORACLESIDE="$ORACLE_SIDE"} \
      bash -c 'xcrun simctl launch --stdout="$2" --terminate-running-process "$0" "$1" > /dev/null
               for _ in $(seq 1200); do grep -qE "ORACLE (done|no Metal)" "$2" && break; sleep 0.5; done' \
      "$udid" "$bundle" "$PWD/$out/run-$run.txt"
    grep -q 'ORACLE done' "$out/run-$run.txt" || echo "run $run never finished" >&2
  done
  # Each method's frames, from the last run.
  for f in "$out"/frames; do [[ -e $f ]] && trash "$f"; done
  cp -R "$data/tmp/oracle" "$out/frames"
  python3 - "$out" <<'PY'
import re, sys, glob, statistics
runs = {}
for path in sorted(glob.glob(sys.argv[1] + "/run-*.txt")):
    for line in open(path):
        m = re.match(r"ORACLE (\S+) (\S+) frame ([\d.]+) ms \(([\d.]+) to ([\d.]+)\) x([\d.]+) of today, (.*)", line)
        if m:
            runs.setdefault((m[1], m[2]), []).append((float(m[3]), float(m[6]), m[7].strip()))
        elif "glass's fill" in line or "ORACLE done" in line or "ORACLE start" in line:
            print(line.strip())
print(f"{'case':16} {'method':10} {'ms a frame':>10}  {'runs':>24}  {'spread':>7}  {'of today':>8}")
for (case, method), r in runs.items():
    ms = [x[0] for x in r]
    mid = statistics.median(ms)
    print(f"{case:16} {method:10} {mid:10.3f}  {' '.join(f'{x:7.3f}' for x in ms):>24}  {100 * (max(ms) - min(ms)) / mid:6.1f}%  {statistics.median(x[1] for x in r):8.3f}  {r[0][2]}")
PY
}

case "${1:-}" in
  build)
    sim
    stamp=$(mktemp)
    out=$(scripts/build-ios.sh Debug sim) || true
    echo "$out"
    [[ $out == *"BUILD SUCCEEDED"* ]] || { trash "$stamp"; exit 1; }
    # Stamped from before the build began, so an edit made while it ran reads as newer.
    mv "$stamp" build/.oracle-built
    ;;
  ref)
    base=${ORACLE_BASE:-origin/master}
    want=$(git rev-parse "$base:Sources")
    if [[ "$(git rev-parse HEAD:Sources)" != "$want" || -n "$(git status --porcelain -- Sources)" ]]; then
      echo "Sources/ is not $base's: references are the shipping shader's, shot from a checkout of it" >&2
      exit 1
    fi
    mkdir -p "$ref"
    echo "$base $(git rev-parse --short "$base") Sources $want" > "$ref/base.txt"
    ORACLE_EXTRA="" shoot "$ref" "${2:-}"
    # Each reference's twins, the stir a tenth of a pixel along each axis, down both diagonals: what the rule lets a
    # frame differ by.
    ORACLE_EXTRA="NUDGE=0.1,0.1" shoot "$ref/twin" "${2:-}"
    ORACLE_EXTRA="NUDGE=0.1,-0.1" shoot "$ref/twin2" "${2:-}"
    ;;
  shoot) shoot "shots/oracle/${2:?a set name}" "${3:-}" ;;
  diff)
    [[ -e $ref/base.txt ]] && echo "references from $(cat "$ref/base.txt")"
    python3 scripts/twist-oracle.py diff "$ref" "shots/oracle/${2:?a set name}" "${3:-}"
    ;;
  control) python3 scripts/twist-oracle.py control "$ref" "${2:-}" ;;
  film) films "${2:?a set name}" "${3:-}" ;;
  time) timing "${2:-}" ;;
  cases) timed "${2:-}" ;;
  benchdiff)
    dir=shots/oracle/time/frames
    (cd "$dir/today" && ls *.png) | sed 's/\.png$//' | awk '{ print $0 "\t\t" }' > "$dir/today/cases.tsv"
    python3 scripts/twist-oracle.py diff "$dir/today" "$dir/${2:?a method name}"
    ;;
  clean)
    udid=${ORACLE_SIM:-$(xcrun simctl list devices | grep -F "$name (" | head -1 | grep -oE '[0-9A-F-]{36}' || true)}
    [[ -n "$udid" ]] && xcrun simctl delete "$udid"
    ;;
  *) sed -n '3,30p' "$0"; exit 2 ;;
esac
