# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge
from cocotb.binary import BinaryValue

DUT_VECTOR_SIZE = 13

@cocotb.test()
async def test_conv_mem(dut):
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

    # Sequential Write
    for i in range(32):
        dut.cycle_en_i <= 0
        dut.wr_en_i <= 1
        dut.rd_en_i <= 0
        dut.rd_wr_bank_i <= i // 8
        dut.rd_wr_addr_i <= i
        dut.wr_data_i <= i
        await FallingEdge(dut.clk_i)

    # Sequential Read
    for i in range(32):
        dut.cycle_en_i <= 0
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
        else:
            observed = dut.bias_o.value

        expected = i
        assert observed == expected, "observed = %d, expected = %d," %\
                                     (observed, expected)
    await FallingEdge(dut.clk_i)

    # Check Cycling
    for i in range(8 * 50):
        dut.cycle_en_i <= 1
        dut.wr_en_i <= 0
        dut.rd_en_i <= 0
        dut.rd_wr_bank_i <= 0
        dut.rd_wr_addr_i <= 0
        dut.wr_data_i <= 0
        await FallingEdge(dut.clk_i)
        observed0 = dut.data0_o.value
        observed1 = dut.data1_o.value
        observed2 = dut.data2_o.value
        observed_bias = dut.bias_o.value

        expected0 = i // 50
        expected1 = (i // 50) + 8
        expected2 = (i // 50) + 16
        expected_bias = (i // 50) + 24

        assert observed0 == expected0, "observed0 = %d, expected0 = %d," %\
                                       (observed0, expected0)
        assert observed1 == expected1, "observed1 = %d, expected1 = %d," %\
                                       (observed1, expected1)
        assert observed2 == expected2, "observed2 = %d, expected2 = %d," %\
                                       (observed2, expected2)
        assert observed_bias == expected_bias, "observed_bias = %d, expected_bias = %d," %\
                                       (observed_bias, expected_bias)
