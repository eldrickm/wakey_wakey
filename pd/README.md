# Wakey-Wakey - Physical Design

This document covers how to use the `OpenLANE` flow for RTL-to-GDS generation.
This document also summarizes our key design metrics.


## Setup

### Step 1 - Install OpenLANE
Install [OpenLANE](https://github.com/efabless/openlane).
`OpenLANE` has been tricky to install. We are using Stanford's `caddy` computer
cluster on which we were able to get OpenLANE running.


### Step 2 - Create a new OpenLANE design

### Step 3 - Export RTL to the OpenLANE design

### Step 4 - Export RTL to the OpenLANE design

## Usage

In order to run a testbench, navigate to the respective module's directory
and run `make`. Each testbench will report it's success / failure.

Running `make` in the top level `rtl/` directory will concatenate all `.v` files
into a single Verilog source file `design.v` ready for export into a synthesis
tool. In particular, this makes export to the `OpenLANE` flow fairly easy.

### Why cocotb
Our RTL design testbenches are designed to use no additional HDL code.
All tests are written in `python` using `cocotb`.

We believe this facilitates more robust, scalable testing compared to ad-hoc
(System)Verilog testbenches as well as allowing us to directly use our
Python software models in our testbench.

### Creating a new cocotb testbench
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
- [Verlog Style Guide](https://github.com/lowRISC/style-guides/blob/master/VerilogCodingStyle.md)


## Contributors
- [Eldrick Millares (@eldrickm)](https://github.com/eldrickm)
- [Matthew Pauly (@mjpauly)](https://github.com/mjpauly)
