#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

exec bash scripts/internal/00_setup_ucagent_sources.sh "$@"
