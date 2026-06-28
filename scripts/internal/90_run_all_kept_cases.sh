#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

echo "[90] 01_adder_buggy"
bash scripts/internal/10_run_adder_formal_skill_smoke.sh

echo "[90] 02_pr21_mmio_prefetch"
bash scripts/internal/21_run_pr21_real_cache_formal.sh

if [[ "${RUN_UCAGENT_SKILL_EXTENDED:-0}" == "1" ]]; then
  echo "[90] 02_pr21_mmio_prefetch via UCAgent + generic-formal"
  bash scripts/internal/22_run_pr21_ucagent_formal_skill.sh
else
  echo "[90] skip 02 UCAgent formal skill by default; set RUN_UCAGENT_SKILL_EXTENDED=1 to run scripts/internal/22_run_pr21_ucagent_formal_skill.sh"
fi

echo "[90] 03_pr74_cache_io_idbits"
bash scripts/internal/31_run_pr74_real_cache_formal.sh

if [[ "${RUN_UCAGENT_SKILL_EXTENDED:-0}" == "1" ]]; then
  echo "[90] 03_pr74_cache_io_idbits via UCAgent + generic-formal"
  bash scripts/internal/32_run_pr74_ucagent_formal_skill.sh
else
  echo "[90] skip 03 UCAgent formal skill by default; set RUN_UCAGENT_SKILL_EXTENDED=1 to run scripts/internal/32_run_pr74_ucagent_formal_skill.sh"
fi

echo "[90] 04_l2_readburst_hit_ready_valid_deadlock via UCAgent + generic-formal"
bash scripts/internal/40_run_l2_readburst_ucagent_formal.sh

echo "[90] 04_l2_readburst dynamic replay"
bash scripts/internal/41_run_l2_readburst_dynamic.sh

echo "[90] 04_l2_readburst Toffee directed coverage"
bash scripts/internal/42_prepare_l2_readburst_picker_dut.sh
bash scripts/internal/43_run_l2_readburst_toffee_directed.sh

if [[ "${RUN_UCAGENT_FULL_DEMO:-0}" == "1" ]]; then
  echo "[90] 04_l2_readburst UCAgent formal-first full demo"
  bash scripts/internal/45_run_l2_readburst_ucagent_full_demo.sh
else
  echo "[90] skip 04 UCAgent full demo by default; set RUN_UCAGENT_FULL_DEMO=1 to run scripts/internal/45_run_l2_readburst_ucagent_full_demo.sh"
fi

if [[ "${RUN_UCAGENT_ORIGINAL_COMPARE:-0}" == "1" ]]; then
  echo "[90] 02/03/04 UCAgent Toffee dynamic backend without formal skill comparison"
  bash scripts/internal/46_run_three_case_ucagent_original_no_formal.sh
else
  echo "[90] skip no-formal UCAgent Toffee comparison by default; set RUN_UCAGENT_ORIGINAL_COMPARE=1 to run scripts/internal/46_run_three_case_ucagent_original_no_formal.sh"
fi

echo "[90] all kept cases completed"
