# 文件清单

- Date: 2026-06-16
- Scope: 真实 NutShell Cache PR #21 / PR #74 formal 复现。

## Formal Source

| 路径 | 用途 |
| --- | --- |
| `formal/nutshell_pr21_real/Pr21CacheFormalDut.scala` | PR #21 真实 `nutcore.Cache` Chisel wrapper。 |
| `formal/nutshell_pr21_real/pr21_nutshell_cache_mmio_prefetch_formal.sv` | PR #21 formal harness，检查 MMIO prefetch 不破坏已有正常请求。 |
| `formal/nutshell_pr21_real/nutshell_pr21_real_cache_pre.sby` | PR #21 pre-PR BMC 配置。 |
| `formal/nutshell_pr21_real/nutshell_pr21_real_cache_fixed.sby` | PR #21 fixed BMC 配置。 |
| `formal/nutshell_pr74_real/Pr74CacheIOFormalDut.scala` | PR #74 真实 `nutcore.Cache` Chisel wrapper，要求 `idBits=4`。 |
| `formal/nutshell_pr74_real/pr74_nutshell_cache_io_idbits_formal.sv` | PR #74 fixed formal harness，检查 response ID 等于已接受 request ID。 |
| `formal/nutshell_pr74_real/nutshell_pr74_real_cache_fixed.sby` | PR #74 fixed BMC 配置。 |

## Generated Real RTL

| 路径 | 来源 |
| --- | --- |
| `formal/nutshell_pr21_real/generated/pre/` | NutShell `bd425deedff4e896fca59895b34d778f2c8724d9`。 |
| `formal/nutshell_pr21_real/generated/fixed/` | NutShell `f0d7c49411197047dc8464addfacc0fcba5b9e45`。 |
| `formal/nutshell_pr74_real/generated/fixed/` | NutShell `287c5e02490aca73055211bd04908917d71deaf7`。 |

PR #74 pre 版本没有生成 Verilog；失败点就是真实 Cache elaboration 中缺失 `id` 字段。

## Scripts

| 脚本 | 用途 |
| --- | --- |
| `scripts/40_prepare_pr21_real_nutshell_cache.sh` | 获取 PR #21 前后 NutShell commit，插入 probe，生成真实 Cache RTL。 |
| `scripts/41_run_pr21_real_nutshell_cache_formal.sh` | 运行 PR #21 pre/fixed formal。 |
| `scripts/42_prepare_pr74_real_nutshell_cache.sh` | 获取 PR #74 前后 NutShell commit 与 `difftest` submodule，生成 fixed RTL；pre 预期 elaboration fail。 |
| `scripts/43_run_pr74_real_nutshell_cache_formal.sh` | 汇总 PR #74 pre elaboration、fixed generation、fixed formal。 |
| `scripts/00_setup_ucagent_sources.sh` | 拉取官方 UCAgent / Example-NutShellCache / picker 源码。 |
| `scripts/01_install_ucagent_venv.sh` | 可选 UCAgent venv 安装入口。 |

## Reports

| 报告 | 内容 |
| --- | --- |
| `reports/pr21_real_nutshell_cache_formal.md` | PR #21 真实 Cache pre/fixed formal 矩阵。 |
| `reports/pr74_real_nutshell_cache_formal.md` | PR #74 真实 CacheIO elaboration/formal 矩阵。 |
| `reports/ucagent_real_case_status.md` | UCAgent 结果边界：旧 compact/artificial 产物已删除，不声明为真实 Cache 证据。 |
| `reports/toolchain_sources.md` | 官方 UCAgent / Example-NutShellCache / picker commit 记录。 |
| `reports/formal_batch/logs/` | PR21/PR74 真实验证日志。 |
