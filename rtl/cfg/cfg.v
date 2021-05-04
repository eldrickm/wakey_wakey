// =============================================================================
// Module:       Configuration
// Design:       Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// User address space goes from 0x3000_0000 to 0x7FFF_FFFF
// =============================================================================

module cfg #(
    parameter CONV1_BANK_BW = 3,
    parameter CONV1_ADDR_BW = 3,
    parameter CONV1_VECTOR_BW = 104,
    parameter CONV2_BANK_BW = 3,
    parameter CONV2_ADDR_BW = 4,
    parameter CONV2_VECTOR_BW = 64,
    parameter FC_BANK_BW = 4,
    parameter FC_ADDR_BW = 8,
    parameter FC_BIAS_BW = 32,
    parameter WISHBONE_BASE_ADDR = 32'h30000000
)(
    // wishbone slave ports (wb mi a)
    input                                   wb_clk_i,
    input                                   wb_rst_i,
    input                                   wbs_stb_i,
    input                                   wbs_cyc_i,
    input                                   wbs_we_i,
    input         [3  : 0]                  wbs_sel_i,
    input         [31 : 0]                  wbs_dat_i,
    input         [31 : 0]                  wbs_adr_i,
    output                                  wbs_ack_o,
    output        [31 : 0]                  wbs_dat_o,

    // conv1 memory configuration
    input                                   conv1_rd_en_i,
    input                                   conv1_wr_en_i,
    input         [CONV1_BANK_BW - 1 : 0]   conv1_rd_wr_bank_i,
    input         [CONV1_ADDR_BW - 1 : 0]   conv1_rd_wr_addr_i,
    input  signed [CONV1_VECTOR_BW - 1 : 0] conv1_wr_data_i,
    output signed [CONV1_VECTOR_BW - 1 : 0] conv1_rd_data_o,

    // conv2 memory configuration
    input                                   conv2_rd_en_i,
    input                                   conv2_wr_en_i,
    input         [CONV2_BANK_BW - 1 : 0]   conv2_rd_wr_bank_i,
    input         [CONV2_ADDR_BW - 1 : 0]   conv2_rd_wr_addr_i,
    input  signed [CONV2_VECTOR_BW - 1 : 0] conv2_wr_data_i,
    output signed [CONV2_VECTOR_BW - 1 : 0] conv2_rd_data_o,

    // fc memory configuration
    input                                   fc_rd_en_i,
    input                                   fc_wr_en_i,
    input         [FC_BANK_BW - 1 : 0]      fc_rd_wr_bank_i,
    input         [FC_ADDR_BW - 1 : 0]      fc_rd_wr_addr_i,
    input  signed [FC_BIAS_BW - 1 : 0]      fc_wr_data_i,
    output signed [FC_BIAS_BW - 1 : 0]      fc_rd_data_o
);
    // =========================================================================
    // Local Parameters
    // =========================================================================

    reg [31 : 0] cfg_data [3 : 0];
    reg [31 : 0] cfg_addr; 
    reg [31 : 0] cfg_ctrl;

    // handle data / addr / ctrl register writing from wishbone bus

    // handle data / addr / ctrl register reading from wishbone bus

    // ctrl should be self clearing

    // handle store instruction

    // handle load instruction

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    initial begin
      $dumpfile ("wave.vcd");
      $dumpvars (0, cfg);
      #1;
    end
    `endif

endmodule
