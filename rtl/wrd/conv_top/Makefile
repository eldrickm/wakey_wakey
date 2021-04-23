# ==============================================================================
# simulation settings
# ==============================================================================
SIM			    ?= icarus			# simulator (icarus, verilator, ...)
TOPLEVEL_LANG   ?= verilog			# hdl (verilog, vhdl)

# ==============================================================================
# source files
# ==============================================================================
VERILOG_SOURCES += ./*.v
VERILOG_SOURCES += ../vec_mul/*.v
VERILOG_SOURCES += ../vec_add/*.v
VERILOG_SOURCES += ../red_add/*.v
VERILOG_SOURCES += ../recycler/*.v
VERILOG_SOURCES += ../conv_mem/*.v
VERILOG_SOURCES += ../relu/*.v
VERILOG_SOURCES += ../quantizer/*.v
VERILOG_SOURCES += ../../lib/fifo/*.v
VERILOG_SOURCES += ../../lib/dffram/*.v

# ==============================================================================
# modules
# ==============================================================================
MODULE   = test_conv_top			# python cocotb tests
TOPLEVEL = conv_top					# top level rtl module

# ==============================================================================
# cocotb magic
# ==============================================================================
include $(shell cocotb-config --makefiles)/Makefile.sim

# ==============================================================================
# supplemental commands
# ==============================================================================
clean::
	rm -f results.xml
	rm -f *.vcd
	rm -rf __pycache__/

wave:
	gtkwave *.vcd
