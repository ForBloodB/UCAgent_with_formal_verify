from FullCacheCoveragePlan_api import load_plan, summarize_plan, write_report


def test_full_cache_coverage_plan_is_traceable_and_honest():
    plan = load_plan()
    summary = summarize_plan(plan)
    write_report(plan, summary)

    assert plan["scope"].startswith("Plan-level coverage")
    assert summary["counts"]["total"] >= 12
    assert summary["counts"]["implemented"] >= 3
    assert summary["counts"]["gap"] >= 5
    assert "l1_resp_ready_policy" in summary["open_environment_assumptions"]
    assert not summary["missing_evidence"], summary["missing_evidence"]


def test_full_cache_coverage_plan_has_required_methodology_blocks():
    plan = load_plan()
    assert {"human", "ucagent", "picker", "toffee", "formal_skill"} <= set(plan["roles"].keys())
    assert {"reference_memory", "outstanding_tracker", "protocol_monitor", "cache_state_shadow"} <= set(
        plan["scoreboard_plan"].keys()
    )
    assert len(plan["crv_scenarios"]) >= 5
    assert "coverage_database" in plan

