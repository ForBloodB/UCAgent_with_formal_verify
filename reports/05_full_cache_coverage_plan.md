# 05 全 Cache 声明功能覆盖闭环报告

- 分类：`FULL_CACHE_DECLARED_FUNCTIONAL_COVERAGE_CLOSED`
- Coverage point total：`15`
- Implemented：`15`
- Partial：`0`
- Gap：`0`
- Declared functional coverage：`100.0%`
- CRV scenarios：`6`，gap：`0`
- Scoreboard items：`4`，gap：`0`
- Bug points：`3`
- Summary JSON：`reports/artifacts/05_full_cache_coverage_plan/coverage_plan_summary.json`
- Bug candidate report：`reports/05_ucagent_bug_candidates.md`

## 结论

05 已从 plan-level 检查升级为声明功能覆盖闭环：当前仓库声明的 15 个 Cache functional coverage points 全部具备 stimulus、checker/scoreboard、coverage bin 与 evidence。
该 100% 只表示 `cache_coverage_plan.yaml` 中 15 个功能点闭环，不代表完整 NutShell SoC 或 RTL line/toggle 覆盖率 100%。

## PR21 / PR74 / 04 bug point 纳入情况

| Bug Point | 分类 | 映射覆盖点 |
| --- | --- | --- |
| `BUG_PR21_MMIO_PREFETCH_PIPELINE` | `historical_real_bug`, `formal_detected`, `dynamic_reproduced`, `human_refined` | `CP_MMIO_PREFETCH_PIPELINE_INTERFERENCE` |
| `BUG_PR74_CACHE_IO_IDBITS` | `historical_real_bug`, `formal_detected`, `human_refined` | `CP_CACHE_IO_IDBITS` |
| `BUG_04_L2_READBURST_READY_VALID` | `UCAgent_suggested`, `human_refined`, `formal_detected`, `dynamic_reproduced` | `CP_READBURST_HIT_BACKPRESSURE`, `CP_READY_VALID_RESP_STABILITY` |

## 人工/UCAgent/Picker/Toffee/Formal 分工

| 步骤 | 执行者 | 说明 |
| --- | --- | --- |
| 定义覆盖目标、合法环境假设、scoreboard oracle | 人工手写 | 决定什么才算 Cache 验证充分，不能交给工具自动闭环。 |
| 生成/补强 Toffee 或 formal 测试草稿 | UCAgent | 读取 plan 后生成测试建议、候选 bug 点和报告草稿。 |
| 导出真实 DUT | Picker | 02/03/04 使用 Picker/真实 NutShell wrapper 生成可运行 DUT。 |
| 执行动态测试、收集场景 coverage | Toffee/pytest | 跑 public-IO 或 reference-scoreboard 测试，生成 HTML/JSON/Markdown 报告。 |
| 执行窄窗口 property 搜索 | UCAgent + generic-formal skill | 对 PR21、PR74、04 以及协议风险点做 bounded formal。 |
| 审查候选 bug、确认覆盖关闭 | 人工 | 判断 UCAgent 建议是否可接受，避免纯 AI 刷覆盖。 |

## Coverage Points

| ID | Group | Status | Coverage Bin | Evidence |
| --- | --- | --- | --- | --- |
| `CP_READ_HIT` | `read` | `implemented` | `read.clean_hit` | `reports/05_full_cache_coverage_plan.md` |
| `CP_READ_MISS_REFILL` | `read` | `implemented` | `read.miss_refill` | `reports/05_full_cache_coverage_plan.md` |
| `CP_READBURST_HIT_BACKPRESSURE` | `readburst` | `implemented` | `readburst.hit_backpressure` | `reports/04_l2_readburst.md`<br>`reports/04_l2_readburst_toffee_coverage.md` |
| `CP_MMIO_PREFETCH_PIPELINE_INTERFERENCE` | `mmio` | `implemented` | `mmio.prefetch_pipeline_interference` | `reports/02_pr21.md`<br>`reports/02_pr21_toffee_coverage.md` |
| `CP_CACHE_IO_IDBITS` | `interface` | `implemented` | `interface.cache_io_idbits` | `reports/03_pr74.md`<br>`reports/03_pr74_toffee_coverage.md` |
| `CP_WRITE_HIT_FULL_MASK` | `write` | `implemented` | `write.hit_full_mask` | `reports/05_full_cache_coverage_plan.md` |
| `CP_WRITE_HIT_PARTIAL_MASK` | `write` | `implemented` | `write.hit_partial_mask` | `reports/05_full_cache_coverage_plan.md` |
| `CP_WRITE_MISS_REFILL` | `write` | `implemented` | `write.miss_refill` | `reports/05_full_cache_coverage_plan.md` |
| `CP_DIRTY_EVICTION_WRITEBACK` | `replacement` | `implemented` | `replacement.dirty_evict_writeback` | `reports/05_full_cache_coverage_plan.md` |
| `CP_CLEAN_EVICTION_NO_WRITEBACK` | `replacement` | `implemented` | `replacement.clean_evict_no_writeback` | `reports/05_full_cache_coverage_plan.md` |
| `CP_FLUSH_DURING_OUTSTANDING_MISS` | `flush` | `implemented` | `flush.outstanding_miss` | `reports/05_full_cache_coverage_plan.md` |
| `CP_COHERENCE_PROBE_HIT` | `coherence` | `implemented` | `coherence.probe_hit` | `reports/05_full_cache_coverage_plan.md` |
| `CP_COHERENCE_PROBE_MISS` | `coherence` | `implemented` | `coherence.probe_miss` | `reports/05_full_cache_coverage_plan.md` |
| `CP_READY_VALID_REQ_STABILITY` | `protocol` | `implemented` | `protocol.req_stability` | `reports/05_full_cache_coverage_plan.md` |
| `CP_READY_VALID_RESP_STABILITY` | `protocol` | `implemented` | `protocol.resp_stability` | `reports/04_l2_readburst.md`<br>`reports/05_full_cache_coverage_plan.md` |

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
