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


def test_flush_before_refill_no_early_response():
    """测试Flush期间不会提前响应cpu_resp_valid

    测试场景：
    - miss_outstanding=1: 存在未完成的缺失事务
    - flush_valid=1: flush请求到达
    - mem_resp_valid=0: refill尚未到达

    预期行为：
    - cpu_resp_valid 必须为0（flush期间禁止提前响应）

    根据芯片规格，DUT的正确行为是cpu_resp_valid = miss_outstanding & mem_resp_valid，
    当flush_valid有效但mem_resp_valid无效时，cpu_resp_valid应为0。
    """
    dut, env, fc_cover = _make_env()
    try:
        fc_cover["FG-API"].mark_function(
            "FC-FLUSH_REFILL_ORDERING",
            test_flush_before_refill_no_early_response,
            ["CK-FLUSH_BEFORE_REFILL_NO_RESPONSE"],
        )
        # 典型值场景：flush期间mem_resp无效
        cpu_resp = api_CaseFixed_response(env, miss_outstanding=1, flush_valid=1, mem_resp_valid=0)
        assert cpu_resp == 0, (
            f"flush期间不应提前响应cpu_resp_valid："
            f"miss_outstanding=1, flush_valid=1, mem_resp_valid=0 → cpu_resp_valid={cpu_resp}, 预期=0"
        )
    finally:
        dut.Finish()


def test_refill_response_after_memory():
    """测试Flush之后refill到达时允许cpu_resp_valid响应

    测试场景：
    - miss_outstanding=1: 存在未完成的缺失事务
    - flush_valid=0: flush已结束
    - mem_resp_valid=1: refill到达

    预期行为：
    - cpu_resp_valid 可能为1（refill到达后可正常响应）

    根据芯片规格，DUT的正确行为是cpu_resp_valid = miss_outstanding & mem_resp_valid，
    当flush结束且mem_resp有效时，cpu_resp_valid应为1。
    """
    dut, env, fc_cover = _make_env()
    try:
        fc_cover["FG-API"].mark_function(
            "FC-FLUSH_REFILL_ORDERING",
            test_refill_response_after_memory,
            ["CK-REFILL_RESPONSE_ALLOWED"],
        )
        # 典型值场景：refill到达，flush已结束
        cpu_resp = api_CaseFixed_response(env, miss_outstanding=1, flush_valid=0, mem_resp_valid=1)
        assert cpu_resp == 1, (
            f"refill到达后应允许响应cpu_resp_valid："
            f"miss_outstanding=1, flush_valid=0, mem_resp_valid=1 → cpu_resp_valid={cpu_resp}, 预期=1"
        )
    finally:
        dut.Finish()
