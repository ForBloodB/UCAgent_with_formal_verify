#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CASE_TOFFEE="$ROOT/tests/cases/05_full_cache_coverage_plan/toffee"
WORKSPACE="$ROOT/tests/ucagent_workspaces/05_full_cache_coverage_plan"
DUT="FullCacheCoveragePlan"
WORK_TESTS="$WORKSPACE/unity_test/tests"
REPORT_DIR="$ROOT/reports/artifacts/05_full_cache_coverage_plan"
LOG_DIR="$REPORT_DIR/logs"
UCA_LOG="$LOG_DIR/ucagent_full_cache_coverage_plan.log"
MSG_FILE="$LOG_DIR/ucagent_full_cache_coverage_plan_messages.jsonl"
TOKEN_REPORT="$REPORT_DIR/toffee_ucagent/token_usage.md"
REPORT="$ROOT/reports/05_full_cache_coverage_plan_ucagent.md"
SMOKE_REPORT="$ROOT/reports/05_full_cache_coverage_plan_smoke.md"
UCA_TIMEOUT="${UCAGENT_05_TIMEOUT:-1800}"
SMOKE=0

usage() {
  cat <<'EOF'
Usage:
  bash scripts/internal/50_run_full_cache_coverage_plan.sh [--smoke]

Options:
  --smoke  Run local pytest only; do not call UCAgent/API.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --smoke)
      SMOKE=1
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

mkdir -p "$LOG_DIR" "$WORK_TESTS" "$WORKSPACE/reports" "$REPORT_DIR/toffee_ucagent"
cd "$ROOT"

mkdir -p "$WORK_TESTS"
cp "$CASE_TOFFEE"/FullCacheCoveragePlan_api.py "$WORK_TESTS/"
cp "$CASE_TOFFEE"/test_full_cache_coverage_plan.py "$WORK_TESTS/"

cat > "$WORKSPACE/unity_test/.pytest.ini" <<EOF
[pytest]
addopts = --toffee-report --report-dump-json --report-name=index.html --report-dir=$WORKSPACE/uc_test_report
pythonpath =
    ./tests
    ../
    $ROOT/third_party/UCAgent
testpaths = ./tests
EOF

export NUTSHELL_CACHE_VERIFY_ROOT="$ROOT"
export PYTHONPATH="$WORK_TESTS:${PYTHONPATH:-}"

if [[ "$SMOKE" == "1" ]]; then
  python3 -m pytest -q -c /dev/null "$WORK_TESTS/test_full_cache_coverage_plan.py"
  cp "$ROOT/reports/05_full_cache_coverage_plan.md" "$WORKSPACE/reports/05_full_cache_coverage_plan.md"
  cat > "$SMOKE_REPORT" <<EOF
# 05 全 Cache Coverage Plan UCAgent 流程

