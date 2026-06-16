# PR74 Real NutShell CacheIO Formal Report

- Date: 2026-06-16T13:55:59+00:00
- Scope: real NutShell Cache generated from PR #74 parent/fixed commits.
- Property: an OOO-style Cache configuration with `idBits=4` must expose request/response ID fields at `CacheIO.in` and preserve the accepted ID on response.

| Case | Source | Expected | Actual | Verdict | Log |
| --- | --- | --- | --- | --- | --- |
| `pr74_real_nutshell_cache_pre_generate` | NutShell parent 4b656f32 before PR #74 | ELAB_FAIL | ELAB_FAIL | OK | `reports/formal_batch/logs/pr74_real_nutshell_cache_pre_generate.log` |
| `pr74_real_nutshell_cache_fixed_generate` | NutShell PR head 287c5e02 with PR #74 fix | PASS | PASS | OK | `reports/formal_batch/logs/pr74_real_nutshell_cache_fixed_generate.log` |
| `pr74_real_nutshell_cache_fixed_formal` | Fixed real Cache response ID property | PASS | PASS | OK | `reports/formal_batch/logs/pr74_real_nutshell_cache_fixed_formal.log` |

## Sources

- PR #74: https://github.com/OSCPU/NutShell/pull/74
- Pre-PR parent: https://github.com/OSCPU/NutShell/commit/4b656f32aea0687fe8c823b99a54dc76517c3a41
- Fixed PR head: https://github.com/OSCPU/NutShell/commit/287c5e02490aca73055211bd04908917d71deaf7

## Interpretation

- The DUT is the real NutShell `nutcore.Cache`, generated from the two historical commits.
- The parent commit builds `CacheIO.in` as `SimpleBusUC(userBits = userBits)`, so an OOO `idBits=4` wrapper cannot elaborate the required ID field.
- The fixed commit builds `CacheIO.in` as `SimpleBusUC(userBits = userBits, idBits = idBits)`, so the same wrapper elaborates and the fixed formal property can run.
- This case catches an interface/type regression rather than a deep runtime BMC counterexample; that matches PR #74's original symptom: the previous change broke the OOO configuration.
