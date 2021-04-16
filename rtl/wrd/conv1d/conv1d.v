// ============================================================================
// 1D Convolution
// Design: Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// Constraint: FRAME_LEN > FILTER_LEN
// Constraint: FILTER_LEN == 3
// TODO: Deal with ready's / backpressur
// ============================================================================

module conv1d #(
    parameter FRAME_LEN   = 50,
    parameter COLUMN_LEN  = 13,
    parameter NUM_FILTERS = 8
) (
    input                             clk_i,
    input                             rst_n_i,

    // Input Features
    input  signed [VECTOR_BW - 1 : 0] data_i,
    input                             valid_i,
    input                             last_i,
    output                            ready_o,

    // Output Features
    output signed [BW - 1 : 0]        data_o,
    output                            valid_o,
    output                            last_o,
    input                             ready_i,

    // Memory Configuration Ports
    input                             rd_en_i,
    input                             wr_en_i,
    input         [BANK_BW - 1 : 0]   rd_wr_bank_i,
    input         [ADDR_BW - 1 : 0]   rd_wr_addr_i,
    input  signed [VECTOR_BW - 1 : 0] wr_data_i,
    output signed [VECTOR_BW - 1 : 0] rd_data_o
);

    // ========================================================================
    // Local Parameters
    // ========================================================================
    localparam FILTER_LEN = 3;
    localparam MAX_CYCLES = NUM_FILTERS * FRAME_LEN;

    // Bitwidth Definitions
    localparam BW         = 8;
    localparam BIAS_BW    = BW * 4;
    localparam MUL_OUT_BW = 16;
    localparam ADD_OUT_BW = 18;

    localparam VECTOR_BW         = COLUMN_LEN * BW;
    localparam MUL_OUT_VECTOR_BW = COLUMN_LEN * MUL_OUT_BW;
    localparam ADD_OUT_VECTOR_BW = COLUMN_LEN * ADD_OUT_BW;

    localparam ADDR_BW   = $clog2(NUM_FILTERS);
    // Number of weight banks + bias bank
    localparam BANK_BW   = $clog2(FILTER_LEN + 1);
    localparam FRAME_COUNTER_BW = $clog2(FRAME_LEN);
    localparam FILTER_COUNTER_BW = $clog2(NUM_FILTERS);
    localparam SHIFT_BW = $clog2(BIAS_BW);
    // ========================================================================

    genvar i;

    // ========================================================================
    // Recycler
    // ========================================================================
    wire [VECTOR_BW - 1 : 0] recycler_data0_out;
    wire [VECTOR_BW - 1 : 0] recycler_data1_out;
    wire [VECTOR_BW - 1 : 0] recycler_data2_out;
    wire recycler_valid_out;
    wire recycler_last_out;
    wire recycler_ready_out;

    recycler #(
        .BW(BW),
        .FRAME_LEN(FRAME_LEN),
        .COLUMN_LEN(COLUMN_LEN),
        .NUM_FILTERS(NUM_FILTERS)
    ) recycler_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        .data_i(data_i),
        .valid_i(valid_i),
        .last_i(last_i),
        .ready_o(recycler_ready_out),

        .data0_o(recycler_data0_out),
        .data1_o(recycler_data1_out),
        .data2_o(recycler_data2_out),
        .valid_o(recycler_valid_out),
        .last_o(recycler_last_out),
        // TODO: Use all vec_mul ready outs in the array
        .ready_i(vec_mul_ready0_out[0])
    );

    reg [VECTOR_BW - 1 : 0] recycler_data_out_q [FILTER_LEN - 1 : 0];
    reg recycler_valid_out_q;
    reg recycler_last_out_q;
    always @(posedge clk_i) begin
        recycler_data_out_q[0] <= recycler_data0_out;
        recycler_data_out_q[1] <= recycler_data1_out;
        recycler_data_out_q[2] <= recycler_data2_out;
        recycler_valid_out_q   <= recycler_valid_out;
        recycler_last_out_q    <= recycler_last_out;

    end
    // ========================================================================

    // ========================================================================
    // Parameter Memory
    // ========================================================================
    wire [VECTOR_BW - 1 : 0] conv_mem_weight_out [FILTER_LEN - 1 : 0];
    wire [BIAS_BW - 1 : 0]   conv_mem_bias_out;
    wire conv_mem_valid_out;
    wire conv_mem_last_out;

    conv_mem #(
        .BW(BW),
        .BIAS_BW(BIAS_BW),
        .FRAME_LEN(FRAME_LEN),
        .COLUMN_LEN(COLUMN_LEN),
        .NUM_FILTERS(NUM_FILTERS)
    ) conv_mem_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        // Control Ports
        .cycle_en_i(recycler_valid_out),

        // Manual Read/Write Ports
        .rd_en_i(rd_en_i),
        .wr_en_i(wr_en_i),
        .rd_wr_bank_i(rd_wr_bank_i),
        .rd_wr_addr_i(rd_wr_addr_i),
        .wr_data_i(wr_data_i),
        .rd_data_o(rd_data_o),

        // Streaming Interace Ports
        .data0_o(conv_mem_weight_out[0]),
        .data1_o(conv_mem_weight_out[1]),
        .data2_o(conv_mem_weight_out[2]),
        .bias_o(conv_mem_bias_out),
        .valid_o(conv_mem_valid_out),
        .last_o(conv_mem_last_out),
        // TODO: Use all ready outs in the array
        .ready_i(vec_mul_ready1_out[0])
    );
    // ========================================================================


    // ========================================================================
    // Vector Multiplication
    // ========================================================================
    wire [MUL_OUT_VECTOR_BW - 1 : 0] vec_mul_data_out  [FILTER_LEN - 1 : 0];
    wire                             vec_mul_valid_out [FILTER_LEN - 1 : 0];
    wire                             vec_mul_last_out  [FILTER_LEN - 1 : 0];
    wire                             vec_mul_ready0_out  [FILTER_LEN - 1 : 0];
    wire                             vec_mul_ready1_out  [FILTER_LEN - 1 : 0];

    for (i = 0; i < FILTER_LEN; i = i + 1) begin: vector_multiply
        vec_mul #(
            .BW_I(BW),
            .BW_O(MUL_OUT_BW),
            .VECTOR_LEN(COLUMN_LEN)
        ) vec_mul_inst (
            .clk_i(clk_i),
            .rst_n_i(rst_n_i),

            // recycler ports
            .data0_i(recycler_data_out_q[i]),
            .valid0_i(recycler_valid_out_q),
            .last0_i(recycler_last_out_q),
            .ready0_o(vec_mul_ready0_out[i]),

            // conv_mem ports
            .data1_i(conv_mem_weight_out[i]),
            .valid1_i(conv_mem_valid_out),
            .last1_i(conv_mem_last_out),
            .ready1_o(vec_mul_ready1_out[i]),

            // output ports to vec_add
            .data_o(vec_mul_data_out[i]),
            .valid_o(vec_mul_valid_out[i]),
            .last_o(vec_mul_last_out[i]),
            .ready_i(vec_add_ready_out[i])
        );
    end
    // ========================================================================

    // ========================================================================
    // Vector Addition
    // ========================================================================
    wire [ADD_OUT_VECTOR_BW - 1 : 0] vec_add_data_out;
    wire                             vec_add_valid_out;
    wire                             vec_add_last_out;
    wire                             vec_add_ready_out [FILTER_LEN - 1 : 0];

    // needed to be declared up here due to weird error with
    // signal declaration before usage in port assignment
    wire red_add_ready_out;

    vec_add #(
        .BW_I(MUL_OUT_BW),        // input bitwidth
        .BW_O(ADD_OUT_BW),        // output bitwidth
        .VECTOR_LEN(COLUMN_LEN)   // number of vector elements
    ) vec_add_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        .data0_i(vec_mul_data_out[0]),
        .valid0_i(vec_mul_valid_out[0]),
        .last0_i(vec_mul_last_out[0]),
        .ready0_o(vec_add_ready_out[0]),

        .data1_i(vec_mul_data_out[1]),
        .valid1_i(vec_mul_valid_out[1]),
        .last1_i(vec_mul_last_out[1]),
        .ready1_o(vec_add_ready_out[0]),

        .data2_i(vec_mul_data_out[2]),
        .valid2_i(vec_mul_valid_out[2]),
        .last2_i(vec_mul_last_out[2]),
        .ready2_o(vec_add_ready_out[0]),

        .data_o(vec_add_data_out),
        .valid_o(vec_add_valid_out),
        .last_o(vec_add_last_out),
        .ready_i(red_add_ready_out)
    );
    // ========================================================================

    // ========================================================================
    // Reduction Addition
    // ========================================================================
    wire [BIAS_BW - 1 : 0] red_add_data_out;
    wire red_add_valid_out;
    wire red_add_last_out;

    red_add #(
        .BW_I(ADD_OUT_BW),        // input bitwidth
        .BW_O(BIAS_BW),           // output bitwidth
        .VECTOR_LEN(COLUMN_LEN)   // number of vector elements
    ) red_add_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        .data_i(vec_add_data_out),
        .valid_i(vec_add_valid_out),
        .last_i(vec_add_last_out),
        .ready_o(red_add_ready_out),

        .data_o(red_add_data_out),
        .valid_o(red_add_valid_out),
        .last_o(red_add_last_out),
        .ready_i(1'b0)
    );
    // ========================================================================

    // ========================================================================
    // Bias Addition
    // ========================================================================
    wire [BIAS_BW - 1 : 0] bias_add_data_out;
    wire                   bias_add_valid_out;
    wire                   bias_add_last_out;

    // Delay the bias term to align with the output of the multipliers,
    // vector addition, and reduction addition
    reg [BIAS_BW - 1 : 0] conv_mem_bias_out_q, conv_mem_bias_out_q2,
                          conv_mem_bias_out_q3;
    reg                   conv_mem_valid_out_q,
                          conv_mem_valid_out_q2, conv_mem_valid_out_q3;
    reg                   conv_mem_last_out_q, conv_mem_last_out_q2,
                          conv_mem_last_out_q3;
    always @(posedge clk_i) begin
        conv_mem_bias_out_q  <= conv_mem_bias_out;
        conv_mem_bias_out_q2 <= conv_mem_bias_out_q;
        conv_mem_bias_out_q3 <= conv_mem_bias_out_q2;

        conv_mem_valid_out_q  <= conv_mem_valid_out;
        conv_mem_valid_out_q2 <= conv_mem_valid_out_q;
        conv_mem_valid_out_q3 <= conv_mem_valid_out_q2;

        conv_mem_last_out_q  <= conv_mem_last_out;
        conv_mem_last_out_q2 <= conv_mem_last_out_q;
        conv_mem_last_out_q3 <= conv_mem_last_out_q2;
    end

    wire                   relu_ready_out;

    vec_add #(
        .BW_I(BIAS_BW),        // input bitwidth
        .BW_O(BIAS_BW),        // output bitwidth
        .VECTOR_LEN(1)         // number of vector elements
    ) bias_add_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        // bias term
        .data0_i(conv_mem_bias_out_q3),
        .valid0_i(conv_mem_valid_out_q3),
        .last0_i(conv_mem_last_out_q3),
        // TODO
        .ready0_o(),

        // reduced sum
        .data1_i(red_add_data_out),
        .valid1_i(red_add_valid_out),
        .last1_i(red_add_last_out),
        // TODO
        .ready1_o(),

        // Unused
        .data2_i({BIAS_BW{1'b0}}),
        .valid2_i(1'd1),
        .last2_i(1'd0),
        // TODO
        .ready2_o(),

        .data_o(bias_add_data_out),
        .valid_o(bias_add_valid_out),
        .last_o(bias_add_last_out),
        .ready_i(relu_ready_out)
    );
    // ========================================================================

    // ========================================================================
    // ReLU Layer
    // ========================================================================
    wire [BIAS_BW - 1 : 0] relu_data_out;
    wire                   relu_valid_out;
    wire                   relu_last_out;

    wire              quantizer_ready_out;

    relu #(
        .BW(BIAS_BW)
    ) relu_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        .data_i(bias_add_data_out),
        .valid_i(bias_add_valid_out),
        .last_i(bias_add_last_out),
        .ready_o(relu_ready_out),

        .data_o(relu_data_out),
        .valid_o(relu_valid_out),
        .last_o(relu_last_out),
        .ready_i(quantizer_ready_out)
    );
    // ========================================================================

    // ========================================================================
    // Quantization Layer
    // ========================================================================
    wire [BW - 1 : 0] quantizer_data_out;
    wire              quantizer_valid_out;
    wire              quantizer_last_out;

    quantizer #(
        .BW_I(BIAS_BW),
        .BW_O(BW),
        .SHIFT_BW(SHIFT_BW)
    ) quantizer_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        .shift_i(5'd8),

        .data_i(relu_data_out),
        .valid_i(relu_valid_out),
        .last_i(relu_last_out),
        .ready_o(quantizer_ready_out),

        .data_o(quantizer_data_out),
        .valid_o(quantizer_valid_out),
        .last_o(quantizer_last_out),
        .ready_i(1'b1)
    );
    // ========================================================================

    // ========================================================================
    // Output Assignment
    // ========================================================================
    assign data_o  = quantizer_data_out;
    assign valid_o = quantizer_valid_out;
    assign ready_o = recycler_ready_out;
    assign last_o  = quantizer_last_out;
    // ========================================================================

    // ========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // ========================================================================
    `ifdef COCOTB_SIM
    initial begin
      $dumpfile ("wave.vcd");
      $dumpvars (0, conv1d);
      #1;
    end
    `endif
    // ========================================================================

endmodule
