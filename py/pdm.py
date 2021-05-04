'''Simulate a PDM microphone and decoding with some number of CIC stages.'''

import os
import numpy as np
from scipy.io import wavfile
import matplotlib.pyplot as plt

OUTDIR = 'outputs/'
PLOT = True

f_pcm_in = 16000
# ratio_in = 256
ratio_in = 250
f_pdm = f_pcm_in * ratio_in  # 4.096 MHz
f_pcm_out = 16000
# f_pcm_out = 32000
ratio_out = int(f_pdm / f_pcm_out)  # 250
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
    x = x * ratio_in  # scale up by window so that value is # ones
    x = x.astype(np.uint8)
    repeats = np.zeros(x.size * 2, dtype=np.uint8)
    repeats[::2] = x
    repeats[1::2] = ratio_in - x
    one_zero = np.ones(x.size * 2, dtype=np.uint8)
    one_zero[1::2] = 0
    y = np.repeat(one_zero, repeats)
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


def pcm_to_pdm(x, pdm_gen='err'):
    '''Generate the PDM signal for the sample.'''
    # x = read_sample_file(sample_fname)
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
    # x = x.astype(np.int16)  # if ratio is >= 256, need this to not overflow
    return x

def cicn(x):
    '''Later CIC stages.'''
    x = x.astype(np.int64)
    rolled = np.roll(x, ratio_out)
    rolled[:ratio_out] = 0
    x = np.cumsum(x) - np.cumsum(rolled)
    x = x / ratio_out
    x = x.astype(np.int8)
    # x = x.astype(np.int16)  # same here
    return x

def pdm_to_pcm(x, n_cic):
    x = cic1(x)
    for i in range(n_cic - 1):
        x = cicn(x)
    x = x[::ratio_out]
    x[0] = 0
    return x

# =========== Plotting ============

def get_power_spectrum(x):
    ps = np.abs(np.fft.fft(x)) ** 2
    ps = ps / ps.max()
    return ps

def plot_power_spectrum(x, dt, title):
    X = get_power_spectrum(x)
    freqs = np.fft.fftfreq(x.size, dt)
    idx = np.argsort(freqs)
    plt.plot(freqs[idx], X[idx])
    plt.title(title)

def plot_power_spectrum_difference(x1, x2, dt):
    X1 = get_power_spectrum(x1)
    X2 = get_power_spectrum(x2)
    diff = X1 - X2
    freqs = np.fft.fftfreq(x1.size, dt)
    idx = np.argsort(freqs)
    plt.plot(freqs[idx], diff[idx])
    plt.title('Difference')
    plt.ylim(-.01, .01)

# =========== Higher Level Functions ============

def main():
    if not os.path.isdir(OUTDIR):
        os.mkdir(OUTDIR)
    x_orig = read_sample_file(sample_fname)
    for pdm_gen in ['err', 'pwm']:
        x_pdm = pcm_to_pdm(x_orig, pdm_gen=pdm_gen)
        # for n_cic in [1, 2, 4, 8]:
        for n_cic in [1]:
            x_decoded = pdm_to_pcm(x_pdm, n_cic)

            fname_out = OUTDIR + '{}_cic{}_{}'.format(pdm_gen, n_cic, f_pcm_out)
            if PLOT:
                plt.figure(figsize=(8,8))
                plt.subplots_adjust(hspace=0.4)
                plt.subplot(311)
                plot_power_spectrum(x_orig, 1/f_pcm_in, 'Input Power Spectum')
                plt.subplot(312)
                plot_power_spectrum(x_decoded, 1/f_pcm_out, 'Output Power Spectrum')
                plt.subplot(313)
                assert f_pcm_in == f_pcm_out
                plot_power_spectrum_difference(x_orig, x_decoded, 1/f_pcm_in)
                fname_out_plt = fname_out + '_ps' + '.png'
                plt.savefig(fname_out_plt)
                plt.close()
            fname_out_wav = fname_out + '.wav'
            wavfile.write(fname_out_wav, f_pcm_out, x_decoded.astype(np.int16) * 256)
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
