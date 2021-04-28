# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

import numpy as np

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge
from cocotb.binary import BinaryValue

import sys
sys.path.append('../../../py/')
import numpy_arch as na

DUT_VECTOR_SIZE = 2

INT8_MIN = np.iinfo(np.int8).min
INT8_MAX = np.iinfo(np.int8).max
INT32_MIN = np.iinfo(np.int32).min
INT32_MAX = np.iinfo(np.int32).max

ENABLE_ASSERTS = False

def np2bv(int_arr):
    """ Convert a 8b integer numpy array in cocotb BinaryValue """
    int_list = int_arr.tolist()
    binarized = [format(x & 0xFF, '08b') if x < 0 else format(x, '08b')
                 for x in int_list]
    bin_string = ''.join(binarized)
    return BinaryValue(bin_string)


async def write_conv_mem(dut, conv_num, weights, biases, shift):
    '''Write weights and biases to the convolution memory.

    conv_num is which convolution block to write to, either 1 or 2
    weights is size (filter_width, n_channels, n_filters).
    biases is size (n_filters).
    '''
    filter_width, n_channels, n_filters = weights.shape
    if conv_num == 1:  # conv1
        rd_en_i = dut.conv1_rd_en_i
        wr_en_i = dut.conv1_wr_en_i
        rd_wr_bank_i = dut.conv1_rd_wr_bank_i
        rd_wr_addr_i = dut.conv1_rd_wr_addr_i
        wr_data_i = dut.conv1_wr_data_i
        rd_data_o = dut.conv1_rd_data_o
    else:  # conv2
        rd_en_i = dut.conv2_rd_en_i
        wr_en_i = dut.conv2_wr_en_i
        rd_wr_bank_i = dut.conv2_rd_wr_bank_i
        rd_wr_addr_i = dut.conv2_rd_wr_addr_i
        wr_data_i = dut.conv2_wr_data_i
        rd_data_o = dut.conv2_rd_data_o

    await FallingEdge(dut.clk_i)
    rd_en_i <= 0
    wr_en_i <= 1
    # write weights
    for i in range(filter_width):
        for k in range(n_filters):
            rd_wr_bank_i <= filter_width - i - 1  # bank2 is earlier in frame time
            rd_wr_addr_i <= k
            wr_data_i <= np2bv(weights[i,:,k])
            await FallingEdge(dut.clk_i)
    # write biases
    rd_wr_bank_i <= filter_width
    for k in range(n_filters):
        rd_wr_addr_i <= k
        wr_data_i <= int(biases[k])
        await FallingEdge(dut.clk_i)
    # write shift
    rd_wr_bank_i <= filter_width + 1
    wr_data_i <= int(shift)
    await FallingEdge(dut.clk_i)
    # unset signals
    wr_en_i <= 0
    rd_wr_bank_i <= 0
    rd_wr_addr_i <= 0
    wr_data_i <= 0


async def write_fc_mem(dut, w, b):
    in_length, n_classes = w.shape

    rd_en = dut.fc_rd_en_i
    wr_en = dut.fc_wr_en_i
    bank = dut.fc_rd_wr_bank_i
    addr = dut.fc_rd_wr_addr_i
    data = dut.fc_wr_data_i

    await FallingEdge(dut.clk_i)
    rd_en <= 0
    wr_en <= 1
    # write weights
    for i in range(in_length):
        for j in range(n_classes):
            bank <= j
            addr <= i
            data <= int(w[i, j])
            await FallingEdge(dut.clk_i)
    # write biases
    for j in range(n_classes):
        bank <= j + n_classes
        addr <= 0
        data <= int(b[j])
        await FallingEdge(dut.clk_i)
    # unset signals
    wr_en <= 0
    bank <= 0
    addr <= 0
    data <= 0


async def write_input_features(dut, x):
    '''Asynchronously send a full set of MFCC features to the dut.

    x is an array of size (n_frames, n_channels), and needs zero padding.
    '''
    n_frames = x.shape[0]

    await FallingEdge(dut.clk_i)
    dut.valid_i <= 1
    for i in range(n_frames):
        dut.data_i <= np2bv(x[i,:])
        if i == n_frames - 1:
            dut.last_i <= 1
        await FallingEdge(dut.clk_i)
    # unset signals
    dut.valid_i <= 0
    dut.last_i <= 0
    dut.data_i <= 0

