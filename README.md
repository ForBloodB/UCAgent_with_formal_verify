# UCAgent with Formal Verify

把形式验证作为 UCAgent 的一个通用工具接入硬件验证流程。本项目的重点不是重新实现 UCAgent、Picker 或 Toffee，而是提供一个可复现的最小工程：UCAgent 可以先调用 `generic-formal` skill 做 bounded formal diagnosis，发现反例后继续运行原本的 Picker/Toffee/pytest 动态验证。

## 项目重点

- `generic-formal` 是通用 skill：任意可被 Yosys/SymbiYosys 处理的 Verilog/SystemVerilog 模块，都可以通过 YAML 描述 RTL、top、depth、期望结果和报告路径。
- 形式验证不替代动态仿真：它用于快速暴露窄窗口协议问题；Toffee/pytest 用于把场景固化为可维护回归。
- Docker 是推荐复现方式：镜像内包含 UCAgent、Picker、Toffee、Yosys、SymbiYosys、Z3、Verilator、Icarus Verilog、Mill/Java。
- 01 是通用能力证明；02/03 是 NutShell 历史真实问题；04 是 latest NutShell Cache ready/valid candidate；05 是 latest-only 覆盖闭环和 UCAgent bug hypothesis 人工复查。

## 目录

```text
src/                         通用 formal runner、UCAgent skill、helper
tests/cases/                 01-05 复现案例
tests/ucagent_workspaces/    UCAgent workspace
scripts/                     公开入口与内部复现脚本
docker/                      一键复现镜像
reports/                     轻量结果与波形证据
```

## 构建环境

默认构建不使用 Docker layer cache，适合模拟别人从零复现：

```bash
bash scripts/docker_build.sh
```

快速检查镜像和项目 smoke：

```bash
bash scripts/docker_smoke.sh
```

如需在容器中运行任意命令：

```bash
bash scripts/docker_run.sh bash scripts/run_cases.sh --case 01 --with-formal --smoke
```

开发 Dockerfile 时才建议显式启用缓存：

```bash
UCAGENT_FORMAL_DOCKER_CACHE=1 bash scripts/docker_build.sh
```

## 复现案例

本地 smoke 不调用 API：

```bash
bash scripts/docker_run.sh bash scripts/run_cases.sh --case all --with-formal --smoke
```

单独复现某个案例：

```bash
bash scripts/docker_run.sh bash scripts/run_cases.sh --case 01 --with-formal --smoke
bash scripts/docker_run.sh bash scripts/run_cases.sh --case 02 --with-formal --smoke
bash scripts/docker_run.sh bash scripts/run_cases.sh --case 03 --with-formal --smoke
bash scripts/docker_run.sh bash scripts/run_cases.sh --case 04 --with-formal --smoke
bash scripts/docker_run.sh bash scripts/run_cases.sh --case 05 --with-formal --smoke
```

正式 UCAgent API 流程需要配置 `.ucagent_env`：

```bash
cp .ucagent_env.example .ucagent_env
vim .ucagent_env

bash scripts/docker_run.sh bash scripts/run_cases.sh --case 04 --with-formal
bash scripts/docker_run.sh bash scripts/run_cases.sh --case 05
```

参数：

```text
--case all|01|02|03|04|05
--with-formal    默认，运行 formal/skill 路径
--no-formal      运行动态 Toffee 路径；05 不支持该模式
--smoke          不调用 LLM/API
```

## 案例说明

| Case | 目的 | 预期结果 |
| --- | --- | --- |
| 01 | 通用 formal skill 证明 | buggy adder `FAIL`，fixed adder `PASS` |
| 02 | NutShell PR21 历史 MMIO prefetch 问题 | pre `FAIL`，fixed `PASS` |
| 03 | NutShell PR74 CacheIO idBits/interface 问题 | pre elaboration `FAIL/ERROR`，fixed `PASS` |
| 04 | latest L2 readBurst ready/valid candidate | formal assert `FAIL`，cover `PASS`，动态场景可复现 |
| 05 | latest-only UCAgent + formal skill 覆盖闭环 | 15/15 declared functional coverage；UCAgent hypothesis 经过人工 Verilog 波形复查 |

05 的 `100%` 只表示本仓库声明的 15 个 latest NutShell Cache functional coverage points 全部闭合，不代表完整 SoC 或 RTL line/toggle coverage 100%。

## 任意 Verilog 模块

只做工具链 smoke：

```bash
bash scripts/docker_run.sh bash scripts/verify_verilog.sh \
  --rtl path/to/dut.sv \
  --top MyDut \
  --depth 8 \
  --smoke
```

带用户自定义 property/harness：

```bash
bash scripts/docker_run.sh bash scripts/verify_verilog.sh \
  --rtl path/to/dut.sv \
  --property path/to/property.sv \
  --top MyFormalTop \
  --depth 32 \
  --smoke
```

边界：basic smoke 只能证明 RTL 能进入 formal 工具链；功能正确性仍需要 property、reference model、scoreboard 或人工确认后的 harness。

## 关键报告

- `reports/04_l2_readburst.md`
- `reports/assets/04_l2_readburst_ready_valid_waveform.png`
- `reports/05_full_cache_coverage_plan.md`
- `reports/05_ucagent_bug_candidates.md`
- `reports/05_manual_verilog_validation.md`

## 清理本地生成物

```bash
bash scripts/clean_local_env.sh
```

该脚本只清理本仓库内的 `third_party/`、venv、formal run dir、UCAgent cache 和动态二进制，不会删除全局 conda、系统工具或 `.ucagent_env`。

## License

Apache 2.0. See [LICENSE](LICENSE).
