// =============================================================================
// Module:       1D Convolution
// Design:       Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// Constraint: FRAME_LEN > FILTER_LEN
// Constraint: FILTER_LEN == 3
// TODO: Deal with ready's / backpressure
// =============================================================================

module conv_top #(
    parameter FRAME_LEN   = 50,  // output frame length
    parameter VECTOR_LEN  = 13,
    parameter NUM_FILTERS = 8
) (
    // clock and reset
    input                             clk_i,
    input                             rst_n_i,

    // streaming input
    input  signed [VECTOR_BW - 1 : 0] data_i,
    input                             valid_i,
    input                             last_i,
    output                            ready_o,

    // streaming output
    output signed [BW - 1 : 0]        data_o,
    output                            valid_o,
    output                            last_o,
    input                             ready_i,

    // memory configuration
    input                             rd_en_i,
    input                             wr_en_i,
    input         [BANK_BW - 1 : 0]   rd_wr_bank_i,
    input         [ADDR_BW - 1 : 0]   rd_wr_addr_i,
    input  signed [VECTOR_BW - 1 : 0] wr_data_i,
    output signed [VECTOR_BW - 1 : 0] rd_data_o
);

    genvar i;

    // =========================================================================
    // Local Parameters
    // =========================================================================
    localparam FILTER_LEN = 3;
    localparam MAX_CYCLES = NUM_FILTERS * FRAME_LEN;

    // bitwidth definitions
    localparam BW                = 8;
    localparam MUL_BW            = 16;
    localparam ADD_BW            = 18;
    localparam BIAS_BW           = 32;
    localparam VECTOR_BW         = VECTOR_LEN * BW;
    localparam MUL_VECTOR_BW     = VECTOR_LEN * MUL_BW;
    localparam ADD_VECTOR_BW     = VECTOR_LEN * ADD_BW;
    localparam ADDR_BW           = $clog2(NUM_FILTERS);
    localparam BANK_BW           = $clog2(FILTER_LEN + 2);
    localparam FRAME_COUNTER_BW  = $clog2(FRAME_LEN);
    localparam FILTER_COUNTER_BW = $clog2(NUM_FILTERS);
    localparam SHIFT_BW          = $clog2(BIAS_BW);

    // =========================================================================
    // Recycler
    // =========================================================================
    wire [VECTOR_BW - 1 : 0] recycler_data0;
    wire [VECTOR_BW - 1 : 0] recycler_data1;
    wire [VECTOR_BW - 1 : 0] recycler_data2;
    wire                     recycler_valid;
    wire                     recycler_last;
    wire                     recycler_ready;

    recycler #(
        .BW(BW),
        .FRAME_LEN(FRAME_LEN),
        .VECTOR_LEN(VECTOR_LEN),
        .NUM_FILTERS(NUM_FILTERS)
    ) recycler_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        .data_i(data_i),
        .valid_i(valid_i),
        .last_i(last_i),
        .ready_o(recycler_ready),

        .data0_o(recycler_data0),
        .data1_o(recycler_data1),
        .data2_o(recycler_data2),
        .valid_o(recycler_valid),
        .last_o(recycler_last),
        .ready_i(vec_mul_ready0[0])
    );

    reg [VECTOR_BW - 1 : 0] recycler_data_q [FILTER_LEN - 1 : 0];
    reg                     recycler_valid_q;
    reg                     recycler_last_q;

    always @(posedge clk_i) begin
        recycler_data_q[0] <= recycler_data0;
        recycler_data_q[1] <= recycler_data1;
        recycler_data_q[2] <= recycler_data2;
        recycler_valid_q   <= recycler_valid;
        recycler_last_q    <= recycler_last;
    end

    // =========================================================================
    // Parameter Memory
    // =========================================================================
    wire [VECTOR_BW - 1 : 0] conv_mem_weight [FILTER_LEN - 1 : 0];
    wire [BIAS_BW - 1 : 0]   conv_mem_bias;
    wire [SHIFT_BW - 1 : 0]  conv_mem_shift;
    wire                     conv_mem_valid;
    wire                     conv_mem_last;

    conv_mem #(
        .BW(BW),
        .BIAS_BW(BIAS_BW),
        .SHIFT_BW(SHIFT_BW),
        .FRAME_LEN(FRAME_LEN),
        .VECTOR_LEN(VECTOR_LEN),
        .NUM_FILTERS(NUM_FILTERS)
    ) conv_mem_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        .cycle_en_i(recycler_valid),

        .rd_en_i(rd_en_i),
        .wr_en_i(wr_en_i),
        .rd_wr_bank_i(rd_wr_bank_i),
        .rd_wr_addr_i(rd_wr_addr_i),
        .wr_data_i(wr_data_i),
        .rd_data_o(rd_data_o),

        .data0_o(conv_mem_weight[0]),
        .data1_o(conv_mem_weight[1]),
        .data2_o(conv_mem_weight[2]),
        .bias_o(conv_mem_bias),
        .shift_o(conv_mem_shift),
        .valid_o(conv_mem_valid),
        .last_o(conv_mem_last),
        .ready_i(vec_mul_ready1[0])
    );

    // Delay the bias term to align with the output of the multipliers,
    // vector addition, and reduction addition
    reg [BIAS_BW - 1 : 0] conv_mem_bias_q,
                          conv_mem_bias_q2,
                          conv_mem_bias_q3;

    reg                   conv_mem_valid_q,
                          conv_mem_valid_q2,
                          conv_mem_valid_q3;

    reg                   conv_mem_last_q,
                          conv_mem_last_q2,
                          conv_mem_last_q3;
    always @(posedge clk_i) begin
        conv_mem_bias_q  <= conv_mem_bias;
        conv_mem_bias_q2 <= conv_mem_bias_q;
        conv_mem_bias_q3 <= conv_mem_bias_q2;

        conv_mem_valid_q  <= conv_mem_valid;
        conv_mem_valid_q2 <= conv_mem_valid_q;
        conv_mem_valid_q3 <= conv_mem_valid_q2;

        conv_mem_last_q  <= conv_mem_last;
        conv_mem_last_q2 <= conv_mem_last_q;
        conv_mem_last_q3 <= conv_mem_last_q2;
    end

    // =========================================================================
    // Vector Multiplication
    // =========================================================================
    wire [MUL_VECTOR_BW - 1 : 0] vec_mul_data   [FILTER_LEN - 1 : 0];
    wire                         vec_mul_valid  [FILTER_LEN - 1 : 0];
    wire                         vec_mul_last   [FILTER_LEN - 1 : 0];
    wire                         vec_mul_ready0 [FILTER_LEN - 1 : 0];
    wire                         vec_mul_ready1 [FILTER_LEN - 1 : 0];

    for (i = 0; i < FILTER_LEN; i = i + 1) begin: vector_multiply
        vec_mul #(
            .I_BW(BW),
            .O_BW(MUL_BW),
            .VECTOR_LEN(VECTOR_LEN)
        ) vec_mul_inst (
            .clk_i(clk_i),
            .rst_n_i(rst_n_i),

            .data0_i(recycler_data_q[i]),
            .valid0_i(recycler_valid_q),
            .last0_i(recycler_last_q),
            .ready0_o(vec_mul_ready0[i]),

            .data1_i(conv_mem_weight[i]),
            .valid1_i(conv_mem_valid),
            .last1_i(conv_mem_last),
            .ready1_o(vec_mul_ready1[i]),

            .data_o(vec_mul_data[i]),
            .valid_o(vec_mul_valid[i]),
            .last_o(vec_mul_last[i]),
            .ready_i(vec_add_ready[i])
        );
    end

    // =========================================================================
    // Vector Addition
    // =========================================================================
    wire [ADD_VECTOR_BW - 1 : 0] vec_add_data;
    wire                         vec_add_valid;
    wire                         vec_add_last;
    wire                         vec_add_ready [FILTER_LEN - 1 : 0];

    vec_add #(
        .I_BW(MUL_BW),
        .O_BW(ADD_BW),
        .VECTOR_LEN(VECTOR_LEN)
    ) vec_add_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        .data0_i(vec_mul_data[0]),
        .valid0_i(vec_mul_valid[0]),
        .last0_i(vec_mul_last[0]),
        .ready0_o(vec_add_ready[0]),

        .data1_i(vec_mul_data[1]),
        .valid1_i(vec_mul_valid[1]),
        .last1_i(vec_mul_last[1]),
        .ready1_o(vec_add_ready[0]),

        .data2_i(vec_mul_data[2]),
        .valid2_i(vec_mul_valid[2]),
        .last2_i(vec_mul_last[2]),
        .ready2_o(vec_add_ready[0]),

        .data_o(vec_add_data),
        .valid_o(vec_add_valid),
        .last_o(vec_add_last),
        .ready_i(red_add_ready[0])
    );

    // =========================================================================
    // Reduction Addition
    // =========================================================================
    wire [BIAS_BW - 1 : 0] red_add_data;
    wire                   red_add_valid;
    wire                   red_add_last;
    wire [0:0]             red_add_ready; // [0:0] needed to avoid undecl. error

    red_add #(
        .I_BW(ADD_BW),
        .O_BW(BIAS_BW),
        .VECTOR_LEN(VECTOR_LEN)
    ) red_add_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        .data_i(vec_add_data),
        .valid_i(vec_add_valid),
        .last_i(vec_add_last),
        .ready_o(red_add_ready),

        .data_o(red_add_data),
        .valid_o(red_add_valid),
        .last_o(red_add_last),
        .ready_i(bias_add_ready[1])
    );

    // =========================================================================
    // Bias Addition
    // =========================================================================
    wire [BIAS_BW - 1 : 0] bias_add_data;
    wire                   bias_add_valid;
    wire                   bias_add_last;
    wire                   bias_add_ready [FILTER_LEN - 1 : 0];

    vec_add #(
        .I_BW(BIAS_BW),
        .O_BW(BIAS_BW),
        .VECTOR_LEN(1)
    ) bias_add_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        // bias term
        .data0_i(conv_mem_bias_q3),
        .valid0_i(conv_mem_valid_q3),
        .last0_i(conv_mem_last_q3),
        .ready0_o(bias_add_ready[0]),

        // reduced sum
        .data1_i(red_add_data),
        .valid1_i(red_add_valid),
        .last1_i(red_add_last),
        .ready1_o(bias_add_ready[1]),

        // unused
        .data2_i({BIAS_BW{1'b0}}),
        .valid2_i(1'd1),
        .last2_i(1'd0),
        .ready2_o(bias_add_ready[2]),

        .data_o(bias_add_data),
        .valid_o(bias_add_valid),
        .last_o(bias_add_last),
        .ready_i(relu_ready[0])
    );

    // =========================================================================
    // ReLU Layer
    // =========================================================================
    wire [BIAS_BW - 1 : 0] relu_data;
    wire                   relu_valid;
    wire                   relu_last;
    wire [0:0]             relu_ready;

    relu #(
        .BW(BIAS_BW)
    ) relu_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        .data_i(bias_add_data),
        .valid_i(bias_add_valid),
        .last_i(bias_add_last),
        .ready_o(relu_ready),

        .data_o(relu_data),
        .valid_o(relu_valid),
        .last_o(relu_last),
        .ready_i(quantizer_ready[0])
    );

    // =========================================================================
    // Quantization Layer
    // =========================================================================
    wire [BW - 1 : 0] quantizer_data;
    wire              quantizer_valid;
    wire              quantizer_last;
    wire [0:0]        quantizer_ready;

    quantizer #(
        .I_BW(BIAS_BW),
        .O_BW(BW),
        .SHIFT_BW(SHIFT_BW)
    ) quantizer_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        .shift_i(conv_mem_shift),

        .data_i(relu_data),
        .valid_i(relu_valid),
        .last_i(relu_last),
        .ready_o(quantizer_ready),

        .data_o(quantizer_data),
        .valid_o(quantizer_valid),
        .last_o(quantizer_last),
        .ready_i(ready_i)
    );

    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign data_o  = quantizer_data;
    assign valid_o = quantizer_valid;
    assign ready_o = recycler_ready;
    assign last_o  = quantizer_last;

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    initial begin
      $dumpfile ("wave.vcd");
      $dumpvars (0, conv_top);
      #1;
    end
    `endif

endmodule
