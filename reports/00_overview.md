# 五案例验证总览

当前工作区保留五个活跃案例：四个 bug/能力演示案例，以及一个全 Cache 声明功能覆盖闭环案例。

| 编号 | 案例 | 类型 | 当前证据 |
| --- | --- | --- | --- |
| 01 | `adder_formal_skill` | 人工注入 bug | buggy adder `FAIL`，fixed adder `PASS`。 |
| 02 | `pr21_mmio_prefetch` | 真实 NutShell 历史 bug | pre-PR 真实 Cache `FAIL`，fixed 真实 Cache `PASS`。 |
| 03 | `pr74_cache_io_idbits` | 真实 NutShell 历史 bug | pre-PR 真实 Cache `ELAB_FAIL`，fixed generation/formal `PASS`。 |
| 04 | `l2_readburst_hit_ready_valid_deadlock` | latest upstream 候选 bug hunt | UCAgent + `generic-formal`：assert `FAIL`，cover `PASS`；Toffee 场景覆盖率 `100%`；动态复现 `DYNAMIC_REPRODUCED`。 |
| 05 | `full_cache_coverage_plan` | 全 Cache 声明功能覆盖闭环 | UCAgent `RunTestCases` 检查 coverage DB；15 个 coverage points：15 implemented、0 partial、0 gap；PR21/PR74/04 bug points 纳入 DB。 |

## 证明了什么

- 形式验证是有用的：01、02、03、04 都定义了明确 property，并得到预期的 buggy/pre/candidate 失败证据。
- formal skill 是通用的：`src/ucagent_skills/generic-formal` 同时通过 YAML 运行 tiny adder 和 NutShell L2 readBurst SBY case。
- UCAgent 已集成：`tests/ucagent_workspaces/04_l2_readburst_deadlock` 支持 formal-first full demo，先通过 `RunSkillScript` 做形式诊断，再通过 `RunTestCases` 继续 Toffee/pytest 回归。
- 同一套 `generic-formal` UCAgent skill 也已经真实 API 跑通 02/03：PR21 pre/fixed、PR74 pre/fixed 均由 `RunSkillScript` 生成报告。
- 原始 UCAgent no-formal 动态后端已跑通 02/03/04：02/03 在人工补齐 Picker/Toffee harness 后可通过 `RunTestCases` 执行动态回归；04 可依赖 Toffee `RunTestCases` 动态复现。旧的静态 no-formal 对照仍保留为“没有动态 harness 时的能力边界”证据。
- 05 说明完整覆盖必须先由人工定义 coverage plan、CRV、scoreboard 和 coverage database；当前已对仓库声明的 15 个 functional coverage points 形成 15/15 闭环。

## 赛题评分维度自评

| 维度 | 权重 | 证据 | 风险 |
| --- | ---: | --- | --- |
| 完备性 | 40% | 五个确定性案例；两个真实历史 NutShell bug；latest readBurst candidate 同时有 formal 与 dynamic 证据；05 声明功能覆盖 15/15。 | 05 不声称完整 RTL line/toggle 覆盖率。 |
| 技术深度 | 30% | 真实 NutShell commit wrapper、SymbiYosys proof、public-IO replay、Picker/Toffee 场景覆盖率、可复用 formal skill、05 reference scoreboard closure。 | 后续可继续接 UCIS/RTL coverage。 |
| AI 使用效能 | 20% | UCAgent 通过官方 skill tools 执行 `generic-formal` 并记录完成日志。 | 当前后端日志不暴露 token 统计字段。 |
| 工程质量 | 10% | 编号脚本、Apache 2.0 license、最终报告、测试计划、Trash manifest。 | 大型生成 artifact 本地存在但默认忽略，保持提交干净。 |

## 最新运行记录

