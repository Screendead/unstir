#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/strike.sh <film.mp4>   Prints the seconds into a scripts/film.sh take just before its picture strikes,
# past the home screen (bright) and the app's black, whose wait varies with what the launch compiles; prints nothing
# for a take where no picture struck.
set -euo pipefail
ffprobe -v error -f lavfi -i "movie=$1,signalstats" -show_entries frame=pts_time:frame_tags=lavfi.signalstats.YAVG \
  -of csv=p=0 | awk -F, '$2 >= 40 { lit = 1 } lit && $2 < 40 && dark == "" { dark = $1; floor = $2 }
    dark != "" && on == "" { if ($2 < floor) floor = $2; if ($1 > dark + 0.3 && $2 > floor + 0.6) on = $1 }
    END { if (on != "") print (on > 0.2 ? on - 0.2 : 0) }'
