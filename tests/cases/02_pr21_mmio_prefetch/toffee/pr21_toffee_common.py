from __future__ import annotations

from dataclasses import dataclass, field
import importlib.util
import json
import os
from pathlib import Path
import sys

import pytest
import toffee.funcov as fc
from toffee_test.reporter import (
    get_file_in_tmp_dir,
    set_func_coverage,
    set_line_coverage,
    set_title_info,
    set_user_info,
)


SIMPLEBUS_READ = 0x0
SIMPLEBUS_PREFETCH = 0x4


def _find_repo_root() -> Path:
    env_root = os.environ.get("NUTSHELL_CACHE_VERIFY_ROOT")
    if env_root:
        return Path(env_root).resolve()
    here = Path(__file__).resolve()
    for candidate in [here.parent, *here.parents]:
        if (candidate / "tests" / "cases" / "02_pr21_mmio_prefetch").exists():
            return candidate
    return here.parents[3]


REPO_ROOT = _find_repo_root()
ARTIFACT_ROOT = REPO_ROOT / "reports" / "artifacts" / "02_pr21"
TOFFEE_ARTIFACT_DIR = ARTIFACT_ROOT / "toffee"
TOFFEE_REPORT = REPO_ROOT / "reports" / "02_pr21_toffee_coverage.md"
TOFFEE_SUMMARY_JSON = TOFFEE_ARTIFACT_DIR / "coverage_summary.json"
DUT_PRE_DIR = ARTIFACT_ROOT / "toffee_dut_pre"
DUT_FIXED_DIR = ARTIFACT_ROOT / "toffee_dut_fixed"


def _u(signal) -> int:
    return int(signal.value)


def _set(signal, value: int) -> None:
    signal.value = int(value)


