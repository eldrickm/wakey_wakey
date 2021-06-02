# PDM Capture Test

Teensy 3.6 code for capturing PDM data from a Vesper VM3011. Used to verify
the PDM processing pipeline.

Written for 2MHz or 4MHz PDM sampling. Samples are stored in the Teensy's RAM
until 1600000 samples are captured, then the samples are written to Serial to
be captured by the host computer. This results in audio captures that are 800ms
and 400ms long for 2MHz and 4MHz sampling respectively.

To capture data on the host computer, run:

```
cat [serial device] > py/out.bin
```

### Hardware Setup

![Hardware Setup](./img/setup.jpeg)

### Processing

Run `py/parse_pdm_data.py` to process the PDM bitstream into .wav files that can
be listened to.

### Results

- At 4MHz, the PDM clock has to be held low for at least 500us for the
microphone's VAD pin to reset. To ensure enough margin, a timeout of 5ms is
baked into the CTL block of the RTL.
- 2MHz and 4MHz sound quality is comparable. Single CIC stage leaves a decent
amount of high frequency noise, but voice is still clearly audible. A second
CIC stage removes this effectively. You can listen to the results in py/.
- However, The low bit depth from the microphone leaves detection of the wake
word difficult for the rest of the pipeline. For this reason, we are switching
to using a second CIC filter stage. This is now implemented in pdm.py.
