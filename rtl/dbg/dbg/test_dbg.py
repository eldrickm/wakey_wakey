# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

import numpy as np

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge


async def do_test(dut):
    print('Beginning test.')
    for i in range(10):
        assert dut.en_o == 0
        await FallingEdge(dut.clk_i)
    dut.vad_i <= 1
    await FallingEdge(dut.clk_i)
    for i in range(10):
        assert dut.en_o == 1
        await FallingEdge(dut.clk_i)
    dut.wake_valid_i <= 1
    for i in range(10):
        assert dut.en_o == 1
        await FallingEdge(dut.clk_i)
    dut.wake_valid_i <= 0
    await FallingEdge(dut.clk_i)
    for i in range(3):
        assert dut.en_o == 0
        await FallingEdge(dut.clk_i)
    dut.vad_i <= 0
    for i in range(10):
        assert dut.en_o == 0
        await FallingEdge(dut.clk_i)


@cocotb.test()
async def main(dut):
    # Create a 10us period clock on port clk
    clock = Clock(dut.clk_i, 10, units="us")
    cocotb.fork(clock.start())

    # Reset system
    await FallingEdge(dut.clk_i)

    dut.la_data_in_i <= 0
    dut.la_oenb_i <= 0

    dut.ctl_pipeline_en_i <= 0

    dut.mic_pdm_data_i <= 0

    dut.dfe_data_i <= 0xDE
    dut.dfe_valid_i <= 0

    dut.aco_data_i <= 0xDEADBEEFDEADBEEFDEADBEEFCC
    dut.aco_valid_i <= 0
    dut.aco_last_i <= 0

    dut.wrd_wake_i <= 0
    dut.wrd_wake_valid_i <= 0

    # reset
    await FallingEdge(dut.clk_i)
    dut.rst_n_i <= 1
    dut.la_data_in_i <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
    dut.la_oenb_i <= 0b00000
    
    # test CTL
    await FallingEdge(dut.clk_i)
    assert dut.ctl_pipeline_en_o.value == 0
    assert dut.la_data_out_o.value[127 - 0] == 0

    dut.ctl_pipeline_en_i <= 1
    dut.la_oenb_i <= 0b00001

    await FallingEdge(dut.clk_i)
    assert dut.ctl_pipeline_en_o.value == 1
    assert dut.la_data_out_o.value[127 - 0] == 1

    dut.la_oenb_i <= 0b00000

    # test MIC -> DFE
    await FallingEdge(dut.clk_i)
    assert dut.mic_pdm_data_o.value == 0
    assert dut.la_data_out_o.value[127 - 1] == 0

    dut.la_oenb_i <= 0b00010
    dut.mic_pdm_data_i <= 1

    await FallingEdge(dut.clk_i)
    assert dut.mic_pdm_data_o.value == 1
    assert dut.la_data_out_o.value[127 - 1] == 1

    dut.la_oenb_i <= 0b00000

    # test DFE -> ACO
    await FallingEdge(dut.clk_i)
    assert dut.dfe_data_o.value == 0
    assert dut.la_data_out_o.value[127 - 1] == 0

    dut.la_oenb_i <= 0b00010
    dut.mic_pdm_data_i <= 1

    await FallingEdge(dut.clk_i)
    assert dut.mic_pdm_data_o.value == 1
    assert dut.la_data_out_o.value[127 - 1] == 1

    dut.la_oenb_i <= 0b00000
