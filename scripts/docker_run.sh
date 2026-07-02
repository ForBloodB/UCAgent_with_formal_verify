#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE="${UCAGENT_FORMAL_IMAGE:-ucagent-with-formal-verify:latest}"
THIRD_PARTY_VOLUME="${UCAGENT_FORMAL_THIRD_PARTY_VOLUME:-ucagent_formal_verify_third_party}"

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  bash "$ROOT/scripts/docker_build.sh"
fi

env_args=()
if [[ -f "$ROOT/.ucagent_env" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$ROOT/.ucagent_env"
  set +a
fi

for name in \
  OPENAI_API_BASE \
  OPENAI_BASE_URL \
  OPENAI_API_KEY \
  OPENAI_MODEL \
  OPENAI_API_VERSION \
  ANTHROPIC_API_KEY \
  LANGFUSE_PUBLIC_KEY \
  LANGFUSE_SECRET_KEY \
  LANGFUSE_HOST \
  UCAGENT_BACKEND; do
  if [[ -n "${!name:-}" ]]; then
    env_args+=(--env "$name")
  fi
done

cmd=("$@")
if [[ ${#cmd[@]} -eq 0 ]]; then
  cmd=(bash)
fi

tty_args=()
if [[ -t 0 && -t 1 ]]; then
  tty_args=(-it)
fi

exec docker run --rm "${tty_args[@]}" \
  --env HOME=/tmp \
  --env LOCAL_UID="$(id -u)" \
  --env LOCAL_GID="$(id -g)" \
  --env NUTSHELL_CACHE_VERIFY_ROOT=/work \
  --mount type=bind,source="$ROOT",target=/work \
  --mount type=volume,source="$THIRD_PARTY_VOLUME",target=/work/third_party \
  --workdir /work \
  "${env_args[@]}" \
  "$IMAGE" \
  "${cmd[@]}"
