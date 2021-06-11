"""
This file is public domain, it can be freely copied without restrictions.
SPDX-License-Identifier: CC0-1.0

Top Level Wakey-Wakey Testbench
"""

import sys
sys.path.append('../../../py/')
import numpy_arch as na
import pdm

sys.path.append('../../../test/pdm_capture_test/py/')
import parse_mic_data

import numpy as np
from tqdm.auto import tqdm

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge
from cocotb.binary import BinaryValue


# ==============================================================================
# User Defined Flags
# ==============================================================================
ENABLE_ASSERTS = True


# ==============================================================================
# Constants
# ==============================================================================
INT8_MIN = np.iinfo(np.int8).min
INT8_MAX = np.iinfo(np.int8).max
INT32_MIN = np.iinfo(np.int32).min
INT32_MAX = np.iinfo(np.int32).max


# ==============================================================================
# General Utilities
# ==============================================================================
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


# ==============================================================================
# Wishbone Transactions
# ==============================================================================
async def wishbone_write(dut, addr, data):
    """
    Conduct a single wishbone write transaction

    addr is the 32b wishbone address
    data is a 32b value
    """

    # set control signals to write (we_i asserted)
    dut.wbs_stb_i <= 1
    dut.wbs_cyc_i <= 1
    dut.wbs_we_i  <= 1
    dut.wbs_sel_i <= 0xF
    dut.wbs_dat_i <= data
    dut.wbs_adr_i <= addr
    await FallingEdge(dut.clk_i)

    # unset control signals
    dut.wbs_stb_i <= 0
    dut.wbs_cyc_i <= 0
    dut.wbs_we_i  <= 0
    dut.wbs_sel_i <= 0x0
    dut.wbs_dat_i <= 0x0
    dut.wbs_adr_i <= 0x0

    # wait for ack
    while not dut.wbs_ack_o.value:
        await FallingEdge(dut.clk_i)


async def wishbone_read(dut, addr):
    """
    Conduct a single wishbone read transaction

    addr is the 32b wishbone address

    returns a 32b data value from the address that was read
    """

    # set control signals to read (we_i deasserted)
    dut.wbs_stb_i <= 1
    dut.wbs_cyc_i <= 1
    dut.wbs_we_i  <= 0
    dut.wbs_sel_i <= 0xF
    dut.wbs_dat_i <= 0x0
    dut.wbs_adr_i <= addr
    await FallingEdge(dut.clk_i)

    # unset control signals
    dut.wbs_stb_i <= 0
    dut.wbs_cyc_i <= 0
    dut.wbs_we_i  <= 0
    dut.wbs_sel_i <= 0x0
    dut.wbs_dat_i <= 0x0
    dut.wbs_adr_i <= 0x0

    # wait for ack
    while not dut.wbs_ack_o.value:
        await FallingEdge(dut.clk_i)

    return dut.wbs_dat_o.value


# ==============================================================================
# CFG Transactions
# ==============================================================================
async def cfg_store(dut, addr, data_3, data_2, data_1, data_0):
    """
    Store to Wakey Wakey Memory

    addr is a 32b address in the Wakey Wakey address space
    data_3 MSB
    data_2
    data_1
    data_0 LSB
    """
    # write the store address
    await wishbone_write(dut, 0x30000000, addr)
    # write data words
    await wishbone_write(dut, 0x30000008, data_0)
    await wishbone_write(dut, 0x3000000C, data_1)
    await wishbone_write(dut, 0x30000010, data_2)
    await wishbone_write(dut, 0x30000014, data_3)
    # write store command - 0x1
    await wishbone_write(dut, 0x30000004, 0x1)


async def cfg_load(dut, addr):
    """
    Load from Wakey Wakey Memory

    addr is a 32b address in the Wakey Wakey address space
    returns a list of values in the following order:
    [data_3, data_2, data_1, data_0]
    where data_3 is the MSB and data_0 is the LSB
    """
    # write address the load address
    await wishbone_write(dut, 0x30000000, addr)
    # write the load command - 0x2
    await wishbone_write(dut, 0x30000004, 0x2)
    # TODO: Currently need to wait one clock cycle before read starts - fix?
    await FallingEdge(dut.clk_i)
    # read the data words
    data_0 = await wishbone_read(dut, 0x30000008)
    data_1 = await wishbone_read(dut, 0x3000000C)
    data_2 = await wishbone_read(dut, 0x30000010)
    data_3 = await wishbone_read(dut, 0x30000014)

    return [data_3, data_2, data_1, data_0]


