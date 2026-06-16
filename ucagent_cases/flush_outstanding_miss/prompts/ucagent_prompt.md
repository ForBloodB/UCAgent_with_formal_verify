# UCAgent Task: Flush During Outstanding Miss

Please run the normal UCAgent unit-test workflow for the DUT selected on the
command line. Generate executable pytest tests under `unity_test/tests`.

The DUT is a compact timing-window litmus model. It has these ports:

- `miss_outstanding`
- `flush_valid`
- `mem_resp_valid`
- `cpu_resp_valid`

Required directed scenario:

- A miss is already outstanding: `miss_outstanding = 1`
- A flush arrives before refill: `flush_valid = 1` and `mem_resp_valid = 0`
- Later, the refill arrives: `flush_valid = 0` and `mem_resp_valid = 1`

Correct oracle:

- During the flush-before-refill cycle, `cpu_resp_valid` must be `0`
- During the refill cycle, `cpu_resp_valid` may be `1`

Please use only public DUT input/output ports, drive the DUT with the Step
interface, and include clear assert messages. The generated tests must pass on
the fixed behavior and fail on the buggy behavior that asserts `cpu_resp_valid`
early when `flush_valid` is high.

Keep the seeded direct-DUT pytest structure: use `_make_env()` and the `api_*`
helpers already provided in `unity_test/tests`; do not change test functions to
take an `env` fixture argument.
