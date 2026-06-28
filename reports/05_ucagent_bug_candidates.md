# 05 UCAgent Bug Candidates

候选点只有在具备 formal 反例或动态 scoreboard 失败证据后，才能升级为 candidate bug；其余保持 hypothesis。

## Latest candidate bugs with evidence

| Candidate | Evidence Level | 分类 | 触发条件 | 证据 |
| --- | --- | --- | --- | --- |
| `CAND_LATEST_L2_READBURST_READY_VALID` | `formal_counterexample` | `latest_candidate_bug`, `formal_detected`, `dynamic_reproduced`, `human_refined` | Same-address readBurst miss/refill followed by readBurst hit while L1 resp_ready is low. | `reports/05_full_cache_coverage_plan.md`<br>`reports/05_ucagent_bug_candidates.md` |

## Latest hypotheses suggested by UCAgent/human refinement

| ID | Evidence Level | 分类 | 建议触发条件 | 当前处理 |
| --- | --- | --- | --- | --- |
| `HYP_FLUSH_OUTSTANDING_MISS` | `ucagent_hypothesis_only` | `latest_hypothesis`, `UCAgent_suggested`, `human_refined` | Issue a read miss, hold memory response, assert flush, then release memory response. | 05 declared closure uses an outstanding tracker; a future real-DUT formal property should be added if the public Cache flush contract is clarified. |
| `HYP_DIRTY_EVICTION_ORDER` | `ucagent_hypothesis_only` | `latest_hypothesis`, `UCAgent_suggested`, `human_refined` | Dirty a line, force conflict replacement, and observe whether writeback precedes refill. | 05 reference model closes the declared coverage bin; future work can bind the same oracle to a wider randomized real-DUT regression. |
| `HYP_PARTIAL_MASK_MERGE` | `ucagent_hypothesis_only` | `latest_hypothesis`, `UCAgent_suggested`, `human_refined` | Write alternating byte masks to a cached word and read back the untouched lanes. | 05 byte-level scoreboard closes the declared partial-mask bin. |
