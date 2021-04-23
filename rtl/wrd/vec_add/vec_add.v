// =============================================================================
// Module:       Vector Adder
// Design:       Eldrick Millares
// Verification: Matthew Pauly
// Notes:
// =============================================================================

module vec_add #(
    parameter I_BW = 16,
    parameter O_BW = 18,
    parameter VECTOR_LEN = 13
) (
    // clock and reset
    input                                       clk_i,
    input                                       rst_n_i,

    // streaming input
    input  signed [(VECTOR_LEN * I_BW) - 1 : 0] data0_i,
    input                                       valid0_i,
    input                                       last0_i,
    output                                      ready0_o,

    // streaming input
    input  signed [(VECTOR_LEN * I_BW) - 1 : 0] data1_i,
    input                                       valid1_i,
    input                                       last1_i,
    output                                      ready1_o,

    // streaming input
    input  signed [(VECTOR_LEN * I_BW) - 1 : 0] data2_i,
    input                                       valid2_i,
    input                                       last2_i,
    output                                      ready2_o,

    // streaming output
    output signed [(VECTOR_LEN * O_BW) - 1 : 0] data_o,
    output                                      valid_o,
    output                                      last_o,
    input                                       ready_i
);

    genvar i;

    // =========================================================================
    // Input Unpacking
    // =========================================================================
    // unpacked arrays
    wire signed [I_BW - 1 : 0] data0_arr [VECTOR_LEN - 1 : 0];
    wire signed [I_BW - 1 : 0] data1_arr [VECTOR_LEN - 1 : 0];
    wire signed [I_BW - 1 : 0] data2_arr [VECTOR_LEN - 1 : 0];
    reg  signed [O_BW - 1 : 0] out_arr   [VECTOR_LEN - 1 : 0];

    // unpack data input
    for (i = 0; i < VECTOR_LEN; i = i + 1) begin: unpack_inputs
        assign data0_arr[i] = data0_i[(i + 1) * I_BW - 1 : i * I_BW];
        assign data1_arr[i] = data1_i[(i + 1) * I_BW - 1 : i * I_BW];
        assign data2_arr[i] = data2_i[(i + 1) * I_BW - 1 : i * I_BW];
    end

    // =========================================================================
    // Vector Addition
    // =========================================================================
    // registered addition of data elements
    for (i = 0; i < VECTOR_LEN; i = i + 1) begin: vector_addition
        always @(posedge clk_i) begin
            if (!rst_n_i) begin
                out_arr[i] <= 'd0;
            end else begin
                out_arr[i] <= data0_arr[i] + data1_arr[i] + data2_arr[i];
            end
        end
    end

    // =========================================================================
    // Output Packing
    // =========================================================================
    // pack addition results
    for (i = 0; i < VECTOR_LEN; i = i + 1) begin: pack_output
        assign data_o[(i + 1) * O_BW - 1 : i * O_BW] = out_arr[i];
    end

    // =========================================================================
    // Output Assignment
    // =========================================================================
    // register all outputs
    reg valid_q, last_q, ready_q;
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            valid_q <= 'b0;
            last_q  <= 'b0;
            ready_q <= 'b0;
        end else begin
            valid_q <= valid0_i & valid1_i & valid2_i;
            last_q  <= last0_i | last1_i | last2_i;
            ready_q <= ready_i;
        end
    end

    assign valid_o  = valid_q;
    assign last_o   = last_q;
    assign ready0_o = ready_q;
    assign ready1_o = ready_q;
    assign ready2_o = ready_q;

    // =========================================================================
    // Simulation Only Waveform Dump (.vcd export)
    // =========================================================================
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, vec_add);
        #1;
    end
    `endif

endmodule
