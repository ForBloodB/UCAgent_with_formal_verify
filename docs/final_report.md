# NutShell Cache UCAgent 验证最终报告

## 摘要

本仓库整理为五个验证交付案例，用于展示：

- 形式验证可以发现真实历史 bug 或人工注入 bug。
- `generic-formal` 是一个可复用 UCAgent skill，可以运行任意 YAML/`sby` formal case。
- 02/03/04 都支持无 formal skill 的 UCAgent Toffee 动态后端：UCAgent 先生成/承载 `unity_test/tests` 草稿结构，人工完善 Picker DUT、scoreboard 与 coverage，再由真实 API 调 `RunTestCases` 执行。
- 04 案例进一步支持 UCAgent formal-first 完整流程：先通过官方 skill flow 做形式诊断，再继续官方 Toffee/pytest 流程。
- 02/03/04 均提供了 Toffee dynamic backend 证据；04 ready/valid 场景还提供 directed dynamic replay 与 formal counterexample。
- 05 进一步把完整 Cache coverage plan、CRV、scoreboard、coverage database 定义成可执行检查，说明如何从场景级验证扩展到工业级覆盖闭环。

当前自评：这是一个有竞争力的参赛提交形态，尤其在“人工深度介入、真实 bug 复现、UCAgent skill 集成、04 Picker/Toffee 覆盖率闭环”上证据清楚；同时报告中明确保留了与完整工业级全 Cache CRV 环境之间的差距。

## 评分维度映射

| 维度 | 权重 | 当前证据 | 自评 |
| --- | ---: | --- | --- |
| 完备性 | 40% | 五个编号案例；两个真实 NutShell 历史 bug；一个 latest L2 ready/valid 候选 bug；一个人工 skill smoke；一个完整 Cache coverage plan 验证闭环。 | bug 展示完整；全 Cache coverage 已有计划级闭环，具体 CRV/scoreboard 实现仍是后续工作。 |
| 技术深度 | 30% | 真实 NutShell commit checkout/generation、Chisel wrapper、SymbiYosys proof、public-IO 动态复现、04 Picker/Toffee functional coverage。 | formal 与 04 场景动态深度较强；全 Cache CRV 仍需补强。 |
| AI 使用效能 | 20% | UCAgent 通过 `ListSkill`、`RunSkillScript` 调用 `generic-formal`；也能在无 formal skill 时通过 `RunTestCases` 跑 02/03/04 的 Toffee dynamic backend。 | formal-first full demo、skill 集成、Toffee flow 和日志证据清楚。 |
| 工程质量 | 10% | 编号脚本、报告、`_Trash` 归档、Apache 2.0 license、复现指南。 | 结构清晰，可复现；大体积 artifact 放在 `reports/artifacts`。 |

## 四个演示案例

公开复现入口统一为 `scripts/run_cases.sh`。`scripts/internal/` 中的编号脚本是实现细节和证据脚本，新用户不需要直接调用。

| 案例 | 推荐命令 | 预期结果 | 报告 |
| --- | --- | --- | --- |
| 01 通用 formal 能力证明 | `bash scripts/run_cases.sh --case 01 --with-formal --smoke` | buggy `FAIL`，fixed `PASS` | `reports/01_adder.md` |
| 02 PR21 MMIO prefetch formal | `bash scripts/run_cases.sh --case 02 --with-formal --smoke` | pre `FAIL`，fixed `PASS` | `reports/02_pr21.md` |
| 02 PR21 UCAgent formal skill | `source .ucagent_env && bash scripts/run_cases.sh --case 02 --with-formal` | `RunSkillScript` 执行 pre/fixed；pre `FAIL`，fixed `PASS` | `reports/02_pr21_ucagent_formal_skill.md` |
| 02 PR21 UCAgent Toffee no-formal | `source .ucagent_env && bash scripts/run_cases.sh --case 02 --no-formal` | `RunTestCases` 执行 2 个 pytest；场景 check points 命中 | `reports/02_pr21_toffee_ucagent.md` |
| 03 PR74 CacheIO idBits formal | `bash scripts/run_cases.sh --case 03 --with-formal --smoke` | pre `ELAB_FAIL`，fixed formal `PASS` | `reports/03_pr74.md` |
| 03 PR74 UCAgent formal skill | `source .ucagent_env && bash scripts/run_cases.sh --case 03 --with-formal` | `RunSkillScript` 执行 pre/fixed；pre `ERROR`，fixed `PASS` | `reports/03_pr74_ucagent_formal_skill.md` |
| 03 PR74 UCAgent Toffee no-formal | `source .ucagent_env && bash scripts/run_cases.sh --case 03 --no-formal` | `RunTestCases` 执行 1 个 pytest；fixed response ID matched | `reports/03_pr74_toffee_ucagent.md` |
| 04 L2 readBurst formal-first full demo | `source .ucagent_env && bash scripts/run_cases.sh --case 04 --with-formal` | 先 formal assert `FAIL`/cover `PASS`，再 Toffee `RunTestCases` 通过 | `reports/04_l2_readburst_ucagent_full_demo.md` |
| 04 L2 readBurst local smoke | `bash scripts/run_cases.sh --case 04 --with-formal --smoke` | assert `FAIL`、cover `PASS`，dynamic `DYNAMIC_REPRODUCED`，Toffee coverage `5/5` | `reports/04_l2_readburst.md`、`reports/04_l2_readburst_toffee_coverage.md` |
| 04 UCAgent Toffee no-formal | `source .ucagent_env && bash scripts/run_cases.sh --case 04 --no-formal` | `RunTestCases` 1 passed，6/6 check points hit | `reports/04_l2_readburst_toffee_ucagent.md` |
| 05 全 Cache coverage plan | `bash scripts/run_cases.sh --case 05 --smoke` 或 `source .ucagent_env && bash scripts/run_cases.sh --case 05` | coverage plan 可执行检查通过，明确 implemented/partial/gap | `reports/05_full_cache_coverage_plan.md` |

