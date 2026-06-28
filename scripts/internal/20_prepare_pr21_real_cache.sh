#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FORMAL_DIR="$ROOT/tests/cases/02_pr21_mmio_prefetch/formal"
WORK_ROOT="$ROOT/third_party/nutshell_pr21_real"
BIN_DIR="$ROOT/third_party/bin"

PRE_COMMIT="bd425deedff4e896fca59895b34d778f2c8724d9"
FIXED_COMMIT="f0d7c49411197047dc8464addfacc0fcba5b9e45"
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
    echo "[pr21-real] downloading mill $MILL_VERSION to $mill_bin" >&2
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

  if [ -f "$dst/.pr21_real_commit" ] && grep -qx "$commit" "$dst/.pr21_real_commit"; then
    return
  fi

  rm -rf "$dst"
  mkdir -p "$dst"
  echo "[pr21-real] fetching NutShell $name commit $commit"
  curl -L --fail --retry 3 "https://github.com/OSCPU/NutShell/archive/${commit}.tar.gz" |
    tar -xz -C "$dst" --strip-components=1
  echo "$commit" > "$dst/.pr21_real_commit"
}

install_wrapper() {
  local dst="$1"
  cp "$FORMAL_DIR/Pr21CacheFormalDut.scala" "$dst/src/main/scala/top/Pr21CacheFormalDut.scala"

  if ! grep -q "pr21_cache_s2_out_valid" "$dst/src/main/scala/nutcore/Cache.scala"; then
    perl -0pi -e 's@(  PipelineConnect\(s2\.io\.out, s3\.io\.in, s3\.io\.isFinish, [^\n]*\n)@$1
  BoringUtils.addSource(s2.io.out.valid, "pr21_cache_s2_out_valid")
  BoringUtils.addSource(s2.io.out.bits.mmio, "pr21_cache_s2_out_mmio")
  BoringUtils.addSource(s2.io.out.bits.req.isPrefetch(), "pr21_cache_s2_out_prefetch")
  BoringUtils.addSource(s3.io.in.valid, "pr21_cache_s3_in_valid")
  BoringUtils.addSource(s3.io.in.bits.req.isPrefetch(), "pr21_cache_s3_in_prefetch")
@s' "$dst/src/main/scala/nutcore/Cache.scala"
    grep -q "pr21_cache_s2_out_valid" "$dst/src/main/scala/nutcore/Cache.scala" || {
      echo "[pr21-real] failed to instrument Cache.scala" >&2
      exit 1
    }
  fi
}

patch_build_sc() {
  local dst="$1"
  local build_sc="$dst/build.sc"

  if ! grep -q "repositoriesTask" "$build_sc"; then
    perl -0pi -e 's@object CustomZincWorkerModule extends ZincWorkerModule \{\n  def repositories\(\) = super\.repositories \+\+ Seq\((.*?)\)\s*\n\}@object CustomZincWorkerModule extends ZincWorkerModule with CoursierModule {\n  def repositoriesTask = T.task { super.repositoriesTask() ++ Seq($1) }\n}@s' "$build_sc"
  fi

  perl -0pi -e 's@def zincWorker = ModuleRef\(CustomZincWorkerModule\)@def zincWorker = CustomZincWorkerModule@g' "$build_sc"
}

generate_variant() {
  local name="$1"
  local commit="$2"
  local out_name="$3"
  local dst="$WORK_ROOT/$name"
  local mill_cmd

  fetch_nutshell "$name" "$commit"
  install_wrapper "$dst"
  patch_build_sc "$dst"
  mill_cmd="$(download_mill)"

  echo "[pr21-real] generating $out_name from NutShell $commit"
  (
    cd "$dst"
    "$mill_cmd" chiselModule.runMain top.Pr21CacheFormalMain \
      -td "$FORMAL_DIR/generated/$out_name" \
      --output-file Pr21CacheFormalDut.v
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
