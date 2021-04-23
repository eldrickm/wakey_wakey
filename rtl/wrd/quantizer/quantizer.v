// ============================================================================
// Quantizer
// Design: Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// TODO: Can we synthesize a variable arithmetic right shift?
// TODO: Does this need to be signed? Guess is no since it is after ReLU
// ============================================================================

module quantizer #(
    parameter I_BW     = 32,
    parameter O_BW     = 8,
    parameter SHIFT_BW = $clog2(I_BW)
) (
    input                    clk_i,
    input                    rst_n_i,

    input [SHIFT_BW - 1 : 0] shift_i,

    input [I_BW - 1 : 0]     data_i,
    input                    valid_i,
    input                    last_i,
    output                   ready_o,

    output [O_BW - 1 : 0]    data_o,
    output                   valid_o,
    output                   last_o,
    input                    ready_i
);

    localparam [O_BW - 1 : 0] saturate_point = {1'b0, {O_BW - 1{1'b1}}};

    reg [I_BW - 1 : 0] shifted;

    always @(posedge clk_i) begin
        shifted <= (data_i >> shift_i);
    end

    wire [O_BW - 1 : 0] truncated;
    assign truncated = shifted[O_BW - 1 : 0];

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
                                                  shifted[O_BW - 1 : 0];
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
