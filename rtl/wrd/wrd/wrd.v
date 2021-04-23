// =============================================================================
// Module:       Word Recognition Top Module
// Design:       Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// =============================================================================

module wrd #(
    parameter BW = 8,
    parameter CONV1_FRAME_LEN   = 50,
    parameter CONV1_VECTOR_LEN  = 13,
    parameter CONV1_NUM_FILTERS = 8,
    parameter CONV2_FRAME_LEN   = 25,
    parameter CONV2_VECTOR_LEN  = 8,
    parameter CONV2_NUM_FILTERS = 16,
    parameter FC_NUM_CLASSES    = 3
) (
    // clock and reset
    input                             clk_i,
    input                             rst_n_i,

    // streaming input
    input  signed [CONV1_VECTOR_BW - 1 : 0] data_i,
    input                                   valid_i,
    input                                   last_i,
    output                                  ready_o,

    // wake pin
    output                            wake_o,

    // memory configuration
    input                             rd_en_i,
    input                             wr_en_i,
    input         [BANK_BW - 1 : 0]   rd_wr_bank_i,
    input         [ADDR_BW - 1 : 0]   rd_wr_addr_i,
    input  signed [VECTOR_BW - 1 : 0] wr_data_i,
    output signed [VECTOR_BW - 1 : 0] rd_data_o
);
    // =========================================================================
    // Local Parameters
    // =========================================================================
    localparam CONV1_VECTOR_BW = BW * CONV1_VECTOR_LEN;
    localparam CONV2_VECTOR_BW = BW * CONV1_VECTOR_LEN;

    localparam MAX_POOL1_FRAME_LEN = CONV1_FRAME_LEN / 2;
    localparam MAX_POOL2_FRAME_LEN = CONV2_FRAME_LEN / 2;

    // =========================================================================
    // zero_pad1
    // =========================================================================
    wire [CONV1_VECTOR_BW- 1 : 0] zero_pad1_data;
    wire                          zero_pad1_valid;
    wire                          zero_pad1_last;

    zero_pad #(
        .BW(BW),
        .VECTOR_LEN(CONV1_VECTOR_LEN)
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
        .last_o(zero_pad1_valid),
        .ready_i(conv1_ready[0])
    );

    // =========================================================================
    // conv1
    // =========================================================================
    wire [BW - 1 : 0] conv1_data;
    wire              conv1_valid;
    wire              conv1_last;
    wire [0]          conv1_ready;

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
        .rd_en_i(),
        .wr_en_i(),
        .rd_wr_bank_i(),
        .rd_wr_addr_i(),
        .wr_data_i(),
        .rd_data_o()
    );

    // =========================================================================
    // max_pool1
    // =========================================================================
    wire [BW - 1 : 0] max_pool1_data;
    wire              max_pool1_valid;
    wire              max_pool1_last;
    wire [0]          max_pool1_ready;

    max_pool #(
        .BW(BW)
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
        .ready_i(conv_sipo_ready)
    );

    // =========================================================================
    // conv_sipo
    // =========================================================================
    conv_sipo #(
        .BW(BW),
        .FRAME_LEN(MAX_POOL1_FRAME_LEN),
        .VECTOR_LEN(CONV2_VECTOR_LEN)
    ) conv_sipo_inst (
        // clock and reset
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        // streaming input
        .data_i(),
        .valid_i(),
        .last_i(),
        .ready_o(),
     
        // streaming output
        .data_o(),
        .valid_o(),
        .last_o(),
        .ready_i()
    );

    // =========================================================================
    // zero_pad2
    // =========================================================================

    // =========================================================================
    // conv2
    // =========================================================================
    wire [BW - 1 : 0] conv2_data;
    wire              conv2_valid;
    wire              conv2_last;

    conv_top #(
        .FRAME_LEN(CONV2_FRAME_LEN),
        .VECTOR_LEN(CONV2_VECTOR_LEN),
        .NUM_FILTERS(CONV2_NUM_FILTERS)
    ) conv2 (
        // clock and reset
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        // streaming input
        .data_i(data_i),
        .valid_i(valid_i),
        .last_i(last_i),
        .ready_o(ready_o),

        // streaming output
        .data_o(conv2_data),
        .valid_o(conv2_valid),
        .last_o(conv2_last),
        .ready_i(max_pool2_ready[0]),

        // memory configuration
        .rd_en_i(),
        .wr_en_i(),
        .rd_wr_bank_i(),
        .rd_wr_addr_i(),
        .wr_data_i(),
        .rd_data_o()
    );

    // =========================================================================
    // max_pool2
    // =========================================================================
    wire [BW - 1 : 0] max_pool2_data;
    wire              max_pool2_valid;
    wire              max_pool2_last;
    wire [0]          max_pool2_ready;

    max_pool #(
        .BW(BW)
    ) max_pool1 (
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
        .ready_i(fc)
    );

    // =========================================================================
    // fc
    // =========================================================================

    // =========================================================================
    // argmax
    // =========================================================================

    // =========================================================================
    // wake
    // =========================================================================
    wake #(
        .NUM_CLASSES(FC_NUM_CLASSES)
    ) wake_inst (
        // clock and reset
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        // streaming input
        .data_i(),
        .valid_i(),
        .last_i(),
        .ready_o(),

        // wake output
        .wake_o(wake_o)
    );

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    initial begin
      $dumpfile ("wave.vcd");
      $dumpvars (0, wrd);
      #1;
    end
    `endif

endmodule
