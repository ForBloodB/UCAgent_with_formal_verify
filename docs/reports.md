# 报告与产物说明

本仓库保留可读的 Markdown/JSON 摘要报告，默认忽略可再生成的大体积产物。

建议提交到 GitHub 的轻量报告：

- `reports/00_overview.md`
- `reports/01_adder.md`
- `reports/02_pr21.md`
- `reports/02_pr21_toffee_coverage.md`
- `reports/02_pr21_toffee_ucagent.md`
- `reports/02_pr21_ucagent_formal_skill.md`
- `reports/02_pr21_ucagent_original_no_formal.md`
- `reports/03_pr74.md`
- `reports/03_pr74_toffee_coverage.md`
- `reports/03_pr74_toffee_ucagent.md`
- `reports/03_pr74_ucagent_formal_skill.md`
- `reports/03_pr74_ucagent_original_no_formal.md`
- `reports/04_l2_readburst.md`
- `reports/04_l2_readburst_toffee_coverage.md`
- `reports/04_l2_readburst_toffee_ucagent.md`
- `reports/04_l2_readburst_ucagent_full_demo.md`
- `reports/05_full_cache_coverage_plan.md`
- `reports/05_full_cache_coverage_plan_ucagent.md`
- `reports/05_ucagent_original_no_formal_comparison.md`
- `reports/90_reproduction.md`
- `reports/91_ucagent_skill_evidence.md`

建议提交到 GitHub 的轻量产物：

- `reports/artifacts/04_l2_readburst/dynamic_readburst_ready_deadlock.md`
- `reports/artifacts/04_l2_readburst/*token_usage.md`
- `reports/artifacts/04_l2_readburst/toffee/coverage_summary.json`
- `reports/generic_verilog/**/README.md`

默认忽略的产物包括：SBY 工作目录、自动生成的 Verilog harness、波形文件、共享库、长日志、Picker 导出的 DUT 二进制/构建目录，以及 UCAgent 运行时生成的临时 workspace 缓存。
