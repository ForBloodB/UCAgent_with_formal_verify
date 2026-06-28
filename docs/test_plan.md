# NutShell Cache 验证测试计划

## 覆盖矩阵

| Cache 场景 | 当前案例 | 方法 | 状态 |
| --- | --- | --- | --- |
| 简单 RTL formal skill smoke | 01 adder | 通用 formal YAML | 已覆盖 |
| MMIO prefetch 干扰正常 cache pipeline | 02 PR21 | 真实 NutShell 历史 formal | 已覆盖 |
| CacheIO idBits 接口回归 | 03 PR74 | 真实 NutShell elaboration/formal | 已覆盖 |
| L2 readBurst hit 遇到 response backpressure | 04 readBurst | UCAgent formal + directed dynamic replay | 已覆盖 |
| 全 Cache 声明功能 coverage/CRV/scoreboard/coverage DB 定义 | 05 coverage closure | UCAgent `RunTestCases` closure-check | 15/15 已闭环 |
| Read miss/refill 基线 | 04 setup path | public-IO replay 先构造 refill 再 hit | 部分覆盖 |
| Write path 与 partial mask | 05 reference scoreboard closure | Toffee/pytest checker | 声明覆盖已闭合 |
| Dirty eviction/writeback | 无活跃案例 | 后续 CRV 或 formal wrapper | 缺口 |
| Replacement policy stress | 无活跃案例 | 后续 CRV coverage item | 缺口 |
| Flush during outstanding miss | 已归档 | 移入 `_Trash`，非当前交付 | 缺口 |
| Coherence invalidate/probe | 已归档 | 移入 `_Trash`，非当前交付 | 缺口 |

## 验收标准

- 每个活跃案例都有确定性的脚本入口。
- buggy/pre/candidate case 产生预期失败证据。
- fixed case 按预期通过或 elaboration 成功。
- 04 同时包含 formal 与 dynamic 证据。
- UCAgent 证据包含 `RunSkillScript`、`SetSkillUsage`、`RunTestCases`、`Complete`、`Exit` 日志。

## 功能覆盖率说明

本提交不声称已经达到完整 NutShell Cache RTL line/toggle 90% coverage。当前策略是用四个高价值案例证明形式验证、真实历史 bug 复现、UCAgent skill 集成和动态复现闭环，并通过 05 将声明的 15 个 functional coverage points 形成 15/15 closure。

下一步若要冲击完整工业级验证画像，应继续接入 UCIS/Verilator line/toggle/branch coverage，把 05 reference closure 绑定到更大规模的真实 DUT CRV regression。
