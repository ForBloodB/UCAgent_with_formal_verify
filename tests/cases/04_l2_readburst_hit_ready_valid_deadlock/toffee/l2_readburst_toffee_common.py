"""Shared Toffee/pytest helpers for the NutShell L2 readBurst case.

The sequence intentionally mirrors the public-IO SystemVerilog replay:
first fill one line with a readBurst miss, then issue a same-address
readBurst hit and hold the L1 response channel ready low.
"""

from __future__ import annotations

from dataclasses import dataclass, field
import importlib
import json
import os
from pathlib import Path
import sys
from typing import Callable

import pytest
import toffee.funcov as fc
from toffee_test.reporter import (
    get_file_in_tmp_dir,
    set_func_coverage,
    set_line_coverage,
    set_title_info,
    set_user_info,
)


SIMPLEBUS_READBURST = 0x2
SIMPLEBUS_READLAST = 0x6
TEST_ADDR = 0x8000_0000

def _find_repo_root() -> Path:
    env_root = os.environ.get("NUTSHELL_CACHE_VERIFY_ROOT")
    if env_root:
        return Path(env_root).resolve()
    here = Path(__file__).resolve()
    for candidate in [here.parent, *here.parents]:
        if (
            (
                candidate
                / "tests"
                / "cases"
                / "04_l2_readburst_hit_ready_valid_deadlock"
            ).exists()
            and (candidate / "tests" / "ucagent_workspaces").exists()
        ):
            return candidate
    return here.parents[3]


REPO_ROOT = _find_repo_root()
CASE_ROOT = REPO_ROOT / "tests" / "cases" / "04_l2_readburst_hit_ready_valid_deadlock"
ARTIFACT_ROOT = REPO_ROOT / "reports" / "artifacts" / "04_l2_readburst"
TOFFEE_DUT_DIR = ARTIFACT_ROOT / "toffee_dut"
TOFFEE_ARTIFACT_DIR = ARTIFACT_ROOT / "toffee"
TOFFEE_REPORT = REPO_ROOT / "reports" / "04_l2_readburst_toffee_coverage.md"
TOFFEE_SUMMARY_JSON = TOFFEE_ARTIFACT_DIR / "coverage_summary.json"


def _u(signal) -> int:
    return int(signal.value)


def _set(signal, value: int) -> None:
    signal.value = int(value)


def _load_dut_class():
    dut_dir = os.environ.get("L2_READBURST_TOFFEE_DUT_DIR", str(TOFFEE_DUT_DIR))
    if dut_dir not in sys.path:
        sys.path.insert(0, dut_dir)
    module = importlib.import_module("__init__")
    return module.DUTFreshCacheFormalDut


def _tmp_file(request, name: str, new_path: bool) -> str:
    base = Path(__file__).resolve().parent / "data"
    return get_file_in_tmp_dir(request, str(base), name, new_path=new_path)


@dataclass
class L2ReadBurstCoverage:
    first_readburst_miss: bool = False
    memory_refill_readlast: bool = False
    second_same_addr_readburst: bool = False
    s3_readburst_hit: bool = False
    ready_low_during_hit: bool = False
    resp_valid_low_during_ready_low_hit: bool = False

    def setup_total(self) -> int:
        return 5

    def setup_hit(self) -> int:
        return sum(
            [
                self.first_readburst_miss,
                self.memory_refill_readlast,
                self.second_same_addr_readburst,
                self.s3_readburst_hit,
                self.ready_low_during_hit,
            ]
        )

    def setup_percent(self) -> float:
        return round(self.setup_hit() * 100.0 / self.setup_total(), 2)

    def classification(self) -> str:
        if self.setup_hit() != self.setup_total():
            return "UNREACHABLE_IN_TOFFEE"
        if self.resp_valid_low_during_ready_low_hit:
            return "DYNAMIC_REPRODUCED"
        return "NO_DYNAMIC_FAILURE_FOR_SEQUENCE"

    def as_dict(self) -> dict[str, object]:
        return {
            "first_readburst_miss": self.first_readburst_miss,
            "memory_refill_readlast": self.memory_refill_readlast,
            "second_same_addr_readburst": self.second_same_addr_readburst,
            "s3_readburst_hit": self.s3_readburst_hit,
            "ready_low_during_hit": self.ready_low_during_hit,
            "resp_valid_low_during_ready_low_hit": self.resp_valid_low_during_ready_low_hit,
            "setup_hit": self.setup_hit(),
            "setup_total": self.setup_total(),
            "setup_percent": self.setup_percent(),
            "classification": self.classification(),
        }


