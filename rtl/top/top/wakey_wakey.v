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

    // logic analyzer signals
    input  [127:0] la_data_in_i,
    output [127:0] la_data_out_o,
    input  [127:0] la_oenb_i,

    // microphone i/o
    `ifdef COCOTB_SIM
    input [DFE_OUTPUT_BW - 1 : 0] dfe_data,  // bypass DFE for test bench
    input                         dfe_valid,
    `else
    input           pdm_data_i,
    output          pdm_clk_o,
    `endif
    input           vad_i,  // voice activity detection

    // wake output
    output wake_o_muxed
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
    // CTL - Pipeline control
    // =========================================================================
    wire pipeline_en;
    wire pipeline_en_muxed;
    wire wake_valid;  // driven by WRD
    wire wake_valid_muxed;

    ctl #(
        .F_SYSTEM_CLK(F_SYSTEM_CLK)
    ) ctl_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        .vad_i(vad_i),

        .wake_valid_i(wake_valid_muxed),

        .en_o(pipeline_en)
    );

    // =========================================================================
    // DFE - Digital Front End
    // =========================================================================
    localparam DFE_OUTPUT_BW = 8;

    wire [DFE_OUTPUT_BW - 1 : 0] dfe_data_muxed;
    wire                         dfe_valid_muxed;
    `ifndef COCOTB_SIM
    wire pdm_data_i_muxed;
    wire [DFE_OUTPUT_BW - 1 : 0] dfe_data;
    wire                         dfe_valid;

    dfe dfe_inst (
        // clock, reset, and enable
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(pipeline_en_muxed),

        // pdm input
        .pdm_data_i(pdm_data_i_muxed),

        // pdm clock output
        .pdm_clk_o(pdm_clk_o),

        // streaming output
        .data_o(dfe_data),
        .valid_o(dfe_valid)
    );
    `endif

    // =========================================================================
    // ACO - Acoustic Featurizer
    // =========================================================================
    localparam ACO_OUTPUT_BW = 8 * 13;

    wire [ACO_OUTPUT_BW - 1 : 0] aco_data;
    wire                         aco_valid;
    wire                         aco_last;
    wire [ACO_OUTPUT_BW - 1 : 0] aco_data_muxed;
    wire                         aco_valid_muxed;
    wire                         aco_last_muxed;

    aco aco_inst (
        // clock, reset, and enable
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(pipeline_en_muxed),

        // streaming input
        .data_i(dfe_data_muxed),
        .valid_i(dfe_valid_muxed),

        // streaming output
        .data_o(aco_data),
        .valid_o(aco_valid),
        .last_o(aco_last)
    );

    // =========================================================================
    // WRD - Word Recognition DNN Accelerator Module
    // =========================================================================
    wire wrd_ready;
    wire wake_o;

    wrd wrd_inst (
        // clock and reset
        .clk_i(clk_i),
        .rst_n_i(rst_n_i & pipeline_en_muxed),

        // streaming input
        .data_i(aco_data_muxed),
        .valid_i(aco_valid_muxed),
        .last_i(aco_last_muxed),
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
    // DBG - Debug Logic Analyzer
    // =========================================================================
    dbg #(
        .DFE_OUTPUT_BW(DFE_OUTPUT_BW),
        .ACO_OUTPUT_BW(ACO_OUTPUT_BW)
    ) dbg_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        .la_data_in_i(la_data_in_i),
        .la_data_out_o(la_data_out_o),
        .la_oenb_i(la_oenb_i),

        // ctl
        .ctl_pipeline_en_i(pipeline_en),
        .ctl_pipeline_en_o(pipeline_en_muxed),

        `ifndef COCOTB_SIM
        // mic -> dfe
        .mic_pdm_data_i(pdm_data_i),
        .mic_pdm_data_o(pdm_data_i_muxed),
        `endif

        // dfe -> aco
        .dfe_data_i(dfe_data),
        .dfe_valid_i(dfe_valid),
        .dfe_data_o(dfe_data_muxed),
        .dfe_valid_o(dfe_valid_muxed),

        // aco -> wrd
        .aco_data_i(aco_data),
        .aco_valid_i(aco_valid),
        .aco_last_i(aco_last),
        .aco_data_o(aco_data_muxed),
        .aco_valid_o(aco_valid_muxed),
        .aco_last_o(aco_last_muxed),

        // wrd -> wake
        .wrd_wake_i(wake_o),
        .wrd_wake_valid_i(wake_valid),
        .wrd_wake_o(wake_o_muxed),
        .wrd_wake_valid_o(wake_valid_muxed)
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
