# 比赛提交报告

本项目的目标很明确：把形式验证做成 UCAgent 可以调用的通用 skill，让 Agent 不只会写 Toffee/pytest 动态测试，也能在合适的时候先跑 bounded formal，快速给出反例、覆盖证明或环境假设风险。最终仓库保留 01-05 五个可复现案例，其中 01 证明通用能力，02/03 复现 NutShell 历史真实问题，04 给出 公开最终版 Cache 的 ready/valid candidate，05 做 latest-only 覆盖闭环和 UCAgent 候选点人工复查。

## 一句话结论

当前结果可以说明三件事：

1. 形式验证是有用的：01、02、04 都能快速给出反例；03 能把接口修复前后的 elaboration/formal 结果分开。
2. formal skill 可以接入 UCAgent：`generic-formal` 使用 YAML 描述 case，UCAgent 可以通过 `RunSkillScript` 调它，再继续原本的 Toffee/pytest 流程。

## 复现入口

默认复现会真实调用 UCAgent API：

```bash
cp .ucagent_env.example .ucagent_env
vim .ucagent_env
bash scripts/reproduce.sh --case all --rebuild
```

本地快速检查不消耗 API：

```bash
bash scripts/reproduce.sh --case all --smoke
```

运行结果主要在 `reports/`，大体积中间产物由脚本重新生成。

## 五个案例

| Case | 来源 | 验证目的 | 当前证据 |
| --- | --- | --- | --- |
| 01 | 人工构造 adder buggy/fixed | 证明 `generic-formal` 对任意 RTL 的最小闭环能力 | `reports/01_adder.md` |
| 02 | NutShell PR21 前后版本 | 复现 MMIO prefetch 相关历史真实 bug | `reports/02_pr21.md` |
| 03 | NutShell PR74 前后版本 | 复现 CacheIO `idBits` 接口/elaboration 问题 | `reports/03_pr74.md` |
| 04 | latest NutShell Cache 场景 | 检查 L2 readBurst hit + backpressure 下 ready/valid 风险 | `reports/04_l2_readburst.md` |
| 05 | latest NutShell Cache 覆盖闭环 | 15 个声明 functional coverage point 闭合，复查 UCAgent 候选点 | `reports/05_full_cache_coverage_plan.md` |

## 04 重点说明

04 是本项目最有价值的 latest candidate。触发条件是：

1. L2 Cache 先发生一次同地址 `readBurst` miss/refill；
2. 第二次同地址 `readBurst` 命中；
3. 命中进入 S3 后，L1 侧 `resp_ready=0`；
4. 在标准 Decoupled ready/valid 语义下，producer 应该主动拉高 `resp_valid`，不能等 consumer ready；
5. 当前波形显示 `resp_ready=0` 时 `resp_valid=0`，因此存在 ready/valid 互等风险。

结论是：在标准 Decoupled 语义下，这是一个很强的 candidate bug；如果 NutShell 设计额外规定 L1 必须 eager-ready，则这个环境假设应该写进设计文档。

![04 L2 readBurst ready/valid 波形截图](../reports/assets/04_l2_readburst_ready_valid_waveform.png)

## 05 覆盖闭环

05 只面向 latest NutShell Cache，不引用 PR21/PR74 的历史证据。当前声明的 functional coverage 是 15/15：

- read/readBurst/refill/write/replacement/flush/coherence/protocol 等功能点都具备 stimulus、checker 或 formal property、coverage bin 和 evidence；
- 该 100% 只表示本项目定义的 15 个功能覆盖点闭合，不代表完整 SoC、RTL line coverage 或 toggle coverage 100%；
- UCAgent 生成/整理了高风险候选点，但最终是否算 bug 由人工复查签核。

05 中最终保留的 latest candidate 只有 `CAND_LATEST_L2_READBURST_READY_VALID`。另外三个 UCAgent hypothesis：

- `HYP_FLUSH_OUTSTANDING_MISS`
- `HYP_DIRTY_EVICTION_ORDER`
- `HYP_PARTIAL_MASK_MERGE`

已经通过人工 Verilog testbench 加激励并查看 VCD，当前没有复现为 bug。报告见 `reports/05_manual_verilog_validation.md`。

## AI 与人工分工

| 工作 | UCAgent/工具做的 | 人工做的 |
| --- | --- | --- |
| 测试草稿 | 生成 Toffee/pytest 结构、候选 bug 描述、报告草稿 | 修正时序、接口、scoreboard oracle |
| 形式验证 | 通过 `generic-formal` skill 执行 SBY/Yosys/Z3 | 编写 property、环境假设、预期结果矩阵 |
| 覆盖闭合 | 汇总 coverage point 与执行结果 | 定义覆盖计划，判断 coverage 是否有意义 |
| bug 结论 | 给出高风险建议 | 用 formal 反例、动态 scoreboard 或 Verilog 波形签核 |

## 对评分点的对应

- 基础环境：Docker 一键构建，包含 UCAgent、Picker、Toffee、Yosys/SBY、Z3、Verilator、Icarus Verilog。
- 人工干预：手写 formal property、coverage plan、scoreboard oracle、04/05 的 Verilog 后验激励。
- 技术深度：不仅跑动态测试，还把 formal skill 放到 Agent 流程前置诊断中。
- 覆盖率：05 达到本项目声明的 15/15 functional coverage closure。
- 工程质量：`src/` 放通用工具，`tests/` 放案例，`scripts/reproduce.sh` 是统一入口，`reports/` 保存轻量证据。
