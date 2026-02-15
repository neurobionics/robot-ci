#!/usr/bin/env bash
# Comprehensive memory stress test for OS comparison
# Combines: stress-ng VM stressor, kernel memory signals, bandwidth/latency, fragmentation/allocation

set -euo pipefail

# --- Config (env-overridable) ---
DURATION="${DURATION:-60}"
WORKERS_DEFAULT=$(command -v nproc >/dev/null 2>&1 && nproc || echo 1)
WORKERS="${WORKERS:-$WORKERS_DEFAULT}"
VM_BYTES="${VM_BYTES:-75%}"
VM_METHOD="${VM_METHOD:-all}"
SAMPLE="${SAMPLE:-1}"
OUT_DIR="${OUT_DIR:-.}"

# --- Preconditions ---
if ! command -v stress-ng >/dev/null 2>&1; then
    echo "Error: stress-ng is not installed or not in PATH." >&2
    exit 127
fi

mkdir -p "$OUT_DIR"
TS=$(date +%Y%m%d_%H%M%S)
CSV_FILE="$OUT_DIR/mem_stress_${TS}.csv"
LOG_FILE="$OUT_DIR/mem_stress_stressng_${TS}.log"
SUMMARY_FILE="$OUT_DIR/mem_stress_summary_${TS}.json"
BW_FILE="$OUT_DIR/mem_bandwidth_${TS}.csv"
FRAG_FILE="$OUT_DIR/mem_frag_${TS}.csv"

echo "Starting memory stress test: duration=${DURATION}s, workers=${WORKERS}, vm-bytes=${VM_BYTES}, vm-method=${VM_METHOD}, sample=${SAMPLE}s"

# --- CSV header ---
echo "timestamp,used_mem_mb,free_mem_mb,swap_used_mb,majflt,psimem_some,psimem_full,kswapd_steal,kswapd_inodesteal" > "$CSV_FILE"

# Helper: kernel memory signals
get_mem_stats() {
    local used free swap majflt psi_some psi_full kswapd_steal kswapd_inodesteal
    used=$(free -m | awk '/Mem:/ {print $3}')
    free=$(free -m | awk '/Mem:/ {print $4}')
    swap=$(free -m | awk '/Swap:/ {print $3}')
    majflt=$(awk '/^pgmajfault /{print $2}' /proc/vmstat)
    psi_some=$(awk '/some /{print $2}' /proc/pressure/memory 2>/dev/null || echo "N/A")
    psi_full=$(awk '/full /{print $2}' /proc/pressure/memory 2>/dev/null || echo "N/A")
    kswapd_steal=$(awk '/^pgsteal_kswapd /{print $2}' /proc/vmstat)
    kswapd_inodesteal=$(awk '/^pgsteal_kswapd_inodesteal /{print $2}' /proc/vmstat)
    echo "$used,$free,$swap,$majflt,$psi_some,$psi_full,$kswapd_steal,$kswapd_inodesteal"
}

# --- Run stress-ng VM stressor ---
set +e
stress-ng \
    --vm "$WORKERS" \
    --vm-bytes "$VM_BYTES" \
    --vm-method "$VM_METHOD" \
    --timeout "$DURATION" \
    --metrics-brief \
    --log-file "$LOG_FILE" &
PID=$!
set -e

# --- Sampling loop ---
prev_majflt=$(awk '/^pgmajfault /{print $2}' /proc/vmstat)
while kill -0 "$PID" 2>/dev/null; do
    sleep "$SAMPLE"
    now_ts=$(date +%s)
    stats=$(get_mem_stats)
    echo "$now_ts,$stats" >> "$CSV_FILE"
done
wait "$PID" || true

# --- Bandwidth/latency microbenchmark ---
echo "method,bandwidth_mb_s,latency_ns" > "$BW_FILE"
if command -v mbw >/dev/null 2>&1; then
    # mbw: memory bandwidth test (3 methods)
    for m in memcpy dumb memcpy2; do
        res=$(mbw -n 1 -t 1 -a | awk -v meth="$m" '/MiB\/s/ {print meth","$2","$4}')
        echo "$res" >> "$BW_FILE"
    done
