/*
 * 1D Convolution
 */

`define STATE_IDLE '

module conv1d #(
    parameter BW = 8,
    parameter FRAME_SIZE = 50,
    parameter VECTOR_SIZE = 13
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

    localparam FILTER_SIZE = 3;
    localparam VECTOR_BW = VECTOR_SIZE * BW;

    genvar i;

    // === Start Conv1D FSM Logic ===
    // TODO: What is size of state reg?
    reg [4:0] conv1d_state;
    always @(posedge clk) begin
        if (!rst_i_n) begin
            if (valid_i) begin
                conv1d_state <= `STATE_LOAD;
            end
        end else begin
            conv1d_state <= `STATE_IDLE;
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
        fifo_out_sr[0] <= fifo_dout;
    end

    generate
        for (i = 1; i < FILTER_SIZE; i = i + 1) begin: create_fifo_out_sr
            always @(posedge clk_i) begin
                fifo_out_sr[i] <= fifo_out_sr[i-1];
            end
        end
    endgenerate
    // === End Input FIFO Logic ===

    // Weight Bank

    // Weight Bank Registers

    // SIMD Multiplication
    // generate
    //     for (i = 0; i < FILTER_SIZE; i = i + 1) begin: unpack_inputs
    //
    // vec_mul #(
    //     .BW(BW),
    //     .FILTER_SIZE(FILTER_SIZE)
    // ) vec_mul_inst_1 (
    //     .clk_i(),
    //     .rstn_i(),
    //
    //     .data1_i(),
    //     .valid1_i(),
    //     .last1_i(),
    //     .ready1_o(),
    //
    //     .data2_i(),
    //     .valid2_i(),
    //     .last2_i(),
    //     .ready2_o(),
    //
    //     .data_o(),
    //     .valid_o(),
    //     .last_o(),
    //     .ready_i()
    // );
    // endgenerate

    // SIMD Addition

    // Bias Register

    // Quantization Scaling

    // Simulation Only Waveform Dump (.vcd export)
    `ifdef COCOTB_SIM
    initial begin
      $dumpfile ("conv1d.vcd");
      $dumpvars (0, conv1d);
      #1;
    end
    `endif

endmodule
