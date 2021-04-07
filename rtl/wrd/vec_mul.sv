/*
 * Vector Multiplied
 * TODO: Register outputs!
 */

module vec_mul #(
    parameter BW = 8,
    parameter VECTOR_SIZE = 13
) (
    input clk_i,
    input rstn_i,

    input signed [(VECTOR_SIZE * BW) - 1 : 0] data1_i,
    input valid1_i,
    input last1_i,
    output ready1_o,

    input signed [(VECTOR_SIZE * BW) - 1 : 0] data2_i,
    input valid2_i,
    input last2_i,
    output ready2_o,

    output signed [(VECTOR_SIZE * BW) - 1 : 0] data_o,
    output valid_o,
    output last_o,
    input  ready_i
);

    wire signed [BW - 1 : 0] data1_arr [VECTOR_SIZE - 1 : 0];
    wire signed [BW - 1 : 0] data2_arr [VECTOR_SIZE - 1 : 0];
    wire signed [BW - 1 : 0] out_arr   [VECTOR_SIZE - 1 : 0];

    genvar i;

    generate
        for (i = 0; i < VECTOR_SIZE; i = i + 1) begin: unpack_inputs
            assign data1_arr[i] = data1_i[(i + 1) * BW - 1 : i * BW];
            assign data2_arr[i] = data2_i[(i + 1) * BW - 1 : i * BW];
        end
    endgenerate

    generate
        for (i = 0; i < VECTOR_SIZE; i = i + 1) begin: vector_multiply
            assign out_arr[i] = data1_arr[i] * data2_arr[i];
        end
    endgenerate

    generate
        for (i = 0; i < VECTOR_SIZE; i = i + 1) begin: pack_output
            assign data_o[(i + 1) * BW - 1 : i * BW] = out_arr[i];
        end
    endgenerate

    assign valid_o  = valid1_i & valid2_i;
    assign last_o   = last1_i | last2_i;
    assign ready1_o = ready_i;
    assign ready2_o = ready_i;

    `ifdef COCOTB_SIM
    initial begin
      $dumpfile ("vec_mul.vcd");
      $dumpvars (0, vec_mul);
      #1;
    end
    `endif

endmodule
