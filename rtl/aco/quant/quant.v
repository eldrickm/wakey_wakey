// =============================================================================
// Module:       ACO Quantizer
// Design:       Matthew Pauly
// Verification: Eldrick Millares
// Notes:        
//
// Quantize 16b values to 8b values such that they saturate if they don't fit
// within 8b.
// =============================================================================

module quant (
    // clock and reset
    input                                   clk_i,
    input                                   rst_n_i,
    input                                   en_i,

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
    localparam CLIP         = $pow(2, O_BW - 1) - 1;  // clip to this if larger

    wire signed [O_BW - 1 : 0] lower = data_i[O_BW - 1 : 0]; // lower O_BW bits

    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign data_o = (data_i > CLIP) ? CLIP 
                                    : ((data_i < -CLIP-1) ? -CLIP-1
                                                          : lower);
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
