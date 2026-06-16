#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPORT="$ROOT/reports/pr74_real_nutshell_cache_formal.md"
LOG_DIR="$ROOT/reports/formal_batch/logs"

mkdir -p "$LOG_DIR" "$(dirname "$REPORT")"
cd "$ROOT"

if ! command -v sby >/dev/null 2>&1; then
  echo "[pr74-real] error: sby not found. Generate RTL with scripts/42 first, then run inside a SymbiYosys environment." >&2
  exit 127
fi

{
  echo "# PR74 Real NutShell CacheIO Formal Report"
  echo
  echo "- Date: $(date -Iseconds)"
  echo "- Scope: real NutShell Cache generated from PR #74 parent/fixed commits."
  echo "- Property: an OOO-style Cache configuration with \`idBits=4\` must expose request/response ID fields at \`CacheIO.in\` and preserve the accepted ID on response."
  echo
  echo "| Case | Source | Expected | Actual | Verdict | Log |"
  echo "| --- | --- | --- | --- | --- | --- |"
} > "$REPORT"

overall=0

pre_log="$LOG_DIR/pr74_real_nutshell_cache_pre_generate.log"
if [ "${PR74_FORCE_REGEN:-0}" != "1" ] && grep -q "Right Record missing field (id)" "$pre_log" 2>/dev/null; then
  echo "[pr74-real] using existing pre-PR elaboration failure log"
  pre_rc=1
else
  echo "[pr74-real] generating pre-PR parent; expected elaboration failure"
  set +e
  bash "$ROOT/scripts/42_prepare_pr74_real_nutshell_cache.sh" pre >"$pre_log" 2>&1
  pre_rc=$?
  set -e
fi

if [ "$pre_rc" -ne 0 ]; then
  pre_actual="ELAB_FAIL"
else
  pre_actual="PASS"
fi

if [ "$pre_actual" = "ELAB_FAIL" ]; then
  pre_verdict="OK"
else
  pre_verdict="UNEXPECTED"
  overall=1
fi

echo "| \`pr74_real_nutshell_cache_pre_generate\` | NutShell parent 4b656f32 before PR #74 | ELAB_FAIL | $pre_actual | $pre_verdict | \`reports/formal_batch/logs/pr74_real_nutshell_cache_pre_generate.log\` |" >> "$REPORT"
tail -n 20 "$pre_log" || true

fixed_gen_log="$LOG_DIR/pr74_real_nutshell_cache_fixed_generate.log"
if [ "${PR74_FORCE_REGEN:-0}" != "1" ] && [ -f "$ROOT/formal/nutshell_pr74_real/generated/fixed/Pr74CacheIOFormalDut.v" ]; then
  echo "[pr74-real] using existing fixed generated real NutShell Cache RTL"
  fixed_gen_actual="PASS"
else
  echo "[pr74-real] generating fixed PR head"
  if bash "$ROOT/scripts/42_prepare_pr74_real_nutshell_cache.sh" fixed >"$fixed_gen_log" 2>&1; then
    fixed_gen_actual="PASS"
  else
    fixed_gen_actual="ERROR"
  fi
fi

if [ "$fixed_gen_actual" = "PASS" ]; then
  fixed_gen_verdict="OK"
else
  fixed_gen_verdict="UNEXPECTED"
  overall=1
fi

echo "| \`pr74_real_nutshell_cache_fixed_generate\` | NutShell PR head 287c5e02 with PR #74 fix | PASS | $fixed_gen_actual | $fixed_gen_verdict | \`reports/formal_batch/logs/pr74_real_nutshell_cache_fixed_generate.log\` |" >> "$REPORT"
tail -n 20 "$fixed_gen_log" || true

if [ "$fixed_gen_actual" = "PASS" ]; then
  fixed_formal_log="$LOG_DIR/pr74_real_nutshell_cache_fixed_formal.log"
  echo "[pr74-real] running fixed formal"
  if sby -f "$ROOT/formal/nutshell_pr74_real/nutshell_pr74_real_cache_fixed.sby" >"$fixed_formal_log" 2>&1; then
    fixed_formal_actual="PASS"
  elif grep -Eq "DONE \\(FAIL|BMC failed|Assert failed|Status: failed" "$fixed_formal_log"; then
    fixed_formal_actual="FAIL"
  elif grep -q "DONE (TIMEOUT" "$fixed_formal_log"; then
    fixed_formal_actual="TIMEOUT"
  else
    fixed_formal_actual="ERROR"
  fi

  if [ "$fixed_formal_actual" = "PASS" ]; then
    fixed_formal_verdict="OK"
  else
    fixed_formal_verdict="UNEXPECTED"
    overall=1
  fi

  echo "| \`pr74_real_nutshell_cache_fixed_formal\` | Fixed real Cache response ID property | PASS | $fixed_formal_actual | $fixed_formal_verdict | \`reports/formal_batch/logs/pr74_real_nutshell_cache_fixed_formal.log\` |" >> "$REPORT"
  tail -n 20 "$fixed_formal_log" || true
else
  echo "| \`pr74_real_nutshell_cache_fixed_formal\` | Fixed real Cache response ID property | PASS | SKIPPED | UNEXPECTED | \`reports/formal_batch/logs/pr74_real_nutshell_cache_fixed_generate.log\` |" >> "$REPORT"
fi

cat >> "$REPORT" <<'EOF'

## Sources

- PR #74: https://github.com/OSCPU/NutShell/pull/74
- Pre-PR parent: https://github.com/OSCPU/NutShell/commit/4b656f32aea0687fe8c823b99a54dc76517c3a41
- Fixed PR head: https://github.com/OSCPU/NutShell/commit/287c5e02490aca73055211bd04908917d71deaf7

## Interpretation

- The DUT is the real NutShell `nutcore.Cache`, generated from the two historical commits.
- The parent commit builds `CacheIO.in` as `SimpleBusUC(userBits = userBits)`, so an OOO `idBits=4` wrapper cannot elaborate the required ID field.
- The fixed commit builds `CacheIO.in` as `SimpleBusUC(userBits = userBits, idBits = idBits)`, so the same wrapper elaborates and the fixed formal property can run.
- This case catches an interface/type regression rather than a deep runtime BMC counterexample; that matches PR #74's original symptom: the previous change broke the OOO configuration.
EOF

echo "[pr74-real] wrote $REPORT"
exit "$overall"
