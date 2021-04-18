// ============================================================================
// Quantizer
// Design: Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// TODO: Can we synthesize a variable arithmetic right shift?
// TODO: Does this need to be signed? Guess is no since it is after ReLU
// ============================================================================

module quantizer #(
    parameter BW_I     = 32,
    parameter BW_O     = 8,
    parameter SHIFT_BW = $clog2(BW_I)
) (
    input                    clk_i,
    input                    rst_n_i,

    input [SHIFT_BW - 1 : 0] shift_i,

    input [BW_I - 1 : 0]     data_i,
    input                    valid_i,
    input                    last_i,
    output                   ready_o,

    output [BW_O - 1 : 0]    data_o,
    output                   valid_o,
    output                   last_o,
    input                    ready_i
);

    localparam [BW_O - 1 : 0] saturate_point = {1'b0, {BW_O - 1{1'b1}}};

    reg [BW_I - 1 : 0] shifted;

    always @(posedge clk_i) begin
        shifted <= (data_i >> shift_i);
    end

    wire [BW_O - 1 : 0] truncated;
    assign truncated = shifted[BW_O - 1 : 0];

    // register all outputs
    reg valid_q, last_q, ready_q;
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            valid_q <= 'b0;
            last_q  <= 'b0;
            ready_q <= 'b0;
        end else begin
            valid_q <= valid_i;
            last_q  <= last_i;
            ready_q <= ready_i;
        end
    end

    assign data_o  = (shifted > saturate_point) ? saturate_point :
                                                  shifted[BW_O - 1 : 0];
    assign valid_o = valid_q;
    assign last_o  = last_q;
    assign ready_o = ready_q;

    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, quantizer);
        #1;
    end
    `endif

endmodule
