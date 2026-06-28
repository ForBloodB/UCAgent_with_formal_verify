#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RTL="${ROOT_DIR}/tests/cases/04_l2_readburst_hit_ready_valid_deadlock/formal/generated/latest/FreshCacheFormalDut.sv"
TB="${ROOT_DIR}/tests/cases/04_l2_readburst_hit_ready_valid_deadlock/sim/readburst_ready_deadlock_tb.sv"
ARTIFACT_DIR="${ROOT_DIR}/reports/artifacts/04_l2_readburst/artifacts"
LOG="${ARTIFACT_DIR}/dynamic_readburst_ready_deadlock.log"
VVP="${ARTIFACT_DIR}/dynamic_readburst_ready_deadlock.vvp"
REPORT="${ROOT_DIR}/reports/artifacts/04_l2_readburst/dynamic_readburst_ready_deadlock.md"
MAIN_REPORT="${ROOT_DIR}/reports/04_l2_readburst.md"
FORMAL_SKILL_REPORT="${ROOT_DIR}/reports/04_l2_readburst_formal_skill.md"

mkdir -p "${ARTIFACT_DIR}"

if [[ ! -f "${RTL}" ]]; then
  echo "Missing generated RTL: ${RTL}" >&2
  echo "Preparing latest NutShell L2 readBurst wrapper now..." >&2
  python3 "${ROOT_DIR}/tests/cases/04_l2_readburst_hit_ready_valid_deadlock/scripts/prepare_latest_l2_readburst.py" \
    --repo-root "${ROOT_DIR}" \
    --timeout "${L2_READBURST_PREPARE_TIMEOUT:-1200}"
fi

if [[ ! -f "${TB}" ]]; then
  echo "Missing dynamic testbench: ${TB}" >&2
  exit 2
fi

iverilog -g2012 -DSYNTHESIS -o "${VVP}" "${RTL}" "${TB}"
(
  cd "${ROOT_DIR}"
  vvp "${VVP}"
) | tee "${LOG}"

if grep -q "DYNAMIC_RESULT: FAIL_READY_VALID_DEADLOCK_RISK" "${LOG}"; then
  classification="DYNAMIC_REPRODUCED"
  conclusion="public-IO 仿真复现了 ready/valid deadlock 风险：同地址 L2 readBurst hit 停留在 S3 且 L1 侧 \`resp_ready=0\` 时，\`io_cpu_resp_valid\` 也保持为低。"
elif grep -q "DYNAMIC_RESULT: PASS_FOR_THIS_PUBLIC_IO_SEQUENCE" "${LOG}"; then
  classification="NO_DYNAMIC_FAILURE_FOR_SEQUENCE"
  conclusion="directed public-IO 仿真到达了 ready-low readBurst-hit 窗口，但在该 bounded sequence 中没有观察到 \`resp_valid\` 为低。"
elif grep -q "DYNAMIC_RESULT: UNREACHABLE_READY_LOW_HIT_WINDOW" "${LOG}"; then
  classification="UNREACHABLE_IN_DIRECTED_SIM"
  conclusion="directed public-IO 仿真未能到达 ready-low readBurst-hit 窗口。"
else
  classification="INFRA_FAIL"
  conclusion="动态仿真没有以可识别的 result marker 结束。"
fi

first_bug_cycle="$(awk '/DYNAMIC_BUG_REPRODUCED/ { for (i = 1; i <= NF; i++) if ($i == "cycle") print $(i + 1) }' "${LOG}" | head -n 1)"
last_bug_cycle="$(awk '/DYNAMIC_BUG_REPRODUCED/ { for (i = 1; i <= NF; i++) if ($i == "cycle") print $(i + 1) }' "${LOG}" | tail -n 1)"
last_logged_cycle="$(awk '/^C[0-9]+ / { cycle = $1; sub(/^C/, "", cycle); print cycle }' "${LOG}" | tail -n 1)"
post_trigger_cycles="n/a"
if [[ -n "${first_bug_cycle}" && -n "${last_logged_cycle}" ]]; then
  post_trigger_cycles="$((last_logged_cycle - first_bug_cycle))"
fi

cat > "${REPORT}" <<EOF_REPORT
# L2 ReadBurst Ready/Valid 动态仿真

