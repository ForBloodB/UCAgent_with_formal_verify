# 05 完整声明功能覆盖如何实现

## 覆盖口径

05 的 100% 覆盖指：`tests/cases/05_full_cache_coverage_plan/data/cache_coverage_plan.yaml` 中声明的 15 个 functional coverage points 全部具备 stimulus、checker/scoreboard、coverage bin 和 evidence。

它不表示完整 NutShell SoC 覆盖率，也不表示 RTL line/toggle/branch 覆盖率 100%。

## 15 个覆盖点

| 类别 | 覆盖点 |
| --- | --- |
| read | read hit、read miss refill |
| readBurst | L2 readBurst hit backpressure |
| mmio | PR21 MMIO prefetch pipeline interference |
| interface | PR74 CacheIO idBits |
| write | write hit full mask、write hit partial mask、write miss refill |
| replacement | dirty eviction writeback、clean eviction no writeback |
| flush | flush during outstanding miss |
| coherence | probe hit、probe miss |
| protocol | req stability、resp stability |

## PR21 / PR74 / 04 如何纳入 05

| Bug point | 来源 | 05 中的作用 |
| --- | --- | --- |
| PR21 MMIO prefetch pipeline interference | 真实历史 PR21 pre/fixed | 关闭 `CP_MMIO_PREFETCH_PIPELINE_INTERFERENCE` |
| PR74 CacheIO idBits | 真实历史 PR74 pre/fixed | 关闭 `CP_CACHE_IO_IDBITS` |
| 04 L2 readBurst ready/valid candidate | latest upstream candidate | 关闭 `CP_READBURST_HIT_BACKPRESSURE` 与 `CP_READY_VALID_RESP_STABILITY` |

这三个点不是只在 02/03/04 单独展示，而是作为 05 coverage database 的一部分被追踪。

## AI / 人工 / 工具分工

| 内容 | 执行者 | 说明 |
| --- | --- | --- |
| 覆盖目标、环境假设、scoreboard oracle | 人工 | 决定什么行为必须验证，避免纯 AI 刷覆盖。 |
| bug candidate 总结 | UCAgent | 读取 02/03/04/05 报告后形成候选点列表。 |
| formal 反例搜索 | UCAgent + `generic-formal` | PR21、PR74、04 和协议风险点可通过 skill 执行。 |
| 动态测试执行 | UCAgent + Toffee/pytest | 官方 `RunTestCases` 运行 05 coverage closure。 |
| 真实 DUT 导出 | Picker | 02/03/04 使用 Picker 导出真实 NutShell wrapper。 |
| 结果签核 | 人工 | 判断 candidate bug 是否成立、coverage 是否能关闭。 |

## 当前结果

- Declared coverage：`15/15 = 100.0%`
- Bug points：`3`
- Partial：`0`
- Gap：`0`
- CRV scenario gap：`0`
- Scoreboard gap：`0`

主要报告：

- `reports/05_full_cache_coverage_plan.md`
- `reports/05_ucagent_bug_candidates.md`
- `reports/05_full_cache_coverage_plan_ucagent.md`

## 复现

本地 smoke：

```bash
bash scripts/run_cases.sh --case 05 --with-formal --smoke
```

真实 API，formal-first：

```bash
source .ucagent_env
bash scripts/run_cases.sh --case 05 --with-formal
```

真实 API，无 formal 对照：

```bash
source .ucagent_env
bash scripts/run_cases.sh --case 05 --no-formal
```
