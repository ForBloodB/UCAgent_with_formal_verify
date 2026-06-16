def expected_mmio_prefetch_behavior():
    return {
        "stage_flush": False,
        "prefetch_out_valid": False,
        "normal_request_survived": True,
    }
