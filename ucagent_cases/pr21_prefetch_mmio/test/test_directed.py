import os

from env.case_env import PrefetchMmioCase
from ref.reference import expected_mmio_prefetch_behavior


def test_mmio_prefetch_does_not_flush_normal_request():
    dut = PrefetchMmioCase(os.environ.get("CASE_VARIANT", "fixed"))
    result = dut.step(
        normal_req_pending=True,
        prefetch_valid=True,
        prefetch_addr=0xF000_1000,
        explicit_flush=False,
    )
    expected = expected_mmio_prefetch_behavior()

    assert result.stage_flush == expected["stage_flush"]
    assert result.prefetch_out_valid == expected["prefetch_out_valid"]
    assert result.normal_request_survived == expected["normal_request_survived"]
