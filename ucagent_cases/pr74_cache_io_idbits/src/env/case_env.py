from dataclasses import dataclass


@dataclass(frozen=True)
class CacheIoIdResult:
    req_id: int
    resp_id: int


class CacheIoIdBitsCase:
    def __init__(self, variant: str, id_bits: int = 4):
        if variant not in {"buggy", "fixed"}:
            raise ValueError(f"unknown variant: {variant}")
        self.variant = variant
        self.id_mask = (1 << id_bits) - 1

    def request_response(self, req_id: int) -> CacheIoIdResult:
        req_id &= self.id_mask
        if self.variant == "buggy":
            resp_id = 0
        else:
            resp_id = req_id
        return CacheIoIdResult(req_id=req_id, resp_id=resp_id)
