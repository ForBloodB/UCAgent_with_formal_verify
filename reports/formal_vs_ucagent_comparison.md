# Formal vs UCAgent Comparison

- Date: 2026-06-15T13:08:35+08:00
- Formal report: `reports/formal_batch/three_case_formal.md`
- Directed dynamic report: `reports/directed_three_case_results.md`
- UCAgent report: `reports/ucagent_three_case_results.md`

| Case | Formal result | Directed dynamic | UCAgent result | Complementary reading |
| --- | --- | --- | --- | --- |
| PR #21 MMIO prefetch | Buggy FAIL / fixed PASS | Directed test detects buggy | INFRA_FAIL | MMIO prefetch must not flush a pending normal request; UCAgent result is from generated tests replayed against both RTL variants. |
| PR #74 CacheIO idBits | Buggy FAIL / fixed PASS | Directed test detects buggy | DETECTED | Nonzero out-of-order request ID must be preserved; UCAgent result is from generated tests replayed against both RTL variants. |
| Flush outstanding miss | Buggy FAIL / fixed PASS | Directed test detects buggy | DETECTED | Flush before refill must not fabricate an early CPU response; UCAgent result is from generated tests replayed against both RTL variants. |

## Conclusion

Formal verification gives short symbolic counterexamples for all three target bug windows, and the hand-written directed dynamic tests reproduce the same buggy/fixed split. In this run UCAgent successfully converted two cases into maintainable Toffee/pytest regressions (`PR #74` and `flush outstanding miss`). The `PR #21` entry is an explicit UCAgent generation/infrastructure failure: it did not edit the seeded template before timeout, so it is not treated as evidence that the design is clean or that the verification intent is ineffective.
