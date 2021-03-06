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
async def test_vec_mul(dut):
    """ Test Vector Multiplier """
    # Create a 10us period clock on port clk
    clock = Clock(dut.clk_i, 10, units="us")
    cocotb.fork(clock.start())

    # Reset system
    await FallingEdge(dut.clk_i)
    dut.rst_n_i <= 0
    dut.data0_i <= np2bv(np.zeros(shape=DUT_VECTOR_SIZE, dtype=np.int8))
    dut.data1_i <= np2bv(np.zeros(shape=DUT_VECTOR_SIZE, dtype=np.int8))
    dut.last0_i <= 0
    dut.last1_i <= 0
    dut.valid0_i <= 0
    dut.valid1_i <= 0
    dut.ready_i <= 0

    await FallingEdge(dut.clk_i)
    dut.rst_n_i <= 1
    dut.data0_i <= np2bv(np.zeros(shape=DUT_VECTOR_SIZE, dtype=np.int8))
    dut.data1_i <= np2bv(np.zeros(shape=DUT_VECTOR_SIZE, dtype=np.int8))
    dut.ready_i <= 1

    # Generate random values and compare results
    await FallingEdge(dut.clk_i)
    for _ in range(10):
        val1 = np.random.randint(-128, 128, size=DUT_VECTOR_SIZE, dtype=np.int8)
        val2 = np.random.randint(-128, 128, size=DUT_VECTOR_SIZE, dtype=np.int8)
        dut.valid0_i <= 1
        dut.valid1_i <= 1

        dut.data0_i <= np2bv(val1)
        dut.data1_i <= np2bv(val2)

        mult = val1.astype(np.int16) * val2.astype(np.int16)
        expected = np2bv(mult, n_bits=16)

        await FallingEdge(dut.clk_i)
        for j in range(DUT_VECTOR_SIZE):
            observed = dut.data_o.value
            assert observed == expected,\
                   "data0_i = %d, data1_i = %d, expected = %d, observed = %d" %\
                   (val1[j], val2[j], expected.value, observed)
