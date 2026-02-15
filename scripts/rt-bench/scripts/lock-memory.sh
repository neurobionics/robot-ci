#!/bin/bash
#
# lock-memory.sh
#
# Purpose:
# - Increase the `RLIMIT_MEMLOCK` (memlock) limit for the current shell so real-time
#   processes can mlock() memory without being limited by the per-process memlock quota.
#
# What it does:
# - Runs `ulimit -l unlimited` for the current shell session and prints a message.
#
# Notes / Interpretation:
# - This change affects only the current shell/process tree. To make system-wide persistent
#   changes, edit `/etc/security/limits.conf` (or the appropriate PAM limits configuration)
#   for the user running real-time workloads.
# - After running this script, start your real-time process from the same shell so it inherits
#   the raised memlock limit.
#
ulimit -l unlimited
echo "Set memlock unlimited for this shell. To enforce globally, edit /etc/security/limits.conf"