# ==============================================================================
# Memory Write Transactions
# ==============================================================================
def bytes_to_word(byte_arr):
    """
    Combine 4 bytes to 1 32b word.
    Index 0 is the MSB, Index 3 is the LSB
    """
    assert len(byte_arr) == 4
    # set to 32b in order to have left shifts work
    byte_arr = byte_arr.astype(np.int32)
    # assemble via mask and shift
    word = (((byte_arr[0] & 0xff) << 24) | ((byte_arr[1] & 0xff) << 16) |
            ((byte_arr[2] & 0xff) << 8) | (byte_arr[3] & 0xff))
    return word


def partition_weights(weight_vector):
    """
    Return 4 32b values for use in CFG writes from a vector of 8b values

    weight_vector should be no more than 16 entries

    A list of 4 32b words are returned, MSB at index 0
    """
    n_channels = len(weight_vector)
    assert n_channels <= 16

    # properly pad the weight vector to 16 8b entries
    full_word = np.zeros(16, dtype=np.int8)
    for i in range(n_channels):
        full_word[i + (16 - n_channels)] = weight_vector[i]

    # get 32b words from 4 bytes
    msb    = bytes_to_word(full_word[0:4])
    data_2 = bytes_to_word(full_word[4:8])
    data_1 = bytes_to_word(full_word[8:12])
    lsb    = bytes_to_word(full_word[12:16])

    return [msb, data_2, data_1, lsb]


def pack_conv_weights(weights):
    """
    Convert a list of conv weights into a list ready for CFG stores

    The CFG store format is 4 32b words
    """
    filter_width, n_channels, n_filters = weights.shape
    packed = np.zeros((filter_width, 4, n_filters), dtype=np.int32)
    for j in range(filter_width):
        for i in range(n_filters):
            vector = weights[j, :, i]
            partitioned = partition_weights(vector)
            packed[j, 0, i] = partitioned[0]
            packed[j, 1, i] = partitioned[1]
            packed[j, 2, i] = partitioned[2]
            packed[j, 3, i] = partitioned[3]
    return packed


async def write_conv_mem(dut, conv_num, weights, biases, shift):
    """
    Write weights, biases, and shifts to a convolution layer memory.

    conv_num is which convolution block to write to, either 1 or 2
    weights is size (filter_width, n_channels, n_filters).
    biases is size (n_filters).
    """
    filter_width, n_channels, n_filters = weights.shape

    assert filter_width == 3, "Filter Width does not equal 3"
    offsets = None
    weights_packed = pack_conv_weights(weights)

    if conv_num == 1:  # conv1
        assert n_filters == 8, "Conv1 n_filters does not equal 8"
        offsets = [0x20, 0x10, 0x00, 0x30, 0x40]
    elif conv_num == 2:  # conv2
        assert n_filters == 16, "Conv2 n_filters does not equal 16"
        offsets = [0x70, 0x60, 0x50, 0x80, 0x90]
    else:
        assert False, "Invalid Convolution Block Number"

    # Memory Bank 0-2 (Weight - Conv1: 104b, Conv2: 64b)
    for j in range(filter_width):
        for i in range(n_filters):
            # transform weight shape from (3, 13, 8) -> (3, 4, 8) for use in
            # cfg_write this requires stuffing the 13 8b into 4 32b numbers
            await cfg_store(dut, i + offsets[j], int(weights_packed[j, 0, i]),
                                                 int(weights_packed[j, 1, i]),
                                                 int(weights_packed[j, 2, i]),
                                                 int(weights_packed[j, 3, i]))
    # Memory Bank 3 (Bias - 32b)
    for i in range(n_filters):
        await cfg_store(dut, i + offsets[3], 0, 0, 0, int(biases[i]))
    # Memory Bank 4 (Shift - 5b)
    await cfg_store(dut, offsets[4], 0, 0, 0, int(shift))


async def write_fc_mem(dut, w, b):
    """
    Write weights and biases to the fully connected layer memory
    """
    in_length, n_classes = w.shape

    # need to reorder weights
    w = w.reshape(13, 16, 2).transpose((1,0,2)).reshape(208, 2)

    offsets = [0x100, 0x200, 0x300, 0x400]

    # FC Memory Bank 0-1 (Weight - 8b)
    for j in range(n_classes):
        for i in range(in_length):
            await cfg_store(dut, i + offsets[j], 0, 0, 0, int(w[i, j]))

    # FC Memory Bank 2-3 (Bias - 32b)
    for j in range(n_classes):
        await cfg_store(dut, offsets[j + 2], 0, 0, 0, int(b[j]))


