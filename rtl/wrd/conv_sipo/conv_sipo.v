// ============================================================================
// Module:       Convolution Serial In, Parallel Out
// Design:       Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// ============================================================================

module conv_sipo #(
    parameter BW         = 8,
    parameter FRAME_LEN  = 50,
    parameter VECTOR_LEN = 8,

    // ========================================================================
    // Local Parameters - Do Not Edit
    // ========================================================================
    parameter VECTOR_BW  = VECTOR_LEN * BW
) (
    // clock and reset
    input                      clk_i,
    input                      rst_n_i,

    // streaming input
    input  signed [BW - 1 : 0] data_i,
    input                      valid_i,
    input                      last_i,
    output                     ready_o,
 
    // streaming output
    output [VECTOR_BW - 1 : 0] data_o,
    output                     valid_o,
    output                     last_o,
    input                      ready_i
);

    genvar i;

    // ========================================================================
    // Local Parameters
    // ========================================================================
    // Bitwidth Definitions
    localparam COUNTER_BW = $clog2(FRAME_LEN);

    // =========================================================================
    // Control Logic
    // =========================================================================
    localparam STATE_IDLE   = 2'd0,
               STATE_OUTPUT = 2'd1;

    reg [1:0] state;
    reg [COUNTER_BW - 1 : 0] counter;
    reg [VECTOR_LEN - 1 : 0] fifo_sel;

    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            counter <= 'd0;
            state <= STATE_IDLE;
        end else begin
            case (state)
                STATE_IDLE: begin
                    counter <= 'd0;
                    state   <= ((fifo_sel == {{VECTOR_LEN - 1{1'b0}}, 1'b1})
                               && (last_i)) ? STATE_OUTPUT : STATE_IDLE;
                end
                STATE_OUTPUT: begin
                    counter <= counter + 'd1;
                    state   <= (counter == FRAME_LEN - 1) ? STATE_IDLE :
                                                            STATE_OUTPUT;
                end
                default: begin
                    counter <= 'd0;
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            fifo_sel <= {1'b1, {VECTOR_LEN - 1{1'b0}}};
        end else begin
            fifo_sel <= (last_i & valid_i) ?
                        {fifo_sel[0], fifo_sel[VECTOR_LEN - 1 : 1]}
                        : fifo_sel;
        end
    end

    // =========================================================================
    // FIFO Banks
    // =========================================================================
    wire [BW - 1 : 0]         fifo_din;
    wire [BW - 1 : 0]         fifo_dout [VECTOR_LEN - 1 : 0];
    wire [VECTOR_LEN - 1 : 0] fifo_enq;
    wire fifo_deq;

    assign fifo_din = data_i;
    assign fifo_deq = (state == STATE_OUTPUT);
    for (i = 0; i < VECTOR_LEN; i = i + 1) begin: create_sipo_fifo
        assign fifo_enq[i] = fifo_sel[i] && valid_i;
        fifo #(
            .DATA_WIDTH(BW),
            .FIFO_DEPTH(FRAME_LEN)
        ) fifo_inst (
            .clk_i(clk_i),
            .rst_n_i(rst_n_i),

            .enq_i(fifo_enq[i]),
            .deq_i(fifo_deq),

            .din_i(fifo_din),
            .dout_o(fifo_dout[i]),

            .full_o_n(),
            .empty_o_n()
        );
    end

    // =========================================================================
    // Output Assignment
    // =========================================================================
    // register all outputs
    reg ready_q;
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            ready_q <= 'b0;
        end else begin
            ready_q <= ready_i;
        end
    end

    for (i = 0; i < VECTOR_LEN; i = i + 1) begin: pack_output
        assign data_o[(i + 1) * BW - 1 : i * BW] = fifo_dout[i];
    end

    assign valid_o = (state == STATE_OUTPUT);
    assign ready_o = ready_q;
    assign last_o  = (counter == FRAME_LEN - 1);

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    `ifndef SCANNED
    `define SCANNED
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, conv_sipo);
        #1;
    end
    `endif
    `endif

endmodule
