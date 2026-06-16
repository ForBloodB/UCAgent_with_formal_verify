import os

from env.case_env import CacheIoIdBitsCase
from ref.reference import expected_response_id


def test_nonzero_ooo_request_id_is_preserved():
    dut = CacheIoIdBitsCase(os.environ.get("CASE_VARIANT", "fixed"), id_bits=4)
    result = dut.request_response(req_id=1)

    assert result.req_id != 0
    assert result.resp_id == expected_response_id(result.req_id)
