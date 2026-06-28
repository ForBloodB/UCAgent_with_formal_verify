# 通用 Formal Skill 报告

- 创建时间：2026-06-28T10:42:01.987133+00:00

| Case | Expected | Actual | Verdict | Depth | Log |
| --- | --- | --- | --- | --- | --- |
| `pr74_real_nutshell_cache_pre_elab` | ERROR | ERROR | OK | 0 | `reports/artifacts/03_pr74/ucagent_formal/logs/pr74_real_nutshell_cache_pre_elab.log` |
| `pr74_real_nutshell_cache_fixed_formal` | PASS | PASS | OK | 16 | `reports/artifacts/03_pr74/ucagent_formal/logs/pr74_real_nutshell_cache_fixed_formal.log` |

## UCAgent 证据

- UCAgent log：`reports/artifacts/03_pr74/ucagent_formal/logs/ucagent_pr74_formal_skill.log`
- Message log：`reports/artifacts/03_pr74/ucagent_formal/logs/ucagent_pr74_formal_skill_messages.jsonl`
- Token report：`reports/artifacts/03_pr74/ucagent_formal/token_usage.md`
- 结论：UCAgent 通过通用 `generic-formal` skill 捕获 PR74 pre 的接口/elaboration 失败，并验证 fixed formal property 通过。
