/*
 * 1D Convolution
 * Design: Eldrick Millares
 * Verification: Matthew Pauly
 * TODO: Handle deassertion of valid
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
    localparam FIFO_STATE_IDLE     = 2'd0,
               FIFO_STATE_PRELOAD  = 2'd1,
               FIFO_STATE_LOAD     = 2'd2,
               FIFO_STATE_CYCLE    = 2'd3;
    reg [1:0] fifo_state;

    reg [CYCLE_COUNT_BW - 1 :0] cycle_counter;

    wire last_i2 = last_i;

    always @(posedge clk_i) begin
        if (!rst_i_n) begin
            cycle_counter <= 'd0;
            fifo_state <= FIFO_STATE_IDLE;
        end else begin
            case (fifo_state)
                FIFO_STATE_IDLE: begin
                    cycle_counter <= 'd0;
                    fifo_state <= (valid_i) ? FIFO_STATE_PRELOAD : FIFO_STATE_IDLE;
                end
                FIFO_STATE_PRELOAD: begin
                    cycle_counter <= cycle_counter + 'd1;
                    fifo_state <= (cycle_counter == FILTER_SIZE) ? FIFO_STATE_LOAD: FIFO_STATE_PRELOAD;
                end
                FIFO_STATE_LOAD: begin
                    cycle_counter <= 'd0;
                    fifo_state <= (last_i2) ? FIFO_STATE_CYCLE: FIFO_STATE_LOAD;
                end
                FIFO_STATE_CYCLE: begin
                    cycle_counter <= cycle_counter + 'd1;
                    fifo_state <= (cycle_counter < MAX_CYCLES - 1) ? FIFO_STATE_CYCLE :
                                  ((valid_i) ? FIFO_STATE_PRELOAD : FIFO_STATE_IDLE);
                end
                default: begin
                    fifo_state <= FIFO_STATE_IDLE;
                end
            endcase
        end
    end
    // === End Conv1D FSM Logic ===

    // === Start Input FIFO Logic ===
    wire [VECTOR_BW - 1 : 0] fifo_din;
    wire [VECTOR_BW - 1 : 0] fifo_dout;

    wire fifo_enq;
    wire fifo_deq;
    wire fifo_not_full;
    wire fifo_not_empty;

    // Needed to ensure we do not drop the data in the first cycle "valid"
    // is asserted
    reg [VECTOR_BW - 1: 0] din_q;
    always @(posedge clk_i) begin
        din_q <= data_i;
    end

    // Assign din to input if loading, otherwise feedback output
    reg switch_inputs;
    always @(posedge clk_i) begin
        switch_inputs <= (fifo_state == FIFO_STATE_CYCLE);
    end

    assign fifo_din = switch_inputs ? fifo_out_sr[FILTER_SIZE - 1] : din_q;
    assign fifo_enq = (fifo_state == FIFO_STATE_IDLE) ? 0 : 1;

    assign fifo_deq = ((fifo_state == FIFO_STATE_CYCLE) | ((fifo_state == FIFO_STATE_PRELOAD) & (cycle_counter < FILTER_SIZE - 1)));
    assign sr_enq = (switch_inputs | (fifo_state == FIFO_STATE_PRELOAD));

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

        .full_o_n(fifo_not_full),
        .empty_o_n(fifo_not_empty)
    );

    // FIFO Output Shift Register
    reg [VECTOR_BW - 1 : 0] fifo_out_sr [FILTER_SIZE - 1 : 0];

    always @(posedge clk_i) begin
        if (sr_enq) begin
            fifo_out_sr[0] <= fifo_dout;
        end
    end

    generate
        for (i = 1; i < FILTER_SIZE; i = i + 1) begin: create_fifo_out_sr
            always @(posedge clk_i) begin
                if (sr_enq) begin
                    fifo_out_sr[i] <= fifo_out_sr[i-1];
                end
            end
        end
    endgenerate

    // TODO: Parametrize this shift register
    reg sr_valid_q, sr_valid_q2, sr_valid_q3;
    always @(posedge clk_i) begin
        sr_valid_q <= (fifo_state == FIFO_STATE_CYCLE);
        sr_valid_q2 <= sr_valid_q;
        sr_valid_q3 <= sr_valid_q2;
    end

    // TODO: Remove, temporary debug wires
    wire [VECTOR_BW - 1 : 0] sr0 = fifo_out_sr[0];
    wire [VECTOR_BW - 1 : 0] sr1 = fifo_out_sr[1];
    wire [VECTOR_BW - 1 : 0] sr2 = fifo_out_sr[2];

    assign data_o = fifo_out_sr[FILTER_SIZE - 1];
    assign valid_o = sr_valid_q;
    assign ready_o = ready_i;
    assign last_o = last_i;
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
