VCS ?= vcs
VCS_FLAGS ?= -full64 -sverilog -timescale=1ns/1ps +vcs+lic+wait
VCS_UVM_FLAGS ?= -ntb_opts uvm-1.2
VCS_LINT_FLAGS ?= +lint=TFIPC-L
VCS_COV_FLAGS ?= -cm line+cond+fsm+tgl+branch
VCS_DEBUG_FLAGS ?= -debug_access+r+w-memcbk -debug_region+cell

FILELIST ?= filelist.f
RTL_FILELIST ?= .rtl_filelist.f
TOP_MODULE ?= sha2_256_core

UVM_TOP ?= sha2_256_tb_top
UVM_TEST ?= sha2_256_all_test
AXI_TOP ?= sha2_256_axi4_smoke_tb
AXI_TB ?= tb/sha2_256_axi4_smoke_tb.sv

SIM_DIR ?= sim
SIMV ?= $(SIM_DIR)/simv
AXI_SIMV ?= $(SIM_DIR)/axi_simv
RUN_LOG ?= $(SIM_DIR)/run_check.log
AXI_RUN_LOG ?= $(SIM_DIR)/axi_run.log
COMPILE_LOG ?= $(SIM_DIR)/compile.log
AXI_COMPILE_LOG ?= $(SIM_DIR)/axi_compile.log
LINT_LOG ?= $(SIM_DIR)/lint.log
COV_DIR ?= $(SIM_DIR)/vcs_cov

.PHONY: all lint compile run axi-compile axi-run coverage clean check-vcs

all: lint compile

$(RTL_FILELIST): $(FILELIST)
	@grep -v '^uvm/' $(FILELIST) | grep -v '^+incdir+uvm/' > $@

check-vcs:
	@command -v $(VCS) >/dev/null 2>&1 || { echo "ERROR: missing Synopsys VCS executable '$(VCS)'. Set VCS=/opt/synopsys/vcs/X-2025.06/bin/vcs."; exit 127; }

lint: check-vcs $(RTL_FILELIST)
	@mkdir -p $(SIM_DIR)
	$(VCS) $(VCS_FLAGS) $(VCS_LINT_FLAGS) -f $(RTL_FILELIST) -top $(TOP_MODULE) -l $(LINT_LOG)

compile: check-vcs
	@mkdir -p $(SIM_DIR)
	$(VCS) $(VCS_FLAGS) $(VCS_UVM_FLAGS) $(VCS_DEBUG_FLAGS) -f $(FILELIST) -top $(UVM_TOP) -o $(SIMV) -l $(COMPILE_LOG)

run: compile
	@mkdir -p $(SIM_DIR)
	$(SIMV) +UVM_TESTNAME=$(UVM_TEST) +UVM_NO_RELNOTES -l $(RUN_LOG)
	@grep -q 'UVM_ERROR :    0' $(RUN_LOG) || { echo "UVM run failed: see $(RUN_LOG)"; exit 1; }
	@grep -q 'UVM_FATAL :    0' $(RUN_LOG) || { echo "UVM run failed: see $(RUN_LOG)"; exit 1; }

axi-compile: check-vcs $(RTL_FILELIST)
	@mkdir -p $(SIM_DIR)
	$(VCS) $(VCS_FLAGS) $(VCS_DEBUG_FLAGS) -f $(RTL_FILELIST) $(AXI_TB) -top $(AXI_TOP) -o $(AXI_SIMV) -l $(AXI_COMPILE_LOG)

axi-run: axi-compile
	@mkdir -p $(SIM_DIR)
	$(AXI_SIMV) -l $(AXI_RUN_LOG)
	@grep -q 'SHA AXI smoke PASS' $(AXI_RUN_LOG) || { echo "AXI smoke failed: see $(AXI_RUN_LOG)"; exit 1; }

coverage: check-vcs
	@mkdir -p $(SIM_DIR)
	$(VCS) $(VCS_FLAGS) $(VCS_UVM_FLAGS) $(VCS_COV_FLAGS) $(VCS_DEBUG_FLAGS) -f $(FILELIST) -top $(UVM_TOP) -o $(SIMV) -l $(COMPILE_LOG)
	$(SIMV) $(VCS_COV_FLAGS) -cm_dir $(COV_DIR) +UVM_TESTNAME=$(UVM_TEST) +UVM_NO_RELNOTES -l $(RUN_LOG)
	@grep -q 'UVM_ERROR :    0' $(RUN_LOG) || { echo "UVM run failed: see $(RUN_LOG)"; exit 1; }
	@grep -q 'UVM_FATAL :    0' $(RUN_LOG) || { echo "UVM run failed: see $(RUN_LOG)"; exit 1; }
	@echo "Coverage database generated at $(COV_DIR)"

clean:
	rm -rf $(SIM_DIR) csrc simv.daidir ucli.key DVEfiles urgReport
	rm -f $(RTL_FILELIST)
	rm -f simv simv.vdb vc_hdrs.h novas.conf novas.rc verdiLog
	rm -f *.log *.vpd *.vcd *.fsdb *.key
