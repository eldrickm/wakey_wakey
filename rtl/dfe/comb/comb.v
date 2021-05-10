// =============================================================================
// Module:       Comb
// Design:       Matthew Pauly
// Verification: Eldrick Millares
// Notes:
//
// Comb element of the integrator-comb filter. Produces the input delayed by
// WINDOW_LEN subtracted from the input.
// =============================================================================

module comb (
    // clock and reset
    input               clk_i,
    input               rst_n_i,

    // streaming input
    input               en_i,
    input               data_i,
    input               valid_i,

    // streaming output
    output signed [1:0] data_o,
    output              valid_o
);

    // =========================================================================
    // Local Parameters
    // =========================================================================
    localparam WINDOW_LEN = 250;

    // =========================================================================
    // Delay Block
    // =========================================================================
    reg [WINDOW_LEN - 1 : 0] reg_fifo;
    // First register
    always @(posedge clk_i) begin
        if (!rst_n_i | !en_i) begin
            reg_fifo[0] <= 'd0;
        end else begin
            if (valid_i) begin
                reg_fifo[0] <= data_i;
            end else begin
                reg_fifo[0] <= reg_fifo[0];
            end
        end
    end
    // Subsequent registers
    genvar i;
    generate
        for (i = 1; i < WINDOW_LEN; i = i + 1) begin
            always @(posedge clk_i) begin
                if (!rst_n_i | !en_i) begin
                    reg_fifo[i] <= 'd0;
                end else begin
                    if (valid_i) begin
                        reg_fifo[i] <= reg_fifo[i-1];
                    end else begin
                        reg_fifo[i] <= reg_fifo[i];
                    end
                end
            end
        end
    endgenerate
    
    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign valid_o = (en_i & valid_i);
    assign data_o  = data_i - reg_fifo[WINDOW_LEN - 1];

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, comb);
        #1;
    end
    `endif

endmodule