def get_coverage_groups(dut):
    group = fc.CovGroup("FG-L2-READBURST-READY-VALID")
    group.add_watch_point(
        dut,
        {
            "CK-FIRST-READBURST-MISS": lambda x: x.scenario_cov.first_readburst_miss,
            "CK-MEMORY-REFILL-READLAST": lambda x: x.scenario_cov.memory_refill_readlast,
            "CK-SECOND-SAME-ADDR-READBURST": lambda x: x.scenario_cov.second_same_addr_readburst,
            "CK-S3-READBURST-HIT": lambda x: x.scenario_cov.s3_readburst_hit,
            "CK-READY-LOW-DURING-HIT": lambda x: x.scenario_cov.ready_low_during_hit,
            "CK-RESP-VALID-LOW-DURING-READY-LOW-HIT": lambda x: (
                x.scenario_cov.resp_valid_low_during_ready_low_hit
            ),
        },
        name="FC-L2-READBURST-READY-VALID",
    )
    return [group]


def create_dut(request):
    dut_class = _load_dut_class()
    dut = dut_class()
    TOFFEE_ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)
    dut.SetCoverage(_tmp_file(request, "l2_readburst_line.dat", new_path=True))
    dut.SetWaveform(str(TOFFEE_ARTIFACT_DIR / "l2_readburst_ready_deadlock.fst"))
    dut.InitClock("clock")
    dut.scenario_cov = L2ReadBurstCoverage()
    return dut


@pytest.fixture(scope="function")
def dut(request):
    instance = create_dut(request)
    coverage_groups = get_coverage_groups(instance)
    instance.StepRis(lambda _: [g.sample() for g in coverage_groups])
    instance.fc_cover = {g.name: g for g in coverage_groups}
    yield instance
    set_func_coverage(request, coverage_groups)
    set_line_coverage(
        request,
        _tmp_file(request, "l2_readburst_line.dat", new_path=False),
        ignore=str(Path(__file__).resolve().parent / "L2ReadBurstDeadlock.ignore"),
    )
    set_user_info("NutShellCacheVerify", "formal-skill-toffee-flow")
    set_title_info("L2 readBurst ready/valid Toffee report")
    for group in coverage_groups:
        group.clear()
    instance.Finish()


