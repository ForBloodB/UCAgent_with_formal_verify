from L2ReadBurstDeadlock_api import *  # noqa: F401,F403


def test_l2_readburst_hit_ready_valid_deadlock(env):
    mark_readburst_function(env, test_l2_readburst_hit_ready_valid_deadlock)
    coverage = env.run_directed_replay()
    write_toffee_report(coverage, env.events, source="case-local directed Toffee test")

    assert coverage.setup_hit() == coverage.setup_total(), coverage.as_dict()
    assert coverage.resp_valid_low_during_ready_low_hit, coverage.as_dict()
