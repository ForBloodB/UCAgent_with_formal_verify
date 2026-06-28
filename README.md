# UCAgent with Formal Verify

面向 Verilog/SystemVerilog 与 NutShell Cache 的可复现验证工程。项目的核心创新是把 SymbiYosys 形式验证封装成 UCAgent 可调用的通用 skill，让 agent 在原有 Picker/Toffee 动态验证流程之前，先具备“自动搜索 bounded counterexample”的能力。

## 特性

- 通用 Verilog formal 入口：任意可被 Yosys/Verilator 解析的 RTL 都可进入 smoke 或用户自定义 property 验证。
- UCAgent skill：`src/ucagent_skills/generic-formal`，兼容官方 UCAgent `ListSkill -> ReadTextFile -> RunSkillScript -> SetSkillUsage` 流程。
- 五个可复现案例：01 通用能力证明，02/03 真实 NutShell 历史 bug，04 latest candidate bug，05 latest-only UCAgent + formal skill 覆盖闭环。
- 04 提供动态 VCD/FST 与波形截图；05 声明的 15 个 latest Cache functional coverage points 达到 15/15。

## 目录结构

```text
src/                         通用验证工具、UCAgent skill、runner helper
tests/cases/                 01-05 可复现案例
tests/ucagent_workspaces/    UCAgent 官方 workspace
scripts/                     公开入口脚本
scripts/internal/            案例内部脚本
docs/                        用户文档与比赛报告
reports/                     本轮本地复现结果
docker/                      formal Dockerfile
```

## 环境构建

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

检查工具链：

```bash
yosys -V
verilator --version
conda run -n ucagent python -c "import ucagent, toffee, toffee_test"
```

构建 formal Docker fallback：

```bash
docker build -f docker/formal.Dockerfile -t nutshell-cache-formal:latest .
```

## 验证任意 Verilog 模块

只做本地 smoke，不调用 API：

```bash
bash scripts/verify_verilog.sh \
  --rtl path/to/dut.sv \
  --top MyDut \
  --depth 8 \
  --smoke
```

使用用户提供的 formal harness/property：

```bash
bash scripts/verify_verilog.sh \
  --rtl path/to/dut.sv \
  --property path/to/my_property.sv \
  --top my_formal_top \
  --depth 32 \
  --smoke
```

说明：basic smoke 只能证明 RTL 能进入工具链；功能正确性需要 property、reference model 或人工确认后的 harness。

## 复现 01-05

本地 smoke，不调用 API：

```bash
bash scripts/run_cases.sh --case all --with-formal --smoke
```

正式 UCAgent API 流程：

```bash
source .ucagent_env
bash scripts/run_cases.sh --case 02 --with-formal
bash scripts/run_cases.sh --case 03 --with-formal
bash scripts/run_cases.sh --case 04 --with-formal
bash scripts/run_cases.sh --case 05
```

参数：

```text
--case all|01|02|03|04|05
--with-formal    默认，运行 formal/skill 路径
--no-formal      动态 Toffee 路径；05 不支持该模式
--smoke          不调用 LLM/API
```

## 本地复现结果

| Case | 定位 | 本轮结果 |
| --- | --- | --- |
| 01 | 通用 formal skill 能力证明 | buggy `FAIL`，fixed `PASS` |
| 02 | NutShell PR21 历史 bug | pre `FAIL`，fixed `PASS`，UCAgent 调用 `generic-formal` |
| 03 | NutShell PR74 历史接口 bug | pre `ELAB_FAIL/ERROR`，fixed `PASS`，UCAgent 调用 `generic-formal` |
| 04 | latest L2 readBurst ready/valid candidate bug | formal assert `FAIL`，cover `PASS`，Toffee `DYNAMIC_REPRODUCED`，场景覆盖 `5/5` |
| 05 | latest-only formal-enabled UCAgent 覆盖闭环 | 15/15 declared functional coverage，latest candidate bug 汇总 |

05 的 `100%` 只表示本仓库声明的 15 个 latest NutShell Cache functional coverage points 全部闭合，不代表完整 NutShell SoC 或 RTL line/toggle 覆盖率 100%。

## 报告入口

- [比赛提交报告](docs/competition_report.md)
- [形式验证与 UCAgent 集成说明](docs/formal_ucagent_integration.md)
- [添加新的 Verilog/SystemVerilog 模块](docs/adding_new_verilog_module.md)
- [本轮复现总览](reports/00_overview.md)
- [04 latest candidate bug 报告](reports/04_l2_readburst.md)
- [05 latest coverage 报告](reports/05_full_cache_coverage_plan.md)
- [05 latest 可疑 bug 汇总](reports/05_ucagent_bug_candidates.md)

## License

Apache 2.0. See [LICENSE](LICENSE).
