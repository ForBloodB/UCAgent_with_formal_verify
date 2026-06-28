#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "[compat] scripts/90_run_all_kept_cases.sh is deprecated."
echo "[compat] Forwarding to scripts/run_cases.sh --case all --with-formal."

exec bash scripts/run_cases.sh --case all --with-formal "$@"
