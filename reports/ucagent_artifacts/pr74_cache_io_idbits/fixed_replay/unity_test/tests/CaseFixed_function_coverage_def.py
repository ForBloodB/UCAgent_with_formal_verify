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
