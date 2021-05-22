// =============================================================================
// Module:       ACO Quantizer
// Design:       Matthew Pauly
// Verification: Eldrick Millares
// Notes:        
//
// Takes in a 16b value and right shifts is by some amount that is
// configurable from CFG.
// =============================================================================

module quant (
    // clock and reset
    input                                   clk_i,
    input                                   rst_n_i,
    input                                   en_i,

    input  [SHIFT_BW - 1 : 0]               shift_i,
    input                                   wr_en,

    // streaming input
    input  signed [I_BW - 1 : 0]            data_i,
    input                                   valid_i,
    input                                   last_i,

    // streaming output
    output  signed [O_BW - 1 : 0]           data_o,
    output                                  valid_o,
    output                                  last_o
);
    // =========================================================================
    // Local Parameters
    // =========================================================================
    localparam I_BW         = 16;
    localparam O_BW         = 8;
    localparam SHIFT_BW     = 8;

    reg [SHIFT_BW - 1 : 0] shift;  // amount to shift by
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            shift <= 'd0;
        end else begin
            if (wr_en) begin
                shift <= shift_i;
            end else begin
                shift <= shift;
            end
        end
    end

    wire signed [I_BW - 1 : 0] shifted = data_i >>> shift;

    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign data_o = shifted[O_BW - 1 : 0];  // take lower bits
    assign valid_o = (en_i & valid_i);
    assign last_o  = last_i;

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    `ifndef SCANNED
    `define SCANNED
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, quant);
        #1;
    end
    `endif
    `endif

endmodule
