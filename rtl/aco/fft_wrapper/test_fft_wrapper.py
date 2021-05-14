# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

import numpy as np
import matplotlib.pyplot as plt

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, Timer
from cocotb.binary import BinaryValue

ENABLE_ASSERTS = True

FFT_LEN = 256
RFFT_LEN = int(FFT_LEN / 2 + 1)

scale_factor = 8  # dut results are this factor smaller than the expected
                  # this is log2(fft_length), so it probably makes sense
max_deviation_percent = 10  # threshold to error at

test_results = []
expected_results = []
titles = []

OKGREEN = '\033[92m'
ENDC = '\033[0m'

def constant_sig():
    titles.append('Constant input')
    return np.ones(FFT_LEN)

def cosine_sig(f):
    titles.append('Cosine input')
    t = np.linspace(0, 1, FFT_LEN)  # test with 1 second sampling at 256 Hz
    f = 5  # 5 Hz
    sig = 100 * np.cos(2*np.pi * f * t)
    sig = sig.astype(np.int16)
    return sig

def random_sig():
    titles.append('Random input')
    sig = np.random.randn(FFT_LEN) * FFT_LEN
    sig = sig.astype(np.int16)
    return sig

async def write_input(dut, sig):
    '''Send inputs into the dut and save the expected output.'''
    dut.valid_i <= 1
    for i in range(FFT_LEN):
        dut.data_i <= int(sig[i])
        await FallingEdge(dut.clk_i)
    dut.valid_i <= 0
    dut.data_i <= 1
    expected_results.append(np.fft.rfft(sig))

async def read_output_once(dut):
    while (dut.valid_o != 1):  # wait until output is valid
        await FallingEdge(dut.clk_i)
    sig = np.zeros(RFFT_LEN, dtype=np.cdouble)
    for i in range(RFFT_LEN):
        binstr = dut.data_o.value.get_binstr()
        split_binstr = [binstr[:21], binstr[21:]]
        output_arr = [BinaryValue(x).signed_integer for x in split_binstr]
        sig[i] = output_arr[0] + output_arr[1] * 1j
        if i == RFFT_LEN - 1:
            assert dut.last_o == 1
        await FallingEdge(dut.clk_i)
    test_results.append(sig)

def gen_result_plots():
    '''Plot expected results against received results and save them in the
    plots/ directory.'''
    n = len(test_results)
    x = np.arange(RFFT_LEN)
    for i in range(n):
        t = test_results[i] * scale_factor
        e = expected_results[i]
        # print('Max expected value: {}'.format(e.real.max()))
        # print('Max test value: {}'.format(t.real.max()))

        plt.figure()
        plt.subplot(211)
        plt.title(titles[i])
        plt.plot(x, e.real, label='expected real')
        plt.plot(x, t.real, label='dut output real')
        plt.legend()
        plt.subplot(212)
        plt.plot(x, e.imag, label='expected imag')
        plt.plot(x, t.imag, label='dut output imag')
        plt.legend()
        plt.savefig('plots/{}.png'.format(i))

        max_val = np.max(e.real)
        diff = e - t
        percent_err = (diff / max_val) * 100
        if (percent_err > max_deviation_percent).any():
            print(titles[i], 'expected output deviates by more than 10%.',
                  'Max deviation of {}% in result'.format(percent_err.max()))
            if ENABLE_ASSERTS:
                raise Exception('Output deviation above error threshold')
        else:
            print(OKGREEN + titles[i],
                  'expected output within error threshold.', ENDC)

@cocotb.test()
async def main(dut):
    # Create a 10us period clock on port clk
    clock = Clock(dut.clk_i, 10, units="us")
    cocotb.fork(clock.start())

    await FallingEdge(dut.clk_i)
    dut.rst_n_i <= 0
    dut.en_i <= 0
    dut.data_i <= 0
    dut.valid_i <= 0
    dut.last_i <= 0

    for _ in range(50):
        await FallingEdge(dut.clk_i)

    dut.rst_n_i <= 1
    dut.en_i <= 1

    await write_input(dut, cosine_sig(5))
    await read_output_once(dut)
    await Timer(5000, units='us')

    await write_input(dut, constant_sig())
    await read_output_once(dut)
    await Timer(5000, units='us')  # wait enough time for the fft core to reset

    await write_input(dut, constant_sig())
    await read_output_once(dut)
    await Timer(5000, units='us')  # wait enough time for the fft core to reset
    # await write_input(dut, cosine_sig(5))
    # await read_output_once(dut)
    # await Timer(5000, units='us')

    await write_input(dut, random_sig())
    await read_output_once(dut)
    await Timer(5000, units='us')

    gen_result_plots()
