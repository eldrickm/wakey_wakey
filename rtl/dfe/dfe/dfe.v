// =============================================================================
// Module:       DFE
// Design:       Matthew Pauly
// Verification: Eldrick Millares
// Notes:
//
// Top level module of the digital front end. Contains PDM clock generation,
// PDM sampling, and PDM filtering. Produces a 8b 16kHz audio stream which is
// sent to ACO.
// =============================================================================

module dfe #(
    // =========================================================================
    // Local Parameters - Do Not Edit
    // =========================================================================
    // These are not parameterized in the downstream modules; they are only
    // here for readability
    parameter OUTPUT_BW = 8

) (
    // clock, reset, and enable
    input                               clk_i,
    input                               rst_n_i,
    input                               en_i,

    // pdm input
    input                               pdm_data_i,

    // pdm clock output
    output                              pdm_clk_o,

    // streaming output
    output signed [OUTPUT_BW - 1 : 0]   data_o,
    output                              valid_o
);

    // =========================================================================
    // PDM Clock Generator
    // =========================================================================
    pdm_clk comb_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .pdm_clk_o(pdm_clk_o)
    );

    // =========================================================================
    // Sampler
    // =========================================================================
    wire sampler_data_o;
    wire sampler_valid_o;
    sampler sampler_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .pdm_clk_i(pdm_clk_o),
        .data_i(pdm_data_i),

        .data_o(sampler_data_o),
        .valid_o(sampler_valid_o)
    );

    // =========================================================================
    // Filter
    // =========================================================================
    wire [OUTPUT_BW - 1 : 0] filter_data_o;
    wire filter_valid_o;
    filter filter_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .data_i(sampler_data_o),
        .valid_i(sampler_valid_o),

        .data_o(filter_data_o),
        .valid_o(filter_valid_o)
    );

    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign data_o  = filter_data_o;
    assign valid_o = filter_valid_o;

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    `ifndef SCANNED
    `define SCANNED
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, dfe);
        #1;
    end
    `endif
    `endif

endmodule
