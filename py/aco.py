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

# ==================== ACO modelling ====================

maxes = {}
def detect_max(arr, name):
    '''Detect the maximum bit width at various stages of the pipeline. Does
    not include the sign bit for signed numbers.'''
    global maxes
    absmax = np.abs(arr.astype(np.float64)).max()
    absmax = np.max((absmax, 1))  # avoid inf in log
    val = np.log2(absmax)  # consider absolute magnitude bits
    # print(name, 'bitwidth', val)
    if (name not in maxes) or (maxes[name] < val):
        maxes[name] = val

def print_maxes():
    print('Max bit values detected during featurisation:')
    for k in maxes:
        print('\t{:20} {}'.format(k, maxes[k]))

def gen_dct_coefs():
    '''Type 2 dct with 'ortho' norm.
    See https://docs.scipy.org/doc/scipy/reference/generated/scipy.fft.dct.html.
    '''
    DCT_LEN = 32
    N_COEFS = 13
    coefs = np.zeros((N_COEFS, DCT_LEN))
    n = np.arange(DCT_LEN)
    for k in range(N_COEFS):
        coefs[k,:] = np.cos(np.pi * k * (2*n + 1) / (2 * DCT_LEN))
        if k == 0:
            coefs[k,:] *= 2 * np.sqrt(1/(4*DCT_LEN))
        else:
            coefs[k,:] *= 2 * np.sqrt(1/(2*DCT_LEN))
    coefs = np.round(coefs * 2**15).astype(np.int16)
    return coefs.T

dct_coefs = gen_dct_coefs().astype(np.int64)

def aco(signal, fft_override=None):
    '''Quantized python model of the ACO pipeline.

    If fft_override is not None, use the value supplied as the fft output for
    the rest of the calculations.'''
    fs = 16000
    signal = signal.astype(np.int16)  # increase bitwidth for preemphasis
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
    rolled_signal[0] = 0  # zero out initial value

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
    # fft_out = np.fft.rfft(framing_out)
    if fft_override is None:
        fft_out = np.fft.rfft(framing_out) / 8  # RTL FFT scaled down by 8
    else:
        fft_out = fft_override

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
                                                   FFT_LENGTH,
                                                   FS)[:,:129]

    # quantize
    mfcc_filterbank = (mfcc_filterbank * (2 ** 16 - 1)).astype(np.uint16)

    # 6) mel filterbank application
    # =========================================================================
    # shift by 16 to cancel initial quantization in step 5)
    mfcc_out = np.dot(power_spectrum_out, mfcc_filterbank.T)
    mfcc_out = np.right_shift(mfcc_out, 16)
    detect_max(mfcc_out, 'mfcc_out')

    # 7) log
    # =========================================================================
    n_frames, n_mfcc = mfcc_out.shape
    log_out = np.zeros((n_frames, n_mfcc), dtype=np.uint8)
    for i in range(n_frames):
        for j in range(n_mfcc):
            for k in range(31, -1, -1):
                if mfcc_out[i,j] & (1 << k):
                    log_out[i,j] = k + 1
                    break
    detect_max(log_out, 'log_out')

    # 8) dct
    # TODO: Check 16b quantization
    # =========================================================================
    # scipy.fft.dct
    log_out = log_out.astype(np.int64)
    dct_out_raw = np.dot(log_out, dct_coefs).astype(np.int64)
    dct_out_raw = np.right_shift(dct_out_raw, 15)

    # quantize
    dct_out = dct_out_raw.astype(np.int16)
    detect_max(dct_out, 'dct_out')

    # check 16b quantization
    assert np.array_equal(dct_out_raw.astype(np.int64), dct_out)

    # 9) quantize to byte
    # =========================================================================
    quant_out = np.clip(dct_out, -2**7, 2**7-1)

    # =========================================================================
    # flatten for use in pipeline
    out = quant_out.flatten()

    # collect intermediate values for RTL verification
    sigs = [preemphasis_out, framing_out, fft_out, power_spectrum_out,
            mfcc_out, log_out, dct_out, quant_out, out]

    return sigs

def aco_with_dfe(fullfname):
    '''Quantized python model of the ACO pipeline.'''
    # Get raw 16b audio data
    fs, signal = wavfile.read(fullfname)

    # DFE quantization model
    signal = pdm_model(signal, model_type='fast')
    # signal = pdm_model(signal, model_type='accurate')
    detect_max(signal, 'signal')
    return aco(signal)[-1]

def get_speechpy_features(fullfname):
    '''Reads a .wav file and outputs the MFCC features using SpeechPy.'''
    # parameters:
    p = {'num_mfcc_cof': 13,
         'frame_length': 0.02,
         'frame_stride': 0.02,
         'filter_num': 32,
         'fft_length': 256,
         'window_size': 101,
         'low_frequency': 300,
         'preemph_cof': 0.98}
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

def get_fnames_group(group):
    '''Gets all the filenames (with directories) for a given class.'''
    dir = group + '/'
    fnames = os.listdir(dir)
    fnames = [x for x in fnames if not x.startswith('.')]  # ignore .DS_Store
    fullnames = [dir + fname for fname in fnames]
    return fullnames

def get_fnames_and_labels():
    '''Collect a big list of filenames and a big list of labels.'''
    all_fnames = []
    all_labels = []
    for group in ['yes', 'unknown', 'noise']:
        fnames = get_fnames_group(group)
        label = 1 if group == 'yes' else 2
        repeat = 2 if group == 'yes' else 1  # oversample wake word class to balance dataset
        for _ in range(repeat):
            all_fnames.extend(fnames)
            for i in range(len(fnames)):
                all_labels.append(label)
    all_labels = np.array(all_labels)
    return all_fnames, all_labels

def get_features_quantized(all_fnames):
    '''Get a big list of mfcc features for each wav file.'''
    n = len(all_fnames)
    # n = 1
    print('num samples: ', n)
    all_features = np.zeros((0, 13*50))
    for i in tqdm(range(n)):
        fname = all_fnames[i]
        features = aco_with_dfe(fname)
        all_features = np.vstack((all_features, features))
    print_maxes()
    return all_features

def shuffle_and_split(all_features, all_labels):
    '''First shuffle the data randomly, then split it into test and train.'''
    np.random.seed(1)
    n = len(all_labels)
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
    return X, Y, Xtest, Ytest

def generate_features():
    '''Main function for generating MFCC features.'''
    all_fnames, all_labels = get_fnames_and_labels()
    all_features = get_features_quantized(all_fnames)
    return shuffle_and_split(all_features, all_labels)

# X, Y, Xtest, Ytest = generate_features()
