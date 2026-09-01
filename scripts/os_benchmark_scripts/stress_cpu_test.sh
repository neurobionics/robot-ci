#!/usr/bin/env bash

# Context-switch focused OS behavior test using stress-ng
# - Drives context switching with the 'switch' stressor
# - Samples system-wide context switch rate from /proc/stat
# - Captures procs_running and procs_blocked as scheduling signals
# - Saves a time-series CSV and parses stress-ng metrics into a JSON summary

set -euo pipefail

# --- Config (env-overridable) ---
DURATION="${DURATION:-60}"           # seconds to run the stressor
WORKERS_DEFAULT=$(command -v nproc >/dev/null 2>&1 && nproc || echo 1)
# Accept WORKERS, or fall back to legacy CORES env for convenience
WORKERS="${WORKERS:-${CORES:-$WORKERS_DEFAULT}}"
SAMPLE="${SAMPLE:-1}"               # sampling interval in seconds
OUT_DIR="${OUT_DIR:-.}"

# --- Preconditions ---
if ! command -v stress-ng >/dev/null 2>&1; then
    echo "Error: stress-ng is not installed or not in PATH." >&2
    echo "On Debian/Ubuntu/Raspberry Pi OS: sudo apt-get update && sudo apt-get install -y stress-ng" >&2
    exit 127
fi

if ! [[ "$DURATION" =~ ^[0-9]+$ ]] || ! [[ "$WORKERS" =~ ^[0-9]+$ ]] || ! [[ "$SAMPLE" =~ ^[0-9]+$ ]]; then
    echo "Error: DURATION, WORKERS, and SAMPLE must be positive integers." >&2
    exit 2
fi

mkdir -p "$OUT_DIR"
START_TS_EPOCH=$(date +%s)
TS=$(date +%Y%m%d_%H%M%S)
CSV_FILE="$OUT_DIR/switch_ctx_${TS}.csv"
LOG_FILE="$OUT_DIR/switch_ctx_stressng_${TS}.log"
SUMMARY_FILE="$OUT_DIR/switch_ctx_summary_${TS}.json"

echo "Starting context-switch test: duration=${DURATION}s, workers=${WORKERS}, sample=${SAMPLE}s"

# --- CSV header ---
echo "timestamp,ctxt_per_s,procs_running,procs_blocked,ctxt_total,interval_s" > "$CSV_FILE"

# Helper: read total context switches from /proc/stat
get_ctxt_total() {
    awk '/^ctxt /{print $2}' /proc/stat
}

# Helper: read procs_running and procs_blocked from /proc/stat
get_procs_signals() {
    awk '/^procs_running /{pr=$2} /^procs_blocked /{pb=$2} END{print pr,pb}' /proc/stat
}

# Initialize sampling baselines
prev_ctxt=$(get_ctxt_total)
prev_ts=$(date +%s)

# --- Run stress-ng in the background with logging ---
# Using --log-file to reliably capture metrics-brief output in LOG_FILE
set +e
stress-ng \
    --switch "$WORKERS" \
    --timeout "$DURATION" \
    --metrics-brief \
    --times \
    --log-file "$LOG_FILE" &
PID=$!
set -e

# --- Sampling loop ---
sample_count=0
sum_rate=0
max_rate=0
max_procs_running=0
max_procs_blocked=0

while kill -0 "$PID" 2>/dev/null; do
    sleep "$SAMPLE"
    now_ts=$(date +%s)
    now_ctxt=$(get_ctxt_total)
    interval=$(( now_ts - prev_ts ))
    if (( interval <= 0 )); then
        continue
    fi
    delta=$(( now_ctxt - prev_ctxt ))
    # Compute per-second rate with two decimal precision
    rate=$(awk -v d="$delta" -v i="$interval" 'BEGIN{ if(i>0){ printf("%.2f", d/i) } else { printf("0.00") } }')
    read -r procs_running procs_blocked < <(get_procs_signals)

    # Append to CSV
    echo "${now_ts},${rate},${procs_running},${procs_blocked},${now_ctxt},${interval}" >> "$CSV_FILE"

    # Update accumulators
    sample_count=$(( sample_count + 1 ))
    # sum_rate as integer*100 to avoid floating math issues; scale by 100
    rate_int=$(awk -v r="$rate" 'BEGIN{ printf("%d", r*100) }')
    sum_rate=$(( sum_rate + rate_int ))

    # Track max rate (string compare is tricky; compare as integers with scale*100)
    if (( rate_int > max_rate )); then
        max_rate=$rate_int
    fi

    if (( procs_running > max_procs_running )); then
        max_procs_running=$(( procs_running ))
    fi
    if (( procs_blocked > max_procs_blocked )); then
        max_procs_blocked=$(( procs_blocked ))
    fi

    # Shift baseline
    prev_ctxt=$now_ctxt
    prev_ts=$now_ts
