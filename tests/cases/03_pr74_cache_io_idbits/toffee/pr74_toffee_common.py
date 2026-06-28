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
SIMPLEBUS_READLAST = 0x6
TEST_ID = 0xA


def _find_repo_root() -> Path:
    env_root = os.environ.get("NUTSHELL_CACHE_VERIFY_ROOT")
    if env_root:
        return Path(env_root).resolve()
    here = Path(__file__).resolve()
    for candidate in [here.parent, *here.parents]:
        if (candidate / "tests" / "cases" / "03_pr74_cache_io_idbits").exists():
            return candidate
    return here.parents[3]


REPO_ROOT = _find_repo_root()
ARTIFACT_ROOT = REPO_ROOT / "reports" / "artifacts" / "03_pr74"
TOFFEE_ARTIFACT_DIR = ARTIFACT_ROOT / "toffee"
TOFFEE_REPORT = REPO_ROOT / "reports" / "03_pr74_toffee_coverage.md"
TOFFEE_SUMMARY_JSON = TOFFEE_ARTIFACT_DIR / "coverage_summary.json"
DUT_FIXED_DIR = ARTIFACT_ROOT / "toffee_dut_fixed"


def _u(signal) -> int:
    return int(signal.value)


def _set(signal, value: int) -> None:
    signal.value = int(value)


