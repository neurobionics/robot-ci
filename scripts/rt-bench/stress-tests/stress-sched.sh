#!/bin/bash
#
# stress-sched.sh
#
# Purpose:
# - Exercise the scheduler to generate load that may reveal scheduling-related latency issues.
#
# What it does:
# - Runs `stress-ng --sched 4 --timeout <DUR>s --metrics-brief` and prints a brief summary.
#
# Interpretation:
# - Use to evaluate scheduler-induced latency. Compare results with isolated CPU configurations
#   to see how scheduler contention affects RT measurements.
#
set -e

DUR=${1:-120}

echo "Running scheduler stress for $DUR seconds"
stress-ng --sched 4 --timeout ${DUR}s --metrics-brief
