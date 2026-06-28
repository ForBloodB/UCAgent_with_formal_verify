# UCAgent Workspace: 02 PR21 MMIO Prefetch

This workspace demonstrates the real NutShell PR #21 cache bug with two flows:

- `config.yaml`: UCAgent calls the generic `generic-formal` skill.
- `config_original.yaml`: UCAgent runs without any formal skill and can only perform normal file/report analysis for this case.

The real DUT source is generated from the historical NutShell commits by the repository scripts under `scripts/20_*` and `scripts/21_*`.
