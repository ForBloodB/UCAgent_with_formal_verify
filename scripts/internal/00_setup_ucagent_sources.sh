#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
THIRD_PARTY="$ROOT/third_party"
REPORT="$ROOT/reports/toolchain_sources.md"

mkdir -p "$THIRD_PARTY" "$(dirname "$REPORT")"

clone_or_update() {
  local name="$1"
  local url="$2"
  local dir="$THIRD_PARTY/$name"

  if [ -d "$dir/.git" ]; then
    echo "[setup] updating $name"
    git -C "$dir" fetch --depth 1 origin
    git -C "$dir" checkout -q FETCH_HEAD
  else
    echo "[setup] cloning $name from $url"
    git clone --depth 1 "$url" "$dir"
  fi
}

clone_or_update "UCAgent" "https://github.com/XS-MLVP/UCAgent.git"
clone_or_update "Example-NutShellCache" "https://github.com/XS-MLVP/Example-NutShellCache.git"
clone_or_update "picker" "https://github.com/XS-MLVP/picker.git"

{
  echo "# Toolchain Sources"
  echo
  echo "- Date: $(date -Iseconds)"
  echo
  echo "| Component | URL | Commit |"
  echo "| --- | --- | --- |"
  for name in UCAgent Example-NutShellCache picker; do
    dir="$THIRD_PARTY/$name"
    url="$(git -C "$dir" remote get-url origin)"
    commit="$(git -C "$dir" rev-parse HEAD)"
    echo "| $name | $url | \`$commit\` |"
  done
} > "$REPORT"

echo "[setup] wrote $REPORT"