done

wait "$PID" || true
END_TS_EPOCH=$(date +%s)

# --- Parse stress-ng metrics from LOG_FILE ---
# Try to find the last data line for the 'switch' stressor. The fields typically are:
# stressor  bogo ops  real time  usr time  sys time  bogo ops/s
switch_line=$(grep -E "[[:space:]]switch[[:space:]]+[0-9]" "$LOG_FILE" | tail -n 1 || true)

bogo_ops=""
real_time_s=""
user_time_s=""
sys_time_s=""
bogo_ops_per_s=""

if [[ -n "$switch_line" ]]; then
    # Extract fields after the token 'switch'
    # This is robust to leading 'stress-ng: info: [pid]' prefixes
    read -r bogo_ops real_t user_t sys_t bos <<EOF
$(awk '{
    s=0; for(i=1;i<=NF;i++){ if($i=="switch"){ s=i; break } }
    if(s>0){
        # Handle both with and without trailing s in times (e.g., 10.00 or 10.00s)
        rt=$(s+1); gsub(/s$/,"",rt);
        ut=$(s+2); gsub(/s$/,"",ut);
        st=$(s+3); gsub(/s$/,"",st);
        bos=$(s+4);
        print $(s+1),rt,ut,st,bos;
    }
}' <<< "$switch_line")
EOF
    bogo_ops="$bogo_ops"
    real_time_s="$real_t"
    user_time_s="$user_t"
    sys_time_s="$sys_t"
    bogo_ops_per_s="$bos"
fi

# Compute averages
avg_rate="0.00"
max_rate_float="0.00"
if (( sample_count > 0 )); then
    avg_rate=$(awk -v s="$sum_rate" -v n="$sample_count" 'BEGIN{ printf("%.2f", (s/100)/n) }')
    max_rate_float=$(awk -v m="$max_rate" 'BEGIN{ printf("%.2f", m/100) }')
fi

# --- Summary JSON ---
uname_str=$(uname -a || true)
start_iso=$(date -u -d @${START_TS_EPOCH} +%Y-%m-%dT%H:%M:%SZ)
end_iso=$(date -u -d @${END_TS_EPOCH} +%Y-%m-%dT%H:%M:%SZ)

cat > "$SUMMARY_FILE" <<JSON
{
    "test": "context-switch",
    "start_time": "${start_iso}",
    "end_time": "${end_iso}",
    "duration_s": ${DURATION},
    "workers": ${WORKERS},
    "sample_interval_s": ${SAMPLE},
    "artifacts": {
        "time_series_csv": "${CSV_FILE}",
        "stressng_log": "${LOG_FILE}"
    },
    "system": {
        "uname": "${uname_str}" 
    },
    "stats": {
        "samples": ${sample_count},
        "avg_ctxt_per_s": ${avg_rate},
        "max_ctxt_per_s": ${max_rate_float},
        "max_procs_running": ${max_procs_running},
        "max_procs_blocked": ${max_procs_blocked}
    },
    "stress_ng": {
        "stressor": "switch",
        "bogo_ops": ${bogo_ops:-0},
        "bogo_ops_per_s": ${bogo_ops_per_s:-0},
        "real_time_s": ${real_time_s:-0},
        "user_time_s": ${user_time_s:-0},
        "sys_time_s": ${sys_time_s:-0}
    }
}
JSON

echo "Context-switch test complete."
echo "- CSV:     $CSV_FILE"
echo "- Log:     $LOG_FILE"
echo "- Summary: $SUMMARY_FILE"

