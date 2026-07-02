#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE="${UCAGENT_FORMAL_IMAGE:-ucagent-with-formal-verify:latest}"

cd "$ROOT"
cache_args=(--no-cache)
if [[ "${UCAGENT_FORMAL_DOCKER_CACHE:-0}" == "1" ]]; then
  cache_args=()
fi
if [[ "${UCAGENT_FORMAL_DOCKER_PULL:-0}" == "1" ]]; then
  cache_args+=(--pull)
fi

docker build \
  "${cache_args[@]}" \
  -f docker/repro.Dockerfile \
  -t "$IMAGE" \
  .

echo "[docker_build] built $IMAGE"
