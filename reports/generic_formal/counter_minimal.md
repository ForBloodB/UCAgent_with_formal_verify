# Generic Formal Skill Smoke Report

- Created: 2026-06-21T03:23:39.548672+00:00

| Case | Expected | Actual | Verdict | Depth | Log |
| --- | --- | --- | --- | --- | --- |
| `counter_buggy` | FAIL | FAIL | OK | 8 | `reports/generic_formal/logs/counter_buggy.log` |
| `counter_fixed` | PASS | PASS | OK | 8 | `reports/generic_formal/logs/counter_fixed.log` |

## Reproduce

```bash
bash scripts/50_run_generic_formal_skill_smoke.sh
```

## UCAgent Skill-Path Check

The skill path was checked with UCAgent's real CLI:

```bash
conda run -n ucagent ucagent examples/counter_formal Counter \
  --config third_party/UCAgent/ucagent/lang/zh/config/default.yaml \
  --use-skill \
  --extra-skill-path ./ucagent_skills \
  --emulate-config \
  --no-history \
  --no-embed-tools
```

The command exited successfully and UCAgent reported copying one extra skill file,
which confirms that `ucagent_skills/generic-formal/SKILL.md` is discoverable via
`--extra-skill-path`.
