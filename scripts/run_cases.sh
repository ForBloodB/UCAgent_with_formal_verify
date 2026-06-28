#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

case_id="all"
mode="with-formal"
smoke=0

usage() {
  cat <<'EOF'
Usage:
  bash scripts/run_cases.sh [--case all|01|02|03|04|05] [--with-formal|--no-formal] [--smoke]

Modes:
  --with-formal  Run formal-oriented flows. This is the default.
  --no-formal    Run dynamic/Toffee flows where available.
  --smoke        Do not call UCAgent/API; run local reproducible checks only.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --case)
      case_id="${2:-}"
      shift 2
      ;;
    --with-formal)
      mode="with-formal"
      shift
      ;;
    --no-formal)
      mode="no-formal"
      shift
      ;;
    --smoke)
      smoke=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

case "$case_id" in
  all|01|02|03|04|05) ;;
  *)
    echo "--case must be one of all|01|02|03|04|05" >&2
    exit 2
    ;;
esac

require_api() {
  if [[ "$smoke" == "1" ]]; then
    return
  fi
  if [[ -f "$ROOT/.ucagent_env" ]]; then
    set -a
    # shellcheck disable=SC1091
    source "$ROOT/.ucagent_env"
    set +a
  fi
  if [[ -z "${OPENAI_API_KEY:-}" || -z "${OPENAI_MODEL:-}" ]]; then
    echo "Missing OPENAI_API_KEY or OPENAI_MODEL. Use --smoke for local-only checks." >&2
    exit 1
  fi
}

run_case_01() {
  if [[ "$mode" == "no-formal" ]]; then
    echo "[01] generic formal proof is formal-only; checking RTL parse smoke"
    bash scripts/verify_verilog.sh \
      --rtl tests/cases/01_generic_formal_proof/rtl/adder_buggy.sv \
      --top adder_buggy \
      --depth 2 \
      --smoke
    return
  fi
  echo "[01] generic formal proof"
  bash scripts/internal/10_run_adder_formal_skill_smoke.sh
}

run_case_02() {
  if [[ "$mode" == "no-formal" ]]; then
    echo "[02] PR21 Toffee dynamic flow"
    bash scripts/internal/24_prepare_pr21_picker_dut.sh
    bash scripts/internal/25_run_pr21_toffee_directed.sh
    if [[ "$smoke" != "1" ]]; then
      bash scripts/internal/26_run_pr21_ucagent_toffee.sh
    fi
    return
  fi
  echo "[02] PR21 formal flow"
  bash scripts/internal/21_run_pr21_real_cache_formal.sh
  if [[ "$smoke" != "1" ]]; then
    bash scripts/internal/22_run_pr21_ucagent_formal_skill.sh
  fi
}

run_case_03() {
  if [[ "$mode" == "no-formal" ]]; then
    echo "[03] PR74 Toffee dynamic flow"
    bash scripts/internal/34_prepare_pr74_picker_dut.sh
    bash scripts/internal/35_run_pr74_toffee_directed.sh
    if [[ "$smoke" != "1" ]]; then
      bash scripts/internal/36_run_pr74_ucagent_toffee.sh
    fi
    return
  fi
  echo "[03] PR74 formal/elaboration flow"
  bash scripts/internal/31_run_pr74_real_cache_formal.sh
  if [[ "$smoke" != "1" ]]; then
    bash scripts/internal/32_run_pr74_ucagent_formal_skill.sh
  fi
}

run_case_04() {
  if [[ "$mode" == "no-formal" ]]; then
    echo "[04] L2 readBurst Toffee dynamic flow"
    bash scripts/internal/42_prepare_l2_readburst_picker_dut.sh
    bash scripts/internal/43_run_l2_readburst_toffee_directed.sh
    if [[ "$smoke" != "1" ]]; then
      bash scripts/internal/44_run_l2_readburst_ucagent_toffee.sh
    fi
    return
  fi
  echo "[04] L2 readBurst formal-first flow"
  if [[ "$smoke" == "1" ]]; then
    python3 src/ucagent_skills/generic-formal/scripts/run_formal.py \
      --case tests/cases/04_l2_readburst_hit_ready_valid_deadlock/formal/l2_readburst_assert.yaml \
      --timeout 1200
    python3 src/ucagent_skills/generic-formal/scripts/run_formal.py \
      --case tests/cases/04_l2_readburst_hit_ready_valid_deadlock/formal/l2_readburst_cover.yaml \
      --timeout 1200
    bash scripts/internal/41_run_l2_readburst_dynamic.sh
    bash scripts/internal/42_prepare_l2_readburst_picker_dut.sh
    bash scripts/internal/43_run_l2_readburst_toffee_directed.sh
  else
    bash scripts/internal/45_run_l2_readburst_ucagent_full_demo.sh
  fi
}

run_case_05() {
  echo "[05] full Cache coverage plan UCAgent/Toffee flow"
  local mode_arg="--with-formal"
  if [[ "$mode" == "no-formal" ]]; then
    mode_arg="--no-formal"
  fi
  if [[ "$smoke" == "1" ]]; then
    bash scripts/internal/50_run_full_cache_coverage_plan.sh "$mode_arg" --smoke
  else
    bash scripts/internal/50_run_full_cache_coverage_plan.sh "$mode_arg"
  fi
}

if [[ "$smoke" != "1" ]]; then
  require_api
fi

run_selected() {
  case "$1" in
    01) run_case_01 ;;
    02) run_case_02 ;;
    03) run_case_03 ;;
    04) run_case_04 ;;
    05) run_case_05 ;;
  esac
}

if [[ "$case_id" == "all" ]]; then
  for c in 01 02 03 04 05; do
    run_selected "$c"
  done
else
  run_selected "$case_id"
fi

echo "[run_cases] completed case=$case_id mode=$mode smoke=$smoke"
