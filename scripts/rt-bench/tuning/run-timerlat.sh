#!/bin/bash
#
# run-timerlat.sh
#
# Purpose:
# - Wrapper around `rtla timerlat` to run timer latency measurements and save output
#   to the `~/rt-bench/results` directory with an informative filename.
#
# What it does / Outputs:
# - Invokes `sudo rtla timerlat --duration <DUR> --cpu <CPU> --period 1000 --quiet` and writes
#   the tool output to `~/rt-bench/results/timerlat-<uname>-cpu<CPU>-<stamp>.txt`.
#
# Interpretation:
# - `rtla timerlat` reports timer interrupt handling latency (histogram, min/max/percentiles).
#   Look at max and high-percentile buckets to evaluate worst-case timer behavior.
#
set -e

DUR=${1:-600}
CPU=${2:-0}

OUT=~/rt-bench/results/timerlat-$(uname -r)-cpu${CPU}-$(date +"%Y%m%d-%H%M%S").txt

echo "Running rtla timerlat for $DUR seconds on CPU ${CPU}"
sudo rtla timerlat \
    --duration $DUR \
    --cpu $CPU \
    --period 1000 \
    --quiet \
    > "$OUT"

echo "Wrote $OUT"
