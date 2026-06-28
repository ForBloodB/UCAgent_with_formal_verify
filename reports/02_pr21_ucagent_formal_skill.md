# 通用 Formal Skill 报告

- 创建时间：2026-06-28T05:56:35.469128+00:00

| Case | Expected | Actual | Verdict | Depth | Log |
| --- | --- | --- | --- | --- | --- |
| `pr21_real_nutshell_cache_pre` | FAIL | FAIL | OK | 24 | `reports/artifacts/02_pr21/ucagent_formal/logs/pr21_real_nutshell_cache_pre.log` |
| `pr21_real_nutshell_cache_fixed` | PASS | PASS | OK | 24 | `reports/artifacts/02_pr21/ucagent_formal/logs/pr21_real_nutshell_cache_fixed.log` |

## UCAgent 证据

- UCAgent log：`reports/artifacts/02_pr21/ucagent_formal/logs/ucagent_pr21_formal_skill.log`
- Message log：`reports/artifacts/02_pr21/ucagent_formal/logs/ucagent_pr21_formal_skill_messages.jsonl`
- Token report：`reports/artifacts/02_pr21/ucagent_formal/token_usage.md`
- 结论：UCAgent 通过通用 `generic-formal` skill 对真实 NutShell PR21 pre/fixed 版本完成了同一套 formal 闭环。
