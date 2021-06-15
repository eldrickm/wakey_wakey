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

#include "wrd_params.h"

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
    // INFO: Currently need to wait one clock cycle before read starts
    __asm__("nop\n\t");

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
 
// void cfg_store(int addr, int data_3, int data_2, int data_1, int data_0)
// void cfg_load(int addr, int *data)
bool check_output(int *expected, int *observed) {
    for (int k = 0; k < 4; k++) {
        if (expected[k] != observed[k]) return false;
    }
    return true;
}

void mult_arr(int *arr) {
    for (int k = 0; k < 4; k++) {
        arr[k] *= 2;
    }
}

/* Returns true if the test passes and false if not. */
bool run_test() {
    // return false;
    int readbuf[4] = {0,0,0,0};

    // /*
    // simple test
    int writebuf[4] = {1, 3, 4, 2};
    cfg_store(0, writebuf[3], writebuf[2], writebuf[1], writebuf[0]);
    cfg_store(1, writebuf[3]*2, writebuf[2]*2, writebuf[1]*2, writebuf[0]*2);
    cfg_store(2, writebuf[3]*4, writebuf[2]*4, writebuf[1]*4, writebuf[0]*4);
    cfg_store(3, writebuf[3]*8, writebuf[2]*8, writebuf[1]*8, writebuf[0]*8);
    // cfg_store(4, writebuf[3]*5, writebuf[2]*5, writebuf[1]*5, writebuf[0]*5);
    // cfg_store(5, writebuf[3]*6, writebuf[2]*6, writebuf[1]*6, writebuf[0]*6);
    // cfg_store(6, writebuf[3]*7, writebuf[2]*7, writebuf[1]*7, writebuf[0]*7);
    // cfg_store(7, writebuf[3]*8, writebuf[2]*8, writebuf[1]*8, writebuf[0]*8);

    cfg_load(0, readbuf);
    if (!check_output(writebuf, readbuf)) return false;

    cfg_load(1, readbuf);
    mult_arr(writebuf);
    if (!check_output(writebuf, readbuf)) return false;

    cfg_load(2, readbuf);
    mult_arr(writebuf);
    if (!check_output(writebuf, readbuf)) return false;

    // return true;
    // return check_output(writebuf, readbuf);
    // */

    int expected[4];

    // WRITING

    // Sequential write to conv1 memory banks
    // for (int j = 0; j < 4; j++) {  // banks
    for (int j = 0; j < 1; j++) {  // banks
        for (int k = 0; k < 8; k++) {
            cfg_store(k + j*0x10, k+3, k+2, k+1, k+0);
        }
    }
    int k = 7;
    cfg_store(0x40, k+3, k+2, k+1, k+0);  // shift

    /*
    // Sequential write to conv2 memory banks
    for (int j = 5; j < 9; j++) {  // banks
        for (int k = 0; k < 8; k++) {
            cfg_store(k + j*0x10, k+3, k+2, k+1, k+0);
        }
    }
    k = 7;
    cfg_store(0x90, k+3, k+2, k+1, k+0);  // shift

    // Sequential write to FC memory banks
    for (int j = 0x100; j < 0x300; j += 0x100) {
        for (int k = 0; k < 208; k++) {
            cfg_store(j, k+3, k+2, k+1, k+0);
        }
    }
    k = 207;
    cfg_store(0x300, k+3, k+2, k+1, k+0);  // bias
    cfg_store(0x400, k+3, k+2, k+1, k+0);  // bias
    */
    
    // READING

    // for (int j = 0; j < 4; j++) {  // banks
    for (int j = 0; j < 1; j++) {  // banks
        for (int k = 0; k < 8; k++) {
            // int expected[4] = {k+3, k+2, k+1, k+0};
            int expected[4] = {k, k+1, k+2, k+3};
            cfg_load(k + j*0x10, readbuf);
            if (!check_output(expected, readbuf)) return false;
        }
    }
    // int expected[4] = {k+3, k+2, k+1, k+0};
    // k = 7;
    // cfg_load(0x40, k+3, k+2, k+1, k+0);  // shift

    return true;  // didn't fail earlier
    // return false;  // test that returning false actually fails the test bench
}

/* Test the logic analyzer using the waveforms. Hardcode la_data_out to 'h7777777...
 * in user_project_wrapper.
 */
void la_test() {
    // reg_la2_oenb = reg_la2_iena = 0xFFFFFFFF;    // [95:64]
    reg_la0_oenb = reg_la0_iena = 0x0;  // OUTPUT
    reg_la1_oenb = reg_la1_iena = 0x0;
    reg_la2_oenb = reg_la2_iena = 0x0;
    reg_la3_oenb = reg_la3_iena = 0x0;
    reg_la0_data = 0xAAAAAAAA;
    reg_la1_data = 0xAAAAAAAA;
    reg_la2_data = 0xAAAAAAAA;
    reg_la3_data = 0xAAAAAAAA;

    reg_la1_oenb = reg_la1_iena = 0xFFFFFFFF;  // INPUT
    int read = reg_la1_data;   // READ DATA
    reg_la3_data = read;   // WRITE ON REG 3
    reg_la1_oenb = reg_la1_iena = 0x0;

}

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

    reg_mprj_io_31 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_30 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_29 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_28 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_27 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_26 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_25 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_24 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_23 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_22 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_21 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_20 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_19 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_18 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_17 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_16 = GPIO_MODE_MGMT_STD_OUTPUT;

     /* Apply configuration */
    reg_mprj_xfer = 1;
    while (reg_mprj_xfer == 1) {}

    la_test();


    // Flag start of the test
    reg_mprj_datal = 0xAB600000;

    // reg_mprj_datal = 0xAB610000;  // test success condition
    /*
    reg_mprj_slave = 0x00002710;
    if (reg_mprj_slave == 0x2752) {
        reg_mprj_datal = 0xAB610000;
    } else {
        reg_mprj_datal = 0xAB600000;
    }
    */
    if (run_test()) reg_mprj_datal = 0xAB610000;
    else            reg_mprj_datal = 0xAB620000;  // notify verilog tb
}
