#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

bash "$ROOT/scripts/docker_run.sh" bash -lc '
  set -euo pipefail
  yosys -V
  sby --version
  verilator --version
  picker --version || picker -h >/tmp/picker.help
  iverilog -V >/tmp/iverilog.version
  conda run -n ucagent python -c "import ucagent, toffee, toffee_test, xspcomm; print(\"ucagent/toffee/xspcomm imports ok\")"
  bash scripts/run_cases.sh --case 01 --with-formal --smoke
  bash scripts/run_cases.sh --case 05 --with-formal --smoke
'

echo "[docker_smoke] Docker environment smoke passed"
