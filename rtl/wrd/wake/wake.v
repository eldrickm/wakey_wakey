// ============================================================================
// Module:       Wake
// Design:       Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// TODO: Make multi-class?
// TODO: Make SUSTAIN_LEN configurable?
// ============================================================================

module wake #(
    parameter NUM_CLASSES = 3
) (
    // clock and reset
    input                       clk_i,
    input                       rst_n_i,

    // streaming input
    input [NUM_CLASSES - 1 : 0] data_i,
    input                       valid_i,
    input                       last_i,
    output                      ready_o,

    // wake output
    output                      wake_o
);

    // =========================================================================
    // Local Parameters
    // =========================================================================
    localparam SUSTAIN_LEN = 1024;
    localparam COUNTER_BW = $clog2(SUSTAIN_LEN);

    // =========================================================================
    // Control Logic
    // =========================================================================
    localparam STATE_IDLE = 1'd0,
               STATE_WAKE = 1'd1;

    reg [COUNTER_BW - 1 : 0] counter;
    reg state;

    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            counter <= 'd0;
            state   <= STATE_IDLE;
        end else begin
            case (state)
                STATE_IDLE: begin
                    counter <= 'd0;
                    state <= (data_i[0]) ? STATE_WAKE : STATE_IDLE;
                end
                STATE_WAKE: begin
                    counter <= counter + 'd1;
                    state <= (counter == SUSTAIN_LEN - 1) ? STATE_IDLE :
                                                            STATE_WAKE;
                end
                default: begin
                    counter <= 'd0;
                    state   <= STATE_IDLE;
                end
            endcase
        end
    end

    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign wake_o = (state == STATE_WAKE);

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, wake);
        #1;
    end
    `endif

endmodule
