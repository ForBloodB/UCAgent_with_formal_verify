# 比赛提交报告

## 项目定位

本项目将形式验证封装为 UCAgent 可调用的通用 skill，并提供一个面向任意 Verilog/SystemVerilog 模块的验证入口。五个内置案例用于证明工具链可用、AI/人工协作有效、能在 NutShell Cache 上复现真实历史 bug、发现 latest candidate bug，并把全 Cache 覆盖闭环定义为可执行计划。

## 五个案例

| Case | 来源 | 目标 | 证据 |
| --- | --- | --- | --- |
| 01 generic formal proof | 人工构造最小 adder buggy/fixed | buggy 版本丢弃 carry-out，fixed 版本保留进位 | `reports/01_adder.md` |
| 02 PR21 MMIO prefetch | NutShell PR21 parent/fixed commit | MMIO prefetch 不能破坏已有 normal cache pipeline entry | `reports/02_pr21.md` |
| 03 PR74 CacheIO idBits | NutShell PR74 parent/fixed commit | OOO 配置下 `CacheIO.in` 缺少 `idBits`，pre-PR elaboration/interface failure | `reports/03_pr74.md` |
| 04 L2 readBurst ready/valid | latest upstream NutShell Cache wrapper | 同地址 `readBurst` miss/refill 后再次 hit，`resp_ready=0` 时 `resp_valid` 不主动拉高，存在 ready/valid deadlock 风险 | `reports/04_l2_readburst.md` |
| 05 declared functional coverage closure | 人工定义 + UCAgent `RunTestCases` 检查 | 15 个声明 functional coverage points 全部 implemented，并纳入 PR21/PR74/04 bug points | `reports/05_full_cache_coverage_plan.md` |

04 仍表述为 latest upstream candidate bug，不写成 upstream 已确认公开 bug。

## UCAgent 与人工分工

| 内容 | UCAgent/AI 作用 | 人工介入 |
| --- | --- | --- |
| 通用 skill | 通过 `RunSkillScript` 调用 `generic-formal` | 设计 YAML/SBY 接口、结果分类、Docker fallback |
| 任意 RTL 接入 | 可辅助生成 formal harness 草稿 | 人工确认 top、clock/reset、property 语义 |
| 02/03 动态后端 | 运行官方 `RunTestCases` | 接入 Picker DUT、memory mock、scoreboard、coverage |
| 04 candidate bug | 调用 formal-first flow 并继续 Toffee 回归 | 设计 ready/valid property、public-IO replay、覆盖点 |
| 05 coverage closure | 调用官方 `RunTestCases` 检查 15/15 coverage DB 与 bug candidates | 人工定义覆盖目标、CRV、scoreboard oracle、候选 bug 签核策略 |

## 评分标准映射

| 评分项 | 权重 | 本项目证据 |
| --- | ---: | --- |
| 基础环境构建 | 20 | `scripts/verify_verilog.sh`、`scripts/run_cases.sh`、Picker/Toffee/UCAgent workspace、Docker fallback |
| 人工干预与优化 | 25 | 真实 NutShell commit wrapper、formal property、scoreboard、coverage、AI 草稿修正 |
| 验证覆盖率达标 | 15 | 04 场景 setup coverage `5/5 = 100%`；02/03 场景 coverage `5/5 = 100%`；05 对声明的 15 个 functional coverage points 达成 `15/15 = 100%`；不声称 RTL line/toggle 90% |
| 协同过程记录 | 20 | `docs/ai_human_collaboration.md`、`reports/91_ucagent_skill_evidence.md` |
| 工程规范与复现 | 20 | `src/tests/docs` 结构、Apache 2.0、`.gitignore` 忽略大产物、公开入口脚本 |

## 复现命令

任意 RTL smoke：

```bash
bash scripts/verify_verilog.sh --rtl path/to/dut.sv --top MyDut --smoke
```

五案例本地 smoke：

```bash
bash scripts/run_cases.sh --case all --with-formal --smoke
bash scripts/run_cases.sh --case all --no-formal --smoke
```

04 严格 UCAgent full demo：

```bash
source .ucagent_env
bash scripts/run_cases.sh --case 04 --with-formal
```

## 结论

本项目不是纯 AI 生成测试，而是把形式验证、Picker/Toffee 动态验证和人工验证策略组织成可复用工具链。`generic-formal` 让 UCAgent 获得可执行的反例搜索能力；`verify_verilog.sh` 让任意 RTL 模块可以先进入本地 smoke，再逐步加入功能性质。
