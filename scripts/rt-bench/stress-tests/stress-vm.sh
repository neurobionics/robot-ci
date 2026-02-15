#!/bin/bash
#
# stress-vm.sh
#
# Purpose:
# - Apply virtual memory and page-fault heavy workloads to stress the memory subsystem and MM.
#
# What it does:
# - Runs `stress-ng --page-in 4 --page-out 4 --mmap 4 --timeout <DUR>s --metrics-brief`.
#
# Interpretation:
# - Use to observe how heavy memory activity and page faults affect latency measurements; large
#   VM activity can trigger CPU or I/O contention that shows up as latency spikes.
#
set -e

DUR=${1:-120}

echo "Running VM/page-fault stress for $DUR seconds"
stress-ng --page-in 4 --page-out 4 --mmap 4 --timeout ${DUR}s --metrics-brief
