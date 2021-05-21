# ==============================================================================
# simulation settings
# ==============================================================================
SIM		?= icarus			# simulator (icarus, verilator, ...)
TOPLEVEL_LANG   ?= verilog			# hdl (verilog, vhdl)

# ==============================================================================
# source files
# ==============================================================================
VERILOG_SOURCES += ./*.v
VERILOG_SOURCES += ../preemphasis/*.v
VERILOG_SOURCES += ../framing/*.v
VERILOG_SOURCES += ../../lib/fifo/*.v
VERILOG_SOURCES += ../fft_wrapper/*.v
VERILOG_SOURCES += ../../lib/fft/*.v
VERILOG_SOURCES += ../power_spectrum/*.v
VERILOG_SOURCES += ../filterbank/*.v
VERILOG_SOURCES += ../filterbank_half/*.v
VERILOG_SOURCES += ../log/*.v
VERILOG_SOURCES += ../dct/*.v
VERILOG_SOURCES += ../quant/*.v
VERILOG_SOURCES += ../packing/*.v

$(shell cp ../../lib/fft/*.hex .)  # copy over FFT hex files
$(shell cp ../filterbank/*.hex .)  # copy over MFCC filterbank hex files
$(shell cp ../dct/*.hex .)  # copy over DCT hex files

# ==============================================================================
# modules
# ==============================================================================
MODULE	 = test_aco 			# Python cocotb tests
TOPLEVEL = aco	        		# Top level RTL module

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
