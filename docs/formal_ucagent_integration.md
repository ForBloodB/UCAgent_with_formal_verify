# 形式验证如何与 UCAgent 配合

## 核心思想

本项目把 SymbiYosys 形式验证封装成 UCAgent 可调用的通用 skill：`src/ucagent_skills/generic-formal`。

UCAgent 本身负责读取任务、选择工具、调用 `RunSkillScript`、总结结果；`generic-formal` 负责执行具体 YAML/`.sby` case，并把 PASS/FAIL/ERROR、日志路径和报告写回仓库。

这相当于给 agent 增加一个硬件验证后端：它不只会生成动态测试，还能主动搜索 bounded counterexample。

## 调用流程

| 步骤 | 执行者 | 产物 |
| --- | --- | --- |
| 编写 formal harness、`.sby`、YAML case | 人工 | 可执行 property |
| 读取 `generic-formal/SKILL.md` | UCAgent | skill 使用说明 |
| 调用 `RunSkillScript` | UCAgent | formal 执行日志 |
| 执行 SymbiYosys | `generic-formal` | PASS/FAIL/ERROR |
| 解释反例或 PASS | UCAgent + 人工复核 | bug 复现方式或 false-positive 排除 |
| 转入 Toffee/pytest | UCAgent | 动态回归与覆盖报告 |

## 为什么需要 formal skill

动态测试擅长做长期回归和软件式环境组织，但对窄时序窗口通常覆盖率低。例如：

- PR21：MMIO prefetch 与已有 pipeline entry 在关键窗口冲突。
- 04：L2 readBurst hit 时 `resp_ready=0`，观察 `resp_valid` 是否仍主动拉高。
- flush/outstanding miss、ready/valid stability 等协议问题。

这些场景在随机动态测试中需要碰到精确时序，而 formal 可以直接符号化构造窗口，快速给出反例或 bounded PASS。

## 有无 formal skill 的差异

| 能力 | 无 formal skill | 有 `generic-formal` skill |
| --- | --- | --- |
| 运行 Toffee/pytest | 可以 | 可以 |
| 读取报告并总结现象 | 可以 | 可以 |
| 自动搜索 bounded counterexample | 不具备 | 具备 |
| 证明 fixed 版本不再触发 property | 需要 directed regression 辅助 | 可直接跑 fixed PASS |
| 对窄时序窗口定位 | 依赖人工 directed replay | agent 可先 formal 诊断，再转动态回归 |

## 功能边界

`generic-formal` 是通用 skill，不是 04 专用工具。它可以运行任意符合 YAML 接口的 `.sby` case。

但它不会自动知道“什么是正确行为”。property、环境假设、reset 约束、合法输入空间仍需要人工定义或人工审核 UCAgent 草稿。

## 当前证据

- 01：人工 adder bug，buggy `FAIL`、fixed `PASS`。
- 02：PR21 真实 NutShell 历史 bug，pre `FAIL`、fixed `PASS`。
- 03：PR74 真实 NutShell 接口 bug，pre `ERROR/ELAB_FAIL`、fixed `PASS`。
- 04：latest L2 readBurst candidate，assert `FAIL`、cover `PASS`，并继续 Toffee 动态复现。
- 05：UCAgent formal-first 流程把 PR21、PR74、04 bug evidence 纳入 declared coverage closure。
