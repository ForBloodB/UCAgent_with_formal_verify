---
name: generic-formal
description: Run a SymbiYosys formal case for arbitrary RTL modules from a YAML file or existing SBY file, then classify PASS/FAIL/TIMEOUT results.
---

# Generic Formal Verification Skill

Use this skill when the task is to run formal verification on an RTL module.
It is intentionally generic: the YAML case file either describes RTL files plus
a harness/top module so the script can create an SBY file, or points at an
existing SBY file. Case-specific source checkout, wrapper generation, or build
steps belong in the YAML `prepare` commands, not in this skill.

This skill follows the official UCAgent skill flow: list the skill with
`ListSkill`, read `.ucagent/skills/generic-formal/SKILL.md`, execute
`run_formal.py` through `RunSkillScript`, and record usage with
`SetSkillUsage` before `Complete` when the stage forces skill usage.

## Required Input

Generated-SBY form:

```yaml
name: adder_buggy
top: adder_formal
files:
  - tests/cases/01_generic_formal_proof/rtl/adder_buggy.sv
  - tests/cases/01_generic_formal_proof/formal/adder_formal.sv
depth: 8
expected: FAIL
report: reports/01_adder.md
```

Existing-SBY form:

```yaml
name: l2_readburst_hit_ready_deadlock_assert
sby: tests/cases/04_l2_readburst_hit_ready_valid_deadlock/formal/l2_readburst_hit_ready_deadlock_assert.sby
depth: 96
expected: FAIL
prepare:
  - python3 tests/cases/04_l2_readburst_hit_ready_valid_deadlock/scripts/prepare_latest_l2_readburst.py --timeout 1200
report: reports/04_l2_readburst.md
log_dir: reports/artifacts/04_l2_readburst/logs
result_dir: reports/artifacts/04_l2_readburst/results
mirror_report:
  - tests/ucagent_workspaces/04_l2_readburst_deadlock/reports/04_l2_readburst.md
```

Paths are relative to the workspace root passed to `run_formal.py`, unless
absolute.

Optional fields:

- `prepare`: one shell command or a list of shell commands to run before SBY.
- `defines`: one macro or a list of macros used for generated-SBY cases.
- `engines`: one engine or a list of engines, defaulting to `smtbmc z3`.
- `mirror_report`: one path or list of paths where the markdown report is copied.

## Workflow

1. Read the DUT RTL, formal harness, or existing SBY case.
2. Run the case through UCAgent's official `RunSkillScript` tool.
   The UCAgent version used by this workspace expects each command as
   `[skill_name, skill_script, args]`; the script runner is inferred by
   UCAgent from the script extension:

```json
{
  "commands": [
    ["generic-formal", "run_formal.py", "--case tests/cases/01_generic_formal_proof/formal/adder_buggy.yaml"]
  ]
}
```

Equivalent direct shell command:

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
