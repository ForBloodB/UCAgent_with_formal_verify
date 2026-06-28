# 05 全 Cache 声明功能覆盖闭环 UCAgent 流程

- 分类：`UCAgent_DECLARED_COVERAGE_CLOSURE_COMPLETED`
- Mode：`no-formal`
- UCAgent log：`reports/artifacts/05_full_cache_coverage_plan/logs/ucagent_full_cache_coverage_plan_no_formal.log`
- Message log：`reports/artifacts/05_full_cache_coverage_plan/logs/ucagent_full_cache_coverage_plan_no_formal_messages.jsonl`
- UCAgent Toffee HTML：`tests/ucagent_workspaces/05_full_cache_coverage_plan/uc_test_report/index.html`
- Plan report：`reports/05_full_cache_coverage_plan.md`
- Bug candidate report：`reports/05_ucagent_bug_candidates.md`
- Summary JSON：`reports/artifacts/05_full_cache_coverage_plan/coverage_plan_summary.json`
- Token report：`reports/artifacts/05_full_cache_coverage_plan/toffee_ucagent/token_usage_no_formal.md`

本次运行使用官方 UCAgent flow 检查 05 声明的 15 个 functional coverage points。若 mode 为 `with-formal`，UCAgent 会先调用 `generic-formal` skill 收集 PR21、PR74 和 04 的 bug evidence，再继续 `RunTestCases`；若 mode 为 `no-formal`，则只运行动态/checker 后端。这里的 100% 只表示 05 声明覆盖闭环，不代表完整 RTL line/toggle 覆盖率。
