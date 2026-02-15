#!/bin/bash
#
# stress-cpu.sh
#
# Purpose:
# - Run CPU-bound stress using `stress-ng` across all available CPUs.
#
# What it does:
# - Detects CPU count via `nproc` and runs `stress-ng --cpu <CPUS> --timeout <DUR>s --metrics-brief`.
#
# Interpretation:
# - Use to simulate heavy CPU load and measure how CPU saturation affects latency recordings from
#   `rtla` or `cyclictest` when run concurrently.
#
set -e

DUR=${1:-120}
CPUS=$(nproc)

echo "Running CPU stress for $DUR seconds on $CPUS CPUs"
stress-ng --cpu $CPUS --timeout ${DUR}s --metrics-brief
