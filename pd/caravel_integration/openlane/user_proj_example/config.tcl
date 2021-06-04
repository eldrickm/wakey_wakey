# SPDX-FileCopyrightText: 2020 Efabless Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# SPDX-License-Identifier: Apache-2.0

set script_dir [file dirname [file normalize [info script]]]

set ::env(DESIGN_NAME) user_proj_example

# Wakey Wakey Change: Add `design.v` to the VERILOG_FILES variable
set ::env(VERILOG_FILES) "\
	$script_dir/../../caravel/verilog/rtl/defines.v \
	$script_dir/../../verilog/rtl/design.v \
	$script_dir/../../verilog/rtl/user_proj_example.v"

# Wakey Wakey Change: Only specify CLOCK_PORT, change frequency to 16 MHz
# set ::env(CLOCK_PORT) ""
# set ::env(CLOCK_NET) "counter.clk"
# set ::env(CLOCK_PERIOD) "10"
set ::env(CLOCK_PORT) "wb_clk_i"
# set ::env(CLOCK_NET) "wb_clk_i"
set ::env(CLOCK_PERIOD) "250"

set ::env(FP_SIZING) absolute
# Wakey Wakey Change: Expand DIE_AREA, leave 100 micron buffer from max size
# set ::env(DIE_AREA) "0 0 900 600"
# set ::env(DIE_AREA) "0 0 2920 3520"
set ::env(DIE_AREA) "0 0 2820 3420"
set ::env(DESIGN_IS_CORE) 0

# Wakey Wakey Change: Remove analog power nets
# set ::env(VDD_NETS) [list {vccd1} {vccd2} {vdda1} {vdda2}]
# set ::env(GND_NETS) [list {vssd1} {vssd2} {vssa1} {vssa2}]
set ::env(VDD_NETS) [list {vccd1} {vccd2}]
set ::env(GND_NETS) [list {vssd1} {vssd2}]

set ::env(FP_PIN_ORDER_CFG) $script_dir/pin_order.cfg

# Wakey Wakey Change: Disable PL_BASIC_PLACEMENT, increase PL_TARGET_DENSITY
# set ::env(PL_BASIC_PLACEMENT) 1
# set ::env(PL_TARGET_DENSITY) 0.05
set ::env(PL_BASIC_PLACEMENT) 0
set ::env(PL_TARGET_DENSITY) 0.55

# If you're going to use multiple power domains, then keep this disabled.
set ::env(RUN_CVC) 0

# Wakey Wakey Change: Added to disable the [WARNING PDM-0030] messages in PDN
set ::env(FP_PDN_CHECK_NODES) 0
