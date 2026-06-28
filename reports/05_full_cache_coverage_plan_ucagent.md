# 05 全 Cache 声明功能覆盖闭环 UCAgent 流程

- 分类：`UCAgent_DECLARED_COVERAGE_CLOSURE_COMPLETED`
- Mode：`with-formal`
- UCAgent log：`reports/artifacts/05_full_cache_coverage_plan/logs/ucagent_full_cache_coverage_plan_with_formal.log`
- Message log：`reports/artifacts/05_full_cache_coverage_plan/logs/ucagent_full_cache_coverage_plan_with_formal_messages.jsonl`
- UCAgent Toffee HTML：`tests/ucagent_workspaces/05_full_cache_coverage_plan/uc_test_report/index.html`
- Plan report：`reports/05_full_cache_coverage_plan.md`
- Bug candidate report：`reports/05_ucagent_bug_candidates.md`
- Summary JSON：`reports/artifacts/05_full_cache_coverage_plan/coverage_plan_summary.json`
- Token report：`reports/artifacts/05_full_cache_coverage_plan/toffee_ucagent/token_usage.md`

本次运行是 05 唯一正式流程：UCAgent 先调用 `generic-formal` skill 运行 latest Cache formal diagnosis，再继续 `RunTestCases`。这里的 100% 只表示 05 latest 声明功能覆盖闭环，不代表完整 RTL line/toggle 覆盖率。
