#!/usr/bin/env bash
set -euo pipefail

if [[ -d /work ]]; then
  mkdir -p /work/third_party/bin

  for name in UCAgent Example-NutShellCache picker; do
    target="/work/third_party/${name}"
    if [[ -L "$target" && ! -e "$target" ]]; then
      rm -f "$target"
    fi
    if [[ ! -e "$target" ]]; then
      ln -s "/opt/toolchain/${name}" "$target"
    fi
  done

  for version in 0.9.12 0.11.12; do
    target="/work/third_party/bin/mill-${version}"
    if [[ -L "$target" && ! -e "$target" ]]; then
      rm -f "$target"
    fi
    if [[ ! -e "$target" ]]; then
      ln -s "/opt/toolchain/bin/mill-${version}" "$target"
    fi
  done

  if [[ -n "${LOCAL_UID:-}" && -n "${LOCAL_GID:-}" ]]; then
    chown -h "${LOCAL_UID}:${LOCAL_GID}" /work/third_party || true
    find /work/third_party -maxdepth 1 -mindepth 1 -exec chown -h "${LOCAL_UID}:${LOCAL_GID}" {} + || true
    chown -h "${LOCAL_UID}:${LOCAL_GID}" /work/third_party/bin || true
    find /work/third_party/bin -maxdepth 1 -mindepth 1 -exec chown -h "${LOCAL_UID}:${LOCAL_GID}" {} + || true
  fi
fi

if [[ "$(id -u)" == "0" && -n "${LOCAL_UID:-}" && -n "${LOCAL_GID:-}" ]]; then
  export HOME=/tmp
  exec gosu "${LOCAL_UID}:${LOCAL_GID}" "$@"
fi

exec "$@"
