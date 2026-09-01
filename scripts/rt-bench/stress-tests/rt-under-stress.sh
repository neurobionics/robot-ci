#!/bin/bash
#
# rt-under-stress.sh
#
# Purpose:
# - Run a `stress-ng` workload of a chosen type while measuring timer latency with `rtla timerlat`.
#
# What it does:
# - Usage: `./rt-under-stress.sh <cpu|irq|sched|context|fork|vm> [duration] [cpu]`
# - Starts `stress-ng --<test> 4 --timeout <DUR>s --metrics-brief` in the background and then runs
#   `sudo rtla timerlat --cpu <CPU> --duration <DUR> --period 1000 --quiet` to capture latency while
#   the system is under the selected stress.
# - Writes `~/rt-bench/results/rtla-<test>-<uname>-<stamp>.txt` with the `rtla` output.
#
# Interpretation:
# - Use this script to reproduce how different stressors (CPU, IRQ, VM, fork, context switches, scheduler)
#   impact timer latency. Compare `rtla` results produced here with baseline `timerlat` runs without stress.
# - `stress-ng` output is printed to the terminal (or redirected by the caller); `rtla` output is saved to the log file.
#
set -e

TEST=$1
DUR=${2:-120}
CPU=${3:-0}

if [ -z "$TEST" ]; then
    echo "Usage: ./rt-under-stress.sh <cpu|irq|sched|context|fork|vm> [duration] [cpu]"
    exit 1
fi

LOG=~/rt-bench/results/rtla-${TEST}-$(uname -r)-$(date +"%Y%m%d-%H%M%S").txt

echo "Starting ${TEST} stress + rtla timerlat on CPU ${CPU} for ${DUR}s"

# start stress-ng in background
stress-ng --${TEST} 4 --timeout ${DUR}s --metrics-brief &
STRESS_PID=$!

# run latency detector
sudo rtla timerlat --cpu $CPU --duration $DUR --period 1000 --quiet > "$LOG"

wait $STRESS_PID
echo "Wrote $LOG"
