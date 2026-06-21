---
name: generic-formal
description: Build and run a small SymbiYosys-based formal verification flow for arbitrary RTL modules from a YAML case file, then classify PASS/FAIL/TIMEOUT results.
---

# Generic Formal Verification Skill

Use this skill when the task is to run formal verification on an RTL module.
It is intentionally generic: the YAML case file names the RTL files, harness,
formal top module, depth, expected result, and report path.

## Required Input

Create a YAML case file with this shape:

```yaml
name: counter_buggy
top: counter_formal
files:
  - examples/counter_formal/rtl/counter_buggy.sv
  - examples/counter_formal/formal/counter_formal.sv
depth: 8
expected: FAIL
report: reports/generic_formal/counter_minimal.md
```

Paths are relative to the workspace root unless absolute.

## Workflow

1. Read the DUT RTL and formal harness.
2. Run the case:

```bash
python3 .ucagent/skills/generic-formal/scripts/run_formal.py --case <case.yaml>
```

3. Interpret the result:
   - `PASS`: all assertions passed up to the configured depth.
   - `FAIL`: the solver found a counterexample.
   - `TIMEOUT`: the run exceeded the requested timeout.
   - `ERROR`: infrastructure or script failure.
4. If a buggy case is expected to fail, `FAIL` is a successful detection.
5. If a fixed case is expected to pass, `PASS` is the no-false-positive check.

## Notes

- If local `sby` is unavailable, the script automatically uses Docker image
  `nutshell-cache-formal:latest`.
- Do not treat `PASS` alone as proof of complete verification. Check that the
  harness includes useful assumptions and at least one meaningful cover/assert.
- For arbitrary modules, start with small BMC depths, then increase depth once
  the environment is stable.
