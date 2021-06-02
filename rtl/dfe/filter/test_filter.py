# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

import numpy as np

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, Timer

import sys
sys.path.append('../../../py/')
import pdm

WINDOW_LEN = 250

def get_msg(i, received, expected):
    return 'idx {}, dut output of {}, expected {}'.format(i, received, expected)

def get_test_vector():
    n = 100
    # x = np.random.randint(2**15, size=n)
    t = np.linspace(0, 1, n)
    x = np.cos(2*np.pi * 5 * t) * (2**15 - 1)

    x = pdm.pcm_to_pdm_pwm(x)
    # x = pdm.pcm_to_pdm_random(x)
    # x = pdm.pcm_to_pdm_err(x)
    print('generated pdm sig', x[10:])
    print('len x', len(x))
    y = pdm.pdm_to_pcm(x, 2)
    print('expected values', y)
    print('len y', len(y))
    return x, y

async def check_output(dut):
    print('Beginning test with random input data.')
    x, y = get_test_vector()
    i = 0  # index into x
    j = 0  # index into y
    while i < len(x):
        dut.data_i <= int(x[i])
        # valid = np.random.randint(2)  # randomly de-assert valid
        valid = 1
        dut.valid_i <= (1 if valid else 0)
        await Timer(1, units='us')  # let combinational logic work
        if (dut.valid_o.value.integer):
            expected_val = y[j]
            received_val = dut.data_o.value.signed_integer
            if (j >= 2):  # first TWO values are garbage
                assert received_val == expected_val, get_msg(i, received_val,
                                                             expected_val)
            j += 1
            print('\r{}/{}'.format(j, len(y)), end='')
        if (valid):
            i += 1
        await FallingEdge(dut.clk_i)

async def check_output_no_en(dut):
    '''Check that dut doesn't output valid data if en if off.'''
    print('Beginning test with random input data but en_i is low.')
    await Timer(1, units='us')
    for i in range(1000):
        dut.data_i <= int(np.random.randint(2))  # feed in garbage data
        dut.valid_i <= 1
        assert dut.valid_o == 0
        await FallingEdge(dut.clk_i)

@cocotb.test()
async def main(dut):
    """ Test Rectified Linear Unit """
    # Create a 10us period clock on port clk
    clock = Clock(dut.clk_i, 10, units="us")
    cocotb.fork(clock.start())

    # Reset system
    await FallingEdge(dut.clk_i)
    dut.rst_n_i <= 0
    dut.en_i <= 0
    dut.data_i <= 0
    dut.valid_i <= 0

    # reset
    await FallingEdge(dut.clk_i)
    dut.rst_n_i <= 1

    # test 1
    dut.en_i <= 1
    await check_output(dut)

    # test 2
    dut.en_i <= 0
    await check_output_no_en(dut)

    # test 3
    dut.en_i <= 1
    await check_output(dut)
