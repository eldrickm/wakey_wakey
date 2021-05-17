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

#  async def store_conv1_weight(dut, bank, values):
#      assert bank >= 0 and bank <= 3
#      assert values.shape == (8, 13)
#      bank_offset = 0x10 * bank
#      for i in range(8):
#          await store(dut, i + bank_offset, values[i][, i + 2, i + 1, i)
#
#  async def store_conv1_bias(dut, values):
#  async def store_conv1_shift(dut, values):


async def store(dut, addr, data_3, data_2, data_1, data_0):
    '''Store to Wakey Wakey Memory

    addr is a 32b address in the Wakey Wakey address space
    data_3 MSB
    data_2
    data_1
    data_0 LSB
    '''
    await wishbone_write(dut, 0x30000000, addr)
    await wishbone_write(dut, 0x30000008, data_0)
    await wishbone_write(dut, 0x3000000C, data_1)
    await wishbone_write(dut, 0x30000010, data_2)
    await wishbone_write(dut, 0x30000014, data_3)
    await wishbone_write(dut, 0x30000004, 0x1)


async def load(dut, addr):
    '''Load from Wakey Wakey Memory

    addr is a 32b address in the Wakey Wakey address space
    returns a list of values in the following order:
    [data_0, data_1, data_2, data_3]
    '''
    await wishbone_write(dut, 0x30000000, addr)
    await wishbone_write(dut, 0x30000004, 0x2)
    # TODO: Need to wait one clock cycle before read starts?
    await FallingEdge(dut.clk_i)
    data_0 = await wishbone_read(dut, 0x30000008)
    data_1 = await wishbone_read(dut, 0x3000000C)
    data_2 = await wishbone_read(dut, 0x30000010)
    data_3 = await wishbone_read(dut, 0x30000014)
    return [data_3, data_2, data_1, data_0]


async def wishbone_write(dut, addr, data):
    '''A single wishbone write transaction

    addr is the 32b wishbone address
    data is a 32b value
    '''
    wbs_stb_i = dut.wbs_stb_i
    wbs_cyc_i = dut.wbs_cyc_i
    wbs_we_i  = dut.wbs_we_i
    wbs_sel_i = dut.wbs_sel_i
    wbs_dat_i = dut.wbs_dat_i
    wbs_adr_i = dut.wbs_adr_i
    wbs_ack_o = dut.wbs_ack_o

    await FallingEdge(dut.clk_i)
    wbs_stb_i <= 1
    wbs_cyc_i <= 1
    wbs_we_i  <= 1
    wbs_sel_i <= 0xF
    wbs_dat_i <= data
    wbs_adr_i <= addr
    await FallingEdge(dut.clk_i)
    # unset signals
    wbs_stb_i <= 0
    wbs_cyc_i <= 0
    wbs_we_i  <= 0
    wbs_sel_i <= 0x0
    wbs_dat_i <= data
    wbs_adr_i <= addr

    while not wbs_ack_o.value:
        await FallingEdge(dut.clk_i)


async def wishbone_read(dut, addr):
    '''A single wishbone read transaction

    addr is the 32b wishbone address
    '''
    wbs_stb_i = dut.wbs_stb_i
    wbs_cyc_i = dut.wbs_cyc_i
    wbs_we_i  = dut.wbs_we_i
    wbs_sel_i = dut.wbs_sel_i
    wbs_dat_i = dut.wbs_dat_i
    wbs_adr_i = dut.wbs_adr_i
    wbs_dat_o = dut.wbs_dat_o
    wbs_ack_o = dut.wbs_ack_o

    await FallingEdge(dut.clk_i)
    wbs_stb_i <= 1
    wbs_cyc_i <= 1
    wbs_we_i  <= 0
    wbs_sel_i <= 0xF
    wbs_dat_i <= 0
    wbs_adr_i <= addr
    await FallingEdge(dut.clk_i)
    # unset signals
    wbs_stb_i <= 0
    wbs_cyc_i <= 0
    wbs_we_i  <= 0
    wbs_sel_i <= 0x0
    wbs_dat_i <= 0
    wbs_adr_i <= addr

    while not wbs_ack_o.value:
        await FallingEdge(dut.clk_i)

    return wbs_dat_o.value


