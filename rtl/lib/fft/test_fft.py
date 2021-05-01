# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge
from cocotb.binary import BinaryValue


def np2bv(int_arr):
    """ Convert a 16b integer numpy array in cocotb BinaryValue """
    int_list = int_arr.tolist()
    binarized = [format(x & 0xFFFF, '016b') if x < 0 else format(x, '016b')
                 for x in int_list]
    bin_string = ''.join(binarized)
    return BinaryValue(bin_string)


@cocotb.test()
async def test_fft(dut):
    # Create a 10us period clock on port clk
    clock = Clock(dut.clk_i, 10, units="us")
    cocotb.fork(clock.start())

    await FallingEdge(dut.clk_i)
    dut.i_reset <= 1
    dut.i_ce <= 0
    dut.i_sample <= 0

    for _ in range(50):
        await FallingEdge(dut.clk_i)

    dut.i_reset <= 0
    dut.i_ce <= 1

    # put in constant real input
    for i in range(256):
        bv = np2bv(np.array([1, 0]))
        dut.i_sample <= bv

    # read output
    for _ in range(500):
        await FallingEdge(dut.clk_i)
