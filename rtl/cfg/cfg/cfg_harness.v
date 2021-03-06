// =============================================================================
// Module:       Wakey Wakey
// Design:       Eldrick Millares & Matthew Pauly
// Verification: Eldrick Millares & Matthew Pauly
// Notes:
// =============================================================================

module wakey_wakey (
    // clock and reset
    input           clk_i,
    input           rst_n_i,

    // wishbone slave ports (wb mi a)
    input           wbs_stb_i,
    input           wbs_cyc_i,
    input           wbs_we_i,
    input  [3  : 0] wbs_sel_i,
    input  [31 : 0] wbs_dat_i,
    input  [31 : 0] wbs_adr_i,
    output          wbs_ack_o,
    output [31 : 0] wbs_dat_o,

    // test harness
    input [CONV1_VECTOR_BW - 1 : 0] data_i,
    input valid_i,
    input last_i,

    // wake output
    output wake_o
);
    localparam F_SYSTEM_CLK = 16000000;

    // =========================================================================
    // CFG - System Configuration
    // =========================================================================
    localparam CONV1_BANK_BW = 3;
    localparam CONV1_ADDR_BW = 3;
    localparam CONV1_VECTOR_BW = 104;
    localparam CONV2_BANK_BW = 3;
    localparam CONV2_ADDR_BW = 4;
    localparam CONV2_VECTOR_BW = 64;
    localparam FC_BANK_BW = 2;
    localparam FC_ADDR_BW = 8;
    localparam FC_BIAS_BW = 32;
    localparam WISHBONE_BASE_ADDR = 32'h30000000;

    // conv1 memory configuration
    wire                                  conv1_rd_en;
    wire                                  conv1_wr_en;
    wire        [CONV1_BANK_BW - 1 : 0]   conv1_rd_wr_bank;
    wire        [CONV1_ADDR_BW - 1 : 0]   conv1_rd_wr_addr;
    wire signed [CONV1_VECTOR_BW - 1 : 0] conv1_wr_data;
    wire signed [CONV1_VECTOR_BW - 1 : 0] conv1_rd_data;

    // conv2 memory configuration
    wire                                  conv2_rd_en;
    wire                                  conv2_wr_en;
    wire        [CONV2_BANK_BW - 1 : 0]   conv2_rd_wr_bank;
    wire        [CONV2_ADDR_BW - 1 : 0]   conv2_rd_wr_addr;
    wire signed [CONV2_VECTOR_BW - 1 : 0] conv2_wr_data;
    wire signed [CONV2_VECTOR_BW - 1 : 0] conv2_rd_data;

    // fc memory configuration
    wire                                  fc_rd_en;
    wire                                  fc_wr_en;
    wire        [FC_BANK_BW - 1 : 0]      fc_rd_wr_bank;
    wire        [FC_ADDR_BW - 1 : 0]      fc_rd_wr_addr;
    wire signed [FC_BIAS_BW - 1 : 0]      fc_wr_data;
    wire signed [FC_BIAS_BW - 1 : 0]      fc_rd_data;

    cfg #(
        .CONV1_BANK_BW(CONV1_BANK_BW),
        .CONV1_ADDR_BW(CONV1_ADDR_BW),
        .CONV1_VECTOR_BW(CONV1_VECTOR_BW),
        .CONV2_BANK_BW(CONV2_BANK_BW),
        .CONV2_ADDR_BW(CONV2_ADDR_BW),
        .CONV2_VECTOR_BW(CONV2_VECTOR_BW),
        .FC_BANK_BW(FC_BANK_BW),
        .FC_ADDR_BW(FC_ADDR_BW),
        .FC_BIAS_BW(FC_BIAS_BW),
        .WISHBONE_BASE_ADDR(WISHBONE_BASE_ADDR)
    ) cfg_inst (
        // clock and reset
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        // wishbone slave ports (wb mi a)
        .wbs_stb_i(wbs_stb_i),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ack_o),
        .wbs_dat_o(wbs_dat_o),

        // conv1 memory configuration
        .conv1_rd_en_o(conv1_rd_en),
        .conv1_wr_en_o(conv1_wr_en),
        .conv1_rd_wr_bank_o(conv1_rd_wr_bank),
        .conv1_rd_wr_addr_o(conv1_rd_wr_addr),
        .conv1_wr_data_o(conv1_wr_data),
        .conv1_rd_data_i(conv1_rd_data),

        // conv2 memory configuration
        .conv2_rd_en_o(conv2_rd_en),
        .conv2_wr_en_o(conv2_wr_en),
        .conv2_rd_wr_bank_o(conv2_rd_wr_bank),
        .conv2_rd_wr_addr_o(conv2_rd_wr_addr),
        .conv2_wr_data_o(conv2_wr_data),
        .conv2_rd_data_i(conv2_rd_data),

        // fc memory configuration
        .fc_rd_en_o(fc_rd_en),
        .fc_wr_en_o(fc_wr_en),
        .fc_rd_wr_bank_o(fc_rd_wr_bank),
        .fc_rd_wr_addr_o(fc_rd_wr_addr),
        .fc_wr_data_o(fc_wr_data),
        .fc_rd_data_i(fc_rd_data)
    );


    // =========================================================================
    // WRD - Word Recognition DNN Accelerator Module
    // =========================================================================
    wire wrd_ready;
    wire wake_valid;

    wrd wrd_inst (
        // clock and reset
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        // streaming input
        .data_i(data_i),
        .valid_i(valid_i),
        .last_i(last_i),
        .ready_o(wrd_ready),

        // wake pin
        .wake_o(wake_o),
        .wake_valid(wake_valid),

        // conv1 memory configuration
        .conv1_rd_en_i(conv1_rd_en),
        .conv1_wr_en_i(conv1_wr_en),
        .conv1_rd_wr_bank_i(conv1_rd_wr_bank),
        .conv1_rd_wr_addr_i(conv1_rd_wr_addr),
        .conv1_wr_data_i(conv1_wr_data),
        .conv1_rd_data_o(conv1_rd_data),

        // conv2 memory configuration
        .conv2_rd_en_i(conv2_rd_en),
        .conv2_wr_en_i(conv2_wr_en),
        .conv2_rd_wr_bank_i(conv2_rd_wr_bank),
        .conv2_rd_wr_addr_i(conv2_rd_wr_addr),
        .conv2_wr_data_i(conv2_wr_data),
        .conv2_rd_data_o(conv2_rd_data),

        // fc memory configuration
        .fc_rd_en_i(fc_rd_en),
        .fc_wr_en_i(fc_wr_en),
        .fc_rd_wr_bank_i(fc_rd_wr_bank),
        .fc_rd_wr_addr_i(fc_rd_wr_addr),
        .fc_wr_data_i(fc_wr_data),
        .fc_rd_data_o(fc_rd_data)
    );

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    `ifndef SCANNED
    `define SCANNED
    initial begin
      $dumpfile ("wave.vcd");
      $dumpvars (0, wakey_wakey);
      #1;
    end
    `endif
    `endif

endmodule
