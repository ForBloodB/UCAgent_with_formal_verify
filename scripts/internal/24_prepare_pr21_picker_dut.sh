#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CASE_DIR="$ROOT/tests/cases/02_pr21_mmio_prefetch"
RTL_PRE="$CASE_DIR/formal/generated/pre/Pr21CacheFormalDut.v"
RTL_FIXED="$CASE_DIR/formal/generated/fixed/Pr21CacheFormalDut.v"
ARTIFACT_ROOT="$ROOT/reports/artifacts/02_pr21"
DUT_PRE="$ARTIFACT_ROOT/toffee_dut_pre"
DUT_FIXED="$ARTIFACT_ROOT/toffee_dut_fixed"
LOG_DIR="$ARTIFACT_ROOT/logs"

mkdir -p "$LOG_DIR"
cd "$ROOT"

if [[ ! -f "$RTL_PRE" || ! -f "$RTL_FIXED" ]]; then
  echo "[24] missing generated PR21 wrappers; preparing real NutShell Cache revisions first"
  bash "$ROOT/scripts/internal/20_prepare_pr21_real_cache.sh" all
fi

rm -rf "$DUT_PRE" "$DUT_FIXED"

echo "[24] exporting PR21 pre-PR DUT with picker"
picker export "$RTL_PRE" \
  --sname Pr21CacheFormalDut \
  --tdir "$DUT_PRE" \
  --lang python \
  --sim verilator \
  --autobuild=true \
  -e \
  -c \
  -w "$DUT_PRE/Pr21CacheFormalDut.fst" \
  -V "-DSYNTHESIS --trace-fst" 2>&1 | tee "$LOG_DIR/pr21_pre_picker_export.log"

echo "[24] exporting PR21 fixed DUT with picker"
picker export "$RTL_FIXED" \
  --sname Pr21CacheFormalDut \
  --tdir "$DUT_FIXED" \
  --lang python \
  --sim verilator \
  --autobuild=true \
  -e \
  -c \
  -w "$DUT_FIXED/Pr21CacheFormalDut.fst" \
  -V "-DSYNTHESIS --trace-fst" 2>&1 | tee "$LOG_DIR/pr21_fixed_picker_export.log"

for dir in "$DUT_PRE" "$DUT_FIXED"; do
  if [[ ! -f "$dir/__init__.py" || ! -f "$dir/_UT_Pr21CacheFormalDut.so" ]]; then
    echo "[24] picker export did not produce expected Python DUT package in $dir" >&2
    exit 1
  fi
done

conda run -n ucagent python -c \
  "import sys; sys.path.insert(0, '$DUT_PRE'); from __init__ import DUTPr21CacheFormalDut; dut=DUTPr21CacheFormalDut(); dut.InitClock('clock'); print('PR21 pre DUT import OK'); dut.Finish()"
conda run -n ucagent python -c \
  "import sys; sys.path.insert(0, '$DUT_FIXED'); from __init__ import DUTPr21CacheFormalDut; dut=DUTPr21CacheFormalDut(); dut.InitClock('clock'); print('PR21 fixed DUT import OK'); dut.Finish()"

echo "[24] wrote $DUT_PRE"
echo "[24] wrote $DUT_FIXED"
