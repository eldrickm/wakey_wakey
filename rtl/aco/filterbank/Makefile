# ==============================================================================
# simulation settings
# ==============================================================================
SIM		?= icarus			# simulator (icarus, verilator, ...)
TOPLEVEL_LANG   ?= verilog			# hdl (verilog, vhdl)

# ==============================================================================
# source files
# ==============================================================================
VERILOG_SOURCES += ./*.v
VERILOG_SOURCES += ../filterbank_half/*.v

# ==============================================================================
# modules
# ==============================================================================
MODULE	 = test_filterbank 			# Python cocotb tests
TOPLEVEL = filterbank	       		# Top level RTL module

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
	rm *.hex

wave:
	gtkwave *.vcd -a view.gtkw
