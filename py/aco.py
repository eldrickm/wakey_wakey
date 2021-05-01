#!/usr/bin/env python3

"""
ACO (Acoustic Featurization) Software Model

This is used to test our custom acoustic featurization pipeline against
the speechpy implementation used in EdgeImpulse.
"""

import os
import numpy as np
from scipy.io import wavfile
import speechpy

# uncomment below to download and unzip keywords dataset
#  os.system('curl -O https://cdn.edgeimpulse.com/datasets/keywords2.zip')
#  os.system('unzip keywords2.zip')

TRAIN_TEST_SPLIT = 0.75  # fraction to have as training data

# parameters
p = {'num_mfcc_cof': 13,
     'frame_length': 0.02,
     'frame_stride': 0.02,
     'filter_num': 32,
     'fft_length': 256,
     'window_size': 101,
     'low_frequency': 300,
     'preemph_cof': 0.98}


def get_features(fullfname, custom=False):
    if custom:
        return custom_aco(fullfname)
    '''Reads a .wav file and outputs the MFCC features.'''
    try:
        fs, data = wavfile.read(fullfname)
    except ValueError:
        print('failed to read file {}, continuing'.format(fullfname))
        return np.zeros(650)

    # generate features
    preemphasized = speechpy.processing.preemphasis(data, cof=p['preemph_cof'], shift=1)
    mfcc = speechpy.feature.mfcc(preemphasized, fs, frame_length=p['frame_length'],
                                 frame_stride=p['frame_stride'], num_cepstral=p['num_mfcc_cof'],
                                 num_filters=p['filter_num'], fft_length=p['fft_length'],
                                 low_frequency=p['low_frequency'])
    # print('mfcc shape', mfcc.shape)
    # TODO: Why is the output shape here (49, 13) and not (50, 13)?
    # For now just repeat last frame:
    mfcc2 = np.zeros((50, 13))
    mfcc2[:-1, :] = mfcc
    mfcc2[-1, :] = mfcc[-1, :]

    mfcc_cmvn = speechpy.processing.cmvnw(mfcc2, win_size=p['window_size'],
                                          variance_normalization=True)

    flattened = mfcc_cmvn#.flatten()
    return flattened


def get_fnames(group):
    '''Gets all the filenames (with directories) for a given class.'''
    dir = group + '/'
    fnames = os.listdir(dir)
    fnames = [x for x in fnames if not x.startswith('.')]  # ignore .DS_Store
    fullnames = [dir + fname for fname in fnames]
    return fullnames


def custom_aco(fullfname):
    # Outstanding Questions:
    # 1) What is our sampling rate? Do we want to anti-alias and downsample?
    #       >> Fs = TODO?
    #       >> Anti-alias / Downsample:
    # 2) Will we plan on constant 1s of samples per activation?
    #       >> Yes!
    #       >> Enforce this at DFE
    # 3) How much will we overlap our frames?
    #       >> 1s -> 50 frames (20ms) stride of 20ms, so no overlap!
    # 4) Do we need a Hamming window? speechpy does not use one
    #       >> Nope
    # 5) Should we buffer the 20ms of data coming in for processing?
    #       >> Buffer the input feature map to the model, after ACO
    #       >> 256 samples?
    # Get raw 16b audio data
    fs, signal = wavfile.read(fullfname)

    # Get MFCC Feature
    FS = fs
    PERIOD = 1 / FS
    SIGNAL_LENGTH = len(signal) * PERIOD
    FRAME_LENGTH = .02  # in seconds
    NUM_MFCC_COEFF = 13
    FFT_LENGTH = 256

    # Fs = 16 KHz = 1 / 0.0625 ms
    # For 20 ms frames, we need 320 samples

    # 1) preemphasis
    # Delay by 1 cycle, multiply 31 and divide by 32 (right bitshift by 5) to get
    # preemphasis coefficient of 31 / 32 = 0.96875
    rolled_signal = np.roll(signal, 1)
    scaled_rolled_signal = np.right_shift(31 * rolled_signal, 5)
    preemphasis_out = signal - scaled_rolled_signal

    # 2) framing
    # Get NUM_SAMPLES_IN_FRAME-sized non-overlapping frames
    framing_out = np.asarray(np.split(preemphasis_out, SIGNAL_LENGTH / FRAME_LENGTH))
    # Only take the first 256 samples of each frame
    framing_out = framing_out[:, :256]

    # 3) fft
    # TODO: How do we quantize the FFT output?
    # seems like we need a 32b output
    fft_out = np.fft.rfft(framing_out)
    # Check that we don't overflow 32b representation out
    assert np.array_equal(fft_out.real.astype(np.int32), fft_out.real.astype(np.int64))
    assert np.array_equal(fft_out.imag.astype(np.int32), fft_out.imag.astype(np.int64))
    fft_out_real = fft_out.real.astype(np.int32)
    fft_out_imag = fft_out.imag.astype(np.int32)

    # 4) power spectrum
    # power spectrum = amplitude spectrum squared = real^2 + complex^2 / FFT_PTS
    # seems like we need a 64b output? can we add a quantization stage here to 32b?
    power_spectrum_out = (fft_out_real.astype(np.int64) * fft_out_real.astype(np.int64)) + (fft_out_imag.astype(np.int64) * fft_out_imag.astype(np.int64))
    power_spectrum_out = np.right_shift(power_spectrum_out, int(np.log2(FFT_LENGTH)))

    # 5) mel filterbank
    # TODO: What should we make our low or high freq?
    mfcc_filterbank_raw = speechpy.feature.filterbanks(NUM_MFCC_COEFF, FFT_LENGTH // 2 + 1,
                                                   FS, low_freq=0, high_freq=FS / 2)
    mfcc_filterbank = (mfcc_filterbank_raw * (2 ** 15 - 1)).astype(np.int16)
    mfcc_out = np.right_shift(np.dot(power_spectrum_out, mfcc_filterbank.T), 15)

    # 6) dct
    pass

    # 7) cmvnw (scaling)
    pass

    features = mfcc_out
    features = features.flatten()
    return features


