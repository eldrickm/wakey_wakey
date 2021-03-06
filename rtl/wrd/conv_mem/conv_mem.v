// =============================================================================
// Module:       Convolution Memory
// Design:       Eldrick Millares
// Verification: Matthew Pauly
// Notes:
//
// Stores weights, biases, and shifts in different banks, numbered like so:
// [0, NUM_FILTERS-1] : Kernel weights for nth output channel
// [NUM_FILTERS]      : Bias terms for each kernel
// [NUM_FILTERS+1]    : Global shift applied to all outputs of this convolution
// =============================================================================

module conv_mem #(
    parameter BW          = 8,
    parameter BIAS_BW     = 32,
    parameter SHIFT_BW    = $clog2(BIAS_BW),
    parameter FRAME_LEN   = 50,
    parameter VECTOR_LEN  = 13,
    parameter NUM_FILTERS = 8,

    // =========================================================================
    // Local Parameters - DO NOT EDIT
    // =========================================================================
    // This unit is hard coded for width 3 filters
    parameter FILTER_LEN = 3,

    // Bitwidth Definitions
    parameter VECTOR_BW = VECTOR_LEN * BW,
    parameter ADDR_BW   = $clog2(NUM_FILTERS),
    // Number of weight banks + bias bank + shift bank
    parameter BANK_BW   = $clog2(FILTER_LEN + 2)
) (
    // clock and reset
    input                             clk_i,
    input                             rst_n_i,

    // control
    input                             cycle_en_i,

    // memory configuration
    input                             rd_en_i,
    input                             wr_en_i,
    input         [BANK_BW - 1 : 0]   rd_wr_bank_i,
    input         [ADDR_BW - 1 : 0]   rd_wr_addr_i,
    input  signed [VECTOR_BW - 1 : 0] wr_data_i,
    output signed [VECTOR_BW - 1 : 0] rd_data_o,

    // streaming output
    output signed [VECTOR_BW - 1 : 0] data0_o,
    output signed [VECTOR_BW - 1 : 0] data1_o,
    output signed [VECTOR_BW - 1 : 0] data2_o,
    output signed [BIAS_BW - 1 : 0]   bias_o,
    output        [SHIFT_BW - 1 : 0]  shift_o,
    output                            valid_o,
    output                            last_o,
    input                             ready_i
);

    // =========================================================================
    // Local Parameters
    // =========================================================================
    localparam FRAME_COUNTER_BW = $clog2(FRAME_LEN);
    localparam FILTER_COUNTER_BW = $clog2(NUM_FILTERS);

    genvar i;

    // ========================================================================
    // Convolution Memory Controller
    // ========================================================================
    // Define States
    reg [FRAME_COUNTER_BW - 1 : 0] frame_counter;
    reg [FILTER_COUNTER_BW - 1 : 0] filter_counter;

    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            frame_counter <= 0;
            filter_counter <= 0;
        end else begin
            if (cycle_en_i) begin
                frame_counter <= (frame_counter < FRAME_LEN - 1) ?
                                  frame_counter + 'd1 : 'd0;
                filter_counter <= (frame_counter == FRAME_LEN - 1) ?
                                    ((filter_counter < NUM_FILTERS - 1) ?
                                     filter_counter + 1 : 'd0)
                                  : filter_counter;
            end else begin
                frame_counter <= frame_counter;
                filter_counter <= filter_counter;
            end
        end
    end

    // ========================================================================
    // Weight Memories
    // ========================================================================
    wire weight_en;
    wire                     weight_wr_en    [NUM_FILTERS - 1 : 0];
    wire [VECTOR_BW - 1 : 0] weight_data_in;
    wire [ADDR_BW - 1 : 0]   weight_addr;
    wire [VECTOR_BW - 1 : 0] weight_data_out [NUM_FILTERS - 1 : 0];

    assign weight_en      = (wr_en_i | rd_en_i | cycle_en_i);
    for (i = 0; i < FILTER_LEN; i = i + 1) begin: weight_banks_wr_en
        assign weight_wr_en[i] = (wr_en_i) & (rd_wr_bank_i == i);
    end
    assign weight_data_in = (wr_en_i) ? wr_data_i : 'd0;
    assign weight_addr    = (wr_en_i | rd_en_i) ? rd_wr_addr_i : filter_counter;

    for (i = 0; i < FILTER_LEN; i = i + 1) begin: weight_banks
        dffram #(
            .WIDTH(VECTOR_BW),
            .DEPTH(NUM_FILTERS)
        ) weight_ram_inst (
            .clk_i(clk_i),

            .wr_en_i(weight_wr_en[i]),
            .en_i(weight_en),

            .addr_i(weight_addr),
            .data_i(weight_data_in),
            .data_o(weight_data_out[i])
        );
    end

    // ========================================================================
    // Bias Memory
    // ========================================================================
    wire bias_en;
    wire                   bias_wr_en;
    wire [BIAS_BW - 1 : 0] bias_data_in;
    wire [ADDR_BW - 1 : 0] bias_addr;
    wire [BIAS_BW - 1 : 0] bias_data_out;

    assign bias_en      = (wr_en_i | rd_en_i | cycle_en_i);
    assign bias_wr_en   = (wr_en_i) & (rd_wr_bank_i == FILTER_LEN);
    assign bias_data_in = (wr_en_i) ? wr_data_i[BIAS_BW - 1 : 0] : 'd0;
    assign bias_addr    = (wr_en_i | rd_en_i) ? rd_wr_addr_i : filter_counter;

    dffram #(
        .WIDTH(BIAS_BW),
        .DEPTH(NUM_FILTERS)
    ) bias_ram_inst (
        .clk_i(clk_i),

        .wr_en_i(bias_wr_en),
        .en_i(bias_en),

        .addr_i(bias_addr),
        .data_i(bias_data_in),
        .data_o(bias_data_out)
    );

    // ========================================================================
    // Shift Memory
    // ========================================================================
    // wire shift_en;
    wire                   shift_wr_en;
    wire [SHIFT_BW - 1 : 0] shift_data_in;
    reg [SHIFT_BW - 1 : 0] shift_data_out;

    // assign shift_en      = (wr_en_i | rd_en_i | cycle_en_i);
    assign shift_wr_en   = (wr_en_i) & (rd_wr_bank_i == FILTER_LEN + 1);
    assign shift_data_in = (wr_en_i) ? wr_data_i[SHIFT_BW - 1 : 0] : 'd0;

    always @(posedge clk_i) begin
        if (shift_wr_en) begin
            shift_data_out <= shift_data_in;
        end else begin
            shift_data_out <= shift_data_out;
        end
    end

    // ========================================================================
    // Read Data Assignment
    // ========================================================================
    reg [BANK_BW - 1 : 0] rd_wr_bank_q;
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            rd_wr_bank_q <= 'b0;
        end else begin
            rd_wr_bank_q <= rd_wr_bank_i;
        end
    end

    // build array of all the output data, properly padded, to mux to rd_data_o
    wire [VECTOR_BW - 1 : 0] out_data_arr [FILTER_LEN + 1 : 0];

    for (i = 0; i < FILTER_LEN; i = i + 1) begin: weight_banks_out_data_arr
        assign out_data_arr[i] = weight_data_out[i];
    end
    assign out_data_arr[FILTER_LEN] = {{{VECTOR_BW - BIAS_BW}{1'b0}},
                                       bias_data_out};
    assign out_data_arr[FILTER_LEN + 1] = {{{VECTOR_BW - SHIFT_BW}{1'b0}},
                                           shift_data_out};

    assign rd_data_o = out_data_arr[rd_wr_bank_q];

    // ========================================================================
    // Output Assignment
    // ========================================================================
    reg cycle_en_i_q;
    always @(posedge clk_i) begin
        cycle_en_i_q <= cycle_en_i;
    end

    reg frame_last;
    always @(posedge clk_i) begin
        frame_last <= (frame_counter == FRAME_LEN - 1);
    end

    assign data0_o = weight_data_out[0];
    assign data1_o = weight_data_out[1];
    assign data2_o = weight_data_out[2];
    assign bias_o  = bias_data_out;
    assign shift_o  = shift_data_out;
    assign valid_o = cycle_en_i_q;
    assign last_o  = valid_o & frame_last;

    // ========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // ========================================================================
    `ifdef COCOTB_SIM
    `ifndef SCANNED
    `define SCANNED
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, conv_mem);
        #1;
    end
    `endif
    `endif

endmodule
