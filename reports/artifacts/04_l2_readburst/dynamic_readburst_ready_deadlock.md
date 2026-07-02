# L2 ReadBurst Ready/Valid 动态仿真

- 分类：`DYNAMIC_REPRODUCED`
- RTL: `tests/cases/04_l2_readburst_hit_ready_valid_deadlock/formal/generated/latest/FreshCacheFormalDut.sv`
- Testbench: `tests/cases/04_l2_readburst_hit_ready_valid_deadlock/sim/readburst_ready_deadlock_tb.sv`
- 日志：`reports/artifacts/04_l2_readburst/artifacts/dynamic_readburst_ready_deadlock.log`
- VCD: `reports/artifacts/04_l2_readburst/artifacts/dynamic_readburst_ready_deadlock.vcd`
- 首次 bug marker cycle：`41`
- 最后一次 bug marker cycle：`56`
- 最后记录 cycle：`64`
- bug 触发后继续记录周期数：`23`

## 场景

1. 复位生成的 latest-upstream NutShell L2 Cache wrapper。
2. 发送一次同地址 `readBurst` 请求，让简单内存模型完成 miss/refill。
3. 发送第二次同地址 `readBurst` 请求，预期命中刚 refill 的 cache line。
4. 当请求到达 S3，且满足 `valid && hit && readBurst` 时，将 `io_cpu_resp_ready=0` 保持 16 个周期。
5. 检查在 ready-low hit 窗口中 `io_cpu_resp_valid` 是否保持为低。

## 结果

public-IO 仿真复现了 ready/valid deadlock 风险：同地址 L2 readBurst hit 停留在 S3 且 L1 侧 `resp_ready=0` 时，`io_cpu_resp_valid` 也保持为低。

当前 VCD 覆盖首次 bug marker 后至少 `23` 个周期；其中 cycle 45 到 cycle 54 是“触发之后 10 个循环”的核心观察窗口。

这是 directed dynamic replay，只使用 wrapper public ports。它不会初始化或 force Cache 内部状态。
