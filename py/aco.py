#!/usr/bin/env python3

"""
ACO (Acoustic Featurization) Software Model
"""

import os
import speechpy
import numpy as np
from scipy.io import wavfile

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


def get_features(fullfname):
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

    flattened = mfcc_cmvn.flatten()
    return flattened


def get_fnames(group):
    '''Gets all the filenames (with directories) for a given class.'''
    dir = group + '/'
    fnames = os.listdir(dir)
    fnames = [x for x in fnames if not x.startswith('.')]  # ignore .DS_Store
    fullnames = [dir + fname for fname in fnames]
    return fullnames


def aco(signal):
    # TODO:
    # 1) Compute mel filterbank coefficients, quantized

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

    # 1) preemphasis
    # delay by 1, preemphasis coefficient = 31 / 32 = 0.96875
    rolled_signal = np.roll(signal, 1)
    preemphasis_out = signal - 31 * rolled_signal / 32

    # 2) framing

    # 3) fft
    # FFT on each frame

    # 4) power spectrum
    # power spectrum = amplitude spectrum squared = real^2 + complex^2 / FFT_PTS

    # 6) mel filterbank elementwise multiplicaton (parallelized x13)

    # 7) dct

    # 8) cmvnw (scaling)


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

# get a big list of mfcc features
N = len(all_fnames)
print('num samples: ', N)
all_features = np.zeros((0, 13 * 50))
for fname in all_fnames:
    features = get_features(fname)
    all_features = np.vstack((all_features, features))
all_labels = np.array(all_labels)

# shuffle the data randomly
idx = np.arange(N, dtype=int)
np.random.shuffle(idx)
features_shuffled = all_features[idx, :]
labels_shuffled = all_labels[idx]

# split the data into train and test sets
split = int(TRAIN_TEST_SPLIT * N)
X = features_shuffled[:split, :]
Y = labels_shuffled[:split]
Xtest = features_shuffled[split:, :]
Ytest = labels_shuffled[split:]
