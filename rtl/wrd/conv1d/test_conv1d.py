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


def np2bv(int_arr):
    """ Convert a 8b integer numpy array in cocotb BinaryValue """
    int_list = int_arr.tolist()
    binarized = [format(x & 0xFF, '08b') if x < 0 else format(x, '08b')
                 for x in int_list]
    bin_string = ''.join(binarized)
    return BinaryValue(bin_string)


async def write_conv_mem(dut, weights, biases):
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
    # unset signals
    dut.wr_en_i <= 0
    dut.rd_wr_bank_i <= 0
    dut.rd_wr_addr_i <= 0
    dut.wr_data_i <= 0


async def send_data(dut, x):
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


async def receive_data(dut, n_frames, n_channels, expected):
    '''Receive the output featuremap and put it in a numpy array.'''
    total_values = n_frames * n_channels
    received_values = 0
    output_arr = np.zeros((n_frames, n_channels), dtype=np.int8)

    while (received_values < total_values):
        await FallingEdge(dut.clk_i)
        if dut.valid_o.value == 1:
            frame_num = received_values % n_frames
            channel_num = received_values // n_frames
            value = dut.data_o.value
            output_arr[frame_num, channel_num] = value
            expected_value = expected[frame_num, channel_num]
            if value != expected_value:
                print(('Output at frame {} and channel {} of value {} does not match'
                       'expected output of {}').format(frame_num, channel_num, value,
                                                     expected_value))
            received_values += 1
            # if dut.last_o == 1:
                # assert(received_values == total_values)
    # return output_arr
    print('Received output:')
    print(output_arr)
    print('Expected output:')
    print(expected)
    
        #  assert observed == expected, "observed = %d, expected = %d," %\
        #                               (observed, expected)

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

    weights = np.ones((3, 13, 8), dtype=np.int8) * 127
    biases = np.ones(8, dtype=np.int32)
    input_features = np.ones((50, 13), dtype=np.int8)
    expected_output = na.conv1d_multi_kernel(input_features, weights, biases)
    # expected_output = na.scale_feature_map(expected_output, na.bitshifts[0])
    expected_output = na.scale_feature_map(expected_output, 8)

    await write_conv_mem(dut, weights, biases)
    await FallingEdge(dut.clk_i)
    await send_data(dut, input_features)
    await FallingEdge(dut.clk_i)
    await receive_data(dut, 50, 8, expected_output)

        #  assert observed == expected, "observed = %d, expected = %d," %\
        #                               (observed, expected)
