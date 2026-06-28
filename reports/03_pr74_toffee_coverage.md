# 03 PR74 Toffee 动态后端报告

- 分类：`FIXED_DYNAMIC_PASS`
- pre-PR 动态后端状态：`PICKER_EXPORT_EXPECTED_FAIL`，该历史 bug 是接口/elaboration 失败。
- fixed Python DUT：`reports/artifacts/03_pr74/toffee_dut_fixed`
- Coverage JSON：`reports/artifacts/03_pr74/toffee/coverage_summary.json`
- 来源：`human-refined Toffee replay from UCAgent draft`

## fixed Toffee 结果

| setup_hit/setup_total | response_id_matched |
| --- | --- |
| `5/5` | `True` |

## 人工干预

- UCAgent 负责生成 Toffee/API/pytest 草稿结构。
- 人工补充 fixed response ID scoreboard 和 coverage。
- 本动态后端不调用 formal skill。
