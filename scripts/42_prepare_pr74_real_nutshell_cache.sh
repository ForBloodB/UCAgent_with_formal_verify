#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FORMAL_DIR="$ROOT/formal/nutshell_pr74_real"
WORK_ROOT="$ROOT/third_party/nutshell_pr74_real"
BIN_DIR="$ROOT/third_party/bin"

PRE_COMMIT="4b656f32aea0687fe8c823b99a54dc76517c3a41"
FIXED_COMMIT="287c5e02490aca73055211bd04908917d71deaf7"
DIFFTEST_COMMIT="3f20bf7877b9c2c000f78a49c68f5384914560ad"
MILL_VERSION="${MILL_VERSION:-0.9.12}"

variant="${1:-all}"

mkdir -p "$WORK_ROOT" "$BIN_DIR" "$FORMAL_DIR/generated/pre" "$FORMAL_DIR/generated/fixed"

download_mill() {
  if command -v mill >/dev/null 2>&1; then
    echo "mill"
    return
  fi

  local mill_bin="$BIN_DIR/mill-$MILL_VERSION"
  if [ ! -x "$mill_bin" ]; then
    echo "[pr74-real] downloading mill $MILL_VERSION to $mill_bin" >&2
    curl -L --fail --retry 3 -o "$mill_bin" \
      "https://github.com/com-lihaoyi/mill/releases/download/${MILL_VERSION}/${MILL_VERSION}"
    chmod +x "$mill_bin"
  fi
  echo "$mill_bin"
}

fetch_nutshell() {
  local name="$1"
  local commit="$2"
  local dst="$WORK_ROOT/$name"

  if [ -f "$dst/.pr74_real_commit" ] &&
     grep -qx "$commit" "$dst/.pr74_real_commit" &&
     [ -f "$dst/.pr74_real_difftest_commit" ] &&
     grep -qx "$DIFFTEST_COMMIT" "$dst/.pr74_real_difftest_commit" &&
     [ -d "$dst/difftest/src" ]; then
    return
  fi

  rm -rf "$dst"
  mkdir -p "$dst"
  echo "[pr74-real] fetching NutShell $name commit $commit"
  curl -L --fail --retry 3 "https://github.com/OSCPU/NutShell/archive/${commit}.tar.gz" |
    tar -xz -C "$dst" --strip-components=1

  rm -rf "$dst/difftest"
  mkdir -p "$dst/difftest"
  echo "[pr74-real] fetching difftest submodule commit $DIFFTEST_COMMIT"
  curl -L --fail --retry 3 "https://github.com/AugustusWillisWang/difftest/archive/${DIFFTEST_COMMIT}.tar.gz" |
    tar -xz -C "$dst/difftest" --strip-components=1

  echo "$commit" > "$dst/.pr74_real_commit"
  echo "$DIFFTEST_COMMIT" > "$dst/.pr74_real_difftest_commit"
}

install_wrapper() {
  local dst="$1"
  mkdir -p "$dst/src/main/scala/top"
  cp "$FORMAL_DIR/Pr74CacheIOFormalDut.scala" "$dst/src/main/scala/top/Pr74CacheIOFormalDut.scala"
}

generate_variant() {
  local name="$1"
  local commit="$2"
  local out_name="$3"
  local dst="$WORK_ROOT/$name"
  local mill_cmd

  fetch_nutshell "$name" "$commit"
  install_wrapper "$dst"
  mill_cmd="$(download_mill)"

  rm -rf "$FORMAL_DIR/generated/$out_name"
  mkdir -p "$FORMAL_DIR/generated/$out_name"

  echo "[pr74-real] generating $out_name from NutShell $commit"
  (
    cd "$dst"
    "$mill_cmd" chiselModule.runMain top.Pr74CacheIOFormalMain \
      -td "$FORMAL_DIR/generated/$out_name" \
      --output-file Pr74CacheIOFormalDut.v
  )
}

case "$variant" in
  pre)
    generate_variant pre "$PRE_COMMIT" pre
    ;;
  fixed)
    generate_variant fixed "$FIXED_COMMIT" fixed
    ;;
  all)
    generate_variant pre "$PRE_COMMIT" pre
    generate_variant fixed "$FIXED_COMMIT" fixed
    ;;
  *)
    echo "usage: $0 [pre|fixed|all]" >&2
    exit 2
    ;;
esac