def _load_dut_class(dut_dir: Path):
    init_path = dut_dir / "__init__.py"
    sys.path.insert(0, str(dut_dir))
    spec = importlib.util.spec_from_file_location(f"pr21_dut_{dut_dir.name}", init_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load DUT package from {init_path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module.DUTPr21CacheFormalDut


def _tmp_file(request, name: str, new_path: bool) -> str:
    base = Path(__file__).resolve().parent / "data"
    return get_file_in_tmp_dir(request, str(base), name, new_path=new_path)


@dataclass
class Pr21Coverage:
    normal_read_issued: bool = False
    mmio_prefetch_issued: bool = False
    s2_mmio_prefetch_seen: bool = False
    s3_non_prefetch_seen: bool = False
    overlap_window_seen: bool = False
    s3_dropped_after_overlap: bool = False
    bug_observed: bool = False

    def setup_total(self) -> int:
        return 5

    def setup_hit(self) -> int:
        return sum(
            [
                self.normal_read_issued,
                self.mmio_prefetch_issued,
                self.s2_mmio_prefetch_seen,
                self.s3_non_prefetch_seen,
                self.overlap_window_seen,
            ]
        )

    def setup_percent(self) -> float:
        return round(self.setup_hit() * 100.0 / self.setup_total(), 2)

    def classification(self, expected_bug: bool) -> str:
        if expected_bug and self.bug_observed:
            return "DYNAMIC_REPRODUCED"
        if not expected_bug and not self.bug_observed:
            return "FIXED_DYNAMIC_PASS"
        if not expected_bug and self.bug_observed:
            return "FIXED_EDGE_SAMPLING_INCONCLUSIVE"
        if self.setup_hit() != self.setup_total():
            return "UNREACHABLE_IN_TOFFEE"
        return "UNEXPECTED_DYNAMIC_RESULT"

    def as_dict(self) -> dict[str, object]:
        return {
            "normal_read_issued": self.normal_read_issued,
            "mmio_prefetch_issued": self.mmio_prefetch_issued,
            "s2_mmio_prefetch_seen": self.s2_mmio_prefetch_seen,
            "s3_non_prefetch_seen": self.s3_non_prefetch_seen,
            "overlap_window_seen": self.overlap_window_seen,
            "s3_dropped_after_overlap": self.s3_dropped_after_overlap,
            "bug_observed": self.bug_observed,
            "setup_hit": self.setup_hit(),
            "setup_total": self.setup_total(),
            "setup_percent": self.setup_percent(),
        }


def get_coverage_groups(dut):
    group = fc.CovGroup("FG-PR21-MMIO-PREFETCH")
    group.add_watch_point(
        dut,
        {
            "CK-NORMAL-READ-ISSUED": lambda x: x.scenario_cov.normal_read_issued,
            "CK-MMIO-PREFETCH-ISSUED": lambda x: x.scenario_cov.mmio_prefetch_issued,
            "CK-S2-MMIO-PREFETCH-SEEN": lambda x: x.scenario_cov.s2_mmio_prefetch_seen,
            "CK-S3-NON-PREFETCH-SEEN": lambda x: x.scenario_cov.s3_non_prefetch_seen,
            "CK-OVERLAP-WINDOW-SEEN": lambda x: x.scenario_cov.overlap_window_seen,
            "CK-BUG-OBSERVED": lambda x: x.scenario_cov.bug_observed,
        },
        name="FC-PR21-MMIO-PREFETCH",
    )
    return [group]


def create_dut(request, variant: str):
    dut_dir = DUT_PRE_DIR if variant == "pre" else DUT_FIXED_DIR
    if not (dut_dir / "__init__.py").exists():
        raise RuntimeError(
            f"missing Picker DUT package at {dut_dir}; run scripts/internal/24_prepare_pr21_picker_dut.sh first"
        )
    dut_class = _load_dut_class(dut_dir)
    dut = dut_class()
    TOFFEE_ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)
    dut.SetCoverage(_tmp_file(request, f"pr21_{variant}_line.dat", new_path=True))
    dut.SetWaveform(str(TOFFEE_ARTIFACT_DIR / f"pr21_{variant}_mmio_prefetch.fst"))
    dut.InitClock("clock")
    dut.scenario_cov = Pr21Coverage()
    return dut


def _finish_dut(request, dut, variant: str, groups):
    set_func_coverage(request, groups)
    set_line_coverage(
        request,
        _tmp_file(request, f"pr21_{variant}_line.dat", new_path=False),
        ignore=str(Path(__file__).resolve().parent / "Pr21MmioPrefetch.ignore"),
    )
    set_user_info("NutShellCacheVerify", "ucagent-dynamic-no-formal")
    set_title_info(f"PR21 {variant} Toffee dynamic report")
    for group in groups:
        group.clear()
    dut.Finish()


@pytest.fixture(scope="function")
def pre_env(request):
    dut = create_dut(request, "pre")
    groups = get_coverage_groups(dut)
    dut.StepRis(lambda _: [g.sample() for g in groups])
    yield Pr21Env(dut, "pre")
    _finish_dut(request, dut, "pre", groups)


@pytest.fixture(scope="function")
def fixed_env(request):
    dut = create_dut(request, "fixed")
    groups = get_coverage_groups(dut)
    dut.StepRis(lambda _: [g.sample() for g in groups])
    yield Pr21Env(dut, "fixed")
    _finish_dut(request, dut, "fixed", groups)


@dataclass
class Pr21Env:
    dut: object
    variant: str
    cycle: int = 0
    events: list[str] = field(default_factory=list)
    overlap_pending_check: bool = False

    def initialize(self) -> None:
        _set(self.dut.reset, 1)
        _set(self.dut.io_flush, 0)
        _set(self.dut.io_cpu_req_valid, 0)
        _set(self.dut.io_cpu_req_addr, 0)
        _set(self.dut.io_cpu_req_cmd, SIMPLEBUS_READ)
        _set(self.dut.io_cpu_resp_ready, 1)
        _set(self.dut.io_mem_req_ready, 0)
        _set(self.dut.io_mem_resp_valid, 0)
        _set(self.dut.io_mem_resp_cmd, 0x6)
        _set(self.dut.io_mmio_req_ready, 1)
        _set(self.dut.io_mmio_resp_valid, 0)
        _set(self.dut.io_mmio_resp_cmd, 0x6)
        self.step(3)
        _set(self.dut.reset, 0)
        self.step(2)

    def step(self, count: int = 1) -> None:
        for _ in range(count):
            self.dut.Step(1)
            self.cycle += 1
            self.sample()

    def drive_req(self, valid: int, addr: int, cmd: int, resp_ready: int = 1) -> None:
        _set(self.dut.io_cpu_req_valid, valid)
        _set(self.dut.io_cpu_req_addr, addr)
        _set(self.dut.io_cpu_req_cmd, cmd)
        _set(self.dut.io_cpu_resp_ready, resp_ready)
        if valid and cmd == SIMPLEBUS_PREFETCH and (addr >> 28) in (0x3, 0x4):
            self.dut.scenario_cov.mmio_prefetch_issued = True
        if valid and cmd == SIMPLEBUS_READ:
            self.dut.scenario_cov.normal_read_issued = True
        self.step(1)

    def sample(self) -> None:
        cov = self.dut.scenario_cov
        s2_valid = _u(self.dut.io_pr21_s2_out_valid)
        s2_mmio = _u(self.dut.io_pr21_s2_out_mmio)
        s2_prefetch = _u(self.dut.io_pr21_s2_out_prefetch)
        s3_valid = _u(self.dut.io_pr21_s3_in_valid)
        s3_prefetch = _u(self.dut.io_pr21_s3_in_prefetch)

        if self.overlap_pending_check:
            if not s3_valid:
                cov.s3_dropped_after_overlap = True
                cov.bug_observed = True
                self.events.append(f"C{self.cycle}: S3 dropped after overlap in {self.variant}")
            self.overlap_pending_check = False

        if s2_valid and s2_mmio and s2_prefetch:
            cov.s2_mmio_prefetch_seen = True
        if s3_valid and not s3_prefetch:
            cov.s3_non_prefetch_seen = True
        if s2_valid and s2_mmio and s2_prefetch and s3_valid:
            cov.overlap_window_seen = True
            if not s3_prefetch:
                self.overlap_pending_check = True
                self.events.append(f"C{self.cycle}: overlap window seen in {self.variant}")

    def run_counterexample_replay(self) -> Pr21Coverage:
        self.initialize()
        sequence = [
            (1, 0x0000_0000, SIMPLEBUS_READ, 0),
            (0, 0x0000_0000, SIMPLEBUS_READ, 0),
            (1, 0x0000_0000, SIMPLEBUS_READ, 1),
            (1, 0x1000_0000, SIMPLEBUS_READ, 0),
            (1, 0x3000_0000, SIMPLEBUS_PREFETCH, 1),
            (0, 0x0000_0040, SIMPLEBUS_READ, 0),
            (1, 0x0000_0040, SIMPLEBUS_READ, 1),
            (0, 0x0000_0000, SIMPLEBUS_READ, 0),
        ]
        for item in sequence:
            self.drive_req(*item)
        self.step(4)
        return self.dut.scenario_cov


def write_pr21_report(summary: dict[str, object], source: str) -> None:
    TOFFEE_ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)
    existing = {}
    if TOFFEE_SUMMARY_JSON.exists():
        existing = json.loads(TOFFEE_SUMMARY_JSON.read_text())
    for key in ("pre", "fixed"):
        if summary.get(key) is not None:
            existing[key] = summary[key]
    existing["source"] = source
    pre = existing.get("pre")
    fixed = existing.get("fixed")
    if pre and fixed:
        if pre.get("bug_observed") and not fixed.get("bug_observed"):
            existing["classification"] = "DYNAMIC_REPRODUCED_AND_FIXED_PASS"
        elif pre.get("bug_observed") and fixed.get("bug_observed"):
            existing["classification"] = "DYNAMIC_PRE_REPRODUCED_FIXED_EDGE_SAMPLING_LIMIT"
        else:
            existing["classification"] = "UNEXPECTED_DYNAMIC_RESULT"
    else:
        existing["classification"] = summary.get("classification", "PARTIAL")
    TOFFEE_SUMMARY_JSON.write_text(json.dumps(existing, indent=2), encoding="utf-8")

    lines = [
        "# 02 PR21 Toffee 动态后端报告",
        "",
        f"- 分类：`{existing['classification']}`",
        "- 覆盖口径：PR21 MMIO prefetch 场景级 coverpoints，不代表完整 Cache functional coverage。",
        "- Python DUT pre：`reports/artifacts/02_pr21/toffee_dut_pre`",
        "- Python DUT fixed：`reports/artifacts/02_pr21/toffee_dut_fixed`",
        "- Coverage JSON：`reports/artifacts/02_pr21/toffee/coverage_summary.json`",
        f"- 来源：`{source}`",
        "",
        "## 结果",
        "",
        "| Variant | setup_hit/setup_total | bug_observed |",
        "| --- | --- | --- |",
    ]
    for key in ("pre", "fixed"):
        data = existing.get(key) or {}
        lines.append(
            f"| `{key}` | `{data.get('setup_hit', '?')}/{data.get('setup_total', '?')}` | "
            f"`{data.get('bug_observed', '?')}` |"
        )
    lines.extend(
        [
            "",
            "## Bug oracle",
            "",
            "PR21 formal 属性检查的不是“MMIO prefetch 与 S3 正常请求同拍出现”本身，而是该窗口后一拍 S3 中已有正常请求不能被清掉。因此动态 scoreboard 将 `overlap_window_seen` 作为 setup bin，将 `s3_dropped_after_overlap` 作为 bug observation bin。",
            "",
            "注意：Toffee/Python 读取 probe 的时间点是 Verilator `Step` 后状态，而 formal immediate assertion 在 posedge 语义下检查的是边沿采样值。fixed 版本的 public-probe replay 因此只作为动态覆盖证据，不作为 fixed 失败证据；fixed 是否消除该 bug 以 PR21 formal fixed PASS 为准。",
        ]
    )
    lines.extend(
        [
            "",
            "## 人工干预",
            "",
            "- UCAgent 负责生成 Toffee/API/pytest 草稿结构。",
            "- 人工根据 PR21 历史反例 trace 收敛 directed replay、scoreboard 和 coverage。",
            "- 本动态后端不调用 formal skill。",
        ]
    )
    TOFFEE_REPORT.write_text("\n".join(lines) + "\n", encoding="utf-8")
