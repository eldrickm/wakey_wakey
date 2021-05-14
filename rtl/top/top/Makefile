# ==============================================================================
# simulation settings
# ==============================================================================
SIM			    ?= icarus			# simulator (icarus, verilator, ...)
TOPLEVEL_LANG   ?= verilog			# hdl (verilog, vhdl)

# ==============================================================================
# source files
# ==============================================================================
VERILOG_SOURCES += ./*.v
VERILOG_SOURCES += ../../cfg/cfg/*.v
VERILOG_SOURCES += ../../wrd/zero_pad/*.v
VERILOG_SOURCES += ../../wrd/vec_mul/*.v
VERILOG_SOURCES += ../../wrd/vec_add/*.v
VERILOG_SOURCES += ../../wrd/red_add/*.v
VERILOG_SOURCES += ../../wrd/recycler/*.v
VERILOG_SOURCES += ../../wrd/conv_mem/*.v
VERILOG_SOURCES += ../../wrd/relu/*.v
VERILOG_SOURCES += ../../wrd/quantizer/*.v
VERILOG_SOURCES += ../../wrd/conv_top/*.v
VERILOG_SOURCES += ../../wrd/max_pool/*.v
VERILOG_SOURCES += ../../wrd/conv_sipo/*.v
VERILOG_SOURCES += ../../wrd/fc_mem/*.v
VERILOG_SOURCES += ../../wrd/fc_top/*.v
VERILOG_SOURCES += ../../wrd/mac/*.v
VERILOG_SOURCES += ../../wrd/argmax/*.v
VERILOG_SOURCES += ../../wrd/wake/*.v
VERILOG_SOURCES += ../../wrd/wrd/*.v
VERILOG_SOURCES += ../../lib/fifo/*.v
VERILOG_SOURCES += ../../lib/dffram/*.v

# ==============================================================================
# modules
# ==============================================================================
MODULE   = test_wakey_wakey		# python cocotb tests
TOPLEVEL = wakey_wakey			# top level rtl module

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
	gtkwave *.vcd -a *.gtkw
