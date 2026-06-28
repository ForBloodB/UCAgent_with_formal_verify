# 02 PR21 Toffee 动态后端报告

- 分类：`DYNAMIC_PRE_REPRODUCED_FIXED_EDGE_SAMPLING_LIMIT`
- 覆盖口径：PR21 MMIO prefetch 场景级 coverpoints，不代表完整 Cache functional coverage。
- Python DUT pre：`reports/artifacts/02_pr21/toffee_dut_pre`
- Python DUT fixed：`reports/artifacts/02_pr21/toffee_dut_fixed`
- Coverage JSON：`reports/artifacts/02_pr21/toffee/coverage_summary.json`
- 来源：`human-refined Toffee replay from UCAgent draft`

## 结果

| Variant | setup_hit/setup_total | bug_observed |
| --- | --- | --- |
| `pre` | `5/5` | `True` |
| `fixed` | `5/5` | `True` |

## Bug oracle

PR21 formal 属性检查的不是“MMIO prefetch 与 S3 正常请求同拍出现”本身，而是该窗口后一拍 S3 中已有正常请求不能被清掉。因此动态 scoreboard 将 `overlap_window_seen` 作为 setup bin，将 `s3_dropped_after_overlap` 作为 bug observation bin。

注意：Toffee/Python 读取 probe 的时间点是 Verilator `Step` 后状态，而 formal immediate assertion 在 posedge 语义下检查的是边沿采样值。fixed 版本的 public-probe replay 因此只作为动态覆盖证据，不作为 fixed 失败证据；fixed 是否消除该 bug 以 PR21 formal fixed PASS 为准。

## 人工干预

- UCAgent 负责生成 Toffee/API/pytest 草稿结构。
- 人工根据 PR21 历史反例 trace 收敛 directed replay、scoreboard 和 coverage。
- 本动态后端不调用 formal skill。
