# 05 UCAgent Bug Candidates

本报告区分历史真实 bug、latest candidate bug、以及 UCAgent 建议但尚未升级为真实 bug 的假设。
候选点只有在具备 formal 反例或动态 scoreboard 失败证据后，才能升级为 detected/candidate bug。

## 已有证据的 bug points

| ID | 分类 | 触发条件 | 证据 |
| --- | --- | --- | --- |
| `BUG_PR21_MMIO_PREFETCH_PIPELINE` | `historical_real_bug`, `formal_detected`, `dynamic_reproduced`, `human_refined` | An existing normal cache pipeline request reaches the later stage while an MMIO prefetch appears in the front stage. | `reports/02_pr21.md`<br>`reports/02_pr21_ucagent_formal_skill.md`<br>`reports/02_pr21_toffee_coverage.md` |
| `BUG_PR74_CACHE_IO_IDBITS` | `historical_real_bug`, `formal_detected`, `human_refined` | OOO-style Cache configuration requires request/response id fields, but pre-PR CacheIO omitted idBits. | `reports/03_pr74.md`<br>`reports/03_pr74_ucagent_formal_skill.md`<br>`reports/03_pr74_toffee_coverage.md` |
| `BUG_04_L2_READBURST_READY_VALID` | `UCAgent_suggested`, `human_refined`, `formal_detected`, `dynamic_reproduced` | Same-address readBurst miss/refill followed by readBurst hit while L1 resp_ready is low. | `reports/04_l2_readburst.md`<br>`reports/04_l2_readburst_ucagent_full_demo.md`<br>`reports/04_l2_readburst_toffee_coverage.md` |

## UCAgent 建议但需人工签核的后续假设

| ID | 分类 | 建议触发条件 | 当前处理 |
| --- | --- | --- | --- |
| `HYP_FLUSH_OUTSTANDING_MISS` | `UCAgent_suggested`, `human_refined` | Issue a read miss, hold memory response, assert flush, then release memory response. | 05 declared closure uses an outstanding tracker; a future real-DUT formal property should be added if the public Cache flush contract is clarified. |
| `HYP_DIRTY_EVICTION_ORDER` | `UCAgent_suggested`, `human_refined` | Dirty a line, force conflict replacement, and observe whether writeback precedes refill. | 05 reference model closes the declared coverage bin; future work can bind the same oracle to a wider randomized real-DUT regression. |
| `HYP_PARTIAL_MASK_MERGE` | `UCAgent_suggested`, `human_refined` | Write alternating byte masks to a cached word and read back the untouched lanes. | 05 byte-level scoreboard closes the declared partial-mask bin. |
