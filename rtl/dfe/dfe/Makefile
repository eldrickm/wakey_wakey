# ==============================================================================
# simulation settings
# ==============================================================================
SIM		?= icarus			# simulator (icarus, verilator, ...)
TOPLEVEL_LANG   ?= verilog			# hdl (verilog, vhdl)

# ==============================================================================
# source files
# ==============================================================================
VERILOG_SOURCES += ./*.v
VERILOG_SOURCES += ../pdm_clk/*.v
VERILOG_SOURCES += ../sampler/*.v
VERILOG_SOURCES += ../filter/*.v
VERILOG_SOURCES += ../comb/*.v
VERILOG_SOURCES += ../integrator/*.v
VERILOG_SOURCES += ../decimator/*.v

# ==============================================================================
# modules
# ==============================================================================
MODULE	 = test_dfe 			# Python cocotb tests
TOPLEVEL = dfe  	      		# Top level RTL module

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
