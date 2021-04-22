// ============================================================================
// Fully Connected Layer Memory
// Design: Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// Assumes BIAS_BW > BW
// TODO: Implement rd_data_o for reading memories
// ============================================================================

module fc_mem #(
    parameter BW          = 8,
    parameter BIAS_BW     = BW * 2,
    parameter FRAME_LEN   = 208,
    parameter NUM_CLASSES = 3
) (
    input                                           clk_i,
    input                                           rst_n_i,

    // Control Ports
    input                                           cycle_en_i,

    // Manual Read/Write Ports
    input                                           rd_en_i,
    input                                           wr_en_i,
    input         [BANK_BW - 1 : 0]                 rd_wr_bank_i,
    input         [ADDR_BW - 1 : 0]                 rd_wr_addr_i,
    input  signed [BIAS_BW - 1 : 0]                 wr_data_i,
    output signed [BIAS_BW - 1 : 0]                 rd_data_o,

    // Streaming Interace Ports
    output signed [(BW * NUM_CLASSES) - 1 : 0]      data_w_o,
    output signed [(BIAS_BW * NUM_CLASSES) - 1 : 0] data_b_o,
    output                                          valid_o,
    output                                          last_o,
    input                                           ready_i
);

    genvar i;

    // ========================================================================
    // Local Parameters
    // ========================================================================
    // Bitwidth Definitions
    localparam ADDR_BW   = $clog2(FRAME_LEN);
    // Number of weight banks + bias bank per class
    localparam BANK_BW          = $clog2(NUM_CLASSES * 2);
    localparam FRAME_COUNTER_BW = $clog2(FRAME_LEN);
    // ========================================================================

    // ========================================================================
    // Frame Counter
    // ========================================================================
    reg [FRAME_COUNTER_BW - 1 : 0] frame_counter;

    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            frame_counter <= 0;
        end else begin
            if (cycle_en_i) begin
                frame_counter <= (frame_counter < FRAME_LEN - 1) ?
                                  frame_counter + 'd1 : 'd0;
            end else begin
                frame_counter <= 0;
            end
        end
    end
    // ========================================================================

    // ========================================================================
    // Weight Memories
    // ========================================================================
    wire                    weight_wr_en    [NUM_CLASSES - 1 : 0];
    wire                    weight_en;
    wire [BW - 1 : 0]       weight_data_in;
    wire [ADDR_BW - 1 : 0]  weight_addr;
    wire [BW - 1 : 0]       weight_data_out [NUM_CLASSES - 1 : 0];

    for (i = 0; i < NUM_CLASSES; i = i + 1) begin: weight_banks_wr_en
        assign weight_wr_en[i] = (wr_en_i) & (rd_wr_bank_i == i);
    end
    assign weight_en      = (wr_en_i | rd_en_i | cycle_en_i);
    assign weight_data_in = (wr_en_i) ? wr_data_i[BW - 1 : 0] : 'd0;
    assign weight_addr    = (wr_en_i | rd_en_i) ? rd_wr_addr_i : frame_counter;

    for (i = 0; i < NUM_CLASSES; i = i + 1) begin: weight_banks
        dffram #(
            .WIDTH(BW),
            .DEPTH(FRAME_LEN)
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
    // Bias Memories
    // ========================================================================
    wire                   bias_wr_en [NUM_CLASSES - 1 : 0];
    wire                   bias_en;
    wire [BIAS_BW - 1 : 0] bias_data_in;
    // required to be 2 bits for dffram
    wire [1:0]             bias_addr;
    wire [BIAS_BW - 1 : 0] bias_data_out [NUM_CLASSES - 1 : 0];

    for (i = 0; i < NUM_CLASSES; i = i + 1) begin: bias_banks_wr_en
        assign bias_wr_en[i] = (wr_en_i) & (rd_wr_bank_i == i + NUM_CLASSES);
    end
    assign bias_en      = (wr_en_i | rd_en_i | cycle_en_i);
    assign bias_data_in = (wr_en_i) ? wr_data_i : 'd0;
    assign bias_addr    = 'b0;

    for (i = 0; i < NUM_CLASSES; i = i + 1) begin: bias_banks
        dffram #(
            .WIDTH(BIAS_BW),
            .DEPTH(1)
        ) bias_ram_inst (
            .clk_i(clk_i),

            .wr_en_i(bias_wr_en[i]),
            .en_i(bias_en),

            .addr_i(bias_addr),
            .data_i(bias_data_in),
            .data_o(bias_data_out[i])
        );
    end
    // ========================================================================

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

    // pack multiplication results
    for (i = 0; i < NUM_CLASSES; i = i + 1) begin: pack_output
        assign data_w_o[(i + 1) * BW - 1 : i * BW] = weight_data_out[i];
        assign data_b_o[(i + 1) * BIAS_BW - 1 : i * BIAS_BW] = bias_data_out[i];
    end
    assign valid_o = cycle_en_i_q;
    assign last_o  = valid_o & frame_last;
    // ========================================================================

    // ========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // ========================================================================
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, fc_mem);
        #1;
    end
    `endif
    // ========================================================================

endmodule