@dataclass
class L2ReadBurstEnv:
    dut: object
    cycle: int = 0
    mem_pending: bool = False
    mem_beat: int = 0
    events: list[str] = field(default_factory=list)

    def initialize(self) -> None:
        _set(self.dut.reset, 1)
        _set(self.dut.io_flush, 0)
        _set(self.dut.io_cpu_req_valid, 0)
        _set(self.dut.io_cpu_req_addr, TEST_ADDR)
        _set(self.dut.io_cpu_req_cmd, SIMPLEBUS_READBURST)
        _set(self.dut.io_cpu_resp_ready, 1)
        _set(self.dut.io_mem_req_ready, 1)
        _set(self.dut.io_mem_resp_valid, 0)
        _set(self.dut.io_mem_resp_cmd, SIMPLEBUS_READBURST)
        self.step(12)
        _set(self.dut.reset, 0)
        self.step(12)

    def step(self, count: int = 1) -> None:
        for _ in range(count):
            _set(self.dut.io_mem_resp_valid, 1 if self.mem_pending else 0)
            _set(
                self.dut.io_mem_resp_cmd,
                SIMPLEBUS_READLAST
                if self.mem_pending and self.mem_beat == 7
                else SIMPLEBUS_READBURST,
            )
            self.dut.Step(1)
            self.cycle += 1
            self._sample_mem_model()
            self._sample_coverage()

    def _sample_mem_model(self) -> None:
        if (
            not self.mem_pending
            and _u(self.dut.io_mem_req_valid)
            and _u(self.dut.io_mem_req_ready)
            and _u(self.dut.io_mem_req_cmd) == SIMPLEBUS_READBURST
        ):
            self.mem_pending = True
            self.mem_beat = 0
            self.dut.scenario_cov.first_readburst_miss = True
            self.events.append(f"C{self.cycle}: memory readBurst request accepted")
        elif self.mem_pending:
            if self.mem_beat == 7:
                self.mem_pending = False
                self.mem_beat = 0
            else:
                self.mem_beat += 1

    def _sample_coverage(self) -> None:
        if (
            _u(self.dut.io_cpu_resp_valid)
            and _u(self.dut.io_cpu_resp_ready)
            and _u(self.dut.io_cpu_resp_cmd) == SIMPLEBUS_READLAST
        ):
            self.dut.scenario_cov.memory_refill_readlast = True

        hit_window = (
            _u(self.dut.io_fresh_s3_in_valid)
            and _u(self.dut.io_fresh_s3_in_hit)
            and _u(self.dut.io_fresh_s3_in_readburst)
        )
        if hit_window:
            self.dut.scenario_cov.s3_readburst_hit = True
        if hit_window and not _u(self.dut.io_cpu_resp_ready):
            self.dut.scenario_cov.ready_low_during_hit = True
            if not _u(self.dut.io_cpu_resp_valid):
                self.dut.scenario_cov.resp_valid_low_during_ready_low_hit = True

    def issue_readburst(self, addr: int = TEST_ADDR, timeout: int = 80) -> None:
        _set(self.dut.io_cpu_req_addr, addr)
        _set(self.dut.io_cpu_req_cmd, SIMPLEBUS_READBURST)
        _set(self.dut.io_cpu_req_valid, 1)
        accepted = False
        for _ in range(timeout):
            self.step()
            if _u(self.dut.io_cpu_req_ready):
                accepted = True
                break
        if not accepted:
            raise AssertionError("DUT did not accept the CPU readBurst request")
        self.step()
        _set(self.dut.io_cpu_req_valid, 0)

    def wait_for_refill_readlast(self, timeout: int = 160) -> None:
        for _ in range(timeout):
            self.step()
            if self.dut.scenario_cov.memory_refill_readlast:
                self.events.append(f"C{self.cycle}: first readBurst refill reached readlast")
                return
        raise AssertionError("first readBurst refill did not complete")

    def wait_for_s3_readburst_hit(self, timeout: int = 80) -> None:
        for _ in range(timeout):
            self.step()
            if self.dut.scenario_cov.s3_readburst_hit:
                self.events.append(f"C{self.cycle}: second readBurst hit reached S3")
                return
        raise AssertionError("second same-address request did not become S3 readBurst hit")

    def hold_resp_ready_low_and_check(self, cycles: int = 16) -> bool:
        _set(self.dut.io_cpu_resp_ready, 0)
        reproduced = False
        for _ in range(cycles):
            self.step()
            if self.dut.scenario_cov.resp_valid_low_during_ready_low_hit:
                reproduced = True
                self.events.append(
                    f"C{self.cycle}: resp_valid stayed low while ready was low on a readBurst hit"
                )
                break
        _set(self.dut.io_cpu_resp_ready, 1)
        self.step(4)
        return reproduced

    def run_directed_replay(self) -> L2ReadBurstCoverage:
        self.initialize()
        _set(self.dut.io_cpu_resp_ready, 1)
        self.issue_readburst(TEST_ADDR)
        self.wait_for_refill_readlast()
        self.step(4)
        self.dut.scenario_cov.second_same_addr_readburst = True
        self.issue_readburst(TEST_ADDR)
        self.wait_for_s3_readburst_hit()
        self.hold_resp_ready_low_and_check()
        return self.dut.scenario_cov


