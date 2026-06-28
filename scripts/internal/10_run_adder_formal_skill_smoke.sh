#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

rm -rf reports/01_adder.md reports/artifacts/01_adder

python3 src/ucagent_skills/generic-formal/scripts/run_formal.py \
  --case tests/cases/01_generic_formal_proof/formal/adder_buggy.yaml \
  --timeout 120

python3 src/ucagent_skills/generic-formal/scripts/run_formal.py \
  --case tests/cases/01_generic_formal_proof/formal/adder_fixed.yaml \
  --timeout 120

cat >> reports/01_adder.md <<'EOF_REPORT'

## 为什么保留这个案例

这是一个很小的人工 adder bug，用来证明可复用的 `generic-formal` skill 能抓到已知 RTL 缺陷，并且不会在 fixed RTL 上误报。它不是 NutShell Cache 真实 bug。

## UCAgent Skill 兼容性

该案例使用的 YAML case 格式就是 `src/ucagent_skills/generic-formal/SKILL.md` 暴露给 UCAgent 的接口，因此 UCAgent 可以通过 `RunSkillScript` 对任意小模块调用同一个形式验证 skill。
EOF_REPORT

echo "[01-adder] wrote reports/01_adder.md"
