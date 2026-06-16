# NutShell Cache Three Case Verification

This repository contains a compact verification package for three cache bug
cases:

| Case | Type | What is checked |
| --- | --- | --- |
| NutShell PR #21 `Bug prefetch mmio` | Real historical fix | An MMIO prefetch must not flush an existing normal cache/L2 request, and must not be emitted as a normal prefetch request. |
| NutShell PR #74 `cache: fix cache io` | Real historical fix | A nonzero out-of-order request ID must be preserved on the response path. |
| `flush_outstanding_miss` | Injected formal-advantage case | A flush during an outstanding miss must not create an early CPU response before refill. |

The two NutShell cases are compact executable litmus tests derived from public
upstream fixes, not a full SoC replay. Each case has buggy/fixed variants.

## Layout

```text
formal/historical/   SystemVerilog formal litmus tests and SBY configs
ucagent_cases/       UCAgent-style dynamic workspaces with directed pytest tests
scripts/             Formal, directed, UCAgent, and setup runners
reports/             Formal, dynamic, UCAgent, and comparison reports
docker/              Optional formal and UCAgent Docker environments
```

## Reading Order

- `reports/file_inventory.md`: source files, generated artifacts, and script roles.
- `reports/reproduction_guide.md`: exact reproduction flow and result interpretation.
- `reports/ucagent_token_usage.md`: observable UCAgent token/context statistics.
- `reports/formal_vs_ucagent_comparison.md`: final complementary verification reading.

## Formal

Run locally when SymbiYosys/Yosys/Z3 are installed:

```bash
bash scripts/24_run_three_case_formal.sh
```

Or use Docker:

```bash
docker build -f docker/formal.Dockerfile -t nutshell-cache-formal:latest .
bash scripts/25_docker_run_three_case_formal.sh
```

Report:

```text
reports/formal_batch/three_case_formal.md
```

Expected result: all buggy variants fail, all fixed variants pass.

## Directed Dynamic Tests

The dynamic workspaces provide small executable DUT shims and directed pytest
checks. They are the ground truth used before invoking UCAgent:

```bash
bash scripts/31_run_directed_three_cases.sh
```

Report:

```text
reports/directed_three_case_results.md
```

Expected result: buggy variants fail the directed tests, fixed variants pass.

## UCAgent

Fetch official sources:

```bash
bash scripts/00_setup_ucagent_sources.sh
bash scripts/01_install_ucagent_venv.sh
```

Configure the LLM backend:

```bash
cp .ucagent_env.example .ucagent_env
# edit .ucagent_env with real values
source .ucagent_env
```

Run the UCAgent comparison:

```bash
bash scripts/30_run_ucagent_three_cases.sh
```

If `OPENAI_API_BASE`, `OPENAI_API_KEY`, or `OPENAI_MODEL` is missing, the script
writes a `BLOCKED_NO_LLM_ENV` report instead of pretending that UCAgent ran.

Reports:

```text
reports/ucagent_three_case_results.md
reports/formal_vs_ucagent_comparison.md
```

## Official Sources

- UCAgent: https://github.com/XS-MLVP/UCAgent
- Example-NutShellCache: https://github.com/XS-MLVP/Example-NutShellCache
- picker: https://github.com/XS-MLVP/picker
- NutShell PR #21: https://github.com/OSCPU/NutShell/pull/21
- NutShell PR #74: https://github.com/OSCPU/NutShell/pull/74
