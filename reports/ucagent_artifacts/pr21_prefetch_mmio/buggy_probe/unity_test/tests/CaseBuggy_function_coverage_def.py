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
