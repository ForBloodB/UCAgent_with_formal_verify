import os

from env.case_env import FlushOutstandingMissCase
from ref.reference import has_early_cpu_response, has_refill_cpu_response


def test_flush_during_outstanding_miss_does_not_return_early_response():
    mem_resp_cycle = 5
    dut = FlushOutstandingMissCase(os.environ.get("CASE_VARIANT", "fixed"))
    events = dut.run(request_cycle=2, flush_cycle=3, mem_resp_cycle=mem_resp_cycle)

    assert not has_early_cpu_response(events, mem_resp_cycle)
    assert has_refill_cpu_response(events, mem_resp_cycle)
