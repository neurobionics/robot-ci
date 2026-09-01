#!/bin/bash
# usage: scripts/grub-set-cmdline.sh "isolcpus=2 nohz_full=2 rcu_nocbs=2"
#
# grub-set-cmdline.sh
#
# Purpose:
# - Append kernel command-line options to `/etc/default/grub` by updating the
#   `GRUB_CMDLINE_LINUX_DEFAULT` variable. The script creates a timestamped backup
#   of the current `/etc/default/grub` before editing.
#
# What it does:
# - Validates that a quoted string of cmdline options is provided as the first argument.
# - Copies `/etc/default/grub` to `/etc/default/grub.bak.<epoch>`.
# - Appends the given options into the `GRUB_CMDLINE_LINUX_DEFAULT` value using `sed`.
# - Prints a reminder to run `sudo update-grub` and reboot to apply the new cmdline options.
#
# Notes / Caution:
# - The script does a simple append and does not check for duplicate options. If you run it multiple
#   times with the same token the option may be duplicated in the grub config. Inspect `/etc/default/grub`
#   after running and before `update-grub`.
# - Common options used for RT tuning include `isolcpus=<cpu>`, `nohz_full=<cpu>`, and `rcu_nocbs=<cpu>`;
#   these must be applied prior to reboot for certain aggressive RT configurations to take effect.
#
set -e
if [ -z "$1" ]; then
  echo "usage: $0 \"<cmdline-options>\""
  exit 1
fi
sudo cp /etc/default/grub /etc/default/grub.bak.$(date +%s)
# append to GRUB_CMDLINE_LINUX_DEFAULT if not present
sudo sed -i -E "s|^GRUB_CMDLINE_LINUX_DEFAULT=\"(.*)\"|GRUB_CMDLINE_LINUX_DEFAULT=\"\1 $1\"|" /etc/default/grub
echo "Updated /etc/default/grub; run sudo update-grub and reboot"
