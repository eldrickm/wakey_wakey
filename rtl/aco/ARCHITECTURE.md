# Acoustic Featurization

Acoustic featurization consists of generating Mel-frequency cepstral
coefficients (MFCC) from input audio data. Audio data is taken in frames every
20ms. 256 samples are used each frame to generate 13 output coefficients. Once
50 frames are buffered they are sent to WRD.

## Blocks

The block breakdown for ACO will be as follows:
- aco
    - preemphasis
    - framing
    - power\_spectrum
        - fft
    - mel\_filterbanks
    - dct
