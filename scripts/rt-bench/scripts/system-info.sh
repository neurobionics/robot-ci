#!/bin/bash
#
# system-info.sh
#
# Purpose:
# - Collect reproducible system information useful when comparing kernel/RT profiles.
#
# What it does / Outputs:
# - Writes `~/rt-bench/results/system-info-<stamp>.txt` containing:
#   - `uname -a` (kernel/version/host)
#   - `lscpu` (CPU topology and features)
#   - Extracts relevant kernel config lines from `/proc/config.gz` (searching for PREEMPT/HZ/IRQ/NO_HZ)
#   - `systemctl list-units --type=service --state=running` to record running services which
#     may influence latency (daemons, power managers, etc.).
#
# Interpretation:
# - Use this file as a baseline metadata capture for any experiment run. It helps correlate
#   latency regressions/improvements with kernel config, CPU topology, and running services.
#
set -e

OUT=~/rt-bench/results/system-info-$(date +"%Y%m%d-%H%M%S").txt

{
    echo "===== SYSTEM INFO ====="
    uname -a
    echo

    echo "===== CPU INFO ====="
    lscpu
    echo

    echo "===== Kernel Config (relevant RT flags) ====="
    zgrep -E "PREEMPT|HZ_|IRQ|NO_HZ" /proc/config.gz
    echo

    echo "===== Running Services ====="
    systemctl list-units --type=service --state=running
    echo
} > "$OUT"

echo "Wrote $OUT"
