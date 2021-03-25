import subprocess
import sys
import inspect 
import argparse
import json

parser = argparse.ArgumentParser(description='Dumps parameter files for Verilog testbench and glod model from a JSON file')

parser.add_argument("-l", "--layers", type=str, nargs='*', help='Layer specification files to run', default=["./layers/resnet_conv2_x_params.json"])

args = parser.parse_args()

for layer in args.layers:
    print("Dumping parameters for layer:", layer)

    with open(layer) as f:
        data = json.load(f)

    param_str_c = f'''const int IC0 = {data["IC0"]};
const int OC0 = {data["OC0"]};
const int IC1 = {data["IC1"]};
const int OC1 = {data["OC1"]};
const int FX = {data["FX"]};
const int FY = {data["FY"]};
const int OX0 = {data["OX0"]};
const int OY0 = {data["OY0"]};
const int OX1 = {data["OX1"]};
const int OY1 = {data["OY1"]};
const int STRIDE = {data["STRIDE"]}; 
'''

    param_str_v = f'''`define IC0 {data["IC0"]}
`define OC0 {data["OC0"]}
`define IC1 {data["IC1"]}
`define OC1 {data["OC1"]}
`define FX {data["FX"]}
`define FY {data["FY"]}
`define OX0 {data["OX0"]}
`define OY0 {data["OY0"]}
`define OX1 {data["OX1"]}
`define OY1 {data["OY1"]}
`define STRIDE {data["STRIDE"]}
'''
    
    with open("conv_tb_params.h", "w") as output:
        output.write(param_str_c)

    with open("layer_params.v", "w") as output:
        output.write(param_str_v)
 
