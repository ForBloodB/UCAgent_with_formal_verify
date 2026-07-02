# 04 L2 readBurst Toffee 覆盖率报告

- 分类：`DYNAMIC_REPRODUCED`
- 04 场景 setup coverage：`5/5 = 100.0%`
- 覆盖口径：只统计本场景 coverpoints，不代表完整 NutShell Cache functional coverage。
- Python DUT：`reports/artifacts/04_l2_readburst/toffee_dut`
- Toffee waveform：`reports/artifacts/04_l2_readburst/toffee/l2_readburst_ready_deadlock.fst`
- Coverage JSON：`reports/artifacts/04_l2_readburst/toffee/coverage_summary.json`
- 来源：`case-local directed Toffee test`

## Coverpoints

| Coverpoint | Hit |
| --- | --- |
| first readBurst miss | `True` |
| memory refill readlast | `True` |
| second same-address readBurst | `True` |
| S3 readBurst hit | `True` |
| ready low during hit | `True` |
| resp_valid low during ready-low hit | `True` |

## 关键事件

- C26: memory readBurst request accepted
- C34: first readBurst refill reached readlast
- C41: second readBurst hit reached S3
- C42: resp_valid stayed low while ready was low on a readBurst hit

## 人工判定

该 Toffee directed test 使用真实 Picker 导出的 latest NutShell Cache wrapper，
通过 public IO 完成 miss/refill/hit/ready-low 序列，不 force 内部状态。
当 `resp_ready=0` 且 S3 为 `readBurst hit` 时观察到 `resp_valid=0`，
因此分类为 `DYNAMIC_REPRODUCED`。该结论仍表述为 latest upstream candidate bug，
需要结合 NutShell 对该接口 ready/valid 协议的设计约束最终确认。
