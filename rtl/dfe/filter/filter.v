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
    localparam OUTPUT_BW = 8;
    localparam COMB_I_BW1 = 2;  // comb input bw must be 2 so two's complement
                               // can represent +1
    localparam COMB_O_BW1 = 2;  // -1, 0, or 1
    localparam INTEGRATOR_O_BW1 = 9;  // signed, 0 to 250

    localparam DC_CANCEL_O_BW = 8;  // -125 to 125

    localparam COMB_I_BW2 = 8;  // -125 to 125
    localparam COMB_O_BW2 = 9;  // -250 to 250
    localparam INTEGRATOR_O_BW2 = 17;  // signed, -62500 to 62500

    localparam QUANT_O_BW = 8;  // -128 to 128
    localparam QUANT_SHIFT = 5;

    localparam DECIMATOR_O_BW = 8;
    localparam DC_CANCEL_OFFSET = 'd125;

    // =========================================================================
    // Comb 1
    // =========================================================================
    wire signed [COMB_O_BW1 - 1 : 0] comb_data_o1;
    wire comb_valid_o1;
    comb #(
        .I_BW(COMB_I_BW1),
        .O_BW(COMB_O_BW1)
    ) comb_inst1 (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .data_i({1'b0, data_i}),
        .valid_i(valid_i),

        .data_o(comb_data_o1),
        .valid_o(comb_valid_o1)
    );
    
    // =========================================================================
    // Integrator 1
    // =========================================================================
    wire signed [INTEGRATOR_O_BW1 - 1 : 0] integrator_data_o1;
    wire integrator_valid_o1;
    integrator #(
        .I_BW(COMB_O_BW1),
        .O_BW(INTEGRATOR_O_BW1)
    ) integrator_inst1 (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .data_i(comb_data_o1),
        .valid_i(comb_valid_o1),

        .data_o(integrator_data_o1),
        .valid_o(integrator_valid_o1)
    );
    
    // =========================================================================
    // DC Cancel
    // =========================================================================
    wire signed [DC_CANCEL_O_BW - 1 : 0] dc_cancel_data_o;
    wire dc_cancel_valid_o;
    assign dc_cancel_data_o = integrator_data_o1 - DC_CANCEL_OFFSET;
    assign dc_cancel_valid_o = integrator_valid_o1;

    // =========================================================================
    // Comb 2
    // =========================================================================
    wire signed [COMB_O_BW2 - 1 : 0] comb_data_o2;
    wire comb_valid_o2;
    comb # (
        .I_BW(COMB_I_BW2),
        .O_BW(COMB_O_BW2)
    ) comb_inst2 (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .data_i(dc_cancel_data_o),
        .valid_i(dc_cancel_valid_o),

        .data_o(comb_data_o2),
        .valid_o(comb_valid_o2)
    );
    
    // =========================================================================
    // Integrator 2
    // =========================================================================
    wire signed [INTEGRATOR_O_BW2 - 1 : 0] integrator_data_o2;
    wire integrator_valid_o2;
    integrator # (
        .I_BW(COMB_O_BW2),
        .O_BW(INTEGRATOR_O_BW2)
    ) integrator_inst2 (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .data_i(comb_data_o2),
        .valid_i(comb_valid_o2),

        .data_o(integrator_data_o2),
        .valid_o(integrator_valid_o2)
    );

    // =========================================================================
    // Quantization
    // =========================================================================
    wire signed [QUANT_O_BW - 1 : 0] quant_data_o;
    wire quant_valid_o;
    wire signed [INTEGRATOR_O_BW2 - QUANT_SHIFT - 1] shifted;
    wire signed [INTEGRATOR_O_BW2 - QUANT_SHIFT - 1] clipped;
    assign shifted = integrator_data_o2 >>> QUANT_SHIFT;
    assign clipped = (shifted > 'sd127) ? 'sd127
                        : ((shifted < (-'sd128)) ? (-'sd128) : shifted);
    assign quant_data_o = clipped;
    assign quant_valid_o = integrator_valid_o2;

    // =========================================================================
    // Decimation
    // =========================================================================
    wire [DECIMATOR_O_BW - 1 : 0] decimator_data_o;
    wire decimator_valid_o;
    decimator decimator_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .en_i(en_i),

        .data_i(quant_data_o),
        .valid_i(quant_valid_o),

        .data_o(decimator_data_o),
        .valid_o(decimator_valid_o)
    );
    

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
    assign data_o  = decimator_data_o;
    // assign valid_o = (!first_value & decimator_valid_o);
    assign valid_o = decimator_valid_o;

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
