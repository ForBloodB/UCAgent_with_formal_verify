# 比赛提交报告：NutShell Cache 形式验证与 UCAgent Skill 集成

## 1. 项目定位

本项目围绕 NutShell Cache 构建了五个可复现验证案例：

| 编号 | 案例 | 性质 | 当前结论 |
| --- | --- | --- | --- |
| 01 | `adder_formal_skill` | 人工注入小 bug，用于验证通用 formal skill | buggy `FAIL`，fixed `PASS` |
| 02 | `pr21_mmio_prefetch` | 真实 NutShell PR #21 历史 bug | pre-PR `FAIL`，fixed `PASS` |
| 03 | `pr74_cache_io_idbits` | 真实 NutShell PR #74 历史接口 bug | pre-PR `ELAB_FAIL`，fixed formal `PASS` |
| 04 | `l2_readburst_hit_ready_valid_deadlock` | latest upstream 候选 ready/valid bug | formal assert `FAIL`，cover `PASS`，Toffee coverage `100%`，动态复现 `DYNAMIC_REPRODUCED` |
| 05 | `full_cache_coverage_plan` | 全 Cache 声明功能覆盖闭环 | UCAgent `RunTestCases` 通过；15 个 coverage points：15 implemented、0 partial、0 gap |

核心目标不是用 AI 直接“刷”测试，而是把形式验证变成 UCAgent 可调用的工具能力，让 agent 在验证过程中拥有更强的分析和搜索手段。04 的推荐演示采用 formal-first 流程：UCAgent 先调用 `generic-formal` 做前置诊断；如果发现反例，先写出复现方式；随后仍继续原本官方 Toffee/pytest `RunTestCases` 流程，形成“发现问题 -> 动态复现/回归”的闭环。

最新补充：02、03 也已经通过真实 API 调用同一套 `generic-formal` skill。随后又把 02、03 从“只能静态回顾”的 no-formal baseline 升级为 Picker/Toffee 动态后端：UCAgent 官方模板先给出 `unity_test/tests` 草稿结构，人工将草稿接入真实 Picker DUT、scoreboard、memory mock 与 coverage，最后再次用真实 API 让 UCAgent 调 `RunTestCases` 完整执行。结果显示：没有 formal skill 时，UCAgent 仍可运行人工完善后的动态后端；但反例搜索、边界条件收敛和 oracle 校正仍主要依赖人工与 formal 结果。

## 2. 覆盖率说明

当前项目没有声称已经采集完整 Toffee functional coverage，因此没有提交“Cache 全功能覆盖率 90%”这类百分数。当前覆盖率采用更诚实的工程口径：

- **Formal property coverage**：是否对目标性质建立了 assertion，并在 bounded depth 内得到预期结果。
- **Formal cover reachability**：是否证明目标时序窗口可达。
- **Directed dynamic scenario coverage**：是否通过动态仿真复现 formal 发现的场景。

| 案例 | 功能覆盖率百分比 | 当前覆盖证据 | 说明 |
| --- | --- | --- | --- |
| 01 adder | 未采集 Toffee functional coverage | 1 个 assertion 检查 `y == a + b`；1 个 cover 覆盖 `a=0xf,b=0x1`；depth=2 | 对 4-bit adder 性质是符号化检查，不是随机测试采样百分比。 |
| 02 PR21 | Toffee 场景 coverage `5/5 = 100%`，UCAgent report check points `6/6` 命中 | 真实 Cache wrapper；formal pre-PR `FAIL`/fixed `PASS`；Toffee pre 动态复现风险窗口 | 覆盖目标是“MMIO prefetch 不应破坏已有 normal pipeline entry”。fixed 动态 probe 读数存在后沿采样限制，不作为 fixed 失败证据。 |
| 03 PR74 | Toffee 场景 coverage `5/5 = 100%`，UCAgent report check points `5/5` 命中 | pre-PR elaboration 失败；fixed Picker DUT 动态回归保持 response ID；fixed formal depth=24 PASS | 覆盖目标是 `idBits=4` 时 CacheIO 必须暴露并保持 ID。pre-PR 不是可运行动态 DUT，而是接口/elaboration 失败。 |
| 04 L2 readBurst | 04 场景 setup coverage `5/5 = 100%` | Picker 导出真实 Python DUT；Toffee/pytest 命中 miss/refill/same-address hit/ready-low 全部 setup bins，并命中 bug observation bin | 覆盖目标是 `readBurst hit + resp_ready=0` 的 ready/valid 窄窗口，不代表全 Cache coverage。 |