- `reports/artifacts/04_l2_readburst/logs/ucagent_l2_readburst_messages.jsonl` 包含两次成功的四元 `RunSkillScript` 调用：
  - `["python3", "generic-formal", "run_formal.py", "--workspace ../../.. --case ...l2_readburst_assert.yaml --timeout 1200"]`
  - `["python3", "generic-formal", "run_formal.py", "--workspace ../../.. --case ...l2_readburst_cover.yaml --timeout 1200"]`
- UCAgent 日志还包含 `ToolSetSkillUsage`、`ToolComplete`、`ToolExit`。
- `reports/artifacts/04_l2_readburst/logs/ucagent_l2_readburst_full_demo_messages.jsonl` 是推荐检查对象：应同时包含 `RunSkillScript`、`SetSkillUsage`、`RunTestCases`。
- `reports/artifacts/04_l2_readburst/logs/ucagent_l2_readburst_toffee_messages.jsonl` 包含单独 Toffee flow 的 `RunTestCases`：1 个 pytest 通过，6/6 functional check points 命中。
- `reports/artifacts/02_pr21/ucagent_formal/logs/ucagent_pr21_formal_skill_messages.jsonl` 包含 02 的 `RunSkillScript` 和 `SetSkillUsage`。
- `reports/artifacts/03_pr74/ucagent_formal/logs/ucagent_pr74_formal_skill_messages.jsonl` 包含 03 的 `RunSkillScript` 和 `SetSkillUsage`。
- `reports/artifacts/02_pr21/toffee_ucagent/logs/ucagent_pr21_toffee_messages.jsonl` 和 `reports/artifacts/03_pr74/toffee_ucagent/logs/ucagent_pr74_toffee_messages.jsonl` 均包含真实 `RunTestCases` 工具调用，且没有真实 `RunSkillScript` 工具调用，用于证明 no-formal 动态后端未使用 formal skill。
- `reports/artifacts/02_pr21/original_no_formal/logs/ucagent_pr21_original_no_formal_messages.jsonl` 和 `reports/artifacts/03_pr74/original_no_formal/logs/ucagent_pr74_original_no_formal_messages.jsonl` 是旧静态 no-formal baseline，说明没有动态 harness 时 agent 只能做静态回顾。
- `reports/artifacts/04_l2_readburst/token_usage.md` 尝试统计 token；当前后端日志没有暴露 token 字段，因此记录为 `not reported`。
- `reports/artifacts/05_full_cache_coverage_plan/logs/ucagent_full_cache_coverage_plan_messages.jsonl` 包含 05 的真实 `RunTestCases`；with-formal 模式还要求包含 `RunSkillScript` 和 `SetSkillUsage`。

## 活跃报告

- `reports/01_adder.md`
- `reports/02_pr21.md`
- `reports/03_pr74.md`
- `reports/04_l2_readburst.md`
- `reports/04_l2_readburst_toffee_coverage.md`
- `reports/04_l2_readburst_ucagent_full_demo.md`
- `reports/04_l2_readburst_toffee_ucagent.md`
- `reports/02_pr21_ucagent_formal_skill.md`
- `reports/03_pr74_ucagent_formal_skill.md`
- `reports/02_pr21_toffee_coverage.md`
- `reports/03_pr74_toffee_coverage.md`
- `reports/02_pr21_toffee_ucagent.md`
- `reports/03_pr74_toffee_ucagent.md`
- `reports/02_pr21_ucagent_original_no_formal.md`
- `reports/03_pr74_ucagent_original_no_formal.md`
- `reports/05_ucagent_original_no_formal_comparison.md`
- `reports/05_full_cache_coverage_plan.md`
- `reports/05_full_cache_coverage_plan_ucagent.md`
- `reports/05_ucagent_bug_candidates.md`
- `reports/90_reproduction.md`
- `reports/91_ucagent_skill_evidence.md`
- `docs/final_report.md`
- `docs/test_plan.md`
- `docs/ai_human_collaboration.md`

大日志和生成 trace 位于 `reports/artifacts/`。
