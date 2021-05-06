// =============================================================================
// Module:       Sampler
// Design:       Matthew Pauly
// Verification: Eldrick Millares
// Notes:
//
// Samples data coming from the microphone on the positive edge of the PDM
// clock. If timing is not being met, the PDM data transition phase can be
// shifted by 180 degrees by switching the microphone's left/right
// configuration.
// =============================================================================

// module sampler #(
// ) (
module sampler (
    // clock and reset
    input                       clk_i,
    input                       rst_n_i,

    // input
    input                       en_i,
    input                       pdm_clk_i,
    input                       data_i,

    // streaming output
    output                      data_o,
    output                      valid_o
);

    // =========================================================================
    // Local Parameters
    // =========================================================================
    // localparam COUNTER_PERIOD = F_SYSTEM_CLK / 4000000;  // 4 cycles
    // localparam HALF_PERIOD    = COUNTER_PERIOD / 2;      // 2 cycles
    // localparam COUNTER_BW     = $clog2(COUNTER_PERIOD);  // 2 bits

    // =========================================================================
    // PDM Clock Positive Edge Detection
    // =========================================================================
    reg pdm_clk_q;  // counts 0 to 3
    always @(posedge clk_i) begin
        if (!rst_n_i | !en_i) begin
            pdm_clk_q <= 'd0;
        end else begin
            pdm_clk_q <= pdm_clk_i;
        end
    end
    wire pdm_posedge = (pdm_clk_i & !pdm_clk_q);

    // =========================================================================
    // Data Sampling
    // =========================================================================
    reg data_q, valid_q;
    always @(posedge clk_i) begin
        if (!rst_n_i | !en_i) begin
            data_q <= 'd0;
            valid_q <= 'd0;
        end else begin
            if (pdm_posedge) begin
                data_q <= data_i;
                valid_q <= 'd1;
            end else begin
                data_q <= 'd0;
                valid_q <= 'd0;
            end
        end
    end

    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign data_o  = data_q;
    assign valid_o = valid_q;

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, sampler);
        #1;
    end
    `endif

endmodule
