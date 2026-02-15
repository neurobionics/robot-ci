#!/bin/bash
#
# experiment-runner.sh
#
# Purpose:
# - Drive a sequence of latency/stress experiments across several kernel "variants":
#   * "stock"       : keep the current (stock) kernel configuration and run tests
#   * "rt-untuned" : boot the real-time (RT) kernel without additional tuning (user reboot required)
#   * "rt-basic"   : boot RT kernel and apply a set of basic runtime tunings
#   * "rt-aggressive": boot RT kernel and apply more aggressive tuning (user must set GRUB cmdline for isolcpus/nohz_full/rcu_nocbs)
#
# What it does:
# - Creates `~/rt-bench/results` and appends a run header to `experiment-log.txt`.
# - Iterates the variants above. For each variant it:
#   - Logs the variant name to `experiment-log.txt`.
#   - For tuning variants, calls helper scripts in `~/rt-bench/scripts/` to apply tunings.
#   - Launches three concurrent measurements for the specified duration:
#       1) `rtla timerlat` producing `timerlat-<variant>-<stamp>.txt`
#       2) `cyclictest` producing `cyclictest-<variant>-<stamp>.txt`
#       3) `stress-ng` producing `stressng-<variant>-<stamp>.txt`
#   - Waits for the three processes to complete before moving to the next variant.
# - For the `rt-untuned` variant the script exits and prompts the user to reboot into the RT kernel
#   so the remainder of variants can be run under the RT kernel.
#
# Output files (all saved under `~/rt-bench/results`):
# - `experiment-log.txt` : a running log of invocations and uname details.
# - `timerlat-<variant>-<stamp>.txt` : output from `rtla timerlat` (histograms, min/max/percentiles of timer latency).
# - `cyclictest-<variant>-<stamp>.txt` : output from `cyclictest` (per-thread latency stats: min/avg/max, missed wakeups, histograms depending on cyclictest build).
# - `stressng-<variant>-<stamp>.txt` : `stress-ng --metrics-brief` output (operation counts, failure counts, CPU/VM stress summaries).
#
# How to interpret outputs:
# - Primary comparison metric is worst-case (max) latency and high-percentile values (e.g., 99th/99.9th) in `timerlat` and `cyclictest`.
# - `rtla timerlat` focuses on timer interrupt/handler latency: look at the histogram, the maximum observed latency,
#   and the distribution (how many samples exceed thresholds of concern).
# - `cyclictest` measures thread wakeup/jitter: check `max` latency, `histogram` if present, and missed deadlines.
# - `stress-ng` shows the applied load and any failures; use it to confirm the system was stressed while measuring.
# - Use filenames and timestamps to align results across variants; compare `stock` vs `rt-*` outputs to evaluate improvements/regressions.
#
# Preconditions / Notes:
# - The script assumes `rtla`, `cyclictest`, and `stress-ng` are installed and available on the PATH, and that the user
#   has `sudo` privileges for operations that require it.
# - For `rt-untuned` the script will prompt for a reboot and exit; re-run this script after rebooting into the RT kernel
#   to continue with RT variants.
# - The `rt-aggressive` variant expects the user to have set GRUB kernel cmdline options for isolcpus/nohz_full/rcu_nocbs
#   prior to reboot; the script only applies runtime tweaks such as disabling timer migration and setting sched_rt_runtime.
#
set -e
OUTDIR=~/rt-bench/results
mkdir -p "$OUTDIR"
DUR=${1:-120}   # per-test duration
CPU_RT=${2:-2}  # CPU to pin RT test process

# helper to log uname
echo "=== Experiment run $(date) ===" | tee -a $OUTDIR/experiment-log.txt
uname -a | tee -a $OUTDIR/experiment-log.txt

# list of variants: "stock", "rt-untuned", "rt-basic", "rt-aggressive"
VARIANTS=("stock" "rt-untuned" "rt-basic" "rt-aggressive")

for V in "${VARIANTS[@]}"; do
  echo "==== Variant: $V ====" | tee -a $OUTDIR/experiment-log.txt
  if [ "$V" = "stock" ]; then
    echo "Assume currently running stock kernel; run tests now"
  elif [ "$V" = "rt-untuned" ]; then
    echo "Boot into RT kernel with default params and retest"
    # user must reboot into RT kernel before continuing
    echo "Please reboot into RT kernel now, then re-run this script for remaining variants."
    exit 0
  elif [ "$V" = "rt-basic" ]; then
    echo "Applying basic runtime tuning..."
    bash ~/rt-bench/tuning/tune-basic-runtime.sh $CPU_RT 0
    bash ~/rt-bench/tuning/tune-isolate-irq.sh 0
  elif [ "$V" = "rt-aggressive" ]; then
    echo "Applying aggressive tuning: ensure grub contains isolcpus/nohz_full/rcu_nocbs before boot"
    # Optionally remind user to set grub cmdline to include isolcpus,nohz_full,rcu_nocbs before reboot
    echo "Make sure you have rebooted with kernel cmdline including: isolcpus=${CPU_RT} nohz_full=${CPU_RT} rcu_nocbs=${CPU_RT}"
    sleep 2
    # apply other runtime adjustments:
    bash ~/rt-bench/scripts/set-cpu-cstates.sh || true
    sudo sysctl -w kernel.timer_migration=0 || true
    sudo sysctl -w kernel.sched_rt_runtime_us=-1 || true
  fi

  # run stress + latency tests
  stamp=$(date +%Y%m%d-%H%M%S)
  echo "Running rtla timerlat (duration ${DUR}) for $V"
  sudo rtla timerlat --duration $DUR --cpu $CPU_RT --period 1000 --quiet > $OUTDIR/timerlat-${V}-${stamp}.txt & pid_timer=$!

  echo "Run cyclictest for $V"
  sudo cyclictest --mlockall --smp --priority=95 --threads=1 --affinity=$CPU_RT --duration=${DUR}s --interval=1000 > $OUTDIR/cyclictest-${V}-${stamp}.txt & pid_cyc=$!

  # run a representative stress-ng load concurrently (cpu + irq + vm)
  echo "Starting combined stress-ng load"
  stress-ng --cpu 2 --matrix 1 --irq 2 --vm 1 --vm-bytes 256M --timeout ${DUR}s --metrics-brief > $OUTDIR/stressng-${V}-${stamp}.txt 2>&1 & pid_stress=$!

  # wait for tests
  wait $pid_timer $pid_cyc $pid_stress || true
  echo "Completed variant $V"
done

echo "All variants invoked or user-intervention required. Check $OUTDIR"