结论：当前提交证明了四个高价值场景的 formal/directed 覆盖闭环，并且 04 已补齐 Picker/Toffee 场景级 functional coverage。05 进一步把声明的 15 个 Cache functional coverage points、CRV、scoreboard 和 coverage database 做成可执行闭环，并纳入 PR21/PR74/04 bug points。项目仍不声称完成完整 RTL line/toggle 覆盖；后续若冲击工业级 90%+ 指标，需要继续接入 UCIS/Verilator 覆盖合并和更大规模真实 DUT CRV regression。

## 3. 每个复现脚本的作用

| 脚本 | 作用 |
| --- | --- |
| `scripts/internal/00_setup_ucagent_sources.sh` | 下载或更新官方 UCAgent、Example-NutShellCache、picker 到 `third_party/`，并记录 commit。 |
| `scripts/internal/01_install_ucagent_venv.sh` | 基于 `third_party/` 创建本地 Python venv，用于安装 UCAgent/picker；当前主流程优先使用已有 conda `ucagent` 环境。 |
| `scripts/internal/10_run_adder_formal_skill_smoke.sh` | 运行 01 adder buggy/fixed 两个 YAML formal case，证明 `generic-formal` 对任意小 RTL 模块可用。 |
| `scripts/internal/20_prepare_pr21_real_cache.sh` | 拉取 PR21 pre/fixed NutShell 源码，插入 wrapper/probes，生成真实 Cache RTL。 |
| `scripts/internal/21_run_pr21_real_cache_formal.sh` | 对 PR21 pre/fixed 真实 Cache 运行 SymbiYosys，验证 pre FAIL、fixed PASS。 |
| `scripts/internal/22_run_pr21_ucagent_formal_skill.sh` | 使用真实 API 启动 UCAgent，通过 `generic-formal` skill 运行 PR21 pre/fixed。 |
| `scripts/internal/23_run_pr21_ucagent_original_no_formal.sh` | 使用真实 API 启动原始 UCAgent，不带 formal skill，对 PR21 做静态回顾对照。 |
| `scripts/internal/24_prepare_pr21_picker_dut.sh` | 用 Picker 将 PR21 pre/fixed 真实 Cache wrapper 导出为 Python DUT。 |
| `scripts/internal/25_run_pr21_toffee_directed.sh` | 直接运行 02 Toffee directed replay，生成场景 coverage 与 HTML 报告。 |
| `scripts/internal/26_run_pr21_ucagent_toffee.sh` | 使用真实 API 启动 UCAgent no-formal Toffee 动态后端，调用 `RunTestCases` 跑 02。 |
| `scripts/internal/30_prepare_pr74_real_cache.sh` | 拉取 PR74 pre/fixed NutShell 源码和 difftest 依赖，安装 wrapper，生成真实 Cache RTL。 |
| `scripts/internal/31_run_pr74_real_cache_formal.sh` | 复现 PR74 pre elaboration fail，并验证 fixed generation/formal PASS。 |
| `scripts/internal/32_run_pr74_ucagent_formal_skill.sh` | 使用真实 API 启动 UCAgent，通过 `generic-formal` skill 运行 PR74 pre/fixed。 |
| `scripts/internal/33_run_pr74_ucagent_original_no_formal.sh` | 使用真实 API 启动原始 UCAgent，不带 formal skill，对 PR74 做静态回顾对照。 |
| `scripts/internal/34_prepare_pr74_picker_dut.sh` | 记录 PR74 pre-PR elaboration 期望失败，并用 Picker 导出 fixed Python DUT。 |
| `scripts/internal/35_run_pr74_toffee_directed.sh` | 直接运行 03 fixed-DUT Toffee ID-preservation 回归。 |
| `scripts/internal/36_run_pr74_ucagent_toffee.sh` | 使用真实 API 启动 UCAgent no-formal Toffee 动态后端，调用 `RunTestCases` 跑 03。 |
| `scripts/internal/40_run_l2_readburst_ucagent_formal.sh` | 启动 UCAgent，强制通过 `generic-formal` skill 运行 04 的 assert/cover formal case，并保存 UCAgent 工具调用日志。 |
| `scripts/internal/41_run_l2_readburst_dynamic.sh` | 使用 iverilog/vvp 对 04 做 public-IO directed dynamic replay，生成日志和 VCD 波形。 |
| `scripts/internal/42_prepare_l2_readburst_picker_dut.sh` | 使用 Picker 将 latest `FreshCacheFormalDut.sv` 导出为 Python DUT，并启用 Verilator FST waveform/coverage。 |
| `scripts/internal/43_run_l2_readburst_toffee_directed.sh` | 运行 04 的 Toffee/pytest directed test，生成场景级 functional coverage、HTML 报告和 FST 波形。 |
| `scripts/internal/44_run_l2_readburst_ucagent_toffee.sh` | 启动 UCAgent 官方 `unity_test/tests` flow，运行同一套人工校正后的 Toffee 测试并归档日志。 |
| `scripts/internal/45_run_l2_readburst_ucagent_full_demo.sh` | 启动 UCAgent formal-first 完整演示：先调用 `generic-formal`，发现问题后写复现方式，再继续官方 `RunTestCases` Toffee 流程。 |
| `scripts/internal/46_run_three_case_ucagent_original_no_formal.sh` | 使用真实 API 对 02、03、04 运行无 formal skill 的 UCAgent Toffee 动态后端对照。 |
| `scripts/internal/50_run_full_cache_coverage_plan.sh` | 运行 05 声明功能覆盖闭环；`--smoke` 本地 pytest，严格模式可选择 formal-first 或 no-formal UCAgent `RunTestCases`。 |
| `scripts/internal/90_run_all_kept_cases.sh` | 一键串行运行保留案例；设置 `RUN_UCAGENT_FULL_DEMO=1`、`RUN_UCAGENT_SKILL_EXTENDED=1`、`RUN_UCAGENT_ORIGINAL_COMPARE=1` 可打开更多 UCAgent 流程。 |

