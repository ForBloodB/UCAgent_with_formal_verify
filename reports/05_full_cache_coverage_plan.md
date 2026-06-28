# 05 Latest NutShell Cache Formal UCAgent Coverage Report

- 分类：`LATEST_CACHE_FORMAL_UCAGENT_FUNCTIONAL_COVERAGE_CLOSED`
- Coverage point total：`15`
- Implemented：`15`
- Partial：`0`
- Gap：`0`
- Declared functional coverage：`100.0%`
- CRV scenarios：`6`，gap：`0`
- Scoreboard items：`5`，gap：`0`
- Bug points：`1`
- Summary JSON：`reports/artifacts/05_full_cache_coverage_plan/coverage_plan_summary.json`
- Bug candidate report：`reports/05_ucagent_bug_candidates.md`

## 结论

05 是独立的 latest NutShell Cache formal-enabled UCAgent 流程：正式运行必须先调用 `generic-formal` skill，再执行 Toffee/pytest coverage closure。
当前仓库声明的 15 个 latest Cache functional coverage points 全部具备 stimulus、checker/scoreboard、coverage bin 与 evidence。
该 100% 只表示 `cache_coverage_plan.yaml` 中 15 个 latest 功能点闭环，不代表完整 NutShell SoC 或 RTL line/toggle 覆盖率 100%。

## Latest candidate bug 汇总

| Candidate | Evidence Level | 分类 | 映射覆盖点 |
| --- | --- | --- | --- |
| `CAND_LATEST_L2_READBURST_READY_VALID` | `formal_counterexample` | `latest_candidate_bug`, `formal_detected`, `dynamic_reproduced`, `human_refined` | `CP_READBURST_HIT_BACKPRESSURE`, `CP_READY_VALID_RESP_STABILITY` |

## UCAgent Hypothesis 人工 Verilog 复查

UCAgent 在 05 中提出了三个高风险 hypothesis。为了避免把“AI 建议”误写成“已发现 bug”，本仓库新增 `tests/cases/05_full_cache_coverage_plan/manual/`，由人工编写 Verilog probe 和 testbench，使用 `iverilog + vvp` 直接施加触发条件，并通过 VCD 观察结果。

- 报告：`reports/05_manual_verilog_validation.md`
- VCD：`reports/artifacts/05_full_cache_coverage_plan/manual_hypothesis_probe.vcd`
- 运行方式：`bash tests/cases/05_full_cache_coverage_plan/manual/run_manual_verilog.sh`

| ID | UCAgent 建议触发条件 | 人工 Verilog 波形复查结论 |
| --- | --- | --- |
| `HYP_FLUSH_OUTSTANDING_MISS` | read miss 未完成时 flush，之后 memory response 返回 | 未复现为 bug：波形显示 cancelled response 被丢弃，没有 stale CPU response，也没有 after-flush line allocation。 |
| `HYP_DIRTY_EVICTION_ORDER` | dirty line 后 conflict replacement | 未复现为 bug：波形显示 replacement 窗口中 `writeback_valid` 与 refill 事件可见，dirty victim 没有静默丢失。 |
| `HYP_PARTIAL_MASK_MERGE` | alternating byte mask 写 cached word 后读回 | 未复现为 bug：波形显示 `partial_wmask=4'b0101` 时未使能 byte lane 保持原值，`partial_word=32'h44CC_22AA`。 |

因此，05 当前人工签核口径为：`CAND_LATEST_L2_READBURST_READY_VALID` 仍是有 formal/dynamic 证据的潜在 bug；三个 UCAgent hypothesis 是高风险建议，但在人工 Verilog 波形复查中未复现，暂归类为 UCAgent 误判/未升级项。

## 人工/UCAgent/Picker/Toffee/Formal 分工

