# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

import numpy as np

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, Timer

import sys
sys.path.append('../../../py/')
import aco
import pdm

# Fixed parameters:
N_FRAMES = 50  # frames 

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
    print('Preemphasis: expected output: ', y[:200])
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
        print('\r{}/16000'.format(i), end='')
    print('Preemphasis: received expected output of ', y)

async def write_shift(dut, shift=0):
    '''Write the amount to shift by in the quantization stage.'''
    dut.shift_i <= shift
    dut.wr_en <= 1
    await FallingEdge(dut.clk_i)
    dut.shift_i <= 0
    dut.wr_en <= 0

async def do_test(dut):
    print('Beginning directed test with audio data.')
    x, y = get_test_vector()
    cocotb.fork(write_input(dut, x))
    p = cocotb.fork(check_preemphasis   (dut, y[0]))
    # cocotb.fork(check_framing       (dut, y[1]))
    # cocotb.fork(check_fft           (dut, y[2]))
    # cocotb.fork(check_power_spectrum(dut, y[3]))
    # cocotb.fork(check_mfcc          (dut, y[4]))
    # cocotb.fork(check_log           (dut, y[5]))
    # cocotb.fork(check_dct           (dut, y[6]))
    # cocotb.fork(check_quant         (dut, y[7]))
    # await       check_final         (dut, y[8])
    await p

async def do_test_no_en(dut):
    print('Beginning test with random input data but en_i is low.')
    await Timer(1, units='us')
    for i in range(10000):
        dut.data_i <= int(np.random.randint(-128, 128))  # feed in garbage data
        dut.valid_i <= 1
        assert dut.valid_o == 0
        await FallingEdge(dut.clk_i)

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
