# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

import numpy as np

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, Timer

import sys
sys.path.append('../../../py/')
import pdm

WINDOW_LEN = 250

def get_msg(i, received, expected):
    return 'idx {}, dut output of {}, expected {}'.format(i, received, expected)

def get_test_vector():
    # in PCM indexing; about half way through the 1s recording
    start = 8000 + np.random.randint(-100, 100)
    print('Starting at index {}/{} in sample recording.'.format(start, 16000))
    n = 40  # 40 PCM samples, takes a few seconds to simulate
    x = pdm.read_sample_file(pdm.SAMPLE_FNAME)
    x = pdm.pcm_to_pdm_err(x)
    y = pdm.pdm_to_pcm(x, 2)
    
    # cut to a reasonable length
    start_pdm = start * WINDOW_LEN
    end_pdm = start_pdm + n * WINDOW_LEN
    x = x[start_pdm: end_pdm]
    y = y[start: start + n]

    print('Generated PDM signal', x, 'of length', len(x))
    print('Expecting PCM output signal', y)
    return x, y

async def check_output(dut):
    print('Beginning test with simulated PDM microphone data.')
    x, y = get_test_vector()
    i = 0  # index into x
    j = 0  # index into y
    prev_pdm_clk = dut.pdm_clk_o.value.integer
    while i < len(x):
        print('\rindex {}/{}'.format(i, len(x)), end='')
        dut.pdm_data_i <= int(x[i])
        await Timer(1, units='us')  # let combinational logic work
        if (dut.valid_o.value.integer):
            if (j >= 2):
                expected_val = y[j]
                received_val = dut.data_o.value.signed_integer
                assert received_val == expected_val, get_msg(j, received_val,
                                                             expected_val)
                print(' \tRecived expected value of {} from DUT.'
                        .format(expected_val))
            j += 1

        pdm_clk_val = dut.pdm_clk_o.value.integer
        if ((pdm_clk_val == 1) and (prev_pdm_clk == 0)):  # rising pdm clk edge
            i += 1
        prev_pdm_clk = pdm_clk_val
        await FallingEdge(dut.clk_i)
    print()

async def check_output_no_en(dut):
    '''Check that dut doesn't output valid data if en if off.'''
    print('Beginning test with random input data but en_i is low.')
    await Timer(1, units='us')
    for i in range(1000):
        dut.pdm_data_i <= int(np.random.randint(2))  # feed in garbage data
        assert dut.valid_o == 0
        await FallingEdge(dut.clk_i)

@cocotb.test()
async def main(dut):
    """ Test Rectified Linear Unit """
    # Create a 10us period clock on port clk
    clock = Clock(dut.clk_i, 10, units="us")
    cocotb.fork(clock.start())

    # Reset system
    await FallingEdge(dut.clk_i)
    dut.rst_n_i <= 0
    dut.en_i <= 0
    dut.pdm_data_i <= 0

    # reset
    await FallingEdge(dut.clk_i)
    dut.rst_n_i <= 1

    # test 1
    dut.en_i <= 1
    await check_output(dut)

    # test 2
    dut.en_i <= 0
    await check_output_no_en(dut)

    # test 3
    dut.en_i <= 1
    await check_output(dut)
