# CaseFixed Functions And Checks

<FG-API>

## CacheIO ID preservation

<FC-ID_ROUNDTRIP>

Validate that every request ID is returned unchanged on the response ID port.

<CK-NONZERO_ID_PRESERVED>

For any nonzero req_id, resp_id must equal req_id.

<CK-MULTIPLE_ID_VALUES>

At least two distinct nonzero IDs should be checked to avoid constant-only
testing.
