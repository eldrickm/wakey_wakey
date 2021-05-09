// =============================================================================
// Module:       Decimator
// Design:       Matthew Pauly
// Verification: Eldrick Millares
// Notes:
//
// Decimates input by a given rate. This component is used after the integrator-
// comb filter
// =============================================================================

module decimator (
    // clock and reset
    input                       clk_i,
    input                       rst_n_i,

    // streaming input
    input                       en_i,
    input [DATA_BW - 1 : 0]     data_i,
    input                       valid_i,

    // streaming output
    output [DATA_BW - 1 : 0]    data_o,
    output                      valid_o
);

    // =========================================================================
    // Local Parameters
    // =========================================================================
    localparam DATA_BW = 8;
    localparam DECIM_FACTOR = 250;
    localparam COUNTER_BW = $clog2(DECIM_FACTOR);

    // =========================================================================
    // Counter
    // =========================================================================
    reg [COUNTER_BW - 1 : 0] counter;  // counts 0 to 249
    always @(posedge clk_i) begin
        if (!rst_n_i | !en_i) begin
            counter <= 'd0;
        end else begin
            if (valid_i & (counter == DECIM_FACTOR - 1)) begin
                counter <= 'd0;
            end else if (valid_i) begin
                counter <= counter + 'd1;
            end else begin
                counter <= counter;
            end
        end
    end
    
    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign data_o  = data_i;
    assign valid_o = (en_i & valid_i & (counter == 'd0));

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, decimator);
        #1;
    end
    `endif

endmodule
