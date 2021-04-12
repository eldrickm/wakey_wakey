/*
 * 1D Convolution
 * Design: Eldrick Millares
 * Verification: Matthew Pauly
 * Notes:
 *  FRAME_LEN > FILTER_LEN
 *  FILTER_LEN == 3
 *  In order to change filter size, you'll have to parameterize the vec_add
 *  unit.
 */

module conv1d #(
    parameter FRAME_LEN   = 50,
    parameter COLUMN_LEN  = 1,
    parameter NUM_FILTERS  = 8
) (
    input                             clk_i,
    input                             rst_n_i,

    input  signed [VECTOR_BW - 1 : 0] data_i,
    input                             valid_i,
    input                             last_i,
    output                            ready_o,

    output signed [VECTOR_BW - 1 : 0] data_o,
    output                            valid_o,
    output                            last_o,
    input                             ready_i
);

    // ========================================================================
    // Local Parameters
    // ========================================================================
    localparam FILTER_LEN = 3;
    localparam MAX_CYCLES = NUM_FILTERS * FRAME_LEN;

    // Bitwidth Definitions
    localparam BW         = 8;
    localparam MUL_OUT_BW = 16;
    localparam ADD_OUT_BW = 18;
    localparam VECTOR_BW  = COLUMN_LEN  * BW;
    // ========================================================================

    genvar i;

    // ========================================================================
    // Recycler
    // ========================================================================
    wire [VECTOR_BW - 1 : 0] sr0;
    wire [VECTOR_BW - 1 : 0] sr1;
    wire [VECTOR_BW - 1 : 0] sr2;
    wire sr_valid;
    wire sr_last;
    wire sr_ready_i;

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
        .ready_o(ready_o),

        .data0_o(sr0),
        .data1_o(sr1),
        .data2_o(sr2),
        .valid_o(sr_valid),
        .last_o(st_last),
        // TODO: Deal with sr_ready_i
        .ready_i(sr_ready_i)
    );

    wire [VECTOR_BW - 1 : 0] sr_data_arr [FILTER_LEN - 1 : 0];
    assign sr_data_arr[0] = sr0;
    assign sr_data_arr[1] = sr1;
    assign sr_data_arr[2] = sr2;

    // ========================================================================
    // Weight Memory
    // TODO: Add Weight Memory
    // ========================================================================
    // ========================================================================


    // ========================================================================
    // Vector Multiplication
    // ========================================================================
    wire [MUL_OUT_BW - 1 : 0] vec_mul_data_out  [FILTER_LEN - 1 : 0];
    wire                      vec_mul_valid_out [FILTER_LEN - 1 : 0];
    wire                      vec_mul_last_out  [FILTER_LEN - 1 : 0];
    wire                      vec_mul_ready0_out  [FILTER_LEN - 1 : 0];
    wire                      vec_mul_ready1_out  [FILTER_LEN - 1 : 0];

    for (i = 0; i < FILTER_LEN; i = i + 1) begin: vector_multiply
        vec_mul #(
            .BW_I(BW),
            .BW_O(MUL_OUT_BW),
            .VECTOR_LEN(COLUMN_LEN)
        ) vec_mul_inst (
            .clk_i(clk_i),
            .rst_n_i(rst_n_i),

            .data0_i(sr_data_arr[i]),
            .valid0_i(sr_valid),
            // TODO: Deal with ready
            .last0_i(1'b0),
            .ready0_o(vec_mul_ready0_out[i]),

            // TODO: Hook up to memory
            .data1_i(8'd1),
            .valid1_i(1'b1),
            .last1_i(1'b0),
            .ready1_o(vec_mul_ready1_out[i]),

            .data_o(vec_mul_data_out[i]),
            .valid_o(vec_mul_valid_out[i]),
            .last_o(vec_mul_last_out[i]),
            // TODO: Deal with Ready
            .ready_i(1'b1)
        );
    end
    // ========================================================================

    // ========================================================================
    // Vector Addition
    // ========================================================================
    wire [ADD_OUT_BW - 1 : 0] vec_add_data_out;
    wire                      vec_add_valid_out;
    wire                      vec_add_last_out;
    wire                      vec_add_ready_out [FILTER_LEN - 1 : 0];

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
        .ready_i(1'b1)
    );
    // ========================================================================

    // ========================================================================
    // Bias Addition
    // ========================================================================
    // ========================================================================

    // ========================================================================
    // ReLU Layer
    // ========================================================================
    // ========================================================================

    // ========================================================================
    // Quantization Layer
    // ========================================================================
    // ========================================================================

    // ========================================================================
    // Output Assignment
    // ========================================================================
    // ========================================================================
    assign data_o  = sr2;
    assign valid_o = sr_valid;
    assign ready_o = ready_i;
    assign last_o  = last_i;

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
