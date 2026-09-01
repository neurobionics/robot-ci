#!/bin/bash
#
# run-perf.sh
#
# Purpose:
# - Run a short `perf stat` across the whole system to capture high-level hardware/cpu
#   event rates that can help explain latency differences between kernels.
#
# What it does:
# - Runs `sudo perf stat -a sleep <duration>` and captures `perf` stderr to
#   `~/rt-bench/results/perf-stat-<uname>-<stamp>.txt` because `perf stat` prints
#   summary counters to stderr.
#
# Interpretation:
# - Typical counters of interest: context-switches, CPU cycles, instructions, cache-misses,
#   and interrupts. Use these to correlate heavy interrupt or context-switch activity with
#   measured latency spikes in `timerlat`/`cyclictest` outputs.
#
# Notes:
# - `perf` needs sufficient privileges; this script uses `sudo`.
# - Keep duration moderate (default 60s) to avoid very large outputs and to keep comparisons
#   consistent between runs.
#
set -e

DUR=${1:-60}  # perf can't run too long due to huge output

OUT=~/rt-bench/results/perf-stat-$(uname -r)-$(date +"%Y%m%d-%H%M%S").txt

echo "Running perf stat for $DUR seconds"
sudo perf stat -a sleep $DUR 2> "$OUT"

echo "Wrote $OUT"
