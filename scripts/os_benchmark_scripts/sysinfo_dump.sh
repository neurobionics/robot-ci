#!/bin/bash
OUTFILE="sysinfo_dump_$(date +%Y%m%d_%H%M%S).log"

{
  echo "===== SYSTEM INFO ====="
  uname -a
  echo
  echo "===== CPU INFO ====="
  lscpu
  echo
  echo "===== MEMORY INFO ====="
  free -h
  echo
  echo "===== OS RELEASE ====="
  cat /etc/os-release
} > "$OUTFILE"

echo "System info saved to $OUTFILE"
