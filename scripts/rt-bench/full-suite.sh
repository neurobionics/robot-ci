#!/bin/bash
#
# full-suite.sh
#
# Purpose:
# - High-level wrapper to run a collection of system and latency tests that together form the
#   "full" benchmarking suite. Intended to be run on a single system/boot to capture a set
#   of baseline measurements.
#
# What it does:
# - Calls `scripts/system-info.sh` to capture machine details and kernel build/config.
# - Calls tuning/run-osnoise.sh to capture OS noise distribution (rtla osnoise).
# - Calls tuning/run-timerlat.sh to capture timer latencies (rtla timerlat).
# - Calls tuning/run-cyclictest.sh to capture cyclictest wakeup/jitter statistics.
# - Calls scripts/run-perf.sh to capture a short `perf stat` summary of system-wide events.
#
# Outputs (files written to `~/rt-bench/results` by the called scripts):
# - `system-info-<stamp>.txt` : `lscpu`, `uname -a`, running services, and extracts of `/proc/config.gz`.
# - `osnoise-<uname>-cpu<id>-<stamp>.txt` : rtla osnoise output (histograms, counts, max/min latencies).
# - `timerlat-<uname>-cpu<id>-<stamp>.txt` : rtla timerlat output.
# - `cyclictest-<uname>-t<threads>-cpu<id>-<stamp>.txt` : cyclictest output (min/avg/max/missed/histogram).
# - `perf-stat-<uname>-<stamp>.txt` : stderr from `perf stat` capturing system-wide counters over the sample duration.
#
# How to interpret outputs:
# - Use `system-info` to record the environment (kernel version, cpu topology, kernel config bits relevant to RT).
# - Compare `osnoise`, `timerlat`, and `cyclictest` outputs across kernels/boot configurations to look for reduced
#   worst-case latencies and narrower distributions under RT kernels/tuning.
# - `perf stat` can help identify whether interrupts, context switches, or other events correlate with observed latency spikes.
#
# Preconditions / Notes:
# - Many of the called tools require `sudo` and to be installed: `rtla`, `cyclictest`, `perf`, etc.
# - The script accepts optional arguments: CPU (default 0) and duration in seconds (default 600).
#
set -e

CPU=${1:-0}
DUR=${2:-600}

bash ~/rt-bench/scripts/system-info.sh
bash ~/rt-bench/scripts/run-osnoise.sh $DUR $CPU
bash ~/rt-bench/scripts/run-timerlat.sh $DUR $CPU
bash ~/rt-bench/scripts/run-cyclictest.sh $DUR 1 $CPU
bash ~/rt-bench/scripts/run-perf.sh 60
echo "Full suite completed."