# ==================== Writing to dut ====================

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

    # need to reorder weights
    w = w.reshape(13, 16, 2).transpose((1,0,2)).reshape(208, 2)

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


# ==================== Reading from dut ====================

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

    # track mismatches
    mismatches = []

    while (received_values < total_values):
        await FallingEdge(dut.clk_i)
        if valid.value == 1:
            frame_num = received_values % n_frames
            channel_num = received_values // n_frames
            value = data.value.get_value_signed()
            output_arr[frame_num, channel_num] = value
            expected_value = expected[frame_num, channel_num]
            received_values += 1
            if value != expected_value:
                mismatches.append([frame_num, channel_num, value, expected_value])
            if ENABLE_ASSERTS:
                if last == 1:
                    assert frame_num == n_frames - 1, \
                           'last_o asserted at unexpected frame number of {}'.format(frame_num)
                else:
                    assert frame_num != n_frames - 1, \
                           'last_o not asserted at expected frame number of {}'.format(frame_num)
    if len(mismatches) > 0:
        print('Conv {} output has {} mismatches! They are:'.format(conv_num,
                                                            len(mismatches)))
        for m in mismatches:
            print('Frame {}, channel {}, received value {}, expected value {}'.format(
                                m[0], m[1], m[2], m[3]))
    print('Conv {} received output:'.format(conv_num))
    print(output_arr)
    print('Expected output:')
    print(expected)
    if ENABLE_ASSERTS:
        assert len(mismatches) == 0, 'Output mismatch for conv'

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

async def read_wake(dut, wake_expected):
    '''Check the wake signal is as expected.'''
    for _ in range(10):
        await FallingEdge(dut.clk_i)
    wake = dut.wake_o.value
    if wake_expected:
        assert wake == 1, 'Wake not asserted as expected.'
    else:
        assert wake == 0, 'Wake asserted unexpectedly.'
    print('Wake behavior as expected.')


# ==================== Generating inputs ====================

def get_random_int8(size):
    return np.random.randint(INT8_MIN, INT8_MAX, size, dtype=np.int8)

def get_random_int32(size):
    return np.random.randint(INT32_MIN, INT32_MAX, size, dtype=np.int32)

def get_random_conv_values(in_channels, out_channels, zero_biases=False):
    weights = get_random_int8((3, in_channels, out_channels))
    if zero_biases:
        biases = np.zeros(out_channels, dtype=np.int32)
        shift = 0
    else:
        biases = get_random_int32(out_channels)
        shift = np.random.randint(32)
    return weights, biases, shift

def get_random_conv_values2(in_channels, out_channels):
    weights = get_random_int8((3, in_channels, out_channels))
    biases = np.zeros(out_channels, dtype=np.int32)
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
    biases = np.zeros(out_channels, dtype=np.int32)
    shift = 0
    return weights, biases, shift

def get_fixed_conv_values3(in_channels, out_channels):
    weights = np.arange(3*in_channels*out_channels, dtype=np.int8) - 63
    weights = weights.reshape(3, in_channels, out_channels)
    biases = np.zeros(out_channels, dtype=np.int32)
    shift = 0
    return weights, biases, shift

def get_random_fc_values(in_length, n_classes, zero_biases=False):
    weights = get_random_int8((in_length, n_classes))
    if zero_biases:
        biases = np.zeros(n_classes, dtype=np.int32)
    else:
        biases = get_random_int32(n_classes)
    return weights, biases

def get_random_fc_values2(in_length, n_classes):
    weights = get_random_int8((in_length, n_classes))
    biases = np.zeros(n_classes)
    return weights, biases

def get_fixed_fc_values(in_length, n_classes):
    weights = np.ones((in_length, n_classes), dtype=np.int8)
    biases = np.zeros(n_classes, dtype=np.int32)
    return weights, biases

