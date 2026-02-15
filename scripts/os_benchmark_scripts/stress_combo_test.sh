#!/bin/bash
OUTFILE="stress_combo_$(date +%Y%m%d_%H%M%S).csv"
DURATION=60

echo "timestamp,cpu_load,temp_c,used_mem_mb" > "$OUTFILE"

stress-ng --cpu 2 --io 1 --vm 1 --timeout "$DURATION" &

PID=$!

while kill -0 $PID 2>/dev/null; do
    LOAD=$(awk '{print $1}' /proc/loadavg)
    TEMP=$(vcgencmd measure_temp 2>/dev/null | grep -oP '[0-9.]+')
    USED=$(free -m | awk '/Mem:/ {print $3}')
    echo "$(date +%s),$LOAD,${TEMP:-N/A},$USED" >> "$OUTFILE"
    sleep 2
done

echo "Combined stress test complete. Data saved to $OUTFILE"
