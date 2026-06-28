# 05 Manual Verilog Validation

- 分类：`MANUAL_VERILOG_NOT_REPRODUCED`
- Testbench：`tests/cases/05_full_cache_coverage_plan/manual/manual_hypothesis_probe_tb.sv`
- Probe RTL：`tests/cases/05_full_cache_coverage_plan/manual/manual_hypothesis_probe.sv`
- Log：`reports/artifacts/05_full_cache_coverage_plan/manual_hypothesis_probe.log`
- VCD：`reports/artifacts/05_full_cache_coverage_plan/manual_hypothesis_probe.vcd`

## 人工验证方式

这一部分不是 UCAgent 自动判定，也不是 Python reference model。它由人工编写 Verilog probe 和 Verilog testbench，通过 `iverilog + vvp` 对 UCAgent 给出的三个触发条件直接施加激励，并生成 VCD 供人工查看。

查看波形：

```bash
gtkwave reports/artifacts/05_full_cache_coverage_plan/manual_hypothesis_probe.vcd
```

建议观察信号：

- flush outstanding miss：`miss_start`, `flush`, `mem_resp_valid`, `outstanding_valid`, `miss_cancelled`, `cpu_resp_valid`, `line_allocated_after_flush`
- dirty eviction ordering：`fill_old_line`, `write_full_line`, `conflict_access`, `dirty`, `writeback_valid`, `refill_valid`
- partial mask merge：`init_word`, `partial_write`, `partial_wmask`, `partial_wdata`, `partial_word`

## 结论

| ID | UCAgent 触发条件 | 人工 Verilog 波形复查 |
| --- | --- | --- |
| `HYP_FLUSH_OUTSTANDING_MISS` | Issue a read miss, hold memory response, assert flush, then release memory response. | 未复现为 bug：flush 后 outstanding miss 被取消，随后 memory response 不产生 CPU stale response，也不分配 line。 |
| `HYP_DIRTY_EVICTION_ORDER` | Dirty a line, force conflict replacement, and observe whether writeback precedes refill. | 未复现为 bug：replacement 窗口中 `writeback_valid` 与 refill 事件同时可见，说明 dirty victim 没有被静默丢弃。 |
| `HYP_PARTIAL_MASK_MERGE` | Write alternating byte masks to a cached word and read back the untouched lanes. | 未复现为 bug：`partial_wmask=4'b0101` 后，未使能字节保持原值，`partial_word=32'h44CC_22AA`。 |

因此，这三个点在当前人工 Verilog 波形复查下归类为 **UCAgent 高风险建议/误判，未升级为 candidate bug**。05 中仍保留为 candidate bug 的只有 `CAND_LATEST_L2_READBURST_READY_VALID`，它有 formal counterexample 和动态复现证据。

## 边界

该 manual probe 是为复查 UCAgent hypothesis 而写的可执行 Verilog oracle，不声明等价于完整 NutShell Cache RTL 的全接口回放。若要对真实 RTL 做最终签核，需要继续扩展 latest Cache wrapper，暴露 write mask、dirty victim writeback、flush contract 等公共观测点。
