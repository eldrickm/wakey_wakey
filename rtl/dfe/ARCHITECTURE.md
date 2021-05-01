# Digital Front-End

The digital front-end of Wakey-Wakey interfaces with a zero-power listening
PDM microphone. A 4MHz clock is supplied to the microphone which sends back
one-bit data at this sample rate. The front-end converts this PDM signal into
PCM, a stream of higher-precision samples at a lower clock rate. This is done
with 3rd party IP:

- [Matrix Creator FPGA Mic Array](https://github.com/matrix-io/matrix-creator-fpga/tree/master/creator_core/rtl/wb_mic_array)
