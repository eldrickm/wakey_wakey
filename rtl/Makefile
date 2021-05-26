export:
	# find . -name design.v -prune -o -name '*.v' -exec cat {} + > design.v
	find top/ -name '*.v' -exec cat {} + > design.v
	find cfg/ -name '*.v' -exec cat {} + >> design.v
	find ctl/ -name '*.v' -exec cat {} + >> design.v
	find wrd/ -name '*.v' -exec cat {} + >> design.v
	find dfe/ -name '*.v' -exec cat {} + >> design.v
	find aco/ -name '*.v' -exec cat {} + >> design.v
	find lib/fifo -name '*.v' -exec cat {} + >> design.v
	find lib/dffram -name '*.v' -exec cat {} + >> design.v
	find lib/fft -name '*.v' -exec cat {} + >> design.v
