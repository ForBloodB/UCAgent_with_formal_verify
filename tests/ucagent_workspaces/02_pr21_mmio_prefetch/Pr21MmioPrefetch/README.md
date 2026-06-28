# Pr21MmioPrefetch

This DUT label refers to the real NutShell Cache PR #21 MMIO prefetch case.

Expected formal result:

- pre-PR parent `bd425dee`: `FAIL`, counterexample found.
- fixed PR branch `f0d7c494`: `PASS`.

Original no-formal UCAgent flow has no Picker/Toffee dynamic DUT for this historical case, so it should report that it cannot independently reproduce the bug without the formal skill or an added dynamic harness.
