// =============================================================================
// Module:       ACO
// Design:       Matthew Pauly
// Verification: Eldrick Millares
// Notes:
//
// Top level module for the acoustic featurisation pipeline.
// =============================================================================

module aco (
    // clock and reset
    input                                   clk_i,
    input                                   rst_n_i,
    input                                   en_i,

    input  [QUANT_SHIFT_BW - 1 : 0]         shift_i,
    input                                   wr_en,

    // streaming input
    input signed  [I_BW - 1 : 0]            data_i,
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
    localparam PREEMPH_I_BW             = 8;
    localparam I_BW                     = PREEMPH_I_BW;
    localparam PREEMPH_O_BW             = 9;

    localparam FFT_FRAMING_I_BW         = 9;
    localparam FFT_FRAMING_O_BW         = 16;
    localparam FFT_FRAME_LEN            = 256;
    localparam FFT_FRAMING_CADENCE      = 1;

    localparam FFT_I_BW                 = 16;
    localparam FFT_O_BW                 = 21 * 2;

    localparam POWER_SPECTRUM_I_BW      = 21 * 2;
    localparam POWER_SPECTRUM_O_BW      = 32;

    localparam FILTERBANK_I_BW          = 32;
    localparam FILTERBANK_O_BW          = 32;

    localparam LOG_I_BW                 = 32;
    localparam LOG_O_BW                 = 8;

    localparam DCT_FRAMING_I_BW         = 8;
    localparam DCT_FRAMING_O_BW         = 8;
    localparam DCT_FRAME_LEN            = 32;
    localparam DCT_FRAMING_CADENCE      = 13;  // hold each value for 13 cycles

    localparam DCT_I_BW                 = 8;
    localparam DCT_COEFS                = 13;
    localparam DCT_O_BW                 = 16;

    localparam QUANT_I_BW               = 16;
    localparam QUANT_SHIFT_BW           = 8;
    localparam QUANT_O_BW               = 8;

    localparam PACKING_I_BW             = 8;
    localparam PACKING_O_BW             = PACKING_I_BW * DCT_COEFS;

    localparam WRD_FRAMING_I_BW         = PACKING_O_BW;
    localparam WRD_FRAMING_O_BW         = PACKING_O_BW;
    localparam WRD_FRAME_LEN            = 50;
    localparam WRD_FRAMING_CADENCE      = 1;

    // =========================================================================
    // Preemphasis
    // =========================================================================
    wire signed [PREEMPH_O_BW - 1 : 0]  preemph_data_o;
    wire                                preemph_valid_o;
    preemphasis preemphasis_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .data_i(data_i),
        .valid_i(valid_i),

        .data_o(preemph_data_o),
        .valid_o(preemph_valid_o)
    );

    // =========================================================================
    // Framing for FFT
    // =========================================================================
    wire signed [FFT_FRAMING_O_BW - 1 : 0]      fft_framing_data_o;
    wire                                        fft_framing_valid_o;
    wire                                        fft_framing_last_o;
    framing #(
        .I_BW(FFT_FRAMING_I_BW),
        .O_BW(FFT_FRAMING_O_BW),
        .FRAME_LEN(FFT_FRAME_LEN),
        .CADENCE_CYC(FFT_FRAMING_CADENCE)
    ) fft_framing_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .data_i(preemph_data_o),
        .valid_i(preemph_valid_o),

        .data_o(fft_framing_data_o),
        .valid_o(fft_framing_valid_o),
        .last_o(fft_framing_last_o)
    );

    // =========================================================================
    // FFT
    // =========================================================================
    wire signed [FFT_O_BW - 1 : 0]      fft_data_o;
    wire                                fft_valid_o;
    wire                                fft_last_o;
    fft_wrapper fft_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .data_i(fft_framing_data_o),
        .valid_i(fft_framing_valid_o),
        .last_i(fft_framing_last_o),

        .data_o(fft_data_o),
        .valid_o(fft_valid_o),
        .last_o(fft_last_o)
    );

    // =========================================================================
    // Power Spectrum
    // =========================================================================
    wire [POWER_SPECTRUM_O_BW - 1 : 0]  power_spectrum_data_o;
    wire                                power_spectrum_valid_o;
    wire                                power_spectrum_last_o;
    power_spectrum power_spectrum_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .data_i(fft_data_o),
        .valid_i(fft_valid_o),
        .last_i(fft_last_o),

        .data_o(power_spectrum_data_o),
        .valid_o(power_spectrum_valid_o),
        .last_o(power_spectrum_last_o)
    );

    // =========================================================================
    // MFCC Filterbank
    // =========================================================================
    wire [FILTERBANK_O_BW - 1 : 0]      filterbank_data_o;
    wire                                filterbank_valid_o;
    wire                                filterbank_last_o;
    filterbank filterbank_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .data_i(power_spectrum_data_o),
        .valid_i(power_spectrum_valid_o),
        .last_i(power_spectrum_last_o),

        .data_o(filterbank_data_o),
        .valid_o(filterbank_valid_o),
        .last_o(filterbank_last_o)
    );

    // =========================================================================
    // Log
    // =========================================================================
    wire [LOG_O_BW - 1 : 0]             log_data_o;
    wire                                log_valid_o;
    wire                                log_last_o;
    log log_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .data_i(filterbank_data_o),
        .valid_i(filterbank_valid_o),
        .last_i(filterbank_last_o),

        .data_o(log_data_o),
        .valid_o(log_valid_o),
        .last_o(log_last_o)
    );

    // =========================================================================
    // Framing for DCT
    // =========================================================================
    wire [DCT_FRAMING_O_BW - 1 : 0]     dct_framing_data_o;
    wire                                dct_framing_valid_o;
    wire                                dct_framing_last_o;
    framing #(
        .I_BW(DCT_FRAMING_I_BW),
        .O_BW(DCT_FRAMING_O_BW),
        .FRAME_LEN(DCT_FRAME_LEN),
        .CADENCE_CYC(DCT_FRAMING_CADENCE)
    ) dct_framing_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .data_i(log_data_o),
        .valid_i(log_valid_o),

        .data_o(dct_framing_data_o),
        .valid_o(dct_framing_valid_o),
        .last_o(dct_framing_last_o)
    );

    // =========================================================================
    // DCT
    // =========================================================================
    wire signed [DCT_O_BW - 1 : 0]      dct_data_o;
    wire                                dct_valid_o;
    wire                                dct_last_o;
    dct dct_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .data_i(dct_framing_data_o),
        .valid_i(dct_framing_valid_o),
        .last_i(dct_framing_last_o),

        .data_o(dct_data_o),
        .valid_o(dct_valid_o),
        .last_o(dct_last_o)
    );

    // =========================================================================
    // Quantization
    // =========================================================================
    wire signed [QUANT_O_BW - 1 : 0]    quant_data_o;
    wire                                quant_valid_o;
    wire                                quant_last_o;
    quant quant_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .shift_i(shift_i),
        .wr_en(wr_en),

        .data_i(dct_data_o),
        .valid_i(dct_valid_o),
        .last_i(dct_last_o),

        .data_o(quant_data_o),
        .valid_o(quant_valid_o),
        .last_o(quant_last_o)
    );

    // =========================================================================
    // Packing
    // =========================================================================
    wire signed [PACKING_O_BW - 1 : 0]  packing_data_o;
    wire                                packing_valid_o;
    wire                                packing_last_o;
    packing packing_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .data_i(quant_data_o),
        .valid_i(quant_valid_o),
        .last_i(quant_last_o),

        .data_o(packing_data_o),
        .valid_o(packing_valid_o),
        .last_o(packing_last_o)
    );

    // =========================================================================
    // Framing for WRD
    // =========================================================================
    wire [WRD_FRAMING_O_BW - 1 : 0]     wrd_framing_data_o;
    wire                                wrd_framing_valid_o;
    wire                                wrd_framing_last_o;
    framing #(
        .I_BW(WRD_FRAMING_I_BW),
        .O_BW(WRD_FRAMING_O_BW),
        .FRAME_LEN(WRD_FRAME_LEN),
        .CADENCE_CYC(WRD_FRAMING_CADENCE)
    ) wrd_framing_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .data_i(packing_data_o),
        .valid_i(packing_valid_o),

        .data_o(wrd_framing_data_o),
        .valid_o(wrd_framing_valid_o),
        .last_o(wrd_framing_last_o)
    );

    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign valid_o = (en_i & wrd_framing_valid_o);
    assign data_o = wrd_framing_data_o;
    assign last_o = wrd_framing_last_o;

    // ========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // ========================================================================
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, aco);
        #1;
    end
    `endif

endmodule
