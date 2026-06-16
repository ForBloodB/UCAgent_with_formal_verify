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


def test_nonzero_request_id_preserved():
    dut, env, fc_cover = _make_env()
    try:
        fc_cover["FG-API"].mark_function(
            "FC-ID_ROUNDTRIP",
            test_nonzero_request_id_preserved,
            ["CK-NONZERO_ID_PRESERVED"],
        )
        pytest.fail("UCAgent should implement this template")
    finally:
        dut.Finish()


def test_multiple_request_ids_preserved():
    dut, env, fc_cover = _make_env()
    try:
        fc_cover["FG-API"].mark_function(
            "FC-ID_ROUNDTRIP",
            test_multiple_request_ids_preserved,
            ["CK-MULTIPLE_ID_VALUES"],
        )
        pytest.fail("UCAgent should implement this template")
    finally:
        dut.Finish()
