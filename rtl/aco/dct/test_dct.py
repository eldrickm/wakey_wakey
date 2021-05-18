# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

'''Running this file directly from the command line generates the necessary
DCT coefficient hex file.'''

import numpy as np

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, Timer


DCT_LEN = 32
N_COEFS = 13
COEF_FNAME = 'dct.hex'
N_FRAMES = 10

def get_msg(i, received, expected):
    return 'idx {}, dut output of {}, expected {}'.format(i, received, expected)

def gen_dct_coefs():
    '''Type 2 dct with 'ortho' norm.
    See https://docs.scipy.org/doc/scipy/reference/generated/scipy.fft.dct.html.
    '''
    coefs = np.zeros((N_COEFS, DCT_LEN))
    n = np.arange(DCT_LEN)
    for k in range(N_COEFS):
        coefs[k,:] = np.cos(np.pi * k * (2*n + 1) / (2 * DCT_LEN))
        if k == 0:
            coefs[k,:] *= 2 * np.sqrt(1/(4*DCT_LEN))
        else:
            coefs[k,:] *= 2 * np.sqrt(1/(2*DCT_LEN))
    coefs = np.round(coefs * 2**15).astype(np.int16)
    return coefs.T

def write_coef_file():
    coefs = gen_dct_coefs().flatten()  # write 
    print('first 10 coefs: ', coefs[:10])
    with open(COEF_FNAME, 'w') as f:
        f.write('// DCT Coefficient Memory\n//\n')
        f.write('// 32-long input and 13 output coefficients\n//\n')
        f.write('// Values are grouped by output coefficient:\n')
        f.write('//   - First 13 values multiply against x[0]\n')
        f.write('//   - Next 13 values multiply against x[1]\n//\n')
        for i in range(DCT_LEN * N_COEFS):
            f.write('{:04x}\n'.format(0xffff & coefs[i]))

def get_expected_output(x):
    '''Calculate the expected output.'''
    coefs = gen_dct_coefs()
    xl = np.split(x, N_FRAMES)
    y = np.zeros(N_COEFS * N_FRAMES, dtype=np.int64)
    for i in range(N_FRAMES):
        s = np.dot(xl[i], coefs).astype(np.int64)
        s = np.right_shift(s, 15)
        y[i*N_COEFS : (i+1)*N_COEFS] = s
    return y

def get_test_vector():
    n = DCT_LEN * N_FRAMES
    x = np.random.randint(2**8, size=n)
    # x = np.ones(n)
    y = get_expected_output(x)
    return x, y

async def write_input(dut, x):
    for i in range(N_FRAMES):
        for j in range(DCT_LEN):
            for k in range(N_COEFS):  # hold for 13 cycles
                dut.data_i <= int(x[i * DCT_LEN + j])
                dut.valid_i <= 1
                last = (j == DCT_LEN - 1) and (k == N_COEFS - 1)
                dut.last_i <= (1 if last else 0)
                await FallingEdge(dut.clk_i)
        dut.valid_i <= 0
        dut.last_i <= 0
        for j in range(10):
            await FallingEdge(dut.clk_i)

async def check_output(dut, y):
    for j in range(N_COEFS * N_FRAMES):
        while (dut.valid_o != 1):
            await FallingEdge(dut.clk_i)
        await Timer(1, units='us')  # let last signal propagate
        if j % N_COEFS == N_COEFS - 1:
            assert dut.last_o == 1
        else:
            assert dut.last_o == 0
        expected_val = y[j]
        received_val = dut.data_o.value.signed_integer
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
        dut.data_i <= int(np.random.randint(2**8))  # feed in garbage data
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
    write_coef_file()
