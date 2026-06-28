# FullCacheCoveragePlan DUT Shell

This case uses a pytest/Toffee-style executable checker to close the 15 latest
NutShell Cache functional coverage points declared in
`cache_coverage_plan.yaml`.

The executable artifact is a pytest suite under `unity_test/tests`, run by
UCAgent through `RunTestCases`. The official 05 flow is formal-enabled:
UCAgent calls the generic-formal skill before running this dynamic/checker
backend.
