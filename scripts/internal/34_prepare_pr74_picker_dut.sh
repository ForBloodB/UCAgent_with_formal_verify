#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CASE_DIR="$ROOT/tests/cases/03_pr74_cache_io_idbits"
RTL_PRE="$CASE_DIR/formal/generated/pre/Pr74CacheIOFormalDut.v"
RTL_FIXED="$CASE_DIR/formal/generated/fixed/Pr74CacheIOFormalDut.v"
ARTIFACT_ROOT="$ROOT/reports/artifacts/03_pr74"
DUT_FIXED="$ARTIFACT_ROOT/toffee_dut_fixed"
LOG_DIR="$ARTIFACT_ROOT/logs"
PRE_LOG="$LOG_DIR/pr74_pre_prepare_expected_fail.log"

mkdir -p "$LOG_DIR"
cd "$ROOT"

if [[ ! -f "$RTL_FIXED" ]]; then
  echo "[34] missing generated PR74 fixed wrapper; preparing real NutShell Cache revisions first"
  bash "$ROOT/scripts/internal/30_prepare_pr74_real_cache.sh" fixed
fi

if [[ ! -f "$RTL_PRE" ]]; then
  echo "[34] attempting PR74 pre-PR generation; elaboration failure is expected for the historical bug"
  set +e
  bash "$ROOT/scripts/internal/30_prepare_pr74_real_cache.sh" pre >"$PRE_LOG" 2>&1
  pre_rc=$?
  set -e
  if [[ "$pre_rc" -eq 0 && -f "$RTL_PRE" ]]; then
    echo "[34] PR74 pre-PR unexpectedly generated RTL; continuing but keeping the log"
  else
    echo "[34] PR74 pre-PR generation failed as expected; log $PRE_LOG"
  fi
fi

rm -rf "$DUT_FIXED"

echo "[34] exporting PR74 fixed DUT with picker"
picker export "$RTL_FIXED" \
  --sname Pr74CacheIOFormalDut \
  --tdir "$DUT_FIXED" \
  --lang python \
  --sim verilator \
  --autobuild=true \
  -e \
  -c \
  -w "$DUT_FIXED/Pr74CacheIOFormalDut.fst" \
  -V "-DSYNTHESIS --trace-fst" 2>&1 | tee "$LOG_DIR/pr74_fixed_picker_export.log"

if [[ ! -f "$DUT_FIXED/__init__.py" || ! -f "$DUT_FIXED/_UT_Pr74CacheIOFormalDut.so" ]]; then
  echo "[34] picker export did not produce expected Python DUT package in $DUT_FIXED" >&2
  exit 1
fi

conda run -n ucagent python -c \
  "import sys; sys.path.insert(0, '$DUT_FIXED'); from __init__ import DUTPr74CacheIOFormalDut; dut=DUTPr74CacheIOFormalDut(); dut.InitClock('clock'); print('PR74 fixed DUT import OK'); dut.Finish()"

echo "[34] wrote $DUT_FIXED"
