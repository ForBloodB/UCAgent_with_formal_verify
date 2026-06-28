# 复现指南

以下命令均在仓库根目录执行。

## 公开入口

本项目的公开复现入口只有两个：

```bash
bash scripts/verify_verilog.sh --rtl path/to/dut.sv --top MyDut --smoke
bash scripts/run_cases.sh --case all --with-formal --smoke
```

需要真实调用 UCAgent API 时去掉 `--smoke`，并先执行：

```bash
source .ucagent_env
```

下面列出的 `scripts/internal/*` 是各案例的内部实现脚本，用于说明每个阶段如何落地；新用户优先使用 `scripts/run_cases.sh`。

## 01 Generic Formal Proof

关键文件：

- `tests/cases/01_generic_formal_proof/rtl/adder_buggy.sv`
- `tests/cases/01_generic_formal_proof/rtl/adder_fixed.sv`
- `tests/cases/01_generic_formal_proof/formal/adder_formal.sv`
- `tests/cases/01_generic_formal_proof/formal/adder_buggy.yaml`
- `tests/cases/01_generic_formal_proof/formal/adder_fixed.yaml`
- `src/ucagent_skills/generic-formal/scripts/run_formal.py`

命令：

```bash
bash scripts/run_cases.sh --case 01 --with-formal --smoke
```

预期：`adder_buggy` 为 `FAIL`，`adder_fixed` 为 `PASS`。

## 02 PR21 MMIO Prefetch

关键文件：

- `tests/cases/02_pr21_mmio_prefetch/formal/Pr21CacheFormalDut.scala`
- `tests/cases/02_pr21_mmio_prefetch/formal/pr21_nutshell_cache_mmio_prefetch_formal.sv`
- `tests/cases/02_pr21_mmio_prefetch/formal/nutshell_pr21_real_cache_pre.sby`
- `tests/cases/02_pr21_mmio_prefetch/formal/nutshell_pr21_real_cache_fixed.sby`
- `scripts/internal/20_prepare_pr21_real_cache.sh`
- `scripts/internal/21_run_pr21_real_cache_formal.sh`

命令：

```bash
bash scripts/run_cases.sh --case 02 --with-formal --smoke
```

预期：pre-PR 真实 NutShell Cache 为 `FAIL`，fixed 真实 NutShell Cache 为 `PASS`。

UCAgent 调用同一套 `generic-formal` skill：

```bash
source .ucagent_env
bash scripts/run_cases.sh --case 02 --with-formal
```

预期：消息日志包含 `RunSkillScript` 和 `SetSkillUsage`，报告中 pre `FAIL/OK`、fixed `PASS/OK`。

Picker/Toffee 动态后端，不使用 formal skill：

```bash
source .ucagent_env
bash scripts/run_cases.sh --case 02 --no-formal
```

预期：UCAgent 消息日志包含真实 `RunTestCases` 工具调用，不包含真实 `RunSkillScript` 工具调用；2 个 pytest 通过。报告 `reports/02_pr21_toffee_coverage.md` 分类为 `DYNAMIC_PRE_REPRODUCED_FIXED_EDGE_SAMPLING_LIMIT`，表示 pre 风险窗口可动态复现，fixed 对照以 formal PASS 为准。

## 03 PR74 Cache IO idBits

关键文件：

- `tests/cases/03_pr74_cache_io_idbits/formal/Pr74CacheIOFormalDut.scala`
- `tests/cases/03_pr74_cache_io_idbits/formal/pr74_nutshell_cache_io_idbits_formal.sv`
- `tests/cases/03_pr74_cache_io_idbits/formal/nutshell_pr74_real_cache_fixed.sby`
- `scripts/internal/30_prepare_pr74_real_cache.sh`
- `scripts/internal/31_run_pr74_real_cache_formal.sh`

命令：

```bash
bash scripts/run_cases.sh --case 03 --with-formal --smoke
```

预期：pre-PR elaboration 因缺少 `id` field 失败；fixed generation 与 fixed formal 均通过。

UCAgent 调用同一套 `generic-formal` skill：

```bash
source .ucagent_env
bash scripts/run_cases.sh --case 03 --with-formal
```

预期：消息日志包含 `RunSkillScript` 和 `SetSkillUsage`，报告中 pre `ERROR/OK`、fixed `PASS/OK`。

Picker/Toffee 动态后端，不使用 formal skill：

```bash
source .ucagent_env
bash scripts/run_cases.sh --case 03 --no-formal
```

预期：pre-PR generation/elaboration 失败被记录为历史接口 bug；fixed Python DUT 由 Picker 导出成功；UCAgent 消息日志包含真实 `RunTestCases` 工具调用，不包含真实 `RunSkillScript` 工具调用；1 个 pytest 通过。

## 04 L2 ReadBurst Ready/Valid Deadlock

关键文件：

- `tests/cases/04_l2_readburst_hit_ready_valid_deadlock/scripts/prepare_latest_l2_readburst.py`
- `tests/cases/04_l2_readburst_hit_ready_valid_deadlock/formal/l2_readburst_assert.yaml`
- `tests/cases/04_l2_readburst_hit_ready_valid_deadlock/formal/l2_readburst_cover.yaml`
- `tests/cases/04_l2_readburst_hit_ready_valid_deadlock/formal/l2_readburst_hit_ready_deadlock_assert.sby`
- `tests/cases/04_l2_readburst_hit_ready_valid_deadlock/formal/l2_readburst_hit_ready_deadlock_cover.sby`
- `tests/ucagent_workspaces/04_l2_readburst_deadlock/config_full_demo.yaml`
- `tests/ucagent_workspaces/04_l2_readburst_deadlock/config.yaml`
- `src/ucagent_skills/generic-formal/SKILL.md`

推荐 UCAgent formal-first 完整演示：

```bash
source .ucagent_env
bash scripts/run_cases.sh --case 04 --with-formal
```

预期：UCAgent 在同一次 mission 中先通过 `RunSkillScript` 调用 `generic-formal`；若 formal assert 发现 ready/valid 反例，先写出复现方式；随后继续官方 `RunTestCases` Toffee/pytest 流程，得到 1 个 pytest 通过、04 场景 setup coverage `5/5 = 100%`。

仅运行 formal skill：

```bash
bash scripts/run_cases.sh --case 04 --with-formal --smoke
```

动态复现：

```bash
bash scripts/run_cases.sh --case 04 --with-formal --smoke
```

Toffee 场景覆盖率：

```bash
bash scripts/run_cases.sh --case 04 --no-formal --smoke
```

UCAgent Toffee flow：

```bash
source .ucagent_env
bash scripts/run_cases.sh --case 04 --no-formal
```

预期：Toffee directed test 使用 Picker 导出的真实 Python DUT，04 场景 setup coverage 为 `5/5 = 100%`，UCAgent Toffee flow 通过 `RunTestCases` 得到 1 个 pytest 通过、6/6 check points 命中。

## 三案例 No-Formal UCAgent 对照

```bash
source .ucagent_env
bash scripts/run_cases.sh --case all --no-formal
```

预期：

- 02/03/04 都不调用真实 `RunSkillScript` 工具调用。
- 02 通过 `RunTestCases` 跑 2 个 Toffee tests。
- 03 通过 `RunTestCases` 跑 1 个 Toffee test。
- 04 通过 `RunTestCases` 完成 Toffee directed dynamic replay。
