// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

// `ifndef MPRJ_IO_PADS
    `define MPRJ_IO_PADS 38
// `endif
/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * TODO: Write Description
 *-------------------------------------------------------------
 */

module user_proj_example (
`ifdef USE_POWER_PINS
    // inout vdda1,	// User area 1 3.3V supply
    // inout vdda2,	// User area 2 3.3V supply
    // inout vssa1,	// User area 1 analog ground
    // inout vssa2,	// User area 2 analog ground
    inout vccd1,	// User area 1 1.8V supply
    inout vccd2,	// User area 2 1.8v supply
    inout vssd1,	// User area 1 digital ground
    inout vssd2,	// User area 2 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output [2:0] irq
);

    // =========================================================================
    // Wakey Wakey External I/O Declarations
    // =========================================================================
    wire wake;
    wire pdm_data;
    wire pdm_clk;
    wire vad;

    // =========================================================================
    // Wakey Wakey Inputs
    // =========================================================================
    assign pdm_data = io_in[36];
    assign vad = io_in[34];

    // =========================================================================
    // Wakey Wakey Instantiation
    // =========================================================================
    wakey_wakey wakey_wakey_inst (
        // clock and reset
        .clk_i(wb_clk_i),
        .rst_n_i(~wb_rst_i),

        // wishbone slave ports (wb mi a)
        .wbs_stb_i(wbs_stb_i),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ack_o),
        .wbs_dat_o(wbs_dat_o),

        // microphone i/o
        .pdm_data_i(pdm_data),
        .pdm_clk_o(pdm_clk),
        .vad_i(vad),

        // wake output
        .wake_o(wake)
    );

    // =========================================================================
    // Pin DIrections (Output Enable)
    // =========================================================================
    assign io_oeb[37] = 1'b1;       // wake_o
    assign io_oeb[36] = 1'b0;       // pdm_data_i
    assign io_oeb[35] = 1'b1;       // pdm_clk_o
    assign io_oeb[34] = 1'b0;       // vad_i
    assign io_oeb[33:0] = 34'b0;    // unused

    // =========================================================================
    // Wakey Wakey Outputs
    // =========================================================================
    assign io_out[37] = wake;       // wake_o
    assign io_out[36] = 1'b0;       // pdm_data_i
    assign io_out[35] = pdm_clk;    // pdm_clk_o
    assign io_out[34] = 1'b0;       // vad_i
    assign io_out[33:0] = 34'b0;    // unused


    // =========================================================================
    // IRQ
    // =========================================================================
    assign irq = 3'b000;            // unused

    // =========================================================================
    // Logic Analyzer Outputs
    // =========================================================================
    assign la_data_out = 128'b0;    // unused

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    `ifndef SCANNED
    `define SCANNED
    initial begin
      $dumpfile ("wave.vcd");
      $dumpvars (0, user_proj_example);
      #1;
    end
    `endif
    `endif

endmodule
