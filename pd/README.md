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

### Step 5 - Make
In `caravel_user_project/` run the following

```
make user_proj_example
```

### Pulling caravel_user_project changes into wakey_wakey
If you make a modification to the source files to be configured above,
you can pull in the changes into `caravel_integration/` by running

```
./update_caravel_integration
```

## Usage - Design Verification
TODO

### Step X - Import Wakey-Wakey Design Verification Files
TODO

### Step X - Configure Design Verification Makefile
TODO


## Updating caravel_user_project

```
./update_caravel.sh
```

## Contributors
- [Eldrick Millares (@eldrickm)](https://github.com/eldrickm)
- [Matthew Pauly (@mjpauly)](https://github.com/mjpauly)
