# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

import numpy as np
import matplotlib.pyplot as plt

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

def get_test_vector():
    '''Get a real audio sample for input and calculate the expected outputs.'''
    sig_orig = pdm.read_sample_file(pdm.SAMPLE_FNAME)
    sig_distorted = pdm.pdm_model(sig_orig, 'fast')
    sigs = aco.aco(sig_distorted)
    return sig_distorted, sigs

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
    print('Expected first 10 elements of framing: ', y[0,:10])
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

async def check_fft(dut, y):
    threshold = 10  # maximum difference between expected and actual
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
    print('FFT: received expected output.')

async def check_power_spectrum(dut, y):
    threshold = 500  # percent error permissible
    max_percent_err_all = 0
    for i in range(N_FRAMES):
        while (dut.power_spectrum_valid_o != 1):
            await FallingEdge(dut.clk_i)
        sig = np.zeros(RFFT_LEN)
        for j in range(RFFT_LEN):
            await Timer(1, units='us')
            sig[j] = dut.power_spectrum_data_o.value.integer
            if j == RFFT_LEN - 1:
                assert dut.power_spectrum_last_o == 1
            else:
                assert dut.power_spectrum_last_o == 0
            await FallingEdge(dut.clk_i)
        sig_max = np.abs(y[i,:]).max()
        if sig_max > 0:
            percent_err = (y[i,:] - sig) * 100 / sig_max
            max_percent_err = np.abs(percent_err).max()
            if max_percent_err > max_percent_err_all:
                max_percent_err_all = max_percent_err
            msg = 'Power Spectrum: {} exceeds threshold'.format(max_percent_err)
            assert max_percent_err <= threshold, msg
    print('Power Spectrum: received expected output.')
    print('Power Spectrum: Max percent error: {}.'.format(max_percent_err_all))

async def check_filterbank(dut, y):
    threshold = 1000  # percent error permissible
    max_percent_err_all = 0
    for i in range(N_FRAMES):
        sig = np.zeros(N_MFE)
        for j in range(N_MFE):
            while (dut.filterbank_valid_o != 1):
                await FallingEdge(dut.clk_i)
            await Timer(1, units='us')
            sig[j] = dut.filterbank_data_o.value.integer
            if j == N_MFE - 1:
                assert dut.filterbank_last_o == 1
            else:
                assert dut.filterbank_last_o == 0
            await FallingEdge(dut.clk_i)
        sig_max = np.abs(y[i,:]).max()
        if sig_max > 0:
            percent_err = (y[i,:] - sig) * 100 / sig_max
            max_percent_err = np.abs(percent_err).max()
            if max_percent_err > max_percent_err_all:
                max_percent_err_all = max_percent_err
            msg = 'Filterbank: {} exceeds threshold'.format(max_percent_err)
            assert max_percent_err <= threshold, msg
    print('Filterbank: received expected output.')
    print('Filterbank: Max percent error: {}.'.format(max_percent_err_all))

async def check_log(dut, y):
    threshold = 5  # maximum permissible difference
    max_err_all = 0
    for i in range(N_FRAMES):
        sig = np.zeros(N_MFE)
        for j in range(N_MFE):
            while (dut.log_valid_o != 1):
                await FallingEdge(dut.clk_i)
            await Timer(1, units='us')
            sig[j] = dut.log_data_o.value.integer
            if j == N_MFE - 1:
                assert dut.log_last_o == 1
            else:
                assert dut.log_last_o == 0
            await FallingEdge(dut.clk_i)
        diff = y[i,:] - sig
        max_diff = np.abs(diff).max()
        if max_diff > max_err_all:
            max_err_all = max_diff
        msg = 'Log: {} exceeds threshold'.format(max_diff)
        assert max_diff <= threshold, msg
    print('Log: received expected output.')
    print('Log: Max difference: {}.'.format(max_err_all))

async def check_dct(dut, y):
    threshold = 1000  # maximum permissible percent error
    max_percent_err_all = 0
    for i in range(N_FRAMES):
        while (dut.dct_valid_o != 1):
            await FallingEdge(dut.clk_i)
        sig = np.zeros(N_DCT)
        for j in range(N_DCT):
            await Timer(1, units='us')
            assert dut.dct_valid_o == 1
            sig[j] = dut.dct_data_o.value.signed_integer
            if j == N_DCT - 1:
                assert dut.dct_last_o == 1
            else:
                assert dut.dct_last_o == 0
            await FallingEdge(dut.clk_i)
        sig_max = np.abs(y[i,:]).max()
        if sig_max > 0:
            percent_err = (y[i,:] - sig) * 100 / sig_max
            max_percent_err = np.abs(percent_err).max()
            if max_percent_err > max_percent_err_all:
                max_percent_err_all = max_percent_err
            msg = 'DCT: {} exceeds threshold'.format(max_percent_err)
            assert max_percent_err <= threshold, msg
    print('DCT: received expected output.')
    print('DCT: Max percent err: {}.'.format(max_percent_err_all))

