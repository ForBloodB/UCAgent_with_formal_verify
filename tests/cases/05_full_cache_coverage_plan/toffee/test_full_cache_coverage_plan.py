from FullCacheCoveragePlan_api import load_plan, run_declared_coverage_closure, summarize_plan, write_report


def test_full_cache_declared_coverage_closure_is_complete():
    plan = load_plan()
    summary = summarize_plan(plan)
    write_report(plan, summary)

    assert "15 latest NutShell Cache functional coverage points" in plan["scope"]
    assert summary["counts"]["total"] == 15
    assert summary["counts"]["implemented"] == 15
    assert summary["counts"].get("partial", 0) == 0
    assert summary["counts"].get("gap", 0) == 0
    assert summary["coverage_percent"] == 100.0
    assert summary["crv_gap"] == 0
    assert summary["scoreboard_gap"] == 0
    assert not summary["missing_evidence"], summary["missing_evidence"]
    assert not summary["bug_missing_evidence"], summary["bug_missing_evidence"]
    assert not summary["closure"]["missing_bins"], summary["closure"]["missing_bins"]


def test_case05_is_latest_only_and_excludes_historical_bugs():
    plan = load_plan()
    serialized = repr(plan)
    forbidden = ["PR21", "PR74", "02_pr21", "03_pr74", "historical_real_bug"]
    for token in forbidden:
        assert token not in serialized

    bug_ids = {item["id"]: item for item in plan["bug_points"]}

    assert set(bug_ids) == {"CAND_LATEST_L2_READBURST_READY_VALID"}

    latest = bug_ids["CAND_LATEST_L2_READBURST_READY_VALID"]
    assert "latest_candidate_bug" in latest["classification"]
    assert "formal_detected" in latest["classification"]
    assert "dynamic_reproduced" in latest["classification"]

    mapped = {coverage_id for bug in bug_ids.values() for coverage_id in bug["mapped_coverage"]}
    assert "CP_READBURST_HIT_BACKPRESSURE" in mapped
    assert "CP_READY_VALID_RESP_STABILITY" in mapped


def test_reference_scoreboard_hits_all_declared_bins():
    plan = load_plan()
    closure = run_declared_coverage_closure(plan)

    assert len(closure["expected_bins"]) == 15
    assert sorted(closure["hit_bins"]) == sorted(closure["expected_bins"])
    assert "refill.order_last_beat" in closure["hit_bins"]
    assert "interface.uncached_atomic_bypass_policy" in closure["hit_bins"]
    assert closure["writeback_count"] >= 1
    assert not closure["unexpected_bins"], closure["unexpected_bins"]


def test_methodology_blocks_remain_explicit():
    plan = load_plan()
    assert {"human", "ucagent", "picker", "toffee", "formal_skill"} <= set(plan["roles"].keys())
    assert {"reference_memory", "outstanding_tracker", "protocol_monitor", "cache_state_shadow", "refill_and_policy_monitor"} <= set(
        plan["scoreboard_plan"].keys()
    )
    assert len(plan["crv_scenarios"]) == 6
    assert "bug_candidate_report" in plan["coverage_database"]
