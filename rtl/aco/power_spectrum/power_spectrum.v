// =============================================================================
// Module:       Power Spectrum
// Design:       Matthew Pauly
// Verification: Eldrick Millares
// Notes:        Computes the power spectrum of a frequency domain signal from
//               the fft wrapper, which is the real part squared added to the
//               imaginary part squared.
// =============================================================================

module power_spectrum (
    // clock and reset
    input                                   clk_i,
    input                                   rst_n_i,
    input                                   en_i,

    // streaming input
    input  signed [I_BW * 2 - 1 : 0]        data_i,
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
    localparam I_BW         = 21;
    localparam O_BW         = 32;

    // =========================================================================
    // Unpacked Data
    // =========================================================================
    wire signed [I_BW - 1 : 0] real_i = data_i[I_BW * 2 - 1 : I_BW];
    wire signed [I_BW - 1 : 0] imag_i = data_i[I_BW - 1 : 0];

    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign valid_o = (en_i & valid_i);
    assign data_o = (real_i * real_i) + (imag_i * imag_i);
    assign last_o = last_i;

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, power_spectrum);
        #1;
    end
    `endif

endmodule
