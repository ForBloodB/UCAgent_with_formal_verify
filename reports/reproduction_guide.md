# 真实 NutShell Cache PR 复现指南

- Date: 2026-06-16
- Scope: 只保留真实 NutShell 历史 PR case，不再保留 compact/artificial 三案例。

## 结果矩阵

| Case | 版本 | 验证方式 | 当前结果 |
| --- | --- | --- | --- |
| PR #21 `Bug prefetch mmio` | pre `bd425dee` | real Cache BMC | FAIL, step 10 counterexample |
| PR #21 `Bug prefetch mmio` | fixed `f0d7c494` | real Cache BMC | PASS, depth 16 |
| PR #74 `cache: fix cache io` | pre `4b656f32` | real Cache Chisel elaboration | ELAB_FAIL, missing `id` field |
| PR #74 `cache: fix cache io` | fixed `287c5e02` | real Cache generation | PASS |
| PR #74 `cache: fix cache io` | fixed `287c5e02` | real Cache BMC | PASS, depth 24 |

## PR #21 复现

使用文件：

```text
formal/nutshell_pr21_real/Pr21CacheFormalDut.scala
formal/nutshell_pr21_real/pr21_nutshell_cache_mmio_prefetch_formal.sv
formal/nutshell_pr21_real/nutshell_pr21_real_cache_pre.sby
formal/nutshell_pr21_real/nutshell_pr21_real_cache_fixed.sby
scripts/40_prepare_pr21_real_nutshell_cache.sh
scripts/41_run_pr21_real_nutshell_cache_formal.sh
```

生成真实 NutShell Cache DUT：

```bash
bash scripts/40_prepare_pr21_real_nutshell_cache.sh all
```

脚本会下载并使用两个真实上游版本：

- pre-PR parent: `bd425deedff4e896fca59895b34d778f2c8724d9`
- fixed PR head: `f0d7c49411197047dc8464addfacc0fcba5b9e45`

然后在临时上游源码副本里插入 `BoringUtils` probe，生成：

```text
formal/nutshell_pr21_real/generated/pre/Pr21CacheFormalDut.v
formal/nutshell_pr21_real/generated/fixed/Pr21CacheFormalDut.v
```

运行 formal：

```bash
docker run --rm --user "$(id -u):$(id -g)" -v "$PWD:/work" -w /work \
  nutshell-cache-formal:latest bash scripts/41_run_pr21_real_nutshell_cache_formal.sh
```

报告：

```text
reports/pr21_real_nutshell_cache_formal.md
reports/formal_batch/logs/pr21_real_nutshell_cache_pre.log
reports/formal_batch/logs/pr21_real_nutshell_cache_fixed.log
```

## PR #74 复现

使用文件：

```text
formal/nutshell_pr74_real/Pr74CacheIOFormalDut.scala
formal/nutshell_pr74_real/pr74_nutshell_cache_io_idbits_formal.sv
formal/nutshell_pr74_real/nutshell_pr74_real_cache_fixed.sby
scripts/42_prepare_pr74_real_nutshell_cache.sh
scripts/43_run_pr74_real_nutshell_cache_formal.sh
```

PR #74 的真实修复点是：

```scala
// pre
val in = Flipped(new SimpleBusUC(userBits = userBits))

// fixed
val in = Flipped(new SimpleBusUC(userBits = userBits, idBits = idBits))
```

生成 fixed DUT：

```bash
bash scripts/42_prepare_pr74_real_nutshell_cache.sh fixed
```

验证 pre 版本确实失败：

```bash
bash scripts/42_prepare_pr74_real_nutshell_cache.sh pre
```

期望失败信息包含：

```text
Right Record missing field (id)
```

运行 formal：

```bash
docker run --rm --user "$(id -u):$(id -g)" -v "$PWD:/work" -w /work \
  nutshell-cache-formal:latest bash scripts/43_run_pr74_real_nutshell_cache_formal.sh
```

报告：

```text
reports/pr74_real_nutshell_cache_formal.md
reports/formal_batch/logs/pr74_real_nutshell_cache_pre_generate.log
reports/formal_batch/logs/pr74_real_nutshell_cache_fixed_generate.log
reports/formal_batch/logs/pr74_real_nutshell_cache_fixed_formal.log
```

## UCAgent 状态

之前的 UCAgent 产物来自 compact/artificial DUT，不再作为真实 NutShell Cache 证据保留。
当前保留 `reports/ucagent_real_case_status.md`，明确记录这个边界。

官方工具链来源仍可通过以下脚本准备：

```bash
bash scripts/00_setup_ucagent_sources.sh
bash scripts/01_install_ucagent_venv.sh
```

不要在终端打印 `.ucagent_env` 内容。
