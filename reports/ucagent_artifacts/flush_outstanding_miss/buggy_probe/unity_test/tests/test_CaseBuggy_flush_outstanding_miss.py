#coding=utf-8

from CaseBuggy_api import *
from CaseBuggy import DUTCaseBuggy
from CaseBuggy_function_coverage_def import get_coverage_groups
import pytest


def _make_env():
    dut = DUTCaseBuggy()
    groups = get_coverage_groups(dut)
    dut.StepRis(lambda _: [g.sample() for g in groups])
    env = CaseBuggyEnv(dut)
    fc_cover = {g.name: g for g in groups}
    return dut, env, fc_cover


def test_flush_before_refill_no_early_response():
    dut, env, fc_cover = _make_env()
    try:
        fc_cover["FG-API"].mark_function(
            "FC-FLUSH_REFILL_ORDERING",
            test_flush_before_refill_no_early_response,
            ["CK-FLUSH_BEFORE_REFILL_NO_RESPONSE"],
        )
        pytest.fail("UCAgent should implement this template")
    finally:
        dut.Finish()


def test_refill_response_after_memory():
    dut, env, fc_cover = _make_env()
    try:
        fc_cover["FG-API"].mark_function(
            "FC-FLUSH_REFILL_ORDERING",
            test_refill_response_after_memory,
            ["CK-REFILL_RESPONSE_ALLOWED"],
        )
        pytest.fail("UCAgent should implement this template")
    finally:
        dut.Finish()
