# 通用 Formal Skill 报告

- 创建时间：2026-06-28T00:41:48.819760+00:00

| Case | Expected | Actual | Verdict | Depth | Log |
| --- | --- | --- | --- | --- | --- |
| `l2_readburst_hit_ready_deadlock_assert` | FAIL | FAIL | OK | 96 | `reports/artifacts/04_l2_readburst/logs/l2_readburst_hit_ready_deadlock_assert.log` |
| `l2_readburst_hit_ready_deadlock_cover` | PASS | PASS | OK | 96 | `reports/artifacts/04_l2_readburst/logs/l2_readburst_hit_ready_deadlock_cover.log` |

## 解读

- `l2_readburst_hit_ready_deadlock_assert`：expected `FAIL`，actual `FAIL`；bounded formal run 找到了 ready/valid 反例。
- `l2_readburst_hit_ready_deadlock_cover`：expected `PASS`，actual `PASS`；`readBurst hit + resp_ready low` 目标窗口可达。
- 这是 latest-upstream candidate bug 报告，不是 upstream 已确认公开 bug。

## 来源

- Latest upstream NutShell commit: `041f694965728ea183a0622daa1734002bf4621e`



## 动态复现

- 分类：`DYNAMIC_REPRODUCED`
- 报告：`reports/artifacts/04_l2_readburst/dynamic_readburst_ready_deadlock.md`
- 日志：`reports/artifacts/04_l2_readburst/artifacts/dynamic_readburst_ready_deadlock.log`
- VCD: `reports/artifacts/04_l2_readburst/artifacts/dynamic_readburst_ready_deadlock.vcd`

public-IO 仿真复现了 ready/valid deadlock 风险：同地址 L2 readBurst hit 停留在 S3 且 L1 侧 `resp_ready=0` 时，`io_cpu_resp_valid` 也保持为低。

## Toffee 动态覆盖闭环

- 报告：`reports/04_l2_readburst_toffee_coverage.md`
- Toffee/pytest HTML：`reports/artifacts/04_l2_readburst/toffee/pytest_report/index.html`
- Toffee waveform：`reports/artifacts/04_l2_readburst/toffee/l2_readburst_ready_deadlock.fst`
- Coverage JSON：`reports/artifacts/04_l2_readburst/toffee/coverage_summary.json`

该闭环使用 Picker 导出的真实 `FreshCacheFormalDut` Python DUT，并用 Toffee fixture 驱动 public IO。覆盖率只统计 04 场景 coverpoints，不代表完整 Cache functional coverage。
