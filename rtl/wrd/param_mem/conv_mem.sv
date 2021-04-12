// ============================================================================
// Parameter Memory
// Design: Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// ============================================================================

module conv_mem #(
    parameter BW          = 8,
    parameter FRAME_LEN   = 50,
    parameter COLUMN_LEN  = 1,
    parameter NUM_FILTERS = 8
) (
    input                             clk_i,
    input                             rst_n_i,

    input                             enable_cycle_i,
    input                             switch_filter_i,

    input                             rd_en_i,
    input                             wr_en_i,
    input         [BANK_BW - 1 : 0]   rd_wr_bank_i,
    input         [ADDR_BW - 1 : 0]   rd_wr_addr_i,
    input  signed [VECTOR_BW - 1 : 0] wr_data_i,


    output signed [VECTOR_BW - 1 : 0] data0_o,
    output signed [VECTOR_BW - 1 : 0] data1_o,
    output signed [VECTOR_BW - 1 : 0] data2_o,
    output                            valid_o,
    output                            last_o,
    input                             ready_i
);

    genvar i;

    // ========================================================================
    // Local Parameters
    // ========================================================================
    // This unit is hard coded for width 3 filters
    localparam FILTER_LEN = 3;

    // Bitwidth Definitions
    localparam VECTOR_BW = COLUMN_LEN * BW;
    localparam ADDR_BW   = $clog2(NUM_FILTERS);
    // Number of weight banks + bias bank
    localparam BANK_BW   = $clog2(FILTER_LEN + 1);
    // Higher dynamic range for bias
    localparam BIAS_BW   = BW * 2;
    // ========================================================================

    // ========================================================================
    // Parameter Memory Controller
    // ========================================================================
    // Define States
    localparam STATE_IDLE    = 3'd0,
               STATE_WRITE   = 3'd1,
               STATE_READ    = 3'd2,
               STATE_CYCLE   = 3'd3;

    reg [2:0] state;

    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            state <= STATE_IDLE;
        end else begin
            case (state)
                STATE_IDLE: begin
                    state <= STATE_IDLE;
                end

                STATE_CYCLE: begin
                    state <= STATE_CYCLE;

                end
                default: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end
    // 4 States:
    // Idle
    // Memory Write
    // Memory Read
    // Cycling
    // ========================================================================

    // ========================================================================
    // Weight Memories
    // ========================================================================
    wire weight_en;
    wire [VECTOR_BW - 1 : 0] weight_data_in;
    wire [ADDR_BW - 1 : 0]   weight_addr;
    wire                     weight_wr_en    [NUM_FILTERS - 1 : 0];
    wire [VECTOR_BW - 1 : 0] weight_data_out [NUM_FILTERS - 1 : 0];

    // TODO: Remove
    assign weight_en = 'd1;
    wire [ADDR_BW - 1 : 0] read_addr = 'd5;

    assign weight_data_in = (wr_en_i) ? wr_data_i : 'd0;
    assign weight_addr = (rd_en_i | wr_en_i) ? rd_wr_addr_i : read_addr;
    for (i = 0; i < FILTER_LEN; i = i + 1) begin: weight_banks_wr_en
        assign weight_wr_en[i] = wr_en_i & (rd_wr_bank_i == i);
    end

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

    // ========================================================================
    // Bias Memory
    // ========================================================================
    wire bias_en;
    wire [BIAS_BW - 1 : 0] bias_data_in;
    wire [ADDR_BW - 1 : 0] bias_addr;
    wire                   bias_wr_en;
    wire [BIAS_BW - 1 : 0] bias_data_out;

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

    // ========================================================================
    // Output Assignment
    // ========================================================================
    assign data0_o = weight_data_out[0];
    assign data1_o = weight_data_out[1];
    assign data2_o = weight_data_out[2];
    assign valid_o = 0;
    assign last_o  = 0;
    // ========================================================================

    // ========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // ========================================================================
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, conv_mem);
        #1;
    end
    `endif
    // ========================================================================

endmodule
