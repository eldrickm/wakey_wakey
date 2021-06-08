// =============================================================================
// Module:       CTL
// Design:       Matthew Pauly
// Verification: Eldrick Millares
// Notes:
//
// Top level module for pipeline control.
// =============================================================================

module ctl # (
    parameter F_SYSTEM_CLK = 1000  // 100 is used for unit test bench
) (
    // clock and reset
    input                                   clk_i,
    input                                   rst_n_i,

    // voice activity input 
    input                                   vad_i,

    // wake valid
    input                                   wake_valid_i,

    // enable output
    output                                  en_o
);
    // =========================================================================
    // Local Parameters
    // =========================================================================
    // 5ms empirically determined with microphone. See test/pdm_capture_test.
    localparam COUNT_CYCLES   = $rtoi(0.005 * F_SYSTEM_CLK);
    localparam COUNTER_BW     = $clog2(COUNT_CYCLES + 1);

    // =========================================================================
    // Falling Edge Detection for wake_valid_i
    // =========================================================================
    reg wake_valid_q;
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            wake_valid_q <= 'd0;
        end else begin
            wake_valid_q <= wake_valid_i;
        end
    end
    wire wake_valid_falling_edge = (wake_valid_q & !wake_valid_i);

    // =========================================================================
    // State Machine
    //
    // STATE_IDLE:              Waiting for voice activity on vad_i.
    // STATE_ON:                Wait for a falling edge on wake_valid_i
    //                            indicating that an inference just finished.
    // STATE_TIMEOUT:           Wait until 50ms has passed after turning off
    //                            pipeline and pdm clk before checking VAD
    //                            again.
    // =========================================================================
    localparam STATE_IDLE               = 2'd0,
               STATE_ON                 = 2'd1,
               STATE_TIMEOUT            = 2'd2;

    reg [1 : 0] state;
    reg [COUNTER_BW - 1 : 0] counter;

    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            state <= STATE_IDLE;
            counter <= 'd0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    state   <= (vad_i) ? STATE_ON : STATE_IDLE;
                    counter <= 'd0;
                end
                STATE_ON: begin
                    state   <= (wake_valid_falling_edge) ? STATE_TIMEOUT
                                                         : STATE_ON;
                    counter <= 'd0;
                end
                STATE_TIMEOUT: begin
                    state   <= (counter >= COUNT_CYCLES) ? STATE_IDLE
                                                         : STATE_TIMEOUT;
                    counter <= counter + 'd1;
                end
                default: begin
                    state   <= STATE_IDLE;
                    counter <= 'd0;
                end
            endcase
        end
    end

    // =========================================================================
    // Output Assignment
    // =========================================================================
    assign en_o = (state == STATE_ON) ? 'd1 : 'd0;

    // ========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // ========================================================================
    `ifdef COCOTB_SIM
    `ifndef SCANNED
    `define SCANNED
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, ctl);
        #1;
    end
    `endif
    `endif

endmodule
