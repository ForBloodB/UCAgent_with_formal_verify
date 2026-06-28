#!/usr/bin/env python3
import argparse
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path


NUTSHELL_URL = "https://github.com/OSCPU/NutShell"
LATEST_MILL_VERSION = os.environ.get("MILL_VERSION_LATEST", "0.11.12")
GENERATOR_VERSION = "2026-06-22-l2-readburst-deadlock-v1"


WRAPPER = r'''package top

import chisel3._
import chisel3.util._
import chisel3.util.experimental.BoringUtils
import chisel3.stage.ChiselGeneratorAnnotation
import _root_.circt.stage._

import bus.simplebus._
import nutcore._

class FreshCacheFormalDut extends Module {
  val io = IO(new Bundle {
    val flush = Input(UInt(2.W))

    val cpu_req_valid = Input(Bool())
    val cpu_req_ready = Output(Bool())
    val cpu_req_addr = Input(UInt(32.W))
    val cpu_req_cmd = Input(UInt(4.W))
    val cpu_resp_valid = Output(Bool())
    val cpu_resp_ready = Input(Bool())
    val cpu_resp_cmd = Output(UInt(4.W))

    val mem_req_valid = Output(Bool())
    val mem_req_ready = Input(Bool())
    val mem_req_cmd = Output(UInt(4.W))
    val mem_resp_valid = Input(Bool())
    val mem_resp_cmd = Input(UInt(4.W))

    val fresh_s3_in_valid = Output(Bool())
    val fresh_s3_in_hit = Output(Bool())
    val fresh_s3_in_readburst = Output(Bool())
    val fresh_data_read_resp_to_l1 = Output(Bool())
    val fresh_s3_out_valid = Output(Bool())
  })

  val in = Wire(new SimpleBusUC())
  val mmio = Wire(new SimpleBusUC())
  val empty = Wire(Bool())

  implicit val cacheConfig = CacheConfig(
    name = "l2cache",
    totalSize = 1,
    ways = 4,
    cacheLevel = 2
  )
  val cacheOut = Cache(in = in, mmio = Seq(mmio), flush = io.flush, empty = empty, enable = true)

  in.req.valid := io.cpu_req_valid
  io.cpu_req_ready := in.req.ready
  in.req.bits.apply(
    addr = io.cpu_req_addr,
    cmd = io.cpu_req_cmd,
    size = "b011".U,
    wdata = 0.U,
    wmask = Fill(8, 1.U)
  )
  io.cpu_resp_valid := in.resp.valid
  in.resp.ready := io.cpu_resp_ready
  io.cpu_resp_cmd := in.resp.bits.cmd

  io.mem_req_valid := cacheOut.mem.req.valid
  cacheOut.mem.req.ready := io.mem_req_ready
  io.mem_req_cmd := cacheOut.mem.req.bits.cmd
  cacheOut.mem.resp.valid := io.mem_resp_valid
  cacheOut.mem.resp.bits.cmd := io.mem_resp_cmd
  cacheOut.mem.resp.bits.rdata := 0.U

  mmio.req.ready := true.B
  mmio.resp.valid := false.B
  mmio.resp.bits.cmd := SimpleBusCmd.readLast
  mmio.resp.bits.rdata := 0.U

  cacheOut.coh.req.valid := false.B
  cacheOut.coh.req.bits := 0.U.asTypeOf(cacheOut.coh.req.bits)
  cacheOut.coh.resp.ready := true.B

  val s3InValid = WireInit(false.B)
  val s3InHit = WireInit(false.B)
  val s3InReadBurst = WireInit(false.B)
  val dataReadRespToL1 = WireInit(false.B)
  val s3OutValid = WireInit(false.B)
  BoringUtils.addSink(s3InValid, "fresh_s3_in_valid")
  BoringUtils.addSink(s3InHit, "fresh_s3_in_hit")
  BoringUtils.addSink(s3InReadBurst, "fresh_s3_in_readburst")
  BoringUtils.addSink(dataReadRespToL1, "fresh_data_read_resp_to_l1")
  BoringUtils.addSink(s3OutValid, "fresh_s3_out_valid")

  io.fresh_s3_in_valid := s3InValid
  io.fresh_s3_in_hit := s3InHit
  io.fresh_s3_in_readburst := s3InReadBurst
  io.fresh_data_read_resp_to_l1 := dataReadRespToL1
  io.fresh_s3_out_valid := s3OutValid
}

object FreshCacheFormalMain extends App {
  Settings.settings += ("HasL2cache" -> true)
  Settings.settings += ("HasPrefetch" -> true)
  Settings.settings += ("HasDcache" -> true)
  Settings.settings += ("HasIcache" -> true)
  Settings.settings += ("HasDTLB" -> true)
  Settings.settings += ("HasITLB" -> true)
  Settings.settings += ("IsRV32" -> false)
  Settings.settings += ("EnableOutOfOrderExec" -> false)

  (new ChiselStage).execute(args, Seq(
    ChiselGeneratorAnnotation(() => new FreshCacheFormalDut),
    CIRCTTargetAnnotation(CIRCTTarget.SystemVerilog),
    FirtoolOption("--disable-annotation-unknown"),
    FirtoolOption("--lowering-options=disallowLocalVariables"),
    FirtoolOption("--default-layer-specialization=enable")
  ))
}
'''


