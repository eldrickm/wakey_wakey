# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

import numpy as np

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge
from cocotb.binary import BinaryValue

DUT_VECTOR_SIZE = 13


def np2bv(int_arr):
    """ Convert a 8b integer numpy array in cocotb BinaryValue """
    int_list = int_arr.tolist()
    binarized = [format(x & 0xFF, '08b') if x < 0 else format(x, '08b')
                 for x in int_list]
    bin_string = ''.join(binarized)
    return BinaryValue(bin_string)


@cocotb.test()
async def test_conv1d(dut):
    """ Test Conv1D Module """
    # Create a 10us period clock on port clk
    clock = Clock(dut.clk_i, 10, units="us")
    cocotb.fork(clock.start())

    # Reset DUT
    await FallingEdge(dut.clk_i)
    dut.rst_n_i <= 0
    dut.data_i <= 0
    dut.valid_i <= 0
    dut.last_i <= 0
    dut.ready_i <= 0

    for _ in range(20):
        await FallingEdge(dut.clk_i)
        dut.rst_n_i <= 1
        dut.ready_i <= 1

    # Load MFCC Data
    for i in range(50):
        await FallingEdge(dut.clk_i)
        dut.data_i <= i
        dut.valid_i <= 1
        if i == 49:
            dut.last_i <= 1

    # Deassert End-Of-Packet Signals
    await FallingEdge(dut.clk_i)
    dut.last_i <= 0
    dut.valid_i <= 0

    await FallingEdge(dut.clk_i)
    for i in range(50 * 8):
        observed = dut.data_o.value
        expected = i % 50
        await FallingEdge(dut.clk_i)
        assert observed == expected, "observed = %d, expected = %d," %\
                                     (observed, expected)
