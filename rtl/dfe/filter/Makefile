# ==============================================================================
# simulation settings
# ==============================================================================
SIM		?= icarus			# simulator (icarus, verilator, ...)
TOPLEVEL_LANG   ?= verilog			# hdl (verilog, vhdl)

# ==============================================================================
# source files
# ==============================================================================
VERILOG_SOURCES += ./*.v
VERILOG_SOURCES += ../../lib/fifo/*.v
VERILOG_SOURCES += ../comb/*.v
VERILOG_SOURCES += ../integrator/*.v
VERILOG_SOURCES += ../decimator/*.v

# ==============================================================================
# modules
# ==============================================================================
MODULE	 = test_filter 			# Python cocotb tests
TOPLEVEL = filter        		# Top level RTL module

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
	gtkwave *.vcd -a view.gtkw
