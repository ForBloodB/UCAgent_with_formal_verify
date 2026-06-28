#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORKSPACE="$ROOT/tests/ucagent_workspaces/02_pr21_mmio_prefetch"
DUT="Pr21MmioPrefetch"
REPORT="$ROOT/reports/02_pr21_ucagent_formal_skill.md"
REPORT_DIR="$ROOT/reports/artifacts/02_pr21/ucagent_formal"
LOG_DIR="$REPORT_DIR/logs"
UCA_LOG="$LOG_DIR/ucagent_pr21_formal_skill.log"
MSG_FILE="$LOG_DIR/ucagent_pr21_formal_skill_messages.jsonl"
TOKEN_REPORT="$REPORT_DIR/token_usage.md"
UCA_TIMEOUT="${UCAGENT_PR21_FORMAL_TIMEOUT:-3600}"

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
# 02 PR21 UCAgent Formal Skill 运行

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

LOOP_MSG="Run the real NutShell PR21 MMIO prefetch case with the reusable generic-formal skill. You must call ListSkill, read .ucagent/skills/generic-formal/SKILL.md, run RunSkillScript for pr21_pre.yaml and pr21_fixed.yaml, read reports/02_pr21_ucagent_formal_skill.md, call SetSkillUsage, then Complete and Exit. Do not run PR74 or 04."

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
    echo "[22] UCAgent returned $ucagent_rc after ToolComplete/ToolExit; treating completed mission as success"
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

if ! grep -q "pr21_pre.yaml" "$MSG_FILE" || ! grep -q "pr21_fixed.yaml" "$MSG_FILE"; then
  write_blocked_report "RunSkillScript did not include both PR21 formal cases"
  exit 1
fi

if ! grep -q '`pr21_real_nutshell_cache_pre` | FAIL | FAIL | OK' "$REPORT"; then
  write_blocked_report "PR21 pre case did not report expected FAIL/FAIL/OK"
  exit 1
fi

if ! grep -q '`pr21_real_nutshell_cache_fixed` | PASS | PASS | OK' "$REPORT"; then
  write_blocked_report "PR21 fixed case did not report expected PASS/PASS/OK"
  exit 1
fi

cat >> "$REPORT" <<EOF

## UCAgent 证据

- UCAgent log：\`${UCA_LOG#${ROOT}/}\`
- Message log：\`${MSG_FILE#${ROOT}/}\`
- Token report：\`${TOKEN_REPORT#${ROOT}/}\`
- 结论：UCAgent 通过通用 \`generic-formal\` skill 对真实 NutShell PR21 pre/fixed 版本完成了同一套 formal 闭环。
EOF

cp "$REPORT" "$WORKSPACE/reports/02_pr21_ucagent_formal_skill.md"

echo "[22] wrote $REPORT"
echo "[22] wrote $TOKEN_REPORT"
