#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPORT="$ROOT/reports/pr21_real_nutshell_cache_formal.md"
LOG_DIR="$ROOT/reports/formal_batch/logs"

mkdir -p "$LOG_DIR" "$(dirname "$REPORT")"
cd "$ROOT"

if ! command -v sby >/dev/null 2>&1; then
  echo "[pr21-real] error: sby not found. Generate RTL with scripts/40 first, then run inside a SymbiYosys environment." >&2
  exit 127
fi

if [ ! -f "$ROOT/formal/nutshell_pr21_real/generated/pre/Pr21CacheFormalDut.v" ] ||
   [ ! -f "$ROOT/formal/nutshell_pr21_real/generated/fixed/Pr21CacheFormalDut.v" ]; then
  bash "$ROOT/scripts/40_prepare_pr21_real_nutshell_cache.sh" all
else
  echo "[pr21-real] using existing generated real NutShell Cache RTL"
fi

CASES=(
  "pr21_real_nutshell_cache_pre|formal/nutshell_pr21_real/nutshell_pr21_real_cache_pre.sby|FAIL|NutShell parent bd425dee before PR #21"
  "pr21_real_nutshell_cache_fixed|formal/nutshell_pr21_real/nutshell_pr21_real_cache_fixed.sby|PASS|NutShell PR branch f0d7c494 with PR #21 fix"
)

{
  echo "# PR21 Real NutShell Cache Formal Report"
  echo
  echo "- Date: $(date -Iseconds)"
  echo "- Scope: real NutShell Cache generated from PR #21 parent/fixed commits, with a formal wrapper probing the real s2->s3 cache pipeline."
  echo
  echo "| Case | Source | Expected | Actual | Verdict | Log |"
  echo "| --- | --- | --- | --- | --- | --- |"
} > "$REPORT"

overall=0
for entry in "${CASES[@]}"; do
  IFS="|" read -r name sby_file expected description <<< "$entry"
  log="$LOG_DIR/${name}.log"
  log_rel="reports/formal_batch/logs/${name}.log"

  echo "[pr21-real] running $name expected=$expected"
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

cat >> "$REPORT" <<'EOF'

## Sources

- PR #21 merge commit: https://github.com/OSCPU/NutShell/commit/a3663f25183d6cbf89a088e3e8a365e2e6270366
- Pre-PR parent: https://github.com/OSCPU/NutShell/commit/bd425deedff4e896fca59895b34d778f2c8724d9
- Fixed PR head: https://github.com/OSCPU/NutShell/commit/f0d7c49411197047dc8464addfacc0fcba5b9e45

## Interpretation

- The DUT is generated from the real NutShell `nutcore.Cache`, not from the earlier compact litmus.
- The wrapper only drives public cache IO and observes internal s2/s3 signals through Chisel `BoringUtils` probes inserted by `scripts/40_prepare_pr21_real_nutshell_cache.sh`.
- Expected split: pre-PR Cache FAIL, fixed Cache PASS.
EOF

echo "[pr21-real] wrote $REPORT"
exit "$overall"
