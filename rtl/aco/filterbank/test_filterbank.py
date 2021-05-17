# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

'''Running this file directly from the command line generates the necessary
MFCC coefficient and boundary hex files.'''

import numpy as np
import speechpy

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, Timer

FRAME_LEN = 129
NUM_COEF  = 32
N_FRAMES  = 10
EVEN_COEF_FNAME     = 'coef_even.hex'
ODD_COEF_FNAME      = 'coef_odd.hex'
EVEN_BOUNDARY_FNAME = 'boundary_even.hex'
ODD_BOUNDARY_FNAME  = 'boundary_odd.hex'

def get_msg(i, received, expected):
    return 'idx {}, dut output of {}, expected {}'.format(i, received, expected)

def get_boundaries(x):
    '''Get boundary indices between non-overlapping triangular windows.'''
    bounds = np.zeros(int(NUM_COEF / 2), dtype=np.uint8)
    bi = 0
    first = True
    wait_nonzero = True
    for i in range(len(x)):
        if wait_nonzero and x[i] == 0:  # skip leading zeros
            continue
        elif wait_nonzero:
            wait_nonzero = False
        if x[i] == 0:  # accumulate indices that are zero
            bounds[bi] = i
            bi += 1
            wait_nonzero = True  # wait for the next nonzero data before
                                 # considering a new boundary index
    return bounds

def get_filterbank():
    '''Generate deterministic filterbank coefficients and boundary indices.'''
    filterbank = speechpy.feature.filterbanks(32, 256, 16000)[:,:FRAME_LEN]
    even_coef = np.zeros(129)
    odd_coef = np.zeros(129)
    for i in range(0, NUM_COEF, 2):
        even_coef += filterbank[i,:]
    for i in range(1, NUM_COEF, 2):
        odd_coef += filterbank[i,:]
    even_boundary = get_boundaries(even_coef)
    odd_boundary = get_boundaries(odd_coef)
    print('even bounds: ', even_boundary)
    print('odd bounds: ', odd_boundary)
    even_coef = even_coef * (2**16 - 1)  # scale up
    odd_coef = odd_coef * (2**16 - 1)
    even_coef = even_coef.astype(np.uint16)
    odd_coef = odd_coef.astype(np.uint16)
    return even_coef, odd_coef, even_boundary, odd_boundary

def write_hex_file(fname, x, fmt):
    with open(fname, 'w') as f:
        for i in range(len(x)):
            f.write(fmt.format(x[i]))

def write_filterbank():
    '''Write filterbank values to file.'''
    ecoef, ocoef, ebound, obound = get_filterbank()
    coef_fmt = '{:04x}\n'
    bound_fmt = '{:02x}\n'
    write_hex_file(EVEN_COEF_FNAME, ecoef, coef_fmt)
    write_hex_file(ODD_COEF_FNAME, ocoef, coef_fmt)
    write_hex_file(EVEN_BOUNDARY_FNAME, ebound, bound_fmt)
    write_hex_file(ODD_BOUNDARY_FNAME, obound, bound_fmt)

def get_expected_output(x):
    '''Calculate the expected output.'''
    filterbank = speechpy.feature.filterbanks(32, 256, 16000)[:,:FRAME_LEN]
    filterbank = (filterbank * (2**16 - 1)).astype(np.uint16)
    even = filterbank[::2,:]
    odd = filterbank[1::2,:]
    y = np.zeros(N_FRAMES * NUM_COEF)
    for i in range(N_FRAMES):
        frame = x[i*FRAME_LEN : (i+1) * FRAME_LEN]
        even_out = np.dot(frame, even.T)
        odd_out = np.dot(frame, odd.T)
        frame_out = np.zeros(NUM_COEF)
        frame_out[::2] = even_out
        frame_out[1::2] = odd_out
        y[i*NUM_COEF : (i+1) * NUM_COEF] = frame_out
    y = y.astype(int)
    y = np.right_shift(y, 16)
    return y

def get_test_vector():
    n = FRAME_LEN * N_FRAMES
    x = np.random.randint(2**25, size=n)
    # x = np.ones(n)
    y = get_expected_output(x)
    return x, y

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
