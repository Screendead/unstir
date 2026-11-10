#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/layers-film.sh [pattern]   Films the packs' layers in play (scripts/film.sh layer-) with the game's
# sound: the Mac's output switched to BlackHole for the takes and back however they end (needs Homebrew's blackhole-2ch
# and switchaudio-osx), each take's sound recorded from it into shots/film/layer-*.mp4.
set -euo pipefail
cd "$(dirname "$0")/.."
output=$(SwitchAudioSource -c -t output)
trap 'SwitchAudioSource -t output -s "$output" >/dev/null' EXIT
SwitchAudioSource -t output -s "BlackHole 2ch" >/dev/null
FILM_SOUND=1 scripts/film.sh "${1:-layer-}"