# ==============================================================================
# Write to dut
# ==============================================================================
async def write_input_features(dut, x):
    """
    Asynchronously send a full set of MFCC features to the dut.

    x is an array of size (n_frames, n_channels), and needs zero padding.
    """
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

async def write_pdm_input(dut, x):
    '''Write a PDM audio stream to the DUT.'''
    dut.vad_i <= 1  # raise VAD to start DUT processing pipeline
    n = len(x)
    print_interval = int(n/100)
    # for i in tqdm(range(n)):
    for i in range(n):
        dut.pdm_data_i <= int(x[i])
        await FallingEdge(dut.pdm_clk_o)  # wait on PDM clock falling edge
        if (i % print_interval == 0):
            print('{}/{}'.format(i, n))
    dut.vad_i <= 0  # de-assert VAD
    dut.pdm_data_i <= 0

PCM_SPACING = 3  # cycles between writing another PCM input
                 # must be >= 3 so the FFT isn't over utilised
async def write_pcm_input(dut, x):
    '''Write a PCM audio stream directly to ACO.'''
    dut.vad_i <= 1  # raise VAD to start DUT processing pipeline
    for i in range(3000):
        await FallingEdge(dut.clk_i)
    while (dut.ctl_inst.en_o != 1):  # wait until pipeline reactivates
        await FallingEdge(dut.clk_i)
    n = len(x)
    # print_interval = int(n/100)
    # for i in range(n):
    for i in tqdm(range(n)):
        dut.dfe_data <= int(x[i])
        dut.dfe_valid <= 1
        await FallingEdge(dut.clk_i)  # wait on PDM clock falling edge
        dut.dfe_data <= 0
        dut.dfe_valid <= 0
        for j in range(PCM_SPACING):
            await FallingEdge(dut.clk_i)
        # if (i % print_interval == 0):
            # print('{}/{}'.format(i, n))
    dut.vad_i <= 0  # de-assert VAD

# ==============================================================================
# Intermediate Activation Reading
# ==============================================================================
async def read_conv_output(dut, conv_num, n_frames, n_channels, expected):
    """Receive the output featuremap and put it in a numpy array."""
    total_values = n_frames * n_channels
    received_values = 0
    output_arr = np.zeros((n_frames, n_channels), dtype=np.int8)

    if conv_num == 1:
        data = dut.wrd_inst.conv1_data
        valid = dut.wrd_inst.conv1_valid
        last = dut.wrd_inst.conv1_last
    else:
        data = dut.wrd_inst.conv2_data
        valid = dut.wrd_inst.conv2_valid
        last = dut.wrd_inst.conv2_last

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
    """Receive the output featuremap and put it in a numpy array."""
    await FallingEdge(dut.clk_i)
    while (dut.wrd_inst.fc_valid != 1):  # wait until valid output
        await FallingEdge(dut.clk_i)
    binstr = dut.wrd_inst.fc_data.value.get_binstr()
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
        assert dut.wrd_inst.fc_last == 1, 'fc_last not asserted when expected'

    print('Received output:')
    print(output_arr)
    print('Expected output:')
    print(expected)

async def read_wake(dut, wake_expected):
    """Check the wake signal is as expected."""
    for _ in range(10):
        await FallingEdge(dut.clk_i)
    wake = dut.wrd_inst.wake_o.value
    if wake_expected:
        assert wake == 1, 'Wake not asserted as expected.'
    else:
        assert wake == 0, 'Wake asserted unexpectedly.'
    print('Wake behavior as expected.')

async def read_wake_no_assert(dut):
    while (dut.wrd_inst.wake_valid.value != 1):
        await FallingEdge(dut.clk_i)
    for i in range(3):
        await FallingEdge(dut.clk_i)
    wake = dut.wrd_inst.wake_o.value
    print('Received wake determination', wake)
    wake_bool = True if (wake == 1) else False
    return wake_bool

# ==============================================================================
# Generating WRD Inputs
# ==============================================================================

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
    """Write random test values to all memories"""
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
    """Write random test values to all memories"""
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

