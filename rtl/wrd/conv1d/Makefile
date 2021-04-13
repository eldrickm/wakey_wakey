# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

# === cocotb Makefile ===

# === Makefile Variables ===
SIM			    ?= icarus			# Simulator (icarus, verilator, ...)
TOPLEVEL_LANG   ?= verilog			# HDL (verilog, vhdl, ...)
RTL_DIR			 = $(shell pwd)
VERILOG_SOURCES += $(RTL_DIR)/*.sv
VERILOG_SOURCES += ../vec_mul/*.sv
VERILOG_SOURCES += ../vec_add/*.sv
VERILOG_SOURCES += ../red_add/*.sv
VERILOG_SOURCES += ../recycler/*.sv
VERILOG_SOURCES += ../conv_mem/*.sv
VERILOG_SOURCES += ../relu/*.sv
VERILOG_SOURCES += ../quantizer/*.sv
VERILOG_SOURCES += ../../lib/fifo/*.v
VERILOG_SOURCES += ../../lib/dffram/*.sv
MODULE			 = test_conv1d		# Python cocotb tests
TOPLEVEL         = conv1d			# Top level RTL module
# ===

include $(shell cocotb-config --makefiles)/Makefile.sim

clean::
	rm -f results.xml
	rm -f *.vcd
	rm -rf __pycache__/

wave:
	gtkwave *.vcd
