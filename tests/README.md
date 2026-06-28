# tests

本目录保存可复现案例与 UCAgent workspace。

```text
tests/cases/01_generic_formal_proof/          通用 formal 能力证明
tests/cases/02_pr21_mmio_prefetch/            NutShell PR21 历史 bug
tests/cases/03_pr74_cache_io_idbits/          NutShell PR74 历史接口 bug
tests/cases/04_l2_readburst_hit_ready_valid_deadlock/  latest candidate bug
tests/ucagent_workspaces/                     UCAgent 官方 workflow workspace
```

公开测试入口：

```bash
bash scripts/run_cases.sh --case all --with-formal --smoke
bash scripts/run_cases.sh --case all --no-formal --smoke
```

01 是本项目通用型证明：它用最小 adder buggy/fixed 模块证明 `generic-formal` 可以对普通 RTL 运行、捕获反例，并在 fixed RTL 上不误报。它不是 NutShell Cache bug。
