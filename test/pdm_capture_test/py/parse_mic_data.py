import numpy as np
from scipy.io import wavfile
from scipy import signal
import matplotlib.pyplot as plt
import struct

import sys
sys.path.append('../../wakey_wakey/py/')  # assume eldrickm/wakey_wakey is
                                          # cloned in same dir as this repo
import pdm

def get_pdm():
    '''Parse the PDM bitstream into a numpy array of ones and zeros.'''
    data = open('out.bin', 'rb').read()
    num_bytes = len(data)
    print('Num bytes:', num_bytes)
    x_bytes = np.frombuffer(data, dtype='B')
    x = np.zeros(num_bytes * 8, dtype=np.uint8)
    for i in range(num_bytes):  # extract each bit from each byte
        for j in range(8):
            x[i*8 + j] = (x_bytes[i] >> j) & 0x1
    return x

def process_pdm(x):
    '''Filter the PDM array three different ways and save .wav files.'''
    dfe_y_1cic = pdm.pdm_to_pcm(x, 1)  # this is the same as the RTL model
    dfe_y_2cic = pdm.pdm_to_pcm(x, 2)
    y = signal.decimate(x, 25)  # ideal FIR decimating filter
    y = signal.decimate(y, 10)
    wavfile.write('out_perfect_fir.wav', 16000, y)
    wavfile.write('out_dfe_1cic_2mhz.wav', 16000, (dfe_y_1cic + 125).astype(np.uint8))
    wavfile.write('out_dfe_2cic_2mhz.wav', 16000, dfe_y_2cic)

    return y, dfe_y_1cic, dfe_y_2cic


if __name__ == '__main__':
    x = get_pdm()
    process_pdm(x)
