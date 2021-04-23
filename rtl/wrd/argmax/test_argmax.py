# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

import numpy as np

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge
from cocotb.binary import BinaryValue

DUT_VECTOR_SIZE = 3

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
async def test_flat_sum(dut):
    # Create a 10us period clock on port clk
    clock = Clock(dut.clk_i, 10, units="us")
    cocotb.fork(clock.start())

    # Reset system
    await FallingEdge(dut.clk_i)
    dut.rst_n_i <= 0
    dut.data_i  <= np2bv(np.zeros(shape=DUT_VECTOR_SIZE, dtype=np.int32), 18)
    dut.last_i  <= 0
    dut.valid_i <= 0
    dut.ready_i <= 0

    await FallingEdge(dut.clk_i)
    dut.rst_n_i <= 1
    dut.ready_i <= 1

    # Generate random values and compare results
    await FallingEdge(dut.clk_i)
    for _ in range(10):
        val0 = np.random.randint(-2 ** 23, 2 ** 23 - 1, size=DUT_VECTOR_SIZE,
                                 dtype=np.int32)

        dut.data_i <= np2bv(val0, 24)
        dut.valid_i <= 1

        add = np.asarray([1 << np.argmax(np.flip(val0))])
        expected = np2bv(add, n_bits=3).value

        await FallingEdge(dut.clk_i)
        observed = dut.data_o.value
        assert observed == expected,\
               "expected = %d, observed = %d" % (expected, observed)
