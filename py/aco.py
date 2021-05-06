#!/usr/bin/env python3

"""
ACO (Acoustic Featurization) Software Model

This is used to test our custom acoustic featurization pipeline against
the speechpy implementation used in EdgeImpulse.
"""
# !pip install speechpy
import os
import speechpy
import numpy as np
from scipy.io import wavfile
from scipy.fft import dct
from tqdm.auto import tqdm

train_test_split = 0.75  # fraction to have as training data

# ==================== DFE modelling ====================

ratio_in = 250
ratio_out = 250

def shift_zero_to_one(x):
    '''Shift a 16b signed input signal into the range 0-1.'''
    x = x.astype(np.float64)
    x = x + 2**15
    x = x / 2**16
    return x

def pcm_to_pdm_pwm(x):
    '''Pack all ones and zeros together during upsampling when generating PDM
    signal, effectively creating PWM. This results in much less high frequency
    noise in the signal.'''
    x = shift_zero_to_one(x)
    x = x * ratio_in  # scale up by window so that value is # ones
    x = x.astype(np.uint8)
    repeats = np.zeros(x.size * 2, dtype=np.uint8)
    repeats[::2] = x
    repeats[1::2] = ratio_in - x
    one_zero = np.ones(x.size * 2, dtype=np.uint8)
    one_zero[1::2] = 0
    y = np.repeat(one_zero, repeats)
    return y

def cic1(x):
    '''First cic stage treats datatypes differently.'''
    x = x.astype(np.int64)
    rolled = np.roll(x, ratio_out)
    rolled[:ratio_out] = 0
    x = np.cumsum(x) - np.cumsum(rolled)
    x = x - int(ratio_out/2)
    x = x.astype(np.int8)
    # x = x.astype(np.int16)  # if ratio is >= 256, need this to not overflow
    return x

def pcm_to_pdm(x, pdm_gen='err'):
    '''Generate the PDM signal for the sample.'''
    if pdm_gen == 'pwm':
        y = pcm_to_pdm_pwm(x)
    elif pdm_gen == 'random':
        y = pcm_to_pdm_random(x)
    elif pdm_gen == 'err':
        y = pcm_to_pdm_err(x)
    else:
        raise ValueError('{} not known')
    return y

def pdm_to_pcm(x, n_cic):
    x = cic1(x)
    x = x[::ratio_out]
    x[0] = 0
    return x

def dfe_quantized_model(x):
    x = shift_zero_to_one(x)
    x = x * ratio_out
    x = x - (ratio_out / 2)
    x = x.astype(np.int8)
    return x

def pdm_model(x_orig, model_type='fast'):
    '''Main API interface for the pdm model.

    x_orig: input 16kHz signal
    model_type: type of PDM model
        'fast' is fast quantization model and a worst-case distortion scenario
        'pwm' is the medium-accuracy model which takes ~100ms per sample
    '''
    if model_type == 'fast':
        return dfe_quantized_model(x_orig)
    x_pdm = pcm_to_pdm(x_orig, pdm_gen='pwm')
    return pdm_to_pcm(x_pdm, 1)

# parameters
p = {'num_mfcc_cof': 13,
     'frame_length': 0.02,
     'frame_stride': 0.02,
     'filter_num': 32,
     'fft_length': 256,
     'window_size': 101,
     'low_frequency': 300,
     'preemph_cof': 0.98}

maxes = {}
def detect_max(arr, name):
    '''Detect the maximum bit width at various stages of the pipeline.'''
    global maxes
    val = np.log2(np.abs(arr).max())  # consider absolute magnitude bits
    if (name not in maxes) or (maxes[name] < val):
        maxes[name] = val

