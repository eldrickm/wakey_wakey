# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

import numpy as np

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge


def get_msg(received, expected):
    return 'dut output of {}, expected {}'.format(received, expected)

async def check_output(dut, en):
    clock = Clock(dut.pdm_clk_i, 40, units="us")
    clk_gen = cocotb.fork(clock.start())

    input_arr = np.random.randint(2, size=(52,))
    print('input_arr:', input_arr)
    for i in range(52):
        dut.data_i <= int(input_arr[i])
        if (i % 4 == 1) and (en == 1):
            assert dut.valid_o == 1
            expected_val = input_arr[i - 1]
            assert dut.data_o == expected_val, get_msg(dut.data_o, expected_val)
        else:
            assert dut.valid_o == 0
            assert dut.data_o == 0, get_msg(dut.data_o, 0)
        await FallingEdge(dut.clk_i)

    clk_gen.kill()
    dut.pdm_clk_i <= 0

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
    dut.pdm_clk_i <= 0
    dut.data_i <= 0

    await FallingEdge(dut.clk_i)
    dut.rst_n_i <= 1

    dut.en_i <= 1
    await FallingEdge(dut.clk_i)
    await check_output(dut, 1)

    dut.en_i <= 0
    await FallingEdge(dut.clk_i)
    await check_output(dut, 0)

    dut.en_i <= 1
    await FallingEdge(dut.clk_i)
    await check_output(dut, 1)
