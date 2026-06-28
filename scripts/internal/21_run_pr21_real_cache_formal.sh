#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REPORT="$ROOT/reports/02_pr21.md"
LOG_DIR="$ROOT/reports/artifacts/02_pr21/logs"

mkdir -p "$LOG_DIR" "$(dirname "$REPORT")"
cd "$ROOT"

run_sby() {
  local sby_file="$1"
  if command -v sby >/dev/null 2>&1; then
    sby -f "$sby_file"
  elif command -v docker >/dev/null 2>&1; then
    docker run --rm \
      --user "$(id -u):$(id -g)" \
      -v "$ROOT:/work" \
      -w /work \
      "${FORMAL_DOCKER_IMAGE:-nutshell-cache-formal:latest}" \
      sby -f "$sby_file"
  else
    echo "[pr21-real] error: neither local sby nor docker is available." >&2
    return 127
  fi
}

if [ ! -f "$ROOT/tests/cases/02_pr21_mmio_prefetch/formal/generated/pre/Pr21CacheFormalDut.v" ] ||
   [ ! -f "$ROOT/tests/cases/02_pr21_mmio_prefetch/formal/generated/fixed/Pr21CacheFormalDut.v" ]; then
  bash "$ROOT/scripts/internal/20_prepare_pr21_real_cache.sh" all
else
  echo "[pr21-real] using existing generated real NutShell Cache RTL"
fi

CASES=(
  "pr21_real_nutshell_cache_pre|tests/cases/02_pr21_mmio_prefetch/formal/nutshell_pr21_real_cache_pre.sby|FAIL|PR #21 之前的 NutShell parent bd425dee"
  "pr21_real_nutshell_cache_fixed|tests/cases/02_pr21_mmio_prefetch/formal/nutshell_pr21_real_cache_fixed.sby|PASS|带 PR #21 修复的 NutShell PR branch f0d7c494"
)

{
  echo "# PR21 真实 NutShell Cache Formal 报告"
  echo
  echo "- 日期：$(date -Iseconds)"
  echo "- 范围：从 PR #21 parent/fixed commit 生成真实 NutShell Cache，并通过 formal wrapper 观察真实 s2->s3 cache pipeline。"
  echo
  echo "| Case | Source | Expected | Actual | Verdict | Log |"
  echo "| --- | --- | --- | --- | --- | --- |"
} > "$REPORT"

overall=0
for entry in "${CASES[@]}"; do
  IFS="|" read -r name sby_file expected description <<< "$entry"
  log="$LOG_DIR/${name}.log"
  log_rel="reports/artifacts/02_pr21/logs/${name}.log"

  echo "[pr21-real] running $name expected=$expected"
  if run_sby "$sby_file" >"$log" 2>&1; then
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

## 来源

- PR #21 merge commit: https://github.com/OSCPU/NutShell/commit/a3663f25183d6cbf89a088e3e8a365e2e6270366
- Pre-PR parent: https://github.com/OSCPU/NutShell/commit/bd425deedff4e896fca59895b34d778f2c8724d9
- Fixed PR head: https://github.com/OSCPU/NutShell/commit/f0d7c49411197047dc8464addfacc0fcba5b9e45

## 解读

- DUT 来自真实 NutShell `nutcore.Cache`，不是早期 compact litmus。
- wrapper 只驱动 public cache IO，并通过 `scripts/internal/20_prepare_pr21_real_cache.sh` 插入的 Chisel `BoringUtils` probes 观察内部 s2/s3 信号。
- 预期对照为：pre-PR Cache `FAIL`，fixed Cache `PASS`。
EOF

echo "[pr21-real] wrote $REPORT"
exit "$overall"
