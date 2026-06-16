#coding=utf-8

import os
import pytest
import ucagent
from toffee_test.reporter import set_func_coverage, set_line_coverage, get_file_in_tmp_dir
from toffee_test.reporter import set_user_info, set_title_info
from CaseBuggy_function_coverage_def import get_coverage_groups
from CaseBuggy import DUTCaseBuggy


def current_path_file(file_name):
    return os.path.join(os.path.dirname(os.path.abspath(__file__)), file_name)


def get_coverage_data_path(request, new_path: bool):
    tc_name = request.node.name if request is not None else "CaseBuggy"
    return get_file_in_tmp_dir(request, current_path_file("data/"), f"{tc_name}.dat", new_path=new_path)


def get_waveform_path(request, new_path: bool):
    tc_name = request.node.name if request is not None else "CaseBuggy"
    return get_file_in_tmp_dir(request, current_path_file("data/"), f"{tc_name}.fst", new_path=new_path)


def create_dut(request):
    if ucagent.is_imp_test_template():
        return ucagent.get_fake_dut(DUTCaseBuggy)
    dut = DUTCaseBuggy()
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
    set_line_coverage(request, get_coverage_data_path(request, new_path=False), ignore=current_path_file("CaseBuggy.ignore"))
    set_user_info("UCAgent", "-")
    set_title_info("CaseBuggy Test Report")
    for group in groups:
        group.clear()
    dut.Finish()


class CaseBuggyEnv:
    def __init__(self, dut):
        self.dut = dut

    def Step(self, cycles: int = 1):
        return self.dut.Step(cycles)


@pytest.fixture(scope="function")
def env(dut):
    return CaseBuggyEnv(dut)


def api_CaseBuggy_eval(env, normal_req_pending, prefetch_valid, prefetch_addr, explicit_flush):
    d = env.dut
    d.normal_req_pending.value = int(normal_req_pending)
    d.prefetch_valid.value = int(prefetch_valid)
    d.prefetch_addr.value = int(prefetch_addr) & 0xFFFFFFFF
    d.explicit_flush.value = int(explicit_flush)
    env.Step(1)
    stage_flush = int(d.stage_flush.value)
    prefetch_out_valid = int(d.prefetch_out_valid.value)
    return {
        "stage_flush": stage_flush,
        "prefetch_out_valid": prefetch_out_valid,
        "normal_request_survived": bool(normal_req_pending) and stage_flush == 0,
    }
