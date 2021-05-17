// =============================================================================
// Module:       Filterbank
// Design:       Matthew Pauly
// Verification: Eldrick Millares
// Notes:        Takes in an input power spectrum and multiplies it by MFCC
//               overlapping triangular windows.
//               Deassertions of valid are not permitted.
// =============================================================================

module filterbank (
    // clock and reset
    input                                   clk_i,
    input                                   rst_n_i,
    input                                   en_i,

    // streaming input
    input         [I_BW - 1 : 0]            data_i,
    input                                   valid_i,
    input                                   last_i,

    // streaming output
    output         [O_BW - 1 : 0]           data_o,
    output                                  valid_o,
    output                                  last_o
);
    // =========================================================================
    // Local Parameters
    // =========================================================================
    localparam I_BW         = 32;
    localparam INTERNAL_BW  = 64;   // 48 would be sufficient but why not
    localparam O_BW         = 32;
    localparam COEF_BW      = 16;   // bitwidth of the filterbank coefficients
    localparam INPUT_LEN    = 129;  // length of the power spectrum
    localparam NUM_BOUNDARY = 16;   // number of triangle boundary indices
                                    // Signals when a MFCC coefficient is done
    localparam BOUNDARY_BW  = 8;

    localparam EVEN_COEFFILE            = "coef_even.hex";
    localparam ODD_COEFFILE             = "coef_odd.hex";
    localparam EVEN_BOUNDARYFILE        = "boundary_even.hex";
    localparam ODD_BOUNDARYFILE         = "boundary_odd.hex";

    // =========================================================================
    // Even and Odd Filterbanks
    // =========================================================================
    wire [O_BW - 1 : 0] data_even;
    wire valid_even, last_even;
    filterbank_half #(
        .COEFFILE(EVEN_COEFFILE),
        .BOUNDARYFILE(EVEN_BOUNDARYFILE)
    ) even_filterbanks (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .data_i(data_i),
        .valid_i(valid_i),
        .last_i(last_i),

        .data_o(data_even),
        .valid_o(valid_even),
        .last_o(last_even)
    );

    wire [O_BW - 1 : 0] data_odd;
    wire valid_odd, last_odd;
    filterbank_half #(
        .COEFFILE(ODD_COEFFILE),
        .BOUNDARYFILE(ODD_BOUNDARYFILE)
    ) odd_filterbanks (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .data_i(data_i),
        .valid_i(valid_i),
        .last_i(last_i),

        .data_o(data_odd),
        .valid_o(valid_odd),
        .last_o(last_odd)
    );

    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign valid_o = (en_i & (valid_even | valid_odd));
    assign data_o = valid_even ? data_even : data_odd;
    assign last_o = last_i;

    // ========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // ========================================================================
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, filterbank);
        #1;
    end
    `endif

endmodule
