#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

rm -rf reports/generic_formal

python3 ucagent_skills/generic-formal/scripts/run_formal.py \
  --case examples/counter_formal/formal/counter_buggy.yaml \
  --timeout 120

python3 ucagent_skills/generic-formal/scripts/run_formal.py \
  --case examples/counter_formal/formal/counter_fixed.yaml \
  --timeout 120

echo "[generic-formal-smoke] wrote reports/generic_formal/counter_minimal.md"
