# L2ReadBurstDeadlock DUT Shell

This is a UCAgent task shell. The real DUT is generated from latest
OSCPU/NutShell `nutcore.Cache` by the case-local prepare script.

Two active flows use this shell:

- Formal flow: use `generic-formal` with the two YAML cases under
  `tests/cases/04_l2_readburst_hit_ready_valid_deadlock/formal/`.
- Toffee dynamic flow: use Picker to export `FreshCacheFormalDut` as a Python
  DUT, then run the official UCAgent `unity_test/tests` pytest flow.

Do not create compact replacement RTL. The Toffee test must drive the public IO
of the generated `FreshCacheFormalDut` wrapper.
