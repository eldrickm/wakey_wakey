# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge
from cocotb.binary import BinaryValue

DUT_VECTOR_SIZE = 1

@cocotb.test()
async def test_conv_mem(dut):
    # Create a 10us period clock on port clk
    clock = Clock(dut.clk_i, 10, units="us")
    cocotb.fork(clock.start())

    # Reset system
    await FallingEdge(dut.clk_i)
    dut.rst_n_i <= 0
    dut.wr_en_i <= 0
    dut.rd_wr_bank_i <= 0
    dut.rd_wr_addr_i <= 0
    dut.wr_data_i <= 0

    await FallingEdge(dut.clk_i)
    dut.rst_n_i <= 1
    dut.wr_en_i <= 0
    dut.rd_wr_bank_i <= 0
    dut.rd_wr_addr_i <= 0
    dut.wr_data_i <= 0

    await FallingEdge(dut.clk_i)

    # Sequential Write
    for i in range(24):
        dut.wr_en_i <= 1
        dut.rd_wr_bank_i <= i // 8
        dut.rd_wr_addr_i <= i
        dut.wr_data_i <= i
        await FallingEdge(dut.clk_i)

    # Sequential Read
    for i in range(24):
        dut.wr_en_i <= 0
        dut.rd_en_i <= 1
        dut.rd_wr_bank_i <= i // 8
        dut.rd_wr_addr_i <= i
        dut.wr_data_i <= 0
        await FallingEdge(dut.clk_i)
        if i // 8 == 0:
            observed = dut.data0_o.value
        elif i // 8 == 1:
            observed = dut.data1_o.value
        elif i // 8 == 2:
            observed = dut.data2_o.value

        expected = i
        assert observed == expected, "observed = %d, expected = %d," %\
                                     (observed, expected)
