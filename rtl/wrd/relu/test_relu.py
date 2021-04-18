# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge
from cocotb.binary import BinaryValue

@cocotb.test()
async def test_relu(dut):
    """ Test Rectified Linear Unit """
    # Create a 10us period clock on port clk
    clock = Clock(dut.clk_i, 10, units="us")
    cocotb.fork(clock.start())

    # Reset system
    await FallingEdge(dut.clk_i)
    dut.rst_n_i <= 0
    dut.data_i  <= 0
    dut.last_i  <= 0
    dut.valid_i <= 0
    dut.ready_i <= 0

    await FallingEdge(dut.clk_i)
    dut.rst_n_i <= 1
    dut.ready_i <= 1

    # Generate random values and compare results
    await FallingEdge(dut.clk_i)
    for _ in range(10):
        val = random.randint(-2 ** 31, 2 ** 31 - 1)
        dut.data_i <= val
        dut.valid_i <= 1

        expected = max(0, val)

        await FallingEdge(dut.clk_i)
        observed = dut.data_o.value
        assert observed == expected,\
               "expected = %d, observed = %d" % (expected, observed)
