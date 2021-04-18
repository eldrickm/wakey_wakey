/*
 * Vector Multiplier
 * Design: Eldrick Millares
 * Verification: Matthew Pauly
 */

module vec_mul #(
    parameter BW_I = 8,         // input bitwidth
    parameter BW_O = 16,        // output bitwidth
    parameter VECTOR_LEN = 13   // number of vector elements
) (
    input                                       clk_i,
    input                                       rst_n_i,

    input  signed [(VECTOR_LEN * BW_I) - 1 : 0] data0_i,
    input                                       valid0_i,
    input                                       last0_i,
    output                                      ready0_o,

    input  signed [(VECTOR_LEN * BW_I) - 1 : 0] data1_i,
    input                                       valid1_i,
    input                                       last1_i,
    output                                      ready1_o,

    output signed [(VECTOR_LEN * BW_O) - 1 : 0] data_o,
    output                                      valid_o,
    output                                      last_o,
    input                                       ready_i
);

    genvar i;

    // unpacked arrays
    wire signed [BW_I - 1 : 0] data0_arr [VECTOR_LEN - 1 : 0];
    wire signed [BW_I - 1 : 0] data1_arr [VECTOR_LEN - 1 : 0];
    reg  signed [BW_O - 1 : 0] out_arr   [VECTOR_LEN - 1 : 0];

    // unpack data input
    for (i = 0; i < VECTOR_LEN; i = i + 1) begin: unpack_inputs
        assign data0_arr[i] = data0_i[(i + 1) * BW_I - 1 : i * BW_I];
        assign data1_arr[i] = data1_i[(i + 1) * BW_I - 1 : i * BW_I];
    end

    // registered multiplication of data elements
    for (i = 0; i < VECTOR_LEN; i = i + 1) begin: vector_multiply
        always @(posedge clk_i) begin
            if (!rst_n_i) begin
                out_arr[i] <= 'd0;
            end else begin
                out_arr[i] <= data0_arr[i] * data1_arr[i];
            end
        end
    end

    // pack multiplication results
    for (i = 0; i < VECTOR_LEN; i = i + 1) begin: pack_output
        assign data_o[(i + 1) * BW_O - 1 : i * BW_O] = out_arr[i];
    end

    // register all outputs
    reg valid_q, last_q, ready_q;
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            valid_q <= 'b0;
            last_q  <= 'b0;
            ready_q <= 'b0;
        end else begin
            valid_q <= valid0_i & valid1_i;
            last_q  <= last0_i | last1_i;
            ready_q <= ready_i;
        end
    end

    assign valid_o  = valid_q;
    assign last_o   = last_q;
    assign ready0_o = ready_q;
    assign ready1_o = ready_q;

    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wave.vcd");
        $dumpvars (0, vec_mul);
        // Uncomment below to dump array variables
        // for(int i = 0; i < VECTOR_LEN; i = i + 1)
        //     $dumpvars(1, out_arr[i]);
        #1;
    end
    `endif

endmodule
