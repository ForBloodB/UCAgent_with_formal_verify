# 三案例 UCAgent Toffee 动态后端无 Formal Skill 对照

本报告由 `scripts/internal/46_run_three_case_ucagent_original_no_formal.sh` 生成。

| Case | UCAgent Toffee dynamic no-formal 结果 | 说明 |
| --- | --- | --- |
| 02 PR21 MMIO prefetch | `UCAgent_TOFFEE_COMPLETED_NO_FORMAL` | 先由 UCAgent/官方模板生成 Toffee 草稿，再人工补齐 Picker DUT、directed replay、scoreboard 和 coverage，最后由 UCAgent 调 `RunTestCases` 运行。 |
| 03 PR74 CacheIO idBits | `UCAgent_TOFFEE_COMPLETED_NO_FORMAL` | pre-PR 是真实接口/elaboration failure；fixed DUT 通过 Picker/Toffee 动态 ID 回归，UCAgent 调 `RunTestCases` 运行。 |
| 04 L2 readBurst ready/valid | `UCAgent_TOFFEE_COMPLETED` | 人工校正的 Toffee/pytest 动态环境，不依赖 formal skill 也能通过 `RunTestCases` 完成动态复现。 |

## 结论

本轮不调用 formal skill。02/03/04 都使用官方 UCAgent `unity_test/tests` + `RunTestCases` 动态后端执行。02/03 的关键补强来自人工干预：UCAgent 给出 Toffee/API/pytest 草稿结构，人工把草稿接到真实 Picker DUT、稳定时序、补 scoreboard 和 functional coverage。该结果说明 UCAgent 能跑完整动态验证后端，但复杂历史 bug 仍需要人工把可执行 harness 做扎实。

## 子报告

- `reports/02_pr21_toffee_ucagent.md`
- `reports/03_pr74_toffee_ucagent.md`
- `reports/04_l2_readburst_toffee_ucagent.md`
