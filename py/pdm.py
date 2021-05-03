'''Simulate a PDM microphone and decoding with some number of CIC stages.'''

import os
import numpy as np
from scipy.io import wavfile

OUTDIR = 'outputs/'

f_pcm_in = 16000
ratio_in = 256
f_pdm = f_pcm_in * ratio_in  # 4.096 MHz
f_pcm_out = 16000
# f_pcm_out = 32000
ratio_out = int(f_pdm / f_pcm_out)  # 256
sample_fname = 'sample_sound.wav'

def read_sample_file(fname):
    return wavfile.read(fname)[1]

def shift_zero_to_one(x):
    '''Shift an input signal into the range 0-1.'''
    x = x.astype(np.float64)
    x = x - x.min()
    x = x / x.max()
    return x

# =========== PDM computing methods ============

def pcm_to_pdm_random(x):
    '''Use random sampling to generate PDM. This results in much more
    high frequency noise than a real microphone would generate.'''
    x = shift_zero_to_one(x)
    y = np.zeros(len(x) * ratio_in, dtype=np.uint8)
    for i in range(len(x)):
        xi = x[i]
        rand = np.random.rand(ratio_in)
        logical = (rand > xi)
        subseq = np.zeros(ratio_in, dtype=np.uint8)
        subseq[logical] = 1
        y[i * ratio_in : (i + 1) * ratio_in] = subseq
    return y

def pcm_to_pdm_pwm(x):
    '''Pack all ones and zeros together during upsampling when generating PDM
    signal, effectively creating PWM. This results in much less high frequency
    noise in the signal.'''
    x = shift_zero_to_one(x)
    x = x * (ratio_in - 1)  # scale up by window so that value is # ones
    y = np.zeros(len(x) * ratio_in, dtype=np.uint8)
    for i in range(len(x)):
        xi = int(x[i])
        ones = np.ones(xi)
        zeros = np.zeros(ratio_in - xi)
        subseq = np.hstack((ones, zeros))
        y[i * ratio_in : (i + 1) * ratio_in] = subseq
    return y

def pcm_to_pdm_err(x):
    '''From https://gist.github.com/jeanminet/2913ca7a87e96296b27e802575ad6153
    This is the most accurate PDM model.
    '''
    x = shift_zero_to_one(x)
    x = np.repeat(x, ratio_in)
    n = len(x)
    y = np.zeros(n)
    error = np.zeros(n+1)
    for i in range(n):
        y[i] = 1 if x[i] >= error[i] else 0
        error[i+1] = y[i] - x[i] + error[i]
    # return y, error[0:n]
    return y

def gen_pdm(pdm_gen='err'):
    '''Generate the PDM signal for the sample.'''
    x = read_sample_file(sample_fname)
    if pdm_gen == 'pwm':
        y = pcm_to_pdm_pwm(x)
    elif pdm_gen == 'random':
        y = pcm_to_pdm_random(x)
    elif pdm_gen == 'err':
        y = pcm_to_pdm_err(x)
    else:
        raise ValueError('{} not known')
    return y

# =========== Cascaded Integrator-Comb Filter ============

def cic1(x):
    '''First cic stage treats datatypes differently.'''
    x = x.astype(np.int64)
    rolled = np.roll(x, ratio_out)
    rolled[:ratio_out] = 0
    x = np.cumsum(x) - np.cumsum(rolled)
    print('max of cic1 out: ', x.max())
    print('min of cic1 out: ', x.min())
    x = x - int(ratio_out/2)
    x = x.astype(np.int8)
    return x

def cicn(x):
    '''Later CIC stages.'''
    x = x.astype(np.int64)
    rolled = np.roll(x, ratio_out)
    rolled[:ratio_out] = 0
    x = np.cumsum(x) - np.cumsum(rolled)
    x = x / ratio_out
    x = x.astype(np.int8)
    return x

def pdm_to_pcm(x, n_cic):
    x = cic1(x)
    for i in range(n_cic - 1):
        x = cicn(x)
    x = x[::ratio_out]
    x[0] = 0
    return x

def decode(x, n_cic, pdm_gen='err'):
    '''Take a PDM input and output the PCM'''
    x = pdm_to_pcm(x, n_cic)
    fname_out = OUTDIR + '{}_cic{}_{}.wav'.format(pdm_gen, n_cic, f_pcm_out)
    wavfile.write(fname_out, f_pcm_out, x.astype(np.int16) * 256)
    return x

# =========== Higher Level Functions ============

def main():
    if not os.path.isdir(OUTDIR):
        os.mkdir(OUTDIR)
    x = gen_pdm()
    for n_cic in [1, 2, 4, 8]:
        decode(x, n_cic, pdm_gen='err')
    to_8_bits_test()

def to_8_bits_test():
    '''Try quantizing the input signal to 8 bits and see what quality is.'''
    x = read_sample_file(sample_fname)
    x = x / 256
    x = x + 128
    x = x.astype(np.int8)
    wavfile.write(OUTDIR + 'out_8_bits_quantization.wav', f_pcm_in, x)

if __name__ == '__main__':
    main()
