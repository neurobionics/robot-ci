#!/bin/bash
#
# stress-io.sh
#
# Purpose:
# - Stress block I/O submission and completion paths to provoke
#   I/O-driven softirq and block-layer latency.
#
# What it does:
# - Mixes synchronous and asynchronous I/O
# - Forces frequent I/O completion interrupts
# - Exercises writeback, journaling, and bio completion
#
# Interpretation:
# - Use concurrently with cyclictest (Profile 7) to expose
#   unbounded I/O completion latency on non-RT kernels.
#

set -e

DUR=${1:-120}

echo "Running block I/O stress for $DUR seconds"
stress-ng \
  --hdd 4 \
  --hdd-opts sync,fsync \
  --iomix 4 \
  --timeout ${DUR}s \
  --metrics-brief
