#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORKSPACE="$ROOT/tests/ucagent_workspaces/04_l2_readburst_deadlock"
DUT="L2ReadBurstDeadlock"
CASE_TOFFEE="$ROOT/tests/cases/04_l2_readburst_hit_ready_valid_deadlock/toffee"
WORK_TESTS="$WORKSPACE/unity_test/tests"
REPORT_DIR="$ROOT/reports/artifacts/04_l2_readburst"
LOG_DIR="$REPORT_DIR/logs"
UCA_LOG="$LOG_DIR/ucagent_l2_readburst_full_demo.log"
MSG_FILE="$LOG_DIR/ucagent_l2_readburst_full_demo_messages.jsonl"
TOKEN_REPORT="$REPORT_DIR/full_demo_token_usage.md"
FULL_REPORT="$ROOT/reports/04_l2_readburst_ucagent_full_demo.md"
UCA_TIMEOUT="${UCAGENT_FULL_DEMO_TIMEOUT:-3600}"

mkdir -p "$LOG_DIR" "$WORK_TESTS"
cd "$ROOT"

if [[ -f "$ROOT/.ucagent_env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$ROOT/.ucagent_env"
  set +a
fi

write_blocked_report() {
  local reason="$1"
  cat > "$FULL_REPORT" <<EOF
# 04 L2 readBurst UCAgent Formal-First Full Demo

- 分类：\`INFRA_FAIL\`
- 原因：$reason

UCAgent 未运行到足以形成完整 formal-first + Toffee 结论的阶段。
EOF
}

if [[ -z "${OPENAI_API_KEY:-}" || -z "${OPENAI_MODEL:-}" ]]; then
  write_blocked_report "缺少 OPENAI_API_KEY 或 OPENAI_MODEL"
  exit 1
fi

if ! conda run -n ucagent python -c "import ucagent, toffee, toffee_test" >/dev/null 2>&1; then
  write_blocked_report "conda environment 'ucagent' cannot import ucagent/toffee/toffee_test"
  exit 1
fi

if [[ ! -f "$ROOT/reports/artifacts/04_l2_readburst/toffee_dut/__init__.py" ]]; then
  bash "$ROOT/scripts/internal/42_prepare_l2_readburst_picker_dut.sh"
fi

rm -rf "$WORKSPACE/.ucagent" "$WORKSPACE/uc_test_report"
rm -f "$UCA_LOG" "$MSG_FILE" "$FULL_REPORT"
mkdir -p "$WORKSPACE/reports" "$WORK_TESTS"

if [[ -f "$ROOT/reports/04_l2_readburst.md" ]]; then
  cp "$ROOT/reports/04_l2_readburst.md" "$WORKSPACE/reports/04_l2_readburst.md"
fi
if [[ -f "$ROOT/reports/04_l2_readburst_toffee_coverage.md" ]]; then
  cp "$ROOT/reports/04_l2_readburst_toffee_coverage.md" "$WORKSPACE/reports/04_l2_readburst_toffee_coverage.md"
fi

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

LOOP_MSG="Complete the 04 formal-first full demo in one UCAgent run. First use the generic-formal skill as a pre-diagnosis tool: ListSkill, read .ucagent/skills/generic-formal/SKILL.md, RunSkillScript for l2_readburst_assert.yaml and l2_readburst_cover.yaml, read reports/04_l2_readburst.md, and SetSkillUsage. If the assert case reports a counterexample, write the reproduction idea: same-address L2 readBurst miss/refill, then same-address readBurst hit with resp_ready=0, observe resp_valid. Then continue regardless of the formal result and run the original official Toffee flow with RunTestCases using pytest args 'test_l2_readburst_ready_valid.py -q'. Summarize both the formal diagnosis and Toffee scenario coverage. Do not run PR21, PR74, MMIO prefetch, idBits, or any other case. Do not describe this candidate issue as upstream-confirmed."

export L2_READBURST_TOFFEE_DUT_DIR="$ROOT/reports/artifacts/04_l2_readburst/toffee_dut"
export NUTSHELL_CACHE_VERIFY_ROOT="$ROOT"
export PYTHONPATH="$WORK_TESTS:$L2_READBURST_TOFFEE_DUT_DIR:${PYTHONPATH:-}"

set +e
timeout "$UCA_TIMEOUT" conda run -n ucagent ucagent "$WORKSPACE" "$DUT" \
  --config "$WORKSPACE/config_full_demo.yaml" \
  --backend=langchain \
  --use-skill \
  --extra-skill-path "$ROOT/src/ucagent_skills" \
  --override "skill.general_skill_list=['generic-formal']" \
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
  write_blocked_report "UCAgent full demo timed out after ${UCA_TIMEOUT}s"
  exit 1
fi

if [[ "$ucagent_rc" -ne 0 ]]; then
  if [[ -f "$UCA_LOG" ]] && grep -q "ToolExit:" "$UCA_LOG" && grep -q "ToolComplete:" "$UCA_LOG"; then
    echo "[45] UCAgent returned $ucagent_rc after ToolComplete/ToolExit; treating completed mission as success"
  else
    write_blocked_report "UCAgent full demo exited with code $ucagent_rc"
    exit "$ucagent_rc"
  fi
fi

if [[ ! -f "$MSG_FILE" ]]; then
  write_blocked_report "missing UCAgent message log"
  exit 1
fi

if [[ ! -f "$WORKSPACE/uc_test_report/index.html" ]]; then
  write_blocked_report "missing UCAgent Toffee report index.html"
  exit 1
fi

if [[ ! -f "$ROOT/reports/04_l2_readburst.md" ]]; then
  write_blocked_report "missing formal report reports/04_l2_readburst.md"
  exit 1
fi

if [[ ! -f "$ROOT/reports/04_l2_readburst_toffee_coverage.md" ]]; then
  write_blocked_report "missing Toffee coverage report reports/04_l2_readburst_toffee_coverage.md"
  exit 1
fi

if ! grep -q "RunSkillScript (call_" "$MSG_FILE"; then
  write_blocked_report "message log does not show RunSkillScript"
  exit 1
fi

if ! grep -q "l2_readburst_assert.yaml" "$MSG_FILE" || ! grep -q "l2_readburst_cover.yaml" "$MSG_FILE"; then
  write_blocked_report "RunSkillScript did not include both assert and cover formal cases"
  exit 1
fi

if ! grep -q "RunTestCases (call_" "$MSG_FILE"; then
  write_blocked_report "message log does not show RunTestCases"
  exit 1
fi

if ! grep -q "SetSkillUsage (call_" "$MSG_FILE"; then
  write_blocked_report "message log does not show SetSkillUsage"
  exit 1
fi

if ! grep -q "ToolComplete:" "$UCA_LOG" || ! grep -q "ToolExit:" "$UCA_LOG"; then
  write_blocked_report "UCAgent log does not show ToolComplete and ToolExit"
  exit 1
fi

formal_assert_result="UNKNOWN"
if grep -q '`l2_readburst_hit_ready_deadlock_assert` | FAIL | FAIL | OK' "$ROOT/reports/04_l2_readburst.md"; then
  formal_assert_result="FAIL as expected"
fi
formal_cover_result="UNKNOWN"
if grep -q '`l2_readburst_hit_ready_deadlock_cover` | PASS | PASS | OK' "$ROOT/reports/04_l2_readburst.md"; then
  formal_cover_result="PASS as expected"
fi
toffee_coverage="UNKNOWN"
if grep -q '04 场景 setup coverage：`5/5 = 100.0%`' "$ROOT/reports/04_l2_readburst_toffee_coverage.md"; then
  toffee_coverage="5/5 = 100.0%"
fi
toffee_classification="UNKNOWN"
if grep -q '分类：`DYNAMIC_REPRODUCED`' "$ROOT/reports/04_l2_readburst_toffee_coverage.md"; then
  toffee_classification="DYNAMIC_REPRODUCED"
fi

cat > "$FULL_REPORT" <<EOF
# 04 L2 readBurst UCAgent Formal-First Full Demo

- 分类：\`UCAgent_FORMAL_FIRST_FULL_DEMO_COMPLETED\`
- Formal assert：\`${formal_assert_result}\`
- Formal cover：\`${formal_cover_result}\`
- Toffee classification：\`${toffee_classification}\`
- Toffee 04 场景 setup coverage：\`${toffee_coverage}\`

## 1. Formal 前置诊断

UCAgent 在同一次 mission 中先通过 \`generic-formal\` skill 执行：

- \`l2_readburst_assert.yaml\`
- \`l2_readburst_cover.yaml\`

formal 报告：\`reports/04_l2_readburst.md\`

该阶段用于让 agent 先拥有形式验证搜索能力，而不是直接进入动态测试。

## 2. Bug 复现方式

当 formal assert 给出反例时，复现思路为：

1. 对同一地址发起一次 L2 \`readBurst\` miss。
2. 让内存模型完成 refill，形成 cache line。
3. 再对同一地址发起第二次 \`readBurst\`，使其成为 L2 hit。
4. 在 S3 hit/readBurst 窗口将 L1 侧 \`resp_ready=0\`。
5. 观察 \`resp_valid\` 是否仍主动拉高；当前 04 现象为 \`resp_valid\` 保持低电平。

该结论仍是 latest upstream candidate bug，不写成 upstream 已确认公开 bug。

## 3. 原本 UCAgent Toffee 流程

formal 诊断后，UCAgent 没有停止，而是继续通过官方 \`RunTestCases\` 运行：

\`\`\`text
test_l2_readburst_ready_valid.py -q
\`\`\`

动态报告：\`reports/04_l2_readburst_toffee_coverage.md\`
UCAgent Toffee HTML：\`tests/ucagent_workspaces/04_l2_readburst_deadlock/uc_test_report/index.html\`

该阶段证明 formal 发现可以继续转化为 Toffee/pytest 动态复现与回归测试。

## 4. UCAgent 证据

- UCAgent log：\`${UCA_LOG#${ROOT}/}\`
- Message log：\`${MSG_FILE#${ROOT}/}\`
- Token report：\`${TOKEN_REPORT#${ROOT}/}\`

日志验收项包含：\`RunSkillScript\`、\`SetSkillUsage\`、\`RunTestCases\`、\`ToolComplete\`、\`ToolExit\`。
EOF

cp "$ROOT/reports/04_l2_readburst.md" "$WORKSPACE/reports/04_l2_readburst.md"
cp "$ROOT/reports/04_l2_readburst_toffee_coverage.md" "$WORKSPACE/reports/04_l2_readburst_toffee_coverage.md"

echo "[45] wrote ${FULL_REPORT#${ROOT}/}"
echo "[45] wrote ${TOKEN_REPORT#${ROOT}/}"
