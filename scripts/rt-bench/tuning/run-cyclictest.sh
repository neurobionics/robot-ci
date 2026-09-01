#!/bin/bash
#
# run-cyclictest.sh
#
# Purpose:
# - Invoke `cyclictest` with sensible defaults and save its output under `~/rt-bench/results`.
#
# What it does / Outputs:
# - Runs `sudo cyclictest --mlockall --priority=95 --threads=<threads> --affinity=<cpu> --duration=<DUR>s --interval=1000`
#   and writes the output to `~/rt-bench/results/cyclictest-<uname>-t<threads>-cpu<cpu>-<stamp>.txt`.
#
# Interpretation:
# - `cyclictest` reports per-thread wakeup jitter (min/avg/max) and optionally histograms depending on build.
#   Use `max` and missed wakeups to assess whether the scheduler is delivering predictable wakeups for RT tasks.
#
set -e

DUR=${1:-600}
THREADS=${2:-1}
CPU=${3:-0}

OUT=~/rt-bench/results/cyclictest-$(uname -r)-t${THREADS}-cpu${CPU}-$(date +"%Y%m%d-%H%M%S").txt

echo "Running cyclictest for $DUR seconds on CPU $CPU with $THREADS thread(s)"
sudo cyclictest \
    --mlockall \
    --priority=95 \
    --threads=${THREADS} \
    --affinity=${CPU} \
    --duration=${DUR}s \
    --interval=1000 \
    > "$OUT"

echo "Wrote $OUT"
