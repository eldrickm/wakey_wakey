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
    reg signed [BW - 1 : 0] data_q, data_q2, max;

    reg valid_q, valid_q2, valid_q3, last_q, last_q2, last_q3, ready_q;
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            valid_q  <= 'b0;
            valid_q2 <= 'b0;
            valid_q3 <= 'b0;
            last_q   <= 'b0;
            last_q2  <= 'b0;
            last_q3  <= 'b0;
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
            last_q3  <= last_q2;
            ready_q  <= ready_i;
            data_q   <= data_i;
            data_q2  <= data_q;
            max      <= (data_q > data_q2) ? data_q : data_q2;
        end
    end

    // positive edge detector to emit initial 0
    wire valid_i_pos_edge  = valid_i  & (!valid_q);

    // negative edge detectors to extend valid_o, emit last 0
    wire valid_q_neg_edge  = valid_q2 & (!valid_q);
    wire valid_q2_neg_edge = valid_q3 & (!valid_q2);

    assign data_o  = max;
    // assign valid_o = valid_q | valid_q_neg_edge | valid_q2_neg_edge;
    assign valid_o = (state == STATE_VALID);
    assign last_o  = last_q2;
    assign ready_o = ready_q;

    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, max_pool);
        #1;
    end
    `endif

endmodule
