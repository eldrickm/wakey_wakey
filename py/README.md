# Python Models

This directory contains code for training the Wakey Wakey NN architecture, running inferences
with numpy as a testbench for rtl verification, and the quantized weights.

- WakeyWakeyNNArch.ipynb: Notebook for training the network, quantizing the parameters, and developing the numpy model alongside the PyTorch version.
- numpy_arch.py: Python module containing only the numpy model, used with CocoTB for rtl verification.
- parameters_quantized.npz: A numpy archive containing the quantized parameters from the trained network.

A colab version of the ipython notebook can be found here: https://colab.research.google.com/drive/11s4RKhQOqi4lxJz2K83RSuqHdArnLfA0?usp=sharing. Be sure to change your runtime to GPU for faster training.
