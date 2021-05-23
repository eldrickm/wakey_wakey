// =============================================================================
// Module:       Preemphasis
// Design:       Matthew Pauly
// Verification: Eldrick Millares
// Notes:        Implements a simple high-pass filter by multiplying the
//               delayed signal by 0.97 and subtracting that from the
//               undelayed signal. The multiplication is implemented as a
//               multiplication by 31 and a right-shift by 5.
// =============================================================================

module preemphasis (
    // clock and reset
    input                                   clk_i,
    input                                   rst_n_i,
    input                                   en_i,

    // streaming input
    input  signed [I_BW - 1 : 0]            data_i,
    input                                   valid_i,

    // streaming output
    output  signed [O_BW - 1 : 0]           data_o,
    output                                  valid_o
);
    // =========================================================================
    // Local Parameters
    // =========================================================================
    localparam I_BW         = 8;   // PCM input
    localparam O_BW         = 9;
    localparam MUL          = 31;
    localparam SHIFT        = 5;

    // =========================================================================
    // Delayed and scaled data
    // =========================================================================
    reg signed [I_BW - 1 : 0] data_q;
    always @(posedge clk_i) begin
        if (!rst_n_i | !en_i) begin
            data_q <= 'd0;
        end else begin
            if (valid_i) begin
                data_q <= data_i;
            end else begin
                data_q <= data_q;
            end
        end
    end
    wire signed [O_BW - 1 : 0] data_scaled = (data_q * MUL) >>> SHIFT;

    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign valid_o = (en_i & valid_i);
    assign data_o = data_i - data_scaled;

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    `ifndef SCANNED
    `define SCANNED
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, preemphasis);
        #1;
    end
    `endif
    `endif

endmodule
