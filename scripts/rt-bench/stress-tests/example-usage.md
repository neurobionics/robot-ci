✅ WHY stress-ng IS USEFUL FOR RT VS NON-RT COMPARISON

PREEMPT_RT’s benefits only appear under load — when interrupts, timers, memory allocs, syscalls, context switches, and page faults are happening.

The Red Hat tests exercise exactly those subsystems:

| Test                              | Kernel subsystem stressed                  | Why it matters for RT comparison                          |
| --------------------------------- | ------------------------------------------ | --------------------------------------------------------- |
| **29.2 − stress-ng cpu /cpu-ops** | Scheduler, CFS vs RT threaded IRQs         | Measures determinism under heavy compute                  |
| **29.3 − context-switch**         | Scheduler + RT priority inversion handling | Shows reduction of latency spikes in RT kernel            |
| **29.4 − interrupt / irq**        | IRQ handling, threaded interrupts          | RT kernel threads IRQs → should behave better             |
| **29.5 − scheduler / sch**        | Core scheduling loops                      | Detects jitter sources in non-RT kernels                  |
| **29.6 − fork / exec / clone**    | Process creation                           | Measures syscalls + memory allocation delays              |
| **29.8 − page-fault / vm**        | Memory subsystem latencies                 | RT kernel reduces long latencies via priority inheritance |


These stressors do not measure latency directly — but cause “bad conditions” while rtla, cyclictest, etc., record jitter.

So the right approach is:

Run stress-ng in background → run latency test → compare Ubuntu vs Ubuntu-RT.

./rt-under-stress.sh cpu
./rt-under-stress.sh irq
./rt-under-stress.sh vm 300

This script:

runs heavy stress on kernel subsystem X

simultaneously measures timer latency (best PREEMPT_RT metric)

logs results for side-by-side diffing

| Test           | Expected behavior: stock kernel                  | Expected behavior: RT kernel                       |
| -------------- | ------------------------------------------------ | -------------------------------------------------- |
| cpu            | High jitter due to long non-preemptible sections | **Much lower jitter** thanks to preemptible kernel |
| context-switch | Occasional 500–2000 µs spikes                    | **Stable, lower variance**                         |
| irq            | Large spikes from interrupt disabling            | **Smoother** because IRQs become threads           |
| sched          | CFS delays RT tasks under load                   | **Deterministic wakeup**                           |
| fork           | Kernel stalls during allocation                  | PREEMPT_RT handles it with bounded latency         |
| vm             | Long page faults                                 | Far fewer long sections                            |
