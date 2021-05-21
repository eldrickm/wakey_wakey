// =============================================================================
// Module:       DCT
// Design:       Matthew Pauly
// Verification: Eldrick Millares
// Notes:
//
// Computes a 32-element DCT and outputs the first 13 coefficients. Input data
// is expected to stay the same for 13 cycles, permitting the accumulation
// of each output coefficient simultaneously.
// =============================================================================

module dct (
    // clock and reset
    input                                   clk_i,
    input                                   rst_n_i,
    input                                   en_i,

    // streaming input
    input         [I_BW - 1 : 0]            data_i,
    input                                   valid_i,
    input                                   last_i,

    // streaming output
    output signed [O_BW - 1 : 0]            data_o,
    output                                  valid_o,
    output                                  last_o
);
    // =========================================================================
    // Local Parameters
    // =========================================================================
    localparam I_BW          = 8;
    localparam O_BW          = 16;
    localparam INTERNAL_BW   = 32;
    localparam COEF_BW       = 16;
    localparam FRAME_LEN     = 32;  // length of the DCT
    localparam ELEM_COUNT_BW = $clog2(FRAME_LEN);
    localparam N_COEF        = 13;
    localparam COEF_COUNT_BW = $clog2(N_COEF);
    localparam ADDR_BW       = $clog2(N_COEF * FRAME_LEN);
    localparam SHIFT         = 15;

    localparam COEFFILE     = "dct.hex";

    // =========================================================================
    // Element Counter
    // =========================================================================
    reg [ELEM_COUNT_BW - 1 : 0] elem_counter;
    always @(posedge clk_i) begin
        if (!rst_n_i | !en_i) begin
            elem_counter <= 'd0;
        end else begin
            if (valid_i & next_elem) begin
                elem_counter <= elem_counter + 'd1;
            end else if (valid_i) begin
                elem_counter <= elem_counter;
            end else begin
                elem_counter <= 'd0;
            end
        end
    end
    wire last_elem = (elem_counter == FRAME_LEN - 1);

    // =========================================================================
    // Coefficient Counter (aka Cadence)
    // =========================================================================
    reg [COEF_COUNT_BW - 1 : 0] coef_counter;
    always @(posedge clk_i) begin
        if (!rst_n_i | !en_i) begin
            coef_counter <= 'd0;
        end else begin
            if (next_elem) begin
                coef_counter <= 'd0;
            end else if (valid_i) begin
                coef_counter <= coef_counter + 'd1;
            end else begin
                coef_counter <= 'd0;
            end
        end
    end
    wire next_elem = (coef_counter == N_COEF - 'd1);

    // =========================================================================
    // Multiplication
    // =========================================================================
    wire [ADDR_BW - 1 : 0] addr = N_COEF * elem_counter + coef_counter;
    wire signed [INTERNAL_BW - 1 : 0] mult;
    wire signed [I_BW : 0] data_i_signed = data_i;
    assign mult = data_i_signed * coefs[addr];

    // =========================================================================
    // Accumulated coefficients
    // =========================================================================
    reg signed [INTERNAL_BW - 1 : 0] acc_arr [N_COEF - 1 : 0];
    genvar i;
    for (i = 0; i < N_COEF; i = i + 1) begin: accumulation_regs
        always @(posedge clk_i) begin
            if (!rst_n_i | !en_i) begin
                acc_arr[i] <= 'd0;
            end else if (valid_i & (coef_counter == i)) begin
                acc_arr[i] <= acc_arr[i] + mult;
            end else if (valid_i) begin
                acc_arr[i] <= acc_arr[i];
            end else begin
                acc_arr[i] <= 'd0;
            end
        end
    end

    // =========================================================================
    // Output Assignment
    // =========================================================================
    wire signed [INTERNAL_BW - 1 : 0] pre_shift = acc_arr[coef_counter] + mult;
    assign valid_o = (en_i & last_elem);
    assign data_o = pre_shift >> SHIFT;
    assign last_o = last_i;

    // =========================================================================
    // ROM Memory for DCT coefficients
    // =========================================================================
    reg signed [COEF_BW - 1 : 0] coefs [0 : N_COEF * FRAME_LEN - 1];

    initial begin
        $display("reading from: %s", COEFFILE);
        $readmemh(COEFFILE, coefs);

        // =====================================================================
        // Simulation Only Waveform Dump (.vcd export)
        // =====================================================================
        `ifdef COCOTB_SIM
        `ifndef SCANNED
        `define SCANNED
        $dumpfile ("wave.vcd");
        $dumpvars (0, dct);
        $dumpvars (0, acc_arr[0]);
        $dumpvars (0, acc_arr[1]);
        #1;
        `endif
        `endif
    end

endmodule