fi
if command -v stream >/dev/null 2>&1; then
    # stream: memory bandwidth/latency test
    stream_out=$(stream 2>/dev/null | grep -E 'Copy|Scale|Add|Triad')
    while read -r line; do
        meth=$(echo "$line" | awk '{print $1}')
        bw=$(echo "$line" | awk '{print $2}')
        lat=$(echo "$line" | awk '{print $3}')
        echo "$meth,$bw,$lat" >> "$BW_FILE"
    done <<< "$stream_out"
fi

# --- Fragmentation/Allocation stress ---
echo "timestamp,failures,alloc_ops,free_ops" > "$FRAG_FILE"
frag_dur=10
frag_workers=2
frag_ts=$(date +%s)
set +e
frag_log=$(stress-ng --malloc "$frag_workers" --malloc-bytes 10% --malloc-method random --brk "$frag_workers" --timeout "$frag_dur" --metrics-brief 2>&1)
set -e
failures=$(echo "$frag_log" | awk '/fail/ {sum+=$NF} END{print sum+0}')
alloc_ops=$(echo "$frag_log" | awk '/malloc/ && /bogo ops/ {print $3}' | head -n1)
free_ops=$(echo "$frag_log" | awk '/free/ && /bogo ops/ {print $3}' | head -n1)
echo "$frag_ts,$failures,$alloc_ops,$free_ops" >> "$FRAG_FILE"

# --- Parse stress-ng metrics from LOG_FILE ---
if [[ ! -f "$LOG_FILE" ]]; then
    echo "Error: stress-ng log file $LOG_FILE not found. Skipping metrics parsing." >&2
    bogo_ops=0
    real_time_s=0
    user_time_s=0
    sys_time_s=0
    bogo_ops_per_s=0
else
    vm_line=$(grep -E "[[:space:]]vm[[:space:]]+[0-9]" "$LOG_FILE" | tail -n 1 || true)
    bogo_ops=""
    real_time_s=""
    user_time_s=""
    sys_time_s=""
    bogo_ops_per_s=""
    if [[ -n "$vm_line" ]]; then
        read -r bogo_ops real_t user_t sys_t bos <<EOF
$(awk '{
            s=0; for(i=1;i<=NF;i++){ if($i=="vm"){ s=i; break } }
            if(s>0){
                rt=$(s+1); gsub(/s$/,"",rt);
                ut=$(s+2); gsub(/s$/,"",ut);
                st=$(s+3); gsub(/s$/,"",st);
                bos=$(s+4);
                print $(s+1),rt,ut,st,bos;
            }
        }' <<< "$vm_line")
EOF
        bogo_ops="$bogo_ops"
        real_time_s="$real_t"
        user_time_s="$user_t"
        sys_time_s="$sys_t"
        bogo_ops_per_s="$bos"
    fi
fi

# --- Summary JSON ---
uname_str=$(uname -a || true)
start_iso=$(date -u -d @${frag_ts} +%Y-%m-%dT%H:%M:%SZ)
end_iso=$(date -u +%Y-%m-%dT%H:%M:%SZ)
cat > "$SUMMARY_FILE" <<JSON
{
    "test": "memory",
    "start_time": "${start_iso}",
    "end_time": "${end_iso}",
    "duration_s": ${DURATION},
    "workers": ${WORKERS},
    "vm_bytes": "${VM_BYTES}",
    "vm_method": "${VM_METHOD}",
    "sample_interval_s": ${SAMPLE},
    "artifacts": {
        "time_series_csv": "${CSV_FILE}",
        "stressng_log": "${LOG_FILE}",
        "bandwidth_csv": "${BW_FILE}",
        "frag_csv": "${FRAG_FILE}"
    },
    "system": {
        "uname": "${uname_str}"
    },
    "stats": {
        "vm_bogo_ops": ${bogo_ops:-0},
        "vm_bogo_ops_per_s": ${bogo_ops_per_s:-0},
        "real_time_s": ${real_time_s:-0},
        "user_time_s": ${user_time_s:-0},
        "sys_time_s": ${sys_time_s:-0}
    },
    "bandwidth": "${BW_FILE}",
    "fragmentation": {
        "failures": ${failures:-0},
        "alloc_ops": ${alloc_ops:-0},
        "free_ops": ${free_ops:-0}
    }
}
JSON

echo "Memory stress test complete."
echo "- CSV:     $CSV_FILE"
echo "- Log:     $LOG_FILE"
echo "- Bandwidth: $BW_FILE"
echo "- Fragmentation: $FRAG_FILE"
echo "- Summary: $SUMMARY_FILE"
