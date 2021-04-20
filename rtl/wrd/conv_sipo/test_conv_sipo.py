# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

import numpy as np

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge
from cocotb.binary import BinaryValue

DUT_VECTOR_SIZE = 13


def np2bv(int_arr, n_bits=8):
    """ Convert a n_bits integer numpy array to cocotb BinaryValue """
    # Step 1: Turn ndarray into a list of integers
    int_list = int_arr.tolist()

    # Step 2: Format each number as two's complement strings
    binarized = [format(x & 2 ** n_bits - 1, f'0{n_bits}b') if x < 0 else
                 format(x, f'0{n_bits}b')
                 for x in int_list]

    # Step 3: Join all strings into one large binary string
    bin_string = ''.join(binarized)

    # Step 4: Convert to cocotb BinaryValue and return
    return BinaryValue(bin_string)


@cocotb.test()
async def test_conv_sipo(dut):
    """ Test Serial-In, Parallel Out Module """
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

    # Load Complete Sequential Stream
    for i in range(50 * 8):
        await FallingEdge(dut.clk_i)
        dut.data_i <= i
        dut.valid_i <= 1
        if (i + 1) % 50 == 0 and i != 0:
            dut.last_i <= 1
        else:
            dut.last_i <= 0

    # Deassert End-Of-Packet Signals
    await FallingEdge(dut.clk_i)
    dut.last_i <= 0
    dut.valid_i <= 0

    # TODO: Add a real test for this block
    # Output Checking
    await FallingEdge(dut.clk_i)
    for i in range(50):
        observed = dut.data_o.value
        expected = i % 50
        await FallingEdge(dut.clk_i)
        #  assert observed == expected, "observed = %d, expected = %d," %\
        #                               (observed, expected)
