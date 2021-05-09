// =============================================================================
// Module:       Integrator
// Design:       Matthew Pauly
// Verification: Eldrick Millares
// Notes:
//
// Integrator element of the integrator-comb filter. Outputs the input added to
// the previous output. Input is either -1, 0, or 1. An input of -2 will be
// misinterpreted as a -1, so it is not allowed.
// =============================================================================

module integrator (
    // clock and reset
    input                               clk_i,
    input                               rst_n_i,

    // streaming input
    input                               en_i,
    input signed [1:0]                  data_i,
    input                               valid_i,

    // streaming output
    output [OUTPUT_BW - 1 : 0]          data_o,
    output                              valid_o
);

    // =========================================================================
    // Local Parameters
    // =========================================================================
    localparam OUTPUT_BW = 8;

    // =========================================================================
    // Accumulation Register
    // =========================================================================
    reg [OUTPUT_BW - 1 : 0] accumulated;
    always @(posedge clk_i) begin
        if (!rst_n_i | !en_i) begin
            accumulated <= 'd0;
        end else begin
            if (valid_i) begin
                accumulated <= data_o;
            end else begin
                accumulated <= accumulated;
            end
        end
    end
    
    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign data_o  = (data_i[1]) ? accumulated - 'd1
                                 : accumulated + data_i[0];
    assign valid_o = (en_i & valid_i);

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, integrator);
        #1;
    end
    `endif

endmodule
