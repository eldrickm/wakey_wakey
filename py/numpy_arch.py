# -*- coding: utf-8 -*-
"""Wakey Wakey NN Arch implementation in numpy.

Based on colab notebook located at:
https://colab.research.google.com/drive/11s4RKhQOqi4lxJz2K83RSuqHdArnLfA0
"""

import numpy as np
import requests
import os
import pathlib


# Load MFCC features

API_KEY = 'ei_9eedce842a674656748bf65a19f0e2a80cc867cde21a7810354f75a4fb565a3d'

cache_dir = pathlib.Path(__file__).parent.absolute()

def get_data(fname, url):
    '''Locally cache MFCC features so they can be loaded quickly.'''
    if not os.path.exists(cache_dir / fname):
        data = (requests.get(url, headers={'x-api-key': API_KEY})).content
        with open(cache_dir / fname, 'wb') as file:
            file.write(data)
    return np.load(cache_dir / fname)

X = get_data('x_train.npy', 'https://studio.edgeimpulse.com/v1/api/24007/dsp-data/23/x/training')
Y = get_data('y_train.npy', 'https://studio.edgeimpulse.com/v1/api/24007/dsp-data/23/y/training')[:,0]
Xtest = get_data('x_test.npy', 'https://studio.edgeimpulse.com/v1/api/24007/dsp-data/23/x/testing')
Ytest = get_data('y_test.npy', 'https://studio.edgeimpulse.com/v1/api/24007/dsp-data/23/y/testing')[:,0]


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

def get_numpy_pred(features):
    '''Top level function for running inference with the numpy model.'''
    out = np.zeros((features.shape[0], 3), dtype=np.int64)
    for i in range(features.shape[0]):
        # condition input feature map
        x = features[i]
        x = np.clip(np.round(x * input_scale), -128, 127).astype(np.int8)
        x = x.reshape((int(x.size / 13), 13))

        # conv1
        x = conv1d_multi_kernel(x, conv1_weights, conv1_biases)
        x = scale_feature_map(x, bitshifts[0])
        x = max_pool_1d(x)

        # conv2
        x = conv1d_multi_kernel(x, conv2_weights, conv2_biases)
        x = scale_feature_map(x, bitshifts[1])
        x = max_pool_1d(x)

        # fc1
        x = fc(x, fc1_weights, fc1_biases)
        
        out[i] = x
    return out


# Functions for external use in testbench

def get_num_train_samples():
    return X.shape[0]

def get_featuremap(index):
    '''Return the MFCC featuremap for a given index.'''
    x = X[index,:]
    x = np.clip(np.round(x * input_scale), -128, 127).astype(np.int8)
    x = x.reshape((int(x.size / 13), 13))
    return x

def get_numpy_pred_index(index):
    '''Run inference for training sample given its index.'''
    return get_numpy_pred(X[index:index+1,:])

def output_is_equal(y1, y2):
    diff = y1 - y2
    return np.abs(diff).max() < 1e-9
