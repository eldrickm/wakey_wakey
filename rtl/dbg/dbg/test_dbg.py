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
    dut.la_oenb_i <= 0b11111

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
    dut.la_oenb_i <= 0b11111
    
    # test CTL
    await FallingEdge(dut.clk_i)
    assert dut.ctl_pipeline_en_o.value == 0
    assert dut.la_data_out_o.value[127 - 0] == 0

    # dut.ctl_pipeline_en_i <= 1
    dut.la_oenb_i <= 0b11110

    await FallingEdge(dut.clk_i)
    assert dut.ctl_pipeline_en_o.value == 1
    assert dut.la_data_out_o.value[127 - 0] == 0

    dut.la_oenb_i <= 0b11111

    # test MIC -> DFE
    await FallingEdge(dut.clk_i)
    assert dut.mic_pdm_data_o.value == 0
    assert dut.la_data_out_o.value[127 - 1] == 0

    dut.la_oenb_i <= 0b11101
    dut.mic_pdm_data_i <= 1

    await FallingEdge(dut.clk_i)
    assert dut.mic_pdm_data_o.value == 1
    assert dut.la_data_out_o.value[127 - 1] == 1

    dut.la_oenb_i <= 0b11111

    # test DFE -> ACO
    await FallingEdge(dut.clk_i)
    assert dut.dfe_data_o.value == 0xDE
    assert dut.dfe_valid_o.value == 0
    assert dut.la_data_out_o.value[127 - 9 : 127 - 2: -1] == 0xDE
    assert dut.la_data_out_o.value[127 - 10] == 0

    dut.la_oenb_i <= 0b11011
    dut.dfe_valid_i <= 1

    await FallingEdge(dut.clk_i)
    assert dut.dfe_data_o.value == 0xFF
    assert dut.dfe_valid_o.value == 1
    assert dut.la_data_out_o.value[127 - 9 : 127 - 2: -1] == 0xDE
    assert dut.la_data_out_o.value[127 - 10] == 1

    dut.la_oenb_i <= 0b11111

    # test ACO -> WRD
    await FallingEdge(dut.clk_i)
    assert dut.aco_data_o.value == 0xDEADBEEFDEADBEEFDEADBEEFCC
    assert dut.aco_valid_o.value == 0
    assert dut.aco_last_o.value == 0
    assert dut.la_data_out_o.value[127 - 114 : 127 - 11: -1] == 0xDEADBEEFDEADBEEFDEADBEEFCC
    assert dut.la_data_out_o.value[127 - 115] == 0
    assert dut.la_data_out_o.value[127 - 116] == 0

    dut.la_oenb_i <= 0b10111

    await FallingEdge(dut.clk_i)
    assert dut.aco_data_o.value == 0xFFFFFFFFFFFFFFFFFFFFFFFFFF
    assert dut.aco_valid_o.value == 1
    assert dut.aco_last_o.value == 1
    assert dut.la_data_out_o.value[127 - 114 : 127 - 11: -1] == 0xDEADBEEFDEADBEEFDEADBEEFCC
    assert dut.la_data_out_o.value[127 - 115] == 0
    assert dut.la_data_out_o.value[127 - 116] == 0

    dut.la_oenb_i <= 0b11111

    # test WRD -> Wake
    await FallingEdge(dut.clk_i)
    assert dut.wrd_wake_o.value == 0
    assert dut.wrd_wake_valid_o.value == 0
    assert dut.la_data_out_o.value[127 - 117] == 0
    assert dut.la_data_out_o.value[127 - 118] == 0

    dut.la_oenb_i <= 0b01111

    await FallingEdge(dut.clk_i)
    assert dut.wrd_wake_o.value == 1
    assert dut.wrd_wake_valid_o.value == 1
    assert dut.la_data_out_o.value[127 - 117] == 0
    assert dut.la_data_out_o.value[127 - 118] == 0

    dut.la_oenb_i <= 0b11111
