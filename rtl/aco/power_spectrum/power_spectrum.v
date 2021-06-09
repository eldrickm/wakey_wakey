// =============================================================================
// Module:       Power Spectrum
// Design:       Matthew Pauly
// Verification: Eldrick Millares
// Notes:        Computes the power spectrum of a frequency domain signal from
//               the fft wrapper, which is the real part squared added to the
//               imaginary part squared.
// =============================================================================

module power_spectrum #(
    // =========================================================================
    // Local Parameters - Do Not Edit
    // =========================================================================
    parameter I_BW = 21,
    parameter O_BW = 32
) (
    // clock and reset
    input                                   clk_i,
    input                                   rst_n_i,
    input                                   en_i,

    // streaming input
    input  signed [I_BW * 2 - 1 : 0]        data_i,
    input                                   valid_i,
    input                                   last_i,

    // streaming output
    output [O_BW - 1 : 0]                   data_o,
    output                                  valid_o,
    output                                  last_o
);

    // =========================================================================
    // Register input to reduce long path length
    // =========================================================================
    reg signed [I_BW * 2 - 1 : 0] data_i_q;
    reg valid_i_q;
    reg last_i_q;
    always @(posedge clk_i) begin
        if (!rst_n_i | !en_i) begin
            data_i_q <= 'd0;
            valid_i_q <= 'd0;
            last_i_q <= 'd0;
        end else begin
            if (valid_i) begin
                data_i_q <= data_i;
                valid_i_q <= valid_i;
                last_i_q <= last_i;
            end else begin
                data_i_q <= 'd0;
                valid_i_q <= 'd0;
                last_i_q <= 'd0;
            end
        end
    end

    // =========================================================================
    // Unpacked Data
    // =========================================================================
    wire signed [I_BW - 1 : 0] real_i = data_i_q[I_BW * 2 - 1 : I_BW];
    wire signed [I_BW - 1 : 0] imag_i = data_i_q[I_BW - 1 : 0];

    // =========================================================================
    // Result
    // =========================================================================
    wire [O_BW - 1 : 0] data = (real_i * real_i) + (imag_i * imag_i);
    wire valid = valid_i_q;
    wire last = last_i_q;

    // =========================================================================
    // Register output to reduce long path length
    // =========================================================================
    reg [O_BW - 1 : 0] data_q;
    reg valid_q;
    reg last_q;
    always @(posedge clk_i) begin
        if (!rst_n_i | !en_i) begin
            data_q <= 'd0;
            valid_q <= 'd0;
            last_q <= 'd0;
        end else begin
            if (valid) begin
                data_q <= data;
                valid_q <= valid;
                last_q <= last;
            end else begin
                data_q <= 'd0;
                valid_q <= 'd0;
                last_q <= 'd0;
            end
        end
    end

    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign data_o = data_q;
    assign valid_o = valid_q;
    assign last_o = last_q;

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    `ifndef SCANNED
    `define SCANNED
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, power_spectrum);
        #1;
    end
    `endif
    `endif

endmodule
