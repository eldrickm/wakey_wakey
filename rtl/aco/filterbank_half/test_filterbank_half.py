# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

import numpy as np

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, Timer

FRAME_LEN = 129
NUM_COEF  = 16
N_FRAMES  = 10
COEF_FNAME = 'coef_even.hex'
BOUNDARY_FNAME = 'boundary_even.hex'

def get_msg(i, received, expected):
    return 'idx {}, dut output of {}, expected {}'.format(i, received, expected)

def get_filterbank():
    '''Generate deterministic filterbank coefficients and boundary indices.'''
    filterbank = (np.arange(FRAME_LEN) * 2**8).astype(np.uint16)
    boundaries = np.round(np.linspace(0, FRAME_LEN, NUM_COEF+1)[1:]) - 1
    boundaries = boundaries.astype(np.uint8)
    return filterbank, boundaries

def write_filterbank():
    '''Write filterbank values to file.'''
    filts, bounds = get_filterbank()
    with open(COEF_FNAME, 'w') as f:
        for fi in filts:
            f.write('{:04x}\n'.format(fi))
    with open(BOUNDARY_FNAME, 'w') as f:
        for bi in bounds:
            f.write('{:02x}\n'.format(bi))

def get_expected_output(x):
    '''Calculate the expected output.'''
    f, b = get_filterbank()
    # print('filter coeffs: ', f)
    # print('boundary idxs: ', b)
    y = np.zeros(NUM_COEF * N_FRAMES)
    for frame_idx in range(N_FRAMES):
        run_sum = 0
        b_idx = 0
        for i in range(FRAME_LEN):
            run_sum += x[FRAME_LEN * frame_idx + i] * f[i]
            if i == b[b_idx]:
                y[NUM_COEF * frame_idx + b_idx] = run_sum
                run_sum = 0
                b_idx += 1
    y = y / (2**16)
    return y

def get_test_vector():
    n = FRAME_LEN * N_FRAMES
    x = np.random.randint(2**25, size=n)
    y = get_expected_output(x)
    return x, y.astype(np.uint32)

async def write_input(dut, x):
    for i in range(N_FRAMES):
        for j in range(FRAME_LEN):
            dut.data_i <= int(x[i * FRAME_LEN + j])
            dut.valid_i <= 1
            last = (j == FRAME_LEN - 1)
            dut.last_i <= (1 if last else 0)
            await FallingEdge(dut.clk_i)
        dut.valid_i <= 0
        dut.last_i <= 0
        for j in range(10):
            await FallingEdge(dut.clk_i)

async def check_output(dut, y):
    for j in range(NUM_COEF * N_FRAMES):
        while (dut.valid_o != 1):
            await FallingEdge(dut.clk_i)
        await Timer(1, units='us')  # let last signal propagate
        if j % NUM_COEF == NUM_COEF - 1:
            assert dut.last_o == 1
        else:
            assert dut.last_o == 0
        expected_val = y[j]
        received_val = dut.data_o.value.integer
        assert received_val == expected_val, get_msg(j, received_val,
                                                     expected_val)
        print('output {}: received {} and expected {}.'.format(j, received_val,
                                                               expected_val))
        await FallingEdge(dut.clk_i)
    print('Received data as expected.')

async def check_output_no_en(dut):
    '''Check that dut doesn't output valid data if en if off.'''
    print('Beginning test with random input data but en_i is low.')
    await Timer(1, units='us')
    for i in range(600):
        dut.data_i <= int(np.random.randint(2**16))  # feed in garbage data
        dut.valid_i <= 1
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
    dut.data_i <= 0
    dut.valid_i <= 0

    # reset
    await FallingEdge(dut.clk_i)
    dut.rst_n_i <= 1

    # test 1
    dut.en_i <= 1
    x, y = get_test_vector()
    cocotb.fork(write_input(dut, x))
    await check_output(dut, y)

    # test 2
    dut.en_i <= 0
    await check_output_no_en(dut)

    # test 3
    dut.en_i <= 1
    x, y = get_test_vector()
    cocotb.fork(write_input(dut, x))
    await check_output(dut, y)


if __name__ == '__main__':
    write_filterbank()
