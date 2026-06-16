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
