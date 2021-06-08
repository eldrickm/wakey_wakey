// ============================================================================
// Max Pool
// Design: Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// ============================================================================

module max_pool #(
    parameter BW = 8
) (
    // clock and reset
    input                      clk_i,
    input                      rst_n_i,

    // streaming input
    input  signed [BW - 1 : 0] data_i,
    input                      valid_i,
    input                      last_i,
    output                     ready_o,

    // streaming output
    output signed [BW - 1 : 0] data_o,
    output                     valid_o,
    output                     last_o,
    input                      ready_i
);

    // =========================================================================
    // Output Register Declaratons
    // =========================================================================
    reg signed [BW - 1 : 0] data_q, data_q2, max;
    reg valid_q, valid_q2, valid_q3, last_q, last_q2, ready_q;

    // =========================================================================
    // State Machine
    // =========================================================================
    localparam STATE_IDLE   = 2'd0,
               STATE_LOAD_1 = 2'd1,
               STATE_LOAD_2 = 2'd2,
               STATE_VALID  = 2'd3;
    reg [1:0] state;

    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            state <= STATE_IDLE;
        end else begin
            case(state)
                STATE_IDLE: begin
                    state <= (valid_i) ? STATE_LOAD_1 : STATE_IDLE;
                end
                STATE_LOAD_1: begin
                    state <= (valid_i) ? STATE_LOAD_2 : STATE_IDLE;
                end
                STATE_LOAD_2: begin
                    state <= STATE_VALID;
                end
                STATE_VALID: begin
                    state <= (valid_q) ?
                             ((last_q) ? STATE_VALID : STATE_LOAD_2) :
                             STATE_IDLE;
                end
                default: begin
                end
            endcase
        end
    end

    // register all outputs
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            valid_q  <= 'b0;
            valid_q2 <= 'b0;
            valid_q3 <= 'b0;
            last_q   <= 'b0;
            last_q2  <= 'b0;
            ready_q  <= 'b0;
            data_q   <= 'b0;
            data_q2  <= 'b0;
            max      <= 'b0;
        end else begin
            valid_q  <= valid_i;
            valid_q2 <= valid_q;
            valid_q3 <= valid_q2;
            last_q   <= last_i;
            last_q2  <= last_q;
            ready_q  <= ready_i;
            data_q   <= data_i;
            data_q2  <= data_q;
            max      <= (state == STATE_VALID) ? 
                          data_q  // if 2 new data are not ready yet just
                                  // output the first one
                          : ((data_q > data_q2) ? data_q : data_q2);
        end
    end


    assign data_o  = max;
    assign valid_o = (state == STATE_VALID);
    assign last_o  = last_q2;
    assign ready_o = ready_q;

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    `ifndef SCANNED
    `define SCANNED
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, max_pool);
        #1;
    end
    `endif
    `endif

endmodule
