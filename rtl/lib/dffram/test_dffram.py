# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge
from cocotb.binary import BinaryValue


@cocotb.test()
async def test_dffram(dut):
    # Create a 10us period clock on port clk
    clock = Clock(dut.clk_i, 10, units="us")
    cocotb.fork(clock.start())

    await FallingEdge(dut.clk_i)
    dut.data_i <= 0
    dut.addr_i <= 0
    dut.wr_en_i <= 0
    dut.en_i <= 0
    await FallingEdge(dut.clk_i)

    # Sequential Write
    for i in range(256):
        dut.en_i <= 1
        dut.wr_en_i <= 1
        dut.addr_i = i
        dut.data_i = i
        await FallingEdge(dut.clk_i)

    # Sequential Read
    for i in range(256):
        dut.en_i <= 1
        dut.wr_en_i <= 0
        dut.addr_i = i
        dut.data_i = 0
        await FallingEdge(dut.clk_i)
        observed = dut.data_o.value
        expected = i
        assert observed == expected, "observed = %d, expected = %d," %\
                                     (observed, expected)
