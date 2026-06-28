from __future__ import annotations

from pathlib import Path

import yaml


def find_repo_root() -> Path:
    here = Path(__file__).resolve()
    for candidate in [here.parent, *here.parents]:
        if (candidate / "tests" / "cases" / "05_full_cache_coverage_plan").exists():
            return candidate
    raise RuntimeError("cannot locate repository root")


REPO_ROOT = find_repo_root()
PLAN_PATH = REPO_ROOT / "tests" / "cases" / "05_full_cache_coverage_plan" / "data" / "cache_coverage_plan.yaml"
REPORT_PATH = REPO_ROOT / "reports" / "05_full_cache_coverage_plan.md"
SUMMARY_JSON = REPO_ROOT / "reports" / "artifacts" / "05_full_cache_coverage_plan" / "coverage_plan_summary.json"


def load_plan() -> dict:
    with PLAN_PATH.open("r", encoding="utf-8") as fp:
        return yaml.safe_load(fp)


def summarize_plan(plan: dict) -> dict:
    points = plan["coverage_points"]
    counts = {
        "total": len(points),
        "implemented": 0,
        "partial": 0,
        "gap": 0,
    }
    missing_evidence: list[dict[str, str]] = []
    for point in points:
        status = point["status"]
        counts[status] = counts.get(status, 0) + 1
        if status in {"implemented", "partial"}:
            for evidence in point.get("evidence", []):
                if not (REPO_ROOT / evidence).exists():
                    missing_evidence.append({"id": point["id"], "evidence": evidence})

    crv = plan["crv_scenarios"]
    scoreboard = plan["scoreboard_plan"]
    return {
        "counts": counts,
        "missing_evidence": missing_evidence,
        "crv_total": len(crv),
        "crv_gap": sum(1 for item in crv if item["status"] == "gap"),
        "scoreboard_items": len(scoreboard),
        "scoreboard_gap": sum(1 for item in scoreboard.values() if item["status"] == "gap"),
        "open_environment_assumptions": [
            name
            for name, item in plan["environment_assumptions"].items()
            if item["status"] in {"open_question", "gap"}
        ],
    }


def write_report(plan: dict, summary: dict) -> None:
    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    SUMMARY_JSON.parent.mkdir(parents=True, exist_ok=True)

    import json

    SUMMARY_JSON.write_text(json.dumps(summary, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    lines = [
        "# 05 全 Cache Coverage Plan 验证报告",
        "",
        "- 分类：`COVERAGE_PLAN_VALIDATED_BY_UCAGENT_TOFFEE_FLOW`",
        f"- Coverage point total：`{summary['counts']['total']}`",
        f"- Implemented：`{summary['counts'].get('implemented', 0)}`",
        f"- Partial：`{summary['counts'].get('partial', 0)}`",
        f"- Gap：`{summary['counts'].get('gap', 0)}`",
        f"- CRV scenarios：`{summary['crv_total']}`，gap：`{summary['crv_gap']}`",
        f"- Scoreboard items：`{summary['scoreboard_items']}`，gap：`{summary['scoreboard_gap']}`",
        f"- Summary JSON：`{SUMMARY_JSON.relative_to(REPO_ROOT)}`",
        "",
        "## 结论",
        "",
        "本场景不是第五个 bug，而是完整 Cache 覆盖闭环的计划级验证。",
        "它检查人工定义的 coverage plan 是否完整、已有 02/03/04 证据是否可追踪、未完成项是否明确标为 gap。",
        "",
        "## 人工/UCAgent/Picker/Toffee 分工",
        "",
        "| 步骤 | 执行者 | 说明 |",
        "| --- | --- | --- |",
        "| 定义覆盖目标、合法环境假设、scoreboard oracle | 人工手写 | 决定什么才算 Cache 验证充分，不能交给工具自动闭环。 |",
        "| 生成/补强 Toffee 或 formal 测试草稿 | UCAgent | 读取 plan 后生成测试建议或草稿。 |",
        "| 导出真实 DUT | Picker | 将 Chisel/RTL wrapper 导出成 Python DUT。 |",
        "| 执行动态测试、收集场景 coverage | Toffee/pytest | 跑 public-IO 测试、生成 HTML/JSON 报告。 |",
        "| 执行窄窗口 property 搜索 | UCAgent + generic-formal skill | 对 ready/valid、flush、dirty eviction 等高风险窗口做 bounded formal。 |",
        "| 审查 gap、确认是否关闭覆盖 | 人工 | 判断覆盖是否真实有效，避免纯 AI 刷覆盖。 |",
        "",
        "## Coverage Points",
        "",
        "| ID | Group | Status | Target |",
        "| --- | --- | --- | --- |",
    ]
    for point in plan["coverage_points"]:
        lines.append(f"| `{point['id']}` | `{point['group']}` | `{point['status']}` | `{point['target']}` |")

    lines.extend(
        [
            "",
            "## Open Environment Assumptions",
            "",
        ]
    )
    for item in summary["open_environment_assumptions"]:
        lines.append(f"- `{item}`")

    if summary["missing_evidence"]:
        lines.extend(["", "## Missing Evidence", ""])
        for item in summary["missing_evidence"]:
            lines.append(f"- `{item['id']}` -> `{item['evidence']}`")
    else:
        lines.extend(["", "## Missing Evidence", "", "无。"])

    REPORT_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")

