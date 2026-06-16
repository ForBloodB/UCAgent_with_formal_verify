#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPORT="$ROOT/reports/formal_batch/three_case_formal.md"
LOG_DIR="$ROOT/reports/formal_batch/logs"

mkdir -p "$LOG_DIR"
cd "$ROOT"

if ! command -v sby >/dev/null 2>&1; then
  echo "[formal] error: sby not found. Use scripts/25_docker_run_three_case_formal.sh or install SymbiYosys." >&2
  exit 127
fi

CASES=(
  "pr21_prefetch_mmio_buggy|formal/historical/nutshell_pr21_prefetch_mmio_buggy.sby|FAIL|PR #21 old behavior: MMIO prefetch flushes a normal L2/cache pipeline request"
  "pr21_prefetch_mmio_fixed|formal/historical/nutshell_pr21_prefetch_mmio_fixed.sby|PASS|PR #21 fixed behavior: MMIO prefetch is suppressed and does not flush the normal request"
  "pr74_cache_io_idbits_buggy|formal/historical/nutshell_pr74_cache_io_idbits_buggy.sby|FAIL|PR #74 old behavior: CacheIO drops the nonzero OOO request id"
  "pr74_cache_io_idbits_fixed|formal/historical/nutshell_pr74_cache_io_idbits_fixed.sby|PASS|PR #74 fixed behavior: CacheIO preserves the request id"
  "flush_outstanding_miss_buggy|formal/historical/flush_outstanding_miss_buggy.sby|FAIL|Injected narrow timing bug: flush fabricates an early CPU response while a miss is outstanding"
  "flush_outstanding_miss_fixed|formal/historical/flush_outstanding_miss_fixed.sby|PASS|Fixed behavior: CPU response is only allowed when the refill response arrives"
)

{
  echo "# Three Case Formal Report"
  echo
  echo "- Date: $(date -Iseconds)"
  echo "- Scope: compact formal litmus tests for two public NutShell fixes plus one injected formal-advantage timing case."
  echo
  echo "| Case | Source | Expected | Actual | Verdict | Log |"
  echo "| --- | --- | --- | --- | --- | --- |"
} > "$REPORT"

overall=0
for entry in "${CASES[@]}"; do
  IFS="|" read -r name sby_file expected description <<< "$entry"
  log="$LOG_DIR/${name}.log"
  log_rel="reports/formal_batch/logs/${name}.log"

  echo "[formal] running $name expected=$expected"
  if sby -f "$sby_file" >"$log" 2>&1; then
    actual="PASS"
  elif grep -Eq "DONE \\(FAIL|BMC failed|Assert failed|Status: failed" "$log"; then
    actual="FAIL"
  elif grep -q "DONE (TIMEOUT" "$log"; then
    actual="TIMEOUT"
  else
    actual="ERROR"
  fi

  if [ "$actual" = "$expected" ]; then
    verdict="OK"
  else
    verdict="UNEXPECTED"
    overall=1
  fi

  echo "| \`$name\` | $description | $expected | $actual | $verdict | \`$log_rel\` |" >> "$REPORT"
  tail -n 20 "$log"
done

{
  echo
  echo "## Sources"
  echo
  echo "- PR #21: https://github.com/OSCPU/NutShell/pull/21"
  echo "- PR #21 merge commit: https://github.com/OSCPU/NutShell/commit/a3663f25183d6cbf89a088e3e8a365e2e6270366"
  echo "- PR #74: https://github.com/OSCPU/NutShell/pull/74"
  echo "- PR #74 fix commit: https://github.com/OSCPU/NutShell/commit/287c5e02490aca73055211bd04908917d71deaf7"
  echo
  echo "## Interpretation"
  echo
  echo "- Buggy variants are expected to FAIL; this means the property catches the intended bug condition."
  echo "- Fixed variants are expected to PASS; this means the same property does not flag the repaired behavior."
  echo "- The flush outstanding miss case is intentionally artificial and demonstrates a narrow timing window that formal can target directly."
} >> "$REPORT"

echo "[formal] wrote $REPORT"
exit "$overall"
