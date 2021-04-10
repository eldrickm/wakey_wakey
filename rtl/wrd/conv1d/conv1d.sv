/*
 * 1D Convolution
 * Design: Eldrick Millares
 * Verification: Matthew Pauly
 * Notes:
 *  FRAME_SIZE > FILTER_SIZE
 *  FILTER_SIZE > 1
 */

module conv1d #(
    parameter FRAME_SIZE  = 50,
    parameter VECTOR_SIZE = 1,
    parameter NUM_FILTERS = 8
) (
    input                                      clk_i,
    input                                      rst_i_n,

    input  signed [(VECTOR_SIZE * BW) - 1 : 0] data_i,
    input                                      valid_i,
    input                                      last_i,
    output                                     ready_o,

    output signed [(VECTOR_SIZE * BW) - 1 : 0] data_o,
    output                                     valid_o,
    output                                     last_o,
    input                                      ready_i
);

    localparam BW             = 8;
    localparam MUL_OUT_BW     = 32;
    localparam ADD_OUT_BW     = 33;
    localparam FILTER_SIZE    = 3;
    localparam VECTOR_BW      = VECTOR_SIZE * BW;
    localparam MAX_CYCLES     = NUM_FILTERS * FRAME_SIZE;
    localparam CYCLE_COUNT_BW = $clog2(MAX_CYCLES);

    genvar i;

    // === Start Conv1D FSM Logic ===
    // Define FIFO States
    localparam STATE_IDLE     = 2'd0,
               STATE_PRELOAD  = 2'd1,
               STATE_LOAD     = 2'd2,
               STATE_CYCLE    = 2'd3;

    reg [1:0] fifo_state;
    reg [CYCLE_COUNT_BW - 1 :0] state_counter;

    // TODO: Handle deassertions of valid midstream
    always @(posedge clk_i) begin
        if (!rst_i_n) begin
            state_counter <= 'd0;
            fifo_state <= STATE_IDLE;
        end else begin
            case (fifo_state)
                STATE_IDLE: begin
                    // FIFO State only transitions to PRELOAD on valid input
                    state_counter <= 'd0;
                    fifo_state    <= (valid_i) ? STATE_PRELOAD : STATE_IDLE;
                end
                STATE_PRELOAD: begin
                    // In PRELOAD, we're shifting the first FILTER_SIZE - 1
                    // elements into our shift register, then transition
                    // to regular LOAD where the shift register is not active
                    state_counter <= state_counter + 'd1;
                    fifo_state    <= (state_counter == FILTER_SIZE) ?
                                      STATE_LOAD: STATE_PRELOAD;
                end
                STATE_LOAD: begin
                    // In LOAD we're just shifting enough elements until
                    // last_i is asserted
                    state_counter <= 'd0;
                    fifo_state    <= (last_i) ? STATE_CYCLE: STATE_LOAD;
                end
                STATE_CYCLE: begin
                    // In CYCLE, we begin cycling MAX_CYCLE times.
                    // If valid_i is high, we transition straight into
                    // PRELOAD again since a new frame is immediately
                    // available.
                    // If valid_i is deasserted, we transition into IDLE
                    // and wait on the next input blocks to come in
                    state_counter <= state_counter + 'd1;
                    fifo_state    <= (state_counter < MAX_CYCLES - 1) ?
                                      STATE_CYCLE :
                                      ((valid_i) ? STATE_PRELOAD : STATE_IDLE);
                end
                default: begin
                    state_counter <= 'd0;
                    fifo_state <= STATE_IDLE;
                end
            endcase
        end
    end
    // === End Conv1D FSM Logic ===

    // === Start Input FIFO Logic ===
    // Needed to ensure we do not drop data_i the first cycle "valid"
    // is asserted
    reg [VECTOR_BW - 1: 0] data_i_q;
    always @(posedge clk_i) begin
        data_i_q <= data_i;
    end

    // Delayed by 1 cycle since data_i_q is delayed by one cycle
    reg fifo_recycle;
    always @(posedge clk_i) begin
        fifo_recycle <= (fifo_state == STATE_CYCLE);
    end

    // Assign din to input if loading, otherwise feedback output to recycle
    wire [VECTOR_BW - 1 : 0] fifo_din;
    assign fifo_din = fifo_recycle ? fifo_out_sr[FILTER_SIZE - 1] : data_i_q;

    // Always enqueue if FIFO is not idle
    wire fifo_enq;
    assign fifo_enq = !(fifo_state == STATE_IDLE);

    // Dequeue the FIFO when we begin recycling
    // or dequeue the FIFO exactly FILTER_SIZE - 1 times when Preloading
    wire fifo_deq;
    assign fifo_deq = ((fifo_state == STATE_CYCLE) |
                       ((fifo_state == STATE_PRELOAD) &
                        (state_counter < FILTER_SIZE - 1)));

    wire [VECTOR_BW - 1 : 0] fifo_dout;

    fifo #(
        .DATA_WIDTH(VECTOR_BW),
        .FIFO_DEPTH(FRAME_SIZE)
    ) conv1d_input_fifo_inst (
        .clk_i(clk_i),
        .rst_i_n(rst_i_n),

        .enq_i(fifo_enq),
        .deq_i(fifo_deq),

        .din_i(fifo_din),
        .dout_o(fifo_dout),

        // TODO: Handle Full and Empty
        .full_o_n(),
        .empty_o_n()
    );

    // FIFO Output Shift Register
    assign sr_enq = (fifo_recycle | (fifo_state == STATE_PRELOAD));

    reg [VECTOR_BW - 1 : 0] fifo_out_sr [FILTER_SIZE - 1 : 0];
    always @(posedge clk_i) begin
        if (sr_enq) begin
            fifo_out_sr[0] <= fifo_dout;
        end
    end
    for (i = 1; i < FILTER_SIZE; i = i + 1) begin: create_fifo_out_sr
        always @(posedge clk_i) begin
            if (sr_enq) begin
                fifo_out_sr[i] <= fifo_out_sr[i-1];
            end
        end
    end

    // FIFO Output Valid Shift Register
    reg [FILTER_SIZE - 1 : 0]sr_valid_q;
    always @(posedge clk_i) begin
        sr_valid_q[0] <= (fifo_state == STATE_CYCLE);
    end
    for (i = 1; i < FILTER_SIZE; i = i + 1) begin: create_sr_valid_sr
        always @(posedge clk_i) begin
            sr_valid_q[i] <= sr_valid_q[i-1];
        end
    end
    // === End Input FIFO Logic ===

    // Weight Bank

    // Weight Bank Registers

    // SIMD Multiplication
    // generate
    //     for (i = 0; i < FILTER_SIZE; i = i + 1) begin: unpack_inputs
    //         vec_mul #(
    //             .BW_I(BW),
    //             .BW_O(MUL_OUT_BW),
    //             .FILTER_SIZE(FILTER_SIZE)
    //         ) vec_mul_inst_1 (
    //             .clk_i(clk_i),
    //             .rst_ni(rst_ni),
    //
    //             .data1_i(),
    //             .valid1_i(),
    //             .last1_i(),
    //             .ready1_o(),
    //
    //             .data2_i(),
    //             .valid2_i(),
    //             .last2_i(),
    //             .ready2_o(),
    //
    //             .data_o(),
    //             .valid_o(),
    //             .last_o(),
    //             .ready_i()
    //         );
    //     end
    // endgenerate

    // SIMD Addition

    // Bias Register

    // Quantization Scaling

    // Output Assignment
    assign data_o  = fifo_out_sr[FILTER_SIZE - 1];
    assign valid_o = sr_valid_q;
    assign ready_o = ready_i;
    assign last_o  = last_i;

    // Simulation Only Waveform Dump (.vcd export)
    `ifdef COCOTB_SIM
    initial begin
      $dumpfile ("conv1d.vcd");
      $dumpvars (0, conv1d);
      #1;
    end
    `endif

endmodule
