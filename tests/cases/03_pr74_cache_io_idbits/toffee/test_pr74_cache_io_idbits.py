from Pr74CacheIOIdBits_api import *  # noqa: F401,F403


def test_pr74_fixed_preserves_response_id(fixed_env):
    coverage = fixed_env.run_id_replay()
    write_pr74_report(
        {
            "fixed": coverage.as_dict(),
            "classification": coverage.classification(),
        },
        source="human-refined Toffee replay from UCAgent draft",
    )
    assert coverage.setup_hit() == coverage.setup_total(), coverage.as_dict()
    assert coverage.response_id_matched, coverage.as_dict()
