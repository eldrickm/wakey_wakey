# Wakey-Wakey - Physical Design

This document covers how to integrate the Wakey-Wakey design for the Skywater
MPW-TWO shuttle.

## Setup
This assumes you are on the Stanford `caddy` compute cluster.

Install the necessary tools (RISC-V toolchain,`caravel_user_project`, pdk,
precheck, openlane, etc) using the script below. You only need to do this once.

```
./install.sh
```

## Usage

### Step 1 - Set Environment Variables
You should do this every time you start a new session.

```
./setup.sh
```

### Step 2 - Import Wakey-Wakey Design Files
Concatenate all RTL files into `design.v` and move them over to verilog/rtl/
This uses the Makefile in the `rtl/` folder.

```
./pull_rtl.sh
```

### Step 3 - Integrate Wakey-Wakey into verilog/rtl/user_proj_example.v
`wakey_wakey` needs to be instantiated.

This is manually done. The source file is in
`caravel_integratin/user_proj_example.v` and is copied over when Step 2 is
executed.


### Step 4 - Configure uprj_netlists.v
The netlists needs to include the exported `design.v`

This is manually done. The source file is in
`caravel_integratin/uprj_netlists.v` and is copied over when Step 2 is
executed.

### Step 5 - Import Wakey-Wakey Design Verification Files
TODO

### Step 6 - Configure Design Verification Makefile
TODO


## Updating caravel_user_project

```
./update_caravel.sh
```

## Contributors
- [Eldrick Millares (@eldrickm)](https://github.com/eldrickm)
- [Matthew Pauly (@mjpauly)](https://github.com/mjpauly)
