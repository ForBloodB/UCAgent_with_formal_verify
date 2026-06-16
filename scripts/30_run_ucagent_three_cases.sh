#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPORT="$ROOT/reports/ucagent_three_case_results.md"
COMPARISON="$ROOT/reports/formal_vs_ucagent_comparison.md"
LOG_DIR="$ROOT/reports/ucagent_logs"
ARTIFACT_DIR="$ROOT/reports/ucagent_artifacts"
BACKEND="${UCAGENT_BACKEND:-langchain}"
TIMEOUT_SEC="${UCAGENT_TIMEOUT:-1200}"
BUGGY_PROBE_TIMEOUT="${UCAGENT_BUGGY_TIMEOUT:-300}"
RUN_BUGGY_PROBE="${UCAGENT_RUN_BUGGY_PROBE:-1}"
POLL_SEC="${UCAGENT_POLL_SEC:-10}"

mkdir -p "$LOG_DIR" "$ARTIFACT_DIR" "$(dirname "$REPORT")"

if [ -f "$ROOT/.ucagent_env" ]; then
  set -a
  # shellcheck disable=SC1091
  . "$ROOT/.ucagent_env"
  set +a
fi

CASES=(
  "pr21_prefetch_mmio|ucagent_cases/pr21_prefetch_mmio|PR #21 MMIO prefetch|MMIO prefetch must not flush a pending normal request"
  "pr74_cache_io_idbits|ucagent_cases/pr74_cache_io_idbits|PR #74 CacheIO idBits|Nonzero out-of-order request ID must be preserved"
  "flush_outstanding_miss|ucagent_cases/flush_outstanding_miss|Flush outstanding miss|Flush before refill must not fabricate an early CPU response"
)

if [ -n "${UCAGENT_CASE_FILTER:-}" ]; then
  FILTERED_CASES=()
  for entry in "${CASES[@]}"; do
    IFS="|" read -r case_name _ <<< "$entry"
    if [ "$case_name" = "$UCAGENT_CASE_FILTER" ]; then
      FILTERED_CASES+=("$entry")
    fi
  done
  if [ "${#FILTERED_CASES[@]}" -eq 0 ]; then
    echo "[ucagent] unknown UCAGENT_CASE_FILTER: $UCAGENT_CASE_FILTER" >&2
    exit 2
  fi
  CASES=("${FILTERED_CASES[@]}")
fi

{
  echo "# UCAgent Three Case Results"
  echo
  echo "- Date: $(date -Iseconds)"
  echo "- Backend: \`$BACKEND\`"
  echo "- Timeout per fixed-generation UCAgent run: \`$TIMEOUT_SEC\` seconds"
  echo "- Timeout per buggy-probe UCAgent run: \`$BUGGY_PROBE_TIMEOUT\` seconds"
  echo "- Flow: seed UCAgent docs/API, generate tests from \`CaseFixed\`, replay the same \`unity_test/tests\` against fixed and buggy RTL."
  echo "- UCAgent stage policy: seed a clean \`.ucagent/ucagent_info.json\` so stages 0-21 are treated as completed and stages 24-26 as skipped; run test implementation/comprehensive verification/summary stages."
  echo "- Supervisor policy: if UCAgent writes executable tests but the official stage loop does not exit, stop the process and use independent Toffee/pytest replay as the acceptance oracle."
  echo
} > "$REPORT"

missing_env=0
for key in OPENAI_API_BASE OPENAI_API_KEY OPENAI_MODEL; do
  if [ -z "${!key:-}" ]; then
    missing_env=1
  fi
done

write_comparison() {
  local rows="$1"
  {
    echo "# Formal vs UCAgent Comparison"
    echo
    echo "- Date: $(date -Iseconds)"
    echo "- Formal report: \`reports/formal_batch/three_case_formal.md\`"
    echo "- Directed dynamic report: \`reports/directed_three_case_results.md\`"
    echo "- UCAgent report: \`reports/ucagent_three_case_results.md\`"
    echo
    echo "| Case | Formal result | Directed dynamic | UCAgent result | Complementary reading |"
    echo "| --- | --- | --- | --- | --- |"
    printf "%s\n" "$rows"
    echo
    echo "## Conclusion"
    echo
    echo "Formal verification gives short symbolic counterexamples for the target bug windows. UCAgent is complementary when it converts those scenarios into maintainable Toffee/pytest regressions; any \`MISSED\` or \`INFRA_FAIL\` entry is kept explicit rather than treated as evidence that the design is clean."
  } > "$COMPARISON"
}

