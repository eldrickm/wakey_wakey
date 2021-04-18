// ============================================================================
// Convolution Serial In, Parallel Out
// Design: Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// ============================================================================

module conv_sipo #(
    parameter BW          = 8,
    parameter FRAME_LEN   = 50,
    parameter COLUMN_LEN  = 8
) (
    input                                      clk_i,
    input                                      rst_n_i,

    input  signed [(COLUMN_LEN  * BW) - 1 : 0] data_i,
    input                                      valid_i,
    input                                      last_i,
    output                                     ready_o,

    output signed [(COLUMN_LEN  * BW) - 1 : 0] data0_o,
    output                                     valid_o,
    output                                     last_o,
    input                                      ready_i
);

    reg [FRAME_LEN - 1 : 0] fifo_sel;
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            fifo_sel <= {{FRAME_LEN - 1{1'b0}}, 1'b1};
        end else begin
            fifo_sel <= (last_i) ? fifo_sel << 1 : fifo_sel;
    end

    // genvar i;
    //
    // // ========================================================================
    // // Local Parameters
    // // ========================================================================
    // // This unit is hard coded for width 3 filters
    // localparam FILTER_LEN = 3;
    // localparam MAX_CYCLES = NUM_FILTERS * FRAME_LEN;
    //
    // // Bitwidth Definitions
    // localparam VECTOR_BW  = COLUMN_LEN  * BW;
    // localparam COUNTER_BW = $clog2(MAX_CYCLES);
    // // ========================================================================
    //
    // // ========================================================================
    // // Recycler Controller
    // // TODO: Fix initial deque errors
    // // ========================================================================
    // // Define States
    // localparam STATE_IDLE    = 2'd0,
    //            STATE_PRELOAD = 2'd1,
    //            STATE_LOAD    = 2'd2,
    //            STATE_CYCLE   = 2'd3;
    //
    // reg [1:0] state;
    // reg [COUNTER_BW - 1 : 0] counter;
    //
    // // TODO: Handle deassertions of valid midstream
    // always @(posedge clk_i) begin
    //     if (!rst_n_i) begin
    //         counter <= 'd0;
    //         state <= STATE_IDLE;
    //     end else begin
    //         case (state)
    //             STATE_IDLE: begin
    //                 // FIFO State only transitions to PRELOAD on valid input
    //                 counter <= 'd0;
    //                 state   <= (valid_i) ? STATE_PRELOAD : STATE_IDLE;
    //             end
    //             STATE_PRELOAD: begin
    //                 // In PRELOAD, we're shifting the first FILTER_LEN - 1
    //                 // elements into our shift register, then transition
    //                 // to regular LOAD where the shift register is not active
    //                 counter <= counter + 'd1;
    //                 state   <= (counter == FILTER_LEN) ? STATE_LOAD :
    //                                                      STATE_PRELOAD;
    //             end
    //             STATE_LOAD: begin
    //                 // In LOAD we're just shifting enough elements until
    //                 // last_i is asserted
    //                 counter <= 'd0;
    //                 state   <= (last_i) ? STATE_CYCLE: STATE_LOAD;
    //             end
    //             STATE_CYCLE: begin
    //                 // In CYCLE, we begin cycling MAX_CYCLE times.
    //                 // If valid_i is high, we transition straight into
    //                 // PRELOAD again since a new frame is immediately
    //                 // available.
    //                 // If valid_i is deasserted, we transition into IDLE
    //                 // and wait on the next input blocks to come in
    //                 counter <= counter + 'd1;
    //                 state   <= (counter < MAX_CYCLES - 1) ? STATE_CYCLE :
    //                            ((valid_i) ? STATE_PRELOAD : STATE_IDLE);
    //             end
    //             default: begin
    //                 counter <= 'd0;
    //                 state   <= STATE_IDLE;
    //             end
    //         endcase
    //     end
    // end
    // // ========================================================================
    //
    // // ========================================================================
    // // Recycling FIFO
    // // TODO: Fix initial deque errors
    // // ========================================================================
    // // Needed to ensure we do not drop data_i the first cycle "valid"
    // // is asserted
    // reg [VECTOR_BW - 1: 0] data_i_q;
    // always @(posedge clk_i) begin
    //     data_i_q <= data_i;
    // end
    //
    // // Delayed by 1 cycle since data_i_q is delayed by one cycle
    // reg fifo_recycle;
    // always @(posedge clk_i) begin
    //     fifo_recycle <= (state == STATE_CYCLE);
    // end
    //
    // // Assign din to input if loading, otherwise feedback output to recycle
    // wire [VECTOR_BW - 1 : 0] fifo_din;
    // assign fifo_din = fifo_recycle ? fifo_out_sr[FILTER_LEN - 1] : data_i_q;
    //
    // // Always enqueue if FIFO is not idle
    // wire fifo_enq;
    // assign fifo_enq = !(state == STATE_IDLE);
    //
    // // Dequeue the FIFO when we begin recycling
    // // or dequeue the FIFO exactly FILTER_LEN - 1 times when Preloading
    // wire fifo_deq;
    // assign fifo_deq = ((state == STATE_CYCLE) |
    //                    ((state == STATE_PRELOAD) &
    //                     (counter < FILTER_LEN - 1)));
    //
    // wire [VECTOR_BW - 1 : 0] fifo_dout;
    //
    // fifo #(
    //     .DATA_WIDTH(VECTOR_BW),
    //     .FIFO_DEPTH(FRAME_LEN)
    // ) fifo_inst (
    //     .clk_i(clk_i),
    //     .rst_n_i(rst_n_i),
    //
    //     .enq_i(fifo_enq),
    //     .deq_i(fifo_deq),
    //
    //     .din_i(fifo_din),
    //     .dout_o(fifo_dout),
    //
    //     // TODO: Handle Full and Empty
    //     .full_o_n(),
    //     .empty_o_n()
    // );
    //
    // // FIFO Output Shift Register Enable
    // wire sr_en;
    // assign sr_en = (fifo_recycle | (state == STATE_PRELOAD));
    //
    // // FIFO Output Shift Register
    // reg [VECTOR_BW - 1 : 0] fifo_out_sr [FILTER_LEN - 1 : 0];
    // always @(posedge clk_i) begin
    //     if (sr_en) begin
    //         fifo_out_sr[0] <= fifo_dout;
    //     end
    // end
    // for (i = 1; i < FILTER_LEN; i = i + 1) begin: create_fifo_out_sr
    //     always @(posedge clk_i) begin
    //         if (sr_en) begin
    //             fifo_out_sr[i] <= fifo_out_sr[i-1];
    //         end
    //     end
    // end
    //
    // // FIFO Output Valid Shift Register
    // reg fifo_out_valid;
    // always @(posedge clk_i) begin
    //     fifo_out_valid <= (state == STATE_CYCLE);
    // end
    // // ========================================================================
    //
    // // ========================================================================
    // // Output Assignment
    // // ========================================================================
    // assign data0_o = fifo_out_sr[0];
    // assign data1_o = fifo_out_sr[1];
    // assign data2_o = fifo_out_sr[2];
    // assign valid_o = fifo_out_valid;
    // assign ready_o = ready_i;
    // assign last_o  = last_i;
    // // ========================================================================
    //
    // ========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // ========================================================================
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, conv_sipo);
        #1;
    end
    `endif
    // ========================================================================

endmodule
