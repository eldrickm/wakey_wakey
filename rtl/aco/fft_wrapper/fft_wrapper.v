// =============================================================================
// Module:       FFT IP Core Wrapper
// Design:       Matthew Pauly
// Verification: Eldrick Millares
// Notes:        Wraps the 256 sample FFT core as a 129 sample real FFT in a
//               streaming interface. De-assertions of valid_i are not
//               permitted. Operates in a low duty-cycle manner. Only one frame
//               can be processed at a time. This is OK since we need it to
//               operate at 50 Hz minimum, and one full use of the core with
//               reset takes under 1000 clock cycles.
//
//
// On first valid unset the reset, enable the fft clock, and start streaming data
// On sync, count the number of data points up until 128, then emit last and
//      reset the fft core, keeping it reset until the next valid frame
// =============================================================================

module fft_wrapper (
    // clock and reset
    input                                   clk_i,
    input                                   rst_n_i,
    input                                   en_i,

    // streaming input
    input  signed [I_BW - 1 : 0]            data_i,
    input                                   valid_i,
    input                                   last_i,

    // streaming output
    output  signed [O_BW - 1 : 0]           data_o,  // real in higher bits
    output                                  valid_o,
    output                                  last_o
);
    // =========================================================================
    // Local Parameters
    // =========================================================================
    localparam I_BW         = 16;  // real input
    localparam O_BW         = 21 * 2;  // complex output

    // output sample counter for holding valid_o
    localparam FFT_LEN                  = 256;
    localparam RFFT_LEN                 = $rtoi(FFT_LEN / 2 + 1);
    localparam OUTPUT_COUNTER_BW        = $clog2(RFFT_LEN);

    // =========================================================================
    // FFT Enable Logic
    // =========================================================================
    // Latch valid starting with the first valid input and resetting after
    // the last valid output. This is used to enable the FFT core.
    reg valid_i_latch;
    always @(posedge clk_i) begin
        if (!rst_n_i | !en_i) begin
            valid_i_latch <= 'd0;
        end else begin
            if (last_o) begin  // reset after final valid output sample
                valid_i_latch <= 'd0;
            end else if (valid_i) begin  // set to high after first valid input
                valid_i_latch <= 'd1;
            end else begin
                valid_i_latch <= valid_i_latch;
            end
        end
    end
    wire fft_en = (en_i & (valid_i | valid_i_latch));

    // =========================================================================
    // FFT Core
    // =========================================================================
    wire sync;
    wire [2 * I_BW - 1 : 0] fft_data_in = {data_i, {I_BW{1'b0}}};
    fftmain fft_inst (
        .i_clk(clk_i),
        .i_reset(!fft_en),
        .i_ce(fft_en),

        .i_sample(fft_data_in),
        .o_result(data_o),
        .o_sync(sync)
    );

    // =========================================================================
    // Valid Output Logic
    // =========================================================================
    wire valid_o_start = sync;
    reg [OUTPUT_COUNTER_BW - 1: 0] output_counter;
    always @(posedge clk_i) begin
        if (!rst_n_i | !en_i) begin
            output_counter <= 'd0;
        end else begin
            if (last_o) begin
                // reset counter after a valid frame output has finished
                output_counter <= 'd0;
            end else if (valid_o) begin
                // already counting or should begin counting
                output_counter <= output_counter + 'd1;
            end else begin
                output_counter <= output_counter;
            end
        end
    end

    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign valid_o = (valid_o_start | (output_counter > 'd0));
    assign last_o  = (output_counter == RFFT_LEN - 1);

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    `ifndef SCANNED
    `define SCANNED
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, fft_wrapper);
        #1;
    end
    `endif
    `endif

endmodule
