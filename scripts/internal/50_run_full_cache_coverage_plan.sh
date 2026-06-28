#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CASE_TOFFEE="$ROOT/tests/cases/05_full_cache_coverage_plan/toffee"
WORKSPACE="$ROOT/tests/ucagent_workspaces/05_full_cache_coverage_plan"
DUT="FullCacheCoveragePlan"
WORK_TESTS="$WORKSPACE/unity_test/tests"
REPORT_DIR="$ROOT/reports/artifacts/05_full_cache_coverage_plan"
LOG_DIR="$REPORT_DIR/logs"
REPORT="$ROOT/reports/05_full_cache_coverage_plan_ucagent.md"
SMOKE_REPORT="$ROOT/reports/05_full_cache_coverage_plan_smoke.md"
UCA_TIMEOUT="${UCAGENT_05_TIMEOUT:-1800}"
SMOKE=0
MODE="with-formal"

usage() {
  cat <<'EOF'
Usage:
  bash scripts/internal/50_run_full_cache_coverage_plan.sh [--with-formal] [--smoke]

Options:
  --with-formal  Run UCAgent formal-first flow, then RunTestCases. This is mandatory for case 05.
  --smoke  Run local pytest only; do not call UCAgent/API.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-formal)
      MODE="with-formal"
      shift
      ;;
    --no-formal)
      echo "Case 05 does not support --no-formal; it must use UCAgent with generic-formal." >&2
      exit 2
      ;;
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

MODE_TAG="with_formal"
UCA_LOG="$LOG_DIR/ucagent_full_cache_coverage_plan_${MODE_TAG}.log"
MSG_FILE="$LOG_DIR/ucagent_full_cache_coverage_plan_${MODE_TAG}_messages.jsonl"
TOKEN_REPORT="$REPORT_DIR/toffee_ucagent/token_usage.md"
MODE_REPORT="$ROOT/reports/05_full_cache_coverage_plan_ucagent_with_formal.md"

mkdir -p "$LOG_DIR" "$WORK_TESTS" "$WORKSPACE/reports" "$REPORT_DIR/toffee_ucagent"
cd "$ROOT"

mkdir -p "$WORK_TESTS"
rm -f "$WORKSPACE/reports"/02_* "$WORKSPACE/reports"/03_* "$WORKSPACE/reports"/04_* "$WORKSPACE/unity_test"/reports_02_* "$WORKSPACE/unity_test"/reports_03_* "$WORKSPACE/unity_test"/reports_04_*
rm -rf "$WORKSPACE/reports/generic_formal" "$WORKSPACE/unity_test/reports" "$WORKSPACE/unity_test/copy_reports_case" "$WORKSPACE/unity_test/copy_reports.py" "$WORKSPACE/unity_test/copy_reports_case.sby" "$WORKSPACE/unity_test/copy_reports_case.yaml" "$WORKSPACE/unity_test/dummy.sv" "$WORKSPACE/unity_test/dummy_report.md"
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

python3 -m pytest -q -c /dev/null "$WORK_TESTS/test_full_cache_coverage_plan.py"
cp "$ROOT/reports/05_full_cache_coverage_plan.md" "$WORKSPACE/reports/05_full_cache_coverage_plan.md"
cp "$ROOT/reports/05_ucagent_bug_candidates.md" "$WORKSPACE/reports/05_ucagent_bug_candidates.md"

if [[ "$SMOKE" == "1" ]]; then
  cat > "$SMOKE_REPORT" <<EOF
# 05 全 Cache 声明功能覆盖闭环

