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

ENABLE_ASSERTS = True

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


async def write_fc_mem(w, b):
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
            data <= w[i, j]
            await FallingEdge(dut.clk_i)
    # write biases
    for j in range(n_classes):
        bank <= j + n_classes
        addr <= 0
        data <= b[j]
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
    n_frames_pad = x.shape[0] + 2
    x_pad = np.zeros((n_frames_pad, x.shape[1]), dtype=np.int8)
    x_pad[1:-1,:] = x

    await FallingEdge(dut.clk_i)
    dut.valid_i <= 1
    for i in range(n_frames_pad):
        dut.data_i <= np2bv(x_pad[i,:])
        if i == n_frames_pad - 1:
            dut.last_i <= 1
        await FallingEdge(dut.clk_i)
    # unset signals
    dut.valid_i <= 0
    dut.last_i <= 0
    dut.data_i <= 0


async def read_fc_output(dut, expected):
    '''Receive the output featuremap and put it in a numpy array.'''
    await FallingEdge(dut.clk_i)
    while (dut.fc_valid != 1):  # wait until valid output
        await FallingEdge(dut.clk_i)
    binstr = dut.data_o.value.get_binstr()
    split_binstr = [value[:32], value[32:]]
    output_arr = [BinaryValue(x).signed_integer() for x in split_binstr]
    if ENABLE_ASSERTS:
        for i in range(len(expected)):
            assert output_arr[i] == expected[i], \  #TODO
                   (('Output at frame {} and channel {} of value {} does not match '
                       'expected output of {}').format(frame_num, channel_num, value,
                                                       expected_value))
        # if dut.last_o == 1:
            # assert frame_num == n_frames - 1, \
                   # 'last_o asserted at unexpected frame number of {}'.format(frame_num)
        # else:
            # assert frame_num != n_frames - 1, \
                   # 'last_o not asserted at expected frame number of {}'.format(frame_num)

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

def get_random_fc_values(in_length, n_classes):
    weights = get_random_int8((in_length, n_classes))
    biases = get_random_int32(n_classes)
    return weights, biases

def get_random_input():
    input_features = get_random_int8((50, 13))
    return input_features

async def write_all_mem_random(dut):
    '''Write random test values to all memories'''
    c1w, c1b, c1s = get_random_conv_values(13, 8)
    c2w, c2b, c2s = get_random_conv_values(8, 16)
    fcw, fcb      = get_random_fc_values(208, 2)
    await write_conv_mem(dut, 1, c1w, c1b, c1s)
    await write_conv_mem(dut, 2, c2w, c2b, c2s)
    await write_fc_mem(dut, fcw, fcb)


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
    dut.ready_i <= 0

    dut.wr_en_i <= 0
    dut.rd_en_i <= 0
    dut.rd_wr_bank_i <= 0
    dut.rd_wr_addr_i <= 0
    dut.wr_data_i <= 0

    await FallingEdge(dut.clk_i)
    dut.rst_n_i <= 1
    dut.ready_i <= 1
    for _ in range(20):
        await FallingEdge(dut.clk_i)

    print('=' * 100)
    print('Beginning basic test with fixed weights, biases, and features.')
    print('=' * 100)

    # w is weights, b is biases, s is shift, i is input features, o is expected

    w = np.ones((3, 13, 8), dtype=np.int8) * 127
    b = np.ones(8, dtype=np.int32)
    s = 8
    i = np.ones((50, 13), dtype=np.int8)
    o = na.conv1d_multi_kernel(i, w, b)
    o = na.scale_feature_map(o, s)

    await write_conv_mem(dut, w, b, s)
    await write_input_features(dut, i)
    await read_output_features(dut, 50, 8, o)

    print('=' * 100)
    print('Beginning second basic test with fixed weights, biases, and features.')
    print('=' * 100)

    w = np.ones((3, 13, 8), dtype=np.int8) * 100
    b = np.ones(8, dtype=np.int32)
    s = 8
    i = np.ones((50, 13), dtype=np.int8) * 2
    o = na.conv1d_multi_kernel(i, w, b)
    o = na.scale_feature_map(o, s)

    await write_conv_mem(dut, w, b, s)
    await write_input_features(dut, i)
    await read_output_features(dut, 50, 8, o)

    print('=' * 100)
    print('Beginning third test with fixed weights and features, but varied biases.')
    print('=' * 100)

    w = np.ones((3, 13, 8), dtype=np.int8) * 50
    b = np.arange(8, dtype=np.int32) * 2000 + 5
    s = 8
    i = np.ones((50, 13), dtype=np.int8)
    o = na.conv1d_multi_kernel(i, w, b)
    o = na.scale_feature_map(o, s)

    await write_conv_mem(dut, w, b, s)
    await write_input_features(dut, i)
    await read_output_features(dut, 50, 8, o)

    print('=' * 100)
    print('Beginning test with random weights and features.')
    print('=' * 100)

    w, b, s, i, o = get_random_test_values(50, 13, 8, zero_biases=True)

    await write_conv_mem(dut, w, b, s)
    await write_input_features(dut, i)
    await read_output_features(dut, 50, 8, o)

    print('=' * 100)
    print('Beginning saturation test with random weights, biases, and features.')
    print('=' * 100)

    w, b, s, i, o = get_random_test_values(50, 13, 8)

    await write_conv_mem(dut, w, b, s)
    await write_input_features(dut, i)
    await read_output_features(dut, 50, 8, o)

    # Now test with real weights, biases and MFCC features

    total_samples = na.get_num_train_samples()

    for test_num in range(10):
        print('=' * 100)
        print('Beginning conv1 test {}/{} with real weights, biases and features.'.format(test_num, 10))
        print('=' * 100)

        w = na.conv1_weights
        b = na.conv1_biases
        s = na.bitshifts[0]
        i = na.get_featuremap(np.random.randint(total_samples))
        o = na.conv1d_multi_kernel(i, w, b)
        o = na.scale_feature_map(o, s)

        await write_conv_mem(dut, w, b, s)
        await write_input_features(dut, i)
        await read_output_features(dut, 50, 8, o)