def run(cmd: list[str], cwd: Path, log_path: Path, timeout: int) -> tuple[int | None, str, bool]:
    log_path.parent.mkdir(parents=True, exist_ok=True)
    with log_path.open("w", encoding="utf-8", errors="replace") as log:
        log.write("$ " + " ".join(str(x) for x in cmd) + "\n\n")
        log.flush()
        try:
            proc = subprocess.run(
                [str(x) for x in cmd],
                cwd=cwd,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                timeout=timeout,
            )
            output = proc.stdout or ""
            log.write(output)
            return proc.returncode, output, False
        except subprocess.TimeoutExpired as exc:
            output = exc.stdout or ""
            log.write(output)
            log.write(f"\n[TIMEOUT after {timeout} seconds]\n")
            return None, output, True


def find_repo_root(start: Path) -> Path:
    for path in [start.resolve(), *start.resolve().parents]:
        if (path / "src/ucagent_skills/generic-formal/SKILL.md").exists():
            return path
    raise FileNotFoundError("cannot find NutShellCacheVerify repository root")


def latest_commit(root: Path, log_dir: Path, timeout: int) -> str:
    rc, output, timed_out = run(
        ["git", "ls-remote", f"{NUTSHELL_URL}.git", "HEAD"],
        root,
        log_dir / "latest_ls_remote.log",
        min(timeout, 120),
    )
    checkout = root / "third_party/nutshell_l2_readburst_deadlock/latest"
    marker = checkout / ".l2_readburst_commit"
    if timed_out or rc != 0:
        if marker.exists():
            return marker.read_text(encoding="utf-8").strip()
        if (checkout / ".git").exists():
            proc = subprocess.run(
                ["git", "-C", str(checkout), "rev-parse", "HEAD"],
                cwd=root,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
            )
            if proc.returncode == 0 and proc.stdout.strip():
                return proc.stdout.strip()
        raise RuntimeError("failed to query OSCPU/NutShell HEAD")
    return output.strip().split()[0]


def fetch_latest(root: Path, commit: str, log_dir: Path, timeout: int, force: bool) -> Path:
    dst = root / "third_party/nutshell_l2_readburst_deadlock/latest"
    marker = dst / ".l2_readburst_commit"
    has_submodules = (dst / ".git").exists() and any((dst / "difftest").glob("**/*.scala"))
    if not force and marker.exists() and marker.read_text(encoding="utf-8").strip() == commit and has_submodules:
        return dst
    if dst.exists():
        shutil.rmtree(dst)
    rc, _, timed_out = run(
        [
            "git", "clone",
            "--depth", "1",
            "--recurse-submodules",
            "--shallow-submodules",
            f"{NUTSHELL_URL}.git",
            str(dst),
        ],
        root,
        log_dir / "latest_fetch.log",
        timeout,
    )
    if timed_out or rc != 0:
        raise RuntimeError("failed to clone latest NutShell source")
    rc, _, timed_out = run(
        ["git", "-C", str(dst), "checkout", commit],
        root,
        log_dir / "latest_checkout.log",
        min(timeout, 120),
    )
    if timed_out or rc != 0:
        raise RuntimeError("failed to checkout latest NutShell commit")
    rc, _, timed_out = run(
        ["git", "-C", str(dst), "submodule", "update", "--init", "--recursive", "--depth", "1"],
        root,
        log_dir / "latest_submodule.log",
        timeout,
    )
    if timed_out or rc != 0:
        raise RuntimeError("failed to update latest NutShell submodules")
    marker.write_text(commit + "\n", encoding="utf-8")
    return dst


def cache_file(repo: Path) -> Path:
    for path in [
        repo / "src/main/scala/nutcore/mem/Cache.scala",
        repo / "src/main/scala/nutcore/Cache.scala",
    ]:
        if path.exists():
            return path
    raise FileNotFoundError("cannot find NutShell Cache.scala")


