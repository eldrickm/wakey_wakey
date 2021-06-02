import os
import numpy as np
from scipy.io import wavfile
from scipy import signal
import matplotlib.pyplot as plt
import struct
import serial
# import sounddevice as sd
import pyaudio

import sys
sys.path.append('../../../py/')
import pdm
import aco
import numpy_arch as na

TEENSY_PORT = '/dev/cu.usbmodem28376501'

pdm_dir = 'pdm_inputs/'
categories = ['yes/', 'other/']
wav_save_dir = 'wav/'

ONE_SEC_LEN = 4000000
# ONE_SEC_LEN = 2000000
REC_LEN = 2000000

def get_pdm(serial_port=None):
    '''Parse the PDM bitstream into a numpy array of ones and zeros.'''
    if serial_port is not None:
        ser = serial.Serial(port=serial_port)
        ser.timeout = 1
        cleared = ser.read(ONE_SEC_LEN * 100)  # clear out buffer
        print('cleared ', len(cleared), ' bytes')
        ser.timeout = None
        data = ser.read(int(REC_LEN / 8))
        # print('read ', len(data), 'bytes')
        ser.close()
    else:
        data = open('out.bin', 'rb').read()
    x_bytes = np.frombuffer(data, dtype='B')
    x = np.unpackbits(x_bytes, bitorder='little')
    return x


def process_pdm(x):
    '''Filter the PDM array three different ways and save .wav files.'''
    dfe_y_1cic = pdm.pdm_to_pcm(x, 1)  # this is the same as the RTL model
    dfe_y_2cic = pdm.pdm_to_pcm(x, 2)
    y = signal.decimate(x, 25)  # ideal FIR decimating filter
    y = signal.decimate(y, 10)
    wavfile.write('out_perfect_fir.wav', 16000, y)
    wavfile.write('out_dfe_1cic_4mhz.wav', 16000, (dfe_y_1cic + 125).astype(np.uint8))
    wavfile.write('out_dfe_2cic_4mhz.wav', 16000, dfe_y_2cic)

    return y, dfe_y_1cic, dfe_y_2cic

def process_pdm_dfe():
    x = get_pdm()
    process_pdm(x)

def pad_pdm(x_pdm):
    '''Pad a short pdm signal to length.'''
    x = np.zeros(ONE_SEC_LEN)
    x[1::2] = 1
    x[-REC_LEN:] = x_pdm
    return x

maxes = {}
log_maxes = {}
def detect_max(arr, name):
    '''Detect the maximum bit width at various stages of the pipeline. Does
    not include the sign bit for signed numbers.'''
    global maxes
    absmax = np.abs(arr.astype(np.float64)).max()
    absmax = np.max((absmax, 1))  # avoid inf in log
    val = np.log2(absmax)  # consider absolute magnitude bits
    # print(name, 'bitwidth', val)
    if (name not in log_maxes) or (log_maxes[name] < val):
        log_maxes[name] = val
    if (name not in maxes) or (maxes[name] < absmax):
        maxes[name] = absmax

def print_maxes():
    print('Max bit values detected during featurisation:')
    for k in maxes:
        print('\t{:20} {:.03f}   {:.03f}'.format(k, log_maxes[k], maxes[k]))

