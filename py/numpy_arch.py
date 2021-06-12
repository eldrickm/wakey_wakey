# -*- coding: utf-8 -*-
"""Wakey Wakey NN Arch implementation in numpy.

Based on colab notebook located at:
https://colab.research.google.com/drive/11s4RKhQOqi4lxJz2K83RSuqHdArnLfA0
"""

import numpy as np
import requests
import os
import pathlib

import sys
cache_dir = pathlib.Path(__file__).parent.absolute()
sys.path.append(str(cache_dir))
import features  # module for loading mfcc features


# Load quantized parameters

weights_archive = np.load(cache_dir / 'parameters_quantized.npz')
weights_list = [weights_archive['arr_{}'.format(i)] for i in range(len(weights_archive))]

# for weights in weights_list:
    # print(weights.shape)

input_scale = weights_list[0]
bitshifts = weights_list[1]
conv1_weights = weights_list[2]
conv1_biases = weights_list[3]
conv2_weights = weights_list[4]
conv2_biases = weights_list[5]
fc1_weights = weights_list[6]
fc1_biases = weights_list[7]

# fc1_weights = fc1_weights.reshape(13, 16, 2).transpose((1,0,2)).reshape(208, 2)

# Numpy NN model

def relu(x):
    return np.maximum(x, 0)

def conv1d_single_kernel(x, weights, bias):
    '''Perform convolution of a input feature map with a single filter and bias.
    
    featuremap dims are (time, n_coeffs), so (50, 13)
    '''
    out = np.zeros(x.shape[0], dtype=np.int64)  # output length is the same
    x_pad = np.zeros((x.shape[0]+2, x.shape[1]), dtype=np.int64)
    x_pad[1:-1,:] = x  # zero padding
    for i in range(x.shape[0]):
        section = x_pad[i:i+3,:]
        out[i] = relu(np.sum(section * weights) + bias)
    return out

def conv1d_multi_kernel(x, weights, biases):
    n_kernels = weights.shape[2]
    out = np.zeros((x.shape[0], n_kernels), dtype=np.int64)
    for i in range(n_kernels):
        kernel = weights[:,:,i]
        out[:,i] = conv1d_single_kernel(x, kernel, biases[i])
    return out

def max_pool_1d(x):
    out = np.zeros((int(np.ceil(x.shape[0] / 2)), x.shape[1]), dtype=np.int8)
    for j in range(x.shape[1]):
        for i in range(int(np.floor(x.shape[0] / 2))):
            out[i, j] = np.maximum(x[2*i, j], x[2*i+1, j])
        if (x.shape[0] % 2 == 1):
            out[-1, j] = x[-1, j]
    return out

def fc(x, weights, biases):
    '''A fully connected linear layer.'''
    x = x.flatten()
    out = np.matmul(x, weights, dtype=np.int64) + biases
    return out

def scale_feature_map(x, shift):
    '''Scale a featuremap to a byte range given the amount to right shift by.

    Since all weight, bias, and activation quantizations are mapped using the full range
    of values, there is not any need for clamping the values to the range [-128, 127].
    However, it is still useful since the quantization could be changed to not map to the
    full range of the unquantized values.
    '''
    x = np.right_shift(x, shift)
    x = np.clip(x, -128, 127)
    x = x.astype(np.int8)
    return x

def get_numpy_pred_custom_params(x, params, quantize_input=False):
    '''Top level function for running inference with the numpy model.

    quantize_input: treat the input as a floating point MFCC featurmap and
                    quantize it
    '''

    c1w, c1b, c1s, c2w, c2b, c2s, fcw, fcb = params

    assert x.ndim == 2

    # condition input feature map
    if quantize_input:
        x = np.clip(np.round(x * input_scale), -128, 127).astype(np.int8)
        x = x.reshape((int(x.size / 13), 13))

    # conv1
    x = conv1d_multi_kernel(x, c1w, c1b)
    x = scale_feature_map(x, c1s)
    conv1_out = x
    x = max_pool_1d(x)

    # conv2
    x = conv1d_multi_kernel(x, c2w, c2b)
    x = scale_feature_map(x, c2s)
    conv2_out = x
    x = max_pool_1d(x)

    # fc1
    x = fc(x, fcw, fcb)
        
    return x, conv1_out, conv2_out

def get_numpy_pred(x):
    '''Get the output for an unquantized MFCC featuremap.'''
    params = [conv1_weights, conv1_biases, bitshifts[0],
              conv2_weights, conv2_biases, bitshifts[1],
              fc1_weights, fc1_biases]
    return get_numpy_pred_custom_params(x, params, quantize_input=True)

