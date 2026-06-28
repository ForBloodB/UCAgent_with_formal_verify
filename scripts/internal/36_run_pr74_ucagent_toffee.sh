#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORKSPACE="$ROOT/tests/ucagent_workspaces/03_pr74_cache_io_idbits"
DUT="Pr74CacheIOIdBits"
CASE_TOFFEE="$ROOT/tests/cases/03_pr74_cache_io_idbits/toffee"
WORK_TESTS="$WORKSPACE/unity_test/tests"
ARTIFACT_ROOT="$ROOT/reports/artifacts/03_pr74"
REPORT_DIR="$ARTIFACT_ROOT/toffee_ucagent"
LOG_DIR="$REPORT_DIR/logs"
UCA_LOG="$LOG_DIR/ucagent_pr74_toffee.log"
MSG_FILE="$LOG_DIR/ucagent_pr74_toffee_messages.jsonl"
TOKEN_REPORT="$REPORT_DIR/token_usage.md"
REPORT="$ROOT/reports/03_pr74_toffee_ucagent.md"
UCA_TIMEOUT="${UCAGENT_PR74_TOFFEE_TIMEOUT:-2400}"

mkdir -p "$LOG_DIR" "$WORK_TESTS" "$WORKSPACE/reports"
cd "$ROOT"

if [[ -f "$ROOT/.ucagent_env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$ROOT/.ucagent_env"
  set +a
fi

if [[ -z "${OPENAI_API_KEY:-}" || -z "${OPENAI_MODEL:-}" ]]; then
  cat > "$REPORT" <<'EOF'
# 03 PR74 UCAgent Toffee 动态后端

- 分类：`BLOCKED_NO_LLM_ENV`
- 原因：缺少 `OPENAI_API_KEY` 或 `OPENAI_MODEL`。
EOF
  exit 1
fi

if [[ ! -f "$ARTIFACT_ROOT/toffee_dut_fixed/__init__.py" ]]; then
  bash "$ROOT/scripts/internal/34_prepare_pr74_picker_dut.sh"
fi

rm -rf "$WORKSPACE/.ucagent" "$WORKSPACE/uc_test_report"
rm -f "$UCA_LOG" "$MSG_FILE" "$REPORT"
mkdir -p "$ARTIFACT_ROOT/ucagent_draft"
if compgen -G "$WORK_TESTS/*" > /dev/null; then
  cp -a "$WORK_TESTS"/. "$ARTIFACT_ROOT/ucagent_draft/"
fi
rm -rf "$WORK_TESTS"
mkdir -p "$WORK_TESTS"

cp "$CASE_TOFFEE"/Pr74CacheIOIdBits_api.py "$WORK_TESTS/"
cp "$CASE_TOFFEE"/Pr74CacheIOIdBits_function_coverage_def.py "$WORK_TESTS/"
cp "$CASE_TOFFEE"/Pr74CacheIOIdBits.ignore "$WORK_TESTS/"
cp "$CASE_TOFFEE"/pr74_toffee_common.py "$WORK_TESTS/"
cp "$CASE_TOFFEE"/test_pr74_cache_io_idbits.py "$WORK_TESTS/"

cat > "$WORKSPACE/unity_test/.pytest.ini" <<EOF
[pytest]
addopts = --toffee-report --report-dump-json --report-name=index.html --report-dir=$WORKSPACE/uc_test_report
pythonpath =
    ./tests
    ../
    $ARTIFACT_ROOT/toffee_dut_fixed
    $ROOT/third_party/UCAgent
testpaths = ./tests
EOF

if [[ -f "$ROOT/reports/03_pr74_toffee_coverage.md" ]]; then
  cp "$ROOT/reports/03_pr74_toffee_coverage.md" "$WORKSPACE/reports/03_pr74_toffee_coverage.md"
fi

LOOP_MSG="Run the official UCAgent Toffee dynamic flow for case 03 PR74 CacheIO idBits. Do not use any formal verification skill. Read README.md, Pr74CacheIOIdBits/README.md, unity_test/tests/Pr74CacheIOIdBits_api.py, and unity_test/tests/test_pr74_cache_io_idbits.py. Then run RunTestCases with pytest args 'test_pr74_cache_io_idbits.py -q'. Summarize the fixed-DUT Toffee coverage and mention that the historical pre-PR failure is an interface/elaboration issue captured by the prepare log. Do not call ListSkill, RunSkillScript, SetSkillUsage, or any formal tool."

export NUTSHELL_CACHE_VERIFY_ROOT="$ROOT"
export PYTHONPATH="$WORK_TESTS:$ARTIFACT_ROOT/toffee_dut_fixed:${PYTHONPATH:-}"

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
  echo "[36] UCAgent Toffee run timed out after ${UCA_TIMEOUT}s" >&2
  exit 1
fi

if [[ "$ucagent_rc" -ne 0 ]]; then
  if [[ -f "$UCA_LOG" ]] && grep -q "ToolComplete:" "$UCA_LOG" && grep -q "ToolExit:" "$UCA_LOG"; then
    echo "[36] UCAgent returned $ucagent_rc after ToolComplete/ToolExit; treating completed mission as success"
  else
    echo "[36] UCAgent Toffee run exited with code $ucagent_rc" >&2
    exit "$ucagent_rc"
  fi
fi

if [[ ! -f "$MSG_FILE" ]] || ! grep -q "RunTestCases" "$MSG_FILE"; then
  echo "[36] message log does not show RunTestCases" >&2
  exit 1
fi

if grep -q "  RunSkillScript (call_" "$MSG_FILE"; then
  echo "[36] no-formal dynamic run unexpectedly used RunSkillScript" >&2
  exit 1
fi

if [[ ! -f "$WORKSPACE/uc_test_report/index.html" ]]; then
  echo "[36] missing UCAgent Toffee report index.html" >&2
  exit 1
fi

cat > "$REPORT" <<EOF
# 03 PR74 UCAgent Toffee 动态后端

- 分类：\`UCAgent_TOFFEE_COMPLETED_NO_FORMAL\`
- UCAgent log：\`${UCA_LOG#${ROOT}/}\`
- Message log：\`${MSG_FILE#${ROOT}/}\`
- UCAgent Toffee HTML：\`${WORKSPACE#${ROOT}/}/uc_test_report/index.html\`
- Toffee coverage report：\`reports/03_pr74_toffee_coverage.md\`
- UCAgent draft archive：\`${ARTIFACT_ROOT#${ROOT}/}/ucagent_draft\`
- Token report：\`${TOKEN_REPORT#${ROOT}/}\`

本次运行不调用 formal skill。UCAgent 使用官方 \`unity_test/tests\` 结构运行人工完善后的 Toffee dynamic backend；草稿模板归档在 artifact 目录，人工补强了 fixed response ID scoreboard 和 coverage。
EOF

cp "$REPORT" "$WORKSPACE/reports/03_pr74_toffee_ucagent.md"
echo "[36] wrote $REPORT"
