// =============================================================================
// Module:       Filter
// Design:       Matthew Pauly
// Verification: Eldrick Millares
// Notes:
//
// Single stage integrator-comb filter with decimation and DC cancel. Converts
// a 4MHz PDM input signal into a 8b 16kHz signal.
// =============================================================================

module filter (
    // clock and reset
    input                               clk_i,
    input                               rst_n_i,

    // input
    input                               en_i,
    input                               data_i,
    input                               valid_i,

    // streaming output
    output signed [OUTPUT_BW - 1 : 0]   data_o,
    output                              valid_o
);

    // =========================================================================
    // Local Parameters
    // =========================================================================
    // These are not parameterized in the downstream modules; they are only
    // here for readability
    localparam OUTPUT_BW = 8;
    localparam COMB_O_BW = 2;
    localparam INTEGRATOR_O_BW = 8;
    localparam DECIMATOR_O_BW = 8;
    localparam DC_CANCEL_O_BW = 8;
    localparam DC_CANCEL_OFFSET = 'd125;

    // =========================================================================
    // Comb
    // =========================================================================
    wire signed [COMB_O_BW - 1 : 0] comb_data_o;
    wire comb_valid_o;
    comb comb_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .data_i(data_i),
        .valid_i(valid_i),

        .data_o(comb_data_o),
        .valid_o(comb_valid_o)
    );
    
    // =========================================================================
    // Integrator
    // =========================================================================
    wire [INTEGRATOR_O_BW - 1 : 0] integrator_data_o;
    wire integrator_valid_o;
    integrator integrator_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .data_i(comb_data_o),
        .valid_i(comb_valid_o),

        .data_o(integrator_data_o),
        .valid_o(integrator_valid_o)
    );

    // =========================================================================
    // Decimation
    // =========================================================================
    wire [DECIMATOR_O_BW - 1 : 0] decimator_data_o;
    wire decimator_valid_o;
    decimator decimator_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .data_i(integrator_data_o),
        .valid_i(integrator_valid_o),

        .data_o(decimator_data_o),
        .valid_o(decimator_valid_o)
    );
    
    // =========================================================================
    // DC Cancel
    // =========================================================================
    wire signed [DC_CANCEL_O_BW - 1 : 0] dc_cancel_data_o;
    wire dc_cancel_valid_o;
    assign dc_cancel_data_o = decimator_data_o - DC_CANCEL_OFFSET;
    assign dc_cancel_valid_o = decimator_valid_o;

    // =========================================================================
    // Ignore First Value
    // =========================================================================
    // First output value is garbage, so ignore it.
    reg first_value;
    always @(posedge clk_i) begin
        if (!rst_n_i | !en_i) begin
            first_value <= 'd1;
        end else begin
            if (dc_cancel_valid_o) begin
                first_value <= 'd0;
            end else begin
                first_value <= first_value;
            end
        end
    end

    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign data_o  = dc_cancel_data_o;
    assign valid_o = (!first_value & dc_cancel_valid_o);

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, filter);
        #1;
    end
    `endif

endmodule
