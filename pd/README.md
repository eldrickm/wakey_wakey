# Wakey-Wakey - Physical Design

This document covers how to use the `OpenLANE` flow for RTL-to-GDS generation.

## Setup

### Step 1 - Install OpenLANE
Install [OpenLANE](https://github.com/efabless/openlane).
`OpenLANE` has been tricky to install. We are using Stanford's `caddy` computer
cluster on which we were able to get OpenLANE running.

### Step 2 - Create a new OpenLANE design
Please see the [full instructions here](https://openlane.readthedocs.io/en/latest/designs/README.html)
Quick start command for use in the OpenLANE top level directory in Docker:
```
./flow.tcl -design wakey_wakey -init_design_config
```

### Step 3 - Export RTL to the OpenLANE design
Navigate to `rtl/` from the top level and run `make`. This should create a
`design.v` file that has the full verilog source. Copy `design.v` to
```
openlane/designs/wakey_wakey/src/
```

### Step 4 - Set configuration parameters
Set the desired configuration parameters values in
```
openlane/designs/wakey_wakey/config.tcl
```
You can use the `config.tcl` in this directory as a starting point.


### Step 5 - Start OpenLANE Docker container
In `openlane/` run
```
make mount
```


## Usage

To run the full flow hands-free, you can run the following in the running Docker
container, in `openlane/`
```
./flow.tcl -design wakey_wakey -tag NAME_THIS_RUN

```


## Tool Documentation
- [OpenLANE](https://openlane.readthedocs.io/en/latest/)
- [OpenLANE Configuration Parameters](https://github.com/efabless/openlane/tree/master/configuration)


## Contributors
- [Eldrick Millares (@eldrickm)](https://github.com/eldrickm)
- [Matthew Pauly (@mjpauly)](https://github.com/mjpauly)
