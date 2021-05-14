# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

import numpy as np
import matplotlib.pyplot as plt

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge
from cocotb.binary import BinaryValue

ENABLE_ASSERTS = True

scale_factor = 8  # dut results are this factor smaller than the expected
                  # this is log2(fft_length), so it probably makes sense
max_deviation_percent = 10  # threshold to error at

test_results = []
expected_results = []
titles = []

OKGREEN = '\033[92m'
ENDC = '\033[0m'

def np2bv(int_arr):
    """ Convert a 16b integer numpy array in cocotb BinaryValue """
    int_list = int_arr.tolist()
    binarized = [format(x & 0xFFFF, '016b') if x < 0 else format(x, '016b')
                 for x in int_list]
    bin_string = ''.join(binarized)
    return BinaryValue(bin_string)

def constant_sig():
    titles.append('Constant input')
    return np.ones(256)

def cosine_sig(f):
    titles.append('Cosine input')
    t = np.linspace(0, 1, 256)  # test with 1 second sampling at 256 Hz
    f = 5  # 5 Hz
    sig = 100 * np.cos(2*np.pi * f * t)
    return sig

def random_sig():
    titles.append('Random input')
    sig = np.random.randn(256) * 256
    sig = sig.astype(np.int16)
    return sig

def multi_cosine_sig():
    titles.append('Multi Cosine input')
    t = np.linspace(0, 1, 256)  # test with 1 second sampling at 256 Hz
    f = 5  # 5 Hz
    sig = 10 * np.cos(2*np.pi * f * t)
    for i in range(0, 25, 2):
        sig += 10 * np.cos(2*np.pi * f * t * i)
    sig = sig.astype(np.int16)
    return sig

async def write_input(dut, sig):
    '''Send inputs into the dut and save the expected output.'''
    for i in range(256):
        bv = np2bv(np.array([int(sig[i]), 0]))
        dut.i_sample <= bv
        await FallingEdge(dut.i_clk)
    expected_results.append(np.fft.fft(sig))

async def read_output_once(dut):
    while (dut.o_sync != 1):  # wait until sync indicates start of frame
        await FallingEdge(dut.i_clk)
    sig = np.zeros(256, dtype=np.cdouble)
    for i in range(256):
        binstr = dut.o_result.value.get_binstr()
        split_binstr = [binstr[:21], binstr[21:]]
        output_arr = [BinaryValue(x).signed_integer for x in split_binstr]
        sig[i] = output_arr[0] + output_arr[1] * 1j
        await FallingEdge(dut.i_clk)
    test_results.append(sig)

async def read_output_multiple(dut, n):
    for i in range(n):
        await read_output_once(dut)

def gen_result_plots():
    '''Plot expected results against received results and save them in the
    plots/ directory.'''
    n = len(test_results)
    x = np.arange(256)
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
async def test_fft(dut):
    # Create a 10us period clock on port clk
    clock = Clock(dut.i_clk, 10, units="us")
    cocotb.fork(clock.start())

    await FallingEdge(dut.i_clk)
    dut.i_reset <= 1
    dut.i_ce <= 0
    dut.i_sample <= 0

    for _ in range(50):
        await FallingEdge(dut.i_clk)

    dut.i_reset <= 0
    dut.i_ce <= 1

    reader = cocotb.fork(read_output_multiple(dut, 3))

    await write_input(dut, constant_sig())
    await write_input(dut, cosine_sig(5))
    await write_input(dut, multi_cosine_sig())
    await write_input(dut, random_sig())

    await reader

    gen_result_plots()
