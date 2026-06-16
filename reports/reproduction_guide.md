# 三案例复现指南

- Date: 2026-06-16
- Goal: 复现三个 cache bug case 的 formal、directed dynamic、UCAgent/Toffee 互补验证结果。

## 复现思路

本仓库用 `CaseBuggy` 和 `CaseFixed` 做 A/B 对照：

- `CaseBuggy` 表示历史旧 bug 或人工注入 bug。
- `CaseFixed` 表示修复后的正确行为。
- 正确的验证结果应是 `CaseBuggy` 失败、`CaseFixed` 通过。

这套结构能同时回答两个问题：

- 属性/测试是否真的能抓 bug：看 `CaseBuggy` 是否 FAIL。
- 属性/测试是否误报：看 `CaseFixed` 是否 PASS。

## 快速结果矩阵

| Case | Formal | Directed dynamic | UCAgent/Toffee |
| --- | --- | --- | --- |
| PR #21 MMIO prefetch | Buggy FAIL / fixed PASS | Buggy FAIL / fixed PASS | `INFRA_FAIL` in current run |
| PR #74 CacheIO idBits | Buggy FAIL / fixed PASS | Buggy FAIL / fixed PASS | Fixed PASS / buggy FAIL |
| Flush outstanding miss | Buggy FAIL / fixed PASS | Buggy FAIL / fixed PASS | Fixed PASS / buggy FAIL |

## 1. 环境准备

不要在终端打印 `.ucagent_env` 内容。只需要确认文件存在，并在运行 UCAgent 前 source：

```bash
source .ucagent_env
```

可选拉取官方参考源：

```bash
bash scripts/00_setup_ucagent_sources.sh
```

当前 UCAgent 实跑使用已有 conda 环境：

```bash
conda run -n ucagent python -c "import ucagent, toffee, toffee_test"
picker --version
verilator --version
```

## 2. 复现 Formal

本地有 SymbiYosys/Yosys/Z3 时：

```bash
bash scripts/24_run_three_case_formal.sh
```

没有本地 formal 工具链时使用 Docker fallback：

```bash
docker build -f docker/formal.Dockerfile -t nutshell-cache-formal:latest .
bash scripts/25_docker_run_three_case_formal.sh
```

期望报告：

```text
reports/formal_batch/three_case_formal.md
```

接受标准：六个任务全部符合预期，即三个 buggy FAIL、三个 fixed PASS。

## 3. 复现手写 Directed Dynamic

```bash
bash scripts/31_run_directed_three_cases.sh
```

期望报告：

```text
reports/directed_three_case_results.md
```

接受标准：三个 buggy pytest 失败、三个 fixed pytest 通过。这里的失败是预期失败，用于证明 directed test 能检出对应 bug。

## 4. 复现 UCAgent 官方流程风格运行

完整三案例：

```bash
source .ucagent_env
UCAGENT_TIMEOUT=900 UCAGENT_RUN_BUGGY_PROBE=0 UCAGENT_POLL_SEC=10 bash scripts/30_run_ucagent_three_cases.sh
```

单独复现已检出的两个 case：

```bash
source .ucagent_env
UCAGENT_CASE_FILTER=pr74_cache_io_idbits UCAGENT_TIMEOUT=900 UCAGENT_RUN_BUGGY_PROBE=0 bash scripts/30_run_ucagent_three_cases.sh
UCAGENT_CASE_FILTER=flush_outstanding_miss UCAGENT_TIMEOUT=900 UCAGENT_RUN_BUGGY_PROBE=0 bash scripts/30_run_ucagent_three_cases.sh
```

PR #21 在当前模型/环境 run 中是 UCAgent 生成阶段失败，不作为设计漏检结论：

```bash
source .ucagent_env
UCAGENT_CASE_FILTER=pr21_prefetch_mmio UCAGENT_TIMEOUT=900 UCAGENT_RUN_BUGGY_PROBE=0 bash scripts/30_run_ucagent_three_cases.sh
```

主要产物：

```text
reports/ucagent_three_case_results.md
reports/formal_vs_ucagent_comparison.md
reports/ucagent_logs/
reports/ucagent_artifacts/
```

## UCAgent 判定流程

`scripts/30_run_ucagent_three_cases.sh` 做了五步：

1. 调用 Picker 从 `rtl/CaseFixed.sv` 导出 Python DUT 包。
2. 调用 `scripts/32_seed_ucagent_case.sh` 预置官方 `unity_test/tests`、API、coverage 和 case prompt。
3. 运行 UCAgent，让它在 `unity_test/tests` 下生成或补强 pytest。
4. 将生成测试回放到 `CaseFixed`，应当 PASS。
5. 将同一组测试回放到 `CaseBuggy`，应当 FAIL。

UCAgent case 分类：

- `DETECTED`: fixed replay PASS 且 buggy replay FAIL。
- `MISSED`: fixed replay PASS 但 buggy replay PASS。
- `FALSE_POSITIVE`: fixed replay FAIL。
- `INFRA_FAIL`: Picker、pytest、UCAgent 生成或超时等基础设施问题。
- `BLOCKED_NO_LLM_ENV`: 缺少 LLM 环境变量。

## 当前结论

Formal 和手写 directed 已经完整覆盖三案例，均证明验证意图有效。UCAgent 在 PR #74 和 flush case 上把验证意图转成了可维护动态回归；PR #21 当前是 UCAgent 生成流程在 900 秒内没有完成 pytest 模板编辑，因此记录为 `INFRA_FAIL`。这正好体现互补性：formal 可以稳定给出短反例，UCAgent 更适合沉淀动态回归，但会受到模型路径探索和工具调用稳定性的影响。

