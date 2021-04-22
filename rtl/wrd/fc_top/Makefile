# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

# === cocotb Makefile ===

# === Makefile Variables ===
SIM			    ?= icarus			# Simulator (icarus, verilator, ...)
TOPLEVEL_LANG   ?= verilog			# HDL (verilog, vhdl, ...)
RTL_DIR			 = $(shell pwd)
VERILOG_SOURCES += $(RTL_DIR)/*.v
VERILOG_SOURCES += ../../lib/dffram/*.v
VERILOG_SOURCES += ../mac/*.v
VERILOG_SOURCES += ../fc_mem/*.v
MODULE			 = test_fc_top 		# Python cocotb tests
TOPLEVEL         = fc_top	        # Top level RTL module
# ===

include $(shell cocotb-config --makefiles)/Makefile.sim

clean::
	rm -f results.xml
	rm -f *.vcd
	rm -rf __pycache__/

wave:
	gtkwave *.vcd
