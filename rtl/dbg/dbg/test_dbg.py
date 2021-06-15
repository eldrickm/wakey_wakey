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

pipeline_en_slice = 0
mic_data_slice = 1
dfe_data_slice = [9, 2]
dfe_valid_slice = 10
aco_data_slice = [114, 11]
aco_valid_slice = 115
aco_last_slice = 116
wrd_wake_slice = 117
wrd_wake_valid_slice = 118

la_oenb_disabled = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

def get_slice_mask(slice_lst):
    mask = 0
    for write_slice in slice_lst:
        if type(write_slice) is not list:
            mask |= 1 << write_slice
        else:
            ones = 2 ** (write_slice[0] - write_slice[1] + 1) - 1
            mask |= ones << write_slice[1]
    return mask

def enable_la_write(dut, slice_lst):
    mask = get_slice_mask(slice_lst)
    dut.la_oenb_i <= (mask ^ la_oenb_disabled)

def disable_la_write(dut):
    dut.la_oenb_i <= la_oenb_disabled

def get_la_data_slice(dut, read_slice):
    if type(read_slice) is not list:
        return dut.la_data_out_o.value[127 - read_slice]
    else:
        return dut.la_data_out_o.value[127-read_slice[0]: 127-read_slice[1]: -1]

def check_other_slices_unchanged(dut, slice_lst):
    to_check = ~get_slice_mask(slice_lst)  # parts of signal that should be zero
    for i in range(128):
        if ((1 << i) & to_check):
            assert get_la_data_slice(dut, i) == 0

@cocotb.test()
async def main(dut):
    # Create a 10us period clock on port clk
    clock = Clock(dut.clk_i, 10, units="us")
    cocotb.fork(clock.start())

    # Reset system
    await FallingEdge(dut.clk_i)

    dut.la_data_in_i <= 0
    disable_la_write(dut)

    dut.ctl_pipeline_en_i <= 0

    dut.mic_pdm_data_i <= 0

    dut.dfe_data_i <= 0
    dut.dfe_valid_i <= 0

    dut.aco_data_i <= 0
    dut.aco_valid_i <= 0
    dut.aco_last_i <= 0

    dut.wrd_wake_i <= 0
    dut.wrd_wake_valid_i <= 0

    # reset
    await FallingEdge(dut.clk_i)
    dut.rst_n_i <= 1
    dut.la_data_in_i <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
    
    # test CTL
    await FallingEdge(dut.clk_i)
    assert dut.ctl_pipeline_en_o.value == 0
    assert get_la_data_slice(dut, pipeline_en_slice) == 0

    enable_la_write(dut, [pipeline_en_slice])

    await FallingEdge(dut.clk_i)
    assert dut.ctl_pipeline_en_o.value == 1
    assert get_la_data_slice(dut, pipeline_en_slice) == 0
    check_other_slices_unchanged(dut, [pipeline_en_slice])

    disable_la_write(dut)

    # test MIC -> DFE
    await FallingEdge(dut.clk_i)
    assert dut.mic_pdm_data_o.value == 0
    assert get_la_data_slice(dut, mic_data_slice) == 0

    enable_la_write(dut, [mic_data_slice])

    await FallingEdge(dut.clk_i)
    assert dut.mic_pdm_data_o.value == 1
    assert get_la_data_slice(dut, mic_data_slice) == 0
    check_other_slices_unchanged(dut, [mic_data_slice])

    disable_la_write(dut)

    # test DFE -> ACO
    await FallingEdge(dut.clk_i)
    assert dut.dfe_data_o.value == 0
    assert dut.dfe_valid_o.value == 0
    assert get_la_data_slice(dut, dfe_data_slice) == 0
    assert get_la_data_slice(dut, dfe_valid_slice) == 0

    enable_la_write(dut, [dfe_data_slice, dfe_valid_slice])
    dut.dfe_data_i <= 0xDE

    await FallingEdge(dut.clk_i)
    assert dut.dfe_data_o.value == 0xFF
    assert dut.dfe_valid_o.value == 1
    assert get_la_data_slice(dut, dfe_data_slice) == 0xDE
    assert get_la_data_slice(dut, dfe_valid_slice) == 0
    check_other_slices_unchanged(dut, [dfe_data_slice, dfe_valid_slice])

    disable_la_write(dut)
    dut.dfe_data_i <= 0
    await FallingEdge(dut.clk_i)

    # test ACO -> WRD
    await FallingEdge(dut.clk_i)
    # assert dut.aco_data_o.value == 0xDEADBEEFDEADBEEFDEADBEEFCC
    assert dut.aco_data_o.value == 0
    assert dut.aco_valid_o.value == 0
    assert dut.aco_last_o.value == 0
    # assert get_la_data_slice(dut, aco_data_slice) == 0xDEADBEEFDEADBEEFDEADBEEFCC
    assert get_la_data_slice(dut, aco_data_slice) == 0
    assert get_la_data_slice(dut, aco_valid_slice) == 0
    assert get_la_data_slice(dut, aco_last_slice) == 0

    enable_la_write(dut, [aco_data_slice, aco_valid_slice, aco_last_slice])
    dut.aco_data_i <= 0xDEADBEEFDEADBEEFDEADBEEFCC

    await FallingEdge(dut.clk_i)
    assert dut.aco_data_o.value == 0xFFFFFFFFFFFFFFFFFFFFFFFFFF
    assert dut.aco_valid_o.value == 1
    assert dut.aco_last_o.value == 1
    assert get_la_data_slice(dut, aco_data_slice) == 0xDEADBEEFDEADBEEFDEADBEEFCC
    assert get_la_data_slice(dut, aco_valid_slice) == 0
    assert get_la_data_slice(dut, aco_last_slice) == 0
    check_other_slices_unchanged(dut, [aco_data_slice, aco_valid_slice, aco_last_slice])

    disable_la_write(dut)
    dut.aco_data_i <= 0
    await FallingEdge(dut.clk_i)

    # test WRD -> Wake
    await FallingEdge(dut.clk_i)
    assert dut.wrd_wake_o.value == 0
    assert dut.wrd_wake_valid_o.value == 0
    assert get_la_data_slice(dut, wrd_wake_slice) == 0
    assert get_la_data_slice(dut, wrd_wake_valid_slice) == 0

    enable_la_write(dut, [wrd_wake_slice, wrd_wake_valid_slice])

    await FallingEdge(dut.clk_i)
    assert dut.wrd_wake_o.value == 1
    assert dut.wrd_wake_valid_o.value == 1
    assert get_la_data_slice(dut, wrd_wake_slice) == 0
    assert get_la_data_slice(dut, wrd_wake_valid_slice) == 0
    check_other_slices_unchanged(dut, [wrd_wake_slice, wrd_wake_valid_slice])

    disable_la_write(dut)
