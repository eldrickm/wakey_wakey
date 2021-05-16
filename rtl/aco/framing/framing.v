// =============================================================================
// Module:       Framing
// Design:       Matthew Pauly
// Verification: Eldrick Millares
// Notes:        Aggregates 256 samples into a FIFO and outputs them in one
//               large block.
// =============================================================================

module framing (
    // clock and reset
    input                                   clk_i,
    input                                   rst_n_i,
    input                                   en_i,

    // streaming input
    input  signed [I_BW - 1 : 0]            data_i,
    input                                   valid_i,

    // streaming output
    output  signed [O_BW - 1 : 0]           data_o,
    output                                  valid_o,
    output                                  last_o
);
    // =========================================================================
    // Local Parameters
    // =========================================================================
    localparam I_BW         = 9;   // preemphasis input
    localparam O_BW         = 16;  // FFT output
    localparam FRAME_LEN    = 256;
    localparam FIFO_DEPTH   = FRAME_LEN + 4;   // 4 spaces of headroom
    localparam COUNTER_BW   = $clog2(FIFO_DEPTH);

    // =========================================================================
    // State Machine
    // =========================================================================
    localparam STATE_LOAD   = 1'd0,
               STATE_UNLOAD = 1'd1;
    reg state;
    reg [COUNTER_BW - 1 : 0] frame_elem;  // Number of frame elements outputted.
                                          // Zero-indexed counting, so last
                                          // element is FRAME_LEN - 1
    always @(posedge clk_i) begin
        if (!rst_n_i | !en_i) begin
            frame_elem <= 'd0;
            state <= STATE_LOAD;
        end else begin
            case (state)
                STATE_LOAD: begin
                    frame_elem <= 'd0;
                    state      <= (fifo_count == FRAME_LEN) ? STATE_UNLOAD
                                                            : STATE_LOAD;
                end
                STATE_UNLOAD: begin
                    frame_elem <= frame_elem + 'd1;
                    state      <= (frame_elem == FRAME_LEN - 'd1) ? STATE_LOAD
                                                                 : STATE_UNLOAD;
                end
                default: begin
                    frame_elem <= 'd0;
                    state <= STATE_LOAD;
                end
            endcase
        end
    end

    // =========================================================================
    // FIFO element tracking
    // =========================================================================
    reg [COUNTER_BW - 1 : 0] fifo_count;  // number of elements in the fifo
    always @(posedge clk_i) begin
        if (!rst_n_i | !en_i) begin
            fifo_count <= 'd0;
        end else begin
            if (valid_i & !valid_o) begin
                fifo_count <= fifo_count + 'd1;
            end else if (!valid_i & valid_o) begin
                fifo_count <= fifo_count - 'd1;
            end else begin
                fifo_count <= fifo_count;
            end
        end
    end

    // =========================================================================
    // FIFO
    // =========================================================================
    wire signed [I_BW - 1 : 0]  fifo_dout;
    wire                        fifo_deq = (state == STATE_UNLOAD);
    fifo #(
        .DATA_WIDTH(I_BW),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) fifo_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i & en_i),

        .enq_i(valid_i),
        .din_i(data_i),

        .deq_i(fifo_deq),
        .dout_o(fifo_dout),

        .full_o_n(),
        .empty_o_n()
    );

    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign valid_o = (en_i & (state == STATE_UNLOAD));
    assign data_o = fifo_dout;
    assign last_o = ((state == STATE_UNLOAD) & (frame_elem == FRAME_LEN - 'd1));

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, framing);
        #1;
    end
    `endif

endmodule