def _load_dut_class(dut_dir: Path):
    init_path = dut_dir / "__init__.py"
    sys.path.insert(0, str(dut_dir))
    spec = importlib.util.spec_from_file_location("pr74_fixed_dut", init_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load DUT package from {init_path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module.DUTPr74CacheIOFormalDut


def _tmp_file(request, name: str, new_path: bool) -> str:
    base = Path(__file__).resolve().parent / "data"
    return get_file_in_tmp_dir(request, str(base), name, new_path=new_path)


@dataclass
class Pr74Coverage:
    request_issued_with_id: bool = False
    request_accepted: bool = False
    memory_response_issued: bool = False
    cpu_response_seen: bool = False
    response_id_matched: bool = False

    def setup_total(self) -> int:
        return 5

    def setup_hit(self) -> int:
        return sum(
            [
                self.request_issued_with_id,
                self.request_accepted,
                self.memory_response_issued,
                self.cpu_response_seen,
                self.response_id_matched,
            ]
        )

    def setup_percent(self) -> float:
        return round(self.setup_hit() * 100.0 / self.setup_total(), 2)

    def classification(self) -> str:
        if self.setup_hit() == self.setup_total() and self.response_id_matched:
            return "FIXED_DYNAMIC_PASS"
        return "UNEXPECTED_DYNAMIC_RESULT"

    def as_dict(self) -> dict[str, object]:
        return {
            "request_issued_with_id": self.request_issued_with_id,
            "request_accepted": self.request_accepted,
            "memory_response_issued": self.memory_response_issued,
            "cpu_response_seen": self.cpu_response_seen,
            "response_id_matched": self.response_id_matched,
            "setup_hit": self.setup_hit(),
            "setup_total": self.setup_total(),
            "setup_percent": self.setup_percent(),
        }


def get_coverage_groups(dut):
    group = fc.CovGroup("FG-PR74-CACHE-IO-IDBITS")
    group.add_watch_point(
        dut,
        {
            "CK-REQUEST-ISSUED-WITH-ID": lambda x: x.scenario_cov.request_issued_with_id,
            "CK-REQUEST-ACCEPTED": lambda x: x.scenario_cov.request_accepted,
            "CK-MEMORY-RESPONSE-ISSUED": lambda x: x.scenario_cov.memory_response_issued,
            "CK-CPU-RESPONSE-SEEN": lambda x: x.scenario_cov.cpu_response_seen,
            "CK-RESPONSE-ID-MATCHED": lambda x: x.scenario_cov.response_id_matched,
        },
        name="FC-PR74-CACHE-IO-IDBITS",
    )
    return [group]


def create_dut(request):
    if not (DUT_FIXED_DIR / "__init__.py").exists():
        raise RuntimeError(
            f"missing Picker DUT package at {DUT_FIXED_DIR}; run scripts/internal/34_prepare_pr74_picker_dut.sh first"
        )
    dut_class = _load_dut_class(DUT_FIXED_DIR)
    dut = dut_class()
    TOFFEE_ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)
    dut.SetCoverage(_tmp_file(request, "pr74_fixed_line.dat", new_path=True))
    dut.SetWaveform(str(TOFFEE_ARTIFACT_DIR / "pr74_fixed_idbits.fst"))
    dut.InitClock("clock")
    dut.scenario_cov = Pr74Coverage()
    return dut


@pytest.fixture(scope="function")
def fixed_env(request):
    dut = create_dut(request)
    groups = get_coverage_groups(dut)
    dut.StepRis(lambda _: [g.sample() for g in groups])
    yield Pr74Env(dut)
    set_func_coverage(request, groups)
    set_line_coverage(
        request,
        _tmp_file(request, "pr74_fixed_line.dat", new_path=False),
        ignore=str(Path(__file__).resolve().parent / "Pr74CacheIOIdBits.ignore"),
    )
    set_user_info("NutShellCacheVerify", "ucagent-dynamic-no-formal")
    set_title_info("PR74 fixed ID Toffee dynamic report")
    for group in groups:
        group.clear()
    dut.Finish()


@dataclass
class Pr74Env:
    dut: object
    cycle: int = 0
    accepted_id: int = TEST_ID
    events: list[str] = field(default_factory=list)

    def initialize(self) -> None:
        _set(self.dut.reset, 1)
        _set(self.dut.io_flush, 0)
        _set(self.dut.io_cpu_req_valid, 0)
        _set(self.dut.io_cpu_req_addr, 0x8000_1000)
        _set(self.dut.io_cpu_req_cmd, SIMPLEBUS_READ)
        _set(self.dut.io_cpu_req_id, TEST_ID)
        _set(self.dut.io_cpu_resp_ready, 1)
        _set(self.dut.io_mem_req_ready, 1)
        _set(self.dut.io_mem_resp_valid, 0)
        _set(self.dut.io_mem_resp_cmd, SIMPLEBUS_READLAST)
        self.step(4)
        _set(self.dut.reset, 0)
        self.step(4)

    def step(self, count: int = 1) -> None:
        for _ in range(count):
            self.dut.Step(1)
            self.cycle += 1
            self.sample()

    def sample(self) -> None:
        cov = self.dut.scenario_cov
        if _u(self.dut.io_cpu_req_valid) and _u(self.dut.io_cpu_req_id) == TEST_ID:
            cov.request_issued_with_id = True
        if _u(self.dut.io_cpu_req_valid) and _u(self.dut.io_cpu_req_ready):
            cov.request_accepted = True
            self.accepted_id = _u(self.dut.io_cpu_req_id)
            self.events.append(f"C{self.cycle}: request accepted id={self.accepted_id}")
        if _u(self.dut.io_mem_resp_valid):
            cov.memory_response_issued = True
        if _u(self.dut.io_cpu_resp_valid):
            cov.cpu_response_seen = True
            if _u(self.dut.io_cpu_resp_id) == self.accepted_id:
                cov.response_id_matched = True
                self.events.append(f"C{self.cycle}: response id matched")

    def run_id_replay(self) -> Pr74Coverage:
        self.initialize()
        _set(self.dut.io_cpu_req_valid, 1)
        _set(self.dut.io_cpu_req_id, TEST_ID)
        for _ in range(8):
            self.step(1)
            if self.dut.scenario_cov.request_accepted:
                break
        _set(self.dut.io_cpu_req_valid, 0)
        self.step(2)
        for _ in range(16):
            _set(self.dut.io_mem_resp_valid, 1)
            _set(self.dut.io_mem_resp_cmd, SIMPLEBUS_READLAST)
            self.step(1)
            if self.dut.scenario_cov.cpu_response_seen:
                break
        _set(self.dut.io_mem_resp_valid, 0)
        self.step(12)
        return self.dut.scenario_cov


def write_pr74_report(summary: dict[str, object], source: str) -> None:
    TOFFEE_ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)
    existing = {}
    if TOFFEE_SUMMARY_JSON.exists():
        existing = json.loads(TOFFEE_SUMMARY_JSON.read_text())
    existing.update(summary)
    existing["source"] = source
    TOFFEE_SUMMARY_JSON.write_text(json.dumps(existing, indent=2), encoding="utf-8")
    fixed = existing.get("fixed", {})
    lines = [
        "# 03 PR74 Toffee 动态后端报告",
        "",
        f"- 分类：`{existing.get('classification', 'UNKNOWN')}`",
        "- pre-PR 动态后端状态：`PICKER_EXPORT_EXPECTED_FAIL`，该历史 bug 是接口/elaboration 失败。",
        "- fixed Python DUT：`reports/artifacts/03_pr74/toffee_dut_fixed`",
        "- Coverage JSON：`reports/artifacts/03_pr74/toffee/coverage_summary.json`",
        f"- 来源：`{source}`",
        "",
        "## fixed Toffee 结果",
        "",
        "| setup_hit/setup_total | response_id_matched |",
        "| --- | --- |",
        f"| `{fixed.get('setup_hit', '?')}/{fixed.get('setup_total', '?')}` | `{fixed.get('response_id_matched', '?')}` |",
        "",
        "## 人工干预",
        "",
        "- UCAgent 负责生成 Toffee/API/pytest 草稿结构。",
        "- 人工补充 fixed response ID scoreboard 和 coverage。",
        "- 本动态后端不调用 formal skill。",
    ]
    TOFFEE_REPORT.write_text("\n".join(lines) + "\n", encoding="utf-8")