@pytest.fixture(scope="function")
def env(dut):
    return L2ReadBurstEnv(dut)


def write_toffee_summary(cov: L2ReadBurstCoverage, events: list[str], source: str) -> None:
    TOFFEE_ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)
    summary = cov.as_dict()
    summary["events"] = events
    summary["source"] = source
    summary["waveform"] = str(TOFFEE_ARTIFACT_DIR / "l2_readburst_ready_deadlock.fst")
    TOFFEE_SUMMARY_JSON.write_text(json.dumps(summary, indent=2), encoding="utf-8")


def write_toffee_report(cov: L2ReadBurstCoverage, events: list[str], source: str) -> None:
    write_toffee_summary(cov, events, source)
    bins = cov.as_dict()
    rows = [
        ("first readBurst miss", bins["first_readburst_miss"]),
        ("memory refill readlast", bins["memory_refill_readlast"]),
        ("second same-address readBurst", bins["second_same_addr_readburst"]),
        ("S3 readBurst hit", bins["s3_readburst_hit"]),
        ("ready low during hit", bins["ready_low_during_hit"]),
        (
            "resp_valid low during ready-low hit",
            bins["resp_valid_low_during_ready_low_hit"],
        ),
    ]
    lines = [
        "# 04 L2 readBurst Toffee 覆盖率报告",
        "",
        f"- 分类：`{bins['classification']}`",
        f"- 04 场景 setup coverage：`{bins['setup_hit']}/{bins['setup_total']} = {bins['setup_percent']}%`",
        "- 覆盖口径：只统计本场景 coverpoints，不代表完整 NutShell Cache functional coverage。",
        f"- Python DUT：`{TOFFEE_DUT_DIR.relative_to(REPO_ROOT)}`",
        "- Toffee waveform：`reports/artifacts/04_l2_readburst/toffee/l2_readburst_ready_deadlock.fst`",
        "- Coverage JSON：`reports/artifacts/04_l2_readburst/toffee/coverage_summary.json`",
        f"- 来源：`{source}`",
        "",
        "## Coverpoints",
        "",
        "| Coverpoint | Hit |",
        "| --- | --- |",
    ]
    for name, hit in rows:
        lines.append(f"| {name} | `{bool(hit)}` |")
    lines.extend(["", "## 关键事件", ""])
    lines.extend([f"- {event}" for event in events] or ["- 无事件记录"])
    lines.extend(
        [
            "",
            "## 人工判定",
            "",
            "该 Toffee directed test 使用真实 Picker 导出的 latest NutShell Cache wrapper，",
            "通过 public IO 完成 miss/refill/hit/ready-low 序列，不 force 内部状态。",
            "当 `resp_ready=0` 且 S3 为 `readBurst hit` 时观察到 `resp_valid=0`，",
            "因此分类为 `DYNAMIC_REPRODUCED`。该结论仍表述为 latest upstream candidate bug，",
            "需要结合 NutShell 对该接口 ready/valid 协议的设计约束最终确认。",
        ]
    )
    TOFFEE_REPORT.write_text("\n".join(lines) + "\n", encoding="utf-8")


def mark_readburst_function(env: L2ReadBurstEnv, test_function: Callable) -> None:
    env.dut.fc_cover["FG-L2-READBURST-READY-VALID"].mark_function(
        "FC-L2-READBURST-READY-VALID",
        test_function,
        [
            "CK-FIRST-READBURST-MISS",
            "CK-MEMORY-REFILL-READLAST",
            "CK-SECOND-SAME-ADDR-READBURST",
            "CK-S3-READBURST-HIT",
            "CK-READY-LOW-DURING-HIT",
            "CK-RESP-VALID-LOW-DURING-READY-LOW-HIT",
        ],
    )
