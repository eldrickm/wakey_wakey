// ============================================================================
// Module:       Maximum
// Design:       Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// INFO: Hard coded for 2 elements.
// ============================================================================

module argmax #(
    parameter I_BW = 24,

    // =========================================================================
    // Local Parameters - Do Not Edit
    // =========================================================================
    parameter VECTOR_LEN = 2
) (
    // clock and reset
    input                                       clk_i,
    input                                       rst_n_i,

    // streaming input
    input  signed [(VECTOR_LEN * I_BW) - 1 : 0] data_i,
    input                                       valid_i,
    input                                       last_i,
    output                                      ready_o,

    // streaming output
    output signed [VECTOR_LEN - 1 : 0]          data_o,
    output                                      valid_o,
    output                                      last_o,
    input                                       ready_i
);

    genvar i;

    // =========================================================================
    // Input Unpacking
    // =========================================================================
    wire signed [I_BW - 1 : 0] data_arr [VECTOR_LEN - 1 : 0];
    for (i = 0; i < VECTOR_LEN; i = i + 1) begin: unpack_inputs
        assign data_arr[i] = data_i[(i + 1) * I_BW - 1 : i * I_BW];
    end

    // =========================================================================
    // Max
    // =========================================================================
    wire [VECTOR_LEN - 1 : 0] argmax_one_hot;
    reg  [VECTOR_LEN - 1 : 0] argmax_one_hot_q;

    assign argmax_one_hot = (data_arr[0] > data_arr[1]) ? 'b01 : 'b10;

    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            argmax_one_hot_q <= 'd0;
        end else begin
            argmax_one_hot_q <= argmax_one_hot;
        end
    end

    // =========================================================================
    // Output Assignment
    // =========================================================================
    // register all outputs
    reg valid_q, last_q, ready_q;
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            valid_q <= 'b0;
            last_q  <= 'b0;
            ready_q <= 'b0;
        end else begin
            valid_q <= valid_i;
            last_q  <= last_i;
            ready_q <= ready_i;
        end
    end

    assign data_o   = argmax_one_hot_q;
    assign valid_o  = valid_q;
    assign last_o   = last_q;
    assign ready_o  = ready_q;

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    `ifndef SCANNED
    `define SCANNED
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, argmax);
        #1;
    end
    `endif
    `endif

endmodule
