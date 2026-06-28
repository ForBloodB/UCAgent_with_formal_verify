#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CASE_TOFFEE="$ROOT/tests/cases/02_pr21_mmio_prefetch/toffee"
ARTIFACT_ROOT="$ROOT/reports/artifacts/02_pr21"
TOFFEE_DIR="$ARTIFACT_ROOT/toffee"
LOG_DIR="$ARTIFACT_ROOT/logs"
LOG="$LOG_DIR/pr21_toffee_directed_pytest.log"
REPORT="$ROOT/reports/02_pr21_toffee_coverage.md"

mkdir -p "$TOFFEE_DIR" "$LOG_DIR"
cd "$ROOT"

if [[ ! -f "$ARTIFACT_ROOT/toffee_dut_pre/__init__.py" || ! -f "$ARTIFACT_ROOT/toffee_dut_fixed/__init__.py" ]]; then
  bash "$ROOT/scripts/internal/24_prepare_pr21_picker_dut.sh"
fi

rm -rf "$TOFFEE_DIR/pytest_report"
rm -f "$TOFFEE_DIR/coverage_summary.json"
mkdir -p "$TOFFEE_DIR/pytest_report"

export NUTSHELL_CACHE_VERIFY_ROOT="$ROOT"
export PYTHONPATH="$CASE_TOFFEE:$ARTIFACT_ROOT/toffee_dut_pre:$ARTIFACT_ROOT/toffee_dut_fixed:${PYTHONPATH:-}"
PYTEST_BIN="$(conda run -n ucagent which pytest | tail -n 1)"

set +e
"$PYTEST_BIN" -q "$CASE_TOFFEE/test_pr21_mmio_prefetch.py" \
  --toffee-report \
  --report-dump-json \
  --report-name=index.html \
  --report-dir="$TOFFEE_DIR/pytest_report" 2>&1 | tee "$LOG"
pytest_rc=${PIPESTATUS[0]}
set -e

if [[ "$pytest_rc" -ne 0 ]]; then
  echo "[25] pytest failed with code $pytest_rc; see $LOG" >&2
  exit "$pytest_rc"
fi

if [[ ! -f "$REPORT" ]]; then
  echo "[25] missing Toffee coverage report: $REPORT" >&2
  exit 1
fi

classification="$(python3 - <<'PY'
import json
from pathlib import Path
p = Path("reports/artifacts/02_pr21/toffee/coverage_summary.json")
print(json.loads(p.read_text()).get("classification", "UNKNOWN"))
PY
)"

echo "[25] classification=$classification"
echo "[25] wrote $REPORT"
echo "[25] pytest log $LOG"

if [[ "$classification" != "DYNAMIC_REPRODUCED_AND_FIXED_PASS" && "$classification" != "DYNAMIC_PRE_REPRODUCED_FIXED_EDGE_SAMPLING_LIMIT" ]]; then
  echo "[25] expected DYNAMIC_REPRODUCED_AND_FIXED_PASS or DYNAMIC_PRE_REPRODUCED_FIXED_EDGE_SAMPLING_LIMIT but got $classification" >&2
  exit 1
fi
