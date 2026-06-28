# 04 L2 readBurst UCAgent Toffee 运行

- 分类：`UCAgent_TOFFEE_COMPLETED`
- UCAgent log：`reports/artifacts/04_l2_readburst/logs/ucagent_l2_readburst_toffee.log`
- Message log：`reports/artifacts/04_l2_readburst/logs/ucagent_l2_readburst_toffee_messages.jsonl`
- UCAgent Toffee HTML：`tests/ucagent_workspaces/04_l2_readburst_deadlock/uc_test_report/index.html`
- Toffee coverage report：`reports/04_l2_readburst_toffee_coverage.md`
- Workspace mirrored coverage report：`tests/ucagent_workspaces/04_l2_readburst_deadlock/reports/04_l2_readburst_toffee_coverage.md`
- Token report：`reports/artifacts/04_l2_readburst/toffee_token_usage.md`

本次运行使用官方 UCAgent workspace 的 `unity_test/tests` 结构，调用 `RunTestCases` 运行人工校正后的 Toffee directed test。该结果证明 UCAgent 可以完整跑通 04 的 Toffee 动态验证闭环。
