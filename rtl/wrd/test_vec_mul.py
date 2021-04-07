# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

import random
import numpy as np

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge
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
async def test_vec_mul(dut):
    """ Test Vector Multiplier """
    # Create a 10us period clock on port clk
    clock = Clock(dut.clk_i, 10, units="us")
    cocotb.fork(clock.start())

    # Synchronize with the clock
    await FallingEdge(dut.clk_i)
    for i in range(10):
        val1 = np.random.randint(-128, 128, size=DUT_VECTOR_SIZE, dtype=np.int8)
        val2 = np.random.randint(-128, 128, size=DUT_VECTOR_SIZE, dtype=np.int8)

        for i in range(DUT_VECTOR_SIZE):
            dut.data1_i <= np2bv(val1)
            dut.data2_i <= np2bv(val2)

        dut.last1_i <= 0
        dut.last2_i <= 0

        dut.valid1_i <= 1
        dut.valid2_i <= 1

        dut.ready_i <= 1

        expected = np2bv(val1 * val2)
        await FallingEdge(dut.clk_i)
        for i in range(DUT_VECTOR_SIZE):
            observed = dut.data_o.value
            assert observed == expected,\
                   "data1_i = %d, data2_i = %d, expected = %d, observed = %d" %\
                   (val1[i], val2[i], expected, observed)
