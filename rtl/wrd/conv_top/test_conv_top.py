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


async def write_conv_mem(dut, weights, biases, shift):
    '''Write weights and biases to the convolution memory.

    weights is size (filter_width, n_channels, n_filters).
    biases is size (n_filters).
    '''
    filter_width, n_channels, n_filters = weights.shape

    await FallingEdge(dut.clk_i)
    dut.rd_en_i <= 0
    dut.wr_en_i <= 1
    # write weights
    for i in range(filter_width):
        for k in range(n_filters):
            dut.rd_wr_bank_i <= filter_width - i - 1  # bank2 is earlier in frame time
            dut.rd_wr_addr_i <= k
            dut.wr_data_i <= np2bv(weights[i,:,k])
            await FallingEdge(dut.clk_i)
    # write biases
    dut.rd_wr_bank_i <= filter_width
    for k in range(n_filters):
        dut.rd_wr_addr_i <= k
        # dut.wr_data_i <= np2bv(biases[k])
        dut.wr_data_i <= int(biases[k])
        await FallingEdge(dut.clk_i)
    # write shift
    dut.rd_wr_bank_i <= filter_width + 1
    dut.wr_data_i <= int(shift)
    await FallingEdge(dut.clk_i)
    # unset signals
    dut.wr_en_i <= 0
    dut.rd_wr_bank_i <= 0
    dut.rd_wr_addr_i <= 0
    dut.wr_data_i <= 0


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


async def read_output_features(dut, n_frames, n_channels, expected):
    '''Receive the output featuremap and put it in a numpy array.'''
    total_values = n_frames * n_channels
    received_values = 0
    output_arr = np.zeros((n_frames, n_channels), dtype=np.int8)

    while (received_values < total_values):
        await FallingEdge(dut.clk_i)
        if dut.valid_o.value == 1:
            frame_num = received_values % n_frames
            channel_num = received_values // n_frames
            value = dut.data_o.value.get_value_signed()
            output_arr[frame_num, channel_num] = value
            expected_value = expected[frame_num, channel_num]
            received_values += 1
            if ENABLE_ASSERTS:
                assert value == expected_value, \
                       (('Output at frame {} and channel {} of value {} does not match '
                           'expected output of {}').format(frame_num, channel_num, value,
                                                           expected_value))
                if dut.last_o == 1:
                    assert frame_num == n_frames - 1, \
                           'last_o asserted at unexpected frame number of {}'.format(frame_num)
                else:
                    assert frame_num != n_frames - 1, \
                           'last_o not asserted at expected frame number of {}'.format(frame_num)

    print('Received output:')
    print(output_arr)
    print('Expected output:')
    print(expected)


def get_random_int8(size):
    return np.random.randint(INT8_MIN, INT8_MAX, size, dtype=np.int8)


def get_random_int32(size):
    return np.random.randint(INT32_MIN, INT32_MAX, size, dtype=np.int32)


def get_random_test_values(n_frames, in_channels, out_channels, zero_biases=False):
    '''zero_biases: set to True to have biases set to 0.'''
    weights = get_random_int8((3, in_channels, out_channels))
    biases = get_random_int32(8)
    if zero_biases:
        biases = biases * 0
    shift = np.random.randint(32)
    input_features = get_random_int8((n_frames, in_channels))

    expected_conv = na.conv1d_multi_kernel(input_features, weights, biases)
    expected_output = na.scale_feature_map(expected_conv, shift)

    return weights, biases, shift, input_features, expected_output


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
