# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

import numpy as np

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, Timer
from cocotb.binary import BinaryValue

def np2bv(int_list):
    """ Convert a 8b integer numpy array in cocotb BinaryValue """
    # int_list = int_arr.tolist()
    binarized = [format(x & 0x1fffff, '021b') if x < 0 else format(x, '021b')
                 for x in int_list]
    bin_string = ''.join(binarized)
    return BinaryValue(bin_string)

def get_msg(i, received, expected):
    return 'idx {}, dut output of {}, expected {}'.format(i, received, expected)

def get_test_vector():
    n = 200
    x = np.random.randint(-128, 128, size=n).astype(np.complex128)
    x += np.random.randint(-128, 128, size=n) * 1j
    y = x.real ** 2 + x.imag ** 2
    return x, y

async def check_output(dut):
    print('Beginning test with random input data.')
    x, y = get_test_vector()
    i = 0
    while i < len(x):
        dut.data_i <= np2bv([int(x[i].real), int(x[i].imag)])
        valid = np.random.randint(2)  # randomly de-assert valid
        # valid = 1
        last = 1 if np.random.randint(10) == 0 else 0
        # last = 0
        dut.valid_i <= (1 if valid else 0)
        dut.last_i <= last
        # give control to simulator briefly for combinational logic
        await Timer(1, units='us')
        if (valid):
            assert dut.valid_o == 1
            expected_val = y[i]
            received_val = dut.data_o.value.signed_integer
            assert received_val == expected_val, get_msg(i, received_val,
                                                         expected_val)
            i += 1
        else:
            assert dut.valid_o == 0
        if last:
            assert dut.last_o == 1
        else:
            assert dut.last_o == 0
        await FallingEdge(dut.clk_i)

async def check_output_no_en(dut):
    '''Check that dut doesn't output valid data if en if off.'''
    print('Beginning test with random input data but en_i is low.')
    await Timer(1, units='us')
    for i in range(20):
        dut.data_i <= int(np.random.randint(-128, 128))  # feed in garbage data
        dut.valid_i <= 1
        assert dut.valid_o == 0
        await FallingEdge(dut.clk_i)

@cocotb.test()
async def main(dut):
    """ Test Power Spectrum """
    # Create a 10us period clock on port clk
    clock = Clock(dut.clk_i, 10, units="us")
    cocotb.fork(clock.start())

    # Reset system
    await FallingEdge(dut.clk_i)
    dut.rst_n_i <= 0
    dut.en_i <= 0
    dut.data_i <= 0
    dut.valid_i <= 0
    dut.last_i <= 0

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
