#!/bin/bash
#
# stress-context.sh
#
# Purpose:
# - Run a context-switch heavy workload using `stress-ng` to exercise scheduler and context-switch code paths.
#
# What it does:
# - Runs `stress-ng --switch 4 --timeout <DUR>s --metrics-brief` and prints the tool summary.
#
# Interpretation:
# - Use these runs to evaluate the impact of heavy context switching on latency measurements. Compare
#   system behavior with and without this workload during `timerlat`/`cyclictest` runs.
#
set -e

DUR=${1:-120}

echo "Running context-switch stress for $DUR seconds"
stress-ng --switch 4 --timeout ${DUR}s --metrics-brief
