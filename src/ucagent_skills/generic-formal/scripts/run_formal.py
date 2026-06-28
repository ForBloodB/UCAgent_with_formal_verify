#!/usr/bin/env python3
import argparse
import json
import os
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

import yaml


def rel_to_workspace(path: Path, workspace: Path) -> str:
    return path.resolve().relative_to(workspace.resolve()).as_posix()


def resolve_path(value: str, workspace: Path) -> Path:
    p = Path(value)
    return p if p.is_absolute() else workspace / p


def load_case(case_path: Path) -> dict:
    with case_path.open("r", encoding="utf-8") as f:
        data = yaml.safe_load(f) or {}
    required = ["name", "expected"]
    missing = [k for k in required if k not in data]
    if missing:
        raise ValueError(f"missing required case fields: {', '.join(missing)}")
    if "sby" in data:
        if not str(data["sby"]).strip():
            raise ValueError("case field 'sby' must be a non-empty path")
    else:
        generated_required = ["top", "files", "depth"]
        missing = [k for k in generated_required if k not in data]
        if missing:
            raise ValueError(
                "missing required fields for generated SBY case: "
                + ", ".join(missing)
            )
        if not isinstance(data["files"], list) or not data["files"]:
            raise ValueError("case field 'files' must be a non-empty list")
    data["expected"] = str(data["expected"]).upper()
    if data["expected"] not in {"PASS", "FAIL", "TIMEOUT", "ERROR"}:
        raise ValueError("expected must be one of PASS/FAIL/TIMEOUT/ERROR")
    return data


def run_prepare_commands(case: dict, workspace: Path, log_dir: Path, timeout: int) -> str:
    commands = case.get("prepare", [])
    if isinstance(commands, str):
        commands = [commands]
    if not commands:
        return ""
    if not isinstance(commands, list) or not all(isinstance(cmd, str) for cmd in commands):
        raise ValueError("case field 'prepare' must be a string or list of strings")

    log_path = log_dir / f"{case['name']}_prepare.log"
    with log_path.open("w", encoding="utf-8", errors="replace") as log:
        for index, command in enumerate(commands, start=1):
            log.write(f"$ {command}\n\n")
            log.flush()
            try:
                proc = subprocess.run(
                    command,
                    cwd=workspace,
                    shell=True,
                    text=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    timeout=timeout,
                )
            except subprocess.TimeoutExpired as exc:
                output = exc.stdout or ""
                log.write(output)
                log.write(f"\n[TIMEOUT after {timeout} seconds]\n")
                raise RuntimeError(f"prepare command {index} timed out") from exc
            output = proc.stdout or ""
            log.write(output)
            log.write("\n")
            if proc.returncode != 0:
                raise RuntimeError(f"prepare command {index} failed with rc={proc.returncode}")
    return rel_to_workspace(log_path, workspace)


def write_sby(case: dict, case_path: Path, workspace: Path) -> Path:
    sby_path = case_path.with_suffix(".sby")
    file_paths = [resolve_path(str(f), workspace) for f in case["files"]]
    missing = [p for p in file_paths if not p.exists()]
    if missing:
        raise FileNotFoundError("missing formal input files: " + ", ".join(str(p) for p in missing))

    defines = case.get("defines", [])
    if isinstance(defines, str):
        defines = [defines]
    define_flags = " ".join(f"-D{str(d)}" for d in defines)

    read_lines = []
    for p in file_paths:
        read_lines.append(f"read_verilog -formal -sv {define_flags} {p.name}".strip())

    engines = case.get("engines", ["smtbmc z3"])
    if isinstance(engines, str):
        engines = [engines]

    content = []
    content += ["[options]", "mode bmc", f"depth {int(case['depth'])}", "append 0", ""]
    content += ["[engines]", *engines, ""]
    content += ["[script]", *read_lines, f"prep -top {case['top']}", ""]
    content += ["[files]"]
    content += [rel_to_workspace(p, workspace) for p in file_paths]
    content.append("")
    sby_path.write_text("\n".join(content), encoding="utf-8")
    return sby_path


def resolve_sby(case: dict, case_path: Path, workspace: Path) -> Path:
    if "sby" in case:
        sby_path = resolve_path(str(case["sby"]), workspace)
        if not sby_path.exists():
            raise FileNotFoundError(f"missing SBY file: {sby_path}")
        return sby_path
    return write_sby(case, case_path, workspace)


def build_command(sby_path: Path, workspace: Path) -> list[str]:
    sby_rel = rel_to_workspace(sby_path, workspace)
    if shutil.which("sby"):
        return ["sby", "-f", sby_rel]
    if shutil.which("docker"):
        return [
            "docker", "run", "--rm",
            "--user", f"{os.getuid()}:{os.getgid()}",
            "-v", f"{workspace}:/work",
            "-w", "/work",
            os.environ.get("FORMAL_DOCKER_IMAGE", "nutshell-cache-formal:latest"),
            "sby", "-f", sby_rel,
        ]
    raise RuntimeError("neither local sby nor docker is available")


