# Three Case Formal Report

- Date: 2026-06-14T08:08:25+00:00
- Scope: compact formal litmus tests for two public NutShell fixes plus one injected formal-advantage timing case.

| Case | Source | Expected | Actual | Verdict | Log |
| --- | --- | --- | --- | --- | --- |
| `pr21_prefetch_mmio_buggy` | PR #21 old behavior: MMIO prefetch flushes a normal L2/cache pipeline request | FAIL | FAIL | OK | `reports/formal_batch/logs/pr21_prefetch_mmio_buggy.log` |
| `pr21_prefetch_mmio_fixed` | PR #21 fixed behavior: MMIO prefetch is suppressed and does not flush the normal request | PASS | PASS | OK | `reports/formal_batch/logs/pr21_prefetch_mmio_fixed.log` |
| `pr74_cache_io_idbits_buggy` | PR #74 old behavior: CacheIO drops the nonzero OOO request id | FAIL | FAIL | OK | `reports/formal_batch/logs/pr74_cache_io_idbits_buggy.log` |
| `pr74_cache_io_idbits_fixed` | PR #74 fixed behavior: CacheIO preserves the request id | PASS | PASS | OK | `reports/formal_batch/logs/pr74_cache_io_idbits_fixed.log` |
| `flush_outstanding_miss_buggy` | Injected narrow timing bug: flush fabricates an early CPU response while a miss is outstanding | FAIL | FAIL | OK | `reports/formal_batch/logs/flush_outstanding_miss_buggy.log` |
| `flush_outstanding_miss_fixed` | Fixed behavior: CPU response is only allowed when the refill response arrives | PASS | PASS | OK | `reports/formal_batch/logs/flush_outstanding_miss_fixed.log` |

## Sources

- PR #21: https://github.com/OSCPU/NutShell/pull/21
- PR #21 merge commit: https://github.com/OSCPU/NutShell/commit/a3663f25183d6cbf89a088e3e8a365e2e6270366
- PR #74: https://github.com/OSCPU/NutShell/pull/74
- PR #74 fix commit: https://github.com/OSCPU/NutShell/commit/287c5e02490aca73055211bd04908917d71deaf7

## Interpretation

- Buggy variants are expected to FAIL; this means the property catches the intended bug condition.
- Fixed variants are expected to PASS; this means the same property does not flag the repaired behavior.
- The flush outstanding miss case is intentionally artificial and demonstrates a narrow timing window that formal can target directly.