- 分类：\`SMOKE_LOCAL_PYTEST_COMPLETED\`
- 本地报告：\`reports/05_full_cache_coverage_plan.md\`
- Bug candidate report：\`reports/05_ucagent_bug_candidates.md\`
- Summary JSON：\`reports/artifacts/05_full_cache_coverage_plan/coverage_plan_summary.json\`

本次运行使用 \`--smoke\`，不调用 UCAgent API。它验证 05 latest 声明的 15 个 functional coverage points、scoreboard、candidate report 和 evidence 映射是可执行检查的。
EOF
  echo "[50] wrote reports/05_full_cache_coverage_plan.md"
  echo "[50] wrote reports/05_full_cache_coverage_plan_smoke.md"
  exit 0
fi

rm -rf "$WORKSPACE/.ucagent" "$WORKSPACE/uc_test_report"
rm -f "$UCA_LOG" "$MSG_FILE" "$REPORT" "$MODE_REPORT" "$ROOT/reports/05_full_cache_formal_skill.md" "$WORKSPACE/reports/05_full_cache_formal_skill.md"

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

CONFIG="$WORKSPACE/config_full_demo.yaml"
LOOP_MSG="Run case 05 as a latest-only formal-enabled UCAgent flow. First use the generic-formal skill: ListSkill, read .ucagent/skills/generic-formal/SKILL.md, RunSkillScript for latest_l2_readburst_assert.yaml and latest_l2_readburst_cover.yaml, read reports/05_full_cache_formal_skill.md, then SetSkillUsage. Continue regardless of formal failures and call RunTestCases with pytest args 'test_full_cache_coverage_plan.py -q'. Summarize reports/05_full_cache_coverage_plan.md and reports/05_ucagent_bug_candidates.md. State that 15/15 means latest declared functional coverage closure, not full RTL coverage. Do not run historical PR cases or old-version evidence."
SKILL_ARGS=(--use-skill --extra-skill-path "$ROOT/src/ucagent_skills" --override "skill.general_skill_list=['generic-formal']")

set +e
timeout "$UCA_TIMEOUT" conda run -n ucagent ucagent "$WORKSPACE" "$DUT" \
  --config "$CONFIG" \
  --backend=langchain \
  "${SKILL_ARGS[@]}" \
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
cp "$TOKEN_REPORT" "$REPORT_DIR/toffee_ucagent/token_usage_with_formal.md"

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

if ! grep -q "RunSkillScript (call_" "$MSG_FILE"; then
  echo "[50] formal-enabled flow did not use RunSkillScript" >&2
  exit 1
fi
if ! grep -q "SetSkillUsage (call_" "$MSG_FILE"; then
  echo "[50] formal-enabled flow did not use SetSkillUsage" >&2
  exit 1
fi
for formal_case in latest_l2_readburst_assert.yaml latest_l2_readburst_cover.yaml; do
  if ! grep -q "$formal_case" "$MSG_FILE"; then
    echo "[50] formal-enabled flow did not mention $formal_case" >&2
    exit 1
  fi
done
for forbidden in pr21_pre.yaml pr21_fixed.yaml pr74_pre_elab.yaml pr74_fixed.yaml; do
  if grep -q "$forbidden" "$MSG_FILE"; then
    echo "[50] case 05 unexpectedly mentioned historical formal case $forbidden" >&2
    exit 1
  fi
done

if [[ ! -f "$WORKSPACE/uc_test_report/index.html" ]]; then
  echo "[50] missing UCAgent Toffee report index.html" >&2
  exit 1
fi

if [[ ! -f "$ROOT/reports/05_full_cache_coverage_plan.md" ]]; then
  echo "[50] missing plan report" >&2
  exit 1
fi

if [[ ! -f "$ROOT/reports/05_ucagent_bug_candidates.md" ]]; then
  echo "[50] missing bug candidate report" >&2
  exit 1
fi

cp "$ROOT/reports/05_full_cache_coverage_plan.md" "$WORKSPACE/reports/05_full_cache_coverage_plan.md"
cp "$ROOT/reports/05_ucagent_bug_candidates.md" "$WORKSPACE/reports/05_ucagent_bug_candidates.md"

cat > "$MODE_REPORT" <<EOF
# 05 全 Cache 声明功能覆盖闭环 UCAgent 流程

- 分类：\`UCAgent_DECLARED_COVERAGE_CLOSURE_COMPLETED\`
- Mode：\`with-formal\`
- UCAgent log：\`${UCA_LOG#${ROOT}/}\`
- Message log：\`${MSG_FILE#${ROOT}/}\`
- UCAgent Toffee HTML：\`${WORKSPACE#${ROOT}/}/uc_test_report/index.html\`
- Plan report：\`reports/05_full_cache_coverage_plan.md\`
- Bug candidate report：\`reports/05_ucagent_bug_candidates.md\`
- Summary JSON：\`reports/artifacts/05_full_cache_coverage_plan/coverage_plan_summary.json\`
- Token report：\`${TOKEN_REPORT#${ROOT}/}\`

本次运行是 05 唯一正式流程：UCAgent 先调用 \`generic-formal\` skill 运行 latest Cache formal diagnosis，再继续 \`RunTestCases\`。这里的 100% 只表示 05 latest 声明功能覆盖闭环，不代表完整 RTL line/toggle 覆盖率。
EOF

cp "$MODE_REPORT" "$REPORT"

echo "[50] wrote reports/05_full_cache_coverage_plan.md"
echo "[50] wrote reports/05_full_cache_coverage_plan_ucagent.md"
echo "[50] wrote ${MODE_REPORT#${ROOT}/}"
