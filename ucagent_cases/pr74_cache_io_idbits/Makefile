CASE_NAME = pr74_cache_io_idbits
PICKER ?= picker
PYTEST ?= pytest
UC_TEST_DIR = unity_test/tests
UC_REPORT_DIR = uc_test_report

.PHONY: gen_dut_buggy gen_dut_fixed gen_dut_buggy_as_fixed test_buggy_directed test_fixed_directed test_ucagent_official clean clean_dut clean_ucagent

gen_dut_buggy:
	@chmod -R u+w CaseBuggy 2>/dev/null || true
	@rm -rf CaseBuggy
	$(PICKER) export --autobuild=true rtl/CaseBuggy.sv \
		--sname CaseBuggy \
		--tname CaseBuggy \
		--tdir CaseBuggy \
		--lang python \
		--sim verilator \
		-e -c
	@cp prompts/ucagent_prompt.md CaseBuggy/README.md
	@echo "[gen] $(CASE_NAME) CaseBuggy exported by picker"

gen_dut_fixed:
	@chmod -R u+w CaseFixed 2>/dev/null || true
	@rm -rf CaseFixed
	$(PICKER) export --autobuild=true rtl/CaseFixed.sv \
		--sname CaseFixed \
		--tname CaseFixed \
		--tdir CaseFixed \
		--lang python \
		--sim verilator \
		-e -c
	@cp prompts/ucagent_prompt.md CaseFixed/README.md
	@echo "[gen] $(CASE_NAME) CaseFixed exported by picker"

gen_dut_buggy_as_fixed:
	@chmod -R u+w CaseFixed 2>/dev/null || true
	@rm -rf CaseFixed
	$(PICKER) export --autobuild=true rtl/CaseBuggy.sv \
		--sname CaseBuggy \
		--tname CaseFixed \
		--tdir CaseFixed \
		--lang python \
		--sim verilator \
		-e -c
	@cp prompts/ucagent_prompt.md CaseFixed/README.md
	@echo "[gen] $(CASE_NAME) CaseBuggy exported as CaseFixed for replay"

test_buggy_directed: gen_dut_buggy
	@CASE_VARIANT=buggy PYTHONPATH=.:src pytest -q test/test_directed.py

test_fixed_directed: gen_dut_fixed
	@CASE_VARIANT=fixed PYTHONPATH=.:src pytest -q test/test_directed.py

test_ucagent_official:
	@if [ ! -d "$(UC_TEST_DIR)" ]; then echo "missing $(UC_TEST_DIR)"; exit 2; fi
	@PYTHONPATH=.:$(UC_TEST_DIR):src $(PYTEST) -s \
		--toffee-report \
		--report-dump-json \
		--report-name=index.html \
		--report-dir=$(UC_REPORT_DIR) \
		$(UC_TEST_DIR)

clean_dut:
	@chmod -R u+w CaseBuggy CaseFixed build_CaseBuggy build_CaseFixed 2>/dev/null || true
	@rm -rf CaseBuggy CaseFixed build_CaseBuggy build_CaseFixed

clean_ucagent:
	@chmod -R u+w .ucagent unity_test uc_test_report AGENTS.md Guide_Doc log 2>/dev/null || true
	@rm -rf .ucagent unity_test uc_test_report AGENTS.md Guide_Doc log

clean: clean_dut clean_ucagent
	@rm -rf .generated .pytest_cache __pycache__ src/**/__pycache__ test/**/__pycache__
