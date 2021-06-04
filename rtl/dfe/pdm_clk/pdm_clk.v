// =============================================================================
// Module:       PDM Clock
// Design:       Matthew Pauly
// Verification: Eldrick Millares
// Notes:
//
// Generates a 4MHz glock used to drive the microphone PDM interface.
// When en_i is low, the clock output is low which keeps the mic in low power
// mode.
// =============================================================================

module pdm_clk (
    // clock and reset
    input               clk_i,
    input               rst_n_i,

    // input
    input               en_i,

    // output
    output              pdm_clk_o
);

    // =========================================================================
    // Local Parameters
    // =========================================================================
    localparam F_SYSTEM_CLK   = 16000000;  // 16 MHz
    localparam COUNTER_PERIOD = F_SYSTEM_CLK / 4000000;  // 4 cycles
    localparam HALF_PERIOD    = COUNTER_PERIOD / 2;      // 2 cycles
    localparam COUNTER_BW     = $clog2(COUNTER_PERIOD);  // 2 bits

    // =========================================================================
    // Counter
    // =========================================================================
    reg [COUNTER_BW - 1 : 0] counter;  // counts 0 to 3
    always @(posedge clk_i) begin
        if (!rst_n_i | !en_i) begin
            counter <= 'd0;
        end else begin
            if (counter == COUNTER_PERIOD - 1) begin
                counter <= 'd0;
            end else begin
                counter <= counter + 'd1;
            end
        end
    end

    // =========================================================================
    // Output Assignment
    // =========================================================================
    // set pdm_clk_o to high when counter is 2 and 3:
    assign pdm_clk_o = (counter >= HALF_PERIOD);

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    `ifndef SCANNED
    `define SCANNED
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, pdm_clk);
        #1;
    end
    `endif
    `endif

endmodule
