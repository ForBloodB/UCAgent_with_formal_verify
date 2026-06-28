# 05 UCAgent Bug Candidates

本报告只汇总 latest NutShell Cache 模块的可疑 bug 与后续假设，不引用历史 PR 或旧版本证据。
候选点只有在具备 formal 反例或动态 scoreboard 失败证据后，才能升级为 candidate bug；其余保持 hypothesis。

## Latest candidate bugs with evidence

| Candidate | Evidence Level | 分类 | 触发条件 | 证据 |
| --- | --- | --- | --- | --- |
| `CAND_LATEST_L2_READBURST_READY_VALID` | `formal_counterexample` | `latest_candidate_bug`, `formal_detected`, `dynamic_reproduced`, `human_refined` | Same-address readBurst miss/refill followed by readBurst hit while L1 resp_ready is low. | `reports/05_full_cache_coverage_plan.md`<br>`reports/05_ucagent_bug_candidates.md` |

## Latest hypotheses suggested by UCAgent/human refinement

| ID | Evidence Level | 分类 | 建议触发条件 | 人工 Verilog 复查 |
| --- | --- | --- | --- | --- |
| `HYP_FLUSH_OUTSTANDING_MISS` | `manual_verilog_not_reproduced` | `latest_hypothesis`, `UCAgent_suggested`, `human_refined` | Issue a read miss, hold memory response, assert flush, then release memory response. | Manual Verilog testbench drives the trigger and the VCD shows the cancelled response is dropped; not upgraded to candidate bug. |
| `HYP_DIRTY_EVICTION_ORDER` | `manual_verilog_not_reproduced` | `latest_hypothesis`, `UCAgent_suggested`, `human_refined` | Dirty a line, force conflict replacement, and observe whether writeback precedes refill. | Manual Verilog waveform shows writeback is visible with the replacement refill; not upgraded to candidate bug. |
| `HYP_PARTIAL_MASK_MERGE` | `manual_verilog_not_reproduced` | `latest_hypothesis`, `UCAgent_suggested`, `human_refined` | Write alternating byte masks to a cached word and read back the untouched lanes. | Manual Verilog waveform shows disabled byte lanes are preserved; not upgraded to candidate bug. |

## Manual Verilog waveform validation

三个 UCAgent hypothesis 已在 `tests/cases/05_full_cache_coverage_plan/manual/` 中转成 Verilog testbench 激励。
人工复查依据不是 Python reference model，而是 `iverilog + vvp` 生成的 VCD 波形。

- 报告：`reports/05_manual_verilog_validation.md`
- VCD：`reports/artifacts/05_full_cache_coverage_plan/manual_hypothesis_probe.vcd`

结论：这三个 hypothesis 在当前人工 Verilog 波形复查中均未复现为 bug，因此保留为 UCAgent 高风险建议/误判，不升级为 candidate bug。
