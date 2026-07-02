# 通用 Formal Skill 报告

- 创建时间：2026-07-02T10:22:29.015404+00:00

| Case | Expected | Actual | Verdict | Depth | Log |
| --- | --- | --- | --- | --- | --- |
| `adder_buggy` | FAIL | FAIL | OK | 2 | `reports/artifacts/01_adder/logs/adder_buggy.log` |
| `adder_fixed` | PASS | PASS | OK | 2 | `reports/artifacts/01_adder/logs/adder_fixed.log` |

## 为什么保留这个案例

这是一个很小的人工 adder bug，用来证明可复用的 `generic-formal` skill 能抓到已知 RTL 缺陷，并且不会在 fixed RTL 上误报。它不是 NutShell Cache 真实 bug。

## UCAgent Skill 兼容性

该案例使用的 YAML case 格式就是 `src/ucagent_skills/generic-formal/SKILL.md` 暴露给 UCAgent 的接口，因此 UCAgent 可以通过 `RunSkillScript` 对任意小模块调用同一个形式验证 skill。
