#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE="${FORMAL_DOCKER_IMAGE:-nutshell-cache-formal:latest}"

docker run --rm \
  --user "$(id -u):$(id -g)" \
  -v "$ROOT:/work" \
  -w /work \
  "$IMAGE" \
  bash scripts/24_run_three_case_formal.sh
