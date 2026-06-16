#!/usr/bin/env bash
set -euo pipefail

case_dir="$1"
case_name="$2"
dut="${3:-CaseFixed}"

out="$case_dir/unity_test"
tests="$out/tests"
mkdir -p "$tests"
mkdir -p "$case_dir/.ucagent"

cat > "$out/.pytest.ini" <<EOF
[pytest]
addopts = --toffee-report --report-dump-json --report-name=index.html --report-dir=$case_dir/uc_test_report
pythonpath =
    ../
testpaths = ./tests
EOF

cat > "$out/${dut}_basic_info.md" <<EOF
# ${dut} Basic Info

This compact DUT is a combinational cache litmus module. It is intentionally
small so UCAgent can focus on generating executable unit tests against public
input/output ports.
EOF

cat > "$out/${dut}_verification_needs_and_plan.md" <<EOF
# ${dut} Verification Plan

Verify the directed cache bug oracle described in ${dut}/README.md. Generated
tests must use public ports, drive the DUT through Step, and include assertions
that pass on the fixed RTL and fail on the corresponding buggy RTL.
EOF

cat > "$out/${dut}_bug_analysis.md" <<EOF
# ${dut} Bug Analysis

No bug is expected in the fixed DUT. The paired buggy RTL is used only during
replay to prove that generated tests can detect the historical or injected bug.
EOF

cat > "$out/${dut}_line_coverage_analysis.md" <<EOF
# ${dut} Line Coverage

Line coverage is not the primary acceptance metric for this compact litmus.
Functional correctness of the directed oracle is the required criterion.
EOF

cat > "$tests/${dut}.ignore" <<EOF
# No ignored lines for this compact litmus.
EOF

cat > "$tests/${dut}_function_coverage_def.py" <<'PY'
#coding=utf-8

import toffee.funcov as fc


def get_coverage_groups(dut):
    return [fc.CovGroup("FG-API")]
PY

cat > "$tests/${dut}_api.py" <<PY
#coding=utf-8

import os
import pytest
import ucagent
from toffee_test.reporter import set_func_coverage, set_line_coverage, get_file_in_tmp_dir
from toffee_test.reporter import set_user_info, set_title_info
from ${dut}_function_coverage_def import get_coverage_groups
from ${dut} import DUT${dut}


def current_path_file(file_name):
    return os.path.join(os.path.dirname(os.path.abspath(__file__)), file_name)


def get_coverage_data_path(request, new_path: bool):
    tc_name = request.node.name if request is not None else "${dut}"
    return get_file_in_tmp_dir(request, current_path_file("data/"), f"{tc_name}.dat", new_path=new_path)


def get_waveform_path(request, new_path: bool):
    tc_name = request.node.name if request is not None else "${dut}"
    return get_file_in_tmp_dir(request, current_path_file("data/"), f"{tc_name}.fst", new_path=new_path)


def create_dut(request):
    if ucagent.is_imp_test_template():
        return ucagent.get_fake_dut(DUT${dut})
    dut = DUT${dut}()
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
    set_line_coverage(request, get_coverage_data_path(request, new_path=False), ignore=current_path_file("${dut}.ignore"))
    set_user_info("UCAgent", "-")
    set_title_info("${dut} Test Report")
    for group in groups:
        group.clear()
    dut.Finish()


class ${dut}Env:
    def __init__(self, dut):
        self.dut = dut

    def Step(self, cycles: int = 1):
        return self.dut.Step(cycles)


@pytest.fixture(scope="function")
def env(dut):
    return ${dut}Env(dut)
PY

case "$case_name" in
  pr21_prefetch_mmio)
    cat > "$tests/${dut}_function_coverage_def.py" <<'PY'
#coding=utf-8

import toffee.funcov as fc


def get_coverage_groups(dut):
    g = fc.CovGroup("FG-API")
    g.add_watch_point(
        dut,
        {
            "CK-MMIO_NO_FLUSH": lambda x: bool(x.normal_req_pending.value)
            and bool(x.prefetch_valid.value)
            and ((int(x.prefetch_addr.value) >> 28) == 0xF)
            and int(x.stage_flush.value) == 0,
            "CK-MMIO_PREFETCH_SUPPRESSED": lambda x: bool(x.prefetch_valid.value)
            and ((int(x.prefetch_addr.value) >> 28) == 0xF)
            and int(x.prefetch_out_valid.value) == 0,
            "CK-NON_MMIO_PREFETCH_ALLOWED": lambda x: bool(x.prefetch_valid.value)
            and ((int(x.prefetch_addr.value) >> 28) != 0xF)
            and int(x.prefetch_out_valid.value) == 1,
        },
        name="FC-MMIO_PREFETCH_SUPPRESSION",
    )
    return [g]
PY
    cat > "$out/${dut}_functions_and_checks.md" <<EOF
# ${dut} Functions And Checks

<FG-API>

## MMIO prefetch suppression

<FC-MMIO_PREFETCH_SUPPRESSION>