## 04 动态复现触发条件

directed replay 只通过生成 wrapper 的 public ports 驱动：

1. 复位 latest-upstream NutShell L2 Cache wrapper。
2. 对同一地址发送一次 `readBurst` miss，并让简单内存模型完成 refill。
3. 再对同一地址发送第二次 `readBurst`，此时预期命中已 refill 的 cache line。
4. 当请求进入 S3，且满足 `valid && hit && readBurst` 时，将 `io_cpu_resp_ready=0` 保持低电平。
5. 检查 `io_cpu_resp_valid` 是否仍能独立于 ready 主动拉高。

观测结果为 `DYNAMIC_REPRODUCED`：当同地址 L2 readBurst hit 停留在 S3 且 L1 侧 `resp_ready=0` 时，`resp_valid=0`。该现象与 formal counterexample 一致。此问题在报告中表述为 latest upstream candidate bug，不写成 upstream 已确认公开 bug。

## AI 与人工协作总结

UCAgent 用于执行可复用 skill flow、继续官方 Toffee/pytest flow，并保存工具调用证据。人工介入主要体现在：

- 将验证范围收敛为四个可评审案例。
- 将早期专用 skill 重构为 `generic-formal` 通用 skill。
- 要求 PR21/PR74 使用真实 NutShell 历史 commit wrapper，而不是 compact mock。
- 为 04 场景增加 public-IO 动态复现、Picker Python DUT、Toffee env/scoreboard/coverage。
- 报告中区分“真实历史 bug”和“latest candidate bug”。

详细记录见 `docs/ai_human_collaboration.md`。

## UCAgent Skill 与 No-Formal 对照

本仓库用真实 API 分别运行了两类 UCAgent 流程：

| Case | 带 `generic-formal` skill | 原始 no-formal UCAgent |
| --- | --- | --- |
| 02 PR21 | `RunSkillScript` 运行 pre/fixed，pre `FAIL`、fixed `PASS`。 | `RunTestCases` 跑 2 个 Toffee tests；pre 风险窗口动态复现，fixed probe replay 记录采样边界。 |
| 03 PR74 | `RunSkillScript` 运行 pre/fixed，pre `ERROR`、fixed `PASS`。 | `RunTestCases` 跑 1 个 Toffee test；fixed DUT 保持 response ID，pre-PR 仍是 elaboration/interface failure。 |
| 04 readBurst | formal-first full demo 中先 `RunSkillScript`，再 `RunTestCases`。 | 由于已有人工校正 Toffee 环境，no-formal flow 可通过 `RunTestCases` 完成动态复现。 |

该对照说明：UCAgent 原始流程擅长组织、读取和执行已有动态测试；一旦人工补齐 Picker/Toffee harness，no-formal UCAgent 可以完整跑动态后端。形式验证 skill 则进一步为 agent 增加了可执行的 counterexample 搜索后端，尤其适合先定位窄时序窗口，再把结果转为 directed dynamic regression。

## 场景 5：全 Cache 覆盖闭环计划

05 不是第五个 bug，而是面向完整工业级验证的计划级闭环。它回答“为什么当前没有全 Cache 覆盖率，以及如何得到全 Cache 覆盖率”：

- 人工定义 coverage plan、CRV 场景族、scoreboard oracle 和 coverage database。
- UCAgent 读取计划并通过官方 `RunTestCases` 执行计划自检。
- Picker/Toffee 在后续实现阶段负责真实 DUT 导出、动态激励、scoreboard 与 coverage 采集。
- `generic-formal` skill 继续承担 ready/valid、flush、dirty eviction 等窄窗口性质搜索。

详细步骤和分工见 `docs/full_cache_coverage_plan.md`。

## 推荐复现入口

```bash
source .ucagent_env
bash scripts/run_cases.sh --case all --with-formal
```

如果评审时不希望消耗 LLM token，可以运行：

```bash
bash scripts/run_cases.sh --case all --with-formal --smoke
bash scripts/run_cases.sh --case all --no-formal --smoke
```

`--smoke` 不调用 API；真实 UCAgent 运行证据见 `reports/91_ucagent_skill_evidence.md`。
