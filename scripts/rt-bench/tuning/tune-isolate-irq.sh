#!/bin/bash
#
# tune-isolate-irq.sh
#
# Purpose:
# - Set `/proc/irq/*/smp_affinity` so interrupts are steered to a specific CPU or mask,
#   reducing interrupt interference on an isolated real-time CPU.
#
# What it does:
# - Accepts either a CPU number (e.g. `0`) or a hex mask (e.g. `1`) and writes the mask to
#   each `/proc/irq/*/smp_affinity` file using `sudo`.
#
# Notes / Interpretation:
# - If you pass a plain CPU number the script converts it to the appropriate hex mask.
# - Be cautious: changing IRQ affinity affects device handling and may reduce throughput or
#   tie interrupts to less optimal CPUs. Inspect `/proc/irq/*/smp_affinity` after running.
#
set -e
# usage: scripts/tune-isolate-irq.sh 0   => set all IRQ affinity to cpu0
if [ -z "$1" ]; then
  echo "usage: $0 <hex-mask-or-cpu-num>"
  echo "Example: $0 1   (cpu0 -> mask 1)"
  exit 1
fi
TARGET=$1
# if a simple CPU number, convert to hex mask
if [[ "$TARGET" =~ ^[0-9]+$ ]]; then
  mask=$(printf "%x" $((1 << TARGET)))
else
  mask="$TARGET"
fi

for irq in /proc/irq/*/smp_affinity ; do
  echo "$mask" | sudo tee $irq >/dev/null
done
echo "Set /proc/irq/*/smp_affinity -> $mask"
