# 04 L2 readBurst UCAgent Formal-First Full Demo

- 分类：`UCAgent_FORMAL_FIRST_FULL_DEMO_COMPLETED`
- Formal assert：`FAIL as expected`
- Formal cover：`PASS as expected`
- Toffee classification：`DYNAMIC_REPRODUCED`
- Toffee 04 场景 setup coverage：`5/5 = 100.0%`

## 1. Formal 前置诊断

UCAgent 在同一次 mission 中先通过 `generic-formal` skill 执行：

- `l2_readburst_assert.yaml`
- `l2_readburst_cover.yaml`

formal skill 报告：`reports/04_l2_readburst_formal_skill.md`

该阶段用于让 agent 先拥有形式验证搜索能力，而不是直接进入动态测试。

## 2. Bug 复现方式

当 formal assert 给出反例时，复现思路为：

1. 对同一地址发起一次 L2 `readBurst` miss。
2. 让内存模型完成 refill，形成 cache line。
3. 再对同一地址发起第二次 `readBurst`，使其成为 L2 hit。
4. 在 S3 hit/readBurst 窗口将 L1 侧 `resp_ready=0`。
5. 观察 `resp_valid` 是否仍主动拉高；当前 04 现象为 `resp_valid` 保持低电平。

该结论仍是 latest upstream candidate bug，不写成 upstream 已确认公开 bug。

## 3. 原本 UCAgent Toffee 流程

formal 诊断后，UCAgent 没有停止，而是继续通过官方 `RunTestCases` 运行：

```text
test_l2_readburst_ready_valid.py -q
```

动态报告：`reports/04_l2_readburst_toffee_coverage.md`
UCAgent Toffee HTML：`tests/ucagent_workspaces/04_l2_readburst_deadlock/uc_test_report/index.html`

该阶段证明 formal 发现可以继续转化为 Toffee/pytest 动态复现与回归测试。

## 4. UCAgent 证据

- UCAgent log：`reports/artifacts/04_l2_readburst/logs/ucagent_l2_readburst_full_demo.log`
- Message log：`reports/artifacts/04_l2_readburst/logs/ucagent_l2_readburst_full_demo_messages.jsonl`
- Token report：`reports/artifacts/04_l2_readburst/full_demo_token_usage.md`

日志验收项包含：`RunSkillScript`、`SetSkillUsage`、`RunTestCases`、`ToolComplete`、`ToolExit`。
