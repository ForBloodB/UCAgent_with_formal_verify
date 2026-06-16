# Directed Three Case Results

- Date: 2026-06-15T11:17:07+08:00
- Scope: hand-written dynamic ground-truth tests for buggy/fixed variants.

| Case | Variant | Expected | Actual | Verdict | Log |
| --- | --- | --- | --- | --- | --- |
| `pr21_prefetch_mmio` | `buggy` | FAIL | FAIL | OK | `reports/ucagent_logs/pr21_prefetch_mmio_buggy_directed.log` |
| `pr21_prefetch_mmio` | `fixed` | PASS | PASS | OK | `reports/ucagent_logs/pr21_prefetch_mmio_fixed_directed.log` |
| `pr74_cache_io_idbits` | `buggy` | FAIL | FAIL | OK | `reports/ucagent_logs/pr74_cache_io_idbits_buggy_directed.log` |
| `pr74_cache_io_idbits` | `fixed` | PASS | PASS | OK | `reports/ucagent_logs/pr74_cache_io_idbits_fixed_directed.log` |
| `flush_outstanding_miss` | `buggy` | FAIL | FAIL | OK | `reports/ucagent_logs/flush_outstanding_miss_buggy_directed.log` |
| `flush_outstanding_miss` | `fixed` | PASS | PASS | OK | `reports/ucagent_logs/flush_outstanding_miss_fixed_directed.log` |
