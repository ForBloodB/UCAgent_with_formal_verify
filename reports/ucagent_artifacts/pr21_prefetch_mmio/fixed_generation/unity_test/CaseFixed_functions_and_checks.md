# CaseFixed Functions And Checks

<FG-API>

## MMIO prefetch suppression

<FC-MMIO_PREFETCH_SUPPRESSION>

Validate that an MMIO prefetch is suppressed and does not flush a pending
normal cache request.

<CK-MMIO_NO_FLUSH>

When normal_req_pending=1, prefetch_valid=1, prefetch_addr[31:28]=0xF and
explicit_flush=0, stage_flush must be 0.

<CK-MMIO_PREFETCH_SUPPRESSED>

For the same MMIO prefetch scenario, prefetch_out_valid must be 0.

<CK-NON_MMIO_PREFETCH_ALLOWED>

For a non-MMIO prefetch, prefetch_out_valid may be 1 while stage_flush follows
explicit_flush.