def instrument_cache(repo: Path) -> None:
    path = cache_file(repo)
    text = path.read_text(encoding="utf-8")
    if "freshS3InValid" in text:
        return
    probe = (
        '  val freshS3InValid = WireInit(s3.io.in.valid)\n'
        '  val freshS3InHit = WireInit(s3.io.in.bits.hit)\n'
        '  val freshS3InReadBurst = WireInit(s3.io.in.bits.req.isReadBurst())\n'
        '  val freshDataReadRespToL1 = WireInit(s3.io.dataReadRespToL1)\n'
        '  val freshS3OutValid = WireInit(s3.io.out.valid)\n'
        '  BoringUtils.addSource(freshS3InValid, "fresh_s3_in_valid")\n'
        '  BoringUtils.addSource(freshS3InHit, "fresh_s3_in_hit")\n'
        '  BoringUtils.addSource(freshS3InReadBurst, "fresh_s3_in_readburst")\n'
        '  BoringUtils.addSource(freshDataReadRespToL1, "fresh_data_read_resp_to_l1")\n'
        '  BoringUtils.addSource(freshS3OutValid, "fresh_s3_out_valid")\n'
    )
    pattern = re.compile(r"(  PipelineConnect\(s2\.io\.out, s3\.io\.in, s3\.io\.isFinish, [^\n]*\n)")
    new_text, count = pattern.subn(r"\1" + probe, text, count=1)
    if count != 1:
        raise RuntimeError(f"failed to instrument {path}")
    path.write_text(new_text, encoding="utf-8")


def install_wrapper(repo: Path) -> None:
    dst = repo / "src/test/scala/FreshCacheFormalDut.scala"
    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.write_text(WRAPPER, encoding="utf-8")


def mill_command(root: Path) -> str:
    mill = shutil.which("mill")
    if mill:
        return mill
    mill_bin = root / "third_party/bin" / f"mill-{LATEST_MILL_VERSION}"
    if mill_bin.exists() and os.access(mill_bin, os.X_OK):
        return str(mill_bin)
    mill_bin.parent.mkdir(parents=True, exist_ok=True)
    url = f"https://github.com/com-lihaoyi/mill/releases/download/{LATEST_MILL_VERSION}/{LATEST_MILL_VERSION}"
    subprocess.run(["curl", "-L", "--fail", "--retry", "3", "-o", str(mill_bin), url], check=True)
    mill_bin.chmod(0o755)
    return str(mill_bin)


def generate_latest(root: Path, repo: Path, commit: str, log_dir: Path, timeout: int, force: bool) -> Path:
    out_dir = root / "tests/cases/04_l2_readburst_hit_ready_valid_deadlock/formal/generated/latest"
    out_file = out_dir / "FreshCacheFormalDut.sv"
    marker = out_dir / ".l2_readburst_generator_version"
    if (
        not force
        and out_file.exists()
        and marker.exists()
        and marker.read_text(encoding="utf-8").strip() == GENERATOR_VERSION
    ):
        return out_file
    if out_dir.exists():
        shutil.rmtree(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    instrument_cache(repo)
    install_wrapper(repo)
    rc, _, timed_out = run(
        [
            mill_command(root), "-i", "generator.test.runMain", "top.FreshCacheFormalMain",
            "--target-dir", str(out_dir),
        ],
        repo,
        log_dir / "latest_generate.log",
        timeout,
    )
    if timed_out or rc != 0 or not out_file.exists():
        raise RuntimeError("latest NutShell l2 readBurst formal wrapper generation failed")
    marker.write_text(GENERATOR_VERSION + "\n", encoding="utf-8")
    (out_dir / "source_commit.txt").write_text(commit + "\n", encoding="utf-8")
    return out_file


def main() -> int:
    parser = argparse.ArgumentParser(description="Prepare latest NutShell L2 readBurst formal RTL.")
    parser.add_argument("--repo-root", default="", help="Repository root. Defaults to searching upward from cwd.")
    parser.add_argument("--timeout", type=int, default=900)
    parser.add_argument("--force-prepare", action="store_true")
    args = parser.parse_args()

    root = Path(args.repo_root).resolve() if args.repo_root else find_repo_root(Path.cwd())
    log_dir = root / "reports/artifacts/04_l2_readburst/logs"
    log_dir.mkdir(parents=True, exist_ok=True)

    commit = latest_commit(root, log_dir, args.timeout)
    repo = fetch_latest(root, commit, log_dir, args.timeout, args.force_prepare)
    out_file = generate_latest(root, repo, commit, log_dir, args.timeout, args.force_prepare)
    print(f"prepared={out_file.relative_to(root).as_posix()}")
    print(f"commit={commit}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
