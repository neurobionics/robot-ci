High-level plan / experiment design

Baseline (Stock Ubuntu)

Run the full test suite (cyclictest, rtla timerlat/osnoise, perf, stress-ng combos). Save logs.

Install/boot Ubuntu-RT kernel

pro attach <token> then pro enable realtime-kernel (or install appropriate packages) and reboot into RT kernel. Confirm uname -a.

RT, untuned

Run full test suite again (same conditions).

RT, basic tuning (Tuned A): CPU isolation, IRQ affinity, SCHED_FIFO for control process, disable cpufreq scaling, mlockall in test app. Re-run tests.

RT, aggressive tuning (Tuned B): add nohz_full, rcu_nocbs, disable C-states, set sched_rt_runtime_us=-1, set IRQ affinity script, pin housekeeping to core 0, real-time core(s) isolated 1..N. Re-run tests.

(Optional) Repeat with different hardware profiles (hyperthreading on/off, cpufreq governor different, different cores isolated).

Analyze: compute mean/median/p95/p99/max latencies, histogram, overlay kernel variants, correlate spikes with perf/counters.

All tests can and should be run on normal Ubuntu (step 1). The same harness works for stock and RT kernel — that’s how you compare.