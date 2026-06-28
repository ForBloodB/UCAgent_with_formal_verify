# AI 与人工协作记录

## 协作对照表

| 领域 | AI/UCAgent 贡献 | 人工介入 | 结果 |
| --- | --- | --- | --- |
| 通用 formal skill | 形成 UCAgent-compatible 的 skill flow 与脚本调用模式。 | 将专用 case skill 重构为通用 `generic-formal`。 | `src/ucagent_skills/generic-formal` 同时支持 adder 与 NutShell 案例。 |
| UCAgent 命令形态 | UCAgent 尝试调用 skill script。 | 修正为当前工具要求的四元命令 `[runner, skill, script, args]`。 | 得到干净的 `RunSkillScript` 证据。 |
| 案例选择 | AI 辅助探索多个候选场景。 | 人工收敛为 adder、PR21、PR74、L2 readBurst 四个最终案例。 | 形成可评审的四案例提交。 |
| PR21/PR74 | AI 早期生成 compact litmus 思路。 | 人工要求改为真实 NutShell 历史 commit wrapper。 | 得到真实历史 bug 复现。 |
| 02/03 Toffee 动态后端 | UCAgent 官方模板生成 `unity_test/tests` 草稿结构，真实 API run 调用 `RunTestCases`。 | 人工接入 Picker 导出的真实 DUT，补 PR21 pipeline replay、PR74 ID scoreboard、memory mock 和 coverage；修正 PR21 动态采样边界，避免把 fixed 后沿 probe 读数误报为失败。 | 02/03 在不调用 formal skill 的情况下也能跑完整 UCAgent Toffee 动态后端。 |
| 04 readBurst | AI 辅助搜索 ready/valid 窄窗口风险。 | 人工加入 latest-upstream wrapper、formal case 和 directed dynamic replay。 | 得到 formal + dynamic 双证据 candidate bug。 |
| 04 Toffee 覆盖率 | UCAgent 早期生成过 `unity_test/tests` 模板。 | 人工接入真实 Picker DUT，补 reset/memory mock/scoreboard/coverpoints，并修正 waveform 与 pytest 运行方式。 | 得到 `reports/04_l2_readburst_toffee_coverage.md`，04 场景 setup coverage 为 100%。 |
| 报告组织 | AI 生成初稿。 | 人工按赛题评分维度、证据路径和复现入口重排。 | 形成 `docs/final_report.md`、`reports/00_overview.md`、`reports/90_reproduction.md`。 |

## 经验总结

- 纯 AI 生成的 compact litmus 不足以支撑赛题级 NutShell Cache 交付。
- PR21/PR74 必须追溯真实 NutShell commit，才能说明案例不是自造 mock。
- UCAgent 可以生成 Picker/Toffee 代码草稿和执行官方 `RunTestCases` flow，但复杂 Cache 场景仍需要人工把草稿接到真实 DUT、时序 mock、scoreboard 和覆盖率上。
- AI 最有价值的作用是在验证意图被人工约束后，加速 wrapper、测试和报告迭代。
- 形式验证能有效暴露动态随机测试很难快速命中的 ready/valid 窄时序窗口。
