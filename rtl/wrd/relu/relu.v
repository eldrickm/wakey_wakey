// =============================================================================
// Module:       ReLU (Rectified Linear Unit)
// Design:       Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// =============================================================================

module relu #(
    parameter BW = 32
) (
    input                      clk_i,
    input                      rst_n_i,

    input  signed [BW - 1 : 0] data_i,
    input                      valid_i,
    input                      last_i,
    output                     ready_o,

    output signed [BW - 1 : 0] data_o,
    output                     valid_o,
    output                     last_o,
    input                      ready_i
);

    // =========================================================================
    // Rectification
    // =========================================================================
    reg [BW - 1 : 0] rectified;
    always @(posedge clk_i) begin
        rectified <= (data_i > 0) ? data_i : 0;
    end

    // =========================================================================
    // Output Assignment
    // =========================================================================
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

    assign data_o  = rectified;
    assign valid_o = valid_q;
    assign last_o  = last_q;
    assign ready_o = ready_q;

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    `ifndef SCANNED
    `define SCANNED
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, relu);
        #1;
    end
    `endif
    `endif

endmodule
