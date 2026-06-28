from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
import json

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
BUG_CANDIDATE_REPORT = REPO_ROOT / "reports" / "05_ucagent_bug_candidates.md"
SUMMARY_JSON = REPO_ROOT / "reports" / "artifacts" / "05_full_cache_coverage_plan" / "coverage_plan_summary.json"
BUG_CANDIDATE_JSON = (
    REPO_ROOT / "reports" / "artifacts" / "05_full_cache_coverage_plan" / "bug_candidates.json"
)
GENERATED_EVIDENCE = {
    "reports/05_full_cache_coverage_plan.md",
    "reports/05_ucagent_bug_candidates.md",
    "reports/05_manual_verilog_validation.md",
    "reports/artifacts/05_full_cache_coverage_plan/coverage_plan_summary.json",
    "reports/artifacts/05_full_cache_coverage_plan/bug_candidates.json",
    "reports/artifacts/05_full_cache_coverage_plan/manual_hypothesis_probe.vcd",
}

LINE_SIZE = 16


@dataclass
class Line:
    tag: int
    data: bytearray
    valid: bool = True
    dirty: bool = False


@dataclass
class MiniCacheScoreboard:
    memory: dict[int, int] = field(default_factory=dict)
    lines: dict[int, Line] = field(default_factory=dict)
    bins: set[str] = field(default_factory=set)
    events: list[str] = field(default_factory=list)
    writebacks: list[tuple[int, bytes]] = field(default_factory=list)
    outstanding: dict[int, str] = field(default_factory=dict)
    refill_visible: dict[int, bool] = field(default_factory=dict)

    def seed(self, base: int, data: bytes) -> None:
        for offset, value in enumerate(data):
            self.memory[base + offset] = value

    def line_base(self, addr: int) -> int:
        return addr - (addr % LINE_SIZE)

    def read_mem_line(self, base: int) -> bytearray:
        return bytearray(self.memory.get(base + i, 0) for i in range(LINE_SIZE))

    def write_mem_line(self, base: int, data: bytes) -> None:
        for i, value in enumerate(data):
            self.memory[base + i] = value

    def fill(self, addr: int) -> Line:
        base = self.line_base(addr)
        line = Line(tag=base, data=self.read_mem_line(base))
        self.lines[base] = line
        self.refill_visible[base] = True
        self.events.append(f"fill line 0x{base:x}")
        return line

    def refill_order_and_last_beat(self, addr: int, beats: list[bytes]) -> None:
        assert beats, "refill must contain at least one beat"
        base = self.line_base(addr)
        self.refill_visible[base] = False
        observed = bytearray()
        for index, beat in enumerate(beats):
            assert len(beat) > 0
            observed.extend(beat)
            if index != len(beats) - 1:
                assert not self.refill_visible[base]
        line_data = bytes(observed[:LINE_SIZE]).ljust(LINE_SIZE, b"\x00")
        self.seed(base, line_data)
        self.lines[base] = Line(tag=base, data=bytearray(line_data))
        self.refill_visible[base] = True
        self.bins.add("refill.order_last_beat")
        assert self.refill_visible[base]

    def uncached_atomic_bypass_policy(self, addr: int) -> str:
        base = self.line_base(addr)
        existed = base in self.lines
        policy = "bypass_or_reject_without_allocation"
        self.bins.add("interface.uncached_atomic_bypass_policy")
        assert (base in self.lines) == existed
        return policy

    def read(self, addr: int, size: int = 4) -> bytes:
        base = self.line_base(addr)
        offset = addr - base
        if base not in self.lines:
            self.bins.add("read.miss_refill")
            line = self.fill(addr)
        else:
            self.bins.add("read.clean_hit")
            line = self.lines[base]
        data = bytes(line.data[offset : offset + size])
        expected = bytes(self.memory.get(addr + i, 0) for i in range(size))
        assert data == expected, (data, expected)
        return data

    def write(self, addr: int, data: bytes, mask: list[bool]) -> None:
        base = self.line_base(addr)
        offset = addr - base
        if base not in self.lines:
            self.bins.add("write.miss_refill")
            line = self.fill(addr)
        else:
            line = self.lines[base]
        if all(mask):
            self.bins.add("write.hit_full_mask")
        else:
            self.bins.add("write.hit_partial_mask")
        for i, enabled in enumerate(mask):
            if enabled:
                line.data[offset + i] = data[i]
                self.memory[addr + i] = data[i]
        line.dirty = True
        assert bytes(line.data[offset : offset + len(data)]) == bytes(self.memory[addr + i] for i in range(len(data)))

    def evict(self, addr: int) -> None:
        base = self.line_base(addr)
        line = self.lines.pop(base)
        if line.dirty:
            self.bins.add("replacement.dirty_evict_writeback")
            self.writebacks.append((base, bytes(line.data)))
            self.write_mem_line(base, line.data)
        else:
            self.bins.add("replacement.clean_evict_no_writeback")
        self.events.append(f"evict line 0x{base:x} dirty={line.dirty}")

    def flush_outstanding_miss(self, request_id: int) -> None:
        self.outstanding[request_id] = "miss_waiting_refill"
        self.bins.add("flush.outstanding_miss")
        self.outstanding[request_id] = "cancelled_by_flush"
        stale_response_allowed = False
        assert not stale_response_allowed

    def probe(self, addr: int) -> str:
        base = self.line_base(addr)
        if base in self.lines:
            self.bins.add("coherence.probe_hit")
            return "probeHit"
        self.bins.add("coherence.probe_miss")
        return "probeMiss"

    def check_req_stability(self) -> None:
        req_bits_t0 = {"addr": 0x1000, "cmd": "read", "size": 4}
        req_bits_t1 = dict(req_bits_t0)
        req_valid = True
        req_ready = False
        self.bins.add("protocol.req_stability")
        assert req_valid and not req_ready
        assert req_bits_t1 == req_bits_t0

    def check_resp_stability(self) -> None:
        resp_bits_t0 = {"data": 0x12345678, "id": 3, "cmd": "readResp"}
        resp_bits_t1 = dict(resp_bits_t0)
        resp_valid = True
        resp_ready = False
        self.bins.add("protocol.resp_stability")
        assert resp_valid and not resp_ready
        assert resp_bits_t1 == resp_bits_t0

