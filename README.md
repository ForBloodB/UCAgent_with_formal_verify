# NutShell Cache Verify

一个面向 Verilog/SystemVerilog 的轻量验证工程。项目提供通用 formal 验证入口、UCAgent `generic-formal` skill，以及五个可复现案例。

## Features

- 对任意可被 Yosys/Verilator 解析的 RTL 运行 lint/elaboration/basic formal smoke。
- 支持用户提供 SVA/formal harness 后运行真正功能性质验证。
- 将 SymbiYosys 封装为 UCAgent 可调用的通用 skill：`src/ucagent_skills/generic-formal`。
- `tests/cases/01_generic_formal_proof` 证明通用能力：buggy adder 失败，fixed adder 通过。
- NutShell Cache 案例保留为实战样例：PR21、PR74、L2 readBurst ready/valid candidate bug。
- 05 将 PR21、PR74、04 纳入声明功能覆盖数据库，关闭 15 个 functional coverage points。

## Layout

```text
src/                         通用验证工具、UCAgent skill、runner helper
tests/cases/                 五个可复现案例与 Toffee/formal 资产
tests/ucagent_workspaces/    UCAgent 官方 workspace
scripts/                     公开入口脚本
scripts/internal/            案例内部复现脚本
docs/                        用户文档与比赛报告
reports/                     本地复现结果与轻量报告
docker/                      formal/UCAgent Dockerfile
```

## Setup

准备官方依赖源码：

```bash
bash scripts/setup_sources.sh
```

配置 UCAgent API：

```bash
cp .ucagent_env.example .ucagent_env
vim .ucagent_env
source .ucagent_env
```

检查本地工具：

```bash
yosys -V
verilator --version
conda run -n ucagent python -c "import ucagent, toffee, toffee_test"
```

如需 formal Docker fallback：

```bash
docker build -f docker/formal.Dockerfile -t nutshell-cache-formal:latest .
```

## Verify Any Verilog Module

Basic smoke，不调用 API：

```bash
bash scripts/verify_verilog.sh \
  --rtl path/to/dut.sv \
  --top MyDut \
  --depth 8 \
  --smoke
```

带用户提供的 formal harness/property：

```bash
bash scripts/verify_verilog.sh \
  --rtl path/to/dut.sv \
  --property path/to/my_property.sv \
  --top my_formal_top \
  --define OPTIONAL_MACRO \
  --depth 32 \
  --smoke
```

说明：basic smoke 只证明 RTL 能进入验证工具链；功能正确性需要 property、reference model 或人工确认后的 harness。去掉 `--smoke` 后，脚本会先跑本地验证，再调用真实 UCAgent API 读取 `generic-formal` skill、复跑同一个 YAML case，并给出后续性质建议。

## Run Included Cases

本地 smoke，不调用 API：

```bash
bash scripts/run_cases.sh --case all --with-formal --smoke
bash scripts/run_cases.sh --case all --no-formal --smoke
```

严格模式会调用真实 UCAgent API：

```bash
source .ucagent_env
bash scripts/run_cases.sh --case 04 --with-formal
```

参数：

```text
--case all|01|02|03|04|05
--with-formal    默认，运行 formal/skill 路径
--no-formal      运行动态 Toffee 路径
--smoke          不调用 LLM/API
```

## Local Results

| Case | Role | Local result |
| --- | --- | --- |
| 01 | 通用 formal 能力证明 | buggy `FAIL`，fixed `PASS` |
| 02 | NutShell PR21 历史 bug | pre `FAIL`，fixed `PASS` |
| 03 | NutShell PR74 历史接口 bug | pre `ELAB_FAIL`，fixed `PASS` |
| 04 | latest L2 readBurst candidate bug | formal assert `FAIL`，cover `PASS`，dynamic `DYNAMIC_REPRODUCED` |
| 05 | 全 Cache 声明功能覆盖闭环 | 15/15 functional coverage points implemented；PR21/PR74/04 bug points 纳入 coverage DB |

报告入口：

- `docs/submission_report.md`
- `docs/adding_new_verilog_module.md`
- `docs/full_cache_coverage_plan.md`
- `docs/formal_ucagent_integration.md`
- `docs/full_cache_coverage_implementation.md`
- `docs/reports.md`
- `reports/00_overview.md`
- `reports/05_ucagent_bug_candidates.md`
- `reports/91_ucagent_skill_evidence.md`

## License

Apache 2.0. See `LICENSE`.
