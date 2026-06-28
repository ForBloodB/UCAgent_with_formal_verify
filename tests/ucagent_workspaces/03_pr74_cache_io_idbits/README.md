# UCAgent Workspace: 03 PR74 Cache IO idBits

This workspace demonstrates the real NutShell PR #74 CacheIO `idBits` regression.

- `config.yaml`: UCAgent calls the generic `generic-formal` skill.
- `config_original.yaml`: UCAgent runs without any formal skill and performs only normal file/report analysis.

The pre-PR case is an elaboration/interface failure. The fixed case elaborates and then passes the ID preservation formal property.
