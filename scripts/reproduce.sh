#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
case_id="all"
mode="with-formal"
api=1
skip_build=0
rebuild=0
skip_tool_smoke=0

usage() {
  cat <<'EOF'
Usage:
  bash scripts/reproduce.sh [--case all|01|02|03|04|05] [--smoke|--api] [--rebuild] [--skip-build] [--skip-tool-smoke]

Default:
  Reuse the local Docker image if it exists; otherwise build it from scratch.
  Then run the real UCAgent API reproduction. Requires .ucagent_env.

Options:
  --case all|01|02|03|04|05  Select the case to reproduce. Default: all.
  --smoke                    Local-only reproduction. Does not call UCAgent API.
  --api                      Run the real UCAgent API flow. This is the default.
  --rebuild                  Rebuild the Docker image from scratch.
  --skip-build               Require an existing Docker image and never build.
  --skip-tool-smoke          Skip the Docker toolchain smoke check.

Examples:
  bash scripts/reproduce.sh
  bash scripts/reproduce.sh --case 05 --smoke
  bash scripts/reproduce.sh --case 05 --api
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --case)
      case_id="${2:-}"
      shift 2
      ;;
    --smoke)
      api=0
      shift
      ;;
    --api)
      api=1
      shift
      ;;
    --skip-build)
      skip_build=1
      shift
      ;;
    --rebuild|--no-cache)
      rebuild=1
      shift
      ;;
    --skip-tool-smoke)
      skip_tool_smoke=1
      shift
      ;;
    --with-formal)
      mode="with-formal"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

case "$case_id" in
  all|01|02|03|04|05) ;;
  *)
    echo "--case must be one of all|01|02|03|04|05" >&2
    exit 2
    ;;
esac

cd "$ROOT"

if [[ "$api" == "1" && ! -f "$ROOT/.ucagent_env" ]]; then
  echo "[reproduce] missing .ucagent_env. Copy .ucagent_env.example and fill the API settings first." >&2
  echo "[reproduce] use --smoke for local-only checks without API." >&2
  exit 1
fi

image="${UCAGENT_FORMAL_IMAGE:-ucagent-with-formal-verify:latest}"
if [[ "$skip_build" == "1" ]]; then
  if ! docker image inspect "$image" >/dev/null 2>&1; then
    echo "[reproduce] Docker image '$image' does not exist and --skip-build was set." >&2
    exit 1
  fi
elif [[ "$rebuild" == "1" ]]; then
  echo "[reproduce] rebuilding Docker image without layer cache"
  bash scripts/docker_build.sh
elif docker image inspect "$image" >/dev/null 2>&1; then
  echo "[reproduce] using existing Docker image $image"
else
  echo "[reproduce] Docker image $image not found; building it without layer cache"
  bash scripts/docker_build.sh
fi

if [[ "$skip_tool_smoke" != "1" ]]; then
  echo "[reproduce] checking Docker toolchain"
  bash scripts/docker_run.sh bash -lc '
    set -euo pipefail
    yosys -V
    sby --version
    verilator --version
    picker --version || picker -h >/tmp/picker.help
    iverilog -V >/tmp/iverilog.version
    conda run -n ucagent python -c "import ucagent, toffee, toffee_test, xspcomm; print(\"ucagent/toffee/xspcomm imports ok\")"
  '
fi

if [[ "$api" == "1" ]]; then
  echo "[reproduce] running real UCAgent API flow for case=$case_id"
  bash scripts/docker_run.sh bash scripts/run_cases.sh --case "$case_id" --"$mode"
else
  echo "[reproduce] running local smoke flow for case=$case_id"
  bash scripts/docker_run.sh bash scripts/run_cases.sh --case "$case_id" --"$mode" --smoke
fi

echo "[reproduce] completed case=$case_id api=$api"
