# 05 全 Cache Coverage Plan 验证报告

- 分类：`COVERAGE_PLAN_VALIDATED_BY_UCAGENT_TOFFEE_FLOW`
- Coverage point total：`15`
- Implemented：`3`
- Partial：`3`
- Gap：`9`
- CRV scenarios：`6`，gap：`5`
- Scoreboard items：`4`，gap：`2`
- Summary JSON：`reports/artifacts/05_full_cache_coverage_plan/coverage_plan_summary.json`

## 结论

本场景不是第五个 bug，而是完整 Cache 覆盖闭环的计划级验证。
它检查人工定义的 coverage plan 是否完整、已有 02/03/04 证据是否可追踪、未完成项是否明确标为 gap。

## 人工/UCAgent/Picker/Toffee 分工

| 步骤 | 执行者 | 说明 |
| --- | --- | --- |
| 定义覆盖目标、合法环境假设、scoreboard oracle | 人工手写 | 决定什么才算 Cache 验证充分，不能交给工具自动闭环。 |
| 生成/补强 Toffee 或 formal 测试草稿 | UCAgent | 读取 plan 后生成测试建议或草稿。 |
| 导出真实 DUT | Picker | 将 Chisel/RTL wrapper 导出成 Python DUT。 |
| 执行动态测试、收集场景 coverage | Toffee/pytest | 跑 public-IO 测试、生成 HTML/JSON 报告。 |
| 执行窄窗口 property 搜索 | UCAgent + generic-formal skill | 对 ready/valid、flush、dirty eviction 等高风险窗口做 bounded formal。 |
| 审查 gap、确认是否关闭覆盖 | 人工 | 判断覆盖是否真实有效，避免纯 AI 刷覆盖。 |

## Coverage Points

| ID | Group | Status | Target |
| --- | --- | --- | --- |
| `CP_READ_HIT` | `read` | `partial` | `dynamic` |
| `CP_READ_MISS_REFILL` | `read` | `partial` | `dynamic` |
| `CP_READBURST_HIT_BACKPRESSURE` | `readburst` | `implemented` | `formal_and_dynamic` |
| `CP_MMIO_PREFETCH_PIPELINE_INTERFERENCE` | `mmio` | `implemented` | `formal_and_dynamic` |
| `CP_CACHE_IO_IDBITS` | `interface` | `implemented` | `formal_and_dynamic` |
| `CP_WRITE_HIT_FULL_MASK` | `write` | `gap` | `dynamic` |
| `CP_WRITE_HIT_PARTIAL_MASK` | `write` | `gap` | `dynamic` |
| `CP_WRITE_MISS_REFILL` | `write` | `gap` | `dynamic` |
| `CP_DIRTY_EVICTION_WRITEBACK` | `replacement` | `gap` | `dynamic_or_formal` |
| `CP_CLEAN_EVICTION_NO_WRITEBACK` | `replacement` | `gap` | `dynamic` |
| `CP_FLUSH_DURING_OUTSTANDING_MISS` | `flush` | `gap` | `formal_and_dynamic` |
| `CP_COHERENCE_PROBE_HIT` | `coherence` | `gap` | `dynamic_or_formal` |
| `CP_COHERENCE_PROBE_MISS` | `coherence` | `gap` | `dynamic_or_formal` |
| `CP_READY_VALID_REQ_STABILITY` | `protocol` | `gap` | `formal_and_dynamic` |
| `CP_READY_VALID_RESP_STABILITY` | `protocol` | `partial` | `formal_and_dynamic` |

## Open Environment Assumptions

- `l1_resp_ready_policy`
- `coherence_model`

## Missing Evidence

无。
