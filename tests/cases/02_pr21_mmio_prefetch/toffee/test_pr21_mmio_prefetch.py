from Pr21MmioPrefetch_api import *  # noqa: F401,F403


def test_pr21_pre_reproduces_mmio_prefetch_pipeline_bug(pre_env):
    coverage = pre_env.run_counterexample_replay()
    write_pr21_report(
        {
            "pre": coverage.as_dict(),
            "fixed": None,
            "classification": coverage.classification(expected_bug=True),
        },
        source="human-refined Toffee replay from UCAgent draft",
    )
    assert coverage.setup_hit() == coverage.setup_total(), coverage.as_dict()
    assert coverage.bug_observed, coverage.as_dict()


def test_pr21_fixed_reaches_same_window_without_dynamic_fail_assertion(fixed_env):
    coverage = fixed_env.run_counterexample_replay()
    write_pr21_report(
        {
            "pre": None,
            "fixed": coverage.as_dict(),
            "classification": coverage.classification(expected_bug=False),
        },
        source="human-refined Toffee replay from UCAgent draft",
    )
    assert coverage.setup_hit() == coverage.setup_total(), coverage.as_dict()
