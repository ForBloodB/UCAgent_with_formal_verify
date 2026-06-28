# 05 Manual Verilog Validation

This directory contains hand-written Verilog validation for the three UCAgent-suggested hypotheses that did not have formal counterexamples.

Run:

```bash
bash tests/cases/05_full_cache_coverage_plan/manual/run_manual_verilog.sh
```

Outputs:

- `reports/05_manual_verilog_validation.md`
- `reports/artifacts/05_full_cache_coverage_plan/manual_hypothesis_probe.log`
- `reports/artifacts/05_full_cache_coverage_plan/manual_hypothesis_probe.vcd`

The VCD is meant for human waveform inspection. This probe is an executable Verilog oracle for triage; it is not a full NutShell Cache RTL replay.
