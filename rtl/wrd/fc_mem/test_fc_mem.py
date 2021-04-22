# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge
from cocotb.binary import BinaryValue

@cocotb.test()
async def test_fc_mem(dut):
    # Create a 10us period clock on port clk
    clock = Clock(dut.clk_i, 10, units="us")
    cocotb.fork(clock.start())

    # Reset system
    await FallingEdge(dut.clk_i)
    dut.rst_n_i <= 0
    dut.cycle_en_i <= 0
    dut.wr_en_i <= 0
    dut.rd_en_i <= 0
    dut.rd_wr_bank_i <= 0
    dut.rd_wr_addr_i <= 0
    dut.wr_data_i <= 0

    await FallingEdge(dut.clk_i)
    dut.rst_n_i <= 1
    dut.cycle_en_i <= 0
    dut.wr_en_i <= 0
    dut.rd_en_i <= 0
    dut.rd_wr_bank_i <= 0
    dut.rd_wr_addr_i <= 0
    dut.wr_data_i <= 0

    await FallingEdge(dut.clk_i)

    # Sequential Write Weights
    for i in range(208 * 3):
        dut.cycle_en_i <= 0
        dut.wr_en_i <= 1
        dut.rd_en_i <= 0
        dut.rd_wr_bank_i <= i // 208
        dut.rd_wr_addr_i <= i % 208
        dut.wr_data_i <= i % 208
        await FallingEdge(dut.clk_i)

    # Sequential Write Bias
    for i in range(3):
        dut.cycle_en_i <= 0
        dut.wr_en_i <= 1
        dut.rd_en_i <= 0
        dut.rd_wr_bank_i <= i + 3
        dut.rd_wr_addr_i <= 0
        dut.wr_data_i <= i
        await FallingEdge(dut.clk_i)

    # Sequential Read
    for i in range(208 * 3):
        dut.cycle_en_i <= 0
        dut.wr_en_i <= 0
        dut.rd_en_i <= 1
        dut.rd_wr_bank_i <= i // 208
        dut.rd_wr_addr_i <= i % 208
        dut.wr_data_i <= 0
        await FallingEdge(dut.clk_i)

    await FallingEdge(dut.clk_i)

    # Check Cycling
    for i in range(208):
        dut.cycle_en_i <= 1
        dut.wr_en_i <= 0
        dut.rd_en_i <= 0
        dut.rd_wr_bank_i <= 0
        dut.rd_wr_addr_i <= 0
        dut.wr_data_i <= 0
        await FallingEdge(dut.clk_i)