Validate that an MMIO prefetch is suppressed and does not flush a pending
normal cache request.

<CK-MMIO_NO_FLUSH>

When normal_req_pending=1, prefetch_valid=1, prefetch_addr[31:28]=0xF and
explicit_flush=0, stage_flush must be 0.

<CK-MMIO_PREFETCH_SUPPRESSED>

For the same MMIO prefetch scenario, prefetch_out_valid must be 0.

<CK-NON_MMIO_PREFETCH_ALLOWED>

For a non-MMIO prefetch, prefetch_out_valid may be 1 while stage_flush follows
explicit_flush.
EOF
    cat >> "$tests/${dut}_api.py" <<PY


def api_${dut}_eval(env, normal_req_pending, prefetch_valid, prefetch_addr, explicit_flush):
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
PY
    ;;
  pr74_cache_io_idbits)
    cat > "$tests/${dut}_function_coverage_def.py" <<'PY'
#coding=utf-8

import toffee.funcov as fc


def get_coverage_groups(dut):
    g = fc.CovGroup("FG-API")
    g.add_watch_point(
        dut,
        {
            "CK-NONZERO_ID_PRESERVED": lambda x: int(x.req_id.value) != 0
            and int(x.resp_id.value) == int(x.req_id.value),
            "CK-MULTIPLE_ID_VALUES": lambda x: int(x.req_id.value) != 0
            and int(x.resp_id.value) == int(x.req_id.value),
        },
        name="FC-ID_ROUNDTRIP",
    )
    return [g]
PY
    cat > "$out/${dut}_functions_and_checks.md" <<EOF
# ${dut} Functions And Checks

<FG-API>

## CacheIO ID preservation

<FC-ID_ROUNDTRIP>

Validate that every request ID is returned unchanged on the response ID port.

<CK-NONZERO_ID_PRESERVED>

For any nonzero req_id, resp_id must equal req_id.

<CK-MULTIPLE_ID_VALUES>

At least two distinct nonzero IDs should be checked to avoid constant-only
testing.
EOF
    cat >> "$tests/${dut}_api.py" <<PY


def api_${dut}_id_roundtrip(env, req_id):
    d = env.dut
    d.req_id.value = int(req_id) & 0xF
    env.Step(1)
    return int(d.resp_id.value) & 0xF
PY
    ;;
  flush_outstanding_miss)
    cat > "$tests/${dut}_function_coverage_def.py" <<'PY'
#coding=utf-8

import toffee.funcov as fc


def get_coverage_groups(dut):
    g = fc.CovGroup("FG-API")
    g.add_watch_point(
        dut,
        {
            "CK-FLUSH_BEFORE_REFILL_NO_RESPONSE": lambda x: bool(x.miss_outstanding.value)
            and bool(x.flush_valid.value)
            and not bool(x.mem_resp_valid.value)
            and int(x.cpu_resp_valid.value) == 0,
            "CK-REFILL_RESPONSE_ALLOWED": lambda x: bool(x.miss_outstanding.value)
            and bool(x.mem_resp_valid.value)
            and int(x.cpu_resp_valid.value) == 1,
        },
        name="FC-FLUSH_REFILL_ORDERING",
    )
    return [g]
PY
    cat > "$out/${dut}_functions_and_checks.md" <<EOF
# ${dut} Functions And Checks

<FG-API>

## Flush during outstanding miss

<FC-FLUSH_REFILL_ORDERING>

Validate that flush before refill does not fabricate an early CPU response.

<CK-FLUSH_BEFORE_REFILL_NO_RESPONSE>

When miss_outstanding=1, flush_valid=1 and mem_resp_valid=0, cpu_resp_valid
must be 0.

<CK-REFILL_RESPONSE_ALLOWED>

When miss_outstanding=1 and mem_resp_valid=1, cpu_resp_valid may be 1.
EOF
    cat >> "$tests/${dut}_api.py" <<PY


def api_${dut}_response(env, miss_outstanding, flush_valid, mem_resp_valid):
    d = env.dut
    d.miss_outstanding.value = int(miss_outstanding)
    d.flush_valid.value = int(flush_valid)
    d.mem_resp_valid.value = int(mem_resp_valid)
    env.Step(1)
    return int(d.cpu_resp_valid.value)
PY
    ;;
  *)
    echo "unknown case: $case_name" >&2
    exit 2
    ;;
esac

case "$case_name" in
  pr21_prefetch_mmio)
    template="test_${dut}_pr21_prefetch_mmio.py"
    cat > "$tests/$template" <<PY
#coding=utf-8

from ${dut}_api import *
from ${dut} import DUT${dut}
from ${dut}_function_coverage_def import get_coverage_groups
import pytest


