from dataclasses import dataclass


@dataclass(frozen=True)
class CycleEvent:
    cycle: int
    miss_outstanding: bool
    flush_valid: bool
    mem_resp_valid: bool
    cpu_resp_valid: bool


class FlushOutstandingMissCase:
    def __init__(self, variant: str):
        if variant not in {"buggy", "fixed"}:
            raise ValueError(f"unknown variant: {variant}")
        self.variant = variant

    def run(self, request_cycle: int = 2, flush_cycle: int = 3, mem_resp_cycle: int = 5):
        events = []
        outstanding = False
        for cycle in range(mem_resp_cycle + 1):
            if cycle == request_cycle:
                outstanding = True

            flush_valid = cycle == flush_cycle
            mem_resp_valid = cycle == mem_resp_cycle

            if self.variant == "buggy":
                cpu_resp_valid = outstanding and flush_valid
            else:
                cpu_resp_valid = outstanding and mem_resp_valid

            events.append(
                CycleEvent(
                    cycle=cycle,
                    miss_outstanding=outstanding,
                    flush_valid=flush_valid,
                    mem_resp_valid=mem_resp_valid,
                    cpu_resp_valid=bool(cpu_resp_valid),
                )
            )

            if outstanding and mem_resp_valid:
                outstanding = False

        return events
