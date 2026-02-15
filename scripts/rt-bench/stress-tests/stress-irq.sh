#!/bin/bash
#
# stress-irq.sh
#
# Purpose:
# - Generate interrupt-heavy workload using `stress-ng` to observe the effects on interrupt handling
#   and latency-sensitive workloads.
#
# What it does:
# - Runs `stress-ng --irq 4 --timeout <DUR>s --metrics-brief` and prints the brief metrics.
#
# Interpretation:
# - Observe whether increased interrupt activity correlates with increased timer/cyclic latency in
#   `rtla`/`cyclictest` outputs when run concurrently.
#
set -e

DUR=${1:-120}

echo "Running IRQ stress for $DUR seconds"
stress-ng --irq 4 --timeout ${DUR}s --metrics-brief