def custom_aco(fullfname):
    # Get raw 16b audio data
    fs, signal = wavfile.read(fullfname)

    # DFE quantization model
    signal = pdm_model(signal, model_type='fast')
    signal = signal.astype(np.int16)
    detect_max(signal, 'signal')

    # Acoustic Featurization Constants
    FS = fs                                 # 16 KHz
    PERIOD = 1 / FS                         # 0.0625 ms
    SIGNAL_LENGTH = len(signal) * PERIOD    # 1 s
    FRAME_LENGTH = .02                      # 0.02 s = 20 ms = 320 samples
    NUM_MEL_FILTERS = 32                    # of Mel Scale filterbanks
    NUM_CEPSTRAL = 13                       # MFCC Output
    FFT_LENGTH = 256                        # FFT Length

    # 1) preemphasis
    # =========================================================================
    # Delay by 1 cycle
    rolled_signal = np.roll(signal, 1)

    # preemphasis coefficient of 31 / 32 = 0.96875, quantize via right shift
    scaled_rolled_signal = np.right_shift(31 * rolled_signal, 5)
    detect_max(scaled_rolled_signal, 'scaled_rolled_signal')

    preemphasis_out = signal - scaled_rolled_signal
    detect_max(preemphasis_out, 'preemphasis_out')

    # 2) framing
    # =========================================================================
    # Get NUM_SAMPLES_IN_FRAME-sized non-overlapping frames, truncate as needed
    framing_out = np.split(preemphasis_out, SIGNAL_LENGTH / FRAME_LENGTH)
    framing_out = np.asarray(framing_out)
    framing_out = framing_out[:, :FFT_LENGTH]

    # 3) fft
    # TODO: Check 32b quantization, scaling
    # =========================================================================
    fft_out = np.fft.rfft(framing_out)

    # split into real and imag
    fft_out_real = fft_out.real
    fft_out_imag = fft_out.imag
    detect_max(fft_out_real, 'fft_out_real')
    detect_max(fft_out_imag, 'fft_out_imag')

    # quantize
    fft_out_real = fft_out_real.astype(np.int32)
    fft_out_imag = fft_out_imag.astype(np.int32)

    # check 32b quantization
    assert np.array_equal(fft_out_real, fft_out.real.astype(np.int64))
    assert np.array_equal(fft_out_imag, fft_out.imag.astype(np.int64))

    # 4) power spectrum
    # =========================================================================
    # power spectrum = amplitude spectrum ^ 2 = real^2 + complex^2 / FFT_PTS
    power_spectrum_out = ((fft_out_real.astype(np.int64) *
                           fft_out_real.astype(np.int64)) +
                          (fft_out_imag.astype(np.int64) *
                           fft_out_imag.astype(np.int64)))
    detect_max(power_spectrum_out, 'power_spectrum_out')
    # power_spectrum_out = np.right_shift(power_spectrum_out,
                                        # int(np.log2(FFT_LENGTH)))


    # 5) mel filterbank construction
    # =========================================================================
    mfcc_filterbank = speechpy.feature.filterbanks(NUM_MEL_FILTERS,
                                                   FFT_LENGTH // 2 + 1,
                                                   FS)

    # quantize
    mfcc_filterbank = (mfcc_filterbank * (2 ** 15 - 1)).astype(np.int16)

    # 6) mel filterbank application
    # =========================================================================
    # shift by 15 to cancel initial quantization in step 5)
    mfcc_out = np.dot(power_spectrum_out, mfcc_filterbank.T)
    mfcc_out = np.right_shift(mfcc_out, 15)
    detect_max(mfcc_out, 'mfcc_out')

    # 7) log
    # =========================================================================
    # deal with zero values for log
    mfcc_out[mfcc_out == 0] = 1

    # log base 2
    log_out = np.log2(mfcc_out)

    # quantize, max value is 64, so can use 8b
    log_out = np.floor(log_out)
    log_out = log_out.astype(np.int8)
    detect_max(log_out, 'log_out')


    # 8) dct
    # TODO: Check 16b quantization
    # =========================================================================
    # scipy.fft.dct
    dct_out_raw = dct(log_out, type=2, axis=-1, norm='ortho')[:, :NUM_CEPSTRAL]

    # quantize
    dct_out = dct_out_raw.astype(np.int16)
    detect_max(dct_out, 'dct_out')

    # check 16b quantization
    assert np.array_equal(dct_out_raw.astype(np.int64), dct_out)

    # =========================================================================
    # flatten for use in pipeline
    return dct_out.flatten()

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
    #print('mfcc shape', mfcc.shape)
    # TODO: Why is the output shape here (49, 13) and not (50, 13)?
    # For now just repeat last frame:
    mfcc2 = np.zeros((50, 13))
    mfcc2[:-1,:] = mfcc
    mfcc2[-1,:] = mfcc[-1,:]

    mfcc_cmvn = speechpy.processing.cmvnw(mfcc2, win_size=p['window_size'], variance_normalization=True)

    flattened = mfcc_cmvn.flatten()
    return flattened

def get_fnames(group):
    '''Gets all the filenames (with directories) for a given class.'''
    dir = group + '/'
    fnames = os.listdir(dir)
    fnames = [x for x in fnames if not x.startswith('.')]  # ignore .DS_Store
    fullnames = [dir + fname for fname in fnames]
    return fullnames

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
n = len(all_fnames)
# n = 1
print('num samples: ', n)
all_features = np.zeros((0, 13*50))
for i in tqdm(range(n)):
    fname = all_fnames[i]
    features = custom_aco(fname)
    all_features = np.vstack((all_features, features))
all_labels = np.array(all_labels)

print('max bitwidths detected: ', maxes)

# shuffle the data randomly
idx = np.arange(n, dtype=int)
np.random.shuffle(idx)
features_shuffled = all_features[idx,:]
labels_shuffled = all_labels[idx]

# split the data into train and test sets
split = int(train_test_split * n)
X = features_shuffled[:split,:]
Y = labels_shuffled[:split]
Xtest = features_shuffled[split:,:]
Ytest = labels_shuffled[split:]