async def read_conv_output(dut, conv_num, n_frames, n_channels, expected):
    '''Receive the output featuremap and put it in a numpy array.'''
    total_values = n_frames * n_channels
    received_values = 0
    output_arr = np.zeros((n_frames, n_channels), dtype=np.int8)

    if conv_num == 1:
        data = dut.conv1_data
        valid = dut.conv1_valid
        last = dut.conv1_last
    else:
        data = dut.conv2_data
        valid = dut.conv2_valid
        last = dut.conv2_last

    while (received_values < total_values):
        await FallingEdge(dut.clk_i)
        if valid.value == 1:
            frame_num = received_values % n_frames
            channel_num = received_values // n_frames
            value = data.value.get_value_signed()
            output_arr[frame_num, channel_num] = value
            expected_value = expected[frame_num, channel_num]
            received_values += 1
            if ENABLE_ASSERTS:
                assert value == expected_value, \
                       (('Output at frame {} and channel {} of value {} does not match '
                           'expected output of {}').format(frame_num, channel_num, value,
                                                           expected_value))
                if last == 1:
                    assert frame_num == n_frames - 1, \
                           'last_o asserted at unexpected frame number of {}'.format(frame_num)
                else:
                    assert frame_num != n_frames - 1, \
                           'last_o not asserted at expected frame number of {}'.format(frame_num)

    print('Received output:')
    print(output_arr)
    print('Expected output:')
    print(expected)

async def read_fc_output(dut, expected):
    '''Receive the output featuremap and put it in a numpy array.'''
    await FallingEdge(dut.clk_i)
    while (dut.fc_valid != 1):  # wait until valid output
        await FallingEdge(dut.clk_i)
    binstr = dut.fc_data.value.get_binstr()
    split_binstr = [binstr[32:], binstr[:32]]
    output_arr = [BinaryValue(x).signed_integer for x in split_binstr]

    if ENABLE_ASSERTS:
        for i in range(2):
            value = output_arr[i]
            expected_value = expected[i]
            assert value == expected_value, \
                   (('FC output at index {} of value {} does not match '
                       'expected output of {}').format(i, value,
                                                       expected_value))
        assert dut.fc_last == 1, 'fc_last not asserted when expected'

    print('Received output:')
    print(output_arr)
    print('Expected output:')
    print(expected)


def get_random_int8(size):
    return np.random.randint(INT8_MIN, INT8_MAX, size, dtype=np.int8)

def get_random_int32(size):
    return np.random.randint(INT32_MIN, INT32_MAX, size, dtype=np.int32)

def get_random_conv_values(in_channels, out_channels):
    weights = get_random_int8((3, in_channels, out_channels))
    biases = get_random_int32(out_channels)
    shift = np.random.randint(32)
    return weights, biases, shift

def get_fixed_conv_values(in_channels, out_channels):
    weights = np.zeros((3, in_channels, out_channels), dtype=np.int8)
    weights[0, 0, :] = np.ones(out_channels, dtype=np.int8)
    biases = np.zeros(out_channels, dtype=np.int32)
    shift = 0
    return weights, biases, shift

def get_fixed_conv_values2(in_channels, out_channels):
    weights = np.ones((3, in_channels, out_channels), dtype=np.int8)
    # weights[0, 0, :] = np.ones(out_channels, dtype=np.int8)
    biases = np.zeros(out_channels, dtype=np.int32)
    shift = 0
    return weights, biases, shift

def get_random_fc_values(in_length, n_classes):
    weights = get_random_int8((in_length, n_classes))
    # biases = get_random_int32(n_classes)
    biases = np.zeros(n_classes)
    return weights, biases

def get_fixed_fc_values(in_length, n_classes):
    weights = np.ones((in_length, n_classes), dtype=np.int8)
    # seq = np.arange(in_length, dtype=np.int8).reshape(in_length, 1) - 10
    # weights = np.hstack((seq, seq))
    biases = np.zeros(n_classes, dtype=np.int32)
    return weights, biases

