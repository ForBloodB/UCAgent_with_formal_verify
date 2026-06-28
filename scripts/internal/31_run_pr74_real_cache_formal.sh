#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REPORT="$ROOT/reports/03_pr74.md"
LOG_DIR="$ROOT/reports/artifacts/03_pr74/logs"

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
    echo "[pr74-real] error: neither local sby nor docker is available." >&2
    return 127
  fi
}

{
  echo "# PR74 真实 NutShell CacheIO Formal 报告"
  echo
  echo "- 日期：$(date -Iseconds)"
  echo "- 范围：从 PR #74 parent/fixed commit 生成真实 NutShell Cache。"
  echo "- 属性：OOO 风格 Cache 配置在 \`idBits=4\` 时，\`CacheIO.in\` 必须暴露 request/response ID field，并在响应中保持已接收的 ID。"
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
  bash "$ROOT/scripts/internal/30_prepare_pr74_real_cache.sh" pre >"$pre_log" 2>&1
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

echo "| \`pr74_real_nutshell_cache_pre_generate\` | PR #74 之前的 NutShell parent 4b656f32 | ELAB_FAIL | $pre_actual | $pre_verdict | \`reports/artifacts/03_pr74/logs/pr74_real_nutshell_cache_pre_generate.log\` |" >> "$REPORT"
tail -n 20 "$pre_log" || true

fixed_gen_log="$LOG_DIR/pr74_real_nutshell_cache_fixed_generate.log"
if [ "${PR74_FORCE_REGEN:-0}" != "1" ] && [ -f "$ROOT/tests/cases/03_pr74_cache_io_idbits/formal/generated/fixed/Pr74CacheIOFormalDut.v" ]; then
  echo "[pr74-real] using existing fixed generated real NutShell Cache RTL"
  {
    echo "[pr74-real] using existing fixed generated real NutShell Cache RTL"
    echo "generated_rtl=tests/cases/03_pr74_cache_io_idbits/formal/generated/fixed/Pr74CacheIOFormalDut.v"
  } > "$fixed_gen_log"
  fixed_gen_actual="PASS"
else
  echo "[pr74-real] generating fixed PR head"
  if bash "$ROOT/scripts/internal/30_prepare_pr74_real_cache.sh" fixed >"$fixed_gen_log" 2>&1; then
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

echo "| \`pr74_real_nutshell_cache_fixed_generate\` | 带 PR #74 修复的 NutShell PR head 287c5e02 | PASS | $fixed_gen_actual | $fixed_gen_verdict | \`reports/artifacts/03_pr74/logs/pr74_real_nutshell_cache_fixed_generate.log\` |" >> "$REPORT"
tail -n 20 "$fixed_gen_log" || true

if [ "$fixed_gen_actual" = "PASS" ]; then
  fixed_formal_log="$LOG_DIR/pr74_real_nutshell_cache_fixed_formal.log"
  echo "[pr74-real] running fixed formal"
  if run_sby "tests/cases/03_pr74_cache_io_idbits/formal/nutshell_pr74_real_cache_fixed.sby" >"$fixed_formal_log" 2>&1; then
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

  echo "| \`pr74_real_nutshell_cache_fixed_formal\` | fixed 真实 Cache response ID property | PASS | $fixed_formal_actual | $fixed_formal_verdict | \`reports/artifacts/03_pr74/logs/pr74_real_nutshell_cache_fixed_formal.log\` |" >> "$REPORT"
  tail -n 20 "$fixed_formal_log" || true
else
  echo "| \`pr74_real_nutshell_cache_fixed_formal\` | fixed 真实 Cache response ID property | PASS | SKIPPED | UNEXPECTED | \`reports/artifacts/03_pr74/logs/pr74_real_nutshell_cache_fixed_generate.log\` |" >> "$REPORT"
fi

cat >> "$REPORT" <<'EOF'

## 来源

- PR #74: https://github.com/OSCPU/NutShell/pull/74
- Pre-PR parent: https://github.com/OSCPU/NutShell/commit/4b656f32aea0687fe8c823b99a54dc76517c3a41
- Fixed PR head: https://github.com/OSCPU/NutShell/commit/287c5e02490aca73055211bd04908917d71deaf7

## 解读

- DUT 是从两个历史 commit 生成的真实 NutShell `nutcore.Cache`。
- parent commit 将 `CacheIO.in` 构造成 `SimpleBusUC(userBits = userBits)`，因此 OOO `idBits=4` wrapper 无法 elaborate 所需 ID field。
- fixed commit 将 `CacheIO.in` 构造成 `SimpleBusUC(userBits = userBits, idBits = idBits)`，同一个 wrapper 可以 elaborate，fixed formal property 也能运行。
- 该案例捕获的是接口/type 回归，而不是深层运行时 BMC 反例；这与 PR #74 原始症状一致：先前修改破坏了 OOO 配置。
EOF

echo "[pr74-real] wrote $REPORT"
exit "$overall"
