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

## 一键复现

推荐只使用一个入口脚本。若本地已有 Docker 镜像，它会直接复用；若没有镜像，它会自动从零构建。默认模式会读取 `.ucagent_env`，真实调用 UCAgent API，并在容器中复现 01-05：

```bash
cp .ucagent_env.example .ucagent_env
vim .ucagent_env

bash scripts/reproduce.sh
```

如果要强制删除缓存后重新构建镜像并完整复现 01-05：

```bash
bash scripts/reproduce.sh --case all --rebuild
```

如果别人已经下载了预构建镜像，也可以不依赖宿主机 Python/Conda，直接运行镜像内置的项目源码：

```bash
docker run --rm --env-file .ucagent_env ucagent-with-formal-verify:latest \
  bash scripts/run_cases.sh --case all --with-formal
```

复现单个案例：

```bash
bash scripts/reproduce.sh --case 01
bash scripts/reproduce.sh --case 05
```

本地快速检查不调用任何 LLM/API，显式使用 `--smoke`：

```bash
bash scripts/reproduce.sh --case all --smoke
bash scripts/reproduce.sh --case 05 --smoke
```

注意：默认模式和 `--api` 模式会真实调用 UCAgent API。05 的 formal 阶段还需要准备 latest NutShell Cache wrapper；如果运行环境无法访问 upstream Git 仓库，脚本会把它报告为基础设施阻塞，而不会伪装成验证结论。

常用参数：

```text
--case all|01|02|03|04|05  选择案例
--smoke                    本地复现，不调用 API
--api                      调用真实 UCAgent API，默认模式
--rebuild                  强制从零重建 Docker 镜像
--skip-build               要求使用已有 Docker 镜像，不自动构建
--skip-tool-smoke          跳过工具链 smoke
```

底层脚本仍保留给调试使用：

```bash
bash scripts/docker_build.sh
bash scripts/docker_run.sh bash scripts/run_cases.sh --case 05 --with-formal --smoke
```

完整证据链会写入 `reports/` 和 `reports/artifacts/`，包括 formal 反例、PR21/PR74 历史复现、04 ready/valid 波形、Picker/Toffee pytest 报告，以及 05 latest-only 覆盖闭合和人工 Verilog 波形后验结果。

## 案例说明

| Case | 目的 | 预期结果 |
| --- | --- | --- |
| 01 | 通用 formal skill 证明 | buggy adder `FAIL`，fixed adder `PASS` |
| 02 | NutShell PR21 历史 MMIO prefetch 问题 | pre `FAIL`，fixed `PASS` |
| 03 | NutShell PR74 CacheIO idBits/interface 问题 | pre elaboration `FAIL/ERROR`，fixed `PASS` |
| 04 | latest L2 readBurst ready/valid candidate | formal assert `FAIL`，cover `PASS`，动态场景可复现 |
| 05 | latest-only UCAgent + formal skill 覆盖闭环 | 15/15 declared functional coverage；UCAgent hypothesis 经过人工 Verilog 波形复查 |

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

- `docs/competition_report.md`
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
