# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

import numpy as np

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, Timer

FRAME_LEN = 256

def get_msg(i, received, expected):
    return 'idx {}, dut output of {}, expected {}'.format(i, received, expected)

def get_test_vector():
    n = FRAME_LEN * 10
    x = np.random.randint(-256, 256, size=n)
    print('first 10 elems of input vector:')
    print(x[:10])
    y = x.reshape(10, FRAME_LEN)
    return x, y

async def write_input(dut, x):
    i = 0
    while i < len(x):
        dut.data_i <= int(x[i])
        valid = np.random.randint(2)  # randomly de-assert valid
        # valid = 1
        dut.valid_i <= (1 if valid else 0)
        if (valid):
            i += 1
        await FallingEdge(dut.clk_i)

async def check_output(dut, expected_frames):
    for i in range(len(expected_frames)):
        expected_frame = expected_frames[i,:]
        print('first 10 elems expected frame:')
        print(expected_frame[:10])
        while (dut.valid_o != 1):
            await FallingEdge(dut.clk_i)
        for j in range(FRAME_LEN):
            assert dut.valid_o == 1
            if j == FRAME_LEN - 1:
                assert dut.last_o == 1
            else:
                assert dut.last_o == 0
            expected_val = expected_frame[j]
            received_val = dut.data_o.value.signed_integer
            assert received_val == expected_val, get_msg(j, received_val,
                                                         expected_val)
            await FallingEdge(dut.clk_i)
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
    x, y = get_test_vector()
    cocotb.fork(write_input(dut, x))
    await check_output(dut, y)

    # test 2
    dut.en_i <= 0
    await check_output_no_en(dut)

    # test 3
    dut.en_i <= 1
    x, y = get_test_vector()
    cocotb.fork(write_input(dut, x))
    await check_output(dut, y)
