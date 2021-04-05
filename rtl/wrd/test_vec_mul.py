# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge


@cocotb.test()
async def test_vec_mul(dut):
    """ Test Vector Multiplier """

    clock = Clock(dut.clk_i, 10, units="us")  # Create a 10us period clock on port clk
    cocotb.fork(clock.start())  # Start the clock

    await FallingEdge(dut.clk_i)  # Synchronize with the clock
    for i in range(10):
        val = random.randint(0, 8)

        dut.data1_i <= val
        dut.data2_i <= val

        dut.last1_i <= 0
        dut.last2_i <= 0

        dut.valid1_i <= 1
        dut.valid2_i <= 1

        dut.ready_i <= 1

        await FallingEdge(dut.clk_i)
        assert dut.data_o.value == val * val,\
               f"output was incorrect on the {i}th cycle"
