export:
	# find . -name design.v -prune -o -name '*.v' -exec cat {} + > design.v
	find top/ -name '*.v' -exec cat {} + > design.v
	find cfg/ -name '*.v' -exec cat {} + >> design.v
	find wrd/ -name '*.v' -exec cat {} + >> design.v
	find lib/fifo -name '*.v' -exec cat {} + >> design.v
	find lib/dffram -name '*.v' -exec cat {} + >> design.v
