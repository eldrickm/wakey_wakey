# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

import numpy as np

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, Timer
from cocotb.binary import BinaryValue

FRAME_LEN = 13

def np2bv(int_arr, n_bits=8):
    """ Convert a n_bits integer numpy array to cocotb BinaryValue """
    # Step 1: Turn ndarray into a list of integers
    int_list = int_arr.tolist()

    # Step 2: Format each number as two's complement strings
    binarized = [format(x & 2 ** n_bits - 1, f'0{n_bits}b') if x < 0 else
                 format(x, f'0{n_bits}b')
                 for x in int_list]

    # Step 3: Join all strings into one large binary string
    bin_string = ''.join(binarized)

    # Step 4: Convert to cocotb BinaryValue and return
    return BinaryValue(bin_string)

def get_msg(i, received, expected):
    return 'idx {}, dut output of {}, expected {}'.format(i, received, expected)

def get_test_vector():
    n = FRAME_LEN * 10
    x = np.random.randint(-128, 128, size=n)
    print('first 10 elems of input vector:')
    print(x[:10])
    xr = x.reshape(10, FRAME_LEN)
    y = []
    for i in range(10):
        y.append(np2bv(xr[i,:]))
    return x, y

async def write_input(dut, x, inter_frame_delay=0):
    for i in range(10):
        dut.valid_i <= 1
        for j in range(FRAME_LEN):
            dut.data_i <= int(x[i*FRAME_LEN + j])
            await FallingEdge(dut.clk_i)
        dut.valid_i <= 0  # add inter-frame spacing
        for i in range(inter_frame_delay):
            await FallingEdge(dut.clk_i)

async def check_output(dut, expected_vals):
    for i in range(len(expected_vals)):
        expected_val = expected_vals[i]
        while (dut.valid_o != 1):
            await FallingEdge(dut.clk_i)
        assert dut.valid_o == 1
        assert dut.last_o == 1
        received_val = dut.data_o
        assert received_val == expected_val, get_msg(i, received_val,
                                                     expected_val)
        await FallingEdge(dut.clk_i)
        print('Received {} as expected.'.format(expected_val))
    print('Received frames as expected.')

async def check_output_no_en(dut):
    '''Check that dut doesn't output valid data if en if off.'''
    print('Beginning test with random input data but en_i is low.')
    await Timer(1, units='us')
    for i in range(600):
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
    dut.last_i <= 0

    # reset
    await FallingEdge(dut.clk_i)
    dut.rst_n_i <= 1

    # test 1
    dut.en_i <= 1
    x, y = get_test_vector()
    cocotb.fork(write_input(dut, x, inter_frame_delay=0))
    await check_output(dut, y)

    # test 2
    dut.en_i <= 0
    await check_output_no_en(dut)

    # test 3
    dut.en_i <= 1
    x, y = get_test_vector()
    cocotb.fork(write_input(dut, x, inter_frame_delay=5))
    await check_output(dut, y)
