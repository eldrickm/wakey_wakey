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
    input                                      clk_i,
    input                                      rst_n_i,

    input  signed [(COLUMN_LEN  * BW) - 1 : 0] data_i,
    input                                      valid_i,
    input                                      last_i,
    output                                     ready_o,

    output signed [(COLUMN_LEN  * BW) - 1 : 0] data_o,
    output                                     valid_o,
    output                                     last_o,
    input                                      ready_i
);

    // Bitwidth Definitions
    localparam BW             = 8;
    localparam MUL_OUT_BW     = 16;
    localparam ADD_OUT_BW     = 18;
    localparam VECTOR_BW      = COLUMN_LEN  * BW;

    localparam FILTER_LEN    = 3;
    localparam MAX_CYCLES     = NUM_FILTERS * FRAME_LEN;
    localparam CYCLE_COUNT_BW = $clog2(MAX_CYCLES);

    genvar i;

    // === Start Conv1D FSM Logic ===
    // TODO: Fix initial deque errors
    // Define FIFO States
    localparam STATE_IDLE     = 2'd0,
               STATE_PRELOAD  = 2'd1,
               STATE_LOAD     = 2'd2,
               STATE_CYCLE    = 2'd3;

    reg [1:0] fifo_state;
    reg [CYCLE_COUNT_BW - 1 :0] state_counter;

    // TODO: Handle deassertions of valid midstream
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
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
                    // In PRELOAD, we're shifting the first FILTER_LEN - 1
                    // elements into our shift register, then transition
                    // to regular LOAD where the shift register is not active
                    state_counter <= state_counter + 'd1;
                    fifo_state    <= (state_counter == FILTER_LEN) ?
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
    assign fifo_din = fifo_recycle ? fifo_out_sr[FILTER_LEN - 1] : data_i_q;

    // Always enqueue if FIFO is not idle
    wire fifo_enq;
    assign fifo_enq = !(fifo_state == STATE_IDLE);

    // Dequeue the FIFO when we begin recycling
    // or dequeue the FIFO exactly FILTER_LEN - 1 times when Preloading
    wire fifo_deq;
    assign fifo_deq = ((fifo_state == STATE_CYCLE) |
                       ((fifo_state == STATE_PRELOAD) &
                        (state_counter < FILTER_LEN - 1)));

    wire [VECTOR_BW - 1 : 0] fifo_dout;

    fifo #(
        .DATA_WIDTH(VECTOR_BW),
        .FIFO_DEPTH(FRAME_LEN)
    ) fifo_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        .enq_i(fifo_enq),
        .deq_i(fifo_deq),

        .din_i(fifo_din),
        .dout_o(fifo_dout),

        // TODO: Handle Full and Empty
        .full_o_n(),
        .empty_o_n()
    );

    // FIFO Output Shift Register Enable
    wire sr_en;
    assign sr_en = (fifo_recycle | (fifo_state == STATE_PRELOAD));

    // FIFO Output Shift Register
    reg [VECTOR_BW - 1 : 0] fifo_out_sr [FILTER_LEN - 1 : 0];
    always @(posedge clk_i) begin
        if (sr_en) begin
            fifo_out_sr[0] <= fifo_dout;
        end
    end
    for (i = 1; i < FILTER_LEN; i = i + 1) begin: create_fifo_out_sr
        always @(posedge clk_i) begin
            if (sr_en) begin
                fifo_out_sr[i] <= fifo_out_sr[i-1];
            end
        end
    end

    // FIFO Output Valid Shift Register
    reg fifo_out_valid;
    always @(posedge clk_i) begin
        fifo_out_valid <= (fifo_state == STATE_CYCLE);
    end
    // === End Input FIFO Logic ===

    // Weight Bank

    // Weight Bank Registers

    // Vector Multiplication
    wire [MUL_OUT_BW - 1 : 0] vec_mul_data_out  [FILTER_LEN - 1 : 0];
    wire                      vec_mul_valid_out [FILTER_LEN - 1 : 0];
    wire                      vec_mul_last_out  [FILTER_LEN - 1 : 0];
    wire                      vec_mul_ready1_out  [FILTER_LEN - 1 : 0];
    wire                      vec_mul_ready2_out  [FILTER_LEN - 1 : 0];

    for (i = 0; i < FILTER_LEN; i = i + 1) begin: vector_multiply
        vec_mul #(
            .BW_I(BW),
            .BW_O(MUL_OUT_BW),
            .VECTOR_LEN(COLUMN_LEN)
        ) vec_mul_inst (
            .clk_i(clk_i),
            .rst_n_i(rst_n_i),

            .data1_i(fifo_out_sr[i]),
            .valid1_i(fifo_out_valid),
            // TODO: Deal with ready
            .last1_i(1'b0),
            .ready1_o(vec_mul_ready1_out[i]),

            // TODO: Hook up to memory
            .data2_i(8'd1),
            .valid2_i(1'b1),
            .last2_i(1'b0),
            .ready2_o(vec_mul_ready2_out[i]),

            .data_o(vec_mul_data_out[i]),
            .valid_o(vec_mul_valid_out[i]),
            .last_o(vec_mul_last_out[i]),
            // TODO: Deal with Ready
            .ready_i(1'b1)
        );
    end

    // Vector Addition
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

        .data1_i(vec_mul_data_out[0]),
        .valid1_i(vec_mul_valid_out[0]),
        .last1_i(vec_mul_last_out[0]),
        .ready1_o(vec_add_ready_out[0]),

        .data2_i(vec_mul_data_out[1]),
        .valid2_i(vec_mul_valid_out[1]),
        .last2_i(vec_mul_last_out[1]),
        .ready2_o(vec_add_ready_out[0]),

        .data3_i(vec_mul_data_out[2]),
        .valid3_i(vec_mul_valid_out[2]),
        .last3_i(vec_mul_last_out[2]),
        .ready3_o(vec_add_ready_out[0]),

        .data_o(vec_add_data_out),
        .valid_o(vec_add_valid_out),
        .last_o(vec_add_last_out),
        .ready_i(1'b1)
    );

    // Bias Register

    // Quantization Scaling

    // Output Assignment
    assign data_o  = fifo_out_sr[FILTER_LEN - 1];
    assign valid_o = fifo_out_valid;
    assign ready_o = ready_i;
    assign last_o  = last_i;

    // Simulation Only Waveform Dump (.vcd export)
    `ifdef COCOTB_SIM
    initial begin
      $dumpfile ("wave.vcd");
      $dumpvars (0, conv1d);
      #1;
    end
    `endif

endmodule
