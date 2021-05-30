# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

import os
import numpy as np
import matplotlib.pyplot as plt
import pickle

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, Timer
from cocotb.binary import BinaryValue

import sys
sys.path.append('../../../py/')
import aco
import pdm

# Fixed parameters:
N_FRAMES = 50  # frames 
FFT_LEN = 256
RFFT_LEN = int(FFT_LEN / 2 + 1)
N_MFE = 32
N_DCT = 13

# Configurable parameters:
PCM_SPACING = 3  # cycles between writing another PCM input
                 # must be >= 3 so the FFT isn't over utilised
# PCM_SPACING = 250  # 250 is the final value but sim takes longer

def get_msg(block, i, received, expected):
    return '{}: idx {}, dut output of {}, expected {}.'.format(
                    block, i, received, expected)

def get_sample_test_vector():
    '''Get a real audio sample for input and calculate the expected outputs.'''
    x = pdm.read_sample_file(pdm.SAMPLE_FNAME)
    x_distorted = aco.pdm_model(x, 'fast')
    sigs = aco.aco(x_distorted)
    return x_distorted, sigs

def get_cosine_test_vector():
    '''Get a max amplitude cosine test vector to try saturate the pipeline
    with.'''
    t = np.linspace(0, 1, 16000)
    f = 20  # Hz
    A = 2**15-1  # max 16b signed amplitude
    x = A * np.cos(2*np.pi * f * t)
    x = aco.pdm_model(x, 'fast')
    sigs = aco.aco(x)
    return x, sigs

def get_multi_cosine_test_vector():
    '''Get a max amplitude cosine test vector to try saturate the pipeline
    with.'''
    t = np.linspace(0, 1, 16000)
    n_freqs = 100
    freqs = np.logspace(0, np.log10(16000), 10)
    A = (2**15 -1) / n_freqs # max 16b signed amplitude
    x = np.zeros(16000)
    for f in freqs:
        x += A * np.cos(2*np.pi * f * t)
    x = aco.pdm_model(x, 'fast')
    sigs = aco.aco(x)
    return x, sigs

def get_random_test_vector():
    x = np.random.randint(-2**15, 2**15-1, size=16000)
    x = aco.pdm_model(x, 'fast')
    sigs = aco.aco(x)
    return x, sigs

def get_random_sample_test_vector(test_num):
    top_dir = '../../../py/'
    categories = ['yes/', 'noise/', 'no/', 'unknown/']
    category = categories[test_num % 4]
    sample_dir = top_dir + category
    fnames = os.listdir(sample_dir)
    idx = np.random.randint(len(fnames))
    fname = sample_dir + fnames[idx]
    print('Running test with', fname)
    
    x = pdm.read_sample_file(fname)
    x = aco.pdm_model(x, 'fast')
    sigs = aco.aco(x)
    return x, sigs

async def write_input(dut, x):
    '''Write the PCM input to the dut.'''
    for i in range(len(x)):
        dut.data_i <= int(x[i])
        dut.valid_i <= 1
        await FallingEdge(dut.clk_i)
        dut.data_i <= 0
        dut.valid_i <= 0
        for j in range(PCM_SPACING):  # delay next input
            await FallingEdge(dut.clk_i)

async def check_preemphasis(dut, y):
    i = 0
    while i < len(y):
        await Timer(1, units='us')  # wait until slightly after falling edge
        if (dut.preemph_valid_o == 1):
            expected_val = y[i]
            received_val = dut.preemph_data_o.value.signed_integer
            assert received_val == expected_val, get_msg('Preemphasis', i,
                                                    received_val, expected_val)
            i += 1
        await FallingEdge(dut.clk_i)
    print('Preemphasis: received expected output.')

async def check_framing(dut, y):
    for i in range(N_FRAMES):  # 50 frames of PCM data should be generated
        while (dut.fft_framing_valid_o != 1):
            await FallingEdge(dut.clk_i)
        for j in range(FFT_LEN):
            await Timer(1, units='us')
            assert dut.fft_framing_valid_o == 1
            if j == FFT_LEN - 1:
                assert dut.fft_framing_last_o == 1
            else:
                assert dut.fft_framing_last_o == 0
            expected_val = y[i, j]
            received_val = dut.fft_framing_data_o.value.signed_integer
            assert received_val == expected_val, get_msg('FFT Framing', j,
                                                    received_val, expected_val)
            await FallingEdge(dut.clk_i)
    print('FFT Framing: received expected output.')