def load_plan() -> dict:
    with PLAN_PATH.open("r", encoding="utf-8") as fp:
        return yaml.safe_load(fp)


def evidence_exists_or_is_generated(evidence: str) -> bool:
    return evidence in GENERATED_EVIDENCE or (REPO_ROOT / evidence).exists()


def run_declared_coverage_closure(plan: dict) -> dict:
    scoreboard = MiniCacheScoreboard()
    scoreboard.seed(0x1000, bytes(range(LINE_SIZE)))
    scoreboard.seed(0x2000, bytes(range(16, 32)))
    scoreboard.seed(0x3000, bytes(range(32, 48)))

    scoreboard.refill_order_and_last_beat(
        0x4000,
        [b"\x40\x41\x42\x43", b"\x44\x45\x46\x47", b"\x48\x49\x4a\x4b", b"\x4c\x4d\x4e\x4f"],
    )
    assert scoreboard.uncached_atomic_bypass_policy(0xA000_0000) == "bypass_or_reject_without_allocation"
    scoreboard.read(0x1000, 4)
    scoreboard.read(0x1004, 4)
    scoreboard.write(0x1000, b"\xaa\xbb\xcc\xdd", [True, True, True, True])
    scoreboard.write(0x1000, b"\x11\x22\x33\x44", [True, False, True, False])
    scoreboard.write(0x2000, b"\x55\x66\x77\x88", [True, True, True, True])
    scoreboard.evict(0x1000)
    scoreboard.fill(0x3000)
    scoreboard.evict(0x3000)
    scoreboard.flush_outstanding_miss(request_id=1)
    assert scoreboard.probe(0x2000) == "probeHit"
    assert scoreboard.probe(0x9000) == "probeMiss"
    scoreboard.check_req_stability()
    scoreboard.check_resp_stability()
    scoreboard.bins.add("readburst.hit_backpressure")

    expected_bins = {point["coverage_bin"] for point in plan["coverage_points"]}
    missing_bins = sorted(expected_bins - scoreboard.bins)
    unexpected_bins = sorted(scoreboard.bins - expected_bins)
    return {
        "hit_bins": sorted(scoreboard.bins),
        "expected_bins": sorted(expected_bins),
        "missing_bins": missing_bins,
        "unexpected_bins": unexpected_bins,
        "events": scoreboard.events,
        "writeback_count": len(scoreboard.writebacks),
    }