## 4. 04 动态仿真波形位置

04 的动态仿真波形文件为：

```text
reports/artifacts/04_l2_readburst/artifacts/dynamic_readburst_ready_deadlock.vcd
```

完整绝对路径为：

```text
/home/distortionk/WorkSpace/VCS/NutShellCacheVerify/reports/artifacts/04_l2_readburst/artifacts/dynamic_readburst_ready_deadlock.vcd
```

配套文件：

```text
reports/artifacts/04_l2_readburst/artifacts/dynamic_readburst_ready_deadlock.log
reports/artifacts/04_l2_readburst/artifacts/dynamic_readburst_ready_deadlock.vvp
reports/artifacts/04_l2_readburst/dynamic_readburst_ready_deadlock.md
reports/artifacts/04_l2_readburst/toffee/l2_readburst_ready_deadlock.fst
reports/artifacts/04_l2_readburst/toffee/pytest_report/index.html
reports/04_l2_readburst_toffee_coverage.md
```

如需重新生成：

```bash
bash scripts/internal/41_run_l2_readburst_dynamic.sh
bash scripts/internal/42_prepare_l2_readburst_picker_dut.sh
bash scripts/internal/43_run_l2_readburst_toffee_directed.sh
```

## 5. 为什么形式验证应该成为 Agent Skill

硬件验证中，动态仿真擅长复现软件式测试流程，但对窄时序窗口、反压组合、协议死锁等场景常常依赖运气和大量随机测试。形式验证的优势是：

- 使用符号变量一次性覆盖大量输入组合；
- 可以在 bounded depth 内主动搜索反例；
- 可以用 cover 证明目标窗口是否可达；
- 对 ready/valid、pipeline 保持、ID 保持、无请求无响应等协议性质非常敏感；
- 能为动态测试提供最小反例和 directed replay 目标。

因此，形式验证非常适合作为 agent skill。核心思想是：

> 不期待 agent 自己凭空变成验证专家，而是人为给 agent 提供更强的工具箱。

在本项目中，人工将 SymbiYosys runner、YAML case schema、日志分类、Docker fallback 封装为 `generic-formal`。UCAgent 不需要理解所有底层命令细节，只需要按官方流程：

```text
ListSkill -> ReadTextFile -> RunSkillScript -> SetSkillUsage -> Complete -> Exit
```

就可以调用形式验证能力。这样 agent 的作用从“生成普通测试代码”扩展为“调用专业验证工具、读取结果、辅助定位 bug”。

