// =============================================================================
// Module:       Debug
// Design:       Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// =============================================================================

module dbg #(
    parameter DFE_OUTPUT_BW = 8,
    parameter ACO_OUTPUT_BW = 8 * 13
)(
    // clock and reset
    input                                   clk_i,
    input                                   rst_n_i,

    // logic analyzer signals
    input  [127:0] la_data_in_i,
    output [127:0] la_data_out_o,
    input  [127:0] la_oenb_i,

    // ctl
    input  ctl_pipeline_en_i,

    output ctl_pipeline_en_o,

    // mic -> dfe
    input   mic_pdm_data_i,

    output  mic_pdm_data_o,

    // dfe -> aco
    input [DFE_OUTPUT_BW - 1 : 0] dfe_data_i,
    input dfe_valid_i,

    output [DFE_OUTPUT_BW - 1 : 0] dfe_data_o,
    output dfe_valid_o,

    // aco -> wrd
    input [ACO_OUTPUT_BW - 1 : 0] aco_data_i,
    input aco_valid_i,
    input aco_last_i,

    output [ACO_OUTPUT_BW - 1 : 0] aco_data_o,
    output aco_valid_o,
    output aco_last_o,

    // wrd -> wake
    input wrd_wake_i,
    input wrd_wake_valid_i,

    output wrd_wake_o,
    output wrd_wake_valid_o
);
    // =========================================================================
    // Pack input signals into one 128-bit vector
    // =========================================================================

    wire [127:0] packed_input = {9'd0,
                                 wrd_wake_valid_i,
                                 wrd_wake_i,
                                 aco_last_i,
                                 aco_valid_i,
                                 aco_data_i,
                                 dfe_valid_i,
                                 dfe_data_i,
                                 mic_pdm_data_i,
                                 ctl_pipeline_en_i};
    assign la_data_out_o = packed_input;
    wire [127:0] packed_output;

    // =========================================================================
    // Mux each bit between the logic analyzer input and the original signal
    // =========================================================================

    genvar i;
    generate
        for (i = 0; i < 128; i = i + 1) begin
            assign packed_output[i] = (!la_oenb_i[i]) ? la_data_in_i[i] : packed_input[i];
        end
    endgenerate

    // =========================================================================
    // Unpack muxed data
    // =========================================================================

    // CTL -> *** - 1 Pin(s)
    assign ctl_pipeline_en_o = packed_output[0];

    // MIC -> DFE - 1 Pin(s)
    assign mic_pdm_data_o = packed_output[1];

    // DFE -> ACO - 9 Pin(s)
    assign dfe_data_o  = packed_output[9:2];
    assign dfe_valid_o = packed_output[10];

    // ACO -> WRD - 106 Pin(s)
    assign aco_data_o  = packed_output[114:11];
    assign aco_valid_o = packed_output[115];
    assign aco_last_o  = packed_output[116];

    // WRD -> WAKE - 2 Pin(s)
    assign wrd_wake_o       = packed_output[117];
    assign wrd_wake_valid_o = packed_output[118];

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    `ifndef SCANNED
    `define SCANNED
    initial begin
      $dumpfile ("wave.vcd");
      $dumpvars (0, dbg);
      #1;
    end
    `endif
    `endif

endmodule
