#!/usr/bin/env python3
"""Generic Verilog/SystemVerilog verification entrypoint.

This tool intentionally provides two levels:
- parse/elaboration smoke for arbitrary RTL;
- optional property-based formal run when a harness/property is supplied.
"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

import yaml


def repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def rel(path: Path, root: Path) -> str:
    return path.resolve().relative_to(root.resolve()).as_posix()


def run(cmd: list[str], cwd: Path, timeout: int) -> tuple[int, str]:
    proc = subprocess.run(
        cmd,
        cwd=cwd,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        timeout=timeout,
    )
    return proc.returncode, proc.stdout or ""


def define_flags(defines: list[str]) -> str:
    return " ".join(f"-D{define}" for define in defines)


def read_verilog_commands(files: list[Path], defines: list[str]) -> str:
    flags = define_flags(defines)
    return " ; ".join(f"read_verilog -sv {flags} {p}".strip() for p in files)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Verify an arbitrary Verilog/SystemVerilog module."
    )
    parser.add_argument("--rtl", nargs="+", required=True, help="RTL file(s).")
    parser.add_argument("--top", required=True, help="Top module for lint/smoke.")
    parser.add_argument("--clock", default="", help="Optional clock signal name.")
    parser.add_argument("--reset", default="", help="Optional reset signal name.")
    parser.add_argument(
        "--property",
        default="",
        help="Optional formal property/harness file. If provided, --top is the formal top.",
    )
    parser.add_argument(
        "--define",
        action="append",
        default=[],
        help="SystemVerilog preprocessor define. Repeat for multiple defines.",
    )
    parser.add_argument("--depth", type=int, default=8, help="BMC depth.")
    parser.add_argument("--timeout", type=int, default=300, help="Command timeout.")
    parser.add_argument(
        "--smoke",
        action="store_true",
        help="Local-only mode. This tool never calls LLM/API itself.",
    )
    return parser.parse_args()


def verilog_decl(kind: str, name: str, width: int) -> str:
    vector = "" if width <= 1 else f" [{width - 1}:0]"
    return f"  {kind}{vector} {name};"


def verilog_decl_init(kind: str, name: str, width: int, value: str) -> str:
    vector = "" if width <= 1 else f" [{width - 1}:0]"
    return f"  {kind}{vector} {name} = {value};"


def extract_ports(
    rtl_files: list[Path],
    top: str,
    root: Path,
    out_dir: Path,
    defines: list[str],
    timeout: int,
) -> list[dict[str, object]]:
    json_path = out_dir / "yosys_ports.json"
    log_path = out_dir / "logs" / "yosys_ports.log"
    read_cmd = read_verilog_commands(rtl_files, defines)
    script = f"{read_cmd}; hierarchy -check -top {top}; proc; write_json {json_path}"
    cmd = ["yosys", "-p", script]
    rc, out = run(cmd, root, timeout)
    log_path.write_text("$ " + " ".join(cmd) + "\n\n" + out, encoding="utf-8")
    if rc != 0:
        raise RuntimeError(f"Yosys port extraction failed; see {rel(log_path, root)}")

    data = json.loads(json_path.read_text(encoding="utf-8"))
    modules = data.get("modules", {})
    module = modules.get(top) or modules.get("\\" + top)
    if not module:
        raise RuntimeError(f"Top module {top!r} not found in Yosys JSON")

    ports: list[dict[str, object]] = []
    for raw_name, info in module.get("ports", {}).items():
        name = raw_name[1:] if raw_name.startswith("\\") else raw_name
        direction = info.get("direction", "input")
        width = len(info.get("bits", [])) or 1
        if not name.replace("_", "").isalnum() or name[0].isdigit():
            raise RuntimeError(
                f"Auto smoke does not support escaped or complex port name {raw_name!r}; "
                "provide --property with a hand-written harness."
            )
        ports.append({"name": name, "direction": direction, "width": width})
    return ports


def write_auto_harness(
    path: Path,
    top: str,
    ports: list[dict[str, object]],
    clock: str,
    reset: str,
    depth: int,
) -> str:
    # Keep the auto harness conservative: instantiate the DUT, drive unconstrained
    # inputs, and cover bounded progress. Functional correctness still needs
    # user-provided properties.
    module_name = f"{top}_auto_smoke_formal"
    port_names = [str(port["name"]) for port in ports]
    clock_is_port = bool(clock and clock in port_names)
    reset_is_port = bool(reset and reset in port_names)
    text = [
        "`default_nettype none",
        f"module {module_name};",
        "  reg [7:0] __cycle = 8'd0;",
    ]
    if clock and not clock_is_port:
        text.append(verilog_decl_init("reg", clock, 1, "1'b0"))

    for port in ports:
        name = str(port["name"])
        direction = str(port["direction"])
        width = int(port["width"])
        if direction == "input":
            if name == clock:
                text.append(verilog_decl_init("reg", name, width, "1'b0"))
            elif name == reset:
                vector = "" if width <= 1 else f" [{width - 1}:0]"
                text.append(f"  wire{vector} {name} = {{ {width}{{(__cycle < 8'd2)}} }};")
            else:
                text.append(f"  (* anyseq *) {verilog_decl('reg', name, width).strip()}")
        elif direction == "output":
            text.append(verilog_decl("wire", name, width))
        else:
            text.append(verilog_decl("wire", name, width))

    if reset and not reset_is_port:
        text.append(f"  wire {reset} = (__cycle < 8'd2);")

    connections = ",\n".join(f"    .{name}({name})" for name in port_names)
    text.append("")
    text.append(f"  {top} dut (")
    text.append(connections)
    text.append("  );")
    text.append("")
    text.append("  // Auto smoke harness: instantiate real DUT ports and cover bounded progress.")
    text.append("  // Provide --property for functional verification of real behavior.")
    if clock:
        text.append(f"  always #1 {clock} = !{clock};")
        text.append(f"  always @(posedge {clock}) __cycle <= __cycle + 8'd1;")
    else:
        text.append("  always @* begin")
        text.append("    cover (1'b1);")
        text.append("  end")
    if clock:
        if reset:
            text.append(f"  always @(posedge {clock}) begin")
            text.append(f"    if (!{reset}) cover (__cycle == 8'd%d);" % max(depth - 1, 1))
            text.append("  end")
        else:
            text.append(f"  always @(posedge {clock}) begin")
            text.append("    cover (__cycle == 8'd%d);" % max(depth - 1, 1))
            text.append("  end")
    text.extend(["endmodule", "`default_nettype wire", ""])
    path.write_text("\n".join(text), encoding="utf-8")
    return module_name


def main() -> int:
    args = parse_args()
    root = repo_root()
    rtl_files = [(root / p).resolve() if not Path(p).is_absolute() else Path(p) for p in args.rtl]
    missing = [str(p) for p in rtl_files if not p.exists()]
    if missing:
        print("Missing RTL file(s): " + ", ".join(missing), file=sys.stderr)
        return 2

    out_dir = root / "reports" / "generic_verilog" / args.top
    log_dir = out_dir / "logs"
    result_dir = out_dir / "results"
    log_dir.mkdir(parents=True, exist_ok=True)
    result_dir.mkdir(parents=True, exist_ok=True)

    yosys_log = log_dir / "yosys_lint.log"
    prop = None
    verification_files = list(rtl_files)
    if args.property:
        prop = (root / args.property).resolve() if not Path(args.property).is_absolute() else Path(args.property)
        if not prop.exists():
            print(f"Missing property file: {prop}", file=sys.stderr)
            return 2
        verification_files.append(prop)

    yosys_cmd = ["yosys", "-p"]
    read_cmd = read_verilog_commands(verification_files, args.define)
    yosys_script = f"{read_cmd}; hierarchy -check -top {args.top}; proc; check"
    yosys_cmd.append(yosys_script)

    if not shutil.which("yosys"):
        yosys_rc, yosys_out = 127, "yosys not found\n"
    else:
        yosys_rc, yosys_out = run(yosys_cmd, root, args.timeout)
    yosys_log.write_text("$ " + " ".join(yosys_cmd) + "\n\n" + yosys_out, encoding="utf-8")

    formal_actual = "SKIPPED"
    formal_verdict = "SKIPPED"
    case_yaml = out_dir / "auto_formal.yaml"

    if prop:
        files = [rel(p, root) for p in rtl_files] + [rel(prop, root)]
        formal_top = args.top
        expected = "PASS"
    else:
        try:
            ports = extract_ports(rtl_files, args.top, root, out_dir, args.define, args.timeout)
        except Exception as exc:
            print(str(exc), file=sys.stderr)
            return 1
        harness = out_dir / f"{args.top}_auto_smoke_formal.sv"
        formal_top = write_auto_harness(
            harness,
            args.top,
            ports,
            args.clock,
            args.reset,
            args.depth,
        )
        files = [rel(p, root) for p in rtl_files] + [rel(harness, root)]
        expected = "PASS"

    case = {
        "name": f"{args.top}_generic_verilog_formal",
        "top": formal_top,
        "files": files,
        "depth": args.depth,
        "expected": expected,
        "report": rel(out_dir / "formal_report.md", root),
        "log_dir": rel(log_dir, root),
        "result_dir": rel(result_dir, root),
    }
    if args.define:
        case["defines"] = args.define
    case_yaml.write_text(yaml.safe_dump(case, sort_keys=False), encoding="utf-8")

    formal_cmd = [
        sys.executable,
        "src/ucagent_skills/generic-formal/scripts/run_formal.py",
        "--case",
        rel(case_yaml, root),
        "--timeout",
        str(args.timeout),
    ]
    formal_rc, formal_out = run(formal_cmd, root, args.timeout)
    formal_log = log_dir / "generic_formal_invocation.log"
    formal_log.write_text("$ " + " ".join(formal_cmd) + "\n\n" + formal_out, encoding="utf-8")
    try:
        last_json = json.loads(formal_out[formal_out.rfind("{") :])
        formal_actual = last_json.get("actual", "UNKNOWN")
        formal_verdict = last_json.get("verdict", "UNKNOWN")
    except Exception:
        formal_actual = "ERROR" if formal_rc else "PASS"
        formal_verdict = "UNKNOWN"

    classification = "PASS" if yosys_rc == 0 and formal_rc == 0 else "FAIL"
    summary = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "classification": classification,
        "top": args.top,
        "rtl": [rel(p, root) for p in rtl_files],
        "property": args.property,
        "yosys_rc": yosys_rc,
        "formal_actual": formal_actual,
        "formal_verdict": formal_verdict,
        "smoke": args.smoke,
        "reports": {
            "yosys_log": rel(yosys_log, root),
            "formal_case": rel(case_yaml, root),
            "formal_log": rel(formal_log, root),
        },
    }
    (result_dir / "summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    (out_dir / "README.md").write_text(
        "# Generic Verilog Verification Report\n\n"
        f"- Top: `{args.top}`\n"
        f"- Classification: `{classification}`\n"
        f"- Yosys log: `{rel(yosys_log, root)}`\n"
        f"- Formal case: `{rel(case_yaml, root)}`\n"
        f"- Formal result: `{formal_actual}` / `{formal_verdict}`\n\n"
        "This report is a generic toolchain smoke unless a user property was supplied.\n",
        encoding="utf-8",
    )
    print(json.dumps(summary, indent=2))
    return 0 if classification == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