def get_fixed_fc_values2(in_length, n_classes):
    seq = np.arange(in_length, dtype=np.int8).reshape(in_length, 1) - 10
    weights = np.hstack((seq, seq))
    biases = np.zeros(n_classes, dtype=np.int32)
    return weights, biases

def get_random_input():
    input_features = get_random_int8((50, 13))
    return input_features

def get_fixed_input():
    input_features = np.ones((50, 13), dtype=np.int8)
    return input_features

def get_fixed_input2():
    input_features = np.arange(-128, 50*13 - 128, dtype=np.int8).reshape((50, 13))
    return input_features

# ==================== Writing generated inputs ====================

async def write_mem_params(dut, p):
    c1w, c1b, c1s, c2w, c2b, c2s, fcw, fcb = p
    await write_conv_mem(dut, 1, c1w, c1b, c1s)
    await write_conv_mem(dut, 2, c2w, c2b, c2s)
    await write_fc_mem(dut, fcw, fcb)

async def write_all_mem_random(dut, permutation=1):
    '''Write random test values to all memories'''
    if permutation == 1:
        c1w, c1b, c1s = get_random_conv_values(13, 8)
        c2w, c2b, c2s = get_random_conv_values(8, 16)
        fcw, fcb      = get_random_fc_values(208, 2)
    elif permutation == 2:
        c1w, c1b, c1s = get_fixed_conv_values(13, 8)
        c2w, c2b, c2s = get_fixed_conv_values(8, 16)
        fcw, fcb      = get_random_fc_values2(208, 2)
    else:
        c1w, c1b, c1s = get_random_conv_values(13, 8, zero_biases=True)
        c2w, c2b, c2s = get_random_conv_values(8, 16, zero_biases=True)
        fcw, fcb      = get_random_fc_values(208, 2, zero_biases=True)

    p = [c1w, c1b, c1s, c2w, c2b, c2s, fcw, fcb]
    await write_mem_params(dut, p)
    return p

async def write_all_mem_fixed(dut, permutation=1):
    '''Write random test values to all memories'''
    if permutation == 1:
        c1w, c1b, c1s = get_fixed_conv_values(13, 8)
        c2w, c2b, c2s = get_fixed_conv_values(8, 16)
        fcw, fcb      = get_fixed_fc_values(208, 2)
    elif permutation == 2:
        c1w, c1b, c1s = get_fixed_conv_values(13, 8)
        c2w, c2b, c2s = get_fixed_conv_values2(8, 16)
        fcw, fcb      = get_fixed_fc_values(208, 2)
    elif permutation == 3:
        c1w, c1b, c1s = get_fixed_conv_values(13, 8)
        c2w, c2b, c2s = get_fixed_conv_values(8, 16)
        fcw, fcb      = get_fixed_fc_values2(208, 2)
    else:
        c1w, c1b, c1s = get_fixed_conv_values3(13, 8)
        c2w, c2b, c2s = get_fixed_conv_values(8, 16)
        fcw, fcb      = get_fixed_fc_values2(208, 2)

    p = [c1w, c1b, c1s, c2w, c2b, c2s, fcw, fcb]
    await write_mem_params(dut, p)
    return p

# ==================== Individual tests ====================

async def do_random_test(dut, permutation=1):
    params = await write_all_mem_random(dut, permutation=permutation)
    input_features = get_random_input()
    fc_exp, c1_exp, c2_exp = na.get_numpy_pred_custom_params(input_features, params)

    await write_input_features(dut, input_features)
    cocotb.fork(read_conv_output(dut, 1, 50, 8, c1_exp))
    cocotb.fork(read_conv_output(dut, 2, 25, 16, c2_exp))
    await read_fc_output(dut, fc_exp)

async def do_fixed_test(dut, permutation=1):
    params = await write_all_mem_fixed(dut, permutation=permutation)
    if permutation == 4:
        input_features = get_fixed_input2()
    else:
        input_features = get_fixed_input()
    fc_exp, c1_exp, c2_exp = na.get_numpy_pred_custom_params(input_features, params)

    await write_input_features(dut, input_features)
    cocotb.fork(read_conv_output(dut, 1, 50, 8, c1_exp))
    cocotb.fork(read_conv_output(dut, 2, 25, 16, c2_exp))
    await read_fc_output(dut, fc_exp)

