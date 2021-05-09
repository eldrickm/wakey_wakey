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
    // Fifo
    // =========================================================================
    wire fifo_dout;
    wire fifo_full_n;
    wire fifo_deq = (valid_i & !fifo_full_n);  // only dequeue when fifo is full
    fifo #(
        .DATA_WIDTH('d1),
        .FIFO_DEPTH(WINDOW_LEN - 'd1)
    ) comb_fifo_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i & en_i),  // reset fifo on low rst_n_i or low en_i

        .enq_i(valid_i),
        .deq_i(fifo_deq),

        .din_i(data_i),
        .dout_o(fifo_dout),

        .full_o_n(fifo_full_n),
        .empty_o_n()
    );
    
    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign data_o  = (!fifo_full_n) ? data_i - fifo_dout
                                    : data_i;
    assign valid_o = (en_i & valid_i);

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
