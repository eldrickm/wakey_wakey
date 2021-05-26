# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

import numpy as np

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, Timer

F_SYSTEM_CLK = 100  # test frequency
COUNT_CYCLES = 5  # cycles to wait after VAD goes low

def get_msg(i, received, expected):
    return 'idx {}, dut output of {}, expected {}'.format(i, received, expected)

def get_test_vector():
    return x, y

async def do_test(dut):
    print('Beginning test.')
    for i in range(10):
        assert dut.en_o == 0
        await FallingEdge(dut.clk_i)
    dut.vad_i <= 1
    await FallingEdge(dut.clk_i)
    for i in range(10):
        assert dut.en_o == 1
        await FallingEdge(dut.clk_i)
    dut.wake_valid_i <= 1
    for i in range(10):
        assert dut.en_o == 1
        await FallingEdge(dut.clk_i)
    dut.wake_valid_i <= 0
    await FallingEdge(dut.clk_i)
    for i in range(3):
        assert dut.en_o == 0
        await FallingEdge(dut.clk_i)
    dut.vad_i <= 0
    for i in range(10):
        assert dut.en_o == 0
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
    dut.vad_i <= 0
    dut.wake_valid_i <= 0

    # reset
    await FallingEdge(dut.clk_i)
    dut.rst_n_i <= 1

    await do_test(dut)
    await do_test(dut)
    await do_test(dut)