async def do_mfcc_test(dut):
    input_features, index = na.get_random_featuremap()
    fc_exp, c1_exp, c2_exp = na.get_numpy_pred_custom_params(input_features, \
                                                             na.get_params())
    wake = (fc_exp[0] > fc_exp[1])

    await write_input_features(dut, input_features)
    cocotb.fork(read_conv_output(dut, 1, 50, 8, c1_exp))
    cocotb.fork(read_conv_output(dut, 2, 25, 16, c2_exp))
    await read_fc_output(dut, fc_exp)
    await read_wake(dut, wake)


@cocotb.test()
async def test_cfg(dut):
    # Create a 10us period clock on port clk
    clock = Clock(dut.clk_i, 10, units="us")
    cocotb.fork(clock.start())

    # Reset DUT
    await FallingEdge(dut.clk_i)
    dut.rst_n_i <= 0
    dut.wbs_stb_i <= 0
    dut.wbs_cyc_i <= 0
    dut.wbs_we_i <= 0
    dut.wbs_sel_i <= 0
    dut.wbs_dat_i <= 0
    dut.wbs_adr_i <= 0

    await FallingEdge(dut.clk_i)
    dut.rst_n_i <= 1

    # Store Test
    # Sequential Store - Conv 1 Memory Bank 0 (Weight - 104b)
    for i in range(8):
        await store(dut, i, i + 3, i + 2, i + 1, i)
    # Sequential Store - Conv 1 Memory Bank 1 (Weight - 104b)
    for i in range(8):
        await store(dut, i + 0x10, i + 3, i + 2, i + 1, i)
    # Sequential Store - Conv 1 Memory Bank 2 (Weight - 104b)
    for i in range(8):
        await store(dut, i + 0x20, i + 3, i + 2, i + 1, i)
    # Sequential Store - Conv 1 Memory Bank 3 (Bias - 32b)
    for i in range(8):
        await store(dut, i + 0x30, i + 3, i + 2, i + 1, i)
    # Sequential Store - Conv 1 Memory Bank 4 (Shift - 5b)
    await store(dut, 0x40, i + 3, i + 2, i + 1, i)

    # Sequential Store - Conv 2 Memory Bank 0 (Weight - 64b)
    for i in range(16):
        await store(dut, i + 0x50, i + 3, i + 2, i + 1, i)
    # Sequential Store - Conv 2 Memory Bank 1 (Weight - 64b)
    for i in range(16):
        await store(dut, i + 0x60, i + 3, i + 2, i + 1, i)
    # Sequential Store - Conv 2 Memory Bank 2 (Weight - 64b)
    for i in range(16):
        await store(dut, i + 0x70, i + 3, i + 2, i + 1, i)
    # Sequential Store - Conv 2 Memory Bank 3 (Bias - 32b)
    for i in range(16):
        await store(dut, i + 0x80, i + 3, i + 2, i + 1, i)
    # Sequential Store - Conv 2 Memory Bank 4 (Shift - 5b)
    await store(dut, 0x90, i + 3, i + 2, i + 1, i)

    # Sequential Store - FC Memory Bank 0 (Weight - 8b)
    for i in range(208):
        await store(dut, i + 0x100, i + 3, i + 2, i + 1, i)
    # Sequential Store - FC Memory Bank 1 (Weight - 8b)
    for i in range(208):
        await store(dut, i + 0x200, i + 3, i + 2, i + 1, i)
    # Sequential Store - FC Memory Bank 3 (Bias - 32b)
    await store(dut, 0x300, i + 3, i + 2, i + 1, i)
    # Sequential Store - FC Memory Bank 3 (Bias - 32b)
    await store(dut, 0x400, i + 3, i + 2, i + 1, i)

    # Load Test
    # Sequential Load - Conv 1 Memory Bank 0 (Weight - 104b)
    for i in range(8):
        observed = await load(dut, i)
        expected = [i + 3, i + 2, i + 1, i]
        assert observed == expected
    # Sequential Load - Conv 1 Memory Bank 1 (Weight - 104b)
    for i in range(8):
        observed = await load(dut, i + 0x10)
        expected = [i + 3, i + 2, i + 1, i]
        assert observed == expected
    # Sequential Load - Conv 1 Memory Bank 2 (Weight - 104b)
    for i in range(8):
        observed = await load(dut, i + 0x20)
        expected = [i + 3, i + 2, i + 1, i]
        assert observed == expected
    # Sequential Load - Conv 1 Memory Bank 3 (Bias - 32b)
    for i in range(8):
        observed = await load(dut, i + 0x30)
        expected = [0, 0, 0, i]
        assert observed == expected
    # Sequential Load - Conv 1 Memory Bank 4 (Shift - 5b)
    observed = await load(dut, 0x40)
    expected = [0, 0, 0, i]
    assert observed == expected

    # Sequential Load - Conv 2 Memory Bank 0 (Weight - 64b)
    for i in range(16):
        observed = await load(dut, i + 0x50)
        expected = [0, 0, i + 1, i]
        assert observed == expected
    # Sequential Load - Conv 2 Memory Bank 1 (Weight - 64b)
    for i in range(16):
        observed = await load(dut, i + 0x60)
        expected = [0, 0, i + 1, i]
        assert observed == expected
    # Sequential Load - Conv 2 Memory Bank 2 (Weight - 64b)
    for i in range(16):
        observed = await load(dut, i + 0x70)
        expected = [0, 0, i + 1, i]
        assert observed == expected
    # Sequential Load - Conv 2 Memory Bank 3 (Bias - 32b)
    for i in range(16):
        observed = await load(dut, i + 0x80)
        expected = [0, 0, 0, i]
        assert observed == expected
    # Sequential Load - Conv 2 Memory Bank 4 (Shift - 5b)
    observed = await load(dut, 0x90)
    expected = [0, 0, 0, i]
    assert observed == expected

    # Sequential Load - FC Memory Bank 0 (Weight - 8b)
    for i in range(208):
        observed = await load(dut, i + 0x100)
        expected = [0, 0, 0, i]
        assert observed == expected
    # Sequential Load - FC Memory Bank 1 (Weight - 8b)
    for i in range(208):
        observed = await load(dut, i + 0x200)
        expected = [0, 0, 0, i]
        assert observed == expected
    # Sequential Load - FC Memory Bank 3 (Bias - 32b)
    observed = await load(dut, 0x300)
    expected = [0, 0, 0, i]
    assert observed == expected
    # Sequential Load - FC Memory Bank 3 (Bias - 32b)
    observed = await load(dut, 0x400)
    expected = [0, 0, 0, i]
    assert observed == expected

    #  n_fixed_tests = 4  # number of different types of fixed tests
    #  for i in range(n_fixed_tests):
    #      print('=' * 100)
    #      print('Beginning fixed test {}/{}.'.format(i+1, n_fixed_tests))
    #      print('=' * 100)
    #      await do_fixed_test(dut, i)
    #
    #  n_random_tests = 3  # number of different types of random tests
    #  n_repeats = 5  # how many times to repeat each random test
    #  for i in range(n_random_tests):
    #      for j in range(n_repeats):
    #          print('=' * 100)
    #          print('Beginning random test {}/{} repeat num {}/{}.' \
    #                  .format(i+1, n_random_tests, j+1, n_repeats))
    #          print('=' * 100)
    #          await do_random_test(dut, i)
    #
    #  n_mfcc_tests = 10  # number of tests to do with real MFCC features
    #  for i in range(n_mfcc_tests):
    #      print('=' * 100)
    #      print('Beginning MFCC test {}/{} '.format(i+1, n_mfcc_tests))
    #      print('=' * 100)
    #      params = na.get_params()
    #      await write_mem_params(dut, params)
    #      await do_mfcc_test(dut)