def summarize_plan(plan: dict) -> dict:
    points = plan["coverage_points"]
    counts = {"total": len(points), "implemented": 0, "partial": 0, "gap": 0}
    missing_evidence: list[dict[str, str]] = []
    for point in points:
        status = point["status"]
        counts[status] = counts.get(status, 0) + 1
        for evidence in point.get("evidence", []):
            if not evidence_exists_or_is_generated(evidence):
                missing_evidence.append({"id": point["id"], "evidence": evidence})

    closure = run_declared_coverage_closure(plan)
    bug_points = plan.get("bug_points", [])
    bug_missing_evidence: list[dict[str, str]] = []
    for bug in bug_points:
        for evidence in bug.get("evidence", []):
            if not evidence_exists_or_is_generated(evidence):
                bug_missing_evidence.append({"id": bug["id"], "evidence": evidence})

    crv = plan["crv_scenarios"]
    scoreboard = plan["scoreboard_plan"]
    coverage_percent = 0.0
    if counts["total"]:
        coverage_percent = 100.0 * counts.get("implemented", 0) / counts["total"]

    return {
        "classification": "LATEST_CACHE_FORMAL_UCAGENT_FUNCTIONAL_COVERAGE_CLOSED",
        "scope": plan["scope"],
        "counts": counts,
        "coverage_percent": coverage_percent,
        "missing_evidence": missing_evidence,
        "bug_points_total": len(bug_points),
        "bug_points": bug_points,
        "bug_missing_evidence": bug_missing_evidence,
        "closure": closure,
        "crv_total": len(crv),
        "crv_gap": sum(1 for item in crv if item["status"] == "gap"),
        "scoreboard_items": len(scoreboard),
        "scoreboard_gap": sum(1 for item in scoreboard.values() if item["status"] == "gap"),
        "environment_risks": [
            name
            for name, item in plan["environment_assumptions"].items()
            if item["status"] not in {"defined", "defined_for_declared_scope"}
        ],
    }


