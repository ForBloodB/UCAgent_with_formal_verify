# FullCacheCoveragePlan DUT Shell

This case uses a pytest/Toffee-style executable checker to close the 15
functional coverage points declared in `cache_coverage_plan.yaml`.

The executable artifact is a pytest suite under `unity_test/tests`, run by
UCAgent through `RunTestCases`. In formal-first mode, UCAgent also calls the
generic-formal skill before running this dynamic/checker backend.