async def check_fft(dut, y, test_num):
    threshold = 10  # maximum difference between expected and actual
    full_sig = np.zeros((N_FRAMES, RFFT_LEN), dtype=np.cdouble)
    for i in range(N_FRAMES):
        while (dut.fft_valid_o != 1):  # wait until output is valid
            await FallingEdge(dut.clk_i)
        sig = np.zeros(RFFT_LEN, dtype=np.cdouble)
        for j in range(RFFT_LEN):
            await Timer(1, units='us')
            binstr = dut.fft_data_o.value.get_binstr()
            split_binstr = [binstr[:21], binstr[21:]]
            output_arr = [BinaryValue(x).signed_integer for x in split_binstr]
            sig[j] = output_arr[0] + output_arr[1] * 1j
            if j == RFFT_LEN - 1:
                assert dut.fft_last_o == 1
            else:
                assert dut.power_spectrum_last_o == 0
            await FallingEdge(dut.clk_i)
        absmax = np.abs(y[i,:] - sig).max()
        assert absmax <= threshold, ('FFT: deviation of {} exceeds threshold'
                                        .format(absmax))
        full_sig[i, :] = sig
        print('\r{}/50'.format(i+1), end='')
    percent_err = np.abs(full_sig - y) / np.abs(y).max() * 100
    print('FFT: max percent error: {:.03f}%'.format(percent_err.max()))
    print('FFT: received expected output.')
    plot_features((y, full_sig), test_num, '1FFT')
    return full_sig

async def check_power_spectrum(dut, y, test_num):
    full_sig = np.zeros((N_FRAMES, RFFT_LEN))
    for i in range(N_FRAMES):
        while (dut.power_spectrum_valid_o != 1):
            await FallingEdge(dut.clk_i)
        sig = np.zeros(RFFT_LEN, dtype=np.int64)
        for j in range(RFFT_LEN):
            await Timer(1, units='us')
            sig[j] = dut.power_spectrum_data_o.value.integer
            assert sig[j] == y[i,j]
            if j == RFFT_LEN - 1:
                assert dut.power_spectrum_last_o == 1
            else:
                assert dut.power_spectrum_last_o == 0
            await FallingEdge(dut.clk_i)
        full_sig[i, :] = sig
    print('Power Spectrum: received expected output.')
    plot_features((y, full_sig), test_num, '2Power_spectrum')

async def check_filterbank(dut, y, test_num):
    full_sig = np.zeros((N_FRAMES, N_MFE))
    for i in range(N_FRAMES):
        sig = np.zeros(N_MFE)
        for j in range(N_MFE):
            while (dut.filterbank_valid_o != 1):
                await FallingEdge(dut.clk_i)
            await Timer(1, units='us')
            sig[j] = dut.filterbank_data_o.value.integer
            assert sig[j] == y[i,j]
            if j == N_MFE - 1:
                assert dut.filterbank_last_o == 1
            else:
                assert dut.filterbank_last_o == 0
            await FallingEdge(dut.clk_i)
        full_sig[i, :] = sig
    print('Filterbank: received expected output.')
    plot_features((y, full_sig), test_num, '3Filterbank')

async def check_log(dut, y, test_num):
    full_sig = np.zeros((N_FRAMES, N_MFE))
    for i in range(N_FRAMES):
        sig = np.zeros(N_MFE)
        for j in range(N_MFE):
            while (dut.log_valid_o != 1):
                await FallingEdge(dut.clk_i)
            await Timer(1, units='us')
            sig[j] = dut.log_data_o.value.integer
            assert sig[j] == y[i,j]
            if j == N_MFE - 1:
                assert dut.log_last_o == 1
            else:
                assert dut.log_last_o == 0
            await FallingEdge(dut.clk_i)
        full_sig[i, :] = sig
    print('Log: received expected output.')
    plot_features((y, full_sig), test_num, '4Log')

async def check_dct(dut, y, test_num):
    full_sig = np.zeros((N_FRAMES, N_DCT))
    for i in range(N_FRAMES):
        while (dut.dct_valid_o != 1):
            await FallingEdge(dut.clk_i)
        sig = np.zeros(N_DCT)
        was_problem = False
        for j in range(N_DCT):
            await Timer(1, units='us')
            assert dut.dct_valid_o == 1
            sig[j] = dut.dct_data_o.value.signed_integer
            assert sig[j] == y[i,j], 'exp {}, rec {}'.format(sig[j], y[i,j])
            if j == N_DCT - 1:
                assert dut.dct_last_o == 1
            else:
                assert dut.dct_last_o == 0
            await FallingEdge(dut.clk_i)
        full_sig[i, :] = sig
    print('DCT: received expected output.')
    plot_features((y, full_sig), test_num, '5DCT')

async def check_quant(dut, y, test_num):
    full_sig = np.zeros((N_FRAMES, N_DCT))
    for i in range(N_FRAMES):
        while (dut.quant_valid_o != 1):
            await FallingEdge(dut.clk_i)
        sig = np.zeros(N_DCT)
        for j in range(N_DCT):
            await Timer(1, units='us')
            assert dut.quant_valid_o == 1
            sig[j] = dut.quant_data_o.value.signed_integer
            assert sig[j] == y[i,j]
            if j == N_DCT - 1:
                assert dut.quant_last_o == 1
            else:
                assert dut.quant_last_o == 0
            await FallingEdge(dut.clk_i)
        full_sig[i, :] = sig
    print('Quant: received expected output.')
    plot_features((y, full_sig), test_num, '6Quant')

