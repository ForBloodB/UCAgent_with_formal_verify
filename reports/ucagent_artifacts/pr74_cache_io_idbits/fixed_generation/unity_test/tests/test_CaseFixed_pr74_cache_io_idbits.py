#coding=utf-8

from CaseFixed_api import *
from CaseFixed import DUTCaseFixed
from CaseFixed_function_coverage_def import get_coverage_groups
import pytest


def _make_env():
    dut = DUTCaseFixed()
    groups = get_coverage_groups(dut)
    dut.StepRis(lambda _: [g.sample() for g in groups])
    env = CaseFixedEnv(dut)
    fc_cover = {g.name: g for g in groups}
    return dut, env, fc_cover


def test_nonzero_request_id_preserved():
    """测试单个非零请求ID的传递保持功能

    验证对于非零req_id（如0xA），resp_id必须等于req_id，
    不会被DUT内部逻辑错误地置零。
    这是对CK-NONZERO_ID_PRESERVED检测点的验证。
    """
    dut, env, fc_cover = _make_env()
    try:
        fc_cover["FG-API"].mark_function(
            "FC-ID_ROUNDTRIP",
            test_nonzero_request_id_preserved,
            ["CK-NONZERO_ID_PRESERVED"],
        )
        # 使用README建议的典型非零ID值0xA
        test_req_id = 0xA
        resp_id = api_CaseFixed_id_roundtrip(env, test_req_id)
        assert resp_id == test_req_id, (
            f"非零req_id={test_req_id:#x} 的resp_id={resp_id:#x}不匹配，"
            f"期望resp_id={test_req_id:#x}"
        )
    finally:
        dut.Finish()


def test_multiple_request_ids_preserved():
    """测试多个不同非零请求ID的传递保持功能

    验证多个不同非零req_id（典型值、边界值、特殊值）都能正确传递，
    resp_id必须等于req_id，避免只检查单一常量的情况。
    这是对CK-MULTIPLE_ID_VALUES检测点的验证。
    """
    dut, env, fc_cover = _make_env()
    try:
        fc_cover["FG-API"].mark_function(
            "FC-ID_ROUNDTRIP",
            test_multiple_request_ids_preserved,
            ["CK-MULTIPLE_ID_VALUES"],
        )
        # 使用多种非零ID值确保覆盖：
        # - 边界值：最小值0x1，最大值0xF
        # - 典型值：0x5, 0xA（README建议）
        # - 特殊值：0x7（中间值），0x3
        test_req_ids = [0x1, 0x3, 0x5, 0x7, 0xA, 0xF]
        for test_req_id in test_req_ids:
            resp_id = api_CaseFixed_id_roundtrip(env, test_req_id)
            assert resp_id == test_req_id, (
                f"非零req_id={test_req_id:#x} 的resp_id={resp_id:#x}不匹配，"
                f"期望resp_id={test_req_id:#x}"
            )
    finally:
        dut.Finish()
