// =============================================================================
// Module:       Debug
// Design:       Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// TODO: Clock this module? Add registers?
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
    // Logic Analyzer Read Assignments
    // =========================================================================

    // CTL -> *** - 1 Pin(s)
    assign la_data_out_o[0] = ctl_pipeline_en_i;

    // MIC -> DFE - 1 Pin(s)
    assign la_data_out_o[1] = mic_pdm_data_i;

    // DFE -> ACO - 9 Pin(s)
    assign la_data_out_o[9:2] = dfe_data_i;
    assign la_data_out_o[10]  = dfe_valid_i;

    // ACO -> WRD - 106 Pin(s)
    assign la_data_out_o[114:11] = aco_data_i;
    assign la_data_out_o[115]    = aco_valid_i;
    assign la_data_out_o[116]    = aco_last_i;

    // WRD -> WAKE - 2 Pin(s)
    assign la_data_out_o[117] = wrd_wake_i;
    assign la_data_out_o[118] = wrd_wake_valid_i;


    // =========================================================================
    // Logic Analyzer Write Assignments
    // =========================================================================

    // CTL -> *** - 1 Pin(s)
    assign ctl_pipeline_en_o = (la_oenb_i[0]) ? la_data_in_i[0] :
                                                ctl_pipeline_en_i;

    // MIC -> DFE - 1 Pin(s)
    assign mic_pdm_data_o = (la_oenb_i[1]) ? la_data_in_i[1] : mic_pdm_data_i;

    // DFE -> ACO - 9 Pin(s)
    assign dfe_data_o  = (la_oenb_i[2]) ? la_data_in_i[9:2] : dfe_data_i;
    assign dfe_valid_o = (la_oenb_i[2]) ? la_data_in_i[10] : dfe_valid_i;

    // ACO -> WRD - 106 Pin(s)
    assign aco_data_o  = (la_oenb_i[3]) ? la_data_in_i[114:11] : aco_data_i;
    assign aco_valid_o = (la_oenb_i[3]) ? la_data_in_i[115] : aco_valid_i;
    assign aco_last_o  = (la_oenb_i[3]) ? la_data_in_i[116] : aco_last_i;

    // WRD -> WAKE - 2 Pin(s)
    assign wrd_wake_o       = (la_oenb_i[4]) ? la_data_in_i[117] : wrd_wake_i;
    assign wrd_wake_valid_o = (la_oenb_i[4]) ? la_data_in_i[118] :
                                               wrd_wake_valid_i;


    // =========================================================================
    // Tie Off Unused la_data_out signals
    // =========================================================================
    assign la_data_out_o[127:119] = 'b0;


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