def process_pdm_wake(source='mic', method='cic1'):
    if source[-4:] == '.wav':  # 16b wavfile saved on computer
        fs, x = wavfile.read(source)
        x = x[:16000] / 2**8
        dfe_out = x
    elif source == 'mic':  # pdm microphone
        x = get_pdm(serial_port=TEENSY_PORT)
        x = pad_pdm(x)
    elif source[-4:] == '.npy':  # saved pdm sample
        x = np.load(source, allow_pickle=True)
        x = pad_pdm(x)
    else:
        raise Exception('unkown source ' + source)
    if source[-4] != '.wav':  # process pdm to pcm if not a wav file
        if method == 'cic1':
            dfe_out = pdm.pdm_to_pcm(x, 1).astype(np.int16)
            dfe_out *= 8
            dfe_out = np.clip(dfe_out, -128, 127).astype(np.int8)
        elif method == 'cic2':
            dfe_out = pdm.pdm_to_pcm(x, 2)
            # dfe_out = dfe_out / 2**5  # scaling now in pdm.py
            # dfe_out = np.clip(dfe_out, -128, 127).astype(np.int8)
        elif method == 'ideal':  # ideal decimation
            dfe_out = signal.decimate(x, 10)
            dfe_out = signal.decimate(dfe_out, 5)
            dfe_out = signal.decimate(dfe_out, 5)
        else:
            raise Exception('unkown method ' + method)
    detect_max(dfe_out, 'dfe_out')
    if False:  # rescaling
        dfe_out = dfe_out.astype(np.float32)
        dfe_out[:5] = dfe_out.mean()
        dfe_out -= dfe_out.min()
        dfe_out *= 2**8 / dfe_out.max()
        dfe_out -= 2**7
        dfe_out = dfe_out.astype(np.int8)

    aco_out = aco.aco(dfe_out)[-1]
    aco_out = aco_out.reshape((int(aco_out.size / 13), 13))
    wrd_out = na.get_numpy_pred(aco_out)[0]
    wake = (wrd_out[0] > wrd_out[1])
    if wake:
        print('WAKE!')
    else:
        print('sleep.')
    return x, dfe_out, wake

def process_pdm_wake_continuous():
    while True:
        process_pdm_wake()

def save_rec(x):
    x = x.astype(np.float32)
    x += x.min()
    x /= x.max() / 2
    x -= 1
    wavfile.write('saved.wav', 16000, x)

def plot_pdm(x):
    x = x.reshape((int(x.size / 8), 8)).sum(1)
    plt.plot(x)

def save_pdm(fname):
    x = get_pdm(serial_port=TEENSY_PORT)
    np.save(fname, x)

def save_pdm_multiple(category, start_idx, num):
    for i in range(start_idx, start_idx + num):
        fname = pdm_dir + category + '/' + category + str(i) + '.npy'
        save_pdm(fname);

def pdm_to_wav(fname_in, fname_out):
    x = np.load(fname_in, allow_pickle=True)
    y = signal.decimate(x, 10)  # ideal FIR decimating filter
    y = signal.decimate(y, 5)
    y = signal.decimate(y, 5)
    wavfile.write(fname_out, 16000, y)

def pdm_to_wav_multiple():
    '''Parse pdm files in pdm_dir to check their contents.'''
    for category in categories:
        in_dir = pdm_dir + category
        out_dir = pdm_dir + category + wav_save_dir
        fnames = os.listdir(in_dir)
        for fname in fnames:
            if fname[-4:] != '.npy':
                continue
            pdm_to_wav(in_dir + fname, out_dir + fname[:-4] + '.wav')

def eval_pipeline(method='cic1'):
    n_valid_wake = 0
    n_false_wake = 0
    n_valid_sleep = 0
    n_false_sleep = 0
    for category in categories:
        in_dir = pdm_dir + category
        fnames = os.listdir(in_dir)
        for fname in fnames:
            if fname[-4:] != '.npy':
                continue
            full_path = in_dir + fname
            print('Processing', full_path, ': ', end='')
            wake = process_pdm_wake(source=full_path, method=method)[-1]
            if category == 'yes/':
                if wake:
                    n_valid_wake += 1
                else:
                    n_false_sleep += 1
            else:
                if wake:
                    n_false_wake += 1
                else:
                    n_valid_sleep += 1
    total = n_valid_wake + n_valid_sleep + n_false_wake + n_false_sleep
    accuracy = (n_valid_wake + n_valid_sleep) / total * 100
    print('Accuracy: {:.03f}%'.format(accuracy))
    print_maxes()

if __name__ == '__main__':
    process_pdm_dfe()

