#!/bin/bash
#
# set-cpu-cstates.sh
#
# Purpose:
# - Attempt to restrict deep CPU C-states to reduce platform idle latency that can
#   contribute to long wakeup times on some systems.
#
# What it does:
# - Writes to kernel module parameters (if available) to set `max_cstate` values. This is
#   hardware and vendor dependent; commands are guarded with `|| true` so failures are non-fatal.
#
# Notes / Interpretation:
# - This script uses `sudo` to write to `/sys/module/*/parameters/max_cstate`. It may fail
#   silently on systems that do not expose these parameters or use different drivers.
# - After running, inspect `/sys/module/intel_idle/parameters/max_cstate` and
#   `/sys/module/processor/parameters/max_cstate` to verify the applied value.
# - Be cautious: forcing low C-states increases power consumption and heat.
#
echo 0 | sudo tee /sys/module/intel_idle/parameters/max_cstate >/dev/null || true
echo 1 | sudo tee /sys/module/processor/parameters/max_cstate >/dev/null || true
echo "Attempted to set max C-state; check /sys/module/*/parameters/max_cstate"