- 分类：\`SMOKE_LOCAL_PYTEST_COMPLETED\`
- 本地报告：\`reports/05_full_cache_coverage_plan.md\`
- Summary JSON：\`reports/artifacts/05_full_cache_coverage_plan/coverage_plan_summary.json\`

本次运行使用 \`--smoke\`，不调用 UCAgent API。它验证 coverage plan、CRV plan、scoreboard plan 和 evidence 映射是可执行检查的。
EOF
  echo "[50] wrote reports/05_full_cache_coverage_plan.md"
  echo "[50] wrote reports/05_full_cache_coverage_plan_smoke.md"
  exit 0
fi

rm -rf "$WORKSPACE/.ucagent" "$WORKSPACE/uc_test_report"
rm -f "$UCA_LOG" "$MSG_FILE" "$REPORT"

if [[ -f "$ROOT/.ucagent_env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$ROOT/.ucagent_env"
  set +a
fi

if [[ -z "${OPENAI_API_KEY:-}" || -z "${OPENAI_MODEL:-}" ]]; then
  cat > "$REPORT" <<'EOF'
# 05 全 Cache Coverage Plan UCAgent 流程

- 分类：`BLOCKED_NO_LLM_ENV`
- 原因：缺少 `OPENAI_API_KEY` 或 `OPENAI_MODEL`。
EOF
  exit 1
fi

LOOP_MSG="Run case 05 through the official UCAgent Toffee/pytest flow. This is a full Cache coverage-plan validation, not a fifth bug and not a claim that full Cache coverage is achieved. Read README.md, FullCacheCoveragePlan/README.md, unity_test/tests/FullCacheCoveragePlan_api.py, and unity_test/tests/test_full_cache_coverage_plan.py. Then call RunTestCases with pytest args 'test_full_cache_coverage_plan.py -q'. Summarize reports/05_full_cache_coverage_plan.md, especially implemented, partial, and gap coverage points. Do not call any formal skill."

set +e
timeout "$UCA_TIMEOUT" conda run -n ucagent ucagent "$WORKSPACE" "$DUT" \
  --config "$WORKSPACE/config_toffee.yaml" \
  --backend=langchain \
  --exit-on-completion \
  --no-history \
  --stream-output \
  --log \
  --log-file "$UCA_LOG" \
  --msg-file "$MSG_FILE" \
  --loop-msg "$LOOP_MSG"
ucagent_rc=$?
set -e

python3 "$ROOT/src/lib/collect_ucagent_token_usage.py" \
  --log-dir "$LOG_DIR" \
  --output "$TOKEN_REPORT" || true

if [[ "$ucagent_rc" -eq 124 ]]; then
  echo "[50] UCAgent run timed out after ${UCA_TIMEOUT}s" >&2
  exit 1
fi

if [[ "$ucagent_rc" -ne 0 ]]; then
  if [[ -f "$UCA_LOG" ]] && grep -q "ToolComplete:" "$UCA_LOG" && grep -q "ToolExit:" "$UCA_LOG"; then
    echo "[50] UCAgent returned $ucagent_rc after ToolComplete/ToolExit; treating completed mission as success"
  else
    echo "[50] UCAgent run exited with code $ucagent_rc" >&2
    exit "$ucagent_rc"
  fi
fi

if [[ ! -f "$MSG_FILE" ]] || ! grep -q "RunTestCases" "$MSG_FILE"; then
  echo "[50] message log does not show RunTestCases" >&2
  exit 1
fi

if grep -q "  RunSkillScript (call_" "$MSG_FILE"; then
  echo "[50] plan-check flow unexpectedly used RunSkillScript" >&2
  exit 1
fi

if [[ ! -f "$WORKSPACE/uc_test_report/index.html" ]]; then
  echo "[50] missing UCAgent Toffee report index.html" >&2
  exit 1
fi

if [[ ! -f "$ROOT/reports/05_full_cache_coverage_plan.md" ]]; then
  echo "[50] missing plan report" >&2
  exit 1
fi

cp "$ROOT/reports/05_full_cache_coverage_plan.md" "$WORKSPACE/reports/05_full_cache_coverage_plan.md"

cat > "$REPORT" <<EOF
# 05 全 Cache Coverage Plan UCAgent 流程

- 分类：\`UCAgent_TOFFEE_COVERAGE_PLAN_COMPLETED\`
- UCAgent log：\`${UCA_LOG#${ROOT}/}\`
- Message log：\`${MSG_FILE#${ROOT}/}\`
- UCAgent Toffee HTML：\`${WORKSPACE#${ROOT}/}/uc_test_report/index.html\`
- Plan report：\`reports/05_full_cache_coverage_plan.md\`
- Summary JSON：\`reports/artifacts/05_full_cache_coverage_plan/coverage_plan_summary.json\`
- Token report：\`${TOKEN_REPORT#${ROOT}/}\`

本次运行使用官方 UCAgent \`RunTestCases\` 后端检查全 Cache coverage plan 的完整性与诚实性。它不声称已经达到完整 NutShell Cache functional coverage，而是把后续需要人工定义和实现的 CRV、scoreboard、coverage database 明确落成可执行计划。
EOF

echo "[50] wrote reports/05_full_cache_coverage_plan.md"
echo "[50] wrote reports/05_full_cache_coverage_plan_ucagent.md"