if [ "$missing_env" -ne 0 ]; then
  {
    echo "## Blocker"
    echo
    echo "UCAgent was not run because one or more required variables are missing:"
    echo
    echo "- \`OPENAI_API_BASE\`"
    echo "- \`OPENAI_API_KEY\`"
    echo "- \`OPENAI_MODEL\`"
    echo
    echo "Fill \`.ucagent_env\`, then rerun:"
    echo
    echo "\`\`\`bash"
    echo "bash scripts/30_run_ucagent_three_cases.sh"
    echo "\`\`\`"
  } >> "$REPORT"
  write_comparison "| all three cases | See formal report | See directed report | BLOCKED_NO_LLM_ENV | LLM credentials were not available, so UCAgent could not be evaluated. |"
  echo "[ucagent] blocked: missing OPENAI_API_BASE/OPENAI_API_KEY/OPENAI_MODEL"
  exit 2
fi

if command -v conda >/dev/null 2>&1 && conda env list | awk '{print $1}' | grep -qx "ucagent"; then
  UCAGENT_CMD=(conda run --no-capture-output -n ucagent ucagent)
  PYTEST_CMD=(conda run --no-capture-output -n ucagent pytest)
  PYTHON_CMD=(conda run --no-capture-output -n ucagent python)
elif command -v ucagent >/dev/null 2>&1; then
  UCAGENT_CMD=(ucagent)
  PYTEST_CMD=(pytest)
  PYTHON_CMD=(python3)
else
  {
    echo "## Blocker"
    echo
    echo "UCAgent command was not found. The script first looks for conda env \`ucagent\`, then for \`ucagent\` in PATH."
  } >> "$REPORT"
  write_comparison "| all three cases | See formal report | See directed report | INFRA_FAIL | UCAgent executable was not available. |"
  echo "[ucagent] UCAgent not found"
  exit 1
fi

run_smoke() {
  local smoke_log="$LOG_DIR/toolchain_smoke.log"
  {
    echo "[smoke] picker"
    picker --version
    echo
    echo "[smoke] verilator"
    verilator --version
    echo
    echo "[smoke] ucagent python imports"
    "${PYTHON_CMD[@]}" -c 'import ucagent, toffee, toffee_test; print("imports ok")'
  } > "$smoke_log" 2>&1
}

archive_phase() {
  local rel_dir="$1"
  local dest="$2"
  local abs_dir="$ROOT/$rel_dir"
  rm -rf "$dest"
  mkdir -p "$dest"
  for item in unity_test uc_test_report AGENTS.md log; do
    if [ -e "$abs_dir/$item" ]; then
      cp -a "$abs_dir/$item" "$dest/"
    fi
  done
  if [ -f "$abs_dir/.ucagent/ucagent_info.json" ]; then
    mkdir -p "$dest/.ucagent"
    cp -a "$abs_dir/.ucagent/ucagent_info.json" "$dest/.ucagent/"
  fi
}

generated_test_count() {
  local rel_dir="$1"
  local test_dir="$ROOT/$rel_dir/unity_test/tests"
  if [ ! -d "$test_dir" ]; then
    echo 0
    return
  fi
  find "$test_dir" -maxdepth 1 -type f -name 'test*.py' | wc -l
}

generation_templates_implemented() {
  local rel_dir="$1"
  local test_dir="$ROOT/$rel_dir/unity_test/tests"
  if [ ! -d "$test_dir" ]; then
    return 1
  fi
  if ! find "$test_dir" -maxdepth 1 -type f -name 'test*.py' | grep -q .; then
    return 1
  fi
  if grep -R "UCAgent should implement this template" "$test_dir"/test*.py >/dev/null 2>&1; then
    return 1
  fi
  return 0
}

generation_fixed_replay_pass() {
  local name="$1"
  local rel_dir="$2"
  local abs_dir="$ROOT/$rel_dir"
  local log="$LOG_DIR/${name}_fixed_generation_supervisor_replay.log"

  rm -rf "$abs_dir/uc_test_report"
  if make -C "$abs_dir" PYTEST="${PYTEST_CMD[*]}" test_ucagent_official > "$log" 2>&1; then
    return 0
  fi
  return 1
}

stop_process_group() {
  local pid="$1"
  kill -TERM "-$pid" >/dev/null 2>&1 || kill -TERM "$pid" >/dev/null 2>&1 || true
  sleep 2
  kill -KILL "-$pid" >/dev/null 2>&1 || kill -KILL "$pid" >/dev/null 2>&1 || true
}

generation_ok() {
  case "$1" in
    PASS|PASS_EARLY_STOP|PASS_TIMEOUT_WITH_TESTS)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

