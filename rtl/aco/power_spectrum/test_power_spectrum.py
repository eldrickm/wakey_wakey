# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

import numpy as np

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, Timer
from cocotb.binary import BinaryValue

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


def get_msg(i, received, expected):
    return 'idx {}, dut output of {}, expected {}'.format(i, received, expected)

def get_test_vector():
    n = 200
    x = np.random.randint(-128, 128, size=n).astype(np.complex128)
    x += np.random.randint(-128, 128, size=n) * 1j
    y = x.real ** 2 + x.imag ** 2
    l = np.zeros(n)  # last signal
    l[np.random.randint(10) == 0] = 1  # 1 in 10 inputs assert last
    return x, y, l

async def write_input(dut, x, l):
    i = 0
    while i < len(x):
        dut.data_i <= np2bv(np.array([int(x[i].real), int(x[i].imag)]), n_bits=21)
        valid = np.random.randint(2)  # randomly de-assert valid
        # valid = 1
        dut.valid_i <= (1 if valid else 0)
        dut.last_i <= int(l[i])
        if (valid):
            i += 1
        await FallingEdge(dut.clk_i)

async def check_output(dut, y, l):
    for i in range(len(y)):
        while (dut.valid_o != 1):
            await FallingEdge(dut.clk_i)
        await Timer(1, units='us')
        assert dut.valid_o == 1
        assert dut.last_o == l[i]
        expected_val = y[i]
        received_val = dut.data_o.value.signed_integer
        assert received_val == expected_val, get_msg(i, received_val,
                                                     expected_val)
        await FallingEdge(dut.clk_i)

async def do_test(dut):
    print('Beginning test with random input data.')
    x, y, l = get_test_vector()
    cocotb.fork(write_input(dut, x, l))
    await check_output(dut, y, l)

async def check_output_no_en(dut):
    '''Check that dut doesn't output valid data if en if off.'''
    print('Beginning test with random input data but en_i is low.')
    await FallingEdge(dut.clk_i)
    for i in range(20):
        dut.data_i <= int(np.random.randint(-128, 128))  # feed in garbage data
        dut.valid_i <= 1
        assert dut.valid_o == 0
        await FallingEdge(dut.clk_i)

@cocotb.test()
async def main(dut):
    """ Test Power Spectrum """
    # Create a 10us period clock on port clk
    clock = Clock(dut.clk_i, 10, units="us")
    cocotb.fork(clock.start())

    # Reset system
    await FallingEdge(dut.clk_i)
    dut.rst_n_i <= 0
    dut.en_i <= 0
    dut.data_i <= 0
    dut.valid_i <= 0
    dut.last_i <= 0

    # reset
    await FallingEdge(dut.clk_i)
    dut.rst_n_i <= 1

    # test 1
    dut.en_i <= 1
    await do_test(dut)

    # test 2
    dut.en_i <= 0
    await check_output_no_en(dut)

    # test 3
    dut.en_i <= 1
    await do_test(dut)
