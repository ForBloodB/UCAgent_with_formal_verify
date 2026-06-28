# 场景 5：全 Cache 声明功能覆盖与 UCAgent 验证闭环

## 定位

场景 5 不是第五个 bug，也不声称完成 NutShell SoC 或 RTL line/toggle 全覆盖。

它的目标是把本仓库声明的 15 个 Cache functional coverage points 做成可执行、可检查、可追踪的 coverage closure，并把 PR21、PR74、04 三个 bug point 纳入同一张 coverage database。

## 最合理流程

| 步骤 | 执行者 | 产物 | 是否已在场景 5 中落地 |
| --- | --- | --- | --- |
| 1. 阅读 NutShell Cache/SimpleBus 设计文档，列出功能域 | 人工手写，UCAgent 可辅助摘要 | `cache_coverage_plan.yaml` 中的 references 与 coverage groups | 已落地 |
| 2. 定义环境假设，例如 reset、memory latency、MMIO、coherence、L1 ready 策略 | 人工手写 | `environment_assumptions` | 已落地 |
| 3. 定义 functional coverage points | 人工手写，UCAgent 可补建议 | `coverage_points` | 已落地 |
| 4. 定义 CRV 场景族 | 人工手写，UCAgent 可生成草稿 | `crv_scenarios` | 已落地 |
| 5. 定义 scoreboard oracle | 人工手写 | `scoreboard_plan` | 已落地 |
| 6. 用 Picker 导出真实 Cache wrapper Python DUT | Picker 操作，人工选择 wrapper 和参数 | `reports/artifacts/*/toffee_dut*` | 02/03/04 已落地 |
| 7. 用 Toffee/pytest 实现 directed/CRV tests | Toffee 操作，人工补 timing、mock、scoreboard | `unity_test/tests/test_*.py` | 02/03/04 已落地，05 执行 coverage closure |
| 8. 用 UCAgent 跑官方 `RunTestCases` | UCAgent 操作 | `uc_test_report/index.html`、message log | 05 已落地 |
| 9. 对窄窗口高风险点调用 `generic-formal` skill | UCAgent + formal skill | formal report、counterexample log | 01/02/03/04/05 已落地 |
| 10. 合并 coverage DB，审查候选 bug，决定是否关闭覆盖 | 人工签核，UCAgent 可生成候选 bug report | `reports/05_full_cache_coverage_plan.md` | 15/15 已闭环 |

## 为什么需要人工定义

完整 Cache coverage 不是简单统计“跑过多少代码行”。必须有人定义：

- 哪些场景属于合法输入；
- 哪些行为属于必须保证的架构/协议要求；
- scoreboard 如何判断读写、mask、dirty、replacement、flush、coherence 是否正确；
- 哪些 coverage point 可以关闭；
- 像 04 中 `L1 resp.ready` 是否必须 eager-ready 这样的协议假设，必须在设计文档或验证计划中明示。

UCAgent 可以帮助生成草稿、执行测试、总结候选 bug，但最终验证意图和签核需要人工负责。

## 当前结果

- Declared functional coverage：`15/15 = 100.0%`
- PR21 / PR74 / 04 bug points：全部纳入 05 coverage DB
- Partial：`0`
- Gap：`0`
- UCAgent bug candidate report：`reports/05_ucagent_bug_candidates.md`

## 复现命令

本地 smoke，不调用 API：

```bash
bash scripts/run_cases.sh --case 05 --with-formal --smoke
```

严格模式，调用真实 UCAgent API，formal-first：

```bash
source .ucagent_env
bash scripts/run_cases.sh --case 05 --with-formal
```

严格模式，调用真实 UCAgent API，无 formal 对照：

```bash
source .ucagent_env
bash scripts/run_cases.sh --case 05 --no-formal
```

## 关键文件

- Plan：`tests/cases/05_full_cache_coverage_plan/data/cache_coverage_plan.yaml`
- Local pytest：`tests/cases/05_full_cache_coverage_plan/toffee/test_full_cache_coverage_plan.py`
- UCAgent workspace：`tests/ucagent_workspaces/05_full_cache_coverage_plan`
- Coverage report：`reports/05_full_cache_coverage_plan.md`
- UCAgent report：`reports/05_full_cache_coverage_plan_ucagent.md`
- Bug candidate report：`reports/05_ucagent_bug_candidates.md`
