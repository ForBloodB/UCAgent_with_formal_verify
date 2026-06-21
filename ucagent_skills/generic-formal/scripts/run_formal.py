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
    required = ["name", "top", "files", "depth", "expected"]
    missing = [k for k in required if k not in data]
    if missing:
        raise ValueError(f"missing required case fields: {', '.join(missing)}")
    if not isinstance(data["files"], list) or not data["files"]:
        raise ValueError("case field 'files' must be a non-empty list")
    data["expected"] = str(data["expected"]).upper()
    if data["expected"] not in {"PASS", "FAIL", "TIMEOUT", "ERROR"}:
        raise ValueError("expected must be one of PASS/FAIL/TIMEOUT/ERROR")
    return data


def write_sby(case: dict, case_path: Path, workspace: Path) -> Path:
    sby_path = case_path.with_suffix(".sby")
    file_paths = [resolve_path(str(f), workspace) for f in case["files"]]
    missing = [p for p in file_paths if not p.exists()]
    if missing:
        raise FileNotFoundError("missing formal input files: " + ", ".join(str(p) for p in missing))

    read_lines = []
    for p in file_paths:
        read_lines.append(f"read_verilog -formal -sv {p.name}")

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
            "# Generic Formal Skill Smoke Report\n\n"
            f"- Created: {datetime.now(timezone.utc).isoformat()}\n\n"
            "| Case | Expected | Actual | Verdict | Depth | Log |\n"
            "| --- | --- | --- | --- | --- | --- |\n",
            encoding="utf-8",
        )
    with report_path.open("a", encoding="utf-8") as f:
        f.write(
            f"| `{row['name']}` | {row['expected']} | {row['actual']} | "
            f"{row['verdict']} | {row['depth']} | `{row['log']}` |\n"
        )


def main() -> int:
    parser = argparse.ArgumentParser(description="Run one generic formal YAML case.")
    parser.add_argument("--case", required=True, help="Path to formal case YAML")
    parser.add_argument("--workspace", default=".", help="Workspace root")
    parser.add_argument("--timeout", type=int, default=300, help="Run timeout in seconds")
    args = parser.parse_args()

    workspace = Path(args.workspace).resolve()
    case_path = resolve_path(args.case, workspace).resolve()
    case = load_case(case_path)
    sby_path = write_sby(case, case_path, workspace)

    report = resolve_path(case.get("report", "reports/generic_formal/generic_formal.md"), workspace)
    log_dir = resolve_path(case.get("log_dir", "reports/generic_formal/logs"), workspace)
    result_dir = resolve_path(case.get("result_dir", "reports/generic_formal/results"), workspace)
    log_dir.mkdir(parents=True, exist_ok=True)
    result_dir.mkdir(parents=True, exist_ok=True)
    log_path = log_dir / f"{case['name']}.log"
    result_path = result_dir / f"{case['name']}.json"

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
        "depth": int(case["depth"]),
        "log": rel_to_workspace(log_path, workspace),
        "sby": rel_to_workspace(sby_path, workspace),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "command": cmd,
    }
    result_path.write_text(json.dumps(row, indent=2), encoding="utf-8")
    append_report(report, row)

    print(json.dumps(row, indent=2))
    return 0 if verdict == "OK" else 1


if __name__ == "__main__":
    sys.exit(main())
