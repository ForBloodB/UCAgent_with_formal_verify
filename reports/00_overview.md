# 本轮复现总览

复现时间：2026-06-28
入口脚本：`scripts/run_cases.sh`

## 结果矩阵

| Case | 运行方式 | 结果 | 主要证据 |
| --- | --- | --- | --- |
| 01 | `bash scripts/run_cases.sh --case 01 --with-formal --smoke` | buggy `FAIL`，fixed `PASS` | `reports/01_adder.md` |
| 02 | `source .ucagent_env && bash scripts/run_cases.sh --case 02 --with-formal` | PR21 pre `FAIL`，fixed `PASS` | `reports/02_pr21.md`, `reports/02_pr21_ucagent_formal_skill.md` |
| 03 | `source .ucagent_env && bash scripts/run_cases.sh --case 03 --with-formal` | PR74 pre `ERROR/ELAB_FAIL`，fixed `PASS` | `reports/03_pr74.md`, `reports/03_pr74_ucagent_formal_skill.md` |
| 04 | `source .ucagent_env && bash scripts/run_cases.sh --case 04 --with-formal` | formal assert `FAIL`，cover `PASS`，dynamic `DYNAMIC_REPRODUCED` | `reports/04_l2_readburst.md`, `reports/04_l2_readburst_ucagent_full_demo.md` |
| 05 | `source .ucagent_env && bash scripts/run_cases.sh --case 05` | latest-only 15/15 declared functional coverage | `reports/05_full_cache_coverage_plan.md`, `reports/05_ucagent_bug_candidates.md` |

## UCAgent + Formal Skill 证据

| Case | 关键工具调用 | 日志 |
| --- | --- | --- |
| 02 | `ListSkill`, `RunSkillScript`, `SetSkillUsage`, `ToolComplete`, `ToolExit` | `reports/artifacts/02_pr21/ucagent_formal/logs/ucagent_pr21_formal_skill_messages.jsonl` |
| 03 | `ListSkill`, `RunSkillScript`, `SetSkillUsage`, `ToolComplete`, `ToolExit` | `reports/artifacts/03_pr74/ucagent_formal/logs/ucagent_pr74_formal_skill_messages.jsonl` |
| 04 | `RunSkillScript` 后继续 `RunTestCases` | `reports/artifacts/04_l2_readburst/logs/ucagent_l2_readburst_full_demo_messages.jsonl` |
| 05 | `RunSkillScript` 后继续 `RunTestCases` | `reports/artifacts/05_full_cache_coverage_plan/logs/ucagent_full_cache_coverage_plan_with_formal_messages.jsonl` |

## 04 波形与动态复现

- VCD：`reports/artifacts/04_l2_readburst/artifacts/dynamic_readburst_ready_deadlock.vcd`
- 截图：`reports/assets/04_l2_readburst_ready_valid_waveform.png`
- 观察窗口：首次 bug marker cycle `44`，cycle `45` 到 `54` 为触发后 10 个循环的核心窗口。

在标准 Decoupled ready/valid 语义下，04 是一个很强的 latest candidate bug；如果 NutShell 额外规定 L1 必须 eager-ready，则需要在设计文档中明确写出该环境假设。

## 05 覆盖口径

05 是独立 latest-only 部分，不引用 PR21/PR74 历史证据。它声明并关闭 15 个 latest NutShell Cache functional coverage points：

- total：`15`
- implemented：`15`
- partial：`0`
- gap：`0`
- declared functional coverage：`100.0%`

该 100% 不代表完整 NutShell SoC 或 RTL line/toggle 覆盖率 100%。
