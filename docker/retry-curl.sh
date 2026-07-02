#!/usr/bin/env bash
set -euo pipefail

attempts="${RETRY_CURL_ATTEMPTS:-5}"
delay="${RETRY_CURL_DELAY:-8}"

if [[ $# -eq 0 ]]; then
  echo "usage: retry-curl.sh <curl args...>" >&2
  exit 2
fi

for attempt in $(seq 1 "$attempts"); do
  echo "[retry-curl] attempt ${attempt}/${attempts}: curl $*"
  if curl --retry 5 --retry-all-errors --connect-timeout 60 "$@"; then
    exit 0
  fi
  if [[ "$attempt" == "$attempts" ]]; then
    break
  fi
  sleep "$delay"
done

echo "[retry-curl] failed after ${attempts} attempts: curl $*" >&2
exit 1
