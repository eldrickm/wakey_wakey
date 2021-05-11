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

### Step 3 - Integrate into Wakey-Waky into verilog/rtl/user_proj_example.v

### Step 4 - Configure uprj_netlists

### Step 5 - Import Wakey-Wakey Design Verification Files

### Step 6 - Configure Design Verification Makefile


## Updating caravel_user_project

```
./update_caravel.sh
```

## Contributors
- [Eldrick Millares (@eldrickm)](https://github.com/eldrickm)
- [Matthew Pauly (@mjpauly)](https://github.com/mjpauly)