run_ucagent_generate_fixed() {
  local name="$1"
  local rel_dir="$2"
  local prompt_file="$ROOT/$rel_dir/prompts/ucagent_prompt.md"
  local log="$LOG_DIR/${name}_fixed_generate_ucagent.stdout.log"
  local agent_log="$LOG_DIR/${name}_fixed_generate_ucagent.internal.log"
  local msg_log="$LOG_DIR/${name}_fixed_generate_ucagent.messages.log"
  local loop_msg

  loop_msg="$(cat "$prompt_file")

Additional batch-run constraints:
- Follow the official UCAgent workflow and finish by calling the completion/exit tool.
- Do not edit the DUT package or RTL.
- Put executable pytest cases under unity_test/tests.
- The tests must be usable as a regression suite for this same CaseFixed API."

  echo "[ucagent] $name: generating tests from CaseFixed"
  setsid timeout "$TIMEOUT_SEC" "${UCAGENT_CMD[@]}" "$ROOT/$rel_dir" CaseFixed \
      --backend="$BACKEND" \
      --stream-output \
      --loop \
      --exit-on-completion \
      --log \
      --log-file "$agent_log" \
      --msg-file "$msg_log" \
      --loop-msg "$loop_msg" > "$log" 2>&1 &
  local run_pid=$!

  while kill -0 "$run_pid" >/dev/null 2>&1; do
    sleep "$POLL_SEC"
    if generation_templates_implemented "$rel_dir"; then
      if generation_fixed_replay_pass "$name" "$rel_dir"; then
        echo "[ucagent] $name: generated tests pass fixed replay; stopping UCAgent supervisor process." >> "$log"
        stop_process_group "$run_pid"
        wait "$run_pid" >/dev/null 2>&1 || true
        echo "PASS_EARLY_STOP"
        return
      fi
    fi
  done

  if wait "$run_pid"; then
    echo "PASS"
  else
    if generation_templates_implemented "$rel_dir" && generation_fixed_replay_pass "$name" "$rel_dir"; then
      echo "PASS_TIMEOUT_WITH_TESTS"
    else
      echo "FAIL"
    fi
  fi
}

run_ucagent_buggy_probe() {
  local name="$1"
  local rel_dir="$2"
  local prompt_file="$ROOT/$rel_dir/prompts/ucagent_prompt.md"
  local log="$LOG_DIR/${name}_buggy_probe_ucagent.stdout.log"
  local agent_log="$LOG_DIR/${name}_buggy_probe_ucagent.internal.log"
  local msg_log="$LOG_DIR/${name}_buggy_probe_ucagent.messages.log"
  local loop_msg

  if [ "$RUN_BUGGY_PROBE" != "1" ]; then
    echo "SKIPPED"
    return
  fi

  loop_msg="$(cat "$prompt_file")

Additional bounded bug-probe constraints:
- This run targets CaseBuggy and is intentionally time-bounded.
- Try to produce a failing test or bug analysis if the RTL violates the oracle.
- If the time budget is insufficient, exit cleanly rather than modifying RTL."

  echo "[ucagent] $name: bounded CaseBuggy probe"
  if timeout "$BUGGY_PROBE_TIMEOUT" "${UCAGENT_CMD[@]}" "$ROOT/$rel_dir" CaseBuggy \
      --backend="$BACKEND" \
      --stream-output \
      --loop \
      --exit-on-completion \
      --log \
      --log-file "$agent_log" \
      --msg-file "$msg_log" \
      --loop-msg "$loop_msg" > "$log" 2>&1; then
    echo "PASS"
  else
    echo "FAIL"
  fi
}

run_replay() {
  local name="$1"
  local rel_dir="$2"
  local variant="$3"
  local log="$LOG_DIR/${name}_${variant}_ucagent_replay.log"
  local abs_dir="$ROOT/$rel_dir"
  rm -rf "$abs_dir/uc_test_report"
  if make -C "$abs_dir" PYTEST="${PYTEST_CMD[*]}" test_ucagent_official > "$log" 2>&1; then
    echo "PASS"
  else
    echo "FAIL"
  fi
}

{
  echo "## Toolchain Smoke"
  echo
} >> "$REPORT"

if run_smoke; then
  echo "- Status: PASS" >> "$REPORT"
else
  echo "- Status: FAIL" >> "$REPORT"
  echo "- Log: \`reports/ucagent_logs/toolchain_smoke.log\`" >> "$REPORT"
  write_comparison "| all three cases | See formal report | See directed report | INFRA_FAIL | Toolchain smoke failed before UCAgent execution. |"
  echo "[ucagent] toolchain smoke failed; see reports/ucagent_logs/toolchain_smoke.log"
  exit 1
fi
echo "- Log: \`reports/ucagent_logs/toolchain_smoke.log\`" >> "$REPORT"

