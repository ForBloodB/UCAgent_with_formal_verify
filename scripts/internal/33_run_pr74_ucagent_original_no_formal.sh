#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORKSPACE="$ROOT/tests/ucagent_workspaces/03_pr74_cache_io_idbits"
DUT="Pr74CacheIOIdBits"
REPORT="$ROOT/reports/03_pr74_ucagent_original_no_formal.md"
REPORT_DIR="$ROOT/reports/artifacts/03_pr74/original_no_formal"
LOG_DIR="$REPORT_DIR/logs"
UCA_LOG="$LOG_DIR/ucagent_pr74_original_no_formal.log"
MSG_FILE="$LOG_DIR/ucagent_pr74_original_no_formal_messages.jsonl"
TOKEN_REPORT="$REPORT_DIR/token_usage.md"
UCA_TIMEOUT="${UCAGENT_PR74_ORIGINAL_TIMEOUT:-1800}"

mkdir -p "$LOG_DIR" "$WORKSPACE/reports"
cd "$ROOT"

if [[ -f "$ROOT/.ucagent_env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$ROOT/.ucagent_env"
  set +a
fi

write_report() {
  local classification="$1"
  local body="$2"
  cat > "$REPORT" <<EOF
# 03 PR74 原始 UCAgent 无 Formal Skill 对照

- 分类：\`${classification}\`
- UCAgent log：\`${UCA_LOG#${ROOT}/}\`
- Message log：\`${MSG_FILE#${ROOT}/}\`
- Token report：\`${TOKEN_REPORT#${ROOT}/}\`

$body
EOF
}

if [[ -z "${OPENAI_API_KEY:-}" || -z "${OPENAI_MODEL:-}" ]]; then
  write_report "BLOCKED_NO_LLM_ENV" "缺少 OPENAI_API_KEY 或 OPENAI_MODEL。"
  exit 1
fi

rm -rf "$WORKSPACE/.ucagent" "$WORKSPACE/uc_test_report"
rm -f "$UCA_LOG" "$MSG_FILE" "$REPORT"
mkdir -p "$WORKSPACE/reports"
if [[ -f "$ROOT/reports/03_pr74_ucagent_formal_skill.md" ]]; then
  cp "$ROOT/reports/03_pr74_ucagent_formal_skill.md" "$WORKSPACE/reports/03_pr74_ucagent_formal_skill.md"
fi

LOOP_MSG="Run the original UCAgent baseline for PR74 without using any formal verification skill. Read README.md, Pr74CacheIOIdBits/README.md, reports/03_pr74_ucagent_formal_skill.md if present, and config.yaml as a reference for the skill-enabled path. Do not call ListSkill, RunSkillScript, or SetSkillUsage. Conclude honestly whether this no-formal flow independently reproduces the bug. Because this workspace has no Picker/Toffee dynamic DUT, classify it as STATIC_REVIEW_ONLY_NO_DYNAMIC_REPRO unless an executable UCAgent test is actually run."

set +e
timeout "$UCA_TIMEOUT" conda run -n ucagent ucagent "$WORKSPACE" "$DUT" \
  --config "$WORKSPACE/config_original.yaml" \
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
  write_report "INFRA_FAIL" "UCAgent timed out after ${UCA_TIMEOUT}s。"
  exit 1
fi

if [[ "$ucagent_rc" -ne 0 ]]; then
  if [[ -f "$UCA_LOG" ]] && grep -q "ToolComplete:" "$UCA_LOG" && grep -q "ToolExit:" "$UCA_LOG"; then
    echo "[33] UCAgent returned $ucagent_rc after ToolComplete/ToolExit; treating completed mission as success"
  else
    write_report "INFRA_FAIL" "UCAgent exited with code $ucagent_rc。"
    exit "$ucagent_rc"
  fi
fi

if [[ -f "$MSG_FILE" ]] && grep -q "RunSkillScript (call_" "$MSG_FILE"; then
  write_report "UNEXPECTED_FORMAL_SKILL_USED" "no-formal 对照中出现了 RunSkillScript。"
  exit 1
fi

write_report "STATIC_REVIEW_ONLY_NO_DYNAMIC_REPRO" "本轮使用真实 API 调用了原始 UCAgent 流程，但没有 formal skill，也没有 03 的 Picker/Toffee 动态 DUT。因此 agent 能阅读报告和源码并解释 PR74 接口/elaboration 现象，不能独立生成新的 elaboration/formal 结果。"
cp "$REPORT" "$WORKSPACE/reports/03_pr74_ucagent_original_no_formal.md"

echo "[33] wrote $REPORT"
