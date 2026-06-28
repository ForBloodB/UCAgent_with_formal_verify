#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
RTL="$ROOT/tests/cases/04_l2_readburst_hit_ready_valid_deadlock/formal/generated/latest/FreshCacheFormalDut.sv"
DUT_DIR="$ROOT/reports/artifacts/04_l2_readburst/toffee_dut"
LOG_DIR="$ROOT/reports/artifacts/04_l2_readburst/logs"
LOG="$LOG_DIR/toffee_picker_export.log"

mkdir -p "$LOG_DIR"
cd "$ROOT"

if [[ ! -f "$RTL" ]]; then
  echo "[42] missing generated latest wrapper; preparing it first"
  python3 "$ROOT/tests/cases/04_l2_readburst_hit_ready_valid_deadlock/scripts/prepare_latest_l2_readburst.py" \
    --repo-root "$ROOT" \
    --timeout "${L2_READBURST_PREPARE_TIMEOUT:-1200}"
fi

rm -rf "$DUT_DIR"

echo "[42] exporting FreshCacheFormalDut with picker"
picker export "$RTL" \
  --sname FreshCacheFormalDut \
  --tdir "$DUT_DIR" \
  --lang python \
  --sim verilator \
  --autobuild=true \
  -e \
  -c \
  -w "$DUT_DIR/FreshCacheFormalDut.fst" \
  -V "-DSYNTHESIS --trace-fst" 2>&1 | tee "$LOG"

if [[ ! -f "$DUT_DIR/__init__.py" ]] || [[ ! -f "$DUT_DIR/_UT_FreshCacheFormalDut.so" ]]; then
  echo "[42] picker export did not produce the expected Python DUT package" >&2
  exit 1
fi

conda run -n ucagent python -c \
  "import sys; sys.path.insert(0, '$DUT_DIR'); from __init__ import DUTFreshCacheFormalDut; dut=DUTFreshCacheFormalDut(); dut.InitClock('clock'); print('DUTFreshCacheFormalDut import OK'); dut.Finish()"

echo "[42] wrote $DUT_DIR"
echo "[42] log $LOG"
