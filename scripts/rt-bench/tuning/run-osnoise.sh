#!/bin/bash
#
# run-osnoise.sh
#
# Purpose:
# - Run `rtla osnoise` to capture OS-induced noise (scheduling/interrupts/etc.) impacting a chosen CPU.
#
# What it does / Outputs:
# - Executes `sudo rtla osnoise --duration <DUR> --cpu <CPU> --osnoise --period 1000 --quiet`
#   and writes output to `~/rt-bench/results/osnoise-<uname>-cpu<CPU>-<stamp>.txt`.
#
# Interpretation:
# - The `osnoise` mode of `rtla` reports events sized by duration and source; look for frequent or
#   large noise events that line up with latency spikes in `timerlat`/`cyclictest` results.
#
set -e

DUR=${1:-600}   # default: 10 minutes
CPU=${2:-0}     # default: run on CPU 0

OUT=~/rt-bench/results/osnoise-$(uname -r)-cpu${CPU}-$(date +"%Y%m%d-%H%M%S").txt

echo "Running rtla osnoise for $DUR seconds on CPU ${CPU}"
sudo rtla osnoise \
    --duration $DUR \
    --cpu $CPU \
    --osnoise \
    --period 1000 \
    --quiet \
    > "$OUT"

echo "Wrote $OUT"
