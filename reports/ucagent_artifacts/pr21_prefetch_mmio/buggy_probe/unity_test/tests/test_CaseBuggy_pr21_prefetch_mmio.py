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


def test_mmio_prefetch_suppressed():
    dut, env, fc_cover = _make_env()
    try:
        fc_cover["FG-API"].mark_function(
            "FC-MMIO_PREFETCH_SUPPRESSION",
            test_mmio_prefetch_suppressed,
            ["CK-MMIO_PREFETCH_SUPPRESSED"],
        )
        pytest.fail("UCAgent should implement this template")
    finally:
        dut.Finish()


def test_mmio_prefetch_does_not_flush_pending_request():
    dut, env, fc_cover = _make_env()
    try:
        fc_cover["FG-API"].mark_function(
            "FC-MMIO_PREFETCH_SUPPRESSION",
            test_mmio_prefetch_does_not_flush_pending_request,
            ["CK-MMIO_NO_FLUSH"],
        )
        pytest.fail("UCAgent should implement this template")
    finally:
        dut.Finish()
