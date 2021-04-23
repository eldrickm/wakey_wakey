# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

import numpy as np

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge
from cocotb.binary import BinaryValue

@cocotb.test()
async def test(dut):
    # Create a 10us period clock on port clk
    clock = Clock(dut.clk_i, 10, units="us")
    cocotb.fork(clock.start())

    # Reset system
    await FallingEdge(dut.clk_i)
    dut.rst_n_i <= 0
    dut.data_i  <= 0
    dut.last_i  <= 0
    dut.valid_i <= 0

    await FallingEdge(dut.clk_i)
    dut.rst_n_i <= 1

    # Generate random values and compare results
    await FallingEdge(dut.clk_i)
    for _ in range(10):
        dut.data_i <= 0
        dut.valid_i <= 1
        await FallingEdge(dut.clk_i)

    for _ in range(10):
        dut.data_i <= 4
        dut.valid_i <= 1
        await FallingEdge(dut.clk_i)

    for _ in range(10):
        dut.data_i <= 2
        dut.valid_i <= 1
        await FallingEdge(dut.clk_i)

    for _ in range(1):
        dut.data_i <= 1
        dut.valid_i <= 1
        await FallingEdge(dut.clk_i)

    for _ in range(2048):
        dut.data_i <= 2
        dut.valid_i <= 1
        await FallingEdge(dut.clk_i)
