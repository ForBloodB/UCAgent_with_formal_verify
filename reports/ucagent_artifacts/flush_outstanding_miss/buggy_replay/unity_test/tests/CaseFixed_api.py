#coding=utf-8

import os
import pytest
import ucagent
from toffee_test.reporter import set_func_coverage, set_line_coverage, get_file_in_tmp_dir
from toffee_test.reporter import set_user_info, set_title_info
from CaseFixed_function_coverage_def import get_coverage_groups
from CaseFixed import DUTCaseFixed


def current_path_file(file_name):
    return os.path.join(os.path.dirname(os.path.abspath(__file__)), file_name)


def get_coverage_data_path(request, new_path: bool):
    tc_name = request.node.name if request is not None else "CaseFixed"
    return get_file_in_tmp_dir(request, current_path_file("data/"), f"{tc_name}.dat", new_path=new_path)


def get_waveform_path(request, new_path: bool):
    tc_name = request.node.name if request is not None else "CaseFixed"
    return get_file_in_tmp_dir(request, current_path_file("data/"), f"{tc_name}.fst", new_path=new_path)


def create_dut(request):
    if ucagent.is_imp_test_template():
        return ucagent.get_fake_dut(DUTCaseFixed)
    dut = DUTCaseFixed()
    dut.SetCoverage(get_coverage_data_path(request, new_path=True))
    dut.SetWaveform(get_waveform_path(request, new_path=True))
    return dut


@pytest.fixture(scope="function")
def dut(request):
    dut = create_dut(request)
    groups = get_coverage_groups(dut)
    dut.StepRis(lambda _: [g.sample() for g in groups])
    setattr(dut, "fc_cover", {g.name: g for g in groups})
    yield dut
    set_func_coverage(request, groups)
    set_line_coverage(request, get_coverage_data_path(request, new_path=False), ignore=current_path_file("CaseFixed.ignore"))
    set_user_info("UCAgent", "-")
    set_title_info("CaseFixed Test Report")
    for group in groups:
        group.clear()
    dut.Finish()


class CaseFixedEnv:
    def __init__(self, dut):
        self.dut = dut

    def Step(self, cycles: int = 1):
        return self.dut.Step(cycles)


@pytest.fixture(scope="function")
def env(dut):
    return CaseFixedEnv(dut)


def api_CaseFixed_response(env, miss_outstanding, flush_valid, mem_resp_valid):
    d = env.dut
    d.miss_outstanding.value = int(miss_outstanding)
    d.flush_valid.value = int(flush_valid)
    d.mem_resp_valid.value = int(mem_resp_valid)
    env.Step(1)
    return int(d.cpu_resp_valid.value)