04 的完整演示进一步说明：形式验证不是替代 UCAgent 原本流程，而是作为 agent 的前置诊断 skill。即使 formal 已经发现反例，UCAgent 仍继续跑 Toffee/pytest，将反例转化为可维护的动态回归测试。

## 6. 当前 Formal Skill 是否通用

当前活跃 skill 是：

```text
src/ucagent_skills/generic-formal
```

它是通用 skill，不是 04 专用 skill。证据如下：

- 01 adder 使用同一个 skill 运行普通小 RTL 模块。
- 02 PR21 使用同一个 skill 跑真实 NutShell 历史 pre/fixed SBY。
- 03 PR74 使用同一个 skill 捕获 pre elaboration/interface `ERROR`，并验证 fixed formal `PASS`。
- 04 NutShell L2 readBurst 使用同一个 skill 运行已有 SBY case。
- skill 的输入是 YAML，不绑定 NutShell、Cache、readBurst 或 PR21/PR74。
- YAML 支持两种形式：
  - 给出 `top`、`files`、`depth`，由 skill 自动生成 SBY；
  - 给出已有 `sby` 文件，并可通过 `prepare` 命令先准备源码或生成 RTL。

示例接口：

```yaml
name: my_module_case
top: my_formal_top
files:
  - rtl/my_module.sv
  - formal/my_module_formal.sv
depth: 32
expected: PASS
report: reports/my_module.md
```

或：

```yaml
name: existing_sby_case
sby: formal/my_existing_case.sby
depth: 64
expected: FAIL
prepare:
  - python3 scripts/prepare_my_design.py
report: reports/my_existing_case.md
```

需要注意：`generic-formal` 是通用 formal runner，不是自动性质生成器。它可以对任意 Verilog/SystemVerilog 模块运行形式验证，但前提是用户、验证工程师或 agent 已经提供了 formal harness、assert/assume/cover 或 SBY 文件。

## 7. 真实 API 运行的 UCAgent 对照结果

| Case | 带 `generic-formal` skill 的 UCAgent | 无 formal skill 的 UCAgent Toffee 动态后端 |
| --- | --- | --- |
| 02 PR21 | `reports/02_pr21_ucagent_formal_skill.md`：pre `FAIL/OK`，fixed `PASS/OK`。 | `reports/02_pr21_toffee_ucagent.md`：真实 API 调 `RunTestCases`，2 个 Toffee tests 通过。 |
| 03 PR74 | `reports/03_pr74_ucagent_formal_skill.md`：pre `ERROR/OK`，fixed `PASS/OK`。 | `reports/03_pr74_toffee_ucagent.md`：真实 API 调 `RunTestCases`，1 个 Toffee test 通过。 |
| 04 readBurst | `reports/04_l2_readburst_ucagent_full_demo.md`：先 formal，再 Toffee。 | `reports/04_l2_readburst_toffee_ucagent.md`：`RunTestCases` 动态复现。 |

消息日志证据：

- 02 skill：`reports/artifacts/02_pr21/ucagent_formal/logs/ucagent_pr21_formal_skill_messages.jsonl`
- 03 skill：`reports/artifacts/03_pr74/ucagent_formal/logs/ucagent_pr74_formal_skill_messages.jsonl`
- 02 no-formal Toffee：`reports/artifacts/02_pr21/toffee_ucagent/logs/ucagent_pr21_toffee_messages.jsonl`
- 03 no-formal Toffee：`reports/artifacts/03_pr74/toffee_ucagent/logs/ucagent_pr74_toffee_messages.jsonl`
- 04 no-formal Toffee：`reports/artifacts/04_l2_readburst/logs/ucagent_l2_readburst_toffee_messages.jsonl`

## 8. 最终结论

本项目已经展示了一个实用的“AI + 人工 + 形式验证工具”协作模型：

- 人工定义高价值验证目标和真实案例边界；
- UCAgent 通过 skill 流程调用专业 formal 工具；
- formal 快速发现反例或证明目标窗口可达；
- directed dynamic replay 将 formal 发现转化为可观察波形；
- 报告记录真实历史 bug、candidate bug、覆盖口径和剩余缺口。

这比“纯 AI 生成测试”更接近工业验证实践：AI 负责调用、组织和总结，人工负责策略、约束和工具赋能。
