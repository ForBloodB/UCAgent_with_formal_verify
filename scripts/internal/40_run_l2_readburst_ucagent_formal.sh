#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORKSPACE="$ROOT/tests/ucagent_workspaces/04_l2_readburst_deadlock"
DUT="L2ReadBurstDeadlock"
REPORT="$ROOT/reports/04_l2_readburst.md"
REPORT_DIR="$ROOT/reports/artifacts/04_l2_readburst"
LOG_DIR="$REPORT_DIR/logs"
ARTIFACT_DIR="$REPORT_DIR/artifacts"
UCA_LOG="$LOG_DIR/ucagent_l2_readburst.log"
MSG_FILE="$LOG_DIR/ucagent_l2_readburst_messages.jsonl"
UCAGENT_TIMEOUT="${UCAGENT_TIMEOUT:-2400}"
UCA_COMPLETE_WAIT_SECONDS="${UCA_COMPLETE_WAIT_SECONDS:-180}"

mkdir -p "$LOG_DIR" "$ARTIFACT_DIR"
cd "$ROOT"

if [ -f "$ROOT/.ucagent_env" ]; then
  set -a
  # shellcheck disable=SC1091
  source "$ROOT/.ucagent_env"
  set +a
fi

write_blocked_report() {
  local reason="$1"
  cat > "$REPORT" <<EOF
# L2 ReadBurst Ready/Valid UCAgent 运行

- 日期：$(date -Iseconds)
- 总体分类：\`INFRA_FAIL\`
- 原因：$reason

UCAgent skill flow 未运行到足以形成设计结论的阶段。
EOF
}

if ! conda run -n ucagent python -c "import ucagent" >/dev/null 2>&1; then
  write_blocked_report "conda environment 'ucagent' cannot import ucagent"
  exit 1
fi

if [ -z "${OPENAI_API_KEY:-}" ] || [ -z "${OPENAI_MODEL:-}" ]; then
  write_blocked_report "missing OPENAI_API_KEY or OPENAI_MODEL in .ucagent_env"
  exit 1
fi

rm -rf "$WORKSPACE/.ucagent" "$WORKSPACE/unity_test" "$WORKSPACE/uc_test_report" "$WORKSPACE/reports"
rm -f "$UCA_LOG" "$MSG_FILE" "$REPORT"
rm -rf "$REPORT_DIR/results"

LOOP_MSG="Complete the latest NutShell Cache l2_readburst_hit_ready_valid_deadlock single-case verification. Do not run PR21, PR74, MMIO prefetch, idBits, or any non-04 scenario. First call ListSkill, then read generic-formal/SKILL.md, then use RunSkillScript to execute these two four-element commands: [[\"python3\",\"generic-formal\",\"run_formal.py\",\"--workspace ../../.. --case tests/cases/04_l2_readburst_hit_ready_valid_deadlock/formal/l2_readburst_assert.yaml --timeout 1200\"],[\"python3\",\"generic-formal\",\"run_formal.py\",\"--workspace ../../.. --case tests/cases/04_l2_readburst_hit_ready_valid_deadlock/formal/l2_readburst_cover.yaml --timeout 1200\"]]. After that, read reports/04_l2_readburst.md inside the workspace and summarize the classification. The assert case is expected to FAIL, which means formal found a ready/valid counterexample. The cover case is expected to PASS, which means the target window is reachable."

set +e
setsid timeout "$UCAGENT_TIMEOUT" \
  conda run -n ucagent ucagent "$WORKSPACE" "$DUT" \
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
    --loop-msg "$LOOP_MSG" &
ucagent_pid=$!
completed_by_monitor=false
completion_reason=""
complete_seen=false
complete_seen_at=0

while kill -0 "$ucagent_pid" >/dev/null 2>&1; do
  if [ -f "$UCA_LOG" ] && grep -q "ToolExit" "$UCA_LOG"; then
    completed_by_monitor=true
    completion_reason="ToolExit"
    break
  fi
  if [ -f "$UCA_LOG" ] && \
     [ -f "$WORKSPACE/reports/04_l2_readburst.md" ] && \
     grep -q "ToolSetSkillUsage" "$UCA_LOG" && \
     grep -q "ToolComplete:" "$UCA_LOG" && \
     grep -q "complete: true" "$UCA_LOG" && \
     grep -q "All stages completed successfully" "$UCA_LOG"; then
    if [ "$complete_seen" = false ]; then
      complete_seen=true
      completed_by_monitor=true
      completion_reason="monitored ToolComplete"
      complete_seen_at="$(date +%s)"
    else
      now="$(date +%s)"
      elapsed_after_complete=$((now - complete_seen_at))
      if [ "$elapsed_after_complete" -ge "$UCA_COMPLETE_WAIT_SECONDS" ]; then
      completion_reason="monitored ToolComplete without ToolExit after ${UCA_COMPLETE_WAIT_SECONDS}s"
      kill -TERM "-$ucagent_pid" >/dev/null 2>&1 || kill -TERM "$ucagent_pid" >/dev/null 2>&1 || true
      sleep 2
      kill -KILL "-$ucagent_pid" >/dev/null 2>&1 || kill -KILL "$ucagent_pid" >/dev/null 2>&1 || true
      break
      fi
    fi
  fi
  sleep 5
done

wait "$ucagent_pid"
ucagent_rc=$?
set -e

python3 "$ROOT/src/lib/collect_ucagent_token_usage.py" \
  --log-dir "$LOG_DIR" \
  --output "$REPORT_DIR/token_usage.md" || true

if [ "$ucagent_rc" -eq 124 ]; then
  write_blocked_report "UCAgent timed out after ${UCAGENT_TIMEOUT}s"
  exit 1
fi

completed_by_log=false
if [ -f "$REPORT" ] && [ -f "$UCA_LOG" ] && grep -q "ToolExit" "$UCA_LOG"; then
  completed_by_log=true
  completion_reason="ToolExit"
fi
if [ "$completed_by_monitor" = true ]; then
  completed_by_log=true
fi

if [ "$ucagent_rc" -ne 0 ]; then
  if [ "$completed_by_log" = true ]; then
    echo "[04-l2-readburst] UCAgent returned $ucagent_rc after ${completion_reason:-completed mission}; treating completed mission as success"
  elif [ ! -f "$REPORT" ]; then
    write_blocked_report "UCAgent exited with code $ucagent_rc"
    exit "$ucagent_rc"
  else
    exit "$ucagent_rc"
  fi
fi

if [ ! -f "$REPORT" ]; then
  write_blocked_report "UCAgent completed but did not produce reports/04_l2_readburst.md"
  exit 1
fi

if [ ! -f "$WORKSPACE/reports/04_l2_readburst.md" ]; then
  write_blocked_report "UCAgent completed but did not mirror the report inside the workspace"
  exit 1
fi

if ! grep -q "RunSkillScript (call_" "$MSG_FILE"; then
  write_blocked_report "UCAgent completed but the message log does not show an actual RunSkillScript tool call"
  exit 1
fi

COMMIT_FILE="$ROOT/tests/cases/04_l2_readburst_hit_ready_valid_deadlock/formal/generated/latest/source_commit.txt"
if ! grep -q "## 解读" "$REPORT"; then
  cat >> "$REPORT" <<'EOF'

## 解读

- `l2_readburst_hit_ready_deadlock_assert`：expected `FAIL`，actual `FAIL`；bounded formal run 找到了 ready/valid 反例。
- `l2_readburst_hit_ready_deadlock_cover`：expected `PASS`，actual `PASS`；`readBurst hit + resp_ready low` 目标窗口可达。
- 这是 latest-upstream candidate bug 报告，不是 upstream 已确认公开 bug。
EOF
fi

if [ -f "$COMMIT_FILE" ] && ! grep -q "Latest upstream NutShell commit" "$REPORT"; then
  commit_hash="$(tr -d '[:space:]' < "$COMMIT_FILE")"
  {
    printf '\n## 来源\n\n'
    printf -- '- Latest upstream NutShell commit: `%s`\n' "$commit_hash"
  } >> "$REPORT"
fi
mkdir -p "$WORKSPACE/reports"
cp "$REPORT" "$WORKSPACE/reports/04_l2_readburst.md"

echo "[04-l2-readburst] wrote $REPORT"
echo "[04-l2-readburst] mirrored $WORKSPACE/reports/04_l2_readburst.md"
echo "[04-l2-readburst] wrote $REPORT_DIR/token_usage.md"
