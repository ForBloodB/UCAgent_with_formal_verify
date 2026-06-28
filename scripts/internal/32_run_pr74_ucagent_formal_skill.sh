#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORKSPACE="$ROOT/tests/ucagent_workspaces/03_pr74_cache_io_idbits"
DUT="Pr74CacheIOIdBits"
REPORT="$ROOT/reports/03_pr74_ucagent_formal_skill.md"
REPORT_DIR="$ROOT/reports/artifacts/03_pr74/ucagent_formal"
LOG_DIR="$REPORT_DIR/logs"
UCA_LOG="$LOG_DIR/ucagent_pr74_formal_skill.log"
MSG_FILE="$LOG_DIR/ucagent_pr74_formal_skill_messages.jsonl"
TOKEN_REPORT="$REPORT_DIR/token_usage.md"
UCA_TIMEOUT="${UCAGENT_PR74_FORMAL_TIMEOUT:-3600}"

mkdir -p "$LOG_DIR" "$WORKSPACE/reports"
cd "$ROOT"

if [[ -f "$ROOT/.ucagent_env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$ROOT/.ucagent_env"
  set +a
fi

write_blocked_report() {
  local reason="$1"
  cat > "$REPORT" <<EOF
# 03 PR74 UCAgent Formal Skill 运行

- 分类：\`INFRA_FAIL\`
- 原因：$reason
EOF
}

if [[ -z "${OPENAI_API_KEY:-}" || -z "${OPENAI_MODEL:-}" ]]; then
  write_blocked_report "缺少 OPENAI_API_KEY 或 OPENAI_MODEL"
  exit 1
fi

if ! conda run -n ucagent python -c "import ucagent" >/dev/null 2>&1; then
  write_blocked_report "conda environment 'ucagent' cannot import ucagent"
  exit 1
fi

rm -rf "$WORKSPACE/.ucagent" "$WORKSPACE/uc_test_report"
rm -f "$UCA_LOG" "$MSG_FILE" "$REPORT"
rm -rf "$REPORT_DIR/results"
mkdir -p "$WORKSPACE/reports"

LOOP_MSG="Run the real NutShell PR74 CacheIO idBits case with the reusable generic-formal skill. You must call ListSkill, read .ucagent/skills/generic-formal/SKILL.md, run RunSkillScript for pr74_pre_elab.yaml and pr74_fixed.yaml, read reports/03_pr74_ucagent_formal_skill.md, call SetSkillUsage, then Complete and Exit. The pre case is expected ERROR because the historical bug is an elaboration/interface failure. Do not run PR21 or 04."

set +e
timeout "$UCA_TIMEOUT" conda run -n ucagent ucagent "$WORKSPACE" "$DUT" \
  --config "$WORKSPACE/config.yaml" \
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
  write_blocked_report "UCAgent timed out after ${UCA_TIMEOUT}s"
  exit 1
fi

if [[ "$ucagent_rc" -ne 0 ]]; then
  if [[ -f "$UCA_LOG" ]] && grep -q "ToolComplete:" "$UCA_LOG" && grep -q "ToolExit:" "$UCA_LOG"; then
    echo "[32] UCAgent returned $ucagent_rc after ToolComplete/ToolExit; treating completed mission as success"
  else
    write_blocked_report "UCAgent exited with code $ucagent_rc"
    exit "$ucagent_rc"
  fi
fi

if [[ ! -f "$MSG_FILE" ]]; then
  write_blocked_report "missing UCAgent message log"
  exit 1
fi

if ! grep -q "RunSkillScript (call_" "$MSG_FILE"; then
  write_blocked_report "message log does not show RunSkillScript"
  exit 1
fi

if ! grep -q "SetSkillUsage (call_" "$MSG_FILE"; then
  write_blocked_report "message log does not show SetSkillUsage"
  exit 1
fi

if ! grep -q "pr74_pre_elab.yaml" "$MSG_FILE" || ! grep -q "pr74_fixed.yaml" "$MSG_FILE"; then
  write_blocked_report "RunSkillScript did not include both PR74 formal cases"
  exit 1
fi

if ! grep -q '`pr74_real_nutshell_cache_pre_elab` | ERROR | ERROR | OK' "$REPORT"; then
  write_blocked_report "PR74 pre case did not report expected ERROR/ERROR/OK"
  exit 1
fi

if ! grep -q '`pr74_real_nutshell_cache_fixed_formal` | PASS | PASS | OK' "$REPORT"; then
  write_blocked_report "PR74 fixed case did not report expected PASS/PASS/OK"
  exit 1
fi

cat >> "$REPORT" <<EOF

## UCAgent 证据

- UCAgent log：\`${UCA_LOG#${ROOT}/}\`
- Message log：\`${MSG_FILE#${ROOT}/}\`
- Token report：\`${TOKEN_REPORT#${ROOT}/}\`
- 结论：UCAgent 通过通用 \`generic-formal\` skill 捕获 PR74 pre 的接口/elaboration 失败，并验证 fixed formal property 通过。
EOF

cp "$REPORT" "$WORKSPACE/reports/03_pr74_ucagent_formal_skill.md"

echo "[32] wrote $REPORT"
echo "[32] wrote $TOKEN_REPORT"
