# UCAgent Task: PR #21 MMIO Prefetch

Please run the normal UCAgent unit-test workflow for the DUT selected on the
command line. Generate executable pytest tests under `unity_test/tests`.

The DUT is a compact litmus model for NutShell PR #21. It has these ports:

- `normal_req_pending`
- `prefetch_valid`
- `prefetch_addr[31:0]`
- `explicit_flush`
- `stage_flush`
- `prefetch_out_valid`

Required directed scenario:

- `normal_req_pending = 1`
- `prefetch_valid = 1`
- `prefetch_addr[31:28] = 0xF`, meaning the prefetch targets MMIO
- `explicit_flush = 0`

Correct oracle:

- `stage_flush` must be `0`
- `prefetch_out_valid` must be `0`
- the pending normal request is considered preserved because no flush occurs

Please use only public DUT input/output ports, drive the DUT with the Step
interface, and include clear assert messages. The generated tests must pass on
the fixed behavior and fail on the buggy behavior that flushes the pipeline for
an MMIO prefetch.

Keep the seeded direct-DUT pytest structure: use `_make_env()` and the `api_*`
helpers already provided in `unity_test/tests`; do not change test functions to
take an `env` fixture argument.
