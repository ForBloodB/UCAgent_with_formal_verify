#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: retry-git-clone.sh <repo-url> <destination> [extra git clone args...]" >&2
  exit 2
fi

repo="$1"
dest="$2"
shift 2

attempts="${RETRY_GIT_CLONE_ATTEMPTS:-5}"
delay="${RETRY_GIT_CLONE_DELAY:-8}"

for attempt in $(seq 1 "$attempts"); do
  rm -rf "$dest"
  echo "[retry-git-clone] attempt ${attempt}/${attempts}: $repo -> $dest"
  if git -c http.version=HTTP/1.1 clone "$@" "$repo" "$dest"; then
    exit 0
  fi
  if [[ "$attempt" == "$attempts" ]]; then
    break
  fi
  sleep "$delay"
done

echo "[retry-git-clone] failed after ${attempts} attempts: $repo" >&2
exit 1
