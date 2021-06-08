# Overview
This repository runs the following pipecleaner designs through a digital physical design flow using Design Compiler and Innovus with the SkyWater open source 130nm PDK.
*  GcdUnit - computes the greatest common divisor function, consists of 100-200 gates
*  SramUnit - uses an OpenRAM generated SRAM, plus a simple counter that supplies addresses to it

# Setup
To run this flow, please install the following dependencies first in this order:

1. `skywater-pdk` 

Get SkyWater PDK:
```
git clone https://github.com/google/skywater-pdk.git
cd skywater-pdk
```
The cell libraries are in submodules that need to be checked out independently:
```
git submodule update --init libraries/sky130_fd_sc_hd/latest
git submodule update --init libraries/sky130_fd_pr/latest
git submodule update --init libraries/sky130_fd_io/latest
```
To create the .lib timing files:
```
make timing
cd ..
```

2. `open_pdks`

```
git clone https://github.com/RTimothyEdwards/open_pdks.git
cd open_pdks
./configure --enable-sky130-pdk=`realpath ../skywater-pdk/libraries` --with-sky130-local-path=`realpath ../PDKS`
make
make install
cd .. 
```

3. `mflowgen` - This is a tool to create ASIC design flows in a modular fashion.
Follow the setup steps at https://mflowgen.readthedocs.io/en/latest/quick-start.html.

4. `skywater-130nm-adk` - This repo has some scripts that convert the SkyWater PDK into the format that mflowgen expects. Follow the setup steps at https://code.stanford.edu/ee272/skywater-130nm-adk. The files that are in `skywater-130nm-adk/view-standard` are the ones that mflowgen will use. (This is configured in the `design/construct.py` file for each pipecleaner.)

# Using the Pipecleaners

First, make sure you update various install paths in the `setup.bashrc` file. Then source it.
```
bash
source setup.bashrc
```

Next, enter into the build directory of the pipecleaner you want to run, and run the following:
```
cd GcdUnit/build
mflowgen run --design ../design/
```

Now, if you do `make status` you will see the status of all the steps in the flow. Use the following make targets to run and debug each step. For example to run step number N do:
```
make N
```

# Helpful make Targets
*  `make list` - list all the nodes in the graphs and their corresponding step number
*  `make status` - list the build status of all the steps
*  `make graph` - generates a PDF of the graph
*  `make N` - runs step N
*  `make debug-N` - pulls up GUI for the appropriate tool for debugging (at the output of step N)
*  `make clean-N` - removes the folder for step N, and sets the status of steps [N,) to build
*  `make clean-all` - removes folders for all the steps
*  `make runtimes` - lists the runtime for each step