async def check_quant(dut, y):
    threshold = 1000  # maximum permissible percent error
    max_percent_err_all = 0
    for i in range(N_FRAMES):
        while (dut.quant_valid_o != 1):
            await FallingEdge(dut.clk_i)
        sig = np.zeros(N_DCT)
        for j in range(N_DCT):
            await Timer(1, units='us')
            assert dut.quant_valid_o == 1
            sig[j] = dut.quant_data_o.value.signed_integer
            if j == N_DCT - 1:
                assert dut.quant_last_o == 1
            else:
                assert dut.quant_last_o == 0
            await FallingEdge(dut.clk_i)
        sig_max = np.abs(y[i,:]).max()
        if sig_max > 0:
            percent_err = (y[i,:] - sig) * 100 / sig_max
            max_percent_err = np.abs(percent_err).max()
            if max_percent_err > max_percent_err_all:
                max_percent_err_all = max_percent_err
            msg = 'Quant: {} exceeds threshold'.format(max_percent_err)
            assert max_percent_err <= threshold, msg
        print('\r{}/50'.format(i+1), end='')
    print('Quant: received expected output.')
    print('Quant: Max percent err: {}.'.format(max_percent_err_all))

async def check_final(dut, y):
    threshold = 100  # maximum permissible percent error
    max_percent_err_all = 0
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
        if i == N_FRAMES - 1:
            assert dut.last_o == 1
        else:
            assert dut.last_o == 0
        await FallingEdge(dut.clk_i)
    sig = sig.reshape(N_FRAMES * N_DCT)
    sig_max = np.abs(y).max()
    if sig_max > 0:
        percent_err = (y - sig) * 100 / sig_max
        max_percent_err = np.abs(percent_err).max()
        if max_percent_err > max_percent_err_all:
            max_percent_err_all = max_percent_err
        msg = 'Final: {} exceeds threshold'.format(max_percent_err)
        assert max_percent_err <= threshold, msg
    print('Final: received expected output.')
    print('Final: Max percent err: {}.'.format(max_percent_err_all))
    plot_final_features([y, sig])

def plot_final_features(sigs):
    titles = ['Expected Features', 'Received Features']
    plt.figure()
    for i in range(2):
        plt.subplot(2,1,i+1)
        plt.imshow(sigs[i].reshape((N_FRAMES, N_DCT)).T)
        plt.title(titles[i])
    plt.savefig('plots/features_out.png')

async def do_test(dut):
    print('Beginning directed test with audio data.')
    x, y = get_test_vector()
    cocotb.fork(write_input(dut, x))
    cocotb.fork(check_preemphasis   (dut, y[0]))
    cocotb.fork(check_framing       (dut, y[1]))
    cocotb.fork(check_fft           (dut, y[2]))
    cocotb.fork(check_power_spectrum(dut, y[3]))
    cocotb.fork(check_filterbank    (dut, y[4]))
    cocotb.fork(check_log           (dut, y[5]))
    cocotb.fork(check_dct           (dut, y[6]))
    cocotb.fork(check_quant         (dut, y[7]))
    await       check_final         (dut, y[8])

async def do_test_no_en(dut):
    print('Beginning test with random input data but en_i is low.')
    await Timer(1, units='us')
    for i in range(10000):
        dut.data_i <= int(np.random.randint(-128, 128))  # feed in garbage data
        dut.valid_i <= 1
        assert dut.valid_o == 0
        await FallingEdge(dut.clk_i)

async def write_shift(dut, shift=0):
    '''Write the amount to shift by in the quantization stage.'''
    dut.shift_i <= shift
    dut.wr_en <= 1
    await FallingEdge(dut.clk_i)
    dut.shift_i <= 0
    dut.wr_en <= 0

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
    dut.shift_i <= 0
    dut.wr_en <= 0

    # reset
    for _ in range(50):  # wait long enough for fft core
        await FallingEdge(dut.clk_i)
    dut.rst_n_i <= 1

    # write quantization shift amount
    await write_shift(dut)

    # test 1
    dut.en_i <= 1
    await do_test(dut)

    # test 2
    dut.en_i <= 0
    await do_test_no_en(dut)

    # test 3
    # dut.en_i <= 1
    # await do_test(dut)
