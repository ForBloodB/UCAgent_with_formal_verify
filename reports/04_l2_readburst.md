# 04 L2 readBurst Ready/Valid Candidate

- Dynamic replay report：`reports/artifacts/04_l2_readburst/dynamic_readburst_ready_deadlock.md`
- Waveform screenshot：`reports/assets/04_l2_readburst_ready_valid_waveform.png`

## 结论

在标准 Decoupled ready/valid 语义下，当前情况是一个很强的 candidate bug；但如果 NutShell 设计者额外规定 L1 必须一直 ready，则需要在设计文档中明确写出这个环境假设。

公开关联线索：NutShell issue [#95 Ready signal depends on valid signal in cache?](https://github.com/OSCPU/NutShell/issues/95) 已经在 2022 年提出 Cache 中 `io.out.valid` 依赖 `io.out.ready` 的 ready/valid 协议风险。04 案例的价值是把同类风险收敛到 latest L2 readBurst hit backpressure 场景，并提供 formal 与动态复现路径。

![04 ready/valid waveform](assets/04_l2_readburst_ready_valid_waveform.png)

## 动态复现

- 分类：`DYNAMIC_REPRODUCED`
- 报告：`reports/artifacts/04_l2_readburst/dynamic_readburst_ready_deadlock.md`
- 首次 bug marker cycle：`44`
- 最后一次 bug marker cycle：`59`
- 最后记录 cycle：`67`
- bug 触发后继续记录周期数：`23`

public-IO 仿真复现了 ready/valid deadlock 风险：同地址 L2 readBurst hit 停留在 S3 且 L1 侧 `resp_ready=0` 时，`io_cpu_resp_valid` 也保持为低。

当前 VCD 覆盖首次 bug marker 后至少 `23` 个周期；其中 cycle 45 到 cycle 54 是“触发之后 10 个循环”的核心观察窗口。

## 复现方式

```bash
bash scripts/docker_run.sh bash scripts/run_cases.sh --case 04 --with-formal --smoke
```

严格 UCAgent 流程需要配置 `.ucagent_env` 后运行：

```bash
bash scripts/docker_run.sh bash scripts/run_cases.sh --case 04 --with-formal
```
