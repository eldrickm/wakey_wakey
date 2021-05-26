# Wakey-Wakey - Physical Design

This document covers how to integrate the Wakey-Wakey design for the Skywater
MPW-TWO shuttle.

## Setup
This assumes you are on the Stanford `caddy` compute cluster.
Be sure to use the `/tmp` directory on `caddy`.
This setup was validated in `/tmp/eldrick/wakey_wakey/pd` on `caddy09`

Install the necessary tools (RISC-V toolchain,`caravel_user_project`, pdk,
precheck, openlane, etc) using the script below. You only need to do this once.

```
./install.sh
```

## Usage - RTL to GDS

### Step 1 - Set Environment Variables
You should do this every time you start a new session.

```
source setup.sh
```

### Step 2 - Import Wakey-Wakey Design Files
Concatenate all RTL files into `design.v` and move them over to verilog/rtl/
This uses the Makefile in the `rtl/` folder.

```
./patch.sh
```

### Step 3 - Integrate Wakey-Wakey into verilog/rtl/user_proj_example.v
`wakey_wakey` needs to be instantiated.

This is done manually. The source files are
`caravel_integration/rtl/user_proj_example.v` and
`caravel_integration/rtl/user_project_wrapper.v`
and they are copied over to
`caravel_user_project/verilog/rtl/` when Step 2 is
executed.


### Step 4 - Configure uprj_netlists.v
The netlists needs to include the exported `design.v`

This is done manually. The source file is
`caravel_integration/rtl/uprj_netlists.v` and it is copied over to
`caravel_user_project/verilog/rtl/` when Step 2 is
executed.

### Step 5 - Make
In `caravel_user_project/` run the following

```
make user_project_wrapper
```

### Syncing caravel_user_project changes into wakey_wakey
If you make a modification to the source files to be configured above inside of
`caravel_user_project`, you can sync in the changes into `caravel_integration/`
by running

```
./sync.sh
```

## Usage - Design Verification

### Step 1 - Set Environment Variables
You should do this every time you start a new session.

```
source setup.sh
```

### Step 2 - Import Wakey-Wakey Design Verification Files
Similar to Step 2 of the [RTL to GDS](#Usage - RTL to GDS) flow, you can run
the same command to automatically import the verilog files and patch everything.

```
./patch.sh
```


### Step 3 - Configure Design Verification Makefile
This is done manually. The source file is
`caravel_integration/wakey_wakey_test/Makefile` and is copied over to
`caravel_user_project/verilog/dv/wakey_wakey_test` when Step 2 is
executed.

### Step 4 - Write Verilog TB
This is done manually. The source file is
`caravel_integration/wakey_wakey_test/wakey_wakey_test_tb.v` and is copied over
to `caravel_user_project/verilog/dv/wakey_wakey_test` when Step 2 is
executed.

### Step 4 - Write C Firmware
This is done manually. The source file is
`caravel_integration/wakey_wakey_test/wakey_wakey_test.c` and is copied over
to `caravel_user_project/verilog/dv/wakey_wakey_test` when Step 2 is
executed.

### Step 5 - Make
In `caravel_user_project/verilog/dv/wakey_wakey_test` run the following

```
make
```


## Updating caravel_user_project
Uncomment / comment in the proper blocks in `install.sh` as needed


## Contributors
- [Eldrick Millares (@eldrickm)](https://github.com/eldrickm)
- [Matthew Pauly (@mjpauly)](https://github.com/mjpauly)
