# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

# === cocotb Makefile ===

# === Makefile Variables ===
SIM 				  ?= icarus 	# Simulator (icarus, verilator, ...)
TOPLEVEL_LANG ?= verilog	# HDL (verilog, vhdl, ...)
RTL_DIR = $(shell pwd)
VERILOG_SOURCES = $(RTL_DIR)/*.sv
# ===

MODULE 	 			   = test_dff # Python cocotb tests
TOPLEVEL 			   = dff		  # Top level RTL module

include $(shell cocotb-config --makefiles)/Makefile.sim

clean::
	rm -f results.xml
	rm -rf __pycache__/
