// ============================================================================
// Zero Pad
// Design: Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// Adds 1 leading and 1 trailing zero to stream
//
// Minimum dead time between frames is 2 clock cycles.
// This increased dead-time is needed because we reduce latency in this
// module to just 1 cycle.
//
// TODO: Gate registers with valid
// ============================================================================

module zero_pad #(
    parameter BW = 8,
    parameter VECTOR_LEN = 13   // number of vector elements
) (
    input                                       clk_i,
    input                                       rst_n_i,

    input  signed [(VECTOR_LEN * BW) - 1 : 0] data_i,
    input                                       valid_i,
    input                                       last_i,
    output                                      ready_o,

    output signed [(VECTOR_LEN * BW) - 1 : 0] data_o,
    output                                      valid_o,
    output                                      last_o,
    input                                       ready_i
);


    // register all outputs
    reg signed [(VECTOR_LEN * BW) - 1 : 0] data_q, data_q2;
    reg valid_q, valid_q2, valid_q3, last_q, last_q2, last_q3, ready_q;
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            valid_q  <= 'b0;
            valid_q2 <= 'b0;
            valid_q3 <= 'b0;
            last_q   <= 'b0;
            last_q2  <= 'b0;
            last_q3  <= 'b0;
            ready_q  <= 'b0;
            data_q   <= 'b0;
            data_q2  <= 'b0;
        end else begin
            valid_q  <= valid_i;
            valid_q2 <= valid_q;
            valid_q3 <= valid_q2;
            last_q   <= last_i;
            last_q2  <= last_q;
            last_q3  <= last_q2;
            ready_q  <= ready_i;
            data_q   <= (valid_i) ? data_i : 0;
            data_q2  <= (valid_q) ? data_q : 0;
        end
    end

    // positive edge detector to emit initial 0
    wire valid_i_pos_edge  = valid_i  & (!valid_q);

    // negative edge detectors to extend valid_o, emit last 0
    wire valid_q_neg_edge  = valid_q2 & (!valid_q);
    wire valid_q2_neg_edge = valid_q3 & (!valid_q2);

    assign data_o  = (valid_q2_neg_edge | valid_i_pos_edge) ? 0 : data_q2;
    assign valid_o = valid_q | valid_q_neg_edge | valid_q2_neg_edge;
    assign last_o  = last_q3;
    assign ready_o = ready_q;

    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, zero_pad);
        #1;
    end
    `endif

endmodule
