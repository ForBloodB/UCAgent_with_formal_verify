def has_early_cpu_response(events, mem_resp_cycle: int) -> bool:
    return any(event.cpu_resp_valid and event.cycle < mem_resp_cycle for event in events)


def has_refill_cpu_response(events, mem_resp_cycle: int) -> bool:
    return any(event.cpu_resp_valid and event.cycle == mem_resp_cycle for event in events)