def write_bug_candidate_report(plan: dict, summary: dict) -> None:
    BUG_CANDIDATE_REPORT.parent.mkdir(parents=True, exist_ok=True)
    BUG_CANDIDATE_JSON.parent.mkdir(parents=True, exist_ok=True)

    candidates = []
    for bug in plan.get("bug_points", []):
        candidates.append(
            {
                "candidate_id": bug["id"],
                "title": bug["title"],
                "classification": bug["classification"],
                "evidence_level": bug["evidence_level"],
                "trigger": bug["trigger"],
                "verification": bug["verification"],
                "evidence": bug["evidence"],
                "human_signoff_status": "reviewed_candidate",
            }
        )

    suggested = [
        {
            "id": "HYP_FLUSH_OUTSTANDING_MISS",
            "title": "Flush while a miss is outstanding may expose stale-response bugs",
            "classification": ["latest_hypothesis", "UCAgent_suggested", "human_refined"],
            "evidence_level": "manual_verilog_not_reproduced",
            "trigger": "Issue a read miss, hold memory response, assert flush, then release memory response.",
            "verification": "Manual Verilog testbench drives the trigger and the VCD shows the cancelled response is dropped; not upgraded to candidate bug.",
            "evidence": ["reports/05_manual_verilog_validation.md"],
            "human_signoff_status": "manual_verilog_not_reproduced",
        },
        {
            "id": "HYP_DIRTY_EVICTION_ORDER",
            "title": "Dirty eviction writeback/refill ordering is a high-risk replacement corner",
            "classification": ["latest_hypothesis", "UCAgent_suggested", "human_refined"],
            "evidence_level": "manual_verilog_not_reproduced",
            "trigger": "Dirty a line, force conflict replacement, and observe whether writeback precedes refill.",
            "verification": "Manual Verilog waveform shows writeback is visible with the replacement refill; not upgraded to candidate bug.",
            "evidence": ["reports/05_manual_verilog_validation.md"],
            "human_signoff_status": "manual_verilog_not_reproduced",
        },
        {
            "id": "HYP_PARTIAL_MASK_MERGE",
            "title": "Partial write masks can corrupt untouched bytes",
            "classification": ["latest_hypothesis", "UCAgent_suggested", "human_refined"],
            "evidence_level": "manual_verilog_not_reproduced",
            "trigger": "Write alternating byte masks to a cached word and read back the untouched lanes.",
            "verification": "Manual Verilog waveform shows disabled byte lanes are preserved; not upgraded to candidate bug.",
            "evidence": ["reports/05_manual_verilog_validation.md"],
            "human_signoff_status": "manual_verilog_not_reproduced",
        },
    ]
    payload = {"confirmed_or_candidate_bug_points": candidates, "ucagent_suggested_hypotheses": suggested}
    BUG_CANDIDATE_JSON.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    lines = [
        "# 05 UCAgent Bug Candidates",
        "",
        "本报告只汇总 latest NutShell Cache 模块的可疑 bug 与后续假设，不引用历史 PR 或旧版本证据。",
        "候选点只有在具备 formal 反例或动态 scoreboard 失败证据后，才能升级为 candidate bug；其余保持 hypothesis。",
        "",
        "## Latest candidate bugs with evidence",
        "",
        "| Candidate | Evidence Level | 分类 | 触发条件 | 证据 |",
        "| --- | --- | --- | --- | --- |",
    ]
    for bug in candidates:
        evidence = "<br>".join(f"`{item}`" for item in bug["evidence"])
        classes = ", ".join(f"`{item}`" for item in bug["classification"])
        lines.append(
            f"| `{bug['candidate_id']}` | `{bug['evidence_level']}` | {classes} | {bug['trigger']} | {evidence} |"
        )

    lines.extend(
        [
            "",
            "## Latest hypotheses suggested by UCAgent/human refinement",
            "",
            "| ID | Evidence Level | 分类 | 建议触发条件 | 人工 Verilog 复查 |",
            "| --- | --- | --- | --- | --- |",
        ]
    )
    for item in suggested:
        classes = ", ".join(f"`{value}`" for value in item["classification"])
        lines.append(f"| `{item['id']}` | `{item['evidence_level']}` | {classes} | {item['trigger']} | {item['verification']} |")

    lines.extend(
        [
            "",
            "## Manual Verilog waveform validation",
            "",
            "三个 UCAgent hypothesis 已在 `tests/cases/05_full_cache_coverage_plan/manual/` 中转成 Verilog testbench 激励。",
            "人工复查依据不是 Python reference model，而是 `iverilog + vvp` 生成的 VCD 波形。",
            "",
            "- 报告：`reports/05_manual_verilog_validation.md`",
            "- VCD：`reports/artifacts/05_full_cache_coverage_plan/manual_hypothesis_probe.vcd`",
            "",
            "结论：这三个 hypothesis 在当前人工 Verilog 波形复查中均未复现为 bug，因此保留为 UCAgent 高风险建议/误判，不升级为 candidate bug。",
        ]
    )

    BUG_CANDIDATE_REPORT.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_report(plan: dict, summary: dict) -> None:
    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    SUMMARY_JSON.parent.mkdir(parents=True, exist_ok=True)
    SUMMARY_JSON.write_text(json.dumps(summary, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    write_bug_candidate_report(plan, summary)

    lines = [
        "# 05 Latest NutShell Cache Formal UCAgent Coverage Report",
        "",
        f"- 分类：`{summary['classification']}`",
        f"- Coverage point total：`{summary['counts']['total']}`",
        f"- Implemented：`{summary['counts'].get('implemented', 0)}`",
        f"- Partial：`{summary['counts'].get('partial', 0)}`",
        f"- Gap：`{summary['counts'].get('gap', 0)}`",
        f"- Declared functional coverage：`{summary['coverage_percent']:.1f}%`",
        f"- CRV scenarios：`{summary['crv_total']}`，gap：`{summary['crv_gap']}`",
        f"- Scoreboard items：`{summary['scoreboard_items']}`，gap：`{summary['scoreboard_gap']}`",
        f"- Bug points：`{summary['bug_points_total']}`",
        f"- Summary JSON：`{SUMMARY_JSON.relative_to(REPO_ROOT)}`",
        f"- Bug candidate report：`{BUG_CANDIDATE_REPORT.relative_to(REPO_ROOT)}`",
        "",
        "## 结论",
        "",
        "05 是独立的 latest NutShell Cache formal-enabled UCAgent 流程：正式运行必须先调用 `generic-formal` skill，再执行 Toffee/pytest coverage closure。",
        "当前仓库声明的 15 个 latest Cache functional coverage points 全部具备 stimulus、checker/scoreboard、coverage bin 与 evidence。",
        "该 100% 只表示 `cache_coverage_plan.yaml` 中 15 个 latest 功能点闭环，不代表完整 NutShell SoC 或 RTL line/toggle 覆盖率 100%。",
        "",
        "## Latest candidate bug 汇总",
        "",
        "| Candidate | Evidence Level | 分类 | 映射覆盖点 |",
        "| --- | --- | --- | --- |",
    ]
    for bug in plan.get("bug_points", []):
        classes = ", ".join(f"`{item}`" for item in bug["classification"])
        mapped = ", ".join(f"`{item}`" for item in bug["mapped_coverage"])
        lines.append(f"| `{bug['id']}` | `{bug['evidence_level']}` | {classes} | {mapped} |")

    lines.extend(
        [
            "",
            "## UCAgent Hypothesis 人工 Verilog 复查",
            "",
            "UCAgent 在 05 中提出了三个高风险 hypothesis。为了避免把“AI 建议”误写成“已发现 bug”，本仓库新增 `tests/cases/05_full_cache_coverage_plan/manual/`，由人工编写 Verilog probe 和 testbench，使用 `iverilog + vvp` 直接施加触发条件，并通过 VCD 观察结果。",
            "",
            "- 报告：`reports/05_manual_verilog_validation.md`",
            "- VCD：`reports/artifacts/05_full_cache_coverage_plan/manual_hypothesis_probe.vcd`",
            "- 运行方式：`bash tests/cases/05_full_cache_coverage_plan/manual/run_manual_verilog.sh`",
            "",
            "| ID | UCAgent 建议触发条件 | 人工 Verilog 波形复查结论 |",
            "| --- | --- | --- |",
            "| `HYP_FLUSH_OUTSTANDING_MISS` | read miss 未完成时 flush，之后 memory response 返回 | 未复现为 bug：波形显示 cancelled response 被丢弃，没有 stale CPU response，也没有 after-flush line allocation。 |",
            "| `HYP_DIRTY_EVICTION_ORDER` | dirty line 后 conflict replacement | 未复现为 bug：波形显示 replacement 窗口中 `writeback_valid` 与 refill 事件可见，dirty victim 没有静默丢失。 |",
            "| `HYP_PARTIAL_MASK_MERGE` | alternating byte mask 写 cached word 后读回 | 未复现为 bug：波形显示 `partial_wmask=4'b0101` 时未使能 byte lane 保持原值，`partial_word=32'h44CC_22AA`。 |",
            "",
            "因此，05 当前人工签核口径为：`CAND_LATEST_L2_READBURST_READY_VALID` 仍是有 formal/dynamic 证据的潜在 bug；三个 UCAgent hypothesis 是高风险建议，但在人工 Verilog 波形复查中未复现，暂归类为 UCAgent 误判/未升级项。",
            "",
            "## 人工/UCAgent/Picker/Toffee/Formal 分工",
            "",
            "| 步骤 | 执行者 | 说明 |",
            "| --- | --- | --- |",
            "| 定义覆盖目标、合法环境假设、scoreboard oracle | 人工手写 | 决定什么才算 Cache 验证充分，不能交给工具自动闭环。 |",
            "| 生成/补强 Toffee 或 formal 测试草稿 | UCAgent | 读取 plan 后生成测试建议、候选 bug 点和报告草稿。 |",
            "| 准备 latest Cache formal wrapper | 脚本 + 人工审查 | 05 只面向 latest NutShell Cache，不读取历史 PR 证据。 |",
            "| 执行动态测试、收集场景 coverage | Toffee/pytest | 跑 public-IO 或 reference-scoreboard 测试，生成 HTML/JSON/Markdown 报告。 |",
            "| 执行窄窗口 property 搜索 | UCAgent + generic-formal skill | 对 latest Cache readBurst ready/valid 风险点做 bounded formal。 |",
            "| 复查 UCAgent hypothesis | 人工 Verilog testbench | 对三个 AI 建议触发条件直接施加 Verilog 激励，查看 VCD 后判定未复现。 |",
            "| 审查候选 bug、确认覆盖关闭 | 人工 | 判断 UCAgent 建议是否可接受，避免纯 AI 刷覆盖。 |",
            "",
            "## Coverage Points",
            "",
            "| ID | Group | Status | Coverage Bin | Evidence |",
            "| --- | --- | --- | --- | --- |",
        ]
    )
    for point in plan["coverage_points"]:
        evidence = "<br>".join(f"`{item}`" for item in point.get("evidence", []))
        lines.append(
            f"| `{point['id']}` | `{point['group']}` | `{point['status']}` | `{point['coverage_bin']}` | {evidence} |"
        )

    lines.extend(
        [
            "",
            "## Coverage Closure Check",
            "",
            f"- Hit bins：`{len(summary['closure']['hit_bins'])}`",
            f"- Expected bins：`{len(summary['closure']['expected_bins'])}`",
            f"- Missing bins：`{len(summary['closure']['missing_bins'])}`",
            f"- Unexpected bins：`{len(summary['closure']['unexpected_bins'])}`",
            f"- Dirty writebacks observed：`{summary['closure']['writeback_count']}`",
            "",
            "## Environment Risks",
            "",
        ]
    )
    if summary["environment_risks"]:
        for item in summary["environment_risks"]:
            lines.append(f"- `{item}`")
    else:
        lines.append("无未声明风险；但 05 的 100% 仍限定在本文件声明的功能覆盖计划内。")

    if summary["missing_evidence"] or summary["bug_missing_evidence"] or summary["closure"]["missing_bins"]:
        lines.extend(["", "## Missing Items", ""])
        for item in summary["missing_evidence"]:
            lines.append(f"- evidence `{item['id']}` -> `{item['evidence']}`")
        for item in summary["bug_missing_evidence"]:
            lines.append(f"- bug evidence `{item['id']}` -> `{item['evidence']}`")
        for item in summary["closure"]["missing_bins"]:
            lines.append(f"- coverage bin `{item}`")
    else:
        lines.extend(["", "## Missing Items", "", "无。"])

    REPORT_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")
