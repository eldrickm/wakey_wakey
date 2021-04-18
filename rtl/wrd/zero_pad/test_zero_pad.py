# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

import numpy as np
import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge
from cocotb.binary import BinaryValue

DUT_VECTOR_LENGTH = 13
FRAME_LENGTH = 10

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
async def test_zero_pad(dut):
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

    # Sequential data emission
    expected = 0
    oldval = 0
    await FallingEdge(dut.clk_i)
    for i in range(FRAME_LENGTH + 2):
        if i < FRAME_LENGTH:
            val = i + 1
            dut.data_i <= val
            dut.valid_i <= 1
            dut.last_i <= 0
        else:
            dut.last_i <= 0
            dut.valid_i <= 0

        if i == FRAME_LENGTH - 1:
            dut.last_i <= 1

        expected = oldval
        oldval = val

        await FallingEdge(dut.clk_i)
        observed = dut.data_o.value
        if i == 0 or i > FRAME_LENGTH:
            expected = 0
        expected = np2bv(np.asarray([expected]), 8 * DUT_VECTOR_LENGTH)
        assert observed == expected,\
               "expected = %x, observed = %x" % (expected, observed)

    for i in range(FRAME_LENGTH + 2):
        if i < FRAME_LENGTH:
            val = random.randint(-500, 500)
            dut.data_i <= val
            dut.valid_i <= 1
            dut.last_i <= 0
        else:
            dut.last_i <= 0
            dut.valid_i <= 0

        if i == FRAME_LENGTH - 1:
            dut.last_i <= 1

        expected = oldval
        oldval = val

        await FallingEdge(dut.clk_i)
        observed = dut.data_o.value
        if i == 0 or i > FRAME_LENGTH:
            expected = 0
        expected = np2bv(np.asarray([expected]), 8 * DUT_VECTOR_LENGTH)
        assert observed == expected,\
               "expected = %x, observed = %x" % (expected, observed)

    for _ in range(FRAME_LENGTH):
        await FallingEdge(dut.clk_i)

    for i in range(FRAME_LENGTH + 2):
        if i < FRAME_LENGTH:
            val = random.randint(-500, 500)
            dut.data_i <= val
            dut.valid_i <= 1
            dut.last_i <= 0
        else:
            dut.last_i <= 0
            dut.valid_i <= 0

        if i == FRAME_LENGTH - 1:
            dut.last_i <= 1

        expected = oldval
        oldval = val

        await FallingEdge(dut.clk_i)
        observed = dut.data_o.value
        if i == 0 or i > FRAME_LENGTH:
            expected = 0
        expected = np2bv(np.asarray([expected]), 8 * DUT_VECTOR_LENGTH)
        assert observed == expected,\
               "expected = %x, observed = %x" % (expected, observed)
