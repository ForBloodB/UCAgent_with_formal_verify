#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPORT="$ROOT/reports/directed_three_case_results.md"
LOG_DIR="$ROOT/reports/ucagent_logs"

mkdir -p "$LOG_DIR" "$(dirname "$REPORT")"

CASES=(
  "pr21_prefetch_mmio|ucagent_cases/pr21_prefetch_mmio|MMIO prefetch must not flush an existing normal request"
  "pr74_cache_io_idbits|ucagent_cases/pr74_cache_io_idbits|Nonzero OOO request ID must be preserved on response"
  "flush_outstanding_miss|ucagent_cases/flush_outstanding_miss|Flush during outstanding miss must not create an early CPU response"
)

{
  echo "# Directed Three Case Results"
  echo
  echo "- Date: $(date -Iseconds)"
  echo "- Scope: hand-written dynamic ground-truth tests for buggy/fixed variants."
  echo
  echo "| Case | Variant | Expected | Actual | Verdict | Log |"
  echo "| --- | --- | --- | --- | --- | --- |"
} > "$REPORT"

overall=0

run_target() {
  local name="$1"
  local rel_dir="$2"
  local variant="$3"
  local target="$4"
  local expected="$5"
  local log="$LOG_DIR/${name}_${variant}_directed.log"
  local log_rel="reports/ucagent_logs/${name}_${variant}_directed.log"
  local actual verdict

  if make -C "$ROOT/$rel_dir" "$target" >"$log" 2>&1; then
    actual="PASS"
  else
    actual="FAIL"
  fi

  if [ "$actual" = "$expected" ]; then
    verdict="OK"
  else
    verdict="UNEXPECTED"
    overall=1
  fi

  echo "| \`$name\` | \`$variant\` | $expected | $actual | $verdict | \`$log_rel\` |" >> "$REPORT"
  tail -n 12 "$log"
}

for entry in "${CASES[@]}"; do
  IFS="|" read -r name rel_dir _description <<< "$entry"
  echo "[directed] running $name buggy expected=FAIL"
  run_target "$name" "$rel_dir" "buggy" "test_buggy_directed" "FAIL"
  echo "[directed] running $name fixed expected=PASS"
  run_target "$name" "$rel_dir" "fixed" "test_fixed_directed" "PASS"
done

echo "[directed] wrote $REPORT"
exit "$overall"
