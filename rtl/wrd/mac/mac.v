// ============================================================================
// Module:       Multiply Accumulate
// Design:       Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// Assumes that biases have 2x bitwidth of weights, and outputs are 3x bitwidth
// Also assumes that packet lengths are > 3 (which is the propogation length of
// the bias out to the output, since it is pipelined).
//
// TODO: Check which signals have to be signed
// ============================================================================

module mac #(
    parameter I_BW        = 8,          // input bitwidth
    parameter O_BW        = I_BW * 3,   // output bitwidth
    parameter BIAS_BW     = I_BW * 2,   // bias bitwidth
    parameter NUM_CLASSES = 3           // number of output classes
) (
    // clock and reset
    input                                           clk_i,
    input                                           rst_n_i,

    // streaming input
    input  signed [I_BW - 1: 0]                     data0_i,
    input                                           valid0_i,
    input                                           last0_i,
    output                                          ready0_o,

    // streaming input
    input  signed [(NUM_CLASSES * I_BW) - 1 : 0]    data1_w_i,
    input  signed [(NUM_CLASSES * BIAS_BW) - 1 : 0] data1_b_i,
    input                                           valid1_i,
    input                                           last1_i,
    output                                          ready1_o,

    // streaming output
    output signed [(NUM_CLASSES * O_BW) - 1 : 0]    data_o,
    output                                          valid_o,
    output                                          last_o,
    input                                           ready_i
);

    localparam VALID_TIMEOUT_CYCLES         = 8;  // num cycles to reset after
    localparam VALID_TIMEOUT_BW             = $clog2(VALID_TIMEOUT_CYCLES + 1);

    genvar i;

    // =========================================================================
    // Delay Lines
    // =========================================================================
    // add 2 cycle bias delay line to account for multiplier and accumulator
    reg signed [(NUM_CLASSES * BIAS_BW) - 1 : 0] data1_b_q, data1_b_q2;
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            data1_b_q  <= 0;
            data1_b_q2 <= 0;
        end else begin
            data1_b_q  <= data1_b_i;
            data1_b_q2 <= data1_b_q;
        end
    end

    // =========================================================================
    // Input Unpacking
    // =========================================================================
    // unpacked arrays
    wire signed [I_BW - 1 : 0]    weight_arr [NUM_CLASSES - 1 : 0];
    wire signed [BIAS_BW - 1 : 0] bias_arr   [NUM_CLASSES - 1 : 0];

    // unpack data input
    for (i = 0; i < NUM_CLASSES; i = i + 1) begin: unpack_inputs
        assign weight_arr[i] = data1_w_i[(i + 1) * I_BW - 1 : i * I_BW];
        assign bias_arr[i]   = data1_b_q2[(i + 1) * BIAS_BW - 1 : i * BIAS_BW];
    end

    // =========================================================================
    // Vector Multiplication
    // =========================================================================
    // registered multiplication of input and bias
    reg signed [(I_BW * 2) - 1: 0] mult_arr [NUM_CLASSES - 1 : 0];
    for (i = 0; i < NUM_CLASSES; i = i + 1) begin: fc_multiply
        always @(posedge clk_i) begin
            if (!rst_n_i) begin
                mult_arr[i] <= 'd0;
            end else begin
                mult_arr[i] <= data0_i * weight_arr[i];
            end
        end
    end

    // =========================================================================
    // Accumulation Buffer
    // =========================================================================
    // clear the accumulation buffer when valid has a rising edge
    // wire valid_i_pos_edge;
    // assign valid_i_pos_edge = valid0_i & (!valid_q);

    // clear the accumulation buffer if no valid data has been passed in for
    // VALID_TIMEOUT_CYCLES cycles
    wire valid_timeout;
    reg [VALID_TIMEOUT_BW - 1: 0] valid_timeout_counter;
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            valid_timeout_counter <= 'd0;
        end else begin
            if (valid0_i) begin  // reset counter on valid data
                valid_timeout_counter <= 'd0;
            end else if (valid_timeout_counter == VALID_TIMEOUT_CYCLES) begin
                valid_timeout_counter <= valid_timeout_counter;
            end else begin
                valid_timeout_counter <= valid_timeout_counter + 'd1;
            end
        end
    end
    assign valid_timeout = (valid_timeout_counter == VALID_TIMEOUT_CYCLES);

    reg signed [O_BW - 1: 0] acc_arr [NUM_CLASSES - 1 : 0];
    for (i = 0; i < NUM_CLASSES; i = i + 1) begin: fc_accumulate
        always @(posedge clk_i) begin
            if (!rst_n_i) begin
                acc_arr[i] <= 'd0;
            end else begin
                if (last_q2 | valid_timeout) begin
                    acc_arr[i] <= 'd0;
                end else if (valid_q) begin
                    acc_arr[i] <= mult_arr[i] + acc_arr[i];
                end else begin
                    acc_arr[i] <= acc_arr[i];
                end
            end
        end
    end

    // =========================================================================
    // Bias Addition
    // =========================================================================
    reg signed [O_BW - 1: 0] add_arr [NUM_CLASSES - 1 : 0];
    for (i = 0; i < NUM_CLASSES; i = i + 1) begin: fc_bias
        always @(posedge clk_i) begin
            if (!rst_n_i) begin
                add_arr[i] <= 'd0;
            end else begin
                add_arr[i] <= acc_arr[i] + bias_arr[i];
            end
        end
    end

    // =========================================================================
    // Output Assignment
    // =========================================================================
    for (i = 0; i < NUM_CLASSES; i = i + 1) begin: pack_output
        assign data_o[(i + 1) * O_BW - 1 : i * O_BW] = add_arr[i];
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
            // last_q   <= last0_i | last1_i;
            last_q   <= last1_i;
            last_q2  <= last_q;
            last_q3  <= last_q2;
            ready_q  <= ready_i;
        end
    end


    assign valid_o  = valid_q3 && last_q3;
    assign last_o   = last_q3;
    assign ready0_o = ready_q;
    assign ready1_o = ready_q;

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, mac);
        // reg [7:0] idx; // need integer for loop
        $dumpvars(0, mult_arr[0]);
        $dumpvars(0, acc_arr[0]);
        $dumpvars(0, add_arr[0]);
        $dumpvars(0, mult_arr[1]);
        $dumpvars(0, acc_arr[1]);
        $dumpvars(0, add_arr[1]);
        #1;
    end
    `endif

endmodule
