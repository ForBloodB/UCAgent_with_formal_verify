#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VENV="$ROOT/.venv-ucagent"
PYTHON_BIN="${PYTHON_BIN:-}"

if [ ! -d "$ROOT/third_party/UCAgent" ] || [ ! -d "$ROOT/third_party/picker" ]; then
  echo "[venv] missing third_party sources; run scripts/00_setup_ucagent_sources.sh first" >&2
  exit 1
fi

if [ -z "$PYTHON_BIN" ]; then
  if command -v python3.12 >/dev/null 2>&1; then
    PYTHON_BIN="python3.12"
  elif command -v python3.11 >/dev/null 2>&1; then
    PYTHON_BIN="python3.11"
  else
    PYTHON_BIN="python3"
  fi
fi

rm -rf "$VENV"
"$PYTHON_BIN" -m venv "$VENV"
"$VENV/bin/pip" install --upgrade pip
"$VENV/bin/pip" install -r "$ROOT/third_party/UCAgent/requirements.txt"
"$VENV/bin/pip" install -e "$ROOT/third_party/UCAgent" -e "$ROOT/third_party/picker" pytest

echo "[venv] ready: $VENV"
echo "[venv] python: $("$VENV/bin/python" --version)"
echo "[venv] activate with: source $VENV/bin/activate"
