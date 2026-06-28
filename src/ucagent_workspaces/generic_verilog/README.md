# Generic Verilog UCAgent Workspace

This workspace is a reusable shell for arbitrary Verilog/SystemVerilog modules.

The public entrypoint is:

```bash
bash scripts/verify_verilog.sh --rtl path/to/dut.sv --top MyDut
```

`scripts/verify_verilog.sh` creates a case-local copy of this workspace under
`reports/generic_verilog/<top>/ucagent_workspace/`, then asks UCAgent to call the
`generic-formal` skill on the generated formal case.