def _make_env():
    dut = DUT${dut}()
    groups = get_coverage_groups(dut)
    dut.StepRis(lambda _: [g.sample() for g in groups])
    env = ${dut}Env(dut)
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
PY
    cat > "$out/.TEST_TEMPLATE_IMP_REPORT.json" <<EOF
{
  "run_test_success": true,
  "tests": {
    "total": 2,
    "fails": 2,
    "test_cases": {
      "unity_test/tests/$template::test_mmio_prefetch_suppressed": "FAILED",
      "unity_test/tests/$template::test_mmio_prefetch_does_not_flush_pending_request": "FAILED"
    }
  },
  "failed_test_case_with_check_point_list": {
    "unity_test/tests/$template::test_mmio_prefetch_suppressed": [
      "FG-API/FC-MMIO_PREFETCH_SUPPRESSION/CK-MMIO_PREFETCH_SUPPRESSED"
    ],
    "unity_test/tests/$template::test_mmio_prefetch_does_not_flush_pending_request": [
      "FG-API/FC-MMIO_PREFETCH_SUPPRESSION/CK-MMIO_NO_FLUSH"
    ]
  }
}
EOF
    ;;
  pr74_cache_io_idbits)
    template="test_${dut}_pr74_cache_io_idbits.py"
    cat > "$tests/$template" <<PY
#coding=utf-8

from ${dut}_api import *
from ${dut} import DUT${dut}
from ${dut}_function_coverage_def import get_coverage_groups
import pytest


def _make_env():
    dut = DUT${dut}()
    groups = get_coverage_groups(dut)
    dut.StepRis(lambda _: [g.sample() for g in groups])
    env = ${dut}Env(dut)
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
PY
    cat > "$out/.TEST_TEMPLATE_IMP_REPORT.json" <<EOF
{
  "run_test_success": true,
  "tests": {
    "total": 2,
    "fails": 2,
    "test_cases": {
      "unity_test/tests/$template::test_nonzero_request_id_preserved": "FAILED",
      "unity_test/tests/$template::test_multiple_request_ids_preserved": "FAILED"
    }
  },
  "failed_test_case_with_check_point_list": {
    "unity_test/tests/$template::test_nonzero_request_id_preserved": [
      "FG-API/FC-ID_ROUNDTRIP/CK-NONZERO_ID_PRESERVED"
    ],
    "unity_test/tests/$template::test_multiple_request_ids_preserved": [
      "FG-API/FC-ID_ROUNDTRIP/CK-MULTIPLE_ID_VALUES"
    ]
  }
}
EOF
    ;;
  flush_outstanding_miss)
    template="test_${dut}_flush_outstanding_miss.py"
    cat > "$tests/$template" <<PY
#coding=utf-8

from ${dut}_api import *
from ${dut} import DUT${dut}
from ${dut}_function_coverage_def import get_coverage_groups
import pytest


def _make_env():
    dut = DUT${dut}()
    groups = get_coverage_groups(dut)
    dut.StepRis(lambda _: [g.sample() for g in groups])
    env = ${dut}Env(dut)
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
PY
    cat > "$out/.TEST_TEMPLATE_IMP_REPORT.json" <<EOF
{
  "run_test_success": true,
  "tests": {
    "total": 2,
    "fails": 2,
    "test_cases": {
      "unity_test/tests/$template::test_flush_before_refill_no_early_response": "FAILED",
      "unity_test/tests/$template::test_refill_response_after_memory": "FAILED"
    }
  },
  "failed_test_case_with_check_point_list": {
    "unity_test/tests/$template::test_flush_before_refill_no_early_response": [
      "FG-API/FC-FLUSH_REFILL_ORDERING/CK-FLUSH_BEFORE_REFILL_NO_RESPONSE"
    ],
    "unity_test/tests/$template::test_refill_response_after_memory": [
      "FG-API/FC-FLUSH_REFILL_ORDERING/CK-REFILL_RESPONSE_ALLOWED"
    ]
  }
}
EOF
    ;;
esac

now="$(date +%s)"
{
  echo "{"
  echo "  \"version\": \"seeded-by-nutshell-cache-verify\","
  echo "  \"seed\": 1,"
  echo "  \"stage_index\": 22,"
  echo "  \"all_completed\": false,"
  echo "  \"is_agent_exit\": false,"
  echo "  \"is_wait_human_check\": false,"
  echo "  \"time_begin\": $now,"
  echo "  \"time_end\": null,"
  echo "  \"stages_info\": {"
  for i in $(seq 0 27); do
    completed=false
    skipped=false
    reached=false
    if [ "$i" -le 21 ]; then
      completed=true
      reached=true
    fi
    if [ "$i" -eq 24 ] || [ "$i" -eq 25 ] || [ "$i" -eq 26 ]; then
      skipped=true
    fi
    comma=","
    if [ "$i" -eq 27 ]; then
      comma=""
    fi
    echo "    \"$i\": {\"is_completed\": $completed, \"is_skipped\": $skipped, \"reached\": $reached, \"fail_count\": 0, \"time_cost\": 0.0, \"task\": {\"reference_files\": {}}}$comma"
  done
  echo "  }"
  echo "}"
} > "$case_dir/.ucagent/ucagent_info.json"
