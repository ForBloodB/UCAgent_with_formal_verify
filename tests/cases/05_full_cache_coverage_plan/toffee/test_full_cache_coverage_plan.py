from FullCacheCoveragePlan_api import load_plan, run_declared_coverage_closure, summarize_plan, write_report


def test_full_cache_declared_coverage_closure_is_complete():
    plan = load_plan()
    summary = summarize_plan(plan)
    write_report(plan, summary)

    assert "15 functional coverage points" in plan["scope"]
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


def test_pr21_pr74_and_l2_readburst_bug_points_are_first_class_coverage():
    plan = load_plan()
    bug_ids = {item["id"]: item for item in plan["bug_points"]}

    assert {
        "BUG_PR21_MMIO_PREFETCH_PIPELINE",
        "BUG_PR74_CACHE_IO_IDBITS",
        "BUG_04_L2_READBURST_READY_VALID",
    } <= set(bug_ids)

    assert "historical_real_bug" in bug_ids["BUG_PR21_MMIO_PREFETCH_PIPELINE"]["classification"]
    assert "historical_real_bug" in bug_ids["BUG_PR74_CACHE_IO_IDBITS"]["classification"]
    assert "formal_detected" in bug_ids["BUG_04_L2_READBURST_READY_VALID"]["classification"]
    assert "dynamic_reproduced" in bug_ids["BUG_04_L2_READBURST_READY_VALID"]["classification"]

    mapped = {coverage_id for bug in bug_ids.values() for coverage_id in bug["mapped_coverage"]}
    assert "CP_MMIO_PREFETCH_PIPELINE_INTERFERENCE" in mapped
    assert "CP_CACHE_IO_IDBITS" in mapped
    assert "CP_READBURST_HIT_BACKPRESSURE" in mapped
    assert "CP_READY_VALID_RESP_STABILITY" in mapped


def test_reference_scoreboard_hits_all_declared_bins():
    plan = load_plan()
    closure = run_declared_coverage_closure(plan)

    assert len(closure["expected_bins"]) == 15
    assert sorted(closure["hit_bins"]) == sorted(closure["expected_bins"])
    assert closure["writeback_count"] >= 1
    assert not closure["unexpected_bins"], closure["unexpected_bins"]


def test_methodology_blocks_remain_explicit():
    plan = load_plan()
    assert {"human", "ucagent", "picker", "toffee", "formal_skill"} <= set(plan["roles"].keys())
    assert {"reference_memory", "outstanding_tracker", "protocol_monitor", "cache_state_shadow"} <= set(
        plan["scoreboard_plan"].keys()
    )
    assert len(plan["crv_scenarios"]) == 6
    assert "bug_candidate_report" in plan["coverage_database"]
