# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

import numpy as np

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge


COUNTER_PERIOD = 4


async def check_output(dut, en):
    for i in range(22):
        if (en == 1):
            counter_val = i % COUNTER_PERIOD
            high_expected = (counter_val >= COUNTER_PERIOD / 2)
            expected_val = 1 if high_expected else 0
            msg = 'dut output of {}, expected val of {}'.format(dut.pdm_clk_o, expected_val)
            assert dut.pdm_clk_o == expected_val, msg
        else:
            msg = 'dut output of {}, expected {}'.format(dut.pdm_clk_o, 0)
            assert dut.pdm_clk_o == 0, msg
        await FallingEdge(dut.clk_i)

@cocotb.test()
async def test_pdm_clk(dut):
    """ Test Rectified Linear Unit """
    # Create a 10us period clock on port clk
    clock = Clock(dut.clk_i, 10, units="us")
    cocotb.fork(clock.start())

    # Reset system
    await FallingEdge(dut.clk_i)
    dut.rst_n_i <= 0
    dut.en_i  <= 0

    await FallingEdge(dut.clk_i)
    dut.rst_n_i <= 1

    for _ in range(10):
        await FallingEdge(dut.clk_i)

    dut.en_i <= 1
    await check_output(dut, 1)
    dut.en_i <= 0
    await FallingEdge(dut.clk_i)
    await check_output(dut, 0)
    dut.en_i <= 1
    await check_output(dut, 1)
