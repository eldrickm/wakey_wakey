# Digital Front-End

The digital front-end of Wakey-Wakey interfaces with a zero-power listening
PDM microphone. A 4MHz clock is supplied to the microphone which sends back
one-bit data at this sample rate. The front-end converts this PDM signal into
PCM, a stream of higher-precision samples at a lower clock rate. In this case,
it's 8-bit audio at 16kHz.

# Architecture

The DFE architecture converts the PDM audio signal to PCM using a single stage
[integrator comb filter](https://en.wikipedia.org/wiki/Cascaded_integrator-comb_filter).
It's not a great filter, but it's more than enough for voice decoding. The comb
length and decimation factor is 250, which brings our 4MHz PDM signal down to
16kHz.

## Blocks

- dfe
    - pdm\_clk
    - sampler
    - filter
        - comb
        - integrator
        - decimator