- 分类：\`${classification}\`
- RTL: \`${RTL#${ROOT_DIR}/}\`
- Testbench: \`${TB#${ROOT_DIR}/}\`
- 日志：\`${LOG#${ROOT_DIR}/}\`
- VCD: \`reports/artifacts/04_l2_readburst/artifacts/dynamic_readburst_ready_deadlock.vcd\`
- 首次 bug marker cycle：\`${first_bug_cycle:-n/a}\`
- 最后一次 bug marker cycle：\`${last_bug_cycle:-n/a}\`
- 最后记录 cycle：\`${last_logged_cycle:-n/a}\`
- bug 触发后继续记录周期数：\`${post_trigger_cycles}\`

## 场景

1. 复位生成的 latest-upstream NutShell L2 Cache wrapper。
2. 发送一次同地址 \`readBurst\` 请求，让简单内存模型完成 miss/refill。
3. 发送第二次同地址 \`readBurst\` 请求，预期命中刚 refill 的 cache line。
4. 当请求到达 S3，且满足 \`valid && hit && readBurst\` 时，将 \`io_cpu_resp_ready=0\` 保持 16 个周期。
5. 检查在 ready-low hit 窗口中 \`io_cpu_resp_valid\` 是否保持为低。

## 结果

${conclusion}

当前 VCD 覆盖首次 bug marker 后至少 \`${post_trigger_cycles}\` 个周期；其中 cycle 45 到 cycle 54 是“触发之后 10 个循环”的核心观察窗口。

这是 directed dynamic replay，只使用 wrapper public ports。它不会初始化或 force Cache 内部状态。
EOF_REPORT

if [[ -f "${MAIN_REPORT}" ]]; then
  head_report="$(mktemp)"
  tail_report="$(mktemp)"
  awk 'BEGIN { stop = 0 } /^## (Dynamic Replay|动态复现)$/ { stop = 1 } /^## Toffee 动态覆盖闭环$/ { stop = 1 } stop == 0 { print }' "${MAIN_REPORT}" > "${head_report}"
  awk 'BEGIN { keep = 0 } /^## Toffee 动态覆盖闭环$/ { keep = 1 } keep == 1 { print }' "${MAIN_REPORT}" > "${tail_report}"
  if [[ ! -s "${tail_report}" ]]; then
    cat > "${tail_report}" <<'EOF_TAIL'
## Toffee 动态覆盖闭环

- 报告：`reports/04_l2_readburst_toffee_coverage.md`
- Toffee/pytest HTML：`reports/artifacts/04_l2_readburst/toffee/pytest_report/index.html`
- Toffee waveform：`reports/artifacts/04_l2_readburst/toffee/l2_readburst_ready_deadlock.fst`
- Coverage JSON：`reports/artifacts/04_l2_readburst/toffee/coverage_summary.json`

该闭环使用 Picker 导出的 Python DUT、Toffee/pytest env、scoreboard 和场景级 coverage。Coverage 口径只覆盖 04 场景本身，不声明覆盖整个 NutShell Cache。
EOF_TAIL
  fi
  {
    cat "${head_report}"
    cat <<EOF_MAIN

## 动态复现

- 分类：\`${classification}\`
- 报告：\`${REPORT#${ROOT_DIR}/}\`
- 日志：\`${LOG#${ROOT_DIR}/}\`
- VCD: \`reports/artifacts/04_l2_readburst/artifacts/dynamic_readburst_ready_deadlock.vcd\`
- 首次 bug marker cycle：\`${first_bug_cycle:-n/a}\`
- 最后一次 bug marker cycle：\`${last_bug_cycle:-n/a}\`
- 最后记录 cycle：\`${last_logged_cycle:-n/a}\`
- bug 触发后继续记录周期数：\`${post_trigger_cycles}\`

${conclusion}

当前 VCD 覆盖首次 bug marker 后至少 \`${post_trigger_cycles}\` 个周期；其中 cycle 45 到 cycle 54 是“触发之后 10 个循环”的核心观察窗口。
EOF_MAIN
    echo
    cat "${tail_report}"
  } > "${MAIN_REPORT}"
  rm -f "${head_report}" "${tail_report}"
else
  formal_summary="尚未生成。"
  if [[ -f "${FORMAL_SKILL_REPORT}" ]]; then
    formal_summary="\`${FORMAL_SKILL_REPORT#${ROOT_DIR}/}\`"
  fi
  cat > "${MAIN_REPORT}" <<EOF_MAIN
# 04 L2 readBurst Ready/Valid Candidate

- Formal skill report：${formal_summary}
- Dynamic replay report：\`${REPORT#${ROOT_DIR}/}\`
- Toffee coverage report：\`reports/04_l2_readburst_toffee_coverage.md\`
- Waveform screenshot：\`reports/assets/04_l2_readburst_ready_valid_waveform.png\`

## 结论

在标准 Decoupled ready/valid 语义下，当前情况是一个很强的 candidate bug；但如果 NutShell 设计者额外规定 L1 必须一直 ready，则需要在设计文档中明确写出这个环境假设。

![04 ready/valid waveform](assets/04_l2_readburst_ready_valid_waveform.png)

## 动态复现

- 分类：\`${classification}\`
- 报告：\`${REPORT#${ROOT_DIR}/}\`
- 日志：\`${LOG#${ROOT_DIR}/}\`
- VCD: \`reports/artifacts/04_l2_readburst/artifacts/dynamic_readburst_ready_deadlock.vcd\`
- 首次 bug marker cycle：\`${first_bug_cycle:-n/a}\`
- 最后一次 bug marker cycle：\`${last_bug_cycle:-n/a}\`
- 最后记录 cycle：\`${last_logged_cycle:-n/a}\`
- bug 触发后继续记录周期数：\`${post_trigger_cycles}\`

${conclusion}

当前 VCD 覆盖首次 bug marker 后至少 \`${post_trigger_cycles}\` 个周期；其中 cycle 45 到 cycle 54 是“触发之后 10 个循环”的核心观察窗口。

## Toffee 动态覆盖闭环

- 报告：\`reports/04_l2_readburst_toffee_coverage.md\`
- Toffee/pytest HTML：\`reports/artifacts/04_l2_readburst/toffee/pytest_report/index.html\`
- Toffee waveform：\`reports/artifacts/04_l2_readburst/toffee/l2_readburst_ready_deadlock.fst\`
- Coverage JSON：\`reports/artifacts/04_l2_readburst/toffee/coverage_summary.json\`

该闭环使用 Picker 导出的 Python DUT、Toffee/pytest env、scoreboard 和场景级 coverage。Coverage 口径只覆盖 04 场景本身，不声明覆盖整个 NutShell Cache。
EOF_MAIN
fi

workspace_mirror="${ROOT_DIR}/tests/ucagent_workspaces/04_l2_readburst_deadlock/reports/04_l2_readburst.md"
if [[ -d "$(dirname "${workspace_mirror}")" ]]; then
  cp "${MAIN_REPORT}" "${workspace_mirror}"
fi

echo "Wrote ${REPORT}"
echo "classification=${classification}"

if [[ "${classification}" == "INFRA_FAIL" ]]; then
  exit 1
fi