echo "[ucagent] running directed ground-truth tests first"
if ! "$ROOT/scripts/31_run_directed_three_cases.sh"; then
  {
    echo
    echo "## Directed Precheck"
    echo
    echo "- Status: FAIL"
    echo "- Log/report: \`reports/directed_three_case_results.md\`"
  } >> "$REPORT"
  write_comparison "| all three cases | See formal report | Directed precheck failed | INFRA_FAIL | UCAgent was not run because the ground-truth dynamic matrix was not stable. |"
  exit 1
fi

{
  echo
  echo "## Case Matrix"
  echo
  echo "| Case | UCAgent generation | Generated tests | Fixed replay | Buggy replay | Buggy probe | Classification | Artifacts |"
  echo "| --- | --- | ---: | --- | --- | --- | --- | --- |"
} >> "$REPORT"

overall=0
comparison_rows=""

for entry in "${CASES[@]}"; do
  IFS="|" read -r name rel_dir title reading <<< "$entry"
  abs_dir="$ROOT/$rel_dir"
  case_artifacts="$ARTIFACT_DIR/$name"
  rm -rf "$case_artifacts"
  mkdir -p "$case_artifacts"

  echo "[ucagent] preparing $name"
  make -C "$abs_dir" clean >/dev/null
  make -C "$abs_dir" gen_dut_fixed > "$LOG_DIR/${name}_gen_fixed.log" 2>&1
  bash "$ROOT/scripts/32_seed_ucagent_case.sh" "$abs_dir" "$name" CaseFixed

  generation_status="$(run_ucagent_generate_fixed "$name" "$rel_dir" | tail -n 1)"
  test_count="$(generated_test_count "$rel_dir")"
  archive_phase "$rel_dir" "$case_artifacts/fixed_generation"

  if generation_ok "$generation_status" && [ "$test_count" -gt 0 ]; then
    fixed_replay="$(run_replay "$name" "$rel_dir" "fixed" | tail -n 1)"
    archive_phase "$rel_dir" "$case_artifacts/fixed_replay"

    make -C "$abs_dir" gen_dut_buggy_as_fixed > "$LOG_DIR/${name}_gen_buggy_as_fixed.log" 2>&1
    buggy_replay="$(run_replay "$name" "$rel_dir" "buggy" | tail -n 1)"
    archive_phase "$rel_dir" "$case_artifacts/buggy_replay"
  else
    fixed_replay="SKIPPED"
    buggy_replay="SKIPPED"
  fi

  make -C "$abs_dir" clean_ucagent >/dev/null
  make -C "$abs_dir" gen_dut_buggy > "$LOG_DIR/${name}_gen_buggy.log" 2>&1
  bash "$ROOT/scripts/32_seed_ucagent_case.sh" "$abs_dir" "$name" CaseBuggy
  buggy_probe="$(run_ucagent_buggy_probe "$name" "$rel_dir" | tail -n 1)"
  archive_phase "$rel_dir" "$case_artifacts/buggy_probe"

  if ! generation_ok "$generation_status"; then
    classification="INFRA_FAIL"
  elif [ "$test_count" -eq 0 ]; then
    classification="MISSED"
  elif [ "$fixed_replay" = "PASS" ] && [ "$buggy_replay" = "FAIL" ]; then
    classification="DETECTED"
  elif [ "$fixed_replay" = "FAIL" ]; then
    if grep -Eiq "ImportError|ModuleNotFoundError|PermissionError|UsageError|file or directory not found|No module named" "$LOG_DIR/${name}_fixed_ucagent_replay.log"; then
      classification="INFRA_FAIL"
    else
      classification="FALSE_POSITIVE"
    fi
  elif [ "$fixed_replay" = "PASS" ] && [ "$buggy_replay" = "PASS" ]; then
    classification="MISSED"
  else
    classification="INFRA_FAIL"
  fi

  if [ "$classification" != "DETECTED" ]; then
    overall=1
  fi

  artifact_rel="reports/ucagent_artifacts/$name"
  echo "| \`$name\` | $generation_status | $test_count | $fixed_replay | $buggy_replay | $buggy_probe | $classification | \`$artifact_rel\` |" >> "$REPORT"
  comparison_rows+=$'| '"$title"$' | Buggy FAIL / fixed PASS | Directed test detects buggy | '"$classification"$' | '"$reading"$'; UCAgent result is from generated tests replayed against both RTL variants. |\n'
done

write_comparison "${comparison_rows%$'\n'}"

echo "[ucagent] wrote $REPORT"
echo "[ucagent] wrote $COMPARISON"
exit "$overall"
