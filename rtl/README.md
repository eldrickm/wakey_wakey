# Wakey-Wakey - RTL and Simulation

[Verlog Style Guide](https://github.com/lowRISC/style-guides/blob/master/VerilogCodingStyle.md)

## Setup

You have two options for a simulation backend - Icarus Verilog or Verilator
We recommend Icarus Verilog as cocotb + Verilator support is experimental.


### (Recommended) Step 1 - Install Icarus Verilog
Install [Icarus Verilog](https://github.com/steveicarus/iverilog).
Ubuntu 20.04 users can use `apt` directly to install.
```
sudo apt install iverilog
```

### (Not Recommended) Step 1 - Install Verilator
Install [Verilator](https://github.com/verilator/verilator) using these
[instructions](https://www.veripool.org/projects/verilator/wiki/Installing).

In order to work with `cocotb` you will need to install Verilator 4.106
This version is currently not updated in Ubuntu 20.04 PPAs, so you will
need to build from source.

Building Verilator 4.201 from GitHub has been verified to work.
Keep in mind that the `make` process can take a while.

### Step 2 - Install GTKWave
Install [GTKWave](http://gtkwave.sourceforge.net/).
Ubuntu 20.04 users can use `apt` directly to install.
```
sudo apt install gtkwave
```

### Step 3 - Install cocotb
Install [cocotb](https://github.com/cocotb/cocotb), the latesst stable
version can be installed with `pip`.
```
pip install cocotb
```

## Usage

Our RTL design testbenches are designed to use no additional HDL code.
All tests are written in `python` using `cocotb`.
We believe this facilitates more robust, scalable testing compared to ad-hoc
(System)Verilog testbenches.

You can follow the
[cocotb Quickstart Guide](https://docs.cocotb.org/en/stable/quickstart.html)
to walk you through an example `cocotb` testbench.

## External IP - Dependencies
- [FFT - zipcpu/dblclockfft](https://github.com/ZipCPU/dblclockfft)

## External IP - Resources
In order of where you should look first!
- [UCSC OpenRAM](https://github.com/VLSIDA/OpenRAM)
- [UW Basejump STL](https://github.com/bespoke-silicon-group/basejump_stl)
- [TU Dresden Pile of Cores](https://github.com/VLSI-EDA/PoC)
- [FOSSi LibreCores](https://www.librecores.org/)

## Tool Documentation
- [Verilator Manual](https://www.veripool.org/wiki/verilator/Manual-verilator)
- [cocotb Documentation](https://docs.cocotb.org/en/stable/)


## Contributors
- [Eldrick Millares (@eldrickm)](https://github.com/eldrickm)
- [Matthew Pauly (@mjpauly)](https://github.com/mjpauly)
