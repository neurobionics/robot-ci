#!/bin/bash
#
# stress-fork.sh
#
# Purpose:
# - Stress the system with heavy process creation/exit workload using `stress-ng`.
#
# What it does:
# - Runs `stress-ng --fork 8 --exec 8 --timeout <DUR>s --metrics-brief` and prints the summary.
#
# Interpretation:
# - Use to determine how frequent process creation and exec affects scheduling and latency.
#
set -e

DUR=${1:-120}

echo "Running fork/exec/clone stress for $DUR seconds"
stress-ng --fork 8 --exec 8 --timeout ${DUR}s --metrics-brief
