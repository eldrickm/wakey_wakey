// ============================================================================
// Module:       Reduction Addition
// Design:       Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// TODO: Can we make elements in sum minimum length?
// ============================================================================

module red_add #(
    parameter I_BW = 18,
    parameter O_BW = 32,
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
    output signed [O_BW - 1 : 0]                data_o,
    output                                      valid_o,
    output                                      last_o,
    input                                       ready_i
);

    genvar i;

    // =========================================================================
    // Input Unpacking
    // =========================================================================
    // unpacked arrays
    wire signed [I_BW - 1 : 0] data_arr [VECTOR_LEN - 1 : 0];
    wire signed [O_BW - 1 : 0] sum      [VECTOR_LEN - 1 : 0];
    reg  signed [O_BW - 1 : 0] final_sum_q;

    // unpack data input
    for (i = 0; i < VECTOR_LEN; i = i + 1) begin: unpack_inputs
        assign data_arr[i] = data_i[(i + 1) * I_BW - 1 : i * I_BW];
    end

    // =========================================================================
    // Reduction Addition
    // =========================================================================
    for (i = 1; i < VECTOR_LEN; i = i + 1) begin: reduction_sum
         if (i == 1) begin
             assign sum[i] = data_arr[i] + data_arr[i-1];
         end else begin
             assign sum[i] = sum[i-1] + data_arr[i];
         end
    end

    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            final_sum_q <= 'd0;
        end else begin
            final_sum_q <= sum[VECTOR_LEN - 1];
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

    assign data_o   = final_sum_q;
    assign valid_o  = valid_q;
    assign last_o   = last_q;
    assign ready_o = ready_q;

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    `ifndef SCANNED
    `define SCANNED
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, red_add);
        #1;
    end
    `endif
    `endif

endmodule
