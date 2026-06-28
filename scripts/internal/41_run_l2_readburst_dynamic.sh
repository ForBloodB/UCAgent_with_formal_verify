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

cat > "${REPORT}" <<EOF_REPORT
# L2 ReadBurst Ready/Valid 动态仿真

- 分类：\`${classification}\`
- RTL: \`${RTL#${ROOT_DIR}/}\`
- Testbench: \`${TB#${ROOT_DIR}/}\`
- 日志：\`${LOG#${ROOT_DIR}/}\`
- VCD: \`reports/artifacts/04_l2_readburst/artifacts/dynamic_readburst_ready_deadlock.vcd\`

## 场景

1. 复位生成的 latest-upstream NutShell L2 Cache wrapper。
2. 发送一次同地址 \`readBurst\` 请求，让简单内存模型完成 miss/refill。
3. 发送第二次同地址 \`readBurst\` 请求，预期命中刚 refill 的 cache line。
4. 当请求到达 S3，且满足 \`valid && hit && readBurst\` 时，将 \`io_cpu_resp_ready=0\` 保持 16 个周期。
5. 检查在 ready-low hit 窗口中 \`io_cpu_resp_valid\` 是否保持为低。

## 结果

${conclusion}

这是 directed dynamic replay，只使用 wrapper public ports。它不会初始化或 force Cache 内部状态。
EOF_REPORT

if [[ -f "${MAIN_REPORT}" ]]; then
  tmp_report="$(mktemp)"
  awk 'BEGIN { stop = 0 } /^## (Dynamic Replay|动态复现)$/ { stop = 1 } stop == 0 { print }' "${MAIN_REPORT}" > "${tmp_report}"
  mv "${tmp_report}" "${MAIN_REPORT}"
  cat >> "${MAIN_REPORT}" <<EOF_MAIN

## 动态复现

- 分类：\`${classification}\`
- 报告：\`${REPORT#${ROOT_DIR}/}\`
- 日志：\`${LOG#${ROOT_DIR}/}\`
- VCD: \`reports/artifacts/04_l2_readburst/artifacts/dynamic_readburst_ready_deadlock.vcd\`

${conclusion}
EOF_MAIN
  workspace_mirror="${ROOT_DIR}/tests/ucagent_workspaces/04_l2_readburst_deadlock/reports/04_l2_readburst.md"
  if [[ -d "$(dirname "${workspace_mirror}")" ]]; then
    cp "${MAIN_REPORT}" "${workspace_mirror}"
  fi
fi

echo "Wrote ${REPORT}"
echo "classification=${classification}"

if [[ "${classification}" == "INFRA_FAIL" ]]; then
  exit 1
fi
