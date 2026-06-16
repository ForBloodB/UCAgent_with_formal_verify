# 三案例验证文件整理

- Date: 2026-06-16
- Scope: 当前仓库保留三个案例的 formal、directed dynamic、UCAgent/Toffee 验证闭环。

## 一句话入口

先读这四个结果文件：

- `reports/formal_batch/three_case_formal.md`: formal 三案例矩阵。
- `reports/directed_three_case_results.md`: 手写 directed pytest 矩阵。
- `reports/ucagent_three_case_results.md`: UCAgent 生成测试与回放矩阵。
- `reports/formal_vs_ucagent_comparison.md`: 三类验证的互补性总结。

## 源文件与生成物

| 路径 | 类型 | 用途 |
| --- | --- | --- |
| `formal/historical/*.sv` | 源文件 | 三个 compact formal litmus model。 |
| `formal/historical/*.sby` | 源文件 | SymbiYosys 任务配置；每个 case 有 buggy/fixed 两份。 |
| `formal/historical/*_{buggy,fixed}/` | 生成物 | SBY 运行目录，包含 PASS/FAIL、trace、solver log。 |
| `formal/nutshell_pr21_real/Pr21CacheFormalDut.scala` | 源文件 | PR #21 真实 NutShell `nutcore.Cache` wrapper generator。 |
| `formal/nutshell_pr21_real/*.sby` | 源文件 | PR #21 真实 Cache pre/fixed formal 配置。 |
| `formal/nutshell_pr21_real/generated/` | 生成物 | 从 PR #21 前后精确上游 commit 生成的真实 Cache Verilog。 |
| `ucagent_cases/*/rtl/CaseBuggy.sv` | 源文件 | 旧错误行为或人工注入错误行为的 DUT。 |
| `ucagent_cases/*/rtl/CaseFixed.sv` | 源文件 | 修复后的对照 DUT。 |
| `ucagent_cases/*/Makefile` | 源文件 | Picker export、directed test、官方风格 UCAgent replay 入口。 |
| `ucagent_cases/*/test/test_directed.py` | 源文件 | 人工 directed ground truth。 |
| `ucagent_cases/*/prompts/ucagent_prompt.md` | 源文件 | 提供给 UCAgent 的 case 目标与约束。 |
| `ucagent_cases/*/src/env/` | 源文件 | Toffee 环境骨架，保留为结构化验证环境入口。 |
| `ucagent_cases/*/src/ref/` | 源文件 | 参考模型/判定逻辑骨架。 |
| `ucagent_cases/*/CaseBuggy/` | 生成物 | Picker 导出的 Python DUT 包。 |
| `ucagent_cases/*/CaseFixed/` | 生成物 | Picker 导出的 Python DUT 包。 |
| `ucagent_cases/*/unity_test/` | 生成物 | UCAgent 官方流程生成/修改的测试目录。 |
| `reports/ucagent_logs/` | 生成物 | Picker、pytest、UCAgent stdout/internal/messages 日志。 |
| `reports/ucagent_artifacts/` | 生成物 | 每个 UCAgent run 的 `unity_test` 与 Toffee 报告归档。 |

## 脚本入口

| 脚本 | 用途 |
| --- | --- |
| `scripts/00_setup_ucagent_sources.sh` | 拉取官方 `UCAgent`、`Example-NutShellCache`、`picker` 到 `third_party/` 并记录版本。 |
| `scripts/01_install_ucagent_venv.sh` | 可选 venv 安装入口；当前实跑优先使用已有 conda 环境 `ucagent`。 |
| `scripts/24_run_three_case_formal.sh` | 本地 SymbiYosys 三案例批量 formal。 |
| `scripts/25_docker_run_three_case_formal.sh` | Docker fallback 三案例 formal。 |
| `scripts/40_prepare_pr21_real_nutshell_cache.sh` | 下载 PR #21 前后 NutShell、插入 probe、生成真实 Cache Verilog。 |
| `scripts/41_run_pr21_real_nutshell_cache_formal.sh` | 对真实 NutShell Cache pre/fixed DUT 运行 PR #21 formal。 |
| `scripts/31_run_directed_three_cases.sh` | 三案例手写 directed dynamic 批量运行。 |
| `scripts/32_seed_ucagent_case.sh` | 为 UCAgent 预置官方目录、API、coverage 定义和测试模板。 |
| `scripts/30_run_ucagent_three_cases.sh` | 官方流程风格的 UCAgent 三案例批量运行与 replay 判定。 |

## 三个案例

| Case | 来源 | 验证意图 |
| --- | --- | --- |
| `pr21_prefetch_mmio` | NutShell PR #21 `Bug prefetch mmio` | MMIO prefetch 不能 flush 已存在的正常 cache/L2 请求，也不能作为普通 prefetch 进入 memory pipeline。 |
| `pr74_cache_io_idbits` | NutShell PR #74 `cache: fix cache io` | 非零 out-of-order request id 必须在 response path 保留。 |
| `flush_outstanding_miss` | 人工形式验证优势案例 | read miss outstanding 时遇到 flush，不能在 refill response 到来前提前给 CPU response。 |

## Buggy/Fixed 语义

- `CaseBuggy`: 故意保留历史旧行为或人工注入错误，是负样本。
- `CaseFixed`: 修复后的正确行为，是正样本。
- 有效验证的目标不是让两者都通过，而是得到 `buggy FAIL / fixed PASS`。
- `buggy PASS / fixed PASS` 表示测试漏检。
- `buggy FAIL / fixed FAIL` 表示测试过强、环境错误或 false positive。

## 当前结果

| 验证方式 | 当前结果 |
| --- | --- |
| Formal | 3/3 case 均达到 `buggy FAIL / fixed PASS`。 |
| PR #21 real Cache formal | 真实 NutShell `nutcore.Cache` 达到 `pre FAIL / fixed PASS`。 |
| 手写 directed dynamic | 3/3 case 均达到 `buggy FAIL / fixed PASS`。 |
| UCAgent/Toffee | PR #74 与 flush case 达到 `fixed PASS / buggy FAIL`；PR #21 为 `INFRA_FAIL`，原因是 UCAgent 未在 900 秒内完成 seeded pytest 模板编辑。 |