# collect a big list of filenames and a big list of labels
all_fnames = []
all_labels = []
for group in ['yes', 'unknown', 'noise']:
    fnames = get_fnames(group)
    label = 1 if group == 'yes' else 2
    repeat = 2 if group == 'yes' else 1  # oversample wake word class to balance dataset
    for _ in range(repeat):
        all_fnames.extend(fnames)
        for i in range(len(fnames)):
            all_labels.append(label)

# sample
fullfname = all_fnames[0]

# original pipeline
features_raw = get_features(fullfname)

# Get raw 16b audio data
fs, signal = wavfile.read(fullfname)

# Get MFCC Feature
FS = fs
PERIOD = 1 / FS
SIGNAL_LENGTH = len(signal) * PERIOD
FRAME_LENGTH = .02  # in seconds
NUM_MFCC_COEFF = 13
FFT_LENGTH = 256

# Fs = 16 KHz = 1 / 0.0625 ms
# For 20 ms frames, we need 320 samples

# 1) preemphasis
# Delay by 1 cycle, multiply 31 and divide by 32 (right bitshift by 5) to get
# preemphasis coefficient of 31 / 32 = 0.96875
rolled_signal = np.roll(signal, 1)
scaled_rolled_signal = np.right_shift(31 * rolled_signal, 5)
preemphasis_out = signal - scaled_rolled_signal

# 2) framing
# Get NUM_SAMPLES_IN_FRAME-sized non-overlapping frames
framing_out = np.asarray(np.split(preemphasis_out, SIGNAL_LENGTH / FRAME_LENGTH))
# Only take the first 256 samples of each frame
framing_out = framing_out[:, :256]

# 3) fft
# TODO: How do we quantize the FFT output?
# seems like we need a 32b output
fft_out = np.fft.rfft(framing_out)
# Check that we don't overflow 32b representation out
assert np.array_equal(fft_out.real.astype(np.int32), fft_out.real.astype(np.int64))
assert np.array_equal(fft_out.imag.astype(np.int32), fft_out.imag.astype(np.int64))
fft_out_real = fft_out.real.astype(np.int32)
fft_out_imag = fft_out.imag.astype(np.int32)

# 4) power spectrum
# power spectrum = amplitude spectrum squared = real^2 + complex^2 / FFT_PTS
# seems like we need a 64b output? can we add a quantization stage here to 32b?
power_spectrum_out = (fft_out_real.astype(np.int64) * fft_out_real.astype(np.int64)) + (fft_out_imag.astype(np.int64) * fft_out_imag.astype(np.int64))
power_spectrum_out = np.right_shift(power_spectrum_out, int(np.log2(FFT_LENGTH)))
# seems like we can quantize to a 32b stage after the division?
assert np.array_equal(power_spectrum_out.astype(np.int32), power_spectrum_out.astype(np.int64))

# 5) mel filterbank
# TODO: What should we make our low or high freq?
mfcc_filterbank_raw = speechpy.feature.filterbanks(NUM_MFCC_COEFF, FFT_LENGTH // 2 + 1,
                                               FS, low_freq=0, high_freq=FS / 2)
mfcc_filterbank = (mfcc_filterbank_raw * (2 ** 15 - 1)).astype(np.int16)

mfcc_out_raw = np.dot(power_spectrum_out, mfcc_filterbank_raw.T)
mfcc_out = np.right_shift(np.dot(power_spectrum_out, mfcc_filterbank.T), 15)

import matplotlib.pyplot as plt
for x in mfcc_filterbank_raw:
    plt.plot(x)
    plt.title("Original MFCC Filter Bank")

plt.figure()
for x in mfcc_filterbank:
    plt.plot(x)
    plt.title("Quantized MFCC Filter Bank")


# 6) dct
pass

# 7) cmvnw (scaling)
pass

features = mfcc_out
