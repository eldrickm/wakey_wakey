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
VERILOG_SOURCES += ../../dfe/dfe/*.v
VERILOG_SOURCES += ../../dfe/pdm_clk/*.v
VERILOG_SOURCES += ../../dfe/sampler/*.v
VERILOG_SOURCES += ../../dfe/filter/*.v
VERILOG_SOURCES += ../../dfe/comb/*.v
VERILOG_SOURCES += ../../dfe/integrator/*.v
VERILOG_SOURCES += ../../dfe/decimator/*.v
VERILOG_SOURCES += ../../aco/aco/*.v
VERILOG_SOURCES += ../../aco/preemphasis/*.v
VERILOG_SOURCES += ../../aco/framing/*.v
VERILOG_SOURCES += ../../aco/fft_wrapper/*.v
VERILOG_SOURCES += ../../lib/fft/*.v
VERILOG_SOURCES += ../../aco/power_spectrum/*.v
VERILOG_SOURCES += ../../aco/filterbank/*.v
VERILOG_SOURCES += ../../aco/filterbank_half/*.v
VERILOG_SOURCES += ../../aco/log/*.v
VERILOG_SOURCES += ../../aco/dct/*.v
VERILOG_SOURCES += ../../aco/quant/*.v
VERILOG_SOURCES += ../../aco/packing/*.v

$(shell cp ../../lib/fft/*.hex .)  # copy over FFT hex files
$(shell cp ../../aco/filterbank/*.hex .)  # copy over MFCC filterbank hex files
$(shell cp ../../aco/dct/*.hex .)  # copy over DCT hex files

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
	rm *.hex

wave:
	gtkwave *.vcd -a *.gtkw
