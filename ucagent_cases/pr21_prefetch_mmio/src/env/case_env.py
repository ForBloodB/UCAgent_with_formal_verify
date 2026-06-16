from dataclasses import dataclass


MMIO_PREFIX = 0xF


@dataclass(frozen=True)
class PrefetchMmioResult:
    stage_flush: bool
    prefetch_out_valid: bool
    normal_request_survived: bool


class PrefetchMmioCase:
    def __init__(self, variant: str):
        if variant not in {"buggy", "fixed"}:
            raise ValueError(f"unknown variant: {variant}")
        self.variant = variant

    def step(
        self,
        normal_req_pending: bool,
        prefetch_valid: bool,
        prefetch_addr: int,
        explicit_flush: bool,
    ) -> PrefetchMmioResult:
        prefetch_is_mmio = ((prefetch_addr >> 28) & 0xF) == MMIO_PREFIX

        if self.variant == "buggy":
            stage_flush = explicit_flush or (prefetch_valid and prefetch_is_mmio)
            prefetch_out_valid = prefetch_valid
        else:
            stage_flush = explicit_flush
            prefetch_out_valid = prefetch_valid and not prefetch_is_mmio

        normal_request_survived = bool(normal_req_pending and not stage_flush)
        return PrefetchMmioResult(
            stage_flush=bool(stage_flush),
            prefetch_out_valid=bool(prefetch_out_valid),
            normal_request_survived=normal_request_survived,
        )
