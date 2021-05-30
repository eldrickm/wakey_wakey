/*
 * SPDX-FileCopyrightText: 2020 Efabless Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * SPDX-License-Identifier: Apache-2.0
 */

// This include is relative to $CARAVEL_PATH (see Makefile)
#include "verilog/dv/caravel/defs.h"
#include "verilog/dv/caravel/stub.c"

// Define Wishbone Addresses in CFG
#define cfg_reg_addr   (*(volatile uint32_t*)0x30000000)
#define cfg_reg_ctrl   (*(volatile uint32_t*)0x30000004)
#define cfg_reg_data_0 (*(volatile uint32_t*)0x30000008)
#define cfg_reg_data_1 (*(volatile uint32_t*)0x3000000C)
#define cfg_reg_data_2 (*(volatile uint32_t*)0x30000010)
#define cfg_reg_data_3 (*(volatile uint32_t*)0x30000014)

void cfg_store(int addr, int data_3, int data_2, int data_1, int data_0)
{
    /*
     * Store to Wakey Wakey Memory
     * addr is a 32b address in the Wakey Wakey address space
     * data_3 MSB
     * data_2 
     * data_1 
     * data_0 LSB
     */

    // write the store address
    cfg_reg_addr = addr;
    // write data words
    cfg_reg_data_0 = data_0;
    cfg_reg_data_1 = data_1;
    cfg_reg_data_2 = data_2;
    cfg_reg_data_3 = data_3;
    // write store command - 0x1
    cfg_reg_ctrl = 0x1;
}

void cfg_load(int addr, int *data)
{
    /*
     * Load from Wakey Wakey Memory
     * addr is a 32b address in the Wakey Wakey address space
     * returns a list of values into data
     * where data[3] is the MSB (data_3) and data[0] is the LSB (data_0)
     */

    // write address the load address
    cfg_reg_addr = addr;
    // write the load command - 0x2
    cfg_reg_ctrl = 0x2;
    // TODO: Currently need to wait one clock cycle before read starts - fix?

    // read the data words
    data[0] = cfg_reg_data_0;
    data[1] = cfg_reg_data_1;
    data[2] = cfg_reg_data_2;
    data[3] = cfg_reg_data_3;
}

/*
	Wakey Wakey Test:
        1. Configure PDM Data Input Pin
        2. Configure PDM Activate Input Pin
        3. Configure PDM Clock Output Pin
        4. Configure Wake Output Pin
        5. Write CFG Data via wishbone
        6. Read CFG Data via wishbone
*/
int i = 0; 
int clk = 0;

void main()
{

	/* 
	IO Control Registers
	| DM     | VTRIP | SLOW  | AN_POL | AN_SEL | AN_EN | MOD_SEL | INP_DIS | HOLDH | OEB_N | MGMT_EN |
	| 3-bits | 1-bit | 1-bit | 1-bit  | 1-bit  | 1-bit | 1-bit   | 1-bit   | 1-bit | 1-bit | 1-bit   |
	Output: 0000_0110_0000_1110  (0x1808) = GPIO_MODE_USER_STD_OUTPUT
	| DM     | VTRIP | SLOW  | AN_POL | AN_SEL | AN_EN | MOD_SEL | INP_DIS | HOLDH | OEB_N | MGMT_EN |
	| 110    | 0     | 0     | 0      | 0      | 0     | 0       | 1       | 0     | 0     | 0       |
	
	 
	Input: 0000_0001_0000_1111 (0x0402) = GPIO_MODE_USER_STD_INPUT_NOPULL
	| DM     | VTRIP | SLOW  | AN_POL | AN_SEL | AN_EN | MOD_SEL | INP_DIS | HOLDH | OEB_N | MGMT_EN |
	| 001    | 0     | 0     | 0      | 0      | 0     | 0       | 0       | 0     | 1     | 0       |
	*/

	/* Set up the housekeeping SPI to be connected internally so	*/
	/* that external pin changes don't affect it.			*/

	reg_spimaster_config = 0xa002;	// Enable, prescaler = 2,
                                        // connect to housekeeping SPI

	// Connect the housekeeping SPI to the SPI master
	// so that the CSB line is not left floating.  This allows
	// all of the GPIO pins to be used for user functions.

    /* reg_mprj_io_31 = GPIO_MODE_MGMT_STD_OUTPUT; */
    /* reg_mprj_io_30 = GPIO_MODE_MGMT_STD_OUTPUT; */
    /* reg_mprj_io_29 = GPIO_MODE_MGMT_STD_OUTPUT; */
    /* reg_mprj_io_28 = GPIO_MODE_MGMT_STD_OUTPUT; */
    /* reg_mprj_io_27 = GPIO_MODE_MGMT_STD_OUTPUT; */
    /* reg_mprj_io_26 = GPIO_MODE_MGMT_STD_OUTPUT; */
    /* reg_mprj_io_25 = GPIO_MODE_MGMT_STD_OUTPUT; */
    /* reg_mprj_io_24 = GPIO_MODE_MGMT_STD_OUTPUT; */
    /* reg_mprj_io_23 = GPIO_MODE_MGMT_STD_OUTPUT; */
    /* reg_mprj_io_22 = GPIO_MODE_MGMT_STD_OUTPUT; */
    /* reg_mprj_io_21 = GPIO_MODE_MGMT_STD_OUTPUT; */
    /* reg_mprj_io_20 = GPIO_MODE_MGMT_STD_OUTPUT; */
    /* reg_mprj_io_19 = GPIO_MODE_MGMT_STD_OUTPUT; */
    /* reg_mprj_io_18 = GPIO_MODE_MGMT_STD_OUTPUT; */
    /* reg_mprj_io_17 = GPIO_MODE_MGMT_STD_OUTPUT; */
    /* reg_mprj_io_16 = GPIO_MODE_MGMT_STD_OUTPUT; */

     /* Apply configuration */
    /* reg_mprj_xfer = 1; */
    /* while (reg_mprj_xfer == 1); */

	/* reg_la2_oenb = reg_la2_iena = 0xFFFFFFFF;    // [95:64] */

    // Flag start of the test
	reg_mprj_datal = 0xAB600000;

    reg_mprj_slave = 0x00002710;
    if (reg_mprj_slave == 0x2752) {
        reg_mprj_datal = 0xAB610000;
    } else {
        reg_mprj_datal = 0xAB600000;
    }
}
