# UCAgent Task: PR #74 CacheIO idBits

Please run the normal UCAgent unit-test workflow for the DUT selected on the
command line. Generate executable pytest tests under `unity_test/tests`.

The DUT is a compact litmus model for NutShell PR #74. It has these ports:

- `req_id[3:0]`
- `resp_id[3:0]`

Required directed scenario:

- Use at least one nonzero request ID, for example `req_id = 0xA`
- Also cover another nonzero ID to avoid only checking a single constant

Correct oracle:

- `resp_id` must equal `req_id` for every nonzero ID

Please use only public DUT input/output ports, drive the DUT with the Step
interface, and include clear assert messages. The generated tests must pass on
the fixed behavior and fail on the buggy behavior that drops the response ID to
zero.

Keep the seeded direct-DUT pytest structure: use `_make_env()` and the `api_*`
helpers already provided in `unity_test/tests`; do not change test functions to
take an `env` fixture argument.
