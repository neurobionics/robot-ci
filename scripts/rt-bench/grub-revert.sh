#!/bin/bash
#
# grub-revert.sh
#
# Purpose:
# - Restore a previously backed-up `/etc/default/grub` file. This is intended as a quick revert
#   after using `grub-set-cmdline.sh` which creates timestamped backups before updating GRUB_CMDLINE.
#
# What it does:
# - If `/etc/default/grub.bak` exists, copies it back to `/etc/default/grub` using `sudo`.
# - If no canonical backup exists, prints a message advising to inspect `/etc/default/` for other backups.
#
# Notes / Interpretation:
# - This script restores the saved config but does NOT run `update-grub` nor reboot the system. After restore,
#   run: `sudo update-grub` and reboot to apply kernel cmdline changes.
# - The script only looks for a single filename `/etc/default/grub.bak`. `grub-set-cmdline.sh` creates
#   timestamped backups at `/etc/default/grub.bak.<epoch>`, so you may need to choose the appropriate
#   timestamped backup manually if the simple `.bak` is not present.
# - Always inspect the backup being restored before rebooting to avoid accidental removal of required options.
#
set -e
if [ -f /etc/default/grub.bak ]; then
  sudo cp /etc/default/grub.bak /etc/default/grub
  echo "Restored /etc/default/grub from backup /etc/default/grub.bak"
else
  echo "No /etc/default/grub.bak found; check backups in /etc/default/"
fi
