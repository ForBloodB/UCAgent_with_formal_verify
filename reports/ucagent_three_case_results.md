# UCAgent Three Case Results

- Date: 2026-06-15T11:17:06+08:00
- Backend: `langchain`
- Timeout per fixed-generation UCAgent run: `900` seconds
- Timeout per buggy-probe UCAgent run: `300` seconds
- Flow: seed UCAgent docs/API, generate tests from `CaseFixed`, replay the same `unity_test/tests` against fixed and buggy RTL.
- UCAgent stage policy: seed a clean `.ucagent/ucagent_info.json` so stages 0-21 are treated as completed and stages 24-26 as skipped; run test implementation/comprehensive verification/summary stages.
- Supervisor policy: if UCAgent writes executable tests but the official stage loop does not exit, stop the process and use independent Toffee/pytest replay as the acceptance oracle.

## Toolchain Smoke

- Status: PASS
- Log: `reports/ucagent_logs/toolchain_smoke.log`

## Case Matrix

| Case | UCAgent generation | Generated tests | Fixed replay | Buggy replay | Buggy probe | Classification | Artifacts |
| --- | --- | ---: | --- | --- | --- | --- | --- |
| `pr21_prefetch_mmio` | FAIL | 1 | SKIPPED | SKIPPED | SKIPPED | INFRA_FAIL | `reports/ucagent_artifacts/pr21_prefetch_mmio` |
| `pr74_cache_io_idbits` | PASS_EARLY_STOP | 1 | PASS | FAIL | SKIPPED | DETECTED | `reports/ucagent_artifacts/pr74_cache_io_idbits` |
| `flush_outstanding_miss` | PASS_EARLY_STOP | 1 | PASS | FAIL | SKIPPED | DETECTED | `reports/ucagent_artifacts/flush_outstanding_miss` |

## Failure Details

- `pr21_prefetch_mmio`: UCAgent reached the seeded stage-22 batch implementation task, read the template and DUT files, but did not edit the target pytest template before the 900 second supervisor timeout. The log also shows irrelevant/path-confused exploration such as missing `CaseFixed_RTL` / `CaseFixed.py` lookups and context summarization after exceeding the token window. This is recorded as `INFRA_FAIL`, not as evidence that the PR #21 bug is missed by the verification intent.
- `pr74_cache_io_idbits`: UCAgent generated executable pytest tests from the seeded template. Independent replay passed on `CaseFixed` and failed on `CaseBuggy`, so the case is `DETECTED`.
- `flush_outstanding_miss`: UCAgent generated executable pytest tests from the seeded template. Independent replay passed on `CaseFixed` and failed on `CaseBuggy`, so the case is `DETECTED`.

## Acceptance Reading

The formal and hand-written directed matrices cover all three intended bug windows. UCAgent/Toffee produced usable dynamic regressions for two of the three cases in this run; PR #21 remains an explicit UCAgent infrastructure/generation failure for this environment and model run.
