// ============================================================================
// Multiply Accumulate
// Design: Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// Assumes that biases have 2x bitwidth of weights, and outputs are 3x bitwidth
// Also assumes that packet lengths are > 3 (which is the propogation length of
// the bias out to the output, since it is pipelined).
//
// TODO: Check which signals have to be signed
// ============================================================================

module mac #(
    parameter BW_I        = 8,          // input bitwidth
    parameter BW_O        = BW_I * 3,   // output bitwidth
    parameter BW_BIAS     = BW_I * 2,   // bias bitwidth
    parameter NUM_CLASSES = 3           // number of output classes
) (
    input                                           clk_i,
    input                                           rst_n_i,

    input  signed [(NUM_CLASSES * BW_I) - 1 : 0]    data0_i,
    input                                           valid0_i,
    input                                           last0_i,
    output                                          ready0_o,

    input  signed [(NUM_CLASSES * BW_I) - 1 : 0]    data1_w_i,
    input  signed [(NUM_CLASSES * BW_BIAS) - 1 : 0] data1_b_i,
    input                                           valid1_i,
    input                                           last1_i,
    output                                          ready1_o,

    output signed [(NUM_CLASSES * BW_O) - 1 : 0]    data_o,
    output                                          valid_o,
    output                                          last_o,
    input                                           ready_i
);

    genvar i;

    // add 2 cycle bias delay line to account for multiplier and accumulator
    reg signed [(NUM_CLASSES * BW_BIAS) - 1 : 0] data1_b_q, data1_b_q2;
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            data1_b_q  <= 0;
            data1_b_q2 <= 0;
        end else begin
            data1_b_q  <= data1_b_i;
            data1_b_q2 <= data1_b_q;
        end
    end

    // unpacked arrays
    wire signed [BW_I - 1 : 0]    input_arr  [NUM_CLASSES - 1 : 0];
    wire signed [BW_I - 1 : 0]    weight_arr [NUM_CLASSES - 1 : 0];
    wire signed [BW_BIAS - 1 : 0] bias_arr   [NUM_CLASSES - 1 : 0];

    // unpack data input
    for (i = 0; i < NUM_CLASSES; i = i + 1) begin: unpack_inputs
        assign input_arr[i]  = data0_i[(i + 1) * BW_I - 1 : i * BW_I];
        assign weight_arr[i] = data1_w_i[(i + 1) * BW_I - 1 : i * BW_I];
        assign bias_arr[i]   = data1_b_q2[(i + 1) * BW_BIAS - 1 : i * BW_BIAS];
    end

    // registered multiplication of input and bias
    reg signed [(BW_I * 2) - 1: 0] mult_arr [NUM_CLASSES - 1 : 0];
    for (i = 0; i < NUM_CLASSES; i = i + 1) begin: fc_multiply
        always @(posedge clk_i) begin
            if (!rst_n_i) begin
                mult_arr[i] <= 'd0;
            end else begin
                mult_arr[i] <= input_arr[i] * weight_arr[i];
            end
        end
    end

    // accumulation buffer
    reg signed [BW_O - 1: 0] acc_arr [NUM_CLASSES - 1 : 0];
    for (i = 0; i < NUM_CLASSES; i = i + 1) begin: fc_accumulate
        always @(posedge clk_i) begin
            if (!rst_n_i) begin
                acc_arr[i] <= 'd0;
            end else begin
                if (last_q2) begin
                    acc_arr[i] <= 'd0;
                end else begin
                    acc_arr[i] <= mult_arr[i] + acc_arr[i];
                end
            end
        end
    end

    // bias addition
    reg signed [BW_O - 1: 0] add_arr [NUM_CLASSES - 1 : 0];
    for (i = 0; i < NUM_CLASSES; i = i + 1) begin: fc_bias
        always @(posedge clk_i) begin
            if (!rst_n_i) begin
                add_arr[i] <= 'd0;
            end else begin
                add_arr[i] <= acc_arr[i] + bias_arr[i];
            end
        end
    end

    // assign output
    for (i = 0; i < NUM_CLASSES; i = i + 1) begin: pack_output
        assign data_o[(i + 1) * BW_O - 1 : i * BW_O] = add_arr[i];
    end

    // register all outputs
    reg valid_q, valid_q2, valid_q3;
    reg last_q, last_q2, last_q3;
    reg ready_q;
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            valid_q  <= 'b0;
            valid_q2 <= 'b0;
            valid_q3 <= 'b0;
            last_q   <= 'b0;
            last_q2  <= 'b0;
            last_q3  <= 'b0;
            ready_q  <= 'b0;
        end else begin
            valid_q  <= valid0_i && valid1_i;
            valid_q2 <= valid_q;
            valid_q3 <= valid_q2;
            last_q   <= last0_i | last1_i;
            last_q2  <= last_q;
            last_q3  <= last_q2;
            ready_q  <= ready_i;
        end
    end

    assign valid_o  = valid_q3 && last_q3;
    assign last_o   = last_q3;
    assign ready0_o = ready_q;
    assign ready1_o = ready_q;

    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, mac);
        #1;
    end
    `endif

endmodule