# ==============================================================================
# PDM-based testing
# ==============================================================================
async def do_pdm_test(dut, pdm_fname):
    x = np.load(pdm_fname, allow_pickle=True)
    x = parse_mic_data.pad_pdm(x)  # pad half-second signal to 1 second
    print('Beginning of pdm input: ', x[:10])
    await write_pdm_input(dut, x)  # change on falling edge of pdm clk
    wake = await read_wake_no_assert(dut)
    return wake

# ==============================================================================
# ACO-based testing
# ==============================================================================
async def do_pcm_test(dut, pdm_fname):
    x = np.load(pdm_fname, allow_pickle=True)
    x = parse_mic_data.pad_pdm(x)  # pad half-second signal to 1 second
    x = pdm.pdm_to_pcm(x, 2)
    print('Beginning of pcm input: ', x[:10])
    await write_pcm_input(dut, x)  # change on falling edge of pdm clk
    wake = await read_wake_no_assert(dut)
    return wake


@cocotb.test()
async def test_wakey_wakey(dut):
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
    # dut.pdm_data_i <= 0
    dut.dfe_data <= 0
    dut.dfe_valid <= 0
    dut.vad_i <= 0

    # wait long enough for reset to be effective
    for _ in range(50):
        await FallingEdge(dut.clk_i)
    dut.rst_n_i <= 1
    dut.vad_i <= 1
    await FallingEdge(dut.clk_i)

    print('=' * 100)
    print('Beginning Load/Store Test')
    print('=' * 100)
    # Store Test
    # Sequential Store - Conv 1 Memory Bank 0 (Weight - 104b)
    for i in range(8):
        await cfg_store(dut, i, i + 3, i + 2, i + 1, i)
    # Sequential Store - Conv 1 Memory Bank 1 (Weight - 104b)
    for i in range(8):
        await cfg_store(dut, i + 0x10, i + 3, i + 2, i + 1, i)
    # Sequential Store - Conv 1 Memory Bank 2 (Weight - 104b)
    for i in range(8):
        await cfg_store(dut, i + 0x20, i + 3, i + 2, i + 1, i)
    # Sequential Store - Conv 1 Memory Bank 3 (Bias - 32b)
    for i in range(8):
        await cfg_store(dut, i + 0x30, i + 3, i + 2, i + 1, i)
    # Sequential Store - Conv 1 Memory Bank 4 (Shift - 5b)
    await cfg_store(dut, 0x40, i + 3, i + 2, i + 1, i)
    # Sequential Store - Conv 2 Memory Bank 0 (Weight - 64b)
    for i in range(16):
        await cfg_store(dut, i + 0x50, i + 3, i + 2, i + 1, i)
    # Sequential Store - Conv 2 Memory Bank 1 (Weight - 64b)
    for i in range(16):
        await cfg_store(dut, i + 0x60, i + 3, i + 2, i + 1, i)
    # Sequential Store - Conv 2 Memory Bank 2 (Weight - 64b)
    for i in range(16):
        await cfg_store(dut, i + 0x70, i + 3, i + 2, i + 1, i)
    # Sequential Store - Conv 2 Memory Bank 3 (Bias - 32b)
    for i in range(16):
        await cfg_store(dut, i + 0x80, i + 3, i + 2, i + 1, i)
    # Sequential Store - Conv 2 Memory Bank 4 (Shift - 5b)
    await cfg_store(dut, 0x90, i + 3, i + 2, i + 1, i)
    # Sequential Store - FC Memory Bank 0 (Weight - 8b)
    for i in range(208):
        await cfg_store(dut, i + 0x100, i + 3, i + 2, i + 1, i)
    # Sequential Store - FC Memory Bank 1 (Weight - 8b)
    for i in range(208):
        await cfg_store(dut, i + 0x200, i + 3, i + 2, i + 1, i)
    # Sequential Store - FC Memory Bank 3 (Bias - 32b)
    await cfg_store(dut, 0x300, i + 3, i + 2, i + 1, i)
    # Sequential Store - FC Memory Bank 3 (Bias - 32b)
    await cfg_store(dut, 0x400, i + 3, i + 2, i + 1, i)

    # Load Test
    # Sequential Load - Conv 1 Memory Bank 0 (Weight - 104b)
    for i in range(8):
        observed = await cfg_load(dut, i)
        expected = [i + 3, i + 2, i + 1, i]
        assert observed == expected
    # Sequential Load - Conv 1 Memory Bank 1 (Weight - 104b)
    for i in range(8):
        observed = await cfg_load(dut, i + 0x10)
        expected = [i + 3, i + 2, i + 1, i]
        assert observed == expected
    # Sequential Load - Conv 1 Memory Bank 2 (Weight - 104b)
    for i in range(8):
        observed = await cfg_load(dut, i + 0x20)
        expected = [i + 3, i + 2, i + 1, i]
        assert observed == expected
    # Sequential Load - Conv 1 Memory Bank 3 (Bias - 32b)
    for i in range(8):
        observed = await cfg_load(dut, i + 0x30)
        expected = [0, 0, 0, i]
        assert observed == expected
    # Sequential Load - Conv 1 Memory Bank 4 (Shift - 5b)
    observed = await cfg_load(dut, 0x40)
    expected = [0, 0, 0, i]
    assert observed == expected
    # Sequential Load - Conv 2 Memory Bank 0 (Weight - 64b)
    for i in range(16):
        observed = await cfg_load(dut, i + 0x50)
        expected = [0, 0, i + 1, i]
        assert observed == expected
    # Sequential Load - Conv 2 Memory Bank 1 (Weight - 64b)
    for i in range(16):
        observed = await cfg_load(dut, i + 0x60)
        expected = [0, 0, i + 1, i]
        assert observed == expected
    # Sequential Load - Conv 2 Memory Bank 2 (Weight - 64b)
    for i in range(16):
        observed = await cfg_load(dut, i + 0x70)
        expected = [0, 0, i + 1, i]
        assert observed == expected
    # Sequential Load - Conv 2 Memory Bank 3 (Bias - 32b)
    for i in range(16):
        observed = await cfg_load(dut, i + 0x80)
        expected = [0, 0, 0, i]
        assert observed == expected
    # Sequential Load - Conv 2 Memory Bank 4 (Shift - 5b)
    observed = await cfg_load(dut, 0x90)
    expected = [0, 0, 0, i]
    assert observed == expected
    # Sequential Load - FC Memory Bank 0 (Weight - 8b)
    for i in range(208):
        observed = await cfg_load(dut, i + 0x100)
        expected = [0, 0, 0, i]
        assert observed == expected
    # Sequential Load - FC Memory Bank 1 (Weight - 8b)
    for i in range(208):
        observed = await cfg_load(dut, i + 0x200)
        expected = [0, 0, 0, i]
        assert observed == expected
    # Sequential Load - FC Memory Bank 3 (Bias - 32b)
    observed = await cfg_load(dut, 0x300)
    expected = [0, 0, 0, i]
    assert observed == expected
    # Sequential Load - FC Memory Bank 3 (Bias - 32b)
    observed = await cfg_load(dut, 0x400)
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

    print('Make sure to source setup.bashrc!')
    print('To limit the number of tests, run with: make PLUSARGS="+n_tests=2"')
    params = na.get_params()
    await write_mem_params(dut, params)
    print('Preparing software model expected output:')
    fnames, wakes_expected = parse_mic_data.eval_pipeline()  # get input file names and wakes
    sort_order = np.argsort(fnames)  # sort fnames so they're ordered in an expected way
    sort_order[::2] = sort_order[::-2]
    fnames = np.array(fnames)[sort_order]
    wakes_expected = np.array(wakes_expected)[sort_order]
    n_correct = 0
    print('cocotb plusargs: ', cocotb.plusargs)
    if 'n_tests' in cocotb.plusargs:
        n_tests = int(cocotb.plusargs['n_tests'])
        print('Running only {} tests'.format(n_tests))
    else:
        n_tests = len(fnames)
    # test_num = int(cocotb.plusargs['test_num'])
    for test_num in range(n_tests):
        print('Running test {}/{} with {}'.format(test_num, n_tests-1, fnames[test_num]))
        print('=' * 100)
        print('Beginning end-to-end test {}/{} '.format(test_num, n_tests-1))
        print('=' * 100)
        wake = await do_pcm_test(dut, fnames[test_num])
        if wake != wakes_expected[test_num]:
            print('DUT output of {} when expected {}'.format(wake, wakes_expected[test_num]))
        else:
            print('DUT output of {} as expected.'.format(wake))
            n_correct += 1
    accuracy = n_correct / n_tests * 100
    print('Results: {}/{} correct, accuracy: {:.03f}'.format(n_correct, n_tests, accuracy))
