#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
set +e
"$ROOT/scripts/24_run_three_case_formal.sh"
rc=$?
set -e

if [ -f "$ROOT/reports/formal_batch/three_case_formal.md" ]; then
  cp "$ROOT/reports/formal_batch/three_case_formal.md" "$ROOT/reports/formal_batch/historical_bug_litmus.md"
fi

exit "$rc"
