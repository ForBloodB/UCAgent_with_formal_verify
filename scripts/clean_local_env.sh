#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "[clean] removing project-local tool sources and virtual environments"
rm -rf third_party .venv-ucagent

echo "[clean] removing Python and pytest caches"
find . -type d -name __pycache__ -prune -exec rm -rf {} +
find . -type d -name .pytest_cache -prune -exec rm -rf {} +
find . -type f -name '*.pyc' -delete

echo "[clean] removing generated formal run directories"
rm -rf tests/cases/*/formal/*_assert
rm -rf tests/cases/*/formal/*_cover
rm -rf tests/cases/*/formal/*_pre
rm -rf tests/cases/*/formal/*_fixed
rm -rf tests/cases/*/formal/*_buggy
rm -rf tests/cases/*/formal/adder_buggy
rm -rf tests/cases/*/formal/adder_fixed
rm -rf tests/cases/*/formal/generated
rm -f tests/cases/*/formal/adder_*.sby

echo "[clean] removing UCAgent workspace caches"
rm -rf tests/ucagent_workspaces/*/.ucagent
rm -rf tests/ucagent_workspaces/*/unity_test
rm -rf tests/ucagent_workspaces/*/uc_test_report
rm -rf tests/ucagent_workspaces/*/AGENTS.md
rm -rf tests/ucagent_workspaces/*/Guide_Doc
rm -rf tests/ucagent_workspaces/*/reports

echo "[clean] removing generated dynamic binaries while keeping Markdown/VCD evidence"
rm -rf reports/artifacts/*/toffee_dut
find reports/artifacts -type f \( -name '*.vvp' -o -name '*.fst' -o -name '*.dat' -o -name '*.so' -o -name '*.o' \) -delete 2>/dev/null || true

echo "[clean] local project environment removed"
echo "[clean] .ucagent_env was intentionally kept; it is ignored by git and never copied into Docker images"