def classify(returncode: int | None, output: str, timed_out: bool) -> str:
    if timed_out:
        return "TIMEOUT"
    if returncode == 0 and "DONE (PASS" in output:
        return "PASS"
    if "DONE (FAIL" in output or "BMC failed" in output or "Assert failed" in output:
        return "FAIL"
    if returncode == 0:
        return "PASS"
    return "ERROR"


def append_report(report_path: Path, row: dict) -> None:
    report_path.parent.mkdir(parents=True, exist_ok=True)
    if not report_path.exists():
        report_path.write_text(
            "# 通用 Formal Skill 报告\n\n"
            f"- 创建时间：{datetime.now(timezone.utc).isoformat()}\n\n"
            "| Case | Expected | Actual | Verdict | Depth | Log |\n"
            "| --- | --- | --- | --- | --- | --- |\n",
            encoding="utf-8",
        )
    with report_path.open("a", encoding="utf-8") as f:
        f.write(
            f"| `{row['name']}` | {row['expected']} | {row['actual']} | "
            f"{row['verdict']} | {row['depth']} | `{row['log']}` |\n"
        )


def mirror_report(report_path: Path, case: dict, workspace: Path) -> None:
    mirrors = case.get("mirror_report", [])
    if isinstance(mirrors, str):
        mirrors = [mirrors]
    if not mirrors:
        return
    if not isinstance(mirrors, list) or not all(isinstance(item, str) for item in mirrors):
        raise ValueError("case field 'mirror_report' must be a string or list of strings")
    for item in mirrors:
        dst = resolve_path(item, workspace)
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(report_path, dst)


def main() -> int:
    parser = argparse.ArgumentParser(description="Run one generic formal YAML case.")
    parser.add_argument("--case", required=True, help="Path to formal case YAML")
    parser.add_argument("--workspace", default=".", help="Workspace root")
    parser.add_argument("--timeout", type=int, default=300, help="Run timeout in seconds")
    args = parser.parse_args()

    workspace = Path(args.workspace).resolve()
    case_path = resolve_path(args.case, workspace).resolve()
    case = load_case(case_path)
    report = resolve_path(case.get("report", "reports/generic_formal/generic_formal.md"), workspace)
    log_dir = resolve_path(case.get("log_dir", "reports/generic_formal/logs"), workspace)
    result_dir = resolve_path(case.get("result_dir", "reports/generic_formal/results"), workspace)
    log_dir.mkdir(parents=True, exist_ok=True)
    result_dir.mkdir(parents=True, exist_ok=True)

    log_path = log_dir / f"{case['name']}.log"
    result_path = result_dir / f"{case['name']}.json"

    prepare_log = ""
    prepare_log_candidate = log_dir / f"{case['name']}_prepare.log"
    try:
        prepare_log = run_prepare_commands(case, workspace, log_dir, args.timeout)
        sby_path = resolve_sby(case, case_path, workspace)
    except Exception as exc:
        actual = "ERROR"
        verdict = "OK" if actual == case["expected"] else "UNEXPECTED"
        if prepare_log_candidate.exists():
            prepare_log = rel_to_workspace(prepare_log_candidate, workspace)
        log_path.write_text(
            "ERROR before SBY execution\n\n"
            f"{type(exc).__name__}: {exc}\n",
            encoding="utf-8",
            errors="replace",
        )
        row = {
            "name": case["name"],
            "expected": case["expected"],
            "actual": actual,
            "verdict": verdict,
            "depth": str(case.get("depth", "sby")),
            "log": rel_to_workspace(log_path, workspace),
            "sby": "",
            "prepare_log": prepare_log,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "command": [],
            "error": f"{type(exc).__name__}: {exc}",
        }
        result_path.write_text(json.dumps(row, indent=2), encoding="utf-8")
        append_report(report, row)
        mirror_report(report, case, workspace)
        print(json.dumps(row, indent=2))
        return 0 if verdict == "OK" else 1

    cmd = build_command(sby_path, workspace)
    timed_out = False
    try:
        proc = subprocess.run(
            cmd,
            cwd=workspace,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=args.timeout,
        )
        output = proc.stdout
        returncode = proc.returncode
    except subprocess.TimeoutExpired as exc:
        timed_out = True
        output = exc.stdout or ""
        returncode = None

    log_path.write_text("$ " + " ".join(cmd) + "\n\n" + output, encoding="utf-8", errors="replace")
    actual = classify(returncode, output, timed_out)
    verdict = "OK" if actual == case["expected"] else "UNEXPECTED"

    row = {
        "name": case["name"],
        "expected": case["expected"],
        "actual": actual,
        "verdict": verdict,
        "depth": str(case.get("depth", "sby")),
        "log": rel_to_workspace(log_path, workspace),
        "sby": rel_to_workspace(sby_path, workspace),
        "prepare_log": prepare_log,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "command": cmd,
    }
    result_path.write_text(json.dumps(row, indent=2), encoding="utf-8")
    append_report(report, row)
    mirror_report(report, case, workspace)

    print(json.dumps(row, indent=2))
    return 0 if verdict == "OK" else 1


if __name__ == "__main__":
    sys.exit(main())
