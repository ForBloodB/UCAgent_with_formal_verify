#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORKSPACE="$ROOT/tests/ucagent_workspaces/04_l2_readburst_deadlock"
DUT="L2ReadBurstDeadlock"
CASE_TOFFEE="$ROOT/tests/cases/04_l2_readburst_hit_ready_valid_deadlock/toffee"
WORK_TESTS="$WORKSPACE/unity_test/tests"
REPORT_DIR="$ROOT/reports/artifacts/04_l2_readburst"
TOFFEE_DIR="$REPORT_DIR/toffee"
LOG_DIR="$REPORT_DIR/logs"
UCA_LOG="$LOG_DIR/ucagent_l2_readburst_toffee.log"
MSG_FILE="$LOG_DIR/ucagent_l2_readburst_toffee_messages.jsonl"
TOKEN_REPORT="$REPORT_DIR/toffee_token_usage.md"
UCA_TIMEOUT="${UCAGENT_TOFFEE_TIMEOUT:-2400}"

mkdir -p "$LOG_DIR" "$TOFFEE_DIR" "$WORK_TESTS"
cd "$ROOT"

if [[ -f "$ROOT/.ucagent_env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$ROOT/.ucagent_env"
  set +a
fi

if [[ -z "${OPENAI_API_KEY:-}" || -z "${OPENAI_MODEL:-}" ]]; then
  cat > "$ROOT/reports/04_l2_readburst_toffee_ucagent.md" <<'EOF'
# 04 L2 readBurst UCAgent Toffee 运行

- 分类：`BLOCKED_NO_LLM_ENV`
- 原因：缺少 `OPENAI_API_KEY` 或 `OPENAI_MODEL`。
EOF
  exit 1
fi

if [[ ! -f "$ROOT/reports/artifacts/04_l2_readburst/toffee_dut/__init__.py" ]]; then
  bash "$ROOT/scripts/internal/42_prepare_l2_readburst_picker_dut.sh"
fi

rm -rf "$WORKSPACE/.ucagent" "$WORKSPACE/uc_test_report"
mkdir -p "$WORKSPACE/reports"
if [[ -f "$ROOT/reports/04_l2_readburst_toffee_coverage.md" ]]; then
  cp "$ROOT/reports/04_l2_readburst_toffee_coverage.md" "$WORKSPACE/reports/04_l2_readburst_toffee_coverage.md"
fi
mkdir -p "$WORK_TESTS"
cp "$CASE_TOFFEE"/L2ReadBurstDeadlock_api.py "$WORK_TESTS/"
cp "$CASE_TOFFEE"/L2ReadBurstDeadlock_function_coverage_def.py "$WORK_TESTS/"
cp "$CASE_TOFFEE"/L2ReadBurstDeadlock.ignore "$WORK_TESTS/"
cp "$CASE_TOFFEE"/l2_readburst_toffee_common.py "$WORK_TESTS/"
cp "$CASE_TOFFEE"/test_l2_readburst_ready_valid.py "$WORK_TESTS/"

cat > "$WORKSPACE/unity_test/.pytest.ini" <<EOF
[pytest]
addopts = --toffee-report --report-dump-json --report-name=index.html --report-dir=$WORKSPACE/uc_test_report
pythonpath =
    ./tests
    ../
    $ROOT/reports/artifacts/04_l2_readburst/toffee_dut
    $ROOT/third_party/UCAgent
testpaths = ./tests
EOF

LOOP_MSG="Complete the official UCAgent Toffee flow for the latest NutShell Cache l2_readburst_hit_ready_valid_deadlock case. Use the existing human-curated Toffee files under unity_test/tests. First read README.md and L2ReadBurstDeadlock/README.md. Then read unity_test/tests/test_l2_readburst_ready_valid.py and unity_test/tests/L2ReadBurstDeadlock_api.py. Run the directed Toffee pytest with RunTestCases using pytest args 'test_l2_readburst_ready_valid.py -q'. Summarize the Toffee functional coverage report and explicitly say this is 04-scenario coverage, not full Cache coverage. Do not run PR21, PR74, MMIO prefetch, idBits, or any other case. Do not call the generic-formal skill in this Toffee run. Do not describe this candidate issue as upstream-confirmed."

export L2_READBURST_TOFFEE_DUT_DIR="$ROOT/reports/artifacts/04_l2_readburst/toffee_dut"
export NUTSHELL_CACHE_VERIFY_ROOT="$ROOT"
export PYTHONPATH="$WORK_TESTS:$L2_READBURST_TOFFEE_DUT_DIR:${PYTHONPATH:-}"

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
  echo "[44] UCAgent Toffee run timed out after ${UCA_TIMEOUT}s" >&2
  exit 1
fi

if [[ "$ucagent_rc" -ne 0 ]]; then
  if [[ -f "$UCA_LOG" ]] && grep -q "ToolExit:" "$UCA_LOG" && grep -q "ToolComplete:" "$UCA_LOG"; then
    echo "[44] UCAgent returned $ucagent_rc after ToolComplete/ToolExit; treating completed mission as success"
  else
    echo "[44] UCAgent Toffee run exited with code $ucagent_rc" >&2
    exit "$ucagent_rc"
  fi
fi

if ! grep -q "RunTestCases" "$MSG_FILE"; then
  echo "[44] message log does not show RunTestCases" >&2
  exit 1
fi

if [[ ! -f "$WORKSPACE/uc_test_report/index.html" ]]; then
  echo "[44] missing UCAgent Toffee report index.html" >&2
  exit 1
fi

cat > "$ROOT/reports/04_l2_readburst_toffee_ucagent.md" <<EOF
# 04 L2 readBurst UCAgent Toffee 运行

- 分类：\`UCAgent_TOFFEE_COMPLETED\`
- UCAgent log：\`${UCA_LOG#${ROOT}/}\`
- Message log：\`${MSG_FILE#${ROOT}/}\`
- UCAgent Toffee HTML：\`${WORKSPACE#${ROOT}/}/uc_test_report/index.html\`
- Toffee coverage report：\`reports/04_l2_readburst_toffee_coverage.md\`
- Workspace mirrored coverage report：\`${WORKSPACE#${ROOT}/}/reports/04_l2_readburst_toffee_coverage.md\`
- Token report：\`${TOKEN_REPORT#${ROOT}/}\`

本次运行使用官方 UCAgent workspace 的 \`unity_test/tests\` 结构，调用 \`RunTestCases\` 运行人工校正后的 Toffee directed test。该结果证明 UCAgent 可以完整跑通 04 的 Toffee 动态验证闭环。
EOF

echo "[44] wrote reports/04_l2_readburst_toffee_ucagent.md"
echo "[44] wrote $TOKEN_REPORT"
