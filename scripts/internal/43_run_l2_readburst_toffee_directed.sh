#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CASE_TOFFEE="$ROOT/tests/cases/04_l2_readburst_hit_ready_valid_deadlock/toffee"
DUT_DIR="$ROOT/reports/artifacts/04_l2_readburst/toffee_dut"
REPORT_DIR="$ROOT/reports/artifacts/04_l2_readburst"
TOFFEE_DIR="$REPORT_DIR/toffee"
LOG_DIR="$REPORT_DIR/logs"
LOG="$LOG_DIR/toffee_directed_pytest.log"
MAIN_REPORT="$ROOT/reports/04_l2_readburst.md"
TOFFEE_REPORT="$ROOT/reports/04_l2_readburst_toffee_coverage.md"

mkdir -p "$TOFFEE_DIR" "$LOG_DIR"
cd "$ROOT"

if [[ ! -f "$DUT_DIR/__init__.py" ]]; then
  bash "$ROOT/scripts/internal/42_prepare_l2_readburst_picker_dut.sh"
fi

rm -rf "$TOFFEE_DIR/pytest_report"
mkdir -p "$TOFFEE_DIR/pytest_report"

export L2_READBURST_TOFFEE_DUT_DIR="$DUT_DIR"
export NUTSHELL_CACHE_VERIFY_ROOT="$ROOT"
export PYTHONPATH="$CASE_TOFFEE:$DUT_DIR:${PYTHONPATH:-}"
PYTEST_BIN="$(conda run -n ucagent which pytest | tail -n 1)"

set +e
"$PYTEST_BIN" -q "$CASE_TOFFEE/test_l2_readburst_ready_valid.py" \
  --toffee-report \
  --report-dump-json \
  --report-name=index.html \
  --report-dir="$TOFFEE_DIR/pytest_report" 2>&1 | tee "$LOG"
pytest_rc=${PIPESTATUS[0]}
set -e

if [[ "$pytest_rc" -ne 0 ]]; then
  echo "[43] pytest failed with code $pytest_rc" >&2
  exit "$pytest_rc"
fi

if [[ ! -f "$TOFFEE_REPORT" ]]; then
  echo "[43] missing Toffee coverage report: $TOFFEE_REPORT" >&2
  exit 1
fi

classification="$(python3 - <<'PY'
import json
from pathlib import Path
p = Path("reports/artifacts/04_l2_readburst/toffee/coverage_summary.json")
print(json.loads(p.read_text())["classification"])
PY
)"

if [[ -f "$MAIN_REPORT" ]] && ! grep -q "## Toffee 动态覆盖闭环" "$MAIN_REPORT"; then
  cat >> "$MAIN_REPORT" <<'EOF'

## Toffee 动态覆盖闭环

- 报告：`reports/04_l2_readburst_toffee_coverage.md`
- Toffee/pytest HTML：`reports/artifacts/04_l2_readburst/toffee/pytest_report/index.html`
- Toffee waveform：`reports/artifacts/04_l2_readburst/toffee/l2_readburst_ready_deadlock.fst`
- Coverage JSON：`reports/artifacts/04_l2_readburst/toffee/coverage_summary.json`

该闭环使用 Picker 导出的真实 `FreshCacheFormalDut` Python DUT，并用 Toffee fixture 驱动 public IO。覆盖率只统计 04 场景 coverpoints，不代表完整 Cache functional coverage。
EOF
fi

echo "[43] classification=$classification"
echo "[43] wrote $TOFFEE_REPORT"
echo "[43] pytest log $LOG"

if [[ "$classification" != "DYNAMIC_REPRODUCED" ]]; then
  echo "[43] expected DYNAMIC_REPRODUCED but got $classification" >&2
  exit 1
fi
