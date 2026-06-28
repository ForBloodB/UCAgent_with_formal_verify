# 添加新的 Verilog/SystemVerilog 模块

## 1. 先做本地 smoke

```bash
bash scripts/verify_verilog.sh \
  --rtl path/to/dut.sv \
  --top MyDut \
  --depth 8 \
  --smoke
```

该步骤会运行：

- Yosys parse/elaboration；
- 自动生成 basic formal smoke harness；
- 调用 `src/ucagent_skills/generic-formal/scripts/run_formal.py`。

输出位于：

```text
reports/generic_verilog/<top>/
```

## 2. 加入有意义的性质

basic smoke 不能证明功能正确性。要验证真实 bug 或协议性质，需要提供 property/harness：

```bash
bash scripts/verify_verilog.sh \
  --rtl path/to/dut.sv \
  --property path/to/my_property.sv \
  --top my_formal_top \
  --define OPTIONAL_MACRO \
  --depth 32 \
  --smoke
```

`my_property.sv` 应实例化 DUT，并包含 `assert`、`assume`、`cover`。

## 3. 接入 UCAgent

非 smoke 模式会先执行同样的本地验证，然后调用真实 UCAgent API：读取 `generic-formal` skill、通过 `RunSkillScript` 复跑生成的 YAML case，并输出后续性质或 harness 建议。若希望 UCAgent 进一步直接生成 harness 草稿，可以在该通用 workspace 的 prompt 上扩展；生成的性质仍需要人工审查，避免 AI 误解设计意图。

```bash
source .ucagent_env
bash scripts/verify_verilog.sh \
  --rtl path/to/dut.sv \
  --top MyDut \
  --clock clock \
  --reset reset \
  --depth 32
```

## 能力边界

- 任意可被 Yosys/Verilator 解析的模块，都可以进入 lint/elaboration/basic formal smoke。
- 功能级 bug 检出依赖 property、reference model 或人工确认后的 UCAgent 生成 harness。
- `generic-formal` 是 runner，不是自动设计意图推理器。