def get_random_input():
    input_features = get_random_int8((50, 13))
    return input_features

def get_fixed_input():
    input_features = np.ones((50, 13), dtype=np.int8)
    return input_features

async def write_all_mem_random(dut):
    '''Write random test values to all memories'''
    c1w, c1b, c1s = get_random_conv_values(13, 8)
    c2w, c2b, c2s = get_random_conv_values(8, 16)
    fcw, fcb      = get_random_fc_values(208, 2)
    await write_conv_mem(dut, 1, c1w, c1b, c1s)
    await write_conv_mem(dut, 2, c2w, c2b, c2s)
    await write_fc_mem(dut, fcw, fcb)
    return [c1w, c1b, c1s, c2w, c2b, c2s, fcw, fcb]

async def write_all_mem_fixed(dut):
    '''Write random test values to all memories'''
    c1w, c1b, c1s = get_fixed_conv_values(13, 8)
    c2w, c2b, c2s = get_fixed_conv_values2(8, 16)
    # c2w, c2b, c2s = get_random_conv_values(8, 16)
    fcw, fcb      = get_fixed_fc_values(208, 2)
    # fcw, fcb      = get_random_fc_values(208, 2)
    await write_conv_mem(dut, 1, c1w, c1b, c1s)
    await write_conv_mem(dut, 2, c2w, c2b, c2s)
    await write_fc_mem(dut, fcw, fcb)
    return [c1w, c1b, c1s, c2w, c2b, c2s, fcw, fcb]


async def do_random_test(dut):
    params = await write_all_mem_random(dut)
    input_features = get_random_input()
    fc_exp, c1_exp, c2_exp = na.get_numpy_pred_custom_params(input_features, params)

    await write_input_features(dut, input_features)
    # await read_conv_output(dut, 1, 50, 8, c1_exp)
    # await read_conv_output(dut, 2, 25, 16, c2_exp)
    await read_fc_output(dut, fc_exp)

async def do_fixed_test(dut):
    params = await write_all_mem_fixed(dut)
    input_features = get_fixed_input()
    fc_exp, c1_exp, c2_exp = na.get_numpy_pred_custom_params(input_features, params)

    await write_input_features(dut, input_features)
    # await read_conv_output(dut, 1, 50, 8, c1_exp)
    await read_conv_output(dut, 2, 25, 16, c2_exp)
    # await read_fc_output(dut, fc_exp)


@cocotb.test()
async def test_conv1d(dut):
    """ Test Conv1D Module """
    # Create a 10us period clock on port clk
    clock = Clock(dut.clk_i, 10, units="us")
    cocotb.fork(clock.start())

    # Reset DUT
    await FallingEdge(dut.clk_i)
    dut.rst_n_i <= 0
    dut.data_i <= 0
    dut.valid_i <= 0
    dut.last_i <= 0

    dut.conv1_rd_en_i <= 0
    dut.conv1_wr_en_i <= 0
    dut.conv1_rd_wr_bank_i <= 0
    dut.conv1_rd_wr_addr_i <= 0
    dut.conv1_wr_data_i <= 0

    dut.conv2_rd_en_i <= 0
    dut.conv2_wr_en_i <= 0
    dut.conv2_rd_wr_bank_i <= 0
    dut.conv2_rd_wr_addr_i <= 0
    dut.conv2_wr_data_i <= 0

    dut.fc_rd_en_i <= 0
    dut.fc_wr_en_i <= 0
    dut.fc_rd_wr_bank_i <= 0
    dut.fc_rd_wr_addr_i <= 0
    dut.fc_wr_data_i <= 0

    for _ in range(50):
        await FallingEdge(dut.clk_i)
    dut.rst_n_i <= 1
    await FallingEdge(dut.clk_i)

    print('=' * 100)
    print('Beginning test with fixed weights, biases, and features.')
    print('=' * 100)

    await do_fixed_test(dut)

    # print('=' * 100)
    # print('Beginning test with random weights, biases, and features.')
    # print('=' * 100)
# 
    # await do_random_test(dut)