# Functions for external use in testbench
# MFCC featurmaps returned are expected to be quantized already

def get_num_train_samples():
    return features.X.shape[0]

def get_featuremap(index):
    '''Return the MFCC featuremap for a given index.'''
    x = features.X[index,:]
    x = np.clip(np.round(x * input_scale), -128, 127).astype(np.int8)
    x = x.reshape((int(x.size / 13), 13))
    return x

def get_random_featuremap():
    index = np.random.randint(get_num_train_samples())
    return get_featuremap(index), index

def get_numpy_pred_index(index):
    '''Run inference for training sample given its index.'''
    return get_numpy_pred(features.X[index:index+1,:])

def output_is_equal(y1, y2):
    diff = y1 - y2
    return np.abs(diff).max() < 1e-9

def get_params():
    '''Return the trained model weights for writing to dut memory.'''
    params = [conv1_weights, conv1_biases, bitshifts[0],
              conv2_weights, conv2_biases, bitshifts[1],
              fc1_weights, fc1_biases]
    return params

# ==============================================================================
# Memory Writing
# ==============================================================================
# Main source at rtl/top/top/test_wakey_wakey.py

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

def printn(x):
    print(x, end='')

def print_hex_int(x):
    printn('0x{:x}'.format(x & 0xffffffff))

def pretty_print_conv_weights(conv_num, weights):
    weights_packed = pack_conv_weights(weights)
    filter_width = weights_packed.shape[0]
    n_filters = weights_packed.shape[2]
    print('const int conv{}_filter_width = {};'.format(conv_num, filter_width))
    print('const int conv{}_n_filters = {};'.format(conv_num, n_filters))
    print('// CFG reg order: {data3, data2, data1, data0}')
    print('const int conv{}_weights[{}][{}][4] = {{'.format(conv_num,
                                                    filter_width, n_filters))
    for j in range(filter_width):
        printn('{')
        for i in range(n_filters):
            printn('{')
            for k in range(4):
                print_hex_int(weights_packed[j, k, i])
                if k < 4 - 1: printn(', ')
            printn('}')
            if i < n_filters - 1: print(',')
        printn('}')
        if j < filter_width - 1: print(',')
    print('};\n')

def pretty_print_conv_biases(conv_num, biases):
    n_filters = biases.size
    print('// Conv biases should each be written to the CFG data0 reg.')
    print('const int conv{}_biases[{}] = {{'.format(conv_num, n_filters))
    for i in range(n_filters):
        print_hex_int(biases[i])
        if i < n_filters - 1: print(', ')
    print('};\n')

def pretty_print_conv_shift(conv_num, shift):
    printn('const int conv{}_shift = '.format(conv_num))
    print_hex_int(shift)
    print(';\n')

def pretty_print_fc_weights(weights):
    in_length, n_classes = weights.shape
    w = weights.reshape(13, 16, 2).transpose((1,0,2)).reshape(208, 2)
    print('const int fc_n_classes = {};'.format(n_classes))
    print('const int fc_in_length = {};'.format(in_length))
    print('const int fc_weights[{}][{}] = {{'.format(n_classes, in_length))
    for j in range(n_classes):
        printn('{')
        for i in range(in_length):
            print_hex_int(w[i, j])
            if i < in_length - 1: print(',')
        printn('}')
        if j < n_classes - 1: print(',')
    print('};\n')

def pretty_print_fc_biases(biases):
    n_classes = biases.size
    print('const int fc_biases[{}] = {{'.format(n_classes))
    for i in range(n_classes):
        print_hex_int(biases[i])
        if i < n_classes - 1: print(', ')
    print('};\n')

def pretty_print_params():
    '''Pretty print the params so that they can be included in a .h file in
    management soc firmware. The params are already packed so that they can
    be written via the 32-bit wishbone interface without modification.'''
    # params = [conv1_weights, conv1_biases, bitshifts[0],
              # conv2_weights, conv2_biases, bitshifts[1],
              # fc1_weights, fc1_biases]
    print("// Generated by numpy_arch")
    pretty_print_conv_weights(1, conv1_weights)
    pretty_print_conv_biases(1, conv1_biases)
    pretty_print_conv_shift(1, bitshifts[0])

    pretty_print_conv_weights(2, conv2_weights)
    pretty_print_conv_biases(2, conv2_biases)
    pretty_print_conv_shift(2, bitshifts[1])

    pretty_print_fc_weights(fc1_weights)
    pretty_print_fc_biases(fc1_biases)


if __name__ == "__main__":
    pretty_print_params()
