#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CASE_TOFFEE="$ROOT/tests/cases/03_pr74_cache_io_idbits/toffee"
ARTIFACT_ROOT="$ROOT/reports/artifacts/03_pr74"
TOFFEE_DIR="$ARTIFACT_ROOT/toffee"
LOG_DIR="$ARTIFACT_ROOT/logs"
LOG="$LOG_DIR/pr74_toffee_directed_pytest.log"
REPORT="$ROOT/reports/03_pr74_toffee_coverage.md"

mkdir -p "$TOFFEE_DIR" "$LOG_DIR"
cd "$ROOT"

if [[ ! -f "$ARTIFACT_ROOT/toffee_dut_fixed/__init__.py" ]]; then
  bash "$ROOT/scripts/internal/34_prepare_pr74_picker_dut.sh"
fi

rm -rf "$TOFFEE_DIR/pytest_report"
rm -f "$TOFFEE_DIR/coverage_summary.json"
mkdir -p "$TOFFEE_DIR/pytest_report"

export NUTSHELL_CACHE_VERIFY_ROOT="$ROOT"
export PYTHONPATH="$CASE_TOFFEE:$ARTIFACT_ROOT/toffee_dut_fixed:${PYTHONPATH:-}"
PYTEST_BIN="$(conda run -n ucagent which pytest | tail -n 1)"

set +e
"$PYTEST_BIN" -q "$CASE_TOFFEE/test_pr74_cache_io_idbits.py" \
  --toffee-report \
  --report-dump-json \
  --report-name=index.html \
  --report-dir="$TOFFEE_DIR/pytest_report" 2>&1 | tee "$LOG"
pytest_rc=${PIPESTATUS[0]}
set -e

if [[ "$pytest_rc" -ne 0 ]]; then
  echo "[35] pytest failed with code $pytest_rc; see $LOG" >&2
  exit "$pytest_rc"
fi

if [[ ! -f "$REPORT" ]]; then
  echo "[35] missing Toffee coverage report: $REPORT" >&2
  exit 1
fi

classification="$(python3 - <<'PY'
import json
from pathlib import Path
p = Path("reports/artifacts/03_pr74/toffee/coverage_summary.json")
print(json.loads(p.read_text()).get("classification", "UNKNOWN"))
PY
)"

echo "[35] classification=$classification"
echo "[35] wrote $REPORT"
echo "[35] pytest log $LOG"

if [[ "$classification" != "FIXED_DYNAMIC_PASS" ]]; then
  echo "[35] expected FIXED_DYNAMIC_PASS but got $classification" >&2
  exit 1
fi
