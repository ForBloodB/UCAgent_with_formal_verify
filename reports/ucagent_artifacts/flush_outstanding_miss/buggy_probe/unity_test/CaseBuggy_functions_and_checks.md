# CaseBuggy Functions And Checks

<FG-API>

## Flush during outstanding miss

<FC-FLUSH_REFILL_ORDERING>

Validate that flush before refill does not fabricate an early CPU response.

<CK-FLUSH_BEFORE_REFILL_NO_RESPONSE>

When miss_outstanding=1, flush_valid=1 and mem_resp_valid=0, cpu_resp_valid
must be 0.

<CK-REFILL_RESPONSE_ALLOWED>

When miss_outstanding=1 and mem_resp_valid=1, cpu_resp_valid may be 1.
