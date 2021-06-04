// =============================================================================
// Module:       Word Recognition Top Module
// Design:       Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// =============================================================================

module wrd (
    // clock and reset
    input                                   clk_i,
    input                                   rst_n_i,

    // streaming input
    input  signed [CONV1_VECTOR_BW - 1 : 0] data_i,
    input                                   valid_i,
    input                                   last_i,
    output                                  ready_o,

    // wake pin
    output                                  wake_o,
    output                                  wake_valid,

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
    // input parameters
    localparam I_BW         = 8;
    localparam I_FRAME_LEN  = 50;
    localparam I_VECTOR_LEN = 13;

    // zero_pad1 module parameters
    localparam ZERO_PAD1_BW         = I_BW;         // 8
    localparam ZERO_PAD1_VECTOR_LEN = I_VECTOR_LEN; // 13
    // zero_pad1 helper parameters
    localparam ZERO_PAD1_VECTOR_BW = ZERO_PAD1_BW * ZERO_PAD1_VECTOR_LEN; // 104

    // conv1 module parameters
    localparam CONV1_FRAME_LEN   = I_FRAME_LEN;  // 50
    localparam CONV1_VECTOR_LEN  = I_VECTOR_LEN; // 13
    localparam CONV1_NUM_FILTERS = 8;
    // conv1 helper parameters
    localparam CONV1_BW         = ZERO_PAD1_BW; // 8
    localparam CONV1_FILTER_LEN = 3;
    localparam CONV1_VECTOR_BW  = CONV1_BW * CONV1_VECTOR_LEN; // 104
    // conv1 memory configuration parameters
    localparam CONV1_BANK_BW = $clog2(CONV1_FILTER_LEN + 2); // 3
    localparam CONV1_ADDR_BW = $clog2(CONV1_NUM_FILTERS);    // 3

    // max_pool1 module parameters
    localparam MAX_POOL1_BW = CONV1_BW; // 8

    // conv_sipo module parameters
    localparam CONV_SIPO_BW         = MAX_POOL1_BW;                    // 8
    localparam CONV_SIPO_FRAME_LEN  = $rtoi($ceil(I_FRAME_LEN / 2.0)); // 25
    localparam CONV_SIPO_VECTOR_LEN = CONV1_NUM_FILTERS;               // 8
    // conv_sipo helper parameters
    localparam CONV_SIPO_VECTOR_BW = CONV_SIPO_BW * CONV_SIPO_VECTOR_LEN; // 64

    // zero_pad2 module parameters
    localparam ZERO_PAD2_BW         = I_BW;              // 8
    localparam ZERO_PAD2_VECTOR_LEN = CONV1_NUM_FILTERS; // 8
    // zero_pad2 helper parameters
    localparam ZERO_PAD2_VECTOR_BW = ZERO_PAD2_BW * ZERO_PAD2_VECTOR_LEN; // 128

    // conv2 module parameters
    localparam CONV2_FRAME_LEN   = CONV_SIPO_FRAME_LEN; // 25
    localparam CONV2_VECTOR_LEN  = CONV1_NUM_FILTERS;   // 8
    localparam CONV2_NUM_FILTERS = 16;
    // conv2 helper parameters
    localparam CONV2_BW         = CONV_SIPO_BW;                // 8
    localparam CONV2_FILTER_LEN = 3;
    localparam CONV2_VECTOR_BW  = CONV2_BW * CONV2_VECTOR_LEN; // 64
    // conv2 memory configuration parameters
    localparam CONV2_BANK_BW = $clog2(CONV2_FILTER_LEN + 2); // 3
    localparam CONV2_ADDR_BW = $clog2(CONV2_NUM_FILTERS);    // 4

    // max_pool2 module parameters
    localparam MAX_POOL2_BW        = CONV_SIPO_BW; // 8
    localparam MAX_POOL2_FRAME_LEN = $rtoi($ceil(CONV_SIPO_FRAME_LEN / 2.0)); //13

    // fc module parameters
    localparam FC_I_BW        = I_BW; // 8
    localparam FC_BIAS_BW     = 32;
    localparam FC_O_BW        = 32;
    localparam FC_FRAME_LEN   = MAX_POOL2_FRAME_LEN * CONV2_NUM_FILTERS; // 208
    localparam FC_NUM_CLASSES = 2;
    // fc helper parameters
    localparam FC_VECTOR_O_BW = FC_O_BW * FC_NUM_CLASSES; // 64
    // fc memory configuration parameters
    localparam FC_BANK_BW = $clog2(FC_NUM_CLASSES * 2);
    // TODO: Yosys will not resolve FC_FRAME_LEN, need to hard code
    // localparam FC_ADDR_BW = $clog2(FC_FRAME_LEN);
    localparam FC_ADDR_BW = $clog2(208);

    // argmax module parameters
    localparam ARGMAX_I_BW = FC_O_BW; // 24
    // argmax helper parameters
    localparam ARGMAX_O_BW = FC_NUM_CLASSES;

    // wake module parameters
    localparam WAKE_NUM_CLASSES = FC_NUM_CLASSES; // 2

    // =========================================================================
    // zero_pad1
    // =========================================================================
    wire [ZERO_PAD1_VECTOR_BW - 1 : 0] zero_pad1_data;
    wire                               zero_pad1_valid;
    wire                               zero_pad1_last;

    zero_pad #(
        .BW(ZERO_PAD1_BW),
        .VECTOR_LEN(ZERO_PAD1_VECTOR_LEN)
    ) zero_pad1 (
        // clock and reset
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        // streaming input
        .data_i(data_i),
        .valid_i(valid_i),
        .last_i(last_i),
        .ready_o(ready_o),

        // streaming output
        .data_o(zero_pad1_data),
        .valid_o(zero_pad1_valid),
        .last_o(zero_pad1_last),
        .ready_i(conv1_ready[0])
    );

    // =========================================================================
    // conv1
    // =========================================================================
    wire [CONV1_BW - 1 : 0] conv1_data;
    wire                    conv1_valid;
    wire                    conv1_last;
    wire [0:0]              conv1_ready;

    conv_top #(
        .FRAME_LEN(CONV1_FRAME_LEN),
        .VECTOR_LEN(CONV1_VECTOR_LEN),
        .NUM_FILTERS(CONV1_NUM_FILTERS)
    ) conv1 (
        // clock and reset
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        // streaming input
        .data_i(zero_pad1_data),
        .valid_i(zero_pad1_valid),
        .last_i(zero_pad1_last),
        .ready_o(conv1_ready),

        // streaming output
        .data_o(conv1_data),
        .valid_o(conv1_valid),
        .last_o(conv1_last),
        .ready_i(max_pool1_ready[0]),

        // memory configuration
        .rd_en_i(conv1_rd_en_i),
        .wr_en_i(conv1_wr_en_i),
        .rd_wr_bank_i(conv1_rd_wr_bank_i),
        .rd_wr_addr_i(conv1_rd_wr_addr_i),
        .wr_data_i(conv1_wr_data_i),
        .rd_data_o(conv1_rd_data_o)
    );

    // =========================================================================
    // max_pool1
    // =========================================================================
    wire [MAX_POOL1_BW - 1 : 0] max_pool1_data;
    wire                        max_pool1_valid;
    wire                        max_pool1_last;
    wire [0:0]                  max_pool1_ready;

    max_pool #(
        .BW(MAX_POOL1_BW)
    ) max_pool1 (
        // clock and reset
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        // streaming input
        .data_i(conv1_data),
        .valid_i(conv1_valid),
        .last_i(conv1_last),
        .ready_o(max_pool1_ready),

        // streaming output
        .data_o(max_pool1_data),
        .valid_o(max_pool1_valid),
        .last_o(max_pool1_last),
        .ready_i(conv_sipo_ready[0])
    );

    // =========================================================================
    // conv_sipo
    // =========================================================================
    wire [CONV_SIPO_VECTOR_BW - 1 : 0] conv_sipo_data;
    wire                               conv_sipo_valid;
    wire                               conv_sipo_last;
    wire [0:0]                         conv_sipo_ready;

    conv_sipo #(
        .BW(CONV_SIPO_BW),
        .FRAME_LEN(CONV_SIPO_FRAME_LEN),
        .VECTOR_LEN(CONV_SIPO_VECTOR_LEN)
    ) conv_sipo_inst (
        // clock and reset
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        // streaming input
        .data_i(max_pool1_data),
        .valid_i(max_pool1_valid),
        .last_i(max_pool1_last),
        .ready_o(conv_sipo_ready),

        // streaming output
        .data_o(conv_sipo_data),
        .valid_o(conv_sipo_valid),
        .last_o(conv_sipo_last),
        .ready_i(zero_pad2_ready[0])
    );

    // =========================================================================
    // zero_pad2
    // =========================================================================
    wire [ZERO_PAD2_VECTOR_BW - 1 : 0] zero_pad2_data;
    wire                               zero_pad2_valid;
    wire                               zero_pad2_last;
    wire [0:0]                         zero_pad2_ready;

    zero_pad #(
        .BW(ZERO_PAD2_BW),
        .VECTOR_LEN(ZERO_PAD2_VECTOR_LEN)
    ) zero_pad2 (
        // clock and reset
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        // streaming input
        .data_i(conv_sipo_data),
        .valid_i(conv_sipo_valid),
        .last_i(conv_sipo_last),
        .ready_o(ready_o),

        // streaming output
        .data_o(zero_pad2_data),
        .valid_o(zero_pad2_valid),
        .last_o(zero_pad2_last),
        .ready_i(conv2_ready[0])
    );

    // =========================================================================
    // conv2
    // =========================================================================
    wire [CONV2_BW - 1 : 0] conv2_data;
    wire                    conv2_valid;
    wire                    conv2_last;
    wire [0:0]              conv2_ready;

    conv_top #(
        .FRAME_LEN(CONV2_FRAME_LEN),
        .VECTOR_LEN(CONV2_VECTOR_LEN),
        .NUM_FILTERS(CONV2_NUM_FILTERS)
    ) conv2 (
        // clock and reset
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        // streaming input
        .data_i(zero_pad2_data),
        .valid_i(zero_pad2_valid),
        .last_i(zero_pad2_last),
        .ready_o(conv2_ready),

        // streaming output
        .data_o(conv2_data),
        .valid_o(conv2_valid),
        .last_o(conv2_last),
        .ready_i(max_pool2_ready[0]),

        // memory configuration
        .rd_en_i(conv2_rd_en_i),
        .wr_en_i(conv2_wr_en_i),
        .rd_wr_bank_i(conv2_rd_wr_bank_i),
        .rd_wr_addr_i(conv2_rd_wr_addr_i),
        .wr_data_i(conv2_wr_data_i),
        .rd_data_o(conv2_rd_data_o)
    );

    // =========================================================================
    // max_pool2
    // =========================================================================
    wire [MAX_POOL2_BW - 1 : 0] max_pool2_data;
    wire                        max_pool2_valid;
    wire                        max_pool2_last;
    wire [0:0]                  max_pool2_ready;

    max_pool #(
        .BW(MAX_POOL2_BW)
    ) max_pool2 (
        // clock and reset
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        // streaming input
        .data_i(conv2_data),
        .valid_i(conv2_valid),
        .last_i(conv2_last),
        .ready_o(max_pool2_ready),

        // streaming output
        .data_o(max_pool2_data),
        .valid_o(max_pool2_valid),
        .last_o(max_pool2_last),
        .ready_i(fc_ready[0])
    );

    // =========================================================================
    // fc
    // =========================================================================
    wire [FC_VECTOR_O_BW - 1 : 0] fc_data;
    wire                          fc_valid;
    wire                          fc_last;
    wire [0:0]                    fc_ready;

    fc_top #(
        .I_BW(FC_I_BW),
        .BIAS_BW(FC_BIAS_BW),
        .O_BW(FC_O_BW),
        .FRAME_LEN(FC_FRAME_LEN),
        .NUM_CLASSES(FC_NUM_CLASSES)
    ) fc_inst (
        // clock and reset
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        // streaming input
        .data_i(max_pool2_data),
        .valid_i(max_pool2_valid),
        .last_i(max_pool2_last),
        .ready_o(fc_ready),

        // streaming output
        .data_o(fc_data),
        .valid_o(fc_valid),
        .last_o(fc_last),
        .ready_i(argmax_ready[0]),

        // memory configuration
        .rd_en_i(fc_rd_en_i),
        .wr_en_i(fc_wr_en_i),
        .rd_wr_bank_i(fc_rd_wr_bank_i),
        .rd_wr_addr_i(fc_rd_wr_addr_i),
        .wr_data_i(fc_wr_data_i),
        .rd_data_o(fc_rd_data_o)
    );

    // =========================================================================
    // argmax
    // =========================================================================
    wire [ARGMAX_O_BW - 1 : 0] argmax_data;
    wire                       argmax_valid;
    wire                       argmax_last;
    wire [0:0]                 argmax_ready;

    argmax #(
        .I_BW(ARGMAX_I_BW)
    ) argmax_inst (
        // clock and reset
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        // streaming input
        .data_i(fc_data),
        .valid_i(fc_valid),
        .last_i(fc_last),
        .ready_o(argmax_ready),

        // streaming output
        .data_o(argmax_data),
        .valid_o(argmax_valid),
        .last_o(argmax_last),
        .ready_i(wake_ready[0])
    );

    // =========================================================================
    // wake
    // =========================================================================
    wire [0:0] wake_ready;

    wake #(
        .NUM_CLASSES(WAKE_NUM_CLASSES)
    ) wake_inst (
        // clock and reset
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        // streaming input
        .data_i(argmax_data),
        .valid_i(argmax_valid),
        .last_i(argmax_last),
        .ready_o(wake_ready),

        // wake output
        .wake_o(wake_o),
        .valid_o(wake_valid)
    );

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    `ifndef SCANNED
    `define SCANNED
    initial begin
      $dumpfile ("wave.vcd");
      $dumpvars (0, wrd);
      #1;
    end
    `endif
    `endif

endmodule
