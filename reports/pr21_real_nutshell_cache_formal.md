# PR21 Real NutShell Cache Formal Report

- Date: 2026-06-16T13:10:19+00:00
- Scope: real NutShell Cache generated from PR #21 parent/fixed commits, with a formal wrapper probing the real s2->s3 cache pipeline.

| Case | Source | Expected | Actual | Verdict | Log |
| --- | --- | --- | --- | --- | --- |
| `pr21_real_nutshell_cache_pre` | NutShell parent bd425dee before PR #21 | FAIL | FAIL | OK | `reports/formal_batch/logs/pr21_real_nutshell_cache_pre.log` |
| `pr21_real_nutshell_cache_fixed` | NutShell PR branch f0d7c494 with PR #21 fix | PASS | PASS | OK | `reports/formal_batch/logs/pr21_real_nutshell_cache_fixed.log` |

## Sources

- PR #21 merge commit: https://github.com/OSCPU/NutShell/commit/a3663f25183d6cbf89a088e3e8a365e2e6270366
- Pre-PR parent: https://github.com/OSCPU/NutShell/commit/bd425deedff4e896fca59895b34d778f2c8724d9
- Fixed PR head: https://github.com/OSCPU/NutShell/commit/f0d7c49411197047dc8464addfacc0fcba5b9e45

## Interpretation

- The DUT is generated from the real NutShell `nutcore.Cache`, not from the earlier compact litmus.
- The wrapper only drives public cache IO and observes internal s2/s3 signals through Chisel `BoringUtils` probes inserted by `scripts/40_prepare_pr21_real_nutshell_cache.sh`.
- Expected split: pre-PR Cache FAIL, fixed Cache PASS.
