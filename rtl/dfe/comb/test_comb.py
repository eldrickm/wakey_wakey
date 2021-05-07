# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

import numpy as np

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, Timer

WINDOW_LEN = 250

def get_msg(i, received, expected):
    return 'idx {}, dut output of {}, expected {}'.format(i, received, expected)

def get_test_vector():
    x = np.random.randint(2, size=(WINDOW_LEN * 3))
    rolled = np.roll(x, WINDOW_LEN)
    rolled[:WINDOW_LEN] = 0
    y = x - rolled
    return x, y

async def check_output(dut):
    x, y = get_test_vector()
    for i in range(len(x)):
        dut.data_i <= int(x[i])
        valid = True
        dut.valid_i <= 1 if valid else 0
        # give control to simulator for combinational logic:
        await Timer(1, units='us')
        if (valid):
            assert dut.valid_o == 1
            expected_val = y[i]
            received_val = dut.data_o.value.signed_integer
            assert received_val == expected_val, get_msg(i, received_val,
                                                         expected_val)
        else:
            assert dut.valid_o == 0
        await FallingEdge(dut.clk_i)

async def check_output_no_en(dut):
    '''Check that dut doesn't output valid data if en if off.'''
    for i in range(20):
        dut.data_i <= int(np.random.randint(2))  # feed in garbage data
        dut.valid_i <= 1
        assert dut.valid_o == 0
        await FallingEdge(dut.clk_i)

@cocotb.test()
async def test_sampler(dut):
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

    await FallingEdge(dut.clk_i)
    dut.rst_n_i <= 1

    dut.en_i <= 1
    await FallingEdge(dut.clk_i)
    await check_output(dut)

    dut.en_i <= 0
    await FallingEdge(dut.clk_i)
    await check_output_no_en(dut)

    dut.en_i <= 1
    await FallingEdge(dut.clk_i)
    await check_output(dut)  # TODO: fails here. Why?