async def check_final(dut, y, test_num):
    y = y.reshape((N_FRAMES, N_DCT))
    while (dut.valid_o != 1):
        await FallingEdge(dut.clk_i)
    sig = np.zeros((N_FRAMES, N_DCT))
    for i in range(N_FRAMES):
        await Timer(1, units='us')
        assert dut.valid_o == 1
        binstr = dut.data_o.value.get_binstr()
        for j in range(N_DCT):
            section = binstr[j*8 : (j+1)*8]
            sig[i, j] = BinaryValue(section).signed_integer
            assert sig[i, j] == y[i,j]
        if i == N_FRAMES - 1:
            assert dut.last_o == 1
        else:
            assert dut.last_o == 0
        await FallingEdge(dut.clk_i)
    print('Final: received expected output.')
    plot_features((y, sig), test_num, '7Final')

def plot_features(sigs, test_num, name):
    plotdir = 'plots/test_{}/'.format(test_num)
    if not os.path.exists(plotdir):
        os.mkdir(plotdir)
    titles = ['Expected Features', 'Received Features']
    plt.figure()
    for i in range(2):
        plt.subplot(2,1,i+1)
        sig = np.abs(sigs[i]).astype(float)
        size = sig.size
        plt.imshow(sig.reshape((N_FRAMES, size//N_FRAMES)).T)
        plt.title(titles[i])
    plt.savefig(plotdir + '{}.png'.format(name), dpi=400)
    plt.close()

async def do_test(dut, test_num):
    print('Beginning test #{}.'.format(test_num))
    await reset(dut)  # reset to clear out previous values in pipeline
    dut.en_i <= 1
    if test_num == 0:
        await do_test_no_en(dut)
        return
    elif test_num == 1:
        x, y = get_sample_test_vector()
    elif test_num == 2:
        x, y = get_cosine_test_vector()
    elif test_num == 3:
        x, y = get_multi_cosine_test_vector()
    elif test_num == 4:
        x, y = get_random_test_vector()
    else:
        x, y = get_random_sample_test_vector(test_num)
    cocotb.fork(write_input(dut, x))
    cocotb.fork(check_preemphasis   (dut, y[0]))
    cocotb.fork(check_framing       (dut, y[1]))
    fft_out = await check_fft       (dut, y[2], test_num)
    # Take RTL FFT output and feed it to the ACO model to obtain the rest of the
    # expected signals. This is because we don't have a bit-accurate model of
    # the FFT.
    y = aco.aco(x, fft_override=fft_out)
    await reset(dut)  # reset to clear out previous values in pipeline
    dut.en_i <= 1
    cocotb.fork(write_input(dut, x))  # rewrite the input
    cocotb.fork(check_preemphasis   (dut, y[0]))
    cocotb.fork(check_framing       (dut, y[1]))
    cocotb.fork(check_fft           (dut, y[2], test_num))
    cocotb.fork(check_power_spectrum(dut, y[3], test_num))
    cocotb.fork(check_filterbank    (dut, y[4], test_num))
    cocotb.fork(check_log           (dut, y[5], test_num))
    cocotb.fork(check_dct           (dut, y[6], test_num))
    cocotb.fork(check_quant         (dut, y[7], test_num))
    await check_final               (dut, y[8], test_num)
    print()

async def do_test_no_en(dut):
    print('Beginning test with random input data but en_i is low.')
    dut.en_i <= 0
    await Timer(1, units='us')
    for i in range(10000):
        dut.data_i <= int(np.random.randint(-128, 128))  # feed in garbage data
        dut.valid_i <= 1
        assert dut.valid_o == 0
        await FallingEdge(dut.clk_i)

async def reset(dut):
    '''Reset the dut.'''
    dut.rst_n_i <= 0
    for _ in range(50):  # wait long enough for fft core to reset
        await FallingEdge(dut.clk_i)
    dut.rst_n_i <= 1

@cocotb.test()
async def main(dut):
    # Create a 10us period clock on port clk
    clock = Clock(dut.clk_i, 10, units="us")
    cocotb.fork(clock.start())

    # Reset system
    await FallingEdge(dut.clk_i)
    dut.rst_n_i <= 0
    dut.en_i <= 0
    dut.data_i <= 0
    dut.valid_i <= 0

    await reset(dut)

    for i in range(12):
        await do_test(dut, i)
    # await do_test(dut, 1)

    print('Max bitwidths encountered in python ACO model:')
    aco.print_maxes()