| 步骤 | 执行者 | 说明 |
| --- | --- | --- |
| 定义覆盖目标、合法环境假设、scoreboard oracle | 人工手写 | 决定什么才算 Cache 验证充分，不能交给工具自动闭环。 |
| 生成/补强 Toffee 或 formal 测试草稿 | UCAgent | 读取 plan 后生成测试建议、候选 bug 点和报告草稿。 |
| 准备 latest Cache formal wrapper | 脚本 + 人工审查 | 05 只面向 latest NutShell Cache，不读取历史 PR 证据。 |
| 执行动态测试、收集场景 coverage | Toffee/pytest | 跑 public-IO 或 reference-scoreboard 测试，生成 HTML/JSON/Markdown 报告。 |
| 执行窄窗口 property 搜索 | UCAgent + generic-formal skill | 对 latest Cache readBurst ready/valid 风险点做 bounded formal。 |
| 复查 UCAgent hypothesis | 人工 Verilog testbench | 对三个 AI 建议触发条件直接施加 Verilog 激励，查看 VCD 后判定未复现。 |
| 审查候选 bug、确认覆盖关闭 | 人工 | 判断 UCAgent 建议是否可接受，避免纯 AI 刷覆盖。 |

## Coverage Points

| ID | Group | Status | Coverage Bin | Evidence |
| --- | --- | --- | --- | --- |
| `CP_READ_HIT` | `read` | `implemented` | `read.clean_hit` | `reports/05_full_cache_coverage_plan.md` |
| `CP_READ_MISS_REFILL` | `read` | `implemented` | `read.miss_refill` | `reports/05_full_cache_coverage_plan.md` |
| `CP_READBURST_HIT_BACKPRESSURE` | `readburst` | `implemented` | `readburst.hit_backpressure` | `reports/05_full_cache_coverage_plan.md` |
| `CP_REFILL_ORDER_AND_LAST_BEAT` | `refill` | `implemented` | `refill.order_last_beat` | `reports/05_full_cache_coverage_plan.md` |
| `CP_UNCACHED_ATOMIC_BYPASS_POLICY` | `interface` | `implemented` | `interface.uncached_atomic_bypass_policy` | `reports/05_full_cache_coverage_plan.md` |
| `CP_WRITE_HIT_FULL_MASK` | `write` | `implemented` | `write.hit_full_mask` | `reports/05_full_cache_coverage_plan.md` |
| `CP_WRITE_HIT_PARTIAL_MASK` | `write` | `implemented` | `write.hit_partial_mask` | `reports/05_full_cache_coverage_plan.md` |
| `CP_WRITE_MISS_REFILL` | `write` | `implemented` | `write.miss_refill` | `reports/05_full_cache_coverage_plan.md` |
| `CP_DIRTY_EVICTION_WRITEBACK` | `replacement` | `implemented` | `replacement.dirty_evict_writeback` | `reports/05_full_cache_coverage_plan.md` |
| `CP_CLEAN_EVICTION_NO_WRITEBACK` | `replacement` | `implemented` | `replacement.clean_evict_no_writeback` | `reports/05_full_cache_coverage_plan.md` |
| `CP_FLUSH_DURING_OUTSTANDING_MISS` | `flush` | `implemented` | `flush.outstanding_miss` | `reports/05_full_cache_coverage_plan.md` |
| `CP_COHERENCE_PROBE_HIT` | `coherence` | `implemented` | `coherence.probe_hit` | `reports/05_full_cache_coverage_plan.md` |
| `CP_COHERENCE_PROBE_MISS` | `coherence` | `implemented` | `coherence.probe_miss` | `reports/05_full_cache_coverage_plan.md` |
| `CP_READY_VALID_REQ_STABILITY` | `protocol` | `implemented` | `protocol.req_stability` | `reports/05_full_cache_coverage_plan.md` |
| `CP_READY_VALID_RESP_STABILITY` | `protocol` | `implemented` | `protocol.resp_stability` | `reports/05_full_cache_coverage_plan.md` |

## Coverage Closure Check

- Hit bins：`15`
- Expected bins：`15`
- Missing bins：`0`
- Unexpected bins：`0`
- Dirty writebacks observed：`1`

## Environment Risks

- `l1_resp_ready_policy`

## Missing Items

无。
