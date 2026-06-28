# UCAgent Skill 证据

## 活跃 Skill

`src/ucagent_skills/generic-formal` 是当前唯一活跃的自定义 UCAgent skill。

它是通用 skill，因为 skill 本身不编码 NutShell 特定行为。YAML case 可以提供：

- RTL files、formal harness top 与 BMC depth；
- 或已有 SBY 文件，以及可选 `prepare` 命令。

adder case、PR21、PR74 和 NutShell L2 readBurst case 都使用同一个 `run_formal.py` 入口。

## 官方流程兼容性

02、03、04 workspace 均使用如下官方 UCAgent skill sequence：

1. `ListSkill`
2. `ReadTextFile` 读取 `.ucagent/skills/generic-formal/SKILL.md`
3. `RunSkillScript` 调用 `["python3", "generic-formal", "run_formal.py", "..."]`
4. `SetSkillUsage`
5. `Complete`
6. `Exit`

Workspaces：

- `tests/ucagent_workspaces/02_pr21_mmio_prefetch/config.yaml`
- `tests/ucagent_workspaces/03_pr74_cache_io_idbits/config.yaml`
- `tests/ucagent_workspaces/04_l2_readburst_deadlock/config.yaml`

公开入口：

- `scripts/run_cases.sh --case 02 --with-formal`
- `scripts/run_cases.sh --case 03 --with-formal`
- `scripts/run_cases.sh --case 04 --with-formal`

内部 runner：

- `scripts/internal/22_run_pr21_ucagent_formal_skill.sh`
- `scripts/internal/32_run_pr74_ucagent_formal_skill.sh`
- `scripts/internal/40_run_l2_readburst_ucagent_formal.sh`
- `scripts/internal/45_run_l2_readburst_ucagent_full_demo.sh`

运行后可检查的证据：

- `reports/02_pr21_ucagent_formal_skill.md`
- `reports/03_pr74_ucagent_formal_skill.md`
- `reports/04_l2_readburst.md`
- `reports/04_l2_readburst_ucagent_full_demo.md`
- `reports/artifacts/02_pr21/ucagent_formal/logs/ucagent_pr21_formal_skill_messages.jsonl`
- `reports/artifacts/03_pr74/ucagent_formal/logs/ucagent_pr74_formal_skill_messages.jsonl`
- `reports/artifacts/04_l2_readburst/logs/ucagent_l2_readburst.log`
- `reports/artifacts/04_l2_readburst/logs/ucagent_l2_readburst_messages.jsonl`
- `reports/artifacts/04_l2_readburst/logs/ucagent_l2_readburst_full_demo.log`
- `reports/artifacts/04_l2_readburst/logs/ucagent_l2_readburst_full_demo_messages.jsonl`
- `reports/artifacts/04_l2_readburst/token_usage.md`

最新 04 运行包含两次成功的 `RunSkillScript` 调用：

- `l2_readburst_assert.yaml`：expected `FAIL`，actual `FAIL`
- `l2_readburst_cover.yaml`：expected `PASS`，actual `PASS`

日志同时包含 `ToolSetSkillUsage`、`ToolComplete`、`ToolExit`，说明 forced-skill stage 已通过官方 UCAgent flow 完成。

推荐的 04 完整演示入口是 `source .ucagent_env && bash scripts/run_cases.sh --case 04 --with-formal`。该入口要求同一次 UCAgent mission 先执行 `RunSkillScript` 进行 formal 前置诊断；如果 formal 发现反例，就写出复现条件；随后继续执行官方 `RunTestCases` Toffee/pytest 流程。因此它证明的是“formal skill 可以作为 UCAgent 的前置诊断工具，并能继续衔接原本动态验证流程”。

## No-Formal 对照

为了证明 formal skill 不是“装饰性报告”，还运行了不带 skill 的 UCAgent 对照。

第一版 no-formal baseline 说明：如果 02/03 没有动态 harness，UCAgent 只能读报告和做静态回顾，不能独立产生 counterexample 或 elaboration 证据。随后按比赛工程要求补齐 Picker/Toffee harness 后，又运行了 02/03/04 的 no-formal 动态后端：

- `scripts/run_cases.sh --case all --no-formal`
- 报告：`reports/05_ucagent_original_no_formal_comparison.md`

最新结果：

- 02 PR21：UCAgent 调 `RunTestCases`，2 个 Toffee pytest 通过，消息日志没有真实 `RunSkillScript` 工具调用。
- 03 PR74：UCAgent 调 `RunTestCases`，1 个 Toffee pytest 通过，消息日志没有真实 `RunSkillScript` 工具调用。
- 04 readBurst：由于已有人工校正的 Toffee/pytest 动态环境，消息日志包含 `RunTestCases`，并完成动态复现。

动态后端证据：

- `reports/02_pr21_toffee_ucagent.md`
- `reports/03_pr74_toffee_ucagent.md`
- `reports/04_l2_readburst_toffee_ucagent.md`
- `reports/artifacts/02_pr21/toffee_ucagent/logs/ucagent_pr21_toffee_messages.jsonl`
- `reports/artifacts/03_pr74/toffee_ucagent/logs/ucagent_pr74_toffee_messages.jsonl`
- `reports/artifacts/04_l2_readburst/logs/ucagent_l2_readburst_toffee_messages.jsonl`

token 统计已尝试解析，但当前后端日志没有暴露 token 字段。因此 `reports/artifacts/04_l2_readburst/token_usage.md` 记录为 `not reported`，不应理解为实际使用量为